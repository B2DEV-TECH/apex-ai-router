# Handoff notes

This project was built end-to-end (all 10 implementation phases) without
access to a live Oracle Database, an APEX Builder workspace, or any real
model provider credentials. Everything below is what a follow-up
contributor — human or a more capable model — should look at before
treating this as production-ready. Nothing here is a "known bug that was
shipped anyway silently": every item is also disclosed in the relevant
module's own README or in `README.md`'s Limitations section. This file
exists to collect them in one prioritized place, and to record a few
design decisions made under uncertainty so a reviewer doesn't have to
rediscover the reasoning from scratch.

Priority order below is: things that block calling this "validated" at
all, then real design/architecture gaps, then smaller polish items.

## 1. Nothing here has touched a live Oracle Database or APEX Builder

The single biggest gap. Everything in `database/`, `apex-plugin/`, and
`apex-demo/` was written against documented Oracle/APEX behavior
(`JSON_OBJECT_T`/`JSON_ARRAY_T` since 12.2, `APEX_WEB_SERVICE`, Web
Credentials since APEX 20.1, Dynamic Action plug-in APIs) and reviewed
carefully, but **none of it has been run**:

- `database/install.sql` has never been executed against a real Oracle
  instance. Run it in a disposable schema first, then `database/tests/
  smoke_test.sql` and `manual_gateway_test.sql` (the latter needs a real
  Web Credential pointed at a running gateway).
- The plug-in (`apex-plugin/src/apex_ai_router_da.pks/.pkb`,
  `apex-plugin/static/apex_ai_router_generate.js`) has never been built in
  APEX Builder, so there is no `apex-ai-router-plugin.sql` export — see
  `apex-plugin/dist/README.md`. Build it, run through
  `apex-plugin/README.md`'s manual QA checklist (it lists specific
  scenarios, all currently unchecked), export it, and commit the export.
- `apex-demo/` has no `f<app_id>.sql` because it was never imported into a
  workspace. Build it from `apex-demo/README.md`'s page specs, run it
  against a real gateway, and export it.

Recommended order: database objects first (nothing else works without
them), then the plug-in (depends on the database package or direct gateway
calls — see #6), then the demo app (exercises both).

## 2. Switchyard telemetry can't see past its own boundary

Documented in detail in `benchmark/README.md`'s ["An important limitation:
telemetry can't see past the Switchyard
boundary"](benchmark/README.md#an-important-limitation-telemetry-cant-see-past-the-switchyard-boundary)
section. Short version: for `apex-auto`, the gateway's telemetry records
`selected_target="switchyard"` and `selected_model="apex-auto"` literally —
it genuinely does not know which of efficient/capable Switchyard picked,
because that decision happens inside the sidecar over a plain HTTP call.
The benchmark's mock-mode workaround (parsing the mock model's own echoed
response text) only works in `--mode mock` and does not generalize to real
providers.

