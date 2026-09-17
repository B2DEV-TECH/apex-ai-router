from fastapi import APIRouter

from apex_ai_router.config import get_settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    """Liveness probe. Always ok if the process can serve requests."""
    return {"status": "ok"}


@router.get("/ready")
async def ready() -> dict:
    """Readiness probe.

    Confirms local configuration loaded successfully. Deliberately does not
    call any paid upstream provider on every check (spec section 33) — once
    routing config exists, this will validate that it parses, not that
    providers are reachable.
    """
    settings = get_settings()
    checks = {"settings_loaded": True}
    return {"status": "ready", "checks": checks, "environment": settings.environment}
