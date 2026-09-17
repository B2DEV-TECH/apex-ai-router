from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse

from apex_ai_router.config import RoutingConfigError, Settings, get_routing_config, get_settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    """Liveness probe. Always ok if the process can serve requests."""
    return {"status": "ok"}


@router.get("/ready")
async def ready(settings: Settings = Depends(get_settings)):
    """Readiness probe.

    Confirms local configuration loaded successfully, including that
    `routing.yaml` parses and every referenced target has a real model id
    (spec section 33) — deliberately does not call any paid upstream
    provider on every check.
    """
    checks: dict[str, object] = {"settings_loaded": True}

    try:
        routing_config = get_routing_config(settings)
    except RoutingConfigError as exc:
        checks["routing_config_loaded"] = False
        checks["routing_config_error"] = str(exc)
        return JSONResponse(
            status_code=503,
            content={"status": "not_ready", "checks": checks, "environment": settings.environment},
        )

    checks["routing_config_loaded"] = True
    checks["routes_configured"] = len(routing_config.routes)
    return {"status": "ready", "checks": checks, "environment": settings.environment}
