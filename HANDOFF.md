# Handoff notes

## Validation record — 2026-09-17 (branch `feat/live-apex-validation`)

The live validation is complete and written up in
`docs/live-validation-walkthrough.md` (steps, expected results per page,
screenshots in `docs/images/`, and a results table). What was done, in
order:

1. `upstream_model` telemetry (the backend Switchyard reports having
   called) was added to the gateway, `/admin/requests`, a new
   `/admin/metrics/backends`, and the benchmark report; the mock judge was
   made deterministic (word count). Python suite: 106 passed, `ruff` and
   `mypy` clean.
2. `switchyard-server` was built at the pinned commit and run against the
   mock model ports with `scripts/run_switchyard_local.ps1`; the routing
   log confirmed judge + backend calls per Auto request.
3. The demo application (**1213**) was rebuilt around native components —
   Interactive Report and four JET charts as `json_table` over the gateway
   JSON, a Playground decision card with route/target/upstream model — and
   passed the headless browser QA three times (0 failed expectations, 0
   console errors; Auto short → efficient, Auto long → capable; plug-in
   3/3; both tiers badged in Request History).
4. `apex-plugin/tests/apex_ai_router_generate.test.mjs` (10 Node tests)
   covers the plug-in client script: `this` context, Ajax identifier,
   spinner Y/N, success/error items and events.
5. Application 1213 was exported, sanitized with the new
   `scripts/sanitize_apex_export.py` (workspace id, owner, exporter and
   audit user names neutralized) into `apex-demo/f1213.sql`, reimported as
   a throwaway application id, and passed the same QA; the throwaway app
   was then removed. `apex-demo/f1207.sql` was deleted.
6. The QA script was committed as `apex-demo/qa/browser_qa.mjs` (reads the
   user, password and application id from the environment) and run once
   more from its tracked location.

Not done, on purpose: no real model provider was involved, and no
cost/quality number is claimed. See "What this proves, and what it does
not" in the walkthrough.

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
- The four-page demo was built and exported as `apex-demo/f1213.sql`. That
  file reimported under a different application ID, and Playground (Auto
  through Switchyard, fixed routes, all three plug-in prompt sources),
  Dashboard, Request History, and Configuration Help passed in a browser
  without console errors (`docs/live-validation-walkthrough.md`).

The live work exposed and fixed real compatibility issues: portable SQL
includes, SQL*Plus substitution in URL strings, APEX 26.1 plug-in API
version and attribute serialization, Ajax identifier propagation, Dynamic
Action context through JavaScript `this`, button static-ID metadata, admin
endpoint derivation, and numeric HTML escaping. The committed exports have
local workspace, schema, and instance defaults neutralized.

This validation used mock providers. Fixed routing passed, and `apex-auto`
passed through a running Switchyard sidecar (short prompt → efficient,
long prompt → capable, per the mock judge's word-count rule). The
controlled-failure path (sidecar stopped) was exercised earlier the same
day. Real-provider quality and cost remain unmeasured.

## 2. Resolved: which backend `apex-auto` called is now recorded

Previously the gateway's telemetry stopped at `selected_target="switchyard"`
and could not say which of efficient/capable the sidecar picked. Switchyard
returns the backend's model id in the `model` field of its
OpenAI-compatible response; the gateway now stores that verbatim as
`upstream_model` (also populated for fixed routes, from the provider's
response), exposes it in `/admin/requests` and aggregates it in
`GET /admin/metrics/backends`. The benchmark report's "backend actually
called" line reads it, and the mock-mode echo-text parsing is kept only as
a cross-check that must agree with it. Details:
`benchmark/README.md`, ["Which backend did `apex-auto` actually
call?"](benchmark/README.md#which-backend-did-apex-auto-actually-call-upstream_model).

What is still not visible from the gateway: the classifier's score and
threshold, and the judge call itself. Switchyard's `--routing-log-file`
(JSON lines; `scripts/run_switchyard_local.*` enable it) is the record for
that, and `docs/live-validation-walkthrough.md` shows how to reconcile the
two. Exposing the score would need a Switchyard-side change.

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
