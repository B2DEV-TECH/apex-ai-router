# Handoff notes

## Active checkpoint — resume here

Branch: `feat/live-apex-validation`. Worktree used for this validation:
`C:\Users\geefa\Documents\B2DEVTECH\apex-ai-router-live-validation`.

The latest clean APEX build is application **1213**. It includes the fixes
from the final code review: Dashboard charts, `n/a` handling for empty
telemetry, paged/filterable/downloadable Request History, dynamic
`AIR_CONFIG.GATEWAY_BASE_URL`, a real native-setup link, readable proxy
errors, exact “Estimated cost” wording, spinner-off coverage, and plug-in
success/error event coverage. Its expanded browser QA passed once with 47
history rows and no console errors. The mock telemetry store was then
filled to 107 requests so pagination past 100 could be tested.

**The exact next action is to rerun:**

```powershell
$env:APEX_PASSWORD='<local ignored value>'
$env:APP_ID='1213'
node .tools\qa_demo_runtime.mjs
```

That run was interrupted by the user after 6.7 seconds. The script now
clicks Next when more than 100 history rows exist and expects a “Rows 101”
label. Confirm the output includes `secondPageRows` and no console errors.

After that run:

1. Add a focused Node regression test for
   `apex-plugin/static/apex_ai_router_generate.js`, covering the native
   Dynamic Action context through `this`, Ajax identifier forwarding,
   spinner Y/N, and success/error events. This was the remaining Important
   code-review finding.
2. Decide/document the deliberate implementation choice: the validated app
   uses allowlisted APEX Ajax callbacks plus custom charts and a paged table,
   rather than native APEX REST Data Sources and an Interactive Report. The
   functional gaps (charts, pagination, filters, CSV) are now covered, but
   the original implementation plan still names native components.
3. Update the page QA checklists to reflect the paths actually exercised.
4. Export application 1213 over the current `apex-demo/f1207.sql` artifact
   (rename consistently if desired), sanitize workspace/schema/instance
   defaults again, reimport it under a fresh application ID, and rerun the
   browser QA. The currently committed/exported `f1207.sql` predates the
   final review fixes and must not be presented as the final artifact.
5. Re-export the plug-in only if its metadata/static file changes. Its
   current sanitized export already reimported successfully with eight
   attributes.
6. Run the final Oracle compile/smoke script, the Python 3.12 container
   suite (98 passed, 1 optional Switchyard test skipped, Ruff/mypy clean),
   secret scan, and `git diff --check`; then replace this checkpoint with a
   completed validation record.

Local credentials and helper scripts remain ignored under `.env` and
`.tools/`. Do not copy them into tracked files or command output committed
to Git.

This project has now been exercised end to end with Oracle Database 23ai
Free, APEX 26.1, and the local mock gateway stack. Everything below is what
a follow-up contributor should still look at before treating it as
production-ready. Remaining limits are also disclosed in the relevant
module README or in `README.md`.

Priority order below is: things that block calling this "validated" at
all, then real design/architecture gaps, then smaller polish items.

## 1. Resolved: live Oracle/APEX build and export

On 2026-09-17, the project was validated on Oracle Database 23ai Free and
APEX 26.1 against the local gateway and mock providers:

- `database/install.sql`, `database/tests/smoke_test.sql`, and the manual
  PL/SQL gateway round trip passed.
- The Dynamic Action plug-in was built and exported. Its sanitized export
  under `apex-plugin/dist/` reimported into a clean application with all
  eight attributes.
- The four-page demo was built and exported as `apex-demo/f1207.sql`. That
  file reimported under a different application ID, and Playground,
  Efficient/Capable plug-in actions, controlled Auto failure, Dashboard,
  Request History, and Configuration Help passed in a browser without
console errors.

The live work exposed and fixed real compatibility issues: portable SQL
includes, SQL*Plus substitution in URL strings, APEX 26.1 plug-in API
version and attribute serialization, Ajax identifier propagation, Dynamic
Action context through JavaScript `this`, button static-ID metadata, admin
endpoint derivation, and numeric HTML escaping. The committed exports have
local workspace, schema, and instance defaults neutralized.

This validation used mock providers. Fixed routing passed; `apex-auto`
could only verify controlled failure because the Switchyard sidecar was not
running. Real-provider quality and cost remain unmeasured.

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

## 10. Resolved: `uv` / `make` workflow

`make install && make test` now runs with development dependencies included
and passed end to end. The direct gateway checks also passed: 98 tests, one
optional Switchyard integration test skipped, plus clean `ruff` and `mypy`
runs.

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
