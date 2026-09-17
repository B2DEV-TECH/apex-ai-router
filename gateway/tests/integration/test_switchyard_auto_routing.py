"""Real end-to-end test of `apex-auto`: gateway -> RoutingService ->
SwitchyardProvider -> real, compiled `switchyard-server` binary -> real HTTP
calls to the mock model server -> validated response.

This proves the actual wiring (config rendering, sidecar startup, the
OpenAI-compatible HTTP hop in both directions) with no mocked transport
anywhere in the chain, and that Switchyard's real `llm_classifier` policy
runs: the mock judge answers the classifier call with a schema-valid
verdict derived from a word-count heuristic (see
`mocks/mock_model_server.py`), so a short prompt lands on the efficient
target and a long one on the capable target. It intentionally does NOT
prove classification *quality* -- the verdict is a deterministic stand-in,
not a judge model's opinion. Verifying real decision quality requires a
real judge LLM and is out of scope for an offline test suite; see
HANDOFF.md.

Skips automatically if `.tools/switchyard/bin/switchyard-server(.exe)` has
not been built locally (see deploy/switchyard/README.md) -- CI should build
it before running this suite.
"""

from fastapi.testclient import TestClient

from apex_ai_router.config import Settings, get_settings
from apex_ai_router.main import app

client = TestClient(app)

_ROUTING_TEMPLATE = """
routes:
  apex-auto:
    strategy: llm_classifier
    switchyard_target: switchyard
    efficient_target: efficient
    capable_target: capable
    judge_target: judge
    threshold: 0.5
targets:
  efficient:
    provider: openai_compatible
    model: mock-efficient-v1
    base_url: {mock_upstream}
  capable:
    provider: openai_compatible
    model: mock-capable-v1
    base_url: {mock_upstream}
  judge:
    provider: openai_compatible
    model: mock-judge-v1
    base_url: {mock_upstream}
  switchyard:
    provider: switchyard
    model: apex-auto
    base_url: {switchyard_base_url}
    timeout_seconds: 10
"""

_SHORT_PROMPT = "hi"
# Over the mock judge's 40-word limit, so its verdict is "unsupported".
_LONG_PROMPT = " ".join(f"word{i}" for i in range(60))


def _post_auto(prompt: str):
    return client.post(
        "/v1/chat/completions",
        headers={"Authorization": "Bearer test-key"},
        json={"model": "apex-auto", "messages": [{"role": "user", "content": prompt}]},
    )


def test_apex_auto_routes_through_real_switchyard_server(
    tmp_path, mock_upstream, switchyard_sidecar
):
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(
        _ROUTING_TEMPLATE.format(
            mock_upstream=mock_upstream, switchyard_base_url=switchyard_sidecar
        ),
        encoding="utf-8",
    )
    settings = Settings(
        _env_file=None,
        api_keys="test-key",
        admin_api_key="admin-key",
        routing_config=str(routing_path),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
    )
    app.dependency_overrides[get_settings] = lambda: settings

    try:
        short_response = _post_auto(_SHORT_PROMPT)
        long_response = _post_auto(_LONG_PROMPT)
        requests_response = client.get(
            "/admin/requests", headers={"Authorization": "Bearer admin-key"}
        )
        backends_response = client.get(
            "/admin/metrics/backends", headers={"Authorization": "Bearer admin-key"}
        )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert short_response.status_code == 200
    short_body = short_response.json()
    # Switchyard accepted the mock judge's "supported" verdict and picked the
    # weak (efficient) target; its reply carries the backend's own model id,
    # and the mock echoes the model id it was asked for into the content.
    assert short_body["model"] == "mock-efficient-v1"
    assert short_body["choices"][0]["message"]["role"] == "assistant"
    assert "mock-efficient-v1" in short_body["choices"][0]["message"]["content"]
    assert short_body["usage"]["total_tokens"] > 0

    assert long_response.status_code == 200
    long_body = long_response.json()
    # "unsupported" verdict -> strong (capable) target.
    assert long_body["model"] == "mock-capable-v1"
    assert "mock-capable-v1" in long_body["choices"][0]["message"]["content"]

    # The gateway records what the sidecar picked as `upstream_model` while
    # `selected_model` stays the virtual route target (HANDOFF.md section 2).
    assert requests_response.status_code == 200
    rows = requests_response.json()["requests"]
    assert [row["upstream_model"] for row in rows] == ["mock-capable-v1", "mock-efficient-v1"]
    assert {row["selected_model"] for row in rows} == {"apex-auto"}
    assert {row["selected_target"] for row in rows} == {"switchyard"}

    assert backends_response.status_code == 200
    backends = backends_response.json()["backends"]
    assert {(row["route"], row["upstream_model"], row["requests"]) for row in backends} == {
        ("apex-auto", "mock-efficient-v1", 1),
        ("apex-auto", "mock-capable-v1", 1),
    }
