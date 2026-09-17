# apex-ai-router gateway

The OpenAI-compatible FastAPI gateway. See the repository root README for
the overall architecture.

## What exists today (Phase 1)

- App factory (`apex_ai_router.main`), environment-based settings
  (`apex_ai_router.config`), structured JSON logging
  (`apex_ai_router.logging`).
- `GET /health` (liveness) and `GET /ready` (readiness) endpoints.
- Local mock upstream model servers (`apex_ai_router.mocks.mock_model_server`)
  that speak just enough OpenAI-compatible `/v1/chat/completions` to support
  local development and integration tests, without any real provider
  credentials.

Routing, `/v1/chat/completions`, telemetry, and cost estimation are not
implemented yet.

## Development

```sh
uv sync
uv run pytest
uv run ruff check .
uv run uvicorn apex_ai_router.main:app --reload --port 8080
```

## Versions tested

- Python: 3.12.10
- FastAPI / Pydantic: pinned exact versions recorded in `uv.lock` once
  generated.
