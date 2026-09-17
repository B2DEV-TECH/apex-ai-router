import sqlite3

from apex_ai_router.domain.pricing import PricingConfig
from apex_ai_router.telemetry.models import RequestTelemetry
from apex_ai_router.telemetry.store import TelemetryStore


def _telemetry(**overrides) -> RequestTelemetry:
    defaults = dict(
        request_id="req-1",
        route="apex-efficient",
        policy="fixed",
        selected_target="efficient",
        selected_provider="openai_compatible",
        selected_model="mock-efficient-v1",
        routing_duration_ms=1.5,
        provider_duration_ms=42.0,
        total_duration_ms=45.0,
        input_tokens=100,
        output_tokens=50,
        total_tokens=150,
        estimated_cost=0.002,
        estimated_baseline_cost=0.02,
        estimated_savings=0.018,
        success=True,
        http_status=200,
        error_code=None,
    )
    defaults.update(overrides)
    return RequestTelemetry(**defaults)


def test_migration_creates_expected_tables(tmp_path):
    TelemetryStore(str(tmp_path / "telemetry.db"))

    conn = sqlite3.connect(str(tmp_path / "telemetry.db"))
    tables = {
        row[0]
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
    }
    conn.close()

    assert {"ai_request", "ai_model_pricing", "ai_route_config_snapshot"} <= tables


def test_reopening_store_does_not_fail_or_duplicate_schema(tmp_path):
    db_path = str(tmp_path / "telemetry.db")
    TelemetryStore(db_path).close()
    store = TelemetryStore(db_path)  # must not raise "table already exists"

    store.record_request(_telemetry(), timestamp="2026-01-01T00:00:00+00:00")

    assert store.summary()["requests"] == 1


