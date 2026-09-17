"""Environment-based settings for the gateway, plus loading of the
non-secret routing policy file (spec section 8).

Secrets and per-environment values come from the process environment /
`.env`; `routing.yaml` only ever references them by name
(`${EFFICIENT_MODEL_ID}`, `api_key_env: EFFICIENT_MODEL_API_KEY`, ...) and
is safe to commit.
"""

import os
from functools import lru_cache
from pathlib import Path

import yaml
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

from apex_ai_router.domain.model_target import RoutingConfig

# Best-effort: populates os.environ from `.env` so `${VAR}` substitution in
# routing.yaml resolves the same way `Settings` resolves its own fields. A
# real deployment that sets env vars directly needs no `.env` file at all.
load_dotenv()


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
    max_request_body_bytes: int = 1_000_000

    @property
    def api_key_list(self) -> list[str]:
        return [key.strip() for key in self.api_keys.split(",") if key.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


class RoutingConfigError(Exception):
    pass


def load_routing_config(path: str | Path) -> RoutingConfig:
    file_path = Path(path)
    if not file_path.is_file():
        raise RoutingConfigError(f"Routing config file not found: {file_path}")

    expanded = os.path.expandvars(file_path.read_text(encoding="utf-8"))
    data = yaml.safe_load(expanded) or {}
    config = RoutingConfig.model_validate(data)

    for name, target in config.targets.items():
        if "${" in target.model:
            raise RoutingConfigError(
                f"Target '{name}' has an unresolved placeholder in 'model': "
                f"{target.model!r}. Set the referenced environment variable "
                "(see .env.example)."
            )

    return config


@lru_cache
def _load_routing_config_cached(path: str) -> RoutingConfig:
    return load_routing_config(path)


def get_routing_config(settings: Settings) -> RoutingConfig:
    return _load_routing_config_cached(settings.routing_config)
