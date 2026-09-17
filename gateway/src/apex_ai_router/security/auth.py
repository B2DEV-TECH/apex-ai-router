"""Gateway API-key authentication (spec section 21).

Uses a bearer token compared against the configured inference key list
with constant-time comparison. Admin credentials are intentionally a
separate setting and are never returned by any endpoint.
"""

import hmac

from fastapi import Depends, HTTPException, Request

from apex_ai_router.config import Settings, get_settings


def _matches_any(candidate: str, keys: list[str]) -> bool:
    return any(hmac.compare_digest(candidate, key) for key in keys)


async def require_api_key(
    request: Request, settings: Settings = Depends(get_settings)
) -> str:
    if not settings.api_key_list:
        raise HTTPException(
            status_code=500,
            detail={
                "code": "internal_error",
                "message": "No inference API keys are configured for this gateway.",
            },
        )

    header = request.headers.get("authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token or not _matches_any(token, settings.api_key_list):
        raise HTTPException(
            status_code=401,
            detail={
                "code": "authentication_failed",
                "message": "Missing or invalid API key.",
            },
        )
    return token
