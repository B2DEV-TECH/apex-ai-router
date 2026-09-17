"""SQLite-backed telemetry repository (spec section 14).

SQLite is a deliberate choice for local development and demo use, not a
production-scale claim — see HANDOFF.md. One connection is opened per
`TelemetryStore` instance and reused for its lifetime (the process is
expected to run a single asyncio event loop with no thread-pool offloading
of the chat-completions handler, so there is no real concurrent-access
hazard); `check_same_thread=False` is set defensively, not because this is
built to be shared across threads.

Schema changes go through `_MIGRATIONS`, applied in order and tracked via
SQLite's own `PRAGMA user_version` — a minimal but real migration mechanism,
appropriate for this project's single-file demo database.
"""

import sqlite3
from pathlib import Path
from typing import Any

from apex_ai_router.domain.pricing import PricingConfig
from apex_ai_router.telemetry.models import RequestTelemetry

_MIGRATIONS: list[str] = [
    # Migration 1: initial schema.
    """
    CREATE TABLE ai_request (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        route TEXT NOT NULL,
        policy TEXT,
        selected_target TEXT,
        selected_provider TEXT,
        selected_model TEXT,
        routing_duration_ms REAL,
        provider_duration_ms REAL,
        total_duration_ms REAL NOT NULL,
        input_tokens INTEGER,
        output_tokens INTEGER,
        total_tokens INTEGER,
        estimated_cost REAL,
        estimated_baseline_cost REAL,
        estimated_savings REAL,
        success INTEGER NOT NULL,
        http_status INTEGER NOT NULL,
        error_code TEXT,
        -- Only populated when telemetry_log_content is explicitly enabled
        -- (dev-only opt-in, off by default); NULL otherwise. Never returned
        -- by any /admin endpoint regardless of this setting.
        prompt_content TEXT,
        response_content TEXT
    );
    CREATE INDEX idx_ai_request_timestamp ON ai_request(timestamp);
    CREATE INDEX idx_ai_request_selected_model ON ai_request(selected_model);

    CREATE TABLE ai_model_pricing (
        model TEXT PRIMARY KEY,
        effective_date TEXT NOT NULL,
        input_per_million REAL NOT NULL,
        output_per_million REAL NOT NULL
    );

    CREATE TABLE ai_route_config_snapshot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        captured_at TEXT NOT NULL,
        routing_yaml TEXT NOT NULL
    );
    """,
    # Migration 2: retry count (spec section 24 -- "Include retry count in
    # telemetry"), not part of the original schema.
    """
    ALTER TABLE ai_request ADD COLUMN retry_count INTEGER;
    """,
]


def _row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
    return {key: row[key] for key in row.keys()}


