"""Resolves a virtual model id (the OpenAI-compatible `model` field) into a
concrete provider target (spec sections 8, 11).

Only the `fixed` strategy (`apex-efficient` / `apex-capable`) is
implemented. `llm_classifier` (`apex-auto`) is real Switchyard-backed
routing and lands in Phase 3 (see `routing/switchyard_adapter.py` once it
exists) — it is intentionally rejected here rather than faked.
"""

from apex_ai_router.domain.errors import RoutingError
from apex_ai_router.domain.model_target import ResolvedTarget, RoutingConfig
from apex_ai_router.routing.fixed_router import resolve_fixed_route
from apex_ai_router.routing.policies import RouteStrategy


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
            raise RoutingError(
                "routing_failed",
                f"Automatic routing for '{virtual_model}' is not available yet in this "
                "deployment; use a fixed model such as apex-efficient or apex-capable "
                "until Switchyard integration lands (see docs/routing.md).",
            )

        raise RoutingError("routing_failed", f"Unsupported routing strategy '{route.strategy}'.")
