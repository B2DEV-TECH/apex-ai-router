# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Repository foundation: monorepo layout, Apache-2.0 license, README,
  SECURITY.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md.
- Gateway skeleton (`gateway/`): FastAPI app factory, environment-based
  settings, structured JSON logging.
- `GET /health` and `GET /ready` endpoints.
- Local mock upstream model servers (`gateway/src/apex_ai_router/mocks/`)
  for development and integration testing, with configurable behaviors
  (success, slow, rate-limited, error, malformed, large token usage).
- `docker-compose.yml` running the gateway plus two mock model servers.
- Unit tests for settings and health/readiness endpoints.
- OpenAI-compatible `GET /v1/models` and `POST /v1/chat/completions`
  endpoints, backed by a real `httpx`-based provider adapter
  (`OpenAICompatibleProvider`) with bounded retries, timeouts, and
  OpenAI-shaped error mapping. `apex-efficient` and `apex-capable` fixed
  routes are fully wired end to end against `routing.yaml`.
- `apex-auto` (Switchyard-backed `llm_classifier` routing, spec section 11):
  `SwitchyardProvider` forwards requests to a `switchyard-server` sidecar;
  `render_routes_toml` renders that sidecar's native `routes.toml` directly
  from `routing.yaml`, so the classifier's efficient/capable/judge targets
  and threshold are configured in exactly one place. Deployment tooling in
  `deploy/switchyard/` (`README.md`, `routes.example.toml`) and
  `scripts/render_switchyard_config.py`.
- Real end-to-end integration test running the actual compiled
  `switchyard-server` binary against the mock upstream (skips automatically
  if the binary hasn't been built locally; see `deploy/switchyard/README.md`).
- Telemetry and cost estimation (spec sections 12-15): every
  `POST /v1/chat/completions` request is timed (routing duration, provider
  duration, total duration), its token usage and routing metadata are
  recorded, and its cost is estimated from `config/pricing.yaml` via a
  small cost engine (`telemetry/cost.py`) that returns an explicit
  "unknown" result (never a fabricated zero) for any model with no pricing
  entry. `apex-auto` requests additionally get an approximate
  capable-model baseline comparison (estimated savings and savings
  percent), computed against the route's `capable_target` using the same
  observed token counts — a documented approximation, not an independent
  estimate of what the capable model would actually have produced.
- `TelemetryStore` (`telemetry/store.py`): a single-file SQLite store with
  a minimal `PRAGMA user_version` migration mechanism, storing
  `ai_request`, `ai_model_pricing`, and `ai_route_config_snapshot`.
  Prompt/response content is only persisted when the operator explicitly
  opts in (`APEX_AI_ROUTER_TELEMETRY_LOG_CONTENT=true`); it is off by
  default and, regardless of the setting, is never selected by any admin
  API query.
- Read-only admin API (`GET /admin/metrics/summary`, `/admin/metrics/models`,
  `/admin/metrics/daily`, `/admin/requests`, `/admin/routes`), authenticated
  by a separate `APEX_AI_ROUTER_ADMIN_API_KEY` that is entirely independent
  of the inference API key(s) — an inference key can never authenticate an
  admin request.
- New settings: `APEX_AI_ROUTER_PRICING_CONFIG`,
  `APEX_AI_ROUTER_TELEMETRY_DB_PATH`, `APEX_AI_ROUTER_TELEMETRY_LOG_CONTENT`,
  `APEX_AI_ROUTER_ADMIN_API_KEY` (documented in `.env.example`).
- Unit and integration tests for the cost engine, the telemetry store, and
  the admin API, including an end-to-end test that makes a real chat
  completion request and confirms it is both recorded and visible through
  the admin API.

### Fixed

- `load_routing_config`'s `${VAR}` substitution no longer uses
  `os.path.expandvars`: on Windows, `ntpath.expandvars` applies POSIX-style
  single-quote quoting, so one unmatched `'` anywhere earlier in
  `routing.yaml` (plausible in a comment or string value) silently disabled
  substitution for the rest of the file. Replaced with an explicit,
  quote-agnostic `${VAR}` regex substitution. The unresolved-placeholder
  check at load time now also covers `base_url`, not just `model`.
