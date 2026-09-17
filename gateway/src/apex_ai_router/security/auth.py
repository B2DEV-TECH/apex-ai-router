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


async def require_admin_key(
    request: Request, settings: Settings = Depends(get_settings)
) -> str:
    """Deliberately independent of `require_api_key`: an inference key must
    never authenticate an admin request, even if `admin_api_key` happens to
    equal one of `api_key_list` (an operator mistake, not something this
    dependency should paper over) — it only ever compares against the single
    configured `admin_api_key`."""
    if not settings.admin_api_key:
        raise HTTPException(
            status_code=500,
            detail={
                "code": "internal_error",
                "message": "No admin API key is configured for this gateway.",
            },
        )

    header = request.headers.get("authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token or not hmac.compare_digest(
        token, settings.admin_api_key
    ):
        raise HTTPException(
            status_code=401,
            detail={
                "code": "authentication_failed",
                "message": "Missing or invalid admin API key.",
            },
        )
    return token
