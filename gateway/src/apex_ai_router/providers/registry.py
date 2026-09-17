"""Maps a target's declared `provider` string to a concrete adapter
(spec section 9). `openai_compatible` talks directly to an
OpenAI-compatible upstream; `switchyard` talks to a local switchyard-server
sidecar that performs its own efficient/capable routing decision. This
indirection is what lets provider-specific adapters register without the
routing or API layers changing.
"""

from apex_ai_router.domain.errors import ProviderError
from apex_ai_router.domain.model_target import TargetConfig
from apex_ai_router.providers.base import ModelProvider
from apex_ai_router.providers.openai_compatible import OpenAICompatibleProvider
from apex_ai_router.providers.switchyard_adapter import SwitchyardProvider


def get_provider(target: TargetConfig) -> ModelProvider:
    if target.provider == "openai_compatible":
        return OpenAICompatibleProvider(timeout_seconds=target.timeout_seconds)
    if target.provider == "switchyard":
        return SwitchyardProvider(timeout_seconds=target.timeout_seconds)
    raise ProviderError("provider_unavailable", f"Unsupported provider '{target.provider}'.")
