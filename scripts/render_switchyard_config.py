#!/usr/bin/env python3
"""Render `deploy/switchyard/routes.generated.toml` from `gateway/config/routing.yaml`.

Run this whenever routing.yaml's efficient/capable/judge targets or the
apex-auto threshold change, then (re)start switchyard-server with the
generated file:

    uv run --project gateway python scripts/render_switchyard_config.py
    .tools/switchyard/bin/switchyard-server --config deploy/switchyard/routes.generated.toml

The generated file is gitignored (it is a build artifact of routing.yaml,
and its api_key_env values are only meaningful with real environment
variables set) — `deploy/switchyard/routes.example.toml` is the checked-in,
human-readable reference instead.
"""

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "gateway" / "src"))

from apex_ai_router.config import load_routing_config  # noqa: E402
from apex_ai_router.routing.switchyard_config import render_routes_toml  # noqa: E402


def main() -> int:
    routing_yaml = REPO_ROOT / "gateway" / "config" / "routing.yaml"
    output_path = REPO_ROOT / "deploy" / "switchyard" / "routes.generated.toml"

    config = load_routing_config(str(routing_yaml))
    toml_text = render_routes_toml(config)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(toml_text, encoding="utf-8")
    print(f"Wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