class TelemetryStore:
    def __init__(self, db_path: str):
        if db_path != ":memory:":
            parent = Path(db_path).parent
            if str(parent) not in ("", "."):
                parent.mkdir(parents=True, exist_ok=True)

        self._conn = sqlite3.connect(db_path, check_same_thread=False)
        self._conn.row_factory = sqlite3.Row
        self._migrate()

    def _migrate(self) -> None:
        current_version = self._conn.execute("PRAGMA user_version").fetchone()[0]
        for index, script in enumerate(_MIGRATIONS[current_version:], start=current_version + 1):
            self._conn.executescript(script)
            self._conn.execute(f"PRAGMA user_version = {index}")
        self._conn.commit()

    def close(self) -> None:
        self._conn.close()

    def record_request(
        self,
        telemetry: RequestTelemetry,
        *,
        timestamp: str,
        prompt_content: str | None = None,
        response_content: str | None = None,
    ) -> None:
        """`prompt_content`/`response_content` must be passed only when the
        caller has already checked `Settings.telemetry_log_content` — this
        method does not gate on it itself, so the on/off decision lives in
        exactly one place (the request handler)."""
        self._conn.execute(
            """
            INSERT INTO ai_request (
                request_id, timestamp, route, policy, selected_target,
                selected_provider, selected_model, routing_duration_ms,
                provider_duration_ms, total_duration_ms, input_tokens,
                output_tokens, total_tokens, estimated_cost,
                estimated_baseline_cost, estimated_savings, success,
                http_status, error_code, retry_count, prompt_content,
                response_content
            ) VALUES (
                :request_id, :timestamp, :route, :policy, :selected_target,
                :selected_provider, :selected_model, :routing_duration_ms,
                :provider_duration_ms, :total_duration_ms, :input_tokens,
                :output_tokens, :total_tokens, :estimated_cost,
                :estimated_baseline_cost, :estimated_savings, :success,
                :http_status, :error_code, :retry_count, :prompt_content,
                :response_content
            )
            """,
            {
                "request_id": telemetry.request_id,
                "timestamp": timestamp,
                "route": telemetry.route,
                "policy": telemetry.policy,
                "selected_target": telemetry.selected_target,
                "selected_provider": telemetry.selected_provider,
                "selected_model": telemetry.selected_model,
                "routing_duration_ms": telemetry.routing_duration_ms,
                "provider_duration_ms": telemetry.provider_duration_ms,
                "total_duration_ms": telemetry.total_duration_ms,
                "input_tokens": telemetry.input_tokens,
                "output_tokens": telemetry.output_tokens,
                "total_tokens": telemetry.total_tokens,
                "estimated_cost": telemetry.estimated_cost,
                "estimated_baseline_cost": telemetry.estimated_baseline_cost,
                "estimated_savings": telemetry.estimated_savings,
                "success": 1 if telemetry.success else 0,
                "http_status": telemetry.http_status,
                "error_code": telemetry.error_code,
                "retry_count": telemetry.retry_count,
                "prompt_content": prompt_content,
                "response_content": response_content,
            },
        )
        self._conn.commit()

    def snapshot_pricing(self, pricing: PricingConfig) -> None:
        rows = [
            (model, entry.effective_date.isoformat(), entry.input_per_million,
             entry.output_per_million)
            for model, entry in pricing.pricing.items()
        ]
        self._conn.executemany(
            """
            INSERT INTO ai_model_pricing (model, effective_date, input_per_million,
                                           output_per_million)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(model) DO UPDATE SET
                effective_date = excluded.effective_date,
                input_per_million = excluded.input_per_million,
                output_per_million = excluded.output_per_million
            """,
            rows,
        )
        self._conn.commit()

    def snapshot_route_config(self, routing_yaml_text: str, *, captured_at: str) -> None:
        self._conn.execute(
            "INSERT INTO ai_route_config_snapshot (captured_at, routing_yaml) VALUES (?, ?)",
            (captured_at, routing_yaml_text),
        )
        self._conn.commit()

    def summary(self, *, since: str | None = None, until: str | None = None) -> dict[str, Any]:
        where_sql, params = _timestamp_filter(since, until)
        row = self._conn.execute(
            f"""
            SELECT
                COUNT(*) AS requests,
                SUM(success) AS successes,
                SUM(estimated_cost) AS estimated_cost,
                SUM(estimated_baseline_cost) AS estimated_capable_baseline_cost,
                SUM(estimated_savings) AS estimated_savings
            FROM ai_request
            {where_sql}
            """,
            params,
        ).fetchone()

        requests = row["requests"]
        success_rate = (row["successes"] / requests) if requests else None
        return {
            "requests": requests,
            "success_rate": success_rate,
            "estimated_cost": row["estimated_cost"],
            "estimated_capable_baseline_cost": row["estimated_capable_baseline_cost"],
            "estimated_savings": row["estimated_savings"],
        }

    def models_breakdown(
        self, *, since: str | None = None, until: str | None = None
    ) -> list[dict[str, Any]]:
        where_sql, params = _timestamp_filter(since, until)
        rows = self._conn.execute(
            f"""
            SELECT
                selected_model AS model,
                COUNT(*) AS requests,
                SUM(success) AS successes,
                SUM(input_tokens) AS input_tokens,
                SUM(output_tokens) AS output_tokens,
                SUM(estimated_cost) AS estimated_cost,
                SUM(estimated_baseline_cost) AS estimated_capable_baseline_cost,
                SUM(estimated_savings) AS estimated_savings
            FROM ai_request
            {where_sql}
            GROUP BY selected_model
            ORDER BY requests DESC
            """,
            params,
        ).fetchall()

        return [
            {
                "model": row["model"],
                "requests": row["requests"],
                "success_rate": (row["successes"] / row["requests"]) if row["requests"] else None,
                "input_tokens": row["input_tokens"],
                "output_tokens": row["output_tokens"],
                "estimated_cost": row["estimated_cost"],
                "estimated_capable_baseline_cost": row["estimated_capable_baseline_cost"],
                "estimated_savings": row["estimated_savings"],
            }
            for row in rows
        ]

    def daily(self, *, since: str | None = None, until: str | None = None) -> list[dict[str, Any]]:
        where_sql, params = _timestamp_filter(since, until)
        rows = self._conn.execute(
            f"""
            SELECT
                date(timestamp) AS day,
                COUNT(*) AS requests,
                SUM(success) AS successes,
                SUM(estimated_cost) AS estimated_cost,
                SUM(estimated_baseline_cost) AS estimated_capable_baseline_cost,
                SUM(estimated_savings) AS estimated_savings
            FROM ai_request
            {where_sql}
            GROUP BY day
            ORDER BY day ASC
            """,
            params,
        ).fetchall()

        return [
            {
                "date": row["day"],
                "requests": row["requests"],
                "success_rate": (row["successes"] / row["requests"]) if row["requests"] else None,
                "estimated_cost": row["estimated_cost"],
                "estimated_capable_baseline_cost": row["estimated_capable_baseline_cost"],
                "estimated_savings": row["estimated_savings"],
            }
            for row in rows
        ]

    def list_requests(self, *, limit: int = 50, offset: int = 0) -> list[dict[str, Any]]:
        """Never selects `prompt_content`/`response_content` — the admin API
        must not expose prompt contents even when dev-only content logging
        is enabled (spec section 15)."""
        rows = self._conn.execute(
            """
            SELECT
                request_id, timestamp, route, policy, selected_target,
                selected_provider, selected_model, routing_duration_ms,
                provider_duration_ms, total_duration_ms, input_tokens,
                output_tokens, total_tokens, estimated_cost,
                estimated_baseline_cost, estimated_savings, success,
                http_status, error_code, retry_count
            FROM ai_request
            ORDER BY id DESC
            LIMIT :limit OFFSET :offset
            """,
            {"limit": limit, "offset": offset},
        ).fetchall()
        results = []
        for row in rows:
            item = _row_to_dict(row)
            item["success"] = bool(item["success"])
            results.append(item)
        return results


def _timestamp_filter(since: str | None, until: str | None) -> tuple[str, dict[str, Any]]:
    clauses: list[str] = []
    params: dict[str, Any] = {}
    if since is not None:
        clauses.append("timestamp >= :since")
        params["since"] = since
    if until is not None:
        clauses.append("timestamp <= :until")
        params["until"] = until
    where_sql = f"WHERE {' AND '.join(clauses)}" if clauses else ""
    return where_sql, params
