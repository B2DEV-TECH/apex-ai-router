# APEX AI Router -- Benchmark Report

- **Run mode:** `mock`
- **Generated at:** 2026-09-17T03:11:47.211815+00:00
- **Tasks:** 34 across 14 categories
- **Execution modes run:** Efficient (fixed apex-efficient), Capable (fixed apex-capable), Auto (apex-auto)

## Known limitations of this mock-mode run

This run used the project's own local mock model server, not a real LLM
provider. Read every number in this report with these limitations in mind:

1. **Quality scores are not representative of real model quality.** The
   mock upstream returns a fixed, prompt-content-independent string
   (`"[mock:TIER:MODEL] response to: ..."`) for every single request, so
   deterministic scores mostly reflect the mock's canned text, not what a
   real model would produce for these prompts.
2. **`apex-auto` will show ~100% routing to the capable target, and the
   gateway's own telemetry cannot see this at all.** Switchyard's
   `llm_classifier` routing treats an invalid, inconsistent, or unparseable
   classifier verdict as a fail-open condition and routes to `strong_target`
   (see `docs/routing_algorithms/llm_classifier_routing.md` at the pinned
   Switchyard commit, and `gateway/tests/integration/test_switchyard_auto_routing.py`).
   Because the mock's canned response is never a parseable classifier
   verdict, every `apex-auto` call in mock mode deterministically fails open
   to `capable` -- confirmed empirically in this repo's own smoke runs by
   parsing the mock's echoed response text, not just asserted. This is
   correct behavior of the real routing logic under a mock upstream, not a
   bug -- but it means this run cannot demonstrate real auto-routing
   distribution or cost savings. Only `--mode real` with genuinely
   differentiated efficient/capable models can show that. Separately, and in
   every mode (mock or real): the gateway's own `/admin/requests` telemetry
   records `selected_target` and `selected_model` as the fixed literals
   `"switchyard"`/`"apex-auto"` for any classifier-routed call -- it never
   records which backend Switchyard actually picked, because the gateway
   only resolves to the switchyard HTTP target itself and never inspects
   what happens behind that boundary (`routing/service.py`,
   `api/openai_chat.py`). The "observed backend" line below recovers the
   real choice only in mock mode, only because the mock server happens to
   echo the model string it received back into its response content; there
   is currently no equivalent way to recover this from a real deployment's
   telemetry alone (see `HANDOFF.md`).
3. **$0.00 costs are the mock models' genuinely accurate price, not a
   placeholder.** `gateway/config/pricing.yaml` documents `$0.00` for
   `mock-efficient-v1`/`mock-capable-v1`/`mock-judge-v1` because the local
   mock server truly costs nothing to run. This run reuses that real
   pricing file unmodified. It validates that cost-tracking, reconciliation,
   and reporting wiring works end-to-end -- it demonstrates nothing about
   real-world cost savings. Run `--mode real` against priced models for a
   meaningful savings number.
4. **Judge scores, if requested, will universally fail to parse.** The
   mock's canned response is never valid JSON in the shape the judge prompt
   asks for, so every judge call in mock mode is expected to end with a
   `parse_error`, by design (see `benchmark/judge.py`'s module docstring).
   This is reported explicitly below rather than retried or defaulted to a
   fabricated score.


## Comparison

| Mode | Calls | Success Rate | Deterministic Pass Rate | Avg Score | Avg Cost | Avg Latency |
|---|---|---|---|---|---|---|
| Efficient (fixed apex-efficient) | 34 | 100% | 0% | 0.00 | $0.000000 | 220 ms |
| Capable (fixed apex-capable) | 34 | 100% | 0% | 0.00 | $0.000000 | 218 ms |
| Auto (apex-auto) | 34 | 100% | 0% | 0.00 | n/a | 219 ms |

## Auto vs Capable
- **Estimated cost reduction:** n/a (capable's average cost is $0.000000 in this run -- a $0.00 baseline makes a percentage reduction meaningless; see the mock-mode limitations above)
- **Quality difference (deterministic score, auto - capable):** +0.00
- **Latency difference (auto vs capable):** +0.2%
- **`apex-auto` gateway-telemetry model field (measured, this run):** apex-auto: 34/34 (100%) -- for a classifier-routed call this field is always the fixed virtual model name "apex-auto" itself, not the backend Switchyard actually picked; see the next line for the real backend choice in this mock run.
- **`apex-auto` observed backend, mock-mode diagnostic (parsed from the mock's echoed response content, not from gateway telemetry):** mock-capable-v1: 34/34 (100%)

## By category (deterministic pass rate)

| Category | Efficient (fixed apex-efficient) | Capable (fixed apex-capable) | Auto (apex-auto) |
|---|---|---|---|
| apex_validation_logic | 0/3 | 0/3 | 0/3 |
| business_email_generation | 0/2 | 0/2 | 0/2 |
| data_mapping | 0/2 | 0/2 | 0/2 |
| json_extraction | 0/3 | 0/3 | 0/3 |
| longer_context_reasoning | 0/2 | 0/2 | 0/2 |
| multi_step_business_rule_reasoning | 0/2 | 0/2 | 0/2 |
| oracle_error_explanation | 0/3 | 0/3 | 0/3 |
| plsql_explanation | 0/2 | 0/2 | 0/2 |
| plsql_generation | 0/3 | 0/3 | 0/3 |
| rest_payload_transformation | 0/2 | 0/2 | 0/2 |
| simple_sql_generation | 0/3 | 0/3 | 0/3 |
| simple_summarization | 0/2 | 0/2 | 0/2 |
| sql_explanation | 0/2 | 0/2 | 0/2 |
| text_classification | 0/3 | 0/3 | 0/3 |

## LLM-judge results

Judge calls are real gateway requests through `apex-capable`; their cost and tokens are tracked separately from task calls (spec 27: never hide the judge cost).

| Mode | Judge Calls | Parse Failures | Avg Judge Score (0-10) |
|---|---|---|---|
| Efficient (fixed apex-efficient) | 17 | 17 | n/a |
| Capable (fixed apex-capable) | 17 | 17 | n/a |
| Auto (apex-auto) | 17 | 17 | n/a |

<details><summary>51 judge parse failure(s) -- expand for detail</summary>

- `sum-001` (A_fixed_efficient): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sum-001` (B_fixed_capable): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sum-001` (C_apex_auto): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sum-002` (A_fixed_efficient): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sum-002` (B_fixed_capable): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sum-002` (C_apex_auto): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `email-001` (A_fixed_efficient): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `email-001` (B_fixed_capable): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `email-001` (C_apex_auto): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `email-002` (A_fixed_efficient): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `email-002` (B_fixed_capable): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `email-002` (C_apex_auto): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sqlexp-001` (A_fixed_efficient): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sqlexp-001` (B_fixed_capable): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sqlexp-001` (C_apex_auto): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sqlexp-002` (A_fixed_efficient): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sqlexp-002` (B_fixed_capable): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `sqlexp-002` (C_apex_auto): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `plsqlexp-001` (A_fixed_efficient): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- `plsqlexp-001` (B_fixed_capable): judge response not in the expected JSON shape: Expecting value: line 1 column 2 (char 1) (raw: '[mock:shared:mock-capable-v1] response to: success')
- ... and 31 more

</details>

_Every number above comes from a real HTTP call to a running gateway and, where applicable, a real `/admin/requests` reconciliation lookup by `X-Request-Id` -- see `benchmark/runner.py`. No numbers in this report were invented or interpolated._