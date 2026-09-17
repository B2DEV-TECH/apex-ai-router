"""Environment-based settings for the gateway, plus loading of the
non-secret routing policy file (spec section 8).

Secrets and per-environment values come from the process environment /
`.env`; `routing.yaml` only ever references them by name
(`${EFFICIENT_MODEL_ID}`, `api_key_env: EFFICIENT_MODEL_API_KEY`, ...) and
is safe to commit.
"""

import os
import re
from functools import lru_cache
from pathlib import Path

import yaml
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

from apex_ai_router.domain.model_target import RoutingConfig
from apex_ai_router.domain.pricing import PricingConfig
from apex_ai_router.telemetry.store import TelemetryStore

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

    pricing_config: str = "config/pricing.yaml"
    telemetry_db_path: str = "data/telemetry.db"
    telemetry_log_content: bool = False

    @property
    def api_key_list(self) -> list[str]:
        return [key.strip() for key in self.api_keys.split(",") if key.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


class RoutingConfigError(Exception):
    pass


class PricingConfigError(RoutingConfigError):
    pass


_ENV_VAR_PATTERN = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")


def _expand_env_vars(text: str) -> str:
    """Substitutes `${VAR}` placeholders from `os.environ`, leaving unset
    ones untouched so the unresolved-placeholder check below can report them.

    Deliberately NOT `os.path.expandvars`: on Windows, `ntpath.expandvars`
    treats a bare `'` as "no expansion until the next `'`" (POSIX shell
    quoting semantics), and a single unmatched apostrophe anywhere earlier in
    the file — entirely plausible in a YAML comment or string value — would
    silently disable substitution for the rest of the document.
    """

    def _substitute(match: re.Match[str]) -> str:
        return os.environ.get(match.group(1), match.group(0))

    return _ENV_VAR_PATTERN.sub(_substitute, text)


def load_routing_config(path: str | Path) -> RoutingConfig:
    file_path = Path(path)
    if not file_path.is_file():
        raise RoutingConfigError(f"Routing config file not found: {file_path}")

    expanded = _expand_env_vars(file_path.read_text(encoding="utf-8"))
    data = yaml.safe_load(expanded) or {}
    config = RoutingConfig.model_validate(data)

    for name, target in config.targets.items():
        for field in ("model", "base_url"):
            value = getattr(target, field)
            if isinstance(value, str) and "${" in value:
                raise RoutingConfigError(
                    f"Target '{name}' has an unresolved placeholder in '{field}': "
                    f"{value!r}. Set the referenced environment variable "
                    "(see .env.example)."
                )

    return config


@lru_cache
def _load_routing_config_cached(path: str) -> RoutingConfig:
    return load_routing_config(path)


def get_routing_config(settings: Settings) -> RoutingConfig:
    return _load_routing_config_cached(settings.routing_config)


def load_pricing_config(path: str | Path) -> PricingConfig:
    file_path = Path(path)
    if not file_path.is_file():
        raise PricingConfigError(f"Pricing config file not found: {file_path}")

    data = yaml.safe_load(file_path.read_text(encoding="utf-8")) or {}
    return PricingConfig.model_validate(data)


@lru_cache
def _load_pricing_config_cached(path: str) -> PricingConfig:
    return load_pricing_config(path)


def get_pricing_config(settings: Settings) -> PricingConfig:
    return _load_pricing_config_cached(settings.pricing_config)


@lru_cache
def _get_telemetry_store_cached(db_path: str) -> TelemetryStore:
    return TelemetryStore(db_path)


def get_telemetry_store(settings: Settings) -> TelemetryStore:
    """One `TelemetryStore` (and its one open SQLite connection) per distinct
    `telemetry_db_path` for the life of the process — tests each use their
    own `tmp_path`-derived path precisely so they don't share a cached
    instance and pollute each other's rows."""
    return _get_telemetry_store_cached(settings.telemetry_db_path)
