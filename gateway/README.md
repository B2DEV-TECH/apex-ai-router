# apex-ai-router gateway

The OpenAI-compatible FastAPI gateway. See the [repository root
README](../README.md) for the overall architecture and product context.

## What's here

- App factory (`apex_ai_router.main`), environment-based settings
  (`apex_ai_router.config`), structured JSON logging
  (`apex_ai_router.logging`).
- `GET /health` (liveness) and `GET /ready` (readiness) endpoints.
- `GET /v1/models`, `POST /v1/chat/completions` — OpenAI-compatible
  surface, with `apex-efficient`/`apex-capable` (fixed routing) and
  `apex-auto` (forwarded to the NeMo Switchyard sidecar; see
  `../deploy/switchyard/`).
- Telemetry and cost estimation (`apex_ai_router.telemetry`), written to a
  local SQLite store; `GET /admin/*` endpoints to read it back behind a
  separate admin API key (`apex_ai_router.api.admin`).
- Sanitized error responses (`{"error": {"code", "message", "request_id"}}`)
  for every documented failure mode, including config/provider/validation
  errors — see `apex_ai_router.domain.errors` and the exception handlers in
  `main.py`.
- Local mock upstream model servers (`apex_ai_router.mocks.mock_model_server`)
  that speak just enough OpenAI-compatible `/v1/chat/completions` to support
  local development and integration tests, without any real provider
  credentials.

## Development

```sh
uv sync
uv run pytest
uv run pytest tests/integration    # spawns real mock servers + switchyard-server if built
uv run ruff check .
uv run mypy src
uv run uvicorn apex_ai_router.main:app --reload --port 8080
```

## Layout

```
src/apex_ai_router/
├── api/            FastAPI routers: models, openai_chat, admin, health
├── domain/         GatewayError hierarchy, routing/pricing domain types
├── routing/        Route resolution (fixed + switchyard-forwarded)
├── providers/      Provider clients (OpenAI-compatible HTTP calls)
├── telemetry/      SQLite store + cost estimation
├── security/       API key / admin key checks
├── mocks/          Local mock OpenAI-compatible upstream, for dev/tests
├── config.py       Settings, routing.yaml/pricing.yaml loading
└── main.py         App factory, exception handlers
tests/
├── unit/           Pure-function and domain-model tests
├── contract/       TestClient-level HTTP contract tests per endpoint
└── integration/    Real mock-server + real switchyard-server tests
```

## Versions tested

- Python: 3.12.10
- FastAPI / Pydantic / other direct dependencies: pinned exact versions in
  `uv.lock`.
