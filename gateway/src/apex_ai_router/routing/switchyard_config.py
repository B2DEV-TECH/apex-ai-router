"""Renders a native Switchyard `routes.toml` from `config/routing.yaml`
(spec section 11, Phase 3).

Switchyard's TOML has no `${VAR}` substitution for `base_url` (see
`docs/reference/toml_schema.md` in the pinned Switchyard commit) — only
`api_key_env` *names* an environment variable, the secret value itself is
never written to the file. Because our own `routing.yaml` already resolves
`${VAR}` placeholders at load time (`config.py`), this module can render a
ready-to-run TOML file directly from an already-loaded `RoutingConfig`; no
separate substitution step is needed here.

This intentionally supports exactly the one route type this gateway uses:
`llm_classifier` in `mode = "capability"` (`type = "auto"` was evaluated
against the real spec and rejected — it is a tool-call-heuristic preset
with no LLM judge, a poor fit for one-shot APEX chat requests).
"""

from apex_ai_router.domain.model_target import RouteConfig, RoutingConfig, TargetConfig

_SCHEMA_VERSION = 1


def _toml_str(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _require_target(config: RoutingConfig, name: str | None, *, role: str) -> TargetConfig:
    if not name:
        raise ValueError(f"llm_classifier route is missing '{role}_target'.")
    target = config.targets.get(name)
    if target is None:
        raise ValueError(
            f"llm_classifier route's '{role}_target' points to unknown target '{name}'."
        )
    return target


def _openai_chat_base_url(base_url: str) -> str:
    """Everywhere else in this gateway (`OpenAICompatibleProvider`,
    `.env.example`, `routing.yaml`), `TargetConfig.base_url` is a bare host
    root and the caller appends `/v1/...` itself. Switchyard's own
    `openai_chat` client format instead appends only `/chat/completions`
    straight onto `base_url` (its docs example uses
    `base_url = "https://openrouter.ai/api/v1"`), so this is the one place
    that must add the `/v1` this codebase otherwise treats as implicit.
    """
    return base_url.rstrip("/") + "/v1"


def _render_llm_client(name: str, target: TargetConfig) -> str:
    if not target.base_url:
        raise ValueError(f"Target '{name}' has no base_url; cannot render a switchyard llm_client.")
    lines = [
        f"[llm_clients.{name}]",
        'format = "openai_chat"',
        f"base_url = {_toml_str(_openai_chat_base_url(target.base_url))}",
    ]
    if target.api_key_env:
        lines.append(f"api_key_env = {_toml_str(target.api_key_env)}")
    return "\n".join(lines)


def _render_target(name: str, target: TargetConfig) -> str:
    return "\n".join(
        [
            f"[targets.{name}]",
            f"id = {_toml_str(target.model)}",
            f"llm_client = {_toml_str(name)}",
        ]
    )


def render_routes_toml(config: RoutingConfig, *, route_name: str = "apex-auto") -> str:
    """Render a Switchyard `routes.toml` document for one `llm_classifier` route.

    Raises `ValueError` (a build/deploy-time configuration problem, not a
    request-time `GatewayError`) if `route_name` is missing, is not an
    `llm_classifier` route, or is missing a required target.
    """
    route: RouteConfig | None = config.routes.get(route_name)
    if route is None:
        raise ValueError(f"Unknown route '{route_name}'.")
    if route.strategy != "llm_classifier":
        raise ValueError(f"Route '{route_name}' is not an llm_classifier route.")

    efficient = _require_target(config, route.efficient_target, role="efficient")
    capable = _require_target(config, route.capable_target, role="capable")
    judge = _require_target(config, route.judge_target, role="judge")
    threshold = route.threshold if route.threshold is not None else 0.5

    sections = [
        f"schema_version = {_SCHEMA_VERSION}",
        "",
        _render_llm_client("efficient", efficient),
        "",
        _render_llm_client("capable", capable),
        "",
        _render_llm_client("judge", judge),
        "",
        _render_target("efficient", efficient),
        "",
        _render_target("capable", capable),
        "",
        _render_target("judge", judge),
        "",
        f"[routes.{route_name}]",
        f"id = {_toml_str(route_name)}",
        'type = "llm_classifier"',
        'mode = "capability"',
        'classifier_target = "judge"',
        'strong_target = "capable"',
        'weak_target = "efficient"',
        f"base_threshold = {threshold}",
    ]
    return "\n".join(sections) + "\n"
