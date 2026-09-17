"""`GET /v1/models` — lists the virtual models this gateway exposes
(spec section 6). Model ids come straight from `routing.yaml`, so this
endpoint can never advertise a model the router cannot actually resolve.
"""

import time

from fastapi import APIRouter, Depends

from apex_ai_router.config import Settings, get_routing_config, get_settings
from apex_ai_router.security.auth import require_api_key

router = APIRouter(tags=["models"])

_STARTED_AT = int(time.time())


@router.get("/v1/models")
async def list_models(
    _: str = Depends(require_api_key),
    settings: Settings = Depends(get_settings),
) -> dict:
    routing_config = get_routing_config(settings)
    data = [
        {"id": model_id, "object": "model", "created": _STARTED_AT, "owned_by": "apex-ai-router"}
        for model_id in routing_config.routes
    ]
    return {"object": "list", "data": data}
