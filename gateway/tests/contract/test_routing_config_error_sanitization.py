"""Regression coverage for a bug found via a live clean-install smoke test
(Phase 10): `RoutingConfigError` (raised by `config.py` for a broken
routing.yaml/pricing.yaml, e.g. an unresolved `${VAR}` placeholder) is a
plain `Exception`, not a `GatewayError`, so it used to escape every
endpoint that loads routing config uncaught -- producing FastAPI's default
unsanitized 500 (a raw stack trace) instead of the spec-required
`{"error": {"code", "message", "request_id"}}` shape. Fixed by a global
`@app.exception_handler(RoutingConfigError)` in `main.py`. This test
exercises every affected call site: `GET /v1/models`,
`POST /v1/chat/completions`, and `GET /admin/routes`."""

from fastapi.testclient import TestClient

from apex_ai_router.config import Settings
from apex_ai_router.main import app

client = TestClient(app)

_BROKEN_ROUTING_YAML = """
routes:
  apex-efficient:
    strategy: fixed
    target: efficient
targets:
  efficient:
    provider: openai_compatible
    model: ${UNSET_MODEL_ID_ENV_VAR}
    base_url: http://example.test
"""


def _broken_settings(tmp_path, **overrides) -> Settings:
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_BROKEN_ROUTING_YAML, encoding="utf-8")
    return Settings(_env_file=None, routing_config=str(routing_path), **overrides)


def _assert_sanitized_routing_failure(response) -> None:
    assert response.status_code == 500
    body = response.json()
    assert body["error"]["code"] == "routing_failed"
    assert "request_id" in body["error"]
    assert "UNSET_MODEL_ID_ENV_VAR" in body["error"]["message"]


def test_list_models_reports_sanitized_error_for_broken_routing_config(
    tmp_path, override_settings
):
    override_settings(_broken_settings(tmp_path, api_keys="test-key"))

    response = client.get("/v1/models", headers={"Authorization": "Bearer test-key"})

    _assert_sanitized_routing_failure(response)


def test_chat_completions_reports_sanitized_error_for_broken_routing_config(
    tmp_path, override_settings
):
    override_settings(
        _broken_settings(
            tmp_path, api_keys="test-key", telemetry_db_path=str(tmp_path / "telemetry.db")
        )
    )

    response = client.post(
        "/v1/chat/completions",
        headers={"Authorization": "Bearer test-key"},
        json={"model": "apex-efficient", "messages": [{"role": "user", "content": "hi"}]},
    )

    _assert_sanitized_routing_failure(response)


def test_admin_routes_reports_sanitized_error_for_broken_routing_config(
    tmp_path, override_settings
):
    override_settings(_broken_settings(tmp_path, admin_api_key="admin-key"))

    response = client.get("/admin/routes", headers={"Authorization": "Bearer admin-key"})

    _assert_sanitized_routing_failure(response)
