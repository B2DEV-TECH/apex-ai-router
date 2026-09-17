"""Real end-to-end test of `apex-auto`: gateway -> RoutingService ->
SwitchyardProvider -> real, compiled `switchyard-server` binary -> real HTTP
calls to the mock model server -> validated response.

This proves the actual wiring (config rendering, sidecar startup, the
OpenAI-compatible HTTP hop in both directions) with no mocked transport
anywhere in the chain. It intentionally does NOT prove classification
*quality*: the mock upstream returns a plain-text completion for every
call, including the judge call, so Switchyard's classifier verdict parsing
fails and — per its own documented fail-open behavior ("An invalid,
inconsistent, or unparseable verdict routes to strong_target",
docs/routing_algorithms/llm_classifier_routing.md at the pinned commit) —
every request deterministically lands on the capable target. Verifying the
judge's actual decision quality would require a real LLM and is out of
scope for an offline test suite; see HANDOFF.md.

Skips automatically if `.tools/switchyard/bin/switchyard-server(.exe)` has
not been built locally (see deploy/switchyard/README.md) — CI should build
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
    settings = Settings(_env_file=None, api_keys="test-key", routing_config=str(routing_path))
    app.dependency_overrides[get_settings] = lambda: settings

    try:
        response = client.post(
            "/v1/chat/completions",
            headers={"Authorization": "Bearer test-key"},
            json={"model": "apex-auto", "messages": [{"role": "user", "content": "hi"}]},
        )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert response.status_code == 200
    body = response.json()
    # The mock upstream can't produce a valid classifier verdict, so
    # switchyard-server fails open to strong_target (capable) — see the
    # module docstring.
    assert body["model"] == "mock-capable-v1"
    assert body["choices"][0]["message"]["role"] == "assistant"
    assert "mock:" in body["choices"][0]["message"]["content"]
    assert body["usage"]["total_tokens"] > 0
