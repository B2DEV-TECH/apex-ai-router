"""Environment-based settings for the gateway.

Only the settings needed by what is actually implemented so far (health/
readiness) are wired up. Fields for routing, auth, and provider credentials
are declared now so `.env.example` documents the full shape of the
configuration ahead of the phases that consume them.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="APEX_AI_ROUTER_",
        env_file=".env",
        extra="ignore",
    )

    environment: str = "development"
    log_level: str = "info"
    host: str = "0.0.0.0"
    port: int = 8080

    api_keys: str = ""
    admin_api_key: str | None = None

    routing_config: str = "config/routing.yaml"

    @property
    def api_key_list(self) -> list[str]:
        return [key.strip() for key in self.api_keys.split(",") if key.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
