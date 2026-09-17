"""Switchyard provider adapter (spec section 9, Phase 3).

Forwards `apex-auto` requests to a `switchyard-server` sidecar over its
OpenAI Chat Completions-compatible endpoint. Switchyard performs the actual
efficient/capable classification and upstream call itself (per
`deploy/switchyard/routes.generated.toml`); this adapter only owns the one
HTTP hop to the sidecar plus the retry/error-mapping policy for *that* hop.

Retries here are intentionally lighter than `OpenAICompatibleProvider`:
this call only needs to be retried if the sidecar process itself is
unreachable or slow to accept the connection — the `[llm_clients]` sections
of Switchyard's own TOML config already carry a `max_retries`/`timeout_ms`
policy for its calls to the real upstream models, so retrying those here
too would double the effective retry budget.

Status codes from `switchyard-server` are mapped per its documented error
surface (docs/routing_algorithms/llm_classifier_routing.md at the pinned
commit): 504 timeout, 503 `response_state_limit_exceeded`
(too many concurrent in-flight classifications), 409
`response_state_conflict` (a stale/racing classifier turn), 429 upstream
rate limiting bubbled through, anything else 4xx/5xx a generic provider
error.
"""

import asyncio

import httpx

from apex_ai_router.domain.errors import ProviderError
from apex_ai_router.domain.model_target import TargetConfig
from apex_ai_router.domain.request import ChatCompletionRequest
from apex_ai_router.providers.base import ProviderResult

_MAX_RETRIES = 1
_BACKOFF_SECONDS = 0.5


class SwitchyardProvider:
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
                f"No base_url configured for switchyard target '{target.model}'.",
                retry_count=0,
            )

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
                        "/v1/chat/completions",
                        json=payload,
                        headers={"content-type": "application/json"},
                    )
                except httpx.TimeoutException as exc:
                    last_error = ProviderError(
                        "provider_timeout",
                        "The switchyard-server sidecar timed out.",
                        retry_count=attempt,
                    )
                    if attempt < _MAX_RETRIES:
                        await asyncio.sleep(_BACKOFF_SECONDS * (attempt + 1))
                        continue
                    raise last_error from exc
                except httpx.TransportError as exc:
                    last_error = ProviderError(
                        "provider_unavailable",
                        "The switchyard-server sidecar is unreachable.",
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
                            "switchyard-server returned an invalid response.",
                            retry_count=attempt,
                        ) from exc

                if response.status_code == 504:
                    raise ProviderError(
                        "provider_timeout",
                        "switchyard-server timed out routing the request.",
                        retry_count=attempt,
                    )
                if response.status_code in (429, 503):
                    raise ProviderError(
                        "provider_unavailable",
                        "switchyard-server is temporarily unable to route the request.",
                        retry_count=attempt,
                    )
                raise ProviderError(
                    "provider_error",
                    f"switchyard-server returned HTTP {response.status_code}.",
                    retry_count=attempt,
                )

        raise last_error or ProviderError(
            "provider_error", "The switchyard-server request failed."
        )
