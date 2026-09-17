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
- Oracle database integration (spec sections 16-17, `database/`):
  `AIR_CONFIG` (non-secret gateway config) and `AIR_REQUEST_LOG` (APEX
  application-context log — app id, page id, session id, route, HTTP
  status, duration; never prompt/response content, never gateway
  cost/token telemetry, which stays exclusively in the gateway's own
  `TelemetryStore`) tables, plus `AIR_MODEL_USAGE_V` and
  `AIR_DAILY_USAGE_V` reporting views.
- `APEX_AI_ROUTER` PL/SQL package (`database/packages/`): `generate(p_prompt,
  p_route, p_session_id, p_temperature)` and `chat(p_messages_json, p_route,
  p_session_id)`, both calling the gateway's `POST /v1/chat/completions` via
  `APEX_WEB_SERVICE.MAKE_REST_REQUEST` with an APEX Web Credential (the
  package never reads or stores the gateway API key itself), and returning
  the parsed assistant response text. Named exceptions
  (`e_unknown_route`/`e_gateway_error`/`e_missing_config`, ORA-20050..52)
  for callers to handle specific failure modes. `p_session_id` is threaded
  through to logging in preference to the ambient APEX session.
- `database/install.sql` / `uninstall.sql`, optional cross-schema
  `database/grants/*.sql`, and `database/tests/smoke_test.sql` (a
  network-free check of object validity, required config, and unknown-route
  handling).
- `docs/apex-ai-setup.md`: guide for pointing an APEX `APEX_AI` Generative
  AI Service directly at the gateway (`model=apex-auto`) — the
  lowest-friction adoption path, requiring neither the PL/SQL package nor
  the plug-in (spec section 45). Exact Builder field names are explicitly
  flagged as unverified against a live APEX instance, per spec section 17's
  own instruction not to invent them.
- `database/tests/manual_gateway_test.sql`: a documented, non-automated
  test that exercises `generate()` against a real reachable gateway, for
  operators to run by hand once a gateway and Web Credential are in place.

**Caveat:** the Phase 5 SQL/PL/SQL above has not been compiled or run
against a live Oracle Database or APEX workspace in this repository (no
Oracle instance was available in the environment it was built in). It is
hand-verified against documented Oracle/APEX APIs
(`JSON_OBJECT_T`/`JSON_ARRAY_T`, `APEX_WEB_SERVICE.MAKE_REST_REQUEST` with
`p_credential_static_id`). See `database/README.md` and `HANDOFF.md`.

- APEX Dynamic Action plug-in, "APEX AI Router - Generate" (spec sections
  18-19, `apex-plugin/`): `apex_ai_router_da.render()`/`.ajax()` PL/SQL
  callbacks and a client-side script
  (`static/apex_ai_router_generate.js`) implementing the
  browser → APEX Ajax callback → gateway flow — the browser never calls a
  model provider directly. Declarative attributes (Prompt Source Type/Value,
  Route, Result Page Item, Temperature, Session ID Page Item, Show
  Processing Indicator, Error Page Item) match the spec's attribute list;
  no JavaScript is required for basic usage (see
  `apex-plugin/examples/dynamic_action_example.md`). Errors are always
  returned as a controlled `{"success":false,"error":"..."}` JSON body
  instead of an uncaught exception, and success/error are also exposed as
  custom jQuery events (`apexairouter:success`/`apexairouter:error`) for
  declarative chaining.

**Caveat:** the plug-in has not been built or exported from a live APEX
Builder in this repository — no Oracle/APEX instance was available. Its
PL/SQL and JS source is written against the stable, documented APEX plug-in
framework, but `apex-plugin/dist/` has no machine-generated export SQL yet
(APEX's plug-in export format embeds internal sequence IDs and encoded file
content that only APEX Builder's own Export can produce correctly — see
`apex-plugin/dist/README.md`), and the exact client-side contract for a
Dynamic Action plug-in's `javascript_function` callback should be confirmed
against the APEX Plug-In Developer's Guide for the reader's installed
version. See `apex-plugin/README.md` and `HANDOFF.md`.

- Demo APEX application (spec section 20, `apex-demo/`): a reference app
  with four pages, fully specified in `apex-demo/pages/*.md` --
  **Playground** (send a prompt, see the response plus selected
  tier/model, latency, tokens, and estimated cost/baseline/savings for
  that exact request), **Dashboard** (cards + charts over the gateway's
  admin metrics API), **Request History** (an Interactive Report over
  `/admin/requests`, never showing prompt/response content), and
  **Configuration Help** (gateway endpoint, resolved model ids, `APEX_AI`
  setup link, health status -- no secret values).