def test_record_and_list_requests_round_trips_fields(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    store.record_request(_telemetry(), timestamp="2026-01-01T00:00:00+00:00")

    requests = store.list_requests()

    assert len(requests) == 1
    row = requests[0]
    assert row["request_id"] == "req-1"
    assert row["selected_model"] == "mock-efficient-v1"
    assert row["input_tokens"] == 100
    assert row["success"] is True
    assert "prompt_content" not in row
    assert "response_content" not in row


def test_prompt_content_not_persisted_unless_explicitly_passed(tmp_path):
    db_path = str(tmp_path / "telemetry.db")
    store = TelemetryStore(db_path)
    store.record_request(_telemetry(), timestamp="2026-01-01T00:00:00+00:00")

    conn = sqlite3.connect(db_path)
    row = conn.execute("SELECT prompt_content, response_content FROM ai_request").fetchone()
    conn.close()

    assert row == (None, None)


def test_prompt_content_persisted_only_when_dev_opt_in_is_used(tmp_path):
    db_path = str(tmp_path / "telemetry.db")
    store = TelemetryStore(db_path)
    store.record_request(
        _telemetry(),
        timestamp="2026-01-01T00:00:00+00:00",
        prompt_content='{"messages": ["hi"]}',
        response_content='{"content": "hello"}',
    )

    conn = sqlite3.connect(db_path)
    row = conn.execute("SELECT prompt_content, response_content FROM ai_request").fetchone()
    conn.close()

    assert row == ('{"messages": ["hi"]}', '{"content": "hello"}')


def test_summary_aggregates_across_requests(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    store.record_request(_telemetry(request_id="a"), timestamp="2026-01-01T00:00:00+00:00")
    store.record_request(
        _telemetry(request_id="b", success=False, http_status=500, error_code="routing_failed",
                   estimated_cost=None, estimated_baseline_cost=None, estimated_savings=None),
        timestamp="2026-01-01T01:00:00+00:00",
    )

    summary = store.summary()

    assert summary["requests"] == 2
    assert summary["success_rate"] == 0.5
    assert summary["estimated_cost"] == 0.002


def test_summary_cost_is_none_when_no_request_has_known_pricing(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    store.record_request(
        _telemetry(estimated_cost=None, estimated_baseline_cost=None, estimated_savings=None),
        timestamp="2026-01-01T00:00:00+00:00",
    )

    summary = store.summary()

    assert summary["estimated_cost"] is None
    assert summary["estimated_capable_baseline_cost"] is None
    assert summary["estimated_savings"] is None


def test_summary_with_no_requests_returns_none_success_rate(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))

    summary = store.summary()

    assert summary["requests"] == 0
    assert summary["success_rate"] is None


def test_models_breakdown_groups_by_selected_model(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    store.record_request(
        _telemetry(request_id="a", selected_model="mock-efficient-v1"),
        timestamp="2026-01-01T00:00:00+00:00",
    )
    store.record_request(
        _telemetry(request_id="b", selected_model="mock-capable-v1"),
        timestamp="2026-01-01T00:00:00+00:00",
    )

    breakdown = store.models_breakdown()

    models = {row["model"] for row in breakdown}
    assert models == {"mock-efficient-v1", "mock-capable-v1"}


def test_upstream_model_round_trips_and_defaults_to_none(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    store.record_request(
        _telemetry(request_id="a", route="apex-auto", selected_model="apex-auto",
                   upstream_model="mock-efficient-v1"),
        timestamp="2026-01-01T00:00:00+00:00",
    )
    store.record_request(_telemetry(request_id="b"), timestamp="2026-01-01T00:01:00+00:00")

    rows = {row["request_id"]: row for row in store.list_requests()}

    assert rows["a"]["selected_model"] == "apex-auto"
    assert rows["a"]["upstream_model"] == "mock-efficient-v1"
    assert rows["b"]["upstream_model"] is None


def test_backends_breakdown_groups_by_route_and_upstream_model(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    auto = dict(route="apex-auto", selected_target="switchyard", selected_model="apex-auto")
    store.record_request(
        _telemetry(request_id="a", upstream_model="mock-efficient-v1", **auto),
        timestamp="2026-01-01T00:00:00+00:00",
    )
    store.record_request(
        _telemetry(request_id="b", upstream_model="mock-efficient-v1", **auto),
        timestamp="2026-01-01T00:01:00+00:00",
    )
    store.record_request(
        _telemetry(request_id="c", upstream_model="mock-capable-v1", **auto),
        timestamp="2026-01-01T00:02:00+00:00",
    )
    store.record_request(
        _telemetry(request_id="d", upstream_model=None, success=False, http_status=502,
                   error_code="provider_unavailable", **auto),
        timestamp="2026-01-01T00:03:00+00:00",
    )
    store.record_request(
        _telemetry(request_id="e", upstream_model="mock-efficient-v1"),
        timestamp="2026-01-01T00:04:00+00:00",
    )

    breakdown = store.backends_breakdown()

    by_key = {(row["route"], row["upstream_model"]): row for row in breakdown}
    assert by_key[("apex-auto", "mock-efficient-v1")]["requests"] == 2
    assert by_key[("apex-auto", "mock-capable-v1")]["requests"] == 1
    assert by_key[("apex-auto", None)]["requests"] == 1
    assert by_key[("apex-auto", None)]["success_rate"] == 0.0
    assert by_key[("apex-efficient", "mock-efficient-v1")]["requests"] == 1
    # Ordered by route, then most-requested backend first.
    assert [row["route"] for row in breakdown] == ["apex-auto"] * 3 + ["apex-efficient"]
    assert breakdown[0]["upstream_model"] == "mock-efficient-v1"


def test_daily_groups_by_calendar_day(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    store.record_request(_telemetry(request_id="a"), timestamp="2026-01-01T10:00:00+00:00")
    store.record_request(_telemetry(request_id="b"), timestamp="2026-01-01T23:00:00+00:00")
    store.record_request(_telemetry(request_id="c"), timestamp="2026-01-02T01:00:00+00:00")

    daily = store.daily()

    by_day = {row["date"]: row["requests"] for row in daily}
    assert by_day == {"2026-01-01": 2, "2026-01-02": 1}


def test_snapshot_pricing_upserts_current_config(tmp_path):
    store = TelemetryStore(str(tmp_path / "telemetry.db"))
    pricing = PricingConfig.model_validate(
        {
            "pricing": {
                "mock-efficient-v1": {
                    "effective_date": "2026-01-01",
                    "input_per_million": 0.0,
                    "output_per_million": 0.0,
                }
            }
        }
    )

    store.snapshot_pricing(pricing)
    store.snapshot_pricing(pricing)  # must not fail or duplicate on re-snapshot

    conn = sqlite3.connect(str(tmp_path / "telemetry.db"))
    count = conn.execute("SELECT COUNT(*) FROM ai_model_pricing").fetchone()[0]
    conn.close()
    assert count == 1
