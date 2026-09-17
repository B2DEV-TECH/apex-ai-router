# Page 3 — Request History

Spec section 20: a read-only view over the gateway's own request log,
explicitly never showing prompt or response content — which the admin API
enforces at the source anyway (`TelemetryStore.list_requests()` never
selects `prompt_content`/`response_content`, regardless of whether
dev-only content logging is enabled; see `gateway/src/apex_ai_router/
telemetry/store.py`), so this page cannot leak that content even by
mistake.

> **What the exported app (`f1213.sql`) actually does.** A native
> Interactive Report whose source is
> `json_table(apex_ai_router_demo.gateway_json('/admin/requests?limit=500&offset=0'), '$.requests[*]' ...)`
> — so filtering, sorting, highlighting and download are the standard IR
> features, and the admin credential never leaves the database. Columns:
> timestamp, route, target, **backend** (`upstream_model`, rendered as a
> tier-coloured badge, `efficient` / `capable`), latency, tokens, estimated
> cost / baseline / savings, status and request id. The REST Data Source
> design below is the original plan and remains a declarative alternative
> with native paging past 500 rows.

## REST Data Source

`AIR_REQUESTS` — `GET /admin/requests` (paged via `limit`/`offset` query
parameters, max `limit` 500 per the endpoint's own validation), response
root `requests[]`, using the `AIR_GATEWAY_ADMIN_CREDENTIAL` Web Credential
(same as Page 2). Fields, copied verbatim from `store.py`'s
`list_requests()`:

```text
request_id, timestamp, route, policy, selected_target, selected_provider,
selected_model, routing_duration_ms, provider_duration_ms,
total_duration_ms, input_tokens, output_tokens, total_tokens,
estimated_cost, estimated_baseline_cost, estimated_savings, success,
http_status, error_code, retry_count, upstream_model
```

`upstream_model` is the model id the upstream reported in its response —
for `apex-auto` that is the backend Switchyard chose, which is what makes
the Backend column possible.

## Interactive Report columns (spec-required set, mapped to source fields)

| Spec column | Source field(s) | Notes |
|---|---|---|
| Timestamp | `timestamp` | |
| Route | `route` | The requested route (`apex-auto`/`apex-efficient`/`apex-capable`), not the resolved tier. |
| Selected Model | `selected_model` | The resolved model id actually used. |
| Latency | `total_duration_ms` | Label "Latency (ms)". |
| Tokens | `input_tokens` + `output_tokens` (or `total_tokens`) | Consider two columns (Input / Output) rather than collapsing to one, for parity with the Playground page. |
| Estimated Cost | `estimated_cost` | |
| Estimated Savings | `estimated_savings` | `null`/`n/a` for fixed routes (`apex-efficient`/`apex-capable`) — no baseline computed for those, same as Page 1. |
| Status | `success` (boolean) + `http_status` + `error_code` | Render as a badge: green "OK" when `success` is true, red with `error_code` (or `http_status` if `error_code` is null) when false. |

`selected_target` (`efficient`/`capable`/`judge`) is available from the
same Data Source and is a reasonable extra column to add even though the
spec's list doesn't name it explicitly, since it disambiguates
`apex-auto` requests without needing to decode `selected_model`.

## Explicitly excluded

- No prompt content, no response content — not selectable from this Data
  Source at all (enforced server-side, see above), so there's nothing to
  accidentally add. Do not add a custom column pointing at any other
  source that might contain it (e.g. do not join against
  `AIR_REQUEST_LOG` from `database/` for this report — that table is a
  separate, APEX-side log with its own retention and is out of scope for
  this page; see `database/README.md`).

## QA (run 2026-09-17 against the exported app, live gateway, mock providers and the Switchyard sidecar — `apex-demo/qa/browser_qa.mjs`)

- [x] Report loads with every row carrying a Backend badge and both tiers
      present (last run: 38 rows, 25 `efficient`, 13 `capable`), with no
      gateway error region.
- [x] The most recent rows match the Playground decision cards of the same
      session, request id for request id.
- [ ] Pagination past the admin API's 500-row cap: **not exercised** — the
      exported IR reads one page of up to 500 rows (`limit=500&offset=0`);
      the telemetry store never exceeded that during the validation.
- [ ] A failed request with a red Status badge and populated `error_code`:
      **not exercised** in the automated run (all requests succeeded with
      the sidecar up).
- [x] No column, filter, or export option exposes prompt/response text —
      the IR's only source is `/admin/requests`, whose `list_requests()`
      never selects content.
