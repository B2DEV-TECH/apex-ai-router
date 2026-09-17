# Page 3 — Request History

Spec section 20: an Interactive Report over the gateway's own request log,
explicitly never showing prompt or response content — which the admin API
enforces at the source anyway (`TelemetryStore.list_requests()` never
selects `prompt_content`/`response_content`, regardless of whether
dev-only content logging is enabled; see `gateway/src/apex_ai_router/
telemetry/store.py`), so this page cannot leak that content even by
mistake.

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
http_status, error_code
```

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

## Manual QA (requires a live gateway + APEX instance — not run in this repository)

- [ ] Report loads and paginates correctly past the admin API's 500-row
      page cap (Interactive Report's own pagination should issue
      additional `offset`-based REST Data Source calls transparently).
- [ ] A failed request (e.g. an unknown route sent directly to
      `/v1/chat/completions`) appears with a red Status badge and a
      populated `error_code`.
- [ ] No column, filter, or export option on this page ever exposes
      prompt/response text.
