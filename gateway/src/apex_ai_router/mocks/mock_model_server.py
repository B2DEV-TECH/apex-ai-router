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
"""

import os
import time

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, PlainTextResponse

app = FastAPI(title="apex-ai-router mock model server")

MODEL_NAME = os.environ.get("MOCK_MODEL_NAME", "mock-model")
TIER = os.environ.get("MOCK_TIER", "unknown")
DEFAULT_BEHAVIOR = os.environ.get("MOCK_BEHAVIOR", "success")


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

    prompt_tokens = sum(len(str(m.get("content", ""))) // 4 or 1 for m in body.get("messages", []))

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

    completion_tokens = 20000 if behavior == "large_usage" else 12
    content = f"[mock:{TIER}:{model}] response to: {behavior}"
    return _chat_completion_body(content, _usage(prompt_tokens, completion_tokens), model)
