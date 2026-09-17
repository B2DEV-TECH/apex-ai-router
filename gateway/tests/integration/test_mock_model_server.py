"""Exercises the mock upstream model server used by docker-compose and by
future routing integration tests (spec section 57 fixture scenarios)."""

import json

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


# --- Classifier (judge) requests -------------------------------------------
# Shape of the call NeMo Switchyard's llm_classifier makes to the judge
# target: a system prompt asking for a p_solve forecast plus a
# CapabilityClassifierDecision response_format schema.

_CLASSIFIER_SYSTEM_PROMPT = (
    "You are a task-level probability forecaster for a model router. Estimate p_solve last."
)


def _classifier_request(task: str) -> dict:
    return {
        "model": "mock-judge-v1",
        "messages": [
            {"role": "system", "content": _CLASSIFIER_SYSTEM_PROMPT},
            {"role": "user", "content": task},
        ],
        "response_format": {
            "type": "json_schema",
            "json_schema": {"name": "CapabilityClassifierDecision", "strict": True},
        },
    }


def _verdict(response) -> dict:
    assert response.status_code == 200
    return json.loads(response.json()["choices"][0]["message"]["content"])


def test_classifier_request_short_prompt_is_supported():
    verdict = _verdict(client.post("/v1/chat/completions", json=_classifier_request("hi")))
    assert verdict["capability_boundary"] == "supported"
    assert verdict["primary_rule"] == "SUP-1"
    assert verdict["p_solve"] >= 0.5
    assert verdict["crux"]


def test_classifier_request_long_prompt_is_unsupported():
    long_task = " ".join(["word"] * 41)
    verdict = _verdict(client.post("/v1/chat/completions", json=_classifier_request(long_task)))
    assert verdict["capability_boundary"] == "unsupported"
    assert verdict["primary_rule"] == "LIM-2"
    assert verdict["p_solve"] < 0.5


def test_classifier_request_handles_content_part_lists():
    request = _classifier_request("hi")
    request["messages"][1]["content"] = [{"type": "text", "text": "hi"}]
    verdict = _verdict(client.post("/v1/chat/completions", json=request))
    assert verdict["capability_boundary"] == "supported"


def test_plain_request_with_response_format_still_gets_canned_text():
    # response_format alone is not a classifier call: only the p_solve
    # system prompt Switchyard sends turns on the verdict behavior.
    request = _chat_request("success")
    request["response_format"] = {"type": "json_object"}
    response = client.post("/v1/chat/completions", json=request)
    assert response.status_code == 200
    assert "[mock:" in response.json()["choices"][0]["message"]["content"]


def test_classifier_request_error_scenarios_still_apply():
    request = _classifier_request("hi")
    request["mock_scenario"] = "server_error"
    assert client.post("/v1/chat/completions", json=request).status_code == 500
