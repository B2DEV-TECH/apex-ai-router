"""`POST /v1/chat/completions` (spec section 6) — the required MVP endpoint.

No automatic routing yet (Phase 3): only the `fixed` strategy behind
`apex-efficient` / `apex-capable` resolves here. `apex-auto` is advertised
by `/v1/models` but currently fails with a clear `routing_failed` error via
`RoutingService`, rather than pretending to route.
"""

import logging

from fastapi import APIRouter, Depends, Request
from pydantic import ValidationError

from apex_ai_router.config import Settings, get_routing_config, get_settings
from apex_ai_router.domain.errors import GatewayError
from apex_ai_router.domain.request import ChatCompletionRequest
from apex_ai_router.domain.response import ChatCompletionResponse
from apex_ai_router.providers.registry import get_provider
from apex_ai_router.routing.service import RoutingService
from apex_ai_router.security.auth import require_api_key

router = APIRouter(tags=["chat"])
logger = logging.getLogger(__name__)


@router.post("/v1/chat/completions")
async def create_chat_completion(
    body: ChatCompletionRequest,
    request: Request,
    _: str = Depends(require_api_key),
    settings: Settings = Depends(get_settings),
) -> dict:
    if body.stream:
        raise GatewayError(
            "unsupported_parameter",
            "Streaming responses are not implemented yet; send stream=false.",
        )

    routing_config = get_routing_config(settings)
    resolved = RoutingService(routing_config).resolve(body.model)
    provider = get_provider(resolved.config)

    raw_response = await provider.chat_completion(body, resolved.config)

    try:
        parsed = ChatCompletionResponse.model_validate(raw_response)
    except ValidationError as exc:
        raise GatewayError(
            "provider_error",
            "The upstream model provider returned an unexpected response shape.",
        ) from exc

    logger.info(
        "chat completion routed",
        extra={
            "request_id": getattr(request.state, "request_id", None),
            "route": body.model,
            "selected_target": resolved.name,
            "provider": resolved.config.provider,
            "model": resolved.config.model,
        },
    )
    return parsed.model_dump(mode="json")
