"""Exercises the mock upstream model server used by docker-compose and by
future routing integration tests (spec section 57 fixture scenarios)."""

from fastapi.testclient import TestClient

from apex_ai_router.mocks.mock_model_server import app

client = TestClient(app)


def _chat_request(scenario: str) -> dict:
    return {
        "model": "mock-model",
        "messages": [{"role": "user", "content": "hello"}],
        "mock_scenario": scenario,
    }


def test_success_scenario_returns_usage_and_choice():
    response = client.post("/v1/chat/completions", json=_chat_request("success"))
    assert response.status_code == 200
    body = response.json()
    assert body["choices"][0]["message"]["role"] == "assistant"
    assert body["usage"]["total_tokens"] > 0


def test_rate_limited_scenario_returns_429():
    response = client.post("/v1/chat/completions", json=_chat_request("rate_limited"))
    assert response.status_code == 429
    assert response.json()["error"]["type"] == "rate_limit_error"


def test_server_error_scenario_returns_500():
    response = client.post("/v1/chat/completions", json=_chat_request("server_error"))
    assert response.status_code == 500


def test_malformed_scenario_returns_invalid_json():
    response = client.post("/v1/chat/completions", json=_chat_request("malformed"))
    assert response.status_code == 200
    import json

    try:
        json.loads(response.text)
        raised = False
    except json.JSONDecodeError:
        raised = True
    assert raised, "malformed scenario must not be valid JSON"


def test_large_usage_scenario_returns_large_completion_tokens():
    response = client.post("/v1/chat/completions", json=_chat_request("large_usage"))
    assert response.status_code == 200
    assert response.json()["usage"]["completion_tokens"] >= 20000


def test_health_reports_configured_model_and_tier():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert "model" in body and "tier" in body
