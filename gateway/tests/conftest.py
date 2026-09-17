import pytest

from apex_ai_router.config import Settings, get_settings
from apex_ai_router.main import app


@pytest.fixture
def override_settings():
    """Point the shared `app` at a test-specific Settings instance for the
    duration of one test, then clean up so later tests see real settings
    again (the app object is imported once and reused across every test
    module in the same pytest session)."""

    def _apply(settings: Settings) -> None:
        app.dependency_overrides[get_settings] = lambda: settings

    yield _apply
    app.dependency_overrides.pop(get_settings, None)
