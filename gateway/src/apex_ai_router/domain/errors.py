"""Sanitized error taxonomy shared by routing and provider adapters.

Every client-facing error must fit the shape from spec section 23:
``{"error": {"code", "message", "request_id"}}``. Raising `GatewayError`
(or a subclass) anywhere below the API layer is enough to get that shape
and the right HTTP status; see the exception handler in `main.py`.
"""

_DEFAULT_HTTP_STATUS: dict[str, int] = {
    "invalid_request": 400,
    "authentication_failed": 401,
    "route_not_found": 404,
    "routing_failed": 500,
    "provider_unavailable": 503,
    "provider_timeout": 504,
    "provider_error": 502,
    "context_too_large": 413,
    "unsupported_parameter": 400,
    "internal_error": 500,
}


class GatewayError(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        *,
        http_status: int | None = None,
        retry_count: int | None = None,
    ):
        super().__init__(message)
        self.code = code
        self.message = message
        self.http_status = (
            http_status if http_status is not None else _DEFAULT_HTTP_STATUS.get(code, 500)
        )
        # Retries actually performed before giving up (spec section 24).
        # None for errors raised outside a retry loop (e.g. routing_failed);
        # 0+ for a `ProviderError` raised after exhausting the retry budget.
        self.retry_count = retry_count


class RoutingError(GatewayError):
    pass


class ProviderError(GatewayError):
    pass