- `apex_ai_router_demo` PL/SQL support package
  (`apex-demo/sql/demo_playground_pkg.pks/.pkb`): `run_playground()` makes
  two direct gateway HTTP calls (a chat completion with the inference
  credential, then an `/admin/requests` lookup with a separate read-only
  admin credential, matched by the gateway's `X-Request-Id` header) rather
  than going through `apex_ai_router.generate()`, because that package
  intentionally returns only response text. This is an explicit,
  documented demo-only trade-off (the app holds a read-only admin
  credential server-side) -- see `apex-demo/README.md` and `HANDOFF.md`.
- `apex-demo/static/playground.js`: Page 1's client script, talking only
  to the page's own Ajax Callback, never to the gateway directly from the
  browser.
- `apex-demo/sql/install_demo.sql`: installs the support package and
  idempotently seeds the demo-only `ADMIN_CREDENTIAL_STATIC_ID` config key
  without touching `database/install.sql`'s own seed rows.

**Caveat:** as with Phases 5-6, none of `apex-demo/` has been built or run
against a live Oracle/APEX instance in this repository. Additionally, this
phase surfaced two real, previously-undocumented gaps rather than papering
over them: (1) the gateway's internal `request_id` (`X-Request-Id` header)
and the OpenAI-shaped chat-completion response's own `id` field are two
unrelated identifiers -- `AIR_REQUEST_LOG.gateway_response_id` (Phase 5)
therefore cannot actually be correlated against `/admin/requests` by that
field, only by `X-Request-Id`, which is what `apex_ai_router_demo` uses;
(2) `/admin/metrics/summary` has no latency aggregate field, so the
Dashboard's "Average Latency" card can only be an explicitly-labeled
approximation over the most recent requests, not a true all-time average.
Both are recorded in `HANDOFF.md`.

- Benchmark harness (spec sections 26-29, 32, 51-52, Phase 8, `benchmark/`):
  a 34-task synthetic dataset (`tasks/tasks.yaml`) across the 14 categories
  from spec section 26, all referencing the same small synthetic schema
  (`T_CUSTOMERS`/`T_ORDERS`/`T_INVOICES`); `scoring.py`'s six deterministic
  scorers (`valid_json`, `keyword_presence`, `classification_exact_match`,
  `sql_clauses`, `plsql_structure`, `regex_match`), each an explicitly
  documented heuristic rather than a real parser or compiler; an optional
  `judge.py` LLM-judge pass for the 17 tasks marked `judge_eligible: true`,
  itself a real gateway request through `apex-capable` whose cost/tokens
  are tracked separately and never hidden (spec 27).
- `runner.py`: runs the full dataset through all three execution modes
  (fixed `apex-efficient`, fixed `apex-capable`, `apex-auto`) against a
  real gateway over real HTTP, then reconciles routing/cost/timing detail
  from a single paginated `GET /admin/requests` lookup matched by
  `X-Request-Id` -- the same two-call correlation pattern as the demo
  app's Playground page. `--mode mock` spawns the project's own mock
  upstream, the real `switchyard-server` binary (if built), and the
  gateway itself as real local subprocesses on free loopback ports, with a
  temporary routing config and telemetry database -- no network access or
  credentials required. `--mode real` talks to an already-running gateway
  and, per spec section 28, writes an explicit UNMEASURED report instead
  of inventing numbers if it is unreachable or missing credentials.
  `report.py` writes the resulting Markdown + JSON report, including an
  explicit mock-mode limitations section, a comparison table, an Auto vs
  Capable delta block, a per-category breakdown, and a judge-results
  section.
- `make benchmark-mock` / `make benchmark-real` targets.
- `benchmark/results/mock-example/`: a real, committed `--mode mock
  --judge` run over all 34 tasks (not a hand-written sample), so a reader
  can see the exact shape of a report without building and running the
  harness first.

**Caveat:** this phase surfaced a real, previously undocumented
architectural limitation rather than papering over it: the gateway's own
`/admin/requests` telemetry cannot see which backend `apex-auto` actually
selected inside the `switchyard-server` sidecar -- `selected_target` and
`selected_model` are fixed literals (`"switchyard"`/`"apex-auto"`) for any
`llm_classifier`-routed call, in every mode, mock or real
(`routing/service.py`, `api/openai_chat.py`). The harness recovers the
real choice in `--mode mock` only, via a diagnostic that parses the mock
server's own echoed response text (`response_content` contains the exact
`model` string it received); this does not generalize to `--mode real`,
where no equivalent telemetry field currently exists. See
`benchmark/README.md` and `HANDOFF.md` for the suggested fix.

