from fastapi.testclient import TestClient

from apex_ai_router.config import Settings
from apex_ai_router.main import app

client = TestClient(app)

_ROUTING_YAML = """
routes:
  apex-auto:
    strategy: llm_classifier
    efficient_target: efficient
    capable_target: capable
  apex-efficient:
    strategy: fixed
    target: efficient
targets:
  efficient:
    provider: openai_compatible
    model: test-efficient-model
    base_url: http://example.test
  capable:
    provider: openai_compatible
    model: test-capable-model
    base_url: http://example.test
"""

_HEADERS = {"Authorization": "Bearer test-key"}


def _override(tmp_path, override_settings) -> None:
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_ROUTING_YAML, encoding="utf-8")
    override_settings(
        Settings(
            _env_file=None,
            routing_config=str(routing_path),
            api_keys="test-key",
            telemetry_db_path=str(tmp_path / "telemetry.db"),
        )
    )


def test_requires_auth(tmp_path, override_settings):
    _override(tmp_path, override_settings)

    response = client.post(
        "/v1/chat/completions",
        json={"model": "apex-efficient", "messages": [{"role": "user", "content": "hi"}]},
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_failed"


def test_rejects_unknown_field_as_invalid_request(tmp_path, override_settings):
    _override(tmp_path, override_settings)

    response = client.post(
        "/v1/chat/completions",
        headers=_HEADERS,
        json={
            "model": "apex-efficient",
            "messages": [{"role": "user", "content": "hi"}],
            "frequency_penalty": 0.5,
        },
    )

    assert response.status_code == 400
    body = response.json()
    assert body["error"]["code"] == "invalid_request"
    assert "request_id" in body["error"]


def test_rejects_empty_messages(tmp_path, override_settings):
    _override(tmp_path, override_settings)

    response = client.post(
        "/v1/chat/completions",
        headers=_HEADERS,
        json={"model": "apex-efficient", "messages": []},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


def test_stream_true_returns_unsupported_parameter(tmp_path, override_settings):
    _override(tmp_path, override_settings)

    response = client.post(
        "/v1/chat/completions",
        headers=_HEADERS,
        json={
            "model": "apex-efficient",
            "messages": [{"role": "user", "content": "hi"}],
            "stream": True,
        },
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "unsupported_parameter"


def test_unknown_model_returns_route_not_found(tmp_path, override_settings):
    _override(tmp_path, override_settings)

    response = client.post(
        "/v1/chat/completions",
        headers=_HEADERS,
        json={"model": "does-not-exist", "messages": [{"role": "user", "content": "hi"}]},
    )

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "route_not_found"


def test_apex_auto_without_switchyard_target_returns_routing_failed(tmp_path, override_settings):
    # This fixture's apex-auto route intentionally omits `switchyard_target`
    # (a real, if misconfigured, operator mistake) so this test stays a pure
    # validation-layer check with no network call to a switchyard sidecar —
    # see tests/integration/test_switchyard_auto_routing.py for the real,
    # fully-wired end-to-end path through an actual switchyard-server.
    _override(tmp_path, override_settings)

    response = client.post(
        "/v1/chat/completions",
        headers=_HEADERS,
        json={"model": "apex-auto", "messages": [{"role": "user", "content": "hi"}]},
    )

    assert response.status_code == 500
    assert response.json()["error"]["code"] == "routing_failed"
