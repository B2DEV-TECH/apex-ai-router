# Page 1 — Playground

Spec section 20. Lets a user send one prompt through the gateway and see
the routing/cost detail for that exact request.

> **What the exported app (`f1213.sql`) actually does.** Five regions:
> Hero, Prompt (`P1_PROMPT`, `P1_ROUTE`, two example buttons and Send),
> Response (`P1_RESULT`, `P1_ERROR`), a **Routing decision** card and
> "Plug-in Dynamic Action checks" (three buttons, one per prompt source of
> the `APEX AI Router — Generate` plug-in). Send calls the `PLAYGROUND_RUN`
> Ajax Callback (`apex_ai_router_demo.ajax_run`), which runs the inference
> call and then looks the request up in `/admin/requests` to fill the card:
> requested route → selected target → **upstream model** (the backend
> Switchyard chose for `apex-auto`), the tier that answered, latency,
> tokens, estimated cost / baseline / savings and the request id. The
> per-field item list below was the original design; the card replaced it.

## Prerequisites

- `database/install.sql` run (provides `AIR_CONFIG`, `apex_ai_router`).
- `apex-demo/sql/install_demo.sql` run (provides `apex_ai_router_demo`,
  seeds the `ADMIN_CREDENTIAL_STATIC_ID` config key).
- Two Web Credentials created: `AIR_GATEWAY_CREDENTIAL` (inference key) and
  `AIR_GATEWAY_ADMIN_CREDENTIAL` (admin key) — see
  `apex-demo/sql/install_demo.sql`'s "Next steps".

## Page items and buttons (as exported)

| Item / button | Type | Notes |
|---|---|---|
| `P1_PROMPT` | Textarea | Required. |
| `P1_ROUTE` | Select List | List of Values: `AUTO`/`EFFICIENT`/`CAPABLE` display Auto/Efficient/Capable. Default `AUTO`. |
| `P1_EXAMPLE_SHORT` / `P1_EXAMPLE_LONG` | Buttons | Fill `P1_PROMPT` with a short (under the mock judge's 40-word limit) or a long prompt: `apexDemoPlayground.example('short')` / `('long')`. |
| `P1_SEND` | Button | Label "Send", `apexDemoPlayground.run()` — an Ajax call, not a page submit. |
| `P1_RESULT` | Textarea, read-only | The assistant's response text; with the mock providers, `[mock:<tier>:<model>] response to: …`. |
| `P1_ERROR` | Display Only, Escape special characters | Empty unless the last request failed. |
| `P1_PLUGIN_STATIC` / `P1_PLUGIN_ITEM` / `P1_PLUGIN_JS` | Buttons | Each fires an `APEX AI Router — Generate` Dynamic Action with a different prompt source (Static Text, Item, JavaScript Expression); the region "Plug-in Dynamic Action checks" shows the result or error item of each. |

## Routing decision card (region "Routing decision")

Rendered by `playground.js` from the JSON that `ajax_run` returns. Every
value starts as `n/a` and is filled after each request:

| Card field | JSON field | Where it comes from |
|---|---|---|
| Route → Target → Upstream | requested route, `selected_tier`, `upstream_model` | `selected_tier` is the telemetry's `selected_target` (`switchyard` for Auto, `efficient`/`capable` for fixed routes); `upstream_model` is the model id the backend reported — for Auto, the backend Switchyard chose. |
| Tier that answered | `answered_tier` | `upstream_model` resolved against `/admin/routes` targets (`tier_model()`), so the page never hard-codes a model id; `null` → `n/a`. |
| Latency | `latency_ms` | Wall-clock time of the Playground's own `POST /v1/chat/completions`, measured in PL/SQL — not the gateway's `total_duration_ms` (both legitimate, see `apex-demo/sql/demo_playground_pkg.pkb`). |
| Tokens | `input_tokens`, `output_tokens` | From the request's `/admin/requests` row. |
| Estimated cost / capable-model baseline / savings | `estimated_cost`, `estimated_baseline_cost`, `estimated_savings` | Labels per spec section 29 wording ("Estimated …", never "cost"/"saved"). Savings only exist for `AUTO`; fixed routes have no baseline and read `n/a`. |
| Request id | `request_id` | The gateway's `X-Request-Id` — the key for cross-checking Page 3 (Request History), `/admin/requests` and the sidecar routing log. |

If the admin lookup fails (credential missing, telemetry lag) the response
text is still returned and the card fields stay `n/a`, never zero.

## Processes

**On-Demand: Ajax Callback**, name `PLAYGROUND_RUN`, PL/SQL Code:

```sql
apex_ai_router_demo.ajax_run;
```

## Client script

The exported page wires the buttons through their `onclick` attributes
(`apexDemoPlayground.run()`, `apexDemoPlayground.example('short'|'long')`)
rather than a separate Dynamic Action; `apex-demo/static/playground.js` is
carried inside the export as an application static file and loaded from
the page's JavaScript File URLs. The three plug-in buttons are ordinary
Click Dynamic Actions using the `APEX AI Router — Generate` plug-in with
`P1_PROMPT` as the Item source where applicable.

## QA (run 2026-09-17 against the exported app, live gateway, mock providers and the Switchyard sidecar — `apex-demo/qa/browser_qa.mjs`)

- [x] Route=Auto with the short example prompt: `P1_RESULT` reads
      `[mock:efficient:mock-efficient-v1] …`, the card shows target
      `switchyard`, upstream `mock-efficient-v1`, tier `efficient`; the
      sidecar routing log carries the judge call and the efficient backend
      call for the same request.
- [x] Route=Auto with the long example prompt: same flow ending in
      `mock-capable-v1` / `capable`.
- [x] Route=Efficient: target `efficient`, no sidecar entry (the classifier
      is bypassed). The card's `n/a` savings for fixed routes is by design
      but was **not asserted** by the script.
- [x] The three plug-in buttons (Static Text, Item, JavaScript Expression)
      each produced a response in their result item — 3/3, no console
      errors.
- [ ] Pointing `AIR_CONFIG.GATEWAY_BASE_URL` at an unreachable host
      surfacing a message in `P1_ERROR`: **not exercised** in the automated
      run. The controlled-error path was exercised earlier the same day by
      stopping the sidecar and sending an Auto request through the plug-in
      buttons (error item populated, no raw APEX error).
- [ ] Removing/misnaming `ADMIN_CREDENTIAL_STATIC_ID`'s Web Credential
      (response text still returned, card fields `n/a`): **not exercised**;
      the behaviour is in `run_playground()`'s enrichment step but was not
      triggered during the validation.
