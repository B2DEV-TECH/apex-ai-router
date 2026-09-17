from fastapi import FastAPI

from apex_ai_router.api import health
from apex_ai_router.config import get_settings
from apex_ai_router.logging import configure_logging


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
    app.include_router(health.router)
    return app


app = create_app()
