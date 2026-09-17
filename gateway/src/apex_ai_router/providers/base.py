"""Provider interface (spec section 9).

Concrete adapters resolve a `TargetConfig` into a real upstream HTTP call.
V1 only ships `OpenAICompatibleProvider`; the interface exists so
provider-specific adapters can be added later without touching the routing
or API layers. Errors are always raised as `ProviderError`
(re-exported from `apex_ai_router.domain.errors` for convenience) so the
API layer never has to know which adapter produced them.
"""

from dataclasses import dataclass
from typing import Protocol

from apex_ai_router.domain.errors import ProviderError
from apex_ai_router.domain.model_target import TargetConfig
from apex_ai_router.domain.request import ChatCompletionRequest

__all__ = ["ModelProvider", "ProviderError", "ProviderResult"]


@dataclass(frozen=True)
class ProviderResult:
    """`retry_count` is the number of *retries* actually performed (0 on a
    first-attempt success) -- spec section 24: "Include retry count in
    telemetry." Attached to the result rather than raised/logged separately
    so it reaches `RequestTelemetry` on both the success and the
    eventual-failure path without a second return channel."""

    body: dict
    retry_count: int


class ModelProvider(Protocol):
    async def chat_completion(
        self, request: ChatCompletionRequest, target: TargetConfig
    ) -> ProviderResult: ...
