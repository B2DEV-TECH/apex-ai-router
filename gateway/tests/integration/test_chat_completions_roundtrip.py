"""One real end-to-end round trip: gateway -> RoutingService -> provider
adapter -> real HTTP call to the mock model server -> validated response.
Error-path behavior (auth, validation, routing) is already covered without
any network in `tests/contract/`; this is the single test proving the real
HTTP wiring works."""

from fastapi.testclient import TestClient

from apex_ai_router.config import Settings, get_settings
from apex_ai_router.main import app

client = TestClient(app)

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


def test_chat_completion_round_trip_through_real_mock_server(tmp_path, mock_upstream):
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_ROUTING_TEMPLATE.format(base_url=mock_upstream), encoding="utf-8")
    settings = Settings(
        _env_file=None,
        api_keys="test-key",
        routing_config=str(routing_path),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
    )
    app.dependency_overrides[get_settings] = lambda: settings

    try:
        response = client.post(
            "/v1/chat/completions",
            headers={"Authorization": "Bearer test-key"},
            json={"model": "apex-efficient", "messages": [{"role": "user", "content": "hi"}]},
        )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert response.status_code == 200
    body = response.json()
    assert body["model"] == "mock-efficient-v1"
    assert body["choices"][0]["message"]["role"] == "assistant"
    assert "mock:" in body["choices"][0]["message"]["content"]
    assert body["usage"]["total_tokens"] > 0