- Hardening (spec sections 22-24, 60, Phase 9): a genuine, previously
  undocumented spec-compliance gap was found and fixed -- section 24
  requires "Include retry count in telemetry," but no `retry_count` field
  existed anywhere in the pipeline despite the retry/timeout/backoff logic
  itself already being correct in both provider adapters. Fixed end to
  end: `providers/base.py` gained a `ProviderResult(body, retry_count)`
  return type (replacing a bare `dict`) so retry information travels from
  the HTTP retry loop to the API layer without a second return channel;
  `GatewayError` gained a `retry_count` attribute so the failure path
  reports it too; `RequestTelemetry.retry_count` and a new
  `telemetry/store.py` migration (`ALTER TABLE ai_request ADD COLUMN
  retry_count`) persist it; it is automatically exposed by
  `GET /admin/requests` (no schema-filtering code to change there). New
  regression tests cover both providers' retry-count reporting, including
  two previously-missing timeout-exception tests that had no coverage for
  either adapter before this phase.
- `tests/integration/test_hardening.py`: two hardening claims that were
  previously only asserted in docstrings/`SECURITY.md`, now empirically
  tested rather than just documented -- (1) concurrency: 20 truly
  concurrent requests fired within a single asyncio event loop via
  `httpx.ASGITransport` (unlike the thread-based `TestClient` used
  elsewhere) each get exactly one, correctly-matched telemetry row,
  validating `telemetry/store.py`'s single-connection design under this
  project's single-event-loop execution model; (2) log leakage: a request
  carrying a marked secret API key and prompt is confirmed to never
  produce a formatted JSON log line containing either, on both the
  success and the authentication-failure path.
- `SECURITY.md` updated to match: the "Secrets in Git or logs" row no
  longer claims an active log-redaction mechanism that doesn't exist --
  the accurate description is that the one logging call site in the
  request path never includes secrets or content in the first place, now
  backed by the test above rather than only asserted. Added a "Telemetry
  data integrity under concurrent requests" row documenting the
  single-connection concurrency model as an explicit, tested, single-
  process design choice (not built for multi-process horizontal scaling
  against one SQLite file -- see `HANDOFF.md`).

### Fixed

- `load_routing_config`'s `${VAR}` substitution no longer uses
  `os.path.expandvars`: on Windows, `ntpath.expandvars` applies POSIX-style
  single-quote quoting, so one unmatched `'` anywhere earlier in
  `routing.yaml` (plausible in a comment or string value) silently disabled
  substitution for the rest of the file. Replaced with an explicit,
  quote-agnostic `${VAR}` regex substitution. The unresolved-placeholder
  check at load time now also covers `base_url`, not just `model`.
- `benchmark/runner.py`'s `--mode mock` subprocess orchestration
  (`MockEnvironment`): nothing continuously drained a spawned
  subprocess's stdout/stderr pipe, so once a subprocess's cumulative log
  output exceeded the OS pipe buffer (commonly 64KB) it blocked on its own
  next write -- a real deadlock caught by live execution, not static
  review, that surfaced as one in-flight request hanging for the full
  request timeout while every other call in the same run completed in
  ~200ms. Fixed with a bounded per-process background drain thread
  (`collections.deque(maxlen=500)`); verified by a clean re-run with no
  timeouts.
- `RoutingConfigError` (and its subclass `PricingConfigError`), raised by
  `config.py` when `routing.yaml`/`pricing.yaml` fails to load or has an
  unresolved `${VAR}` placeholder, is a plain `Exception`, not a
  `GatewayError` -- it used to escape `GET /v1/models`,
  `POST /v1/chat/completions` (both the routing-config and pricing-config
  lookups), and `GET /admin/routes` completely uncaught, producing
  FastAPI's default unsanitized 500 (a raw stack trace) instead of the
  spec-required `{"error": {"code","message","request_id"}}` shape --
  a real violation of the "errors are sanitized" definition-of-done bullet,
  found via a live clean-install smoke test (`curl`ing a booted server),
  not by reading the code or by the existing test suite, which had no
  coverage of this scenario. Fixed with one global
  `@app.exception_handler(RoutingConfigError)` in `main.py`, mapped to the
  `routing_failed` error code, covering every current and future call
  site rather than patching each one individually. Verified both by a new
  `tests/contract/test_routing_config_error_sanitization.py` covering all
  three endpoints and by re-running the exact `curl` sequence that
  originally surfaced the crash.
