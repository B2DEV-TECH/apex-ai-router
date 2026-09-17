# apex-demo

A reference Oracle APEX application (spec section 20) showcasing the
gateway's routing and cost-estimation behavior: a Playground to send
prompts and see per-request routing/cost detail, a Dashboard of aggregate
metrics, a Request History report, and a Configuration Help page. It is a
**demo**, not part of the reusable product — `database/` (the
`APEX_AI_ROUTER` package) and `apex-plugin/` (the Dynamic Action plug-in)
are what an application actually integrating AI calls should use; this app
exists to make the gateway's own behavior visible and explorable.

> **Status:** built and exported from APEX 26.1 as `f1207.sql`, then
> reimported under a different application ID and exercised in a headless
> browser. Playground, the three Dynamic Action plug-in configurations,
> Dashboard, Request History, and Configuration Help passed against the
> local gateway and mock model providers with no browser console errors.

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
5. Import `f1207.sql` in APEX Builder, choosing the target application ID
   and parsing schema. The export already contains the plug-in metadata,
   its JavaScript file, the four pages, navigation, and `playground.js`.

The committed app uses APEX Ajax Callback processes for the read-only
gateway views. `apex_ai_router_demo.ajax_proxy` keeps both credentials on
the server and restricts requests to the seven documented health, route,
metrics, and history paths.

## Pages

| Page | Doc | Summary |
|---|---|---|
| 1 — Playground | [`pages/01-playground.md`](pages/01-playground.md) | Send a prompt, see the response plus per-request routing/cost detail. |
| 2 — Dashboard | [`pages/02-dashboard.md`](pages/02-dashboard.md) | Aggregate cards and tables over the admin metrics API. |
| 3 — Request History | [`pages/03-request-history.md`](pages/03-request-history.md) | Read-only table over `/admin/requests` — never prompt/response content. |
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
| `f1207.sql` | Sanitized APEX 26.1 application export, verified by reimport under another application ID. |
| `pages/*.md` | Page-by-page build instructions (items, processes, Dynamic Actions, REST Data Sources). |

## Manual QA

See each page doc's own checklist. The exported implementation passed the
live APEX 26.1 browser flow documented in `docs/smoke-test.md`; the fixed
routes used mock providers, and the Auto route intentionally exercised a
controlled failure because Switchyard was not running.
