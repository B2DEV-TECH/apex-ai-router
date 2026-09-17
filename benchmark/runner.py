#!/usr/bin/env python
"""Benchmark harness CLI (spec sections 26-29, 32, 51-52, 60 / Phase 8).

Runs the synthetic task dataset (`tasks/tasks.yaml`) through all three
execution modes -- A: fixed `apex-efficient`, B: fixed `apex-capable`,
C: `apex-auto` -- against a real gateway over real HTTP, scores each
response deterministically (`scoring.py`), optionally runs an LLM-judge
pass on subjective tasks (`judge.py`), reconciles cost/routing detail from
`/admin/requests` by `X-Request-Id`, and writes a Markdown + JSON report
(`report.py`).

Two modes:

  --mode mock   Spawns the project's own local mock model server, the real
                compiled `switchyard-server` binary (if built -- see
                deploy/switchyard/README.md), and the gateway itself as
                local subprocesses on free loopback ports, using a
                temporary routing config and a temporary, throwaway
                telemetry database. No external network access, no API
                credentials required. See the "Known limitations of a mock
                run" section this command prints and `benchmark/README.md`
                for exactly what a mock run does and does not prove.

  --mode real   Talks to an already-running gateway at --gateway-url with
                real --api-key / --admin-key credentials. Per spec section
                28's explicit instruction, if that gateway is not reachable
                this does NOT invent numbers: it writes an UNMEASURED
                report template instead, so the dataset/scorer/runner
                infrastructure is still demonstrably exercised even with no
                live credentials available.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
from collections import deque
from dataclasses import asdict, dataclass
from pathlib import Path

import httpx
import yaml

BENCHMARK_DIR = Path(__file__).resolve().parent
REPO_ROOT = BENCHMARK_DIR.parent
GATEWAY_DIR = REPO_ROOT / "gateway"
SWITCHYARD_BINARY = REPO_ROOT / ".tools" / "switchyard" / "bin" / "switchyard-server.exe"
DEFAULT_TASKS_FILE = BENCHMARK_DIR / "tasks" / "tasks.yaml"
DEFAULT_OUT_DIR = BENCHMARK_DIR / "results"

sys.path.insert(0, str(BENCHMARK_DIR))
import judge as judge_mod  # noqa: E402
import report as report_mod  # noqa: E402
import scoring  # noqa: E402

MODES = {
    "A_fixed_efficient": "apex-efficient",
    "B_fixed_capable": "apex-capable",
    "C_apex_auto": "apex-auto",
}

BENCHMARK_API_KEY = "benchmark-inference-key"
BENCHMARK_ADMIN_KEY = "benchmark-admin-key"


@dataclass
class CallRecord:
    kind: str  # "task" or "judge"
    mode: str | None  # one of MODES keys, or None for judge calls
    task_id: str
    route_requested: str
    request_id: str | None
    http_status: int | None
    response_text: str | None
    client_latency_ms: float
    error: str | None
    # Reconciled from /admin/requests after all calls complete (spec 27:
    # cost/routing detail is always taken from the gateway's own telemetry,
    # never recomputed independently).
    selected_target: str | None = None
    selected_model: str | None = None
    input_tokens: int | None = None
    output_tokens: int | None = None
    routing_duration_ms: float | None = None
    provider_duration_ms: float | None = None
    total_duration_ms: float | None = None
    estimated_cost: float | None = None
    estimated_baseline_cost: float | None = None
    estimated_savings: float | None = None


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def _wait_for_http(
    url: str,
    timeout: float,
    process: subprocess.Popen | None = None,
    tail: "callable[[], str] | None" = None,
) -> None:
    deadline = time.monotonic() + timeout
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        if process is not None and process.poll() is not None:
            output = tail() if tail else ""
            raise RuntimeError(
                f"process exited early (code {process.returncode}) waiting for {url}:\n{output}"
            )
        try:
            response = httpx.get(url, timeout=0.5)
            if response.status_code < 500:
                return
        except httpx.TransportError as exc:
            last_error = exc
        time.sleep(0.1)
    raise RuntimeError(f"{url} did not become reachable within {timeout}s (last error: {last_error})")


class MockEnvironment:
    """Spawns mock upstream + switchyard sidecar (if built) + the gateway
    itself as real local subprocesses on real loopback sockets. Mirrors
    `gateway/tests/integration/conftest.py`'s `mock_upstream` /
    `switchyard_sidecar` fixtures, which are exercised by this repository's
    own test suite -- this class reuses that already-proven wiring rather
    than inventing a new one."""

    def __init__(self, *, verbose: bool = True):
        self.verbose = verbose
        self.tmp_dir = Path(tempfile.mkdtemp(prefix="apex-ai-router-benchmark-"))
        self.processes: list[subprocess.Popen] = []
        self._logs: dict[int, deque] = {}
        self.gateway_url: str | None = None
        self.switchyard_available = SWITCHYARD_BINARY.exists()

    def _log(self, message: str) -> None:
        if self.verbose:
            print(f"[benchmark] {message}", file=sys.stderr)

    def _tail(self, process: subprocess.Popen) -> str:
        return "\n".join(self._logs.get(id(process), []))

    def _drain(self, process: subprocess.Popen, label: str) -> None:
        """Continuously reads a subprocess's combined stdout/stderr into a
        bounded ring buffer. Without a reader, once the OS pipe buffer
        (commonly 64KB) fills up, the child blocks on its own next write --
        a real deadlock this benchmark hit empirically the first time it was
        run for more than a couple of calls (switchyard-server's per-request
        logging filled the pipe and hung mid-request). This must run for the
        whole life of every spawned process, not just be read lazily on
        crash."""
        log = self._logs[id(process)]
        try:
            for line in process.stdout:
                log.append(line.rstrip("\n"))
        except (ValueError, OSError):
            pass

    def _spawn(self, args: list[str], *, env: dict, cwd: Path | None = None, label: str = "process") -> subprocess.Popen:
        process = subprocess.Popen(
            args,
            cwd=str(cwd) if cwd else None,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        self.processes.append(process)
        self._logs[id(process)] = deque(maxlen=500)
        thread = threading.Thread(target=self._drain, args=(process, label), daemon=True)
        thread.start()
        return process

    def __enter__(self) -> "MockEnvironment":
        mock_port = _free_port()
        self._log(f"starting mock upstream on 127.0.0.1:{mock_port}")
        mock_process = self._spawn(
            [
                sys.executable,
                "-m",
                "uvicorn",
                "apex_ai_router.mocks.mock_model_server:app",
                "--host",
                "127.0.0.1",
                "--port",
                str(mock_port),
                "--log-level",
                "warning",
            ],
            env={**os.environ, "MOCK_MODEL_NAME": "mock-model", "MOCK_TIER": "shared"},
            cwd=GATEWAY_DIR,
            label="mock-upstream",
        )
        _wait_for_http(
            f"http://127.0.0.1:{mock_port}/health",
            timeout=20,
            process=mock_process,
            tail=lambda: self._tail(mock_process),
        )
        mock_upstream = f"http://127.0.0.1:{mock_port}"

        switchyard_target = f"http://127.0.0.1:{mock_port}"
        dummy_key_env = {
            "EFFICIENT_MODEL_API_KEY": "benchmark-dummy-key",
            "CAPABLE_MODEL_API_KEY": "benchmark-dummy-key",
            "JUDGE_MODEL_API_KEY": "benchmark-dummy-key",
        }

        switchyard_url = None
        if self.switchyard_available:
            switchyard_port = _free_port()
            routes_toml = self.tmp_dir / "routes.generated.toml"
            routes_toml.write_text(
                self._render_switchyard_routes_toml(switchyard_target), encoding="utf-8"
            )
            self._log(f"starting switchyard-server on 127.0.0.1:{switchyard_port}")
            switchyard_process = self._spawn(
                [
                    str(SWITCHYARD_BINARY),
                    "--config",
                    str(routes_toml),
                    "--host",
                    "127.0.0.1",
                    "--port",
                    str(switchyard_port),
                ],
                env={**os.environ, **dummy_key_env},
                label="switchyard-server",
            )
            switchyard_url = f"http://127.0.0.1:{switchyard_port}"
            _wait_for_http(
                f"{switchyard_url}/health",
                timeout=20,
                process=switchyard_process,
                tail=lambda: self._tail(switchyard_process),
            )
        else:
            self._log(
                "switchyard-server binary not found at "
                f"{SWITCHYARD_BINARY} -- apex-auto will be omitted from this run "
                "(see deploy/switchyard/README.md to build it)."
            )

        gateway_port = _free_port()
        routing_path = self.tmp_dir / "routing.yaml"
        routing_path.write_text(
            self._render_gateway_routing_yaml(mock_upstream, switchyard_url), encoding="utf-8"
        )
        telemetry_db = self.tmp_dir / "telemetry.db"

        gateway_env = {
            **os.environ,
            **dummy_key_env,
            "APEX_AI_ROUTER_ROUTING_CONFIG": str(routing_path),
            "APEX_AI_ROUTER_TELEMETRY_DB_PATH": str(telemetry_db),
            "APEX_AI_ROUTER_API_KEYS": BENCHMARK_API_KEY,
            "APEX_AI_ROUTER_ADMIN_API_KEY": BENCHMARK_ADMIN_KEY,
        }
        self._log(f"starting gateway on 127.0.0.1:{gateway_port}")
        gateway_process = self._spawn(
            [
                sys.executable,
                "-m",
                "uvicorn",
                "apex_ai_router.main:app",
                "--host",
                "127.0.0.1",
                "--port",
                str(gateway_port),
                "--log-level",
                "warning",
            ],
            env=gateway_env,
            cwd=GATEWAY_DIR,
            label="gateway",
        )
        self.gateway_url = f"http://127.0.0.1:{gateway_port}"
        _wait_for_http(
            f"{self.gateway_url}/ready",
            timeout=20,
            process=gateway_process,
            tail=lambda: self._tail(gateway_process),
        )
        return self

    def _render_switchyard_routes_toml(self, target_base_url: str) -> str:
        sys.path.insert(0, str(GATEWAY_DIR / "src"))
        from apex_ai_router.domain.model_target import RoutingConfig
        from apex_ai_router.routing.switchyard_config import render_routes_toml

        config = RoutingConfig.model_validate(
            {
                "routes": {
                    "apex-auto": {
                        "strategy": "llm_classifier",
                        "switchyard_target": "switchyard",
                        "efficient_target": "efficient",
                        "capable_target": "capable",
                        "judge_target": "judge",
                        "threshold": 0.5,
                    }
                },
                "targets": {
                    "efficient": {
                        "provider": "openai_compatible",
                        "model": "mock-efficient-v1",
                        "base_url": target_base_url,
                        "api_key_env": "EFFICIENT_MODEL_API_KEY",
                    },
                    "capable": {
                        "provider": "openai_compatible",
                        "model": "mock-capable-v1",
                        "base_url": target_base_url,
                        "api_key_env": "CAPABLE_MODEL_API_KEY",
                    },
                    "judge": {
                        "provider": "openai_compatible",
                        "model": "mock-judge-v1",
                        "base_url": target_base_url,
                        "api_key_env": "JUDGE_MODEL_API_KEY",
                    },
                    "switchyard": {
                        "provider": "switchyard",
                        "model": "apex-auto",
                        "base_url": "http://unused.invalid",
                    },
                },
            }
        )
        return render_routes_toml(config)

    def _render_gateway_routing_yaml(self, mock_upstream: str, switchyard_url: str | None) -> str:
        routes = {
            "apex-efficient": {"strategy": "fixed", "target": "efficient"},
            "apex-capable": {"strategy": "fixed", "target": "capable"},
        }
        if switchyard_url:
            routes["apex-auto"] = {
                "strategy": "llm_classifier",
                "switchyard_target": "switchyard",
                "efficient_target": "efficient",
                "capable_target": "capable",
                "judge_target": "judge",
                "threshold": 0.5,
            }
        targets = {
            "efficient": {
                "provider": "openai_compatible",
                "model": "mock-efficient-v1",
                "base_url": mock_upstream,
                "api_key_env": "EFFICIENT_MODEL_API_KEY",
            },
            "capable": {
                "provider": "openai_compatible",
                "model": "mock-capable-v1",
                "base_url": mock_upstream,
                "api_key_env": "CAPABLE_MODEL_API_KEY",
            },
            "judge": {
                "provider": "openai_compatible",
                "model": "mock-judge-v1",
                "base_url": mock_upstream,
                "api_key_env": "JUDGE_MODEL_API_KEY",
            },
        }
        if switchyard_url:
            targets["switchyard"] = {
                "provider": "switchyard",
                "model": "apex-auto",
                "base_url": switchyard_url,
            }
        return yaml.safe_dump({"routes": routes, "targets": targets}, sort_keys=False)

    def __exit__(self, *exc_info) -> None:
        for process in self.processes:
            process.kill()
        for process in self.processes:
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                pass
        shutil.rmtree(self.tmp_dir, ignore_errors=True)


def load_tasks(path: Path) -> list[dict]:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, list) or not data:
        raise ValueError(f"{path} did not contain a non-empty list of tasks")
    return data


def call_gateway(
    client: httpx.Client, gateway_url: str, api_key: str, route: str, prompt: str, timeout: float
) -> tuple[str | None, int | None, str | None, float, str | None]:
    """Returns (response_text, http_status, request_id, client_latency_ms, error)."""
    started = time.perf_counter()
    try:
        response = client.post(
            f"{gateway_url}/v1/chat/completions",
            headers={"Authorization": f"Bearer {api_key}"},
            json={"model": route, "messages": [{"role": "user", "content": prompt}]},
            timeout=timeout,
        )
    except httpx.HTTPError as exc:
        return None, None, None, (time.perf_counter() - started) * 1000, f"transport error: {exc}"

    latency_ms = (time.perf_counter() - started) * 1000
    request_id = response.headers.get("X-Request-Id")
    if response.status_code != 200:
        return None, response.status_code, request_id, latency_ms, f"HTTP {response.status_code}: {response.text[:300]}"

    try:
        payload = response.json()
        content = payload["choices"][0]["message"]["content"]
    except (json.JSONDecodeError, KeyError, IndexError, TypeError) as exc:
        return None, response.status_code, request_id, latency_ms, f"malformed response body: {exc}"

    return content, response.status_code, request_id, latency_ms, None


def fetch_admin_requests(client: httpx.Client, gateway_url: str, admin_key: str) -> dict[str, dict]:
    """Fetches up to the admin API's max page size (500) most recent
    requests and indexes them by request_id. A benchmark run this size
    (well under 500 total gateway calls) always fits in a single page; a
    `--mode real` run against a gateway with other concurrent traffic could
    in principle push some of this run's own requests past the 500 most
    recent -- the same limitation `apex-demo`'s Playground page documents
    (see HANDOFF.md), not solved differently here."""
    response = client.get(
        f"{gateway_url}/admin/requests",
        headers={"Authorization": f"Bearer {admin_key}"},
        params={"limit": 500, "offset": 0},
        timeout=30,
    )
    response.raise_for_status()
    rows = response.json().get("requests", [])
    return {row["request_id"]: row for row in rows if row.get("request_id")}


def _reconcile(record: CallRecord, admin_rows: dict[str, dict]) -> None:
    if not record.request_id:
        return
    row = admin_rows.get(record.request_id)
    if row is None:
        return
    record.selected_target = row.get("selected_target")
    record.selected_model = row.get("selected_model")
    record.input_tokens = row.get("input_tokens")
    record.output_tokens = row.get("output_tokens")
    record.routing_duration_ms = row.get("routing_duration_ms")
    record.provider_duration_ms = row.get("provider_duration_ms")
    record.total_duration_ms = row.get("total_duration_ms")
    record.estimated_cost = row.get("estimated_cost")
    record.estimated_baseline_cost = row.get("estimated_baseline_cost")
    record.estimated_savings = row.get("estimated_savings")


def run_benchmark(
    *,
    tasks: list[dict],
    gateway_url: str,
    api_key: str,
    admin_key: str,
    modes: dict[str, str],
    run_judge: bool,
    timeout: float,
) -> tuple[list[CallRecord], list[judge_mod.JudgeResult]]:
    call_records: list[CallRecord] = []
    judge_results: list[judge_mod.JudgeResult] = []

    with httpx.Client() as client:
        for task in tasks:
            for mode_name, route in modes.items():
                response_text, http_status, request_id, latency_ms, error = call_gateway(
                    client, gateway_url, api_key, route, task["prompt"], timeout
                )
                call_records.append(
                    CallRecord(
                        kind="task",
                        mode=mode_name,
                        task_id=task["id"],
                        route_requested=route,
                        request_id=request_id,
                        http_status=http_status,
                        response_text=response_text,
                        client_latency_ms=latency_ms,
                        error=error,
                    )
                )

                if run_judge and error is None and task.get("judge_eligible"):
                    judge_results.append(
                        judge_mod.run_judge(
                            client,
                            gateway_url,
                            api_key,
                            task,
                            response_text,
                            mode=mode_name,
                            timeout=timeout,
                        )
                    )

        admin_rows = fetch_admin_requests(client, gateway_url, admin_key)

    for record in call_records:
        _reconcile(record, admin_rows)

    return call_records, judge_results


def score_call_records(tasks_by_id: dict[str, dict], call_records: list[CallRecord]) -> list[dict]:
    scored = []
    for record in call_records:
        task = tasks_by_id[record.task_id]
        if record.error is not None:
            score_result = scoring.ScoreResult(task["scoring_method"], False, 0.0, record.error)
        else:
            score_result = scoring.score_task(
                task["scoring_method"], record.response_text, task.get("scoring_params", {})
            )
        scored.append(
            {
                "record": asdict(record),
                "task": {
                    "id": task["id"],
                    "category": task["category"],
                    "difficulty": task["difficulty"],
                },
                "deterministic_score": asdict(score_result),
            }
        )
    return scored


def main() -> int:
    parser = argparse.ArgumentParser(description="APEX AI Router benchmark harness")
    parser.add_argument("--mode", choices=["mock", "real"], required=True)
    parser.add_argument("--gateway-url", default="http://127.0.0.1:8080")
    parser.add_argument("--api-key", default="")
    parser.add_argument("--admin-key", default="")
    parser.add_argument("--judge", action="store_true", help="also run the LLM-judge pass")
    parser.add_argument("--tasks-file", type=Path, default=DEFAULT_TASKS_FILE)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--limit", type=int, default=None, help="only run the first N tasks (smoke testing)")
    parser.add_argument("--timeout", type=float, default=30.0, help="per-request HTTP timeout, seconds")
    args = parser.parse_args()

    tasks = load_tasks(args.tasks_file)
    if args.limit:
        tasks = tasks[: args.limit]
    tasks_by_id = {t["id"]: t for t in tasks}
    args.out_dir.mkdir(parents=True, exist_ok=True)

    if args.mode == "mock":
        with MockEnvironment() as env:
            modes = dict(MODES)
            if not env.switchyard_available:
                modes.pop("C_apex_auto")
            call_records, judge_results = run_benchmark(
                tasks=tasks,
                gateway_url=env.gateway_url,
                api_key=BENCHMARK_API_KEY,
                admin_key=BENCHMARK_ADMIN_KEY,
                modes=modes,
                run_judge=args.judge,
                timeout=args.timeout,
            )
        scored = score_call_records(tasks_by_id, call_records)
        report_mod.write_reports(
            out_dir=args.out_dir,
            mode="mock",
            tasks=tasks,
            scored=scored,
            judge_results=judge_results,
            modes_run=list(modes),
        )
        return 0

    # --mode real
    try:
        health = httpx.get(f"{args.gateway_url}/health", timeout=5)
        reachable = health.status_code == 200
    except httpx.HTTPError:
        reachable = False

    if not reachable or not args.api_key or not args.admin_key:
        report_mod.write_unmeasured_report(
            out_dir=args.out_dir,
            tasks=tasks,
            reason=(
                f"gateway at {args.gateway_url} was not reachable"
                if not reachable
                else "no --api-key/--admin-key supplied"
            ),
        )
        print(
            "Gateway unreachable or credentials missing -- wrote an UNMEASURED report "
            f"template to {args.out_dir} per spec section 28. No numbers were invented.",
            file=sys.stderr,
        )
        return 0

    call_records, judge_results = run_benchmark(
        tasks=tasks,
        gateway_url=args.gateway_url,
        api_key=args.api_key,
        admin_key=args.admin_key,
        modes=dict(MODES),
        run_judge=args.judge,
        timeout=args.timeout,
    )
    scored = score_call_records(tasks_by_id, call_records)
    report_mod.write_reports(
        out_dir=args.out_dir,
        mode="real",
        tasks=tasks,
        scored=scored,
        judge_results=judge_results,
        modes_run=list(MODES),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
