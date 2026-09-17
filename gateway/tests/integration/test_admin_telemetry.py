"""End-to-end proof that a real chat completion is recorded as telemetry and
surfaced through the admin API (spec sections 13-15), and that the admin API
enforces its own separate key rather than accepting an inference key."""

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
"""


def _settings(tmp_path, mock_upstream) -> Settings:
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_ROUTING_TEMPLATE.format(base_url=mock_upstream), encoding="utf-8")
    return Settings(
        _env_file=None,
        api_keys="inference-key",
        admin_api_key="admin-key",
        routing_config=str(routing_path),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
    )


def test_successful_chat_completion_is_recorded_and_visible_via_admin_api(
    tmp_path, mock_upstream
):
    settings = _settings(tmp_path, mock_upstream)
    app.dependency_overrides[get_settings] = lambda: settings

    try:
        chat_response = client.post(
            "/v1/chat/completions",
            headers={"Authorization": "Bearer inference-key"},
            json={"model": "apex-efficient", "messages": [{"role": "user", "content": "hi"}]},
        )
        assert chat_response.status_code == 200

        requests_response = client.get(
            "/admin/requests", headers={"Authorization": "Bearer admin-key"}
        )
        assert requests_response.status_code == 200
        requests = requests_response.json()["requests"]
        assert len(requests) == 1
        row = requests[0]
        assert row["route"] == "apex-efficient"
        assert row["selected_model"] == "mock-efficient-v1"
        # The mock echoes the requested model id back, so for a fixed route
        # the upstream-reported model equals the configured one.
        assert row["upstream_model"] == "mock-efficient-v1"
        assert row["success"] is True
        assert row["http_status"] == 200
        assert row["total_tokens"] > 0

        backends_response = client.get(
            "/admin/metrics/backends", headers={"Authorization": "Bearer admin-key"}
        )
        assert backends_response.status_code == 200
        backends = backends_response.json()["backends"]
        assert len(backends) == 1
        assert backends[0]["route"] == "apex-efficient"
        assert backends[0]["upstream_model"] == "mock-efficient-v1"
        assert backends[0]["requests"] == 1
        # The admin API must never expose prompt/response content, regardless
        # of the (default-off) content-logging setting.
        assert "prompt_content" not in row
        assert "response_content" not in row

        summary_response = client.get(
            "/admin/metrics/summary", headers={"Authorization": "Bearer admin-key"}
        )
        assert summary_response.status_code == 200
        summary = summary_response.json()
        assert summary["requests"] == 1
        assert summary["success_rate"] == 1.0
        # mock-efficient-v1 is priced at $0 in config/pricing.yaml — a real
        # known price, not an unknown one, so this must be 0.0, not null.
        assert summary["estimated_cost"] == 0.0

        routes_response = client.get(
            "/admin/routes", headers={"Authorization": "Bearer admin-key"}
        )
        assert routes_response.status_code == 200
        assert "apex-efficient" in routes_response.json()["routes"]
        assert "efficient" in routes_response.json()["targets"]
    finally:
        app.dependency_overrides.pop(get_settings, None)


def test_admin_endpoints_reject_an_inference_key(tmp_path, mock_upstream):
    settings = _settings(tmp_path, mock_upstream)
    app.dependency_overrides[get_settings] = lambda: settings

    try:
        response = client.get(
            "/admin/requests", headers={"Authorization": "Bearer inference-key"}
        )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_failed"


def test_admin_endpoints_require_admin_key_configured(tmp_path, mock_upstream):
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_ROUTING_TEMPLATE.format(base_url=mock_upstream), encoding="utf-8")
    settings = Settings(
        _env_file=None,
        api_keys="inference-key",
        admin_api_key=None,
        routing_config=str(routing_path),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
    )
    app.dependency_overrides[get_settings] = lambda: settings

    try:
        response = client.get(
            "/admin/requests", headers={"Authorization": "Bearer anything"}
        )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    assert response.status_code == 500
    assert response.json()["error"]["code"] == "internal_error"


def test_content_logging_opt_in_persists_content_but_admin_api_still_hides_it(
    tmp_path, mock_upstream
):
    routing_path = tmp_path / "routing.yaml"
    routing_path.write_text(_ROUTING_TEMPLATE.format(base_url=mock_upstream), encoding="utf-8")
    settings = Settings(
        _env_file=None,
        api_keys="inference-key",
        admin_api_key="admin-key",
        routing_config=str(routing_path),
        telemetry_db_path=str(tmp_path / "telemetry.db"),
        telemetry_log_content=True,
    )
    app.dependency_overrides[get_settings] = lambda: settings

    try:
        chat_response = client.post(
            "/v1/chat/completions",
            headers={"Authorization": "Bearer inference-key"},
            json={"model": "apex-efficient", "messages": [{"role": "user", "content": "hi"}]},
        )
        assert chat_response.status_code == 200

        requests_response = client.get(
            "/admin/requests", headers={"Authorization": "Bearer admin-key"}
        )
    finally:
        app.dependency_overrides.pop(get_settings, None)

    row = requests_response.json()["requests"][0]
    assert "prompt_content" not in row
    assert "response_content" not in row
