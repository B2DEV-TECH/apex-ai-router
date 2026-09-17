"""Phase 9 hardening checks (spec section 60): empirical validation of two
claims that were previously only asserted in docstrings/SECURITY.md rather
than tested -- `telemetry/store.py`'s single-event-loop concurrency
assumption, and the no-secret-content logging guarantee described in
`logging.py` and `SECURITY.md`."""

import asyncio
import logging

import httpx
from fastapi.testclient import TestClient

from apex_ai_router.config import Settings, get_settings, get_telemetry_store
from apex_ai_router.logging import JsonFormatter
from apex_ai_router.main import app

_ROUTING_TEMPLATE = """
routes:
  apex-efficient:
    strategy: fixed
    target: efficient
targets:
  efficient:
    provider: openai_compatible
    model: mock-efficient-v1
    base_url: {base_url}
    timeout_seconds: 5
"""

_SECRET_API_KEY = "sk-test-secret-should-never-appear-in-logs-9f3a1c"
_SECRET_PROMPT_MARKER = "PROMPT_MARKER_never_should_appear_in_logs_7b2e"


def _write_routing_config(tmp_path, base_url: str) -> str:
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_ROUTING_TEMPLATE.format(base_url=base_url), encoding="utf-8")
    return str(routing_path)


async def test_concurrent_requests_each_get_a_distinct_correctly_matched_telemetry_row(
    tmp_path, mock_upstream
):
    """Fires many truly-concurrent requests within a single asyncio event
    loop (via `httpx.ASGITransport`, unlike the thread-based `TestClient`
    used elsewhere) to empirically check `telemetry/store.py`'s documented
    claim that a single shared sqlite3 connection is safe under this
    project's single-event-loop, no-thread-pool-offloading execution model:
    no lost writes, no cross-request contamination of telemetry rows."""
    settings = Settings(
        _env_file=None,
        api_keys="test-key",
        routing_config=_write_routing_config(tmp_path, mock_upstream),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
    )
    app.dependency_overrides[get_settings] = lambda: settings

    concurrency = 20
    try:
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            responses = await asyncio.gather(
                *[
                    client.post(
                        "/v1/chat/completions",
                        headers={"Authorization": "Bearer test-key"},
                        json={
                            "model": "apex-efficient",
                            "messages": [{"role": "user", "content": f"concurrent-{i}"}],
                        },
                    )
                    for i in range(concurrency)
                ]
            )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert all(response.status_code == 200 for response in responses)

    request_ids = [response.headers["X-Request-Id"] for response in responses]
    assert len(set(request_ids)) == concurrency  # the middleware never reused a request id

    store = get_telemetry_store(settings)
    rows = store.list_requests(limit=concurrency + 5)

    assert len(rows) == concurrency  # every concurrent write landed -- none lost
    assert {row["request_id"] for row in rows} == set(request_ids)  # no cross-request mixing
    assert all(row["success"] for row in rows)
    assert all(row["selected_model"] == "mock-efficient-v1" for row in rows)


def test_successful_request_never_logs_the_api_key_or_prompt_content(
    tmp_path, mock_upstream, caplog
):
    """`api/openai_chat.py` has exactly one logging call site
    (`logger.info("chat completion routed", extra={...})`); this asserts the
    formatted JSON log line it produces never contains the bearer token or
    the message content, guarding against a future change accidentally
    widening what gets logged."""
    settings = Settings(
        _env_file=None,
        api_keys=_SECRET_API_KEY,
        routing_config=_write_routing_config(tmp_path, mock_upstream),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
    )
    app.dependency_overrides[get_settings] = lambda: settings
    client = TestClient(app)
    formatter = JsonFormatter()

    try:
        with caplog.at_level(logging.INFO):
            response = client.post(
                "/v1/chat/completions",
                headers={"Authorization": f"Bearer {_SECRET_API_KEY}"},
                json={
                    "model": "apex-efficient",
                    "messages": [{"role": "user", "content": _SECRET_PROMPT_MARKER}],
                },
            )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert response.status_code == 200

    formatted_lines = [formatter.format(record) for record in caplog.records]
    assert formatted_lines  # confirms the "chat completion routed" line was actually captured
    combined = "\n".join(formatted_lines)
    assert _SECRET_API_KEY not in combined
    assert _SECRET_PROMPT_MARKER not in combined
    assert "Authorization" not in combined


def test_authentication_failure_never_logs_the_attempted_key(tmp_path, mock_upstream, caplog):
    """Same guarantee on the reject path: an invalid bearer token must never
    reach a log line, including in a future change that might log the
    reason authentication failed."""
    settings = Settings(
        _env_file=None,
        api_keys="the-real-key",
        routing_config=_write_routing_config(tmp_path, mock_upstream),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
    )
    app.dependency_overrides[get_settings] = lambda: settings
    client = TestClient(app)
    formatter = JsonFormatter()

    try:
        with caplog.at_level(logging.INFO):
            response = client.post(
                "/v1/chat/completions",
                headers={"Authorization": f"Bearer {_SECRET_API_KEY}"},
                json={"model": "apex-efficient", "messages": [{"role": "user", "content": "hi"}]},
            )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert response.status_code == 401

    formatted_lines = [formatter.format(record) for record in caplog.records]
    combined = "\n".join(formatted_lines)
    assert _SECRET_API_KEY not in combined
