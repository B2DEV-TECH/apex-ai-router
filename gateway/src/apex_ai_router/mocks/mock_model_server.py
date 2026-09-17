"""A minimal, deterministic OpenAI-compatible mock model server.

Used for local development (docker-compose) and integration tests so the
gateway can be exercised without any real, paid provider credentials (spec
sections 31 and 57). This is not a provider adapter — it is a fake upstream
that the gateway will call exactly like a real one over HTTP.

Behavior is chosen per request via an optional top-level ``mock_scenario``
field in the request body (ignored by any real OpenAI client), falling back
to the ``MOCK_BEHAVIOR`` environment variable, so a single running instance
can serve every fixture scenario integration tests need:

- ``success``        (default) a short canned answer with plausible usage.
- ``slow``            same as success, after an artificial delay.
- ``rate_limited``    HTTP 429 with an OpenAI-style error body.
- ``server_error``    HTTP 500 with an OpenAI-style error body.
- ``malformed``       HTTP 200 with a body that is not valid JSON.
- ``large_usage``     success, but with a very large token count.

Classifier (judge) requests are the one exception to the canned text. NeMo
Switchyard's ``llm_classifier`` routing asks the judge target for a JSON
verdict (``crux`` / ``primary_rule`` / ``capability_boundary`` /
``p_solve``) via an OpenAI ``response_format`` schema, and treats anything
unparseable as a fail-open to the capable target. So that the *real*
Switchyard routing policy can be exercised offline — instead of always
failing open — the mock answers those requests with a schema-valid verdict
derived from a transparent word-count heuristic (see ``_classifier_verdict``).
This is a stand-in for a judge model, not a claim about classification
quality: a real judge LLM is required for that.
"""

import json
import os
import time
from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, PlainTextResponse

app = FastAPI(title="apex-ai-router mock model server")

MODEL_NAME = os.environ.get("MOCK_MODEL_NAME", "mock-model")
TIER = os.environ.get("MOCK_TIER", "unknown")
DEFAULT_BEHAVIOR = os.environ.get("MOCK_BEHAVIOR", "success")

# Prompts with at most this many words (in the latest user message) are
# judged "supported" for the efficient model; longer prompts are judged
# "unsupported" so Switchyard routes them to the capable model. Deliberately
# simple and documented — the point is to be predictable, not smart.
JUDGE_WORD_LIMIT = int(os.environ.get("MOCK_JUDGE_WORD_LIMIT", "40"))


def _usage(prompt_tokens: int, completion_tokens: int) -> dict:
    return {
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": prompt_tokens + completion_tokens,
    }


def _chat_completion_body(content: str, usage: dict, model: str) -> dict:
    return {
        "id": "mock-chatcmpl-0001",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": content},
                "finish_reason": "stop",
            }
        ],
        "usage": usage,
    }


def _message_text(message: dict[str, Any]) -> str:
    """Flattens an OpenAI message ``content`` (string or content-part list)
    to plain text."""
    content = message.get("content", "")
    if isinstance(content, list):
        return " ".join(str(part.get("text", "")) for part in content if isinstance(part, dict))
    return str(content)


def _is_classifier_request(body: dict[str, Any]) -> bool:
    """True when the request looks like Switchyard's capability-classifier
    call: it carries a ``response_format`` and its system prompt asks for a
    ``p_solve`` forecast (the marker is stable across Switchyard's
    ``json_schema`` and ``json_object`` output modes)."""
    if not body.get("response_format"):
        return False
    return any(
        message.get("role") == "system" and "p_solve" in _message_text(message)
        for message in body.get("messages", [])
    )


def _classifier_verdict(body: dict[str, Any]) -> dict[str, Any]:
    """Deterministic ``CapabilityClassifierDecision`` verdict, valid against
    the schema Switchyard ships at the pinned commit
    (``crates/libsy/src/prompts/capability-classifier/schema.json``).

    The rule id and boundary are kept mutually consistent (SUP-* <->
    supported, LIM-* <-> unsupported) because Switchyard rejects
    inconsistent verdicts as fail-open."""
    user_messages = [m for m in body.get("messages", []) if m.get("role") == "user"]
    task_text = _message_text(user_messages[-1]) if user_messages else ""
    word_count = len(task_text.split())

    if word_count <= JUDGE_WORD_LIMIT:
        return {
            "crux": f"short, self-contained request ({word_count} words)",
            "primary_rule": "SUP-1",
            "capability_boundary": "supported",
            "p_solve": 0.9,
        }
    return {
        "crux": f"long, open-ended request ({word_count} words)",
        "primary_rule": "LIM-2",
        "capability_boundary": "unsupported",
        "p_solve": 0.1,
    }


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "model": MODEL_NAME, "tier": TIER}


@app.get("/v1/models")
async def list_models() -> dict:
    return {"object": "list", "data": [{"id": MODEL_NAME, "object": "model", "owned_by": "mock"}]}


@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    body = await request.json()
    model = body.get("model", MODEL_NAME)
    behavior = body.get("mock_scenario", DEFAULT_BEHAVIOR)

    prompt_tokens = sum(len(_message_text(m)) // 4 or 1 for m in body.get("messages", []))

    if behavior == "rate_limited":
        error = {"message": "mock rate limit", "type": "rate_limit_error", "code": "429"}
        return JSONResponse(status_code=429, content={"error": error})
    if behavior == "server_error":
        error = {"message": "mock server error", "type": "server_error", "code": "500"}
        return JSONResponse(status_code=500, content={"error": error})
    if behavior == "malformed":
        return PlainTextResponse(
            content="{not valid json", status_code=200, media_type="application/json"
        )

    if behavior == "slow":
        time.sleep(2)

    if behavior in ("success", "slow") and _is_classifier_request(body):
        verdict = json.dumps(_classifier_verdict(body))
        return _chat_completion_body(verdict, _usage(prompt_tokens, 32), model)

    completion_tokens = 20000 if behavior == "large_usage" else 12
    content = f"[mock:{TIER}:{model}] response to: {behavior}"
    return _chat_completion_body(content, _usage(prompt_tokens, completion_tokens), model)
