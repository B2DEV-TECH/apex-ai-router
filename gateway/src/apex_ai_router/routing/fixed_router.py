"""EFFICIENT/CAPABLE fixed routing (spec section 11).

`apex-efficient` and `apex-capable` always resolve to the single target
named in `routing.yaml`; there is no decision to make here.
"""

from apex_ai_router.domain.errors import RoutingError
from apex_ai_router.domain.model_target import ResolvedTarget, RouteConfig, RoutingConfig


def resolve_fixed_route(
    route_name: str, route: RouteConfig, config: RoutingConfig
) -> ResolvedTarget:
    if not route.target:
        raise RoutingError(
            "routing_failed",
            f"Route '{route_name}' uses strategy 'fixed' but declares no 'target'.",
        )
    target_config = config.targets.get(route.target)
    if target_config is None:
        raise RoutingError(
            "routing_failed",
            f"Route '{route_name}' points to unknown target '{route.target}'.",
        )
    return ResolvedTarget(name=route.target, policy="fixed", config=target_config)
