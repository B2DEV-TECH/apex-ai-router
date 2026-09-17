"""Provider interface (spec section 9).

Concrete adapters resolve a `TargetConfig` into a real upstream HTTP call.
V1 only ships `OpenAICompatibleProvider`; the interface exists so
provider-specific adapters can be added later without touching the routing
or API layers. Errors are always raised as `ProviderError`
(re-exported from `apex_ai_router.domain.errors` for convenience) so the
API layer never has to know which adapter produced them.
"""

from typing import Protocol

from apex_ai_router.domain.errors import ProviderError
from apex_ai_router.domain.model_target import TargetConfig
from apex_ai_router.domain.request import ChatCompletionRequest

__all__ = ["ModelProvider", "ProviderError"]


class ModelProvider(Protocol):
    async def chat_completion(
        self, request: ChatCompletionRequest, target: TargetConfig
    ) -> dict: ...
