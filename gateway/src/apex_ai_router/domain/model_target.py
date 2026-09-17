"""Routing configuration schema and resolved-target types (spec sections 8-9).

`RoutingConfig` is the parsed shape of `config/routing.yaml`. It never
contains secrets: targets reference credentials by environment variable
name (`api_key_env`), resolved later by the provider adapter.
"""

from typing import Literal

from pydantic import BaseModel, ConfigDict


class TargetConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")

    provider: Literal["openai_compatible"]
    model: str
    base_url: str | None = None
    api_key_env: str | None = None
    timeout_seconds: float = 30.0


class RouteConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")

    strategy: Literal["fixed", "llm_classifier"]

    # strategy: fixed
    target: str | None = None

    # strategy: llm_classifier (Phase 3 / Switchyard, not implemented yet)
    efficient_target: str | None = None
    capable_target: str | None = None
    judge_target: str | None = None
    threshold: float | None = None


class RoutingConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")

    routes: dict[str, RouteConfig]
    targets: dict[str, TargetConfig]


class ResolvedTarget(BaseModel):
    """What the routing layer hands the provider layer for one request."""

    model_config = ConfigDict(extra="forbid")

    name: str
    policy: str
    config: TargetConfig
