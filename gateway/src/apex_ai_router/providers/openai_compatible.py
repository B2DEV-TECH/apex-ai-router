"""OpenAI-compatible provider adapter (spec section 9).

Calls a real upstream `/v1/chat/completions` endpoint — a provider's own
OpenAI-compatible gateway, or a local mock model server. Owns transport,
timeouts, and the bounded retry policy from spec section 24; provider
credentials never leave this module.
"""

import asyncio
import os

import httpx

from apex_ai_router.domain.errors import ProviderError
from apex_ai_router.domain.model_target import TargetConfig
from apex_ai_router.domain.request import ChatCompletionRequest
from apex_ai_router.providers.base import ProviderResult

_RETRYABLE_STATUS_CODES = {429, 502, 503, 504}
_MAX_RETRIES = 2
_BACKOFF_SECONDS = 0.5


class OpenAICompatibleProvider:
    def __init__(
        self,
        *,
        timeout_seconds: float = 30.0,
        transport: httpx.AsyncBaseTransport | None = None,
    ):
        self._timeout_seconds = timeout_seconds
        self._transport = transport

    async def chat_completion(
        self, request: ChatCompletionRequest, target: TargetConfig
    ) -> ProviderResult:
        if not target.base_url:
            raise ProviderError(
                "provider_unavailable",
                f"No base_url configured for target model '{target.model}'.",
                retry_count=0,
            )

        api_key = os.environ.get(target.api_key_env, "") if target.api_key_env else ""
        headers = {"content-type": "application/json"}
        if api_key:
            headers["authorization"] = f"Bearer {api_key}"

        payload = request.model_dump(mode="json", exclude={"model", "stream"}, exclude_none=True)
        payload["model"] = target.model

        async with httpx.AsyncClient(
            base_url=target.base_url,
            timeout=self._timeout_seconds,
            transport=self._transport,
        ) as client:
            last_error: ProviderError | None = None
            for attempt in range(_MAX_RETRIES + 1):
                try:
                    response = await client.post(
                        "/v1/chat/completions", json=payload, headers=headers
                    )
                except httpx.TimeoutException as exc:
                    last_error = ProviderError(
                        "provider_timeout",
                        "The upstream model provider timed out.",
                        retry_count=attempt,
                    )
                    if attempt < _MAX_RETRIES:
                        await asyncio.sleep(_BACKOFF_SECONDS * (attempt + 1))
                        continue
                    raise last_error from exc
                except httpx.TransportError as exc:
                    last_error = ProviderError(
                        "provider_unavailable",
                        "The upstream model provider is unreachable.",
                        retry_count=attempt,
                    )
                    if attempt < _MAX_RETRIES:
                        await asyncio.sleep(_BACKOFF_SECONDS * (attempt + 1))
                        continue
                    raise last_error from exc

                if response.status_code == 200:
                    try:
                        return ProviderResult(body=response.json(), retry_count=attempt)
                    except ValueError as exc:
                        raise ProviderError(
                            "provider_error",
                            "The upstream model provider returned an invalid response.",
                            retry_count=attempt,
                        ) from exc

                if response.status_code in _RETRYABLE_STATUS_CODES and attempt < _MAX_RETRIES:
                    await asyncio.sleep(_BACKOFF_SECONDS * (attempt + 1))
                    continue

                if response.status_code == 429:
                    raise ProviderError(
                        "provider_unavailable",
                        "The upstream model provider is rate limiting requests.",
                        retry_count=attempt,
                    )
                if 500 <= response.status_code < 600:
                    raise ProviderError(
                        "provider_error",
                        "The upstream model provider returned an error.",
                        retry_count=attempt,
                    )
                raise ProviderError(
                    "provider_error",
                    f"The upstream model provider returned HTTP {response.status_code}.",
                    retry_count=attempt,
                )

        raise last_error or ProviderError(
            "provider_error", "The upstream model provider request failed."
        )
