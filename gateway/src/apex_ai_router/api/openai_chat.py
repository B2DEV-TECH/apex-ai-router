"""`POST /v1/chat/completions` (spec section 6) — the required MVP endpoint.

Also where request telemetry (spec section 13) and estimated-cost
calculation (spec section 12) are recorded: this is the one place that
already has routing/provider/timing/token information in hand, so telemetry
is written here directly rather than through a generic middleware that
would need to reconstruct all of it.
"""

import logging
import time
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request
from pydantic import ValidationError

from apex_ai_router.config import (
    Settings,
    get_pricing_config,
    get_routing_config,
    get_settings,
    get_telemetry_store,
)
from apex_ai_router.domain.errors import GatewayError
from apex_ai_router.domain.request import ChatCompletionRequest
from apex_ai_router.domain.response import ChatCompletionResponse
from apex_ai_router.providers.registry import get_provider
from apex_ai_router.routing.service import RoutingService
from apex_ai_router.security.auth import require_api_key
from apex_ai_router.telemetry.cost import estimate_baseline_comparison, estimate_cost
from apex_ai_router.telemetry.models import RequestTelemetry

router = APIRouter(tags=["chat"])
logger = logging.getLogger(__name__)


def _elapsed_ms(started: float) -> float:
    return (time.perf_counter() - started) * 1000


@router.post("/v1/chat/completions")
async def create_chat_completion(
    body: ChatCompletionRequest,
    request: Request,
    _: str = Depends(require_api_key),
    settings: Settings = Depends(get_settings),
) -> dict:
    request_id = getattr(request.state, "request_id", "unknown")
    telemetry_store = get_telemetry_store(settings)
    started = time.perf_counter()

    policy: str | None = None
    selected_target: str | None = None
    selected_provider: str | None = None
    selected_model: str | None = None
    routing_duration_ms: float | None = None
    provider_duration_ms: float | None = None
    retry_count: int | None = None

    try:
        if body.stream:
            raise GatewayError(
                "unsupported_parameter",
                "Streaming responses are not implemented yet; send stream=false.",
            )

        routing_config = get_routing_config(settings)

        routing_started = time.perf_counter()
        resolved = RoutingService(routing_config).resolve(body.model)
        routing_duration_ms = _elapsed_ms(routing_started)

        policy = resolved.policy
        selected_target = resolved.name
        selected_provider = resolved.config.provider
        selected_model = resolved.config.model

        provider = get_provider(resolved.config)
        provider_started = time.perf_counter()
        provider_result = await provider.chat_completion(body, resolved.config)
        provider_duration_ms = _elapsed_ms(provider_started)
        retry_count = provider_result.retry_count

        try:
            parsed = ChatCompletionResponse.model_validate(provider_result.body)
        except ValidationError as exc:
            raise GatewayError(
                "provider_error",
                "The upstream model provider returned an unexpected response shape.",
                retry_count=retry_count,
            ) from exc
    except GatewayError as exc:
        telemetry_store.record_request(
            RequestTelemetry(
                request_id=request_id,
                route=body.model,
                policy=policy,
                selected_target=selected_target,
                selected_provider=selected_provider,
                selected_model=selected_model,
                routing_duration_ms=routing_duration_ms,
                provider_duration_ms=provider_duration_ms,
                total_duration_ms=_elapsed_ms(started),
                input_tokens=None,
                output_tokens=None,
                total_tokens=None,
                estimated_cost=None,
                estimated_baseline_cost=None,
                estimated_savings=None,
                success=False,
                http_status=exc.http_status,
                error_code=exc.code,
                retry_count=getattr(exc, "retry_count", None),
            ),
            timestamp=datetime.now(UTC).isoformat(),
        )
        raise

    usage = parsed.usage
    estimated_cost = None
    estimated_baseline_cost = None
    estimated_savings = None
    if usage is not None and selected_model is not None:
        pricing = get_pricing_config(settings)
        actual_cost = estimate_cost(
            selected_model, usage.prompt_tokens, usage.completion_tokens, pricing
        )
        estimated_cost = actual_cost.total_cost

        route_config = routing_config.routes[body.model]
        baseline_target_name = (
            route_config.capable_target if route_config.strategy == "llm_classifier" else None
        )
        if baseline_target_name is not None:
            baseline_target = routing_config.targets[baseline_target_name]
            baseline_cost = estimate_cost(
                baseline_target.model, usage.prompt_tokens, usage.completion_tokens, pricing
            )
            comparison = estimate_baseline_comparison(actual_cost, baseline_cost)
            estimated_baseline_cost = comparison.estimated_capable_baseline_cost
            estimated_savings = comparison.estimated_savings

    telemetry_store.record_request(
        RequestTelemetry(
            request_id=request_id,
            route=body.model,
            policy=policy,
            selected_target=selected_target,
            selected_provider=selected_provider,
            selected_model=selected_model,
            routing_duration_ms=routing_duration_ms,
            provider_duration_ms=provider_duration_ms,
            total_duration_ms=_elapsed_ms(started),
            input_tokens=usage.prompt_tokens if usage else None,
            output_tokens=usage.completion_tokens if usage else None,
            total_tokens=usage.total_tokens if usage else None,
            estimated_cost=estimated_cost,
            estimated_baseline_cost=estimated_baseline_cost,
            estimated_savings=estimated_savings,
            success=True,
            http_status=200,
            error_code=None,
            retry_count=retry_count,
        ),
        timestamp=datetime.now(UTC).isoformat(),
        prompt_content=_prompt_content_if_enabled(settings, body),
        response_content=_response_content_if_enabled(settings, parsed),
    )

    logger.info(
        "chat completion routed",
        extra={
            "request_id": request_id,
            "route": body.model,
            "selected_target": resolved.name,
            "provider": resolved.config.provider,
            "model": resolved.config.model,
        },
    )
    return parsed.model_dump(mode="json")


def _prompt_content_if_enabled(settings: Settings, body: ChatCompletionRequest) -> str | None:
    if not settings.telemetry_log_content:
        return None
    return body.model_dump_json()


def _response_content_if_enabled(
    settings: Settings, parsed: ChatCompletionResponse
) -> str | None:
    if not settings.telemetry_log_content:
        return None
    return parsed.model_dump_json()