**Suggested fix**: have `switchyard-server` (or the gateway's
`SwitchyardProvider`) surface which backend it actually called — either a
response header/field Switchyard already exposes (check its current
version's API before assuming one needs to be added upstream) or, failing
that, a small patch that echoes the selected target name. Until this is
fixed, nobody can honestly report what fraction of `apex-auto` traffic
went to which tier, in production or in a real-provider benchmark.

## 3. SQLite telemetry is single-process by design, not by accident

`telemetry/store.py` uses one `sqlite3` connection per process. This is
empirically safe under the gateway's own execution model (single asyncio
event loop, no thread-pool offloading — see `tests/integration/
test_hardening.py`'s 20-concurrent-request test) but it is **not** a
design that scales to running multiple gateway processes/replicas against
one SQLite file. If this project is deployed with more than one gateway
instance, telemetry needs either a real database (Postgres/Oracle) or a
per-instance SQLite file with a separate aggregation step. This is called
out in `SECURITY.md` and `README.md` already; flagging it here so it isn't
missed as "just needs more replicas."

## 4. Benchmark quality/cost numbers only mean something in `--mode real`

`benchmark/results/mock-example/` is a real, committed run, but it is
against the local mock upstream, which always returns the same fixed
string at $0.00 regardless of prompt. Its own report documents four
specific ways this makes the numbers non-representative (see the report
itself, or `benchmark/README.md`'s "Known limitations of a `--mode mock`
run" section). **No claim about real cost savings or quality trade-offs
exists anywhere in this repository.** The first genuinely interesting
thing a follow-up contributor could do here is run `make benchmark-real`
against two real models (one cheap, one capable) and publish that result —
that is the number this project was actually built to produce, and it
does not exist yet.

## 5. Switchyard's rendered config assumes one wire format

`scripts/render_switchyard_config.py` renders every target in
`deploy/switchyard/routes.generated.toml` with a hard-coded
`format = "openai_chat"` (see `deploy/switchyard/routes.example.toml`).
This matches every target type this project currently supports
(OpenAI-compatible providers only), so it is not wrong today, but it means
adding a non-OpenAI-compatible provider format later requires updating the
render script's assumption, not just adding a routing.yaml entry. Worth a
comment or a `provider`-to-`format` mapping if a second format is ever
added.

## 6. Plug-in uses custom jQuery events, not first-class Plug-in Events

`apex-plugin/static/apex_ai_router_generate.js` fires
`apexairouter:success`/`apexairouter:error` as plain custom events rather
than registering them as declarative APEX Plug-in Events (see
`apex-plugin/README.md`, point 7 under "Standard Events"). This works —
any Dynamic Action can listen via Event type "Custom" — but if your APEX
version supports declaring Plug-in Events, doing so is more discoverable
for page builders than requiring them to know the custom event names.
Low priority; documented as "a reasonable enhancement," not a bug.

## 7. `APEX_AI_ROUTER` package returns text only, not raw gateway JSON

`database/packages/apex_ai_router.pkb`'s `generate()`/`chat()` extract and
return `choices[0].message.content` (a CLOB) rather than the full gateway
response body. This matches what nearly every page process actually wants
(the answer text), but it means metadata the gateway returns alongside the
answer — token counts, selected route/model, estimated cost — is not
reachable from PL/SQL today. If a caller needs that (for example, to log
it into `AIR_REQUEST_LOG` from PL/SQL instead of relying on the gateway's
own telemetry), the cleanest fix is a second function
(`generate_raw`/`chat_raw`) that returns the full JSON CLOB, rather than
changing the existing signature. See `database/README.md` for the current
design rationale.

## 8. Demo dashboard has no all-time average-latency metric

`apex-demo/README.md` already flags this: `GET /admin/metrics/summary`
does not currently expose an all-time average latency figure (only
per-window aggregates), so the planned Dashboard page can't show one
without either a gateway change (add the aggregate) or client-side
computation from `/admin/requests` (expensive at scale). Small, but worth
fixing before the demo app is actually built, since it's cheaper to add to
`admin.py` now than to retrofit after the demo page is wired to the
current shape.

## 9. Already resolved this release — mentioned so it isn't re-investigated

`RoutingConfigError` (and its subclass `PricingConfigError`) used to
escape `GET /v1/models`, `POST /v1/chat/completions`, and
`GET /admin/routes` completely uncaught, producing FastAPI's default
unsanitized 500 instead of the spec-required
`{"error": {"code","message","request_id"}}` shape. This was found via a
live clean-install smoke test (booting the server and `curl`ing it with a
deliberately broken `routing.yaml`), not by reading the code — the
existing 90-test suite had no coverage of this scenario. Fixed with one
global `@app.exception_handler(RoutingConfigError)` in `main.py` (catches
the subclass too, via Starlette's MRO-based handler lookup) and covered by
`tests/contract/test_routing_config_error_sanitization.py`. See
`CHANGELOG.md`'s `[0.1.0]` entry for the full writeup.

Given that this class of bug (a plain-`Exception` config error escaping an
endpoint's `except GatewayError` block) existed in three call sites at
once, this handoff originally suggested "a quick second pass over
`api/*.py` for any other exception type ... that might not inherit from
`GatewayError`." That pass turned out to be worth doing immediately: a
second instance was found the same session, this time a bare
`pydantic.ValidationError` escaping `RoutingConfig.model_validate()` /
`PricingConfig.model_validate()` (triggered by a target env var left
*set-but-empty*, e.g. `JUDGE_MODEL_ID=` in `.env` — see `CHANGELOG.md`'s
`[0.1.0]` entry for the full root-cause writeup). Also fixed, also
resolved this release, covered by six new tests across
`tests/unit/test_config_routing.py`, `tests/unit/test_config_pricing.py`,
and `tests/unit/test_health.py`, and re-verified live against the exact
`.env` that originally crashed. Both bugs are closed for the specific exception types found so far, but
the underlying pattern — a call site under `api/` or `config.py` that can
raise something other than `GatewayError`/`RoutingConfigError` — was only
audited reactively (fix a found crash, add a regression test), never
exhaustively. `providers/openai_compatible.py` and
`providers/switchyard_adapter.py` already convert `httpx.TimeoutException`
and `httpx.TransportError` to `ProviderError` (a `GatewayError`
subclass), so that specific class of failure is covered — but neither
this handoff nor the test suite has deliberately tried to enumerate every
other exception a third-party library call (`yaml.safe_load` on a
non-YAML file, an `httpx` response with an unexpected body shape, etc.)
could raise. A reviewer with more time should treat "sanitized errors
everywhere" as a property to keep re-verifying via smoke testing, not as
fully proven by these two fixes.

## 10. Process note: this was built without `uv`/`make` in the build shell

The implementation and test runs in this repository's history were
executed with `gateway/.venv/Scripts/python.exe -m {pytest,ruff,mypy}`
directly, because neither `uv` nor `make` was available in the shell used
to build this. The `Makefile` and `uv.lock`-based `uv sync` workflow
documented in every README are the intended path and were not
contradicted by anything found this way, but a fresh contributor's first
step should be confirming `make install && make test` works verbatim in
their own environment, since it was never exercised end-to-end here.

## 11. No standalone deployment/troubleshooting guide yet

`docs/README.md` notes that `deployment.md` and `troubleshooting.md` don't
exist yet. `docker-compose.yml` plus `README.md`'s Quick Start cover local
dev; nothing here yet documents a production deployment (reverse proxy /
TLS termination, running the gateway behind a process manager, running
`switchyard-server` as a long-lived service rather than a foreground
process) or a troubleshooting runbook for common failures (unresolved
`${VAR}` in routing.yaml, a missing `switchyard-server` binary, provider
timeouts). Worth writing once this has actually been deployed somewhere
once — writing a deployment guide before doing a real deployment risks
documenting an untested procedure as if it were verified.

## Not on this list

Everything else disclosed in `README.md`'s Limitations section (no
streaming, no non-OpenAI-compatible provider adapters, no stage/escalation
routing, NeMo Switchyard's own pre-production status) is a stated roadmap
gap, not an oversight — see `README.md`'s Roadmap section for sequencing.
