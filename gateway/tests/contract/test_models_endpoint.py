from fastapi.testclient import TestClient

from apex_ai_router.config import Settings
from apex_ai_router.main import app

client = TestClient(app)

_ROUTING_YAML = """
routes:
  apex-efficient:
    strategy: fixed
    target: efficient
  apex-capable:
    strategy: fixed
    target: capable
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


def _routing_settings(tmp_path, **overrides) -> Settings:
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_ROUTING_YAML, encoding="utf-8")
    return Settings(_env_file=None, routing_config=str(routing_path), **overrides)


def test_list_models_requires_auth(tmp_path, override_settings):
    override_settings(_routing_settings(tmp_path, api_keys="test-key"))

    response = client.get("/v1/models")

    assert response.status_code == 401
    body = response.json()
    assert body["error"]["code"] == "authentication_failed"
    assert "request_id" in body["error"]


def test_list_models_returns_internal_error_when_no_keys_configured(tmp_path, override_settings):
    override_settings(_routing_settings(tmp_path, api_keys=""))

    response = client.get("/v1/models", headers={"Authorization": "Bearer anything"})

    assert response.status_code == 500
    assert response.json()["error"]["code"] == "internal_error"


def test_list_models_returns_configured_virtual_models(tmp_path, override_settings):
    override_settings(_routing_settings(tmp_path, api_keys="test-key"))

    response = client.get("/v1/models", headers={"Authorization": "Bearer test-key"})

    assert response.status_code == 200
    ids = {item["id"] for item in response.json()["data"]}
    assert ids == {"apex-efficient", "apex-capable"}
