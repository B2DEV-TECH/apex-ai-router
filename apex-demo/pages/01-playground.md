# Page 1 — Playground

Spec section 20. Lets a user send one prompt through the gateway and see
the routing/cost detail for that exact request.

## Prerequisites

- `database/install.sql` run (provides `AIR_CONFIG`, `apex_ai_router`).
- `apex-demo/sql/install_demo.sql` run (provides `apex_ai_router_demo`,
  seeds the `ADMIN_CREDENTIAL_STATIC_ID` config key).
- Two Web Credentials created: `AIR_GATEWAY_CREDENTIAL` (inference key) and
  `AIR_GATEWAY_ADMIN_CREDENTIAL` (admin key) — see
  `apex-demo/sql/install_demo.sql`'s "Next steps".

## Page items

| Item | Type | Notes |
|---|---|---|
| `P1_PROMPT` | Textarea | Required. |
| `P1_ROUTE` | Select List | List of Values: `AUTO`/`EFFICIENT`/`CAPABLE` display Auto/Efficient/Capable. Default `AUTO`. |
| `P1_SEND` | Button | Label "Send". Action: Defined by Dynamic Action below (not a page submit — this is an Ajax-only page). |
| `P1_RESULT` | Textarea, read-only | The assistant's response text. |
| `P1_ERROR` | Display Only, Escape special characters | Empty unless the last request failed. |
| `P1_SELECTED_TIER` | Display Only | e.g. `efficient` / `capable`. |
| `P1_SELECTED_MODEL` | Display Only | Resolved model id the gateway actually used. |
| `P1_LATENCY_MS` | Display Only | Wall-clock time of the Playground's own `POST /v1/chat/completions` call, measured in PL/SQL — not the gateway's internal `total_duration_ms` (informational difference, both are legitimate, see `apex-demo/sql/demo_playground_pkg.pkb`). |
| `P1_INPUT_TOKENS` | Display Only | |
| `P1_OUTPUT_TOKENS` | Display Only | |
| `P1_ESTIMATED_COST` | Display Only | Label exactly "Estimated request cost" — never "cost", per spec section 29 wording. |
| `P1_ESTIMATED_BASELINE_COST` | Display Only | Label exactly "Estimated capable-model baseline". |
| `P1_ESTIMATED_SAVINGS` | Display Only | Label exactly "Estimated saving". Only meaningful for the `AUTO` route (see `database/README.md` / gateway `README.md` — fixed routes have no baseline to compare against, this will read `n/a`). |
| `P1_REQUEST_ID` | Display Only | The gateway's `X-Request-Id` for this call — useful for cross-checking against Page 3 (Request History) or the gateway's own logs. |

All of `P1_SELECTED_TIER` .. `P1_REQUEST_ID` start empty and are only
populated after a request completes (spec: "Display after each request").

## Processes

**On-Demand: Ajax Callback**, name `PLAYGROUND_RUN`, PL/SQL Code:

```sql
apex_ai_router_demo.ajax_run;
```

## Dynamic Action

```text
Event:  Click
Selector: #P1_SEND (or the button's static id)
Action: Execute JavaScript Code
Code:   apexDemoPlayground.run();
```

Add `apex-demo/static/playground.js` as a page-level JavaScript File (Page
Attributes > JavaScript > File URLs), uploaded as a static application file
or referenced directly.

## Manual QA (requires a live gateway + APEX instance — not run in this repository)

- [ ] Sending a prompt with Route=Auto populates `P1_RESULT` and all
      enrichment fields, with `P1_SELECTED_TIER` showing `efficient` or
      `capable` depending on the classifier's decision.
- [ ] Route=Efficient / Route=Capable always show that fixed tier and
      `P1_ESTIMATED_SAVINGS` reads `n/a` (no baseline to compare against
      for a fixed route).
- [ ] Pointing `AIR_CONFIG.GATEWAY_BASE_URL` at an unreachable host surfaces
      a message in `P1_ERROR`, never a raw APEX/browser error.
- [ ] Removing/misnaming `ADMIN_CREDENTIAL_STATIC_ID`'s Web Credential
      still returns the response text in `P1_RESULT` (the first HTTP call
      succeeded), with the enrichment fields reading `n/a` rather than the
      whole request failing — confirms the two-call design degrades
      gracefully (see `apex-demo/sql/demo_playground_pkg.pkb`).
