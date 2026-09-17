# Page 2 — Dashboard

Spec section 20. Read-only cards + charts, entirely backed by the
gateway's admin API — no direct SQLite access from APEX (the telemetry
database is the gateway process's own file, not something APEX should
reach into directly).

> **What the exported app (`f1213.sql`) actually does.** The KPI tiles are
> a PL/SQL region (`apex_ai_router_demo.render_kpis`, over
> `/admin/metrics/summary` and `/admin/metrics/backends`): Requests,
> Success rate, Estimated cost, Estimated capable-model baseline, Estimated
> savings, and *Auto requests answered by the efficient model*. The four
> charts are native JET chart regions whose SQL is `json_table(...)` over
> `apex_ai_router_demo.gateway_json('/admin/metrics/backends')` and
> `gateway_json('/admin/metrics/daily')`: *Backend that answered, per
> route*, *Requests by route*, *Requests per day (UTC)* and *Tokens per
> backend* — the routing-distribution question below is answered directly
> by `upstream_model`, no model-id join needed. A backends table
> (`render_backends_table`) repeats the breakdown as numbers, and two pills
> show `/health` and `/ready`. The latency card is omitted (option 2 in the
> gap note below). The REST Data Source design that follows is the
> original plan and remains a declarative alternative.

## REST Data Sources (Shared Components > REST Data Sources)

All three use the `AIR_GATEWAY_ADMIN_CREDENTIAL` Web Credential (see
`apex-demo/sql/install_demo.sql`) as an HTTP Header credential
(`Authorization: Bearer <admin-key>`), Base URL = your `AIR_CONFIG.
GATEWAY_BASE_URL` minus the `/v1` suffix (the admin API hangs off the
gateway root, not under `/v1` — verify against your deployed gateway's
actual mount path before pointing production traffic at this).

| REST Data Source | URL | Response root | Columns |
|---|---|---|---|
| `AIR_METRICS_SUMMARY` | `/admin/metrics/summary` | (object, not array — use "Single Row") | `requests`, `success_rate`, `estimated_cost`, `estimated_capable_baseline_cost`, `estimated_savings` |
| `AIR_METRICS_MODELS` | `/admin/metrics/models` | `models[]` | `model`, `requests`, `success_rate`, `input_tokens`, `output_tokens`, `estimated_cost`, `estimated_capable_baseline_cost`, `estimated_savings` |
| `AIR_METRICS_DAILY` | `/admin/metrics/daily` | `daily[]` | `date`, `requests`, `success_rate`, `estimated_cost`, `estimated_capable_baseline_cost`, `estimated_savings` |

Field names above are copied verbatim from
`gateway/src/apex_ai_router/telemetry/store.py`'s `summary()` /
`models_breakdown()` / `daily()` — not guessed.

## Cards (region source: `AIR_METRICS_SUMMARY`)

| Card | Source field | Label wording |
|---|---|---|
| Total Requests | `requests` | "Total Requests" |
| Success Rate | `success_rate` (fraction, format as `%`) | "Success Rate" |
| Estimated Cost | `estimated_cost` | "Estimated Cost" |
| Estimated Baseline Cost | `estimated_capable_baseline_cost` | "Estimated Baseline Cost" |
| Estimated Savings | `estimated_savings` | "Estimated Savings" |
| Average Latency | *(see gap below)* | "Average Latency" |

**Gap, honestly flagged:** `/admin/metrics/summary` has no latency
aggregate field (confirmed by reading `store.py`'s `summary()` — it
selects only `requests`, `successes`, and the three cost sums). There is
no all-time average latency anywhere in the current admin API. Two
options, neither fabricated:

1. **Recommended for this demo:** add a small region querying
   `/admin/requests?limit=500&offset=0` (the endpoint's own max page size)
   through a dedicated REST Data Source (`AIR_REQUESTS_RECENT`) and
   computing `AVG(total_duration_ms)` in a SQL query over that Data
   Source's synced table/view, with the card explicitly labeled "Average
   Latency (last up to 500 requests)" — not "all time."
2. Omit the card and note in the page why, until the gateway itself grows
   a real `avg_total_duration_ms` (or similar) summary field.

This gap is recorded in `HANDOFF.md` as a real gateway enhancement
candidate — `/admin/metrics/summary` should add a latency aggregate so the
Dashboard doesn't need the approximation above.

## Charts

| Chart | Source | Notes |
|---|---|---|
| Requests by model | `AIR_METRICS_MODELS`, `model` / `requests` | Bar chart. |
| Cost by model | `AIR_METRICS_MODELS`, `model` / `estimated_cost` | Bar chart. Label the series "Estimated Cost", not "Cost". |
| Requests per day | `AIR_METRICS_DAILY`, `date` / `requests` | Line chart. |
| Estimated savings per day | `AIR_METRICS_DAILY`, `date` / `estimated_savings` | Line chart. Label "Estimated Savings", not "Savings" or "Money Saved" (spec section 29). |
| Routing distribution | *(see below)* | Pie/donut chart, efficient vs. capable share of requests. |

**Routing distribution derivation:** the admin API has no direct
"requests grouped by selected tier" endpoint — `/admin/metrics/models`
groups by `selected_model`, not by tier (`efficient`/`capable`). Build
this chart by joining `AIR_METRICS_MODELS` (`model`, `requests`) against
`/admin/routes`'s `targets` object (a third REST Data Source,
`AIR_ROUTES`, `GET /admin/routes`, response root `targets` — an object
keyed by target name, each with a `model` field) to map each
`selected_model` back to its target name (`efficient`/`capable`/`judge`),
then `SUM(requests)` grouped by that mapped target name. This is a real
join over real fields, not a fabricated distribution — but note it breaks
if two targets are ever configured with the same underlying model id
(uncommon, but `routing.yaml` does not forbid it); call this out in the
page's own help text if you build it.

## Wording constraint (applies to every label above)

Per spec section 29: use "Estimated cost" / "Estimated capable-model
baseline" / "Estimated savings" everywhere. Never "Money saved" or
"Guaranteed savings" — this project has no real billing integration, only
`config/pricing.yaml`-based estimation (see `gateway/README.md`'s cost
section).

## QA (run 2026-09-17 against the exported app, live gateway, mock providers and the Switchyard sidecar — `apex-demo/qa/browser_qa.mjs`)

- [x] All six KPI tiles show a value (none `n/a`) after the Playground
      requests, and the health/readiness pills read `ok` / `ready`.
- [x] All four JET charts render an SVG with data from the gateway
      (`json_table` over `gateway_json`), with no gateway error region on
      the page.
- [x] Reloading the Dashboard after further Playground requests reflects
      the new counts (the screenshots in `docs/images/04-dashboard.png` were
      taken after the Playground run of the same session).
- [ ] Empty-telemetry rendering (`requests = 0` → `n/a`, `success_rate`
      `null`): handled in `render_kpis`, but **not exercised** — the
      telemetry store was never empty during the validation.
