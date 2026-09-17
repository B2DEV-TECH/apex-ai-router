import uuid

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from apex_ai_router.api import admin, health, models, openai_chat
from apex_ai_router.config import RoutingConfigError, get_settings
from apex_ai_router.domain.errors import GatewayError
from apex_ai_router.logging import configure_logging


def _error_body(code: str, message: str, request_id: str) -> dict:
    return {"error": {"code": code, "message": message, "request_id": request_id}}


def _request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "unknown")


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)

    app = FastAPI(
        title="APEX AI Router",
        version="0.1.0",
        description=(
            "OpenAI-compatible gateway that routes Oracle APEX AI requests "
            "through NVIDIA NeMo Switchyard."
        ),
    )

    @app.middleware("http")
    async def request_context(request: Request, call_next):
        request.state.request_id = str(uuid.uuid4())

        content_length = request.headers.get("content-length")
        if content_length is not None:
            try:
                too_large = int(content_length) > settings.max_request_body_bytes
            except ValueError:
                too_large = False
            if too_large:
                return JSONResponse(
                    status_code=413,
                    content=_error_body(
                        "invalid_request",
                        "Request body exceeds the configured size limit.",
                        request.state.request_id,
                    ),
                )

        response = await call_next(request)
        response.headers["X-Request-Id"] = request.state.request_id
        return response

    @app.exception_handler(GatewayError)
    async def handle_gateway_error(request: Request, exc: GatewayError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.http_status,
            content=_error_body(exc.code, exc.message, _request_id(request)),
        )

    @app.exception_handler(RoutingConfigError)
    async def handle_routing_config_error(
        request: Request, exc: RoutingConfigError
    ) -> JSONResponse:
        # `RoutingConfigError` (raised by `config.py` for a missing/invalid
        # routing.yaml or pricing.yaml, e.g. an unresolved `${VAR}`
        # placeholder) is a plain Exception, not a GatewayError -- it is
        # raised straight out of `get_routing_config`/`get_pricing_config`,
        # which several endpoints (models, chat completions, admin routes)
        # call with no local try/except. Without this handler it fell
        # through to FastAPI's default handling as an unsanitized 500 with
        # a raw traceback, violating the "errors are sanitized" requirement.
        # This one handler covers every call site, present and future, and
        # also catches `PricingConfigError` (a subclass). The message is
        # safe to expose: it only ever names a config file path or an
        # environment variable, the same detail `/ready` already reports.
        return JSONResponse(
            status_code=500,
            content=_error_body("routing_failed", str(exc), _request_id(request)),
        )

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        detail = "; ".join(
            f"{'.'.join(str(part) for part in error['loc'])}: {error['msg']}"
            for error in exc.errors()
        )
        return JSONResponse(
            status_code=400,
            content=_error_body("invalid_request", detail, _request_id(request)),
        )

    @app.exception_handler(StarletteHTTPException)
    async def handle_http_exception(
        request: Request, exc: StarletteHTTPException
    ) -> JSONResponse:
        if isinstance(exc.detail, dict) and "code" in exc.detail:
            code = exc.detail["code"]
            message = exc.detail.get("message", code)
        else:
            code = "internal_error" if exc.status_code >= 500 else "invalid_request"
            message = str(exc.detail)
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_body(code, message, _request_id(request)),
        )

    app.include_router(health.router)
    app.include_router(models.router)
    app.include_router(openai_chat.router)
    app.include_router(admin.router)
    return app


app = create_app()
