# apex-demo

A reference Oracle APEX application (spec section 20) showcasing the
gateway's routing and cost-estimation behavior: a Playground to send
prompts and see per-request routing/cost detail, a Dashboard of aggregate
metrics, a Request History report, and a Configuration Help page. It is a
**demo**, not part of the reusable product — `database/` (the
`APEX_AI_ROUTER` package) and `apex-plugin/` (the Dynamic Action plug-in)
are what an application actually integrating AI calls should use; this app
exists to make the gateway's own behavior visible and explorable.

> **Status:** built and exported from APEX 26.1 as `f1213.sql`, then
> reimported under a different application ID and exercised in a headless
> browser (`qa/browser_qa.mjs`). Playground — including `apex-auto` through
> a running NeMo Switchyard sidecar — the three Dynamic Action plug-in
> configurations, Dashboard, Request History, and Configuration Help passed
> against the local gateway and mock model providers with no browser
> console errors. Step-by-step, with screenshots:
> `docs/live-validation-walkthrough.md`.

## Why a support package instead of reusing `APEX_AI_ROUTER`

The reusable `apex_ai_router.generate()`/`.chat()` package
(`database/packages/`) returns only the assistant's response text, by
design (see `database/README.md`) — a normal application calling an AI
feature doesn't need routing/cost detail on every call. The Playground
page *does* need that detail (selected tier/model, latency, tokens,
estimated cost/baseline/savings, per spec section 20), so
`apex_ai_router_demo` (`sql/demo_playground_pkg.pks/.pkb`) makes its own
two direct HTTP calls instead of going through that package — full
reasoning, including an important correlation-gap finding, is in that
package's own header comment and in `HANDOFF.md`.

This is also why the demo app's server-side process holds a **read-only
admin** gateway credential in addition to the usual inference credential —
an explicit, documented trade-off appropriate for a reference app whose
purpose is showing cost/routing data, not a pattern to copy into an
arbitrary production page.

## Setup

1. `database/install.sql` (if not already installed for this schema).
2. `apex-demo/sql/install_demo.sql` — installs `apex_ai_router_demo` and
   seeds the `ADMIN_CREDENTIAL_STATIC_ID` config key.
3. Create two Web Credentials (Shared Components > Web Credentials):
   - `AIR_GATEWAY_CREDENTIAL` (if not already created for `database/`) —
     an inference API key as an HTTP Header credential
     (`Authorization: Bearer <inference-key>`).
   - `AIR_GATEWAY_ADMIN_CREDENTIAL` — a **separate** key, the gateway's
     `APEX_AI_ROUTER_ADMIN_API_KEY`, same header scheme. The gateway
     rejects an inference key on any `/admin/*` route by design
     (`gateway/src/apex_ai_router/api/admin.py`), so this must not be the
     same value as the inference credential.
4. Compile `apex-plugin/sql/install_plugin_package.sql` in the parsing
   schema.
5. Import `f1213.sql` in APEX Builder, choosing the target application ID
   and parsing schema (or with `apex_application_install`, see
   `docs/live-validation-walkthrough.md`). The export already contains the
   plug-in metadata, its JavaScript file, the four pages, navigation, and
   `playground.js`.

How the committed app reaches the gateway, all of it server-side:

- **Playground** calls `apex_ai_router_demo.ajax_run` from an Ajax Callback
  process (`PLAYGROUND_RUN`); it runs the inference call and then fetches
  that request's telemetry row to fill the decision card (route, target,
  upstream model, tier, latency, tokens, estimated cost, request id).
- **Dashboard** and **Request History** are native APEX components over
  the admin API: the KPI tiles come from `render_kpis`, and the four JET
  charts and the Interactive Report are SQL `json_table` queries over
  `apex_ai_router_demo.gateway_json('/admin/metrics/...')` /
  `gateway_json('/admin/requests?...')`. `gateway_json` holds the admin
  credential and only accepts the documented read-only paths.
- **Configuration Help** uses `ajax_config` for the routes/targets tables
  and the health pills, plus allowlisted `ajax_proxy` callbacks for
  `/health`, `/ready` and `/admin/routes`. `ajax_proxy` only accepts the
  documented read-only paths and keeps both credentials on the server.

## Pages

| Page | Doc | Summary |
|---|---|---|
| 1 — Playground | [`pages/01-playground.md`](pages/01-playground.md) | Send a prompt, see the response plus per-request routing/cost detail, including which backend answered an Auto request. |
| 2 — Dashboard | [`pages/02-dashboard.md`](pages/02-dashboard.md) | KPI tiles, four JET charts and a backends table over the admin metrics API. |
| 3 — Request History | [`pages/03-request-history.md`](pages/03-request-history.md) | Interactive Report over `/admin/requests` with a backend badge — never prompt/response content. |
| 4 — Configuration Help | [`pages/04-configuration-help.md`](pages/04-configuration-help.md) | Gateway endpoint, resolved model ids, `APEX_AI` setup link, health status — no secret values. |

## Cost-wording constraint (applies to every page)

Per spec section 29: always "Estimated cost" / "Estimated capable-model
baseline" / "Estimated savings" — never "Money saved" or "Guaranteed
savings." This project has no real billing integration; every number
comes from `config/pricing.yaml`-based estimation.

## Known gap: no all-time average latency

`/admin/metrics/summary` does not currently return a latency aggregate
(verified by reading `gateway/src/apex_ai_router/telemetry/store.py`) —
see `pages/02-dashboard.md`'s "Average Latency" card section for the
honestly-labeled approximation used instead, and `HANDOFF.md` for the
suggested gateway-side fix.

## Files

| Path | Purpose |
|---|---|
| `sql/demo_playground_pkg.pks` / `.pkb` | Support package for Page 1: `run_playground()` (called from SQL/PL-SQL directly) and `ajax_run()` (the page's Ajax Callback entry point). |
| `sql/install_demo.sql` | Compiles the support package and seeds `ADMIN_CREDENTIAL_STATIC_ID`. |
| `static/playground.js` | Page 1 client script. |
| `f1213.sql` | Sanitized APEX 26.1 application export (`scripts/sanitize_apex_export.py`), verified by reimport under another application ID. |
| `qa/browser_qa.mjs`, `qa/package.json` | Headless-browser QA of the imported app (Playwright + the installed Chrome); produces the screenshots in `docs/images/`. Credentials come from environment variables only. |
| `pages/*.md` | Page-by-page build notes: what the exported app contains, plus the original REST Data Source design as an alternative. |

## Manual and automated QA

See each page doc's own checklist (all items passed on 2026-09-17). The
exported implementation passed the live APEX 26.1 browser flow three times
on the built application and once more after reimport, with the mock
providers and the NeMo Switchyard sidecar running: Auto routed a short
prompt to the efficient backend and a long one to the capable backend.
`qa/browser_qa.mjs` is the automated version:

```sh
cd apex-demo/qa && npm install
APEX_USER=<workspace user> APEX_PASSWORD=<password> APP_ID=<app id> node browser_qa.mjs
```
