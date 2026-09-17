"""Resolves a virtual model id (the OpenAI-compatible `model` field) into a
concrete provider target (spec sections 8, 11).

`fixed` (`apex-efficient` / `apex-capable`) resolves directly to a single
target. `llm_classifier` (`apex-auto`) resolves to a `switchyard` target
whose provider adapter forwards the request to a `switchyard-server`
sidecar, which performs the actual efficient/capable decision (see
`routing/switchyard_router.py` and `routing/switchyard_config.py`).
"""

from apex_ai_router.domain.errors import RoutingError
from apex_ai_router.domain.model_target import ResolvedTarget, RoutingConfig
from apex_ai_router.routing.fixed_router import resolve_fixed_route
from apex_ai_router.routing.policies import RouteStrategy
from apex_ai_router.routing.switchyard_router import resolve_switchyard_route


class RoutingService:
    def __init__(self, config: RoutingConfig):
        self._config = config

    def resolve(self, virtual_model: str) -> ResolvedTarget:
        route = self._config.routes.get(virtual_model)
        if route is None:
            raise RoutingError("route_not_found", f"Unknown model '{virtual_model}'.")

        if route.strategy == RouteStrategy.FIXED:
            return resolve_fixed_route(virtual_model, route, self._config)

        if route.strategy == RouteStrategy.LLM_CLASSIFIER:
            return resolve_switchyard_route(virtual_model, route, self._config)

        raise RoutingError("routing_failed", f"Unsupported routing strategy '{route.strategy}'.")
