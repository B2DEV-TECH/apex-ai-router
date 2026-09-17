"""APEX-AUTO routing via a switchyard-server sidecar (spec section 11, Phase 3).

The actual efficient/capable decision is made by `switchyard-server` (a
standalone NVIDIA NeMo Switchyard process configured from
`deploy/switchyard/routes.generated.toml`, see `switchyard_config.py`), not
by this gateway. This module only resolves the `llm_classifier` route to the
`targets:` entry (provider `switchyard`) that fronts that sidecar's
OpenAI-compatible `/v1/chat/completions` endpoint.
"""

from apex_ai_router.domain.errors import RoutingError
from apex_ai_router.domain.model_target import ResolvedTarget, RouteConfig, RoutingConfig


def resolve_switchyard_route(
    route_name: str, route: RouteConfig, config: RoutingConfig
) -> ResolvedTarget:
    if not route.switchyard_target:
        raise RoutingError(
            "routing_failed",
            f"Route '{route_name}' uses strategy 'llm_classifier' but declares no "
            "'switchyard_target'.",
        )
    target_config = config.targets.get(route.switchyard_target)
    if target_config is None:
        raise RoutingError(
            "routing_failed",
            f"Route '{route_name}' points to unknown switchyard target "
            f"'{route.switchyard_target}'.",
        )
    if target_config.provider != "switchyard":
        raise RoutingError(
            "routing_failed",
            f"Route '{route_name}' switchyard_target '{route.switchyard_target}' must use "
            "provider 'switchyard'.",
        )
    return ResolvedTarget(
        name=route.switchyard_target, policy="llm_classifier", config=target_config
    )
