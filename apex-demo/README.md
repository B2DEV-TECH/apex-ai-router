# apex-demo

A reference Oracle APEX application (spec section 20) showcasing the
gateway's routing and cost-estimation behavior: a Playground to send
prompts and see per-request routing/cost detail, a Dashboard of aggregate
metrics, a Request History report, and a Configuration Help page. It is a
**demo**, not part of the reusable product — `database/` (the
`APEX_AI_ROUTER` package) and `apex-plugin/` (the Dynamic Action plug-in)
are what an application actually integrating AI calls should use; this app
exists to make the gateway's own behavior visible and explorable.

> **Status:** every page's design (items, processes, Dynamic Actions, REST
> Data Sources, exact source fields) is fully specified below and backed by
> a real, hand-verified support package (`sql/demo_playground_pkg.pks/
> .pkb`) and client script (`static/playground.js`). No live Oracle/APEX
> instance was available while building this project, so **no APEX
> application export (`f<app_id>.sql`) exists in this repository** — that
> file can only be produced by actually building these pages in APEX
> Builder and using Application Builder's own Export, the same reasoning
> already applied to `apex-plugin/dist/` (see `apex-plugin/dist/README.md`
> and `HANDOFF.md`). Building the four pages from the docs in `pages/`
> should be straightforward and fast for someone with APEX Builder access
> — most of the design work (data contracts, field names, wording) is
> already done and verified against the gateway's actual source code, not
> guessed.

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
4. Build the four pages per `pages/01-playground.md` ..
   `pages/04-configuration-help.md`, including the REST Data Sources
   listed in pages 2-4 (`AIR_METRICS_SUMMARY`, `AIR_METRICS_MODELS`,
   `AIR_METRICS_DAILY`, `AIR_ROUTES`, `AIR_REQUESTS`, `AIR_HEALTH`,
   `AIR_READY`).
5. Upload `static/playground.js` as a static application file and
   reference it from Page 1's JavaScript File URLs.

## Pages

| Page | Doc | Summary |
|---|---|---|
| 1 — Playground | [`pages/01-playground.md`](pages/01-playground.md) | Send a prompt, see the response plus per-request routing/cost detail. |
| 2 — Dashboard | [`pages/02-dashboard.md`](pages/02-dashboard.md) | Aggregate cards + charts over the admin metrics API. |
| 3 — Request History | [`pages/03-request-history.md`](pages/03-request-history.md) | Interactive Report over `/admin/requests` — never prompt/response content. |
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
| `pages/*.md` | Page-by-page build instructions (items, processes, Dynamic Actions, REST Data Sources). |

## Manual QA

See each page doc's own checklist. None of them have been run against a
live Oracle/APEX instance in this repository — same caveat as
`database/` and `apex-plugin/`, see `HANDOFF.md`.
