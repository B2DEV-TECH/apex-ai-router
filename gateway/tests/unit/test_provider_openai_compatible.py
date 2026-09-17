from unittest.mock import AsyncMock

import httpx
import pytest

from apex_ai_router.domain.errors import ProviderError
from apex_ai_router.domain.model_target import TargetConfig
from apex_ai_router.domain.request import ChatCompletionRequest
from apex_ai_router.providers import openai_compatible as provider_module
from apex_ai_router.providers.openai_compatible import OpenAICompatibleProvider

_REQUEST = ChatCompletionRequest(
    model="apex-efficient", messages=[{"role": "user", "content": "hi"}]
)
_TARGET = TargetConfig(provider="openai_compatible", model="mock-model", base_url="http://test")


def _success_body() -> dict:
    return {
        "id": "chatcmpl-1",
        "object": "chat.completion",
        "created": 1,
        "model": "mock-model",
        "choices": [
            {"index": 0, "message": {"role": "assistant", "content": "hi"}, "finish_reason": "stop"}
        ],
        "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
    }


async def test_success_returns_parsed_json():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=_success_body())

    provider = OpenAICompatibleProvider(transport=httpx.MockTransport(handler))

    result = await provider.chat_completion(_REQUEST, _TARGET)

    assert result["id"] == "chatcmpl-1"


async def test_retries_on_503_then_succeeds(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())
    calls = {"n": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        if calls["n"] < 2:
            return httpx.Response(503, json={"error": "boom"})
        return httpx.Response(200, json=_success_body())

    provider = OpenAICompatibleProvider(transport=httpx.MockTransport(handler))

    result = await provider.chat_completion(_REQUEST, _TARGET)

    assert calls["n"] == 2
    assert result["id"] == "chatcmpl-1"


async def test_exhausts_retries_on_persistent_503(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())
    calls = {"n": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        return httpx.Response(503, json={"error": "boom"})

    provider = OpenAICompatibleProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert calls["n"] == 3  # initial attempt + 2 retries
    assert exc_info.value.code == "provider_error"


async def test_rate_limited_raises_provider_unavailable(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(429, json={"error": "slow down"})

    provider = OpenAICompatibleProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert exc_info.value.code == "provider_unavailable"


async def test_non_retryable_status_raises_immediately():
    calls = {"n": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        return httpx.Response(418, json={"error": "teapot"})

    provider = OpenAICompatibleProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert calls["n"] == 1
    assert exc_info.value.code == "provider_error"


async def test_malformed_json_raises_provider_error():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200, content=b"not valid json", headers={"content-type": "application/json"}
        )

    provider = OpenAICompatibleProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert exc_info.value.code == "provider_error"


async def test_missing_base_url_raises_provider_unavailable():
    target = TargetConfig(provider="openai_compatible", model="mock-model", base_url=None)
    provider = OpenAICompatibleProvider()

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, target)

    assert exc_info.value.code == "provider_unavailable"
