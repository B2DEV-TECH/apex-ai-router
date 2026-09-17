"""Read-only admin API (spec section 15).

Every endpoint here requires `require_admin_key`, never `require_api_key` —
an inference key must not be able to read telemetry. None of these
endpoints ever return prompt or response content, regardless of whether
dev-only content logging is enabled (see `TelemetryStore.list_requests`).
"""

from fastapi import APIRouter, Depends, Query

from apex_ai_router.config import Settings, get_routing_config, get_settings, get_telemetry_store
from apex_ai_router.security.auth import require_admin_key
from apex_ai_router.telemetry.store import TelemetryStore

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin_key)])


@router.get("/metrics/summary")
async def metrics_summary(
    since: str | None = Query(default=None),
    until: str | None = Query(default=None),
    settings: Settings = Depends(get_settings),
) -> dict:
    store: TelemetryStore = get_telemetry_store(settings)
    return store.summary(since=since, until=until)


@router.get("/metrics/models")
async def metrics_models(
    since: str | None = Query(default=None),
    until: str | None = Query(default=None),
    settings: Settings = Depends(get_settings),
) -> dict:
    store: TelemetryStore = get_telemetry_store(settings)
    return {"models": store.models_breakdown(since=since, until=until)}


@router.get("/metrics/backends")
async def metrics_backends(
    since: str | None = Query(default=None),
    until: str | None = Query(default=None),
    settings: Settings = Depends(get_settings),
) -> dict:
    """Per-route split by the model the upstream actually reported -- for
    `apex-auto`, the efficient/capable decision made by the Switchyard
    sidecar (see HANDOFF.md section 2)."""
    store: TelemetryStore = get_telemetry_store(settings)
    return {"backends": store.backends_breakdown(since=since, until=until)}


@router.get("/metrics/daily")
async def metrics_daily(
    since: str | None = Query(default=None),
    until: str | None = Query(default=None),
    settings: Settings = Depends(get_settings),
) -> dict:
    store: TelemetryStore = get_telemetry_store(settings)
    return {"daily": store.daily(since=since, until=until)}


@router.get("/requests")
async def list_requests(
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    settings: Settings = Depends(get_settings),
) -> dict:
    store: TelemetryStore = get_telemetry_store(settings)
    return {"requests": store.list_requests(limit=limit, offset=offset)}


@router.get("/routes")
async def list_routes(settings: Settings = Depends(get_settings)) -> dict:
    routing_config = get_routing_config(settings)
    return {
        "routes": {
            name: route.model_dump(exclude_none=True)
            for name, route in routing_config.routes.items()
        },
        "targets": {
            name: target.model_dump(exclude_none=True)
            for name, target in routing_config.targets.items()
        },
    }
