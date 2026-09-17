from unittest.mock import AsyncMock

import httpx
import pytest

from apex_ai_router.domain.errors import ProviderError
from apex_ai_router.domain.model_target import TargetConfig
from apex_ai_router.domain.request import ChatCompletionRequest
from apex_ai_router.providers import switchyard_adapter as provider_module
from apex_ai_router.providers.switchyard_adapter import SwitchyardProvider

_REQUEST = ChatCompletionRequest(
    model="apex-auto", messages=[{"role": "user", "content": "hi"}]
)
_TARGET = TargetConfig(provider="switchyard", model="apex-auto", base_url="http://test")


def _success_body() -> dict:
    return {
        "id": "chatcmpl-1",
        "object": "chat.completion",
        "created": 1,
        "model": "apex-auto",
        "choices": [
            {"index": 0, "message": {"role": "assistant", "content": "hi"}, "finish_reason": "stop"}
        ],
        "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
    }


async def test_success_returns_parsed_json():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=_success_body())

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    result = await provider.chat_completion(_REQUEST, _TARGET)

    assert result["id"] == "chatcmpl-1"


async def test_forwards_route_id_as_model():
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = request.content
        return httpx.Response(200, json=_success_body())

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    await provider.chat_completion(_REQUEST, _TARGET)

    import json

    assert json.loads(captured["body"])["model"] == "apex-auto"


async def test_504_raises_provider_timeout(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(504, json={"error": "deadline exceeded"})

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert exc_info.value.code == "provider_timeout"


async def test_503_response_state_limit_exceeded_raises_provider_unavailable(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(503, json={"error": "response_state_limit_exceeded"})

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert exc_info.value.code == "provider_unavailable"


async def test_409_response_state_conflict_raises_provider_error(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(409, json={"error": "response_state_conflict"})

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert exc_info.value.code == "provider_error"


async def test_retries_once_on_transport_error_then_succeeds(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())
    calls = {"n": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        if calls["n"] < 2:
            raise httpx.ConnectError("connection refused")
        return httpx.Response(200, json=_success_body())

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    result = await provider.chat_completion(_REQUEST, _TARGET)

    assert calls["n"] == 2
    assert result["id"] == "chatcmpl-1"


async def test_exhausts_single_retry_on_persistent_transport_error(monkeypatch):
    monkeypatch.setattr(provider_module.asyncio, "sleep", AsyncMock())
    calls = {"n": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        raise httpx.ConnectError("connection refused")

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert calls["n"] == 2  # initial attempt + 1 retry (lighter than the OpenAI adapter)
    assert exc_info.value.code == "provider_unavailable"


async def test_missing_base_url_raises_provider_unavailable():
    target = TargetConfig(provider="switchyard", model="apex-auto", base_url=None)
    provider = SwitchyardProvider()

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, target)

    assert exc_info.value.code == "provider_unavailable"


async def test_malformed_json_raises_provider_error():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200, content=b"not valid json", headers={"content-type": "application/json"}
        )

    provider = SwitchyardProvider(transport=httpx.MockTransport(handler))

    with pytest.raises(ProviderError) as exc_info:
        await provider.chat_completion(_REQUEST, _TARGET)

    assert exc_info.value.code == "provider_error"
