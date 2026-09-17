from fastapi.testclient import TestClient

from apex_ai_router.config import Settings
from apex_ai_router.main import app

client = TestClient(app)


def test_health_returns_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ready_returns_not_ready_when_routing_config_is_missing(tmp_path, override_settings):
    missing_path = tmp_path / "does-not-exist.yaml"
    override_settings(Settings(_env_file=None, routing_config=str(missing_path)))

    response = client.get("/ready")

    assert response.status_code == 503
    body = response.json()
    assert body["status"] == "not_ready"
    assert body["checks"]["settings_loaded"] is True
    assert body["checks"]["routing_config_loaded"] is False
    assert "routing_config_error" in body["checks"]


def test_ready_returns_ready_when_routing_config_resolves(tmp_path, override_settings):
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(
        """
routes:
  apex-efficient:
    strategy: fixed
    target: efficient
targets:
  efficient:
    provider: openai_compatible
    model: test-efficient-model
    base_url: http://example.test
""",
        encoding="utf-8",
    )
    override_settings(Settings(_env_file=None, routing_config=str(routing_path)))

    response = client.get("/ready")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ready"
    assert body["checks"]["routing_config_loaded"] is True
    assert body["checks"]["routes_configured"] == 1
    assert "environment" in body
