# benchmark

A synthetic, Oracle/APEX-flavored benchmark harness comparing three
execution modes against a real gateway over real HTTP:

- **A -- Efficient:** fixed `apex-efficient` route
- **B -- Capable:** fixed `apex-capable` route
- **C -- Auto:** `apex-auto` (Switchyard `llm_classifier` routing)

It exists to answer one question honestly: does `apex-auto` actually save
cost relative to always calling the capable model, and at what quality
cost? Spec sections 26-29, 32, 51-52. See root `HANDOFF.md` for open
questions this harness surfaced that a future contributor should look at.

**Golden rule, followed throughout this module:** never fabricate a number.
Every value in a generated report comes from a real HTTP call, a real
`/admin/requests` reconciliation lookup by `X-Request-Id`, or real
deterministic scoring. Where a number is genuinely unavailable, the report
says `n/a` or writes an explicit UNMEASURED template -- never a guess.

## Quick start

```bash
make benchmark-mock
```

This spawns the project's own local mock model server, the real compiled
`switchyard-server` binary (if you've built it -- see
`deploy/switchyard/README.md`; the harness skips Auto mode automatically
if it isn't found), and the gateway itself as local subprocesses on free
loopback ports, using a temporary routing config and a throwaway telemetry
database. No network access or API credentials required. Report goes to
`benchmark/results/latest-mock/{report.md,report.json}`.

Run it directly for more control (smoke-testing a change, limiting to a
few tasks, skipping the judge pass):

```bash
cd gateway
uv run python ../benchmark/runner.py --mode mock --limit 3 --out-dir ../benchmark/results/_smoke
```

## Running against a real gateway

```bash
make benchmark-real GATEWAY_URL=https://your-gateway-host API_KEY=... ADMIN_KEY=...
```

or directly:

```bash
cd gateway
uv run python ../benchmark/runner.py --mode real \
    --gateway-url https://your-gateway-host \
    --api-key <inference-key> --admin-key <admin-key> \
    --judge --out-dir ../benchmark/results/latest-real
```

If the gateway isn't reachable, or `--api-key`/`--admin-key` are missing,
this does **not** invent numbers -- per spec section 28 it writes an
explicit `# ... UNMEASURED` report instead, so the dataset/scorer/runner
infrastructure is still demonstrably exercised even with no live
credentials available.

## CLI reference (`runner.py`)

| Flag | Default | Meaning |
|---|---|---|
| `--mode` | *(required)* | `mock` or `real` |
| `--gateway-url` | `http://127.0.0.1:8080` | only used in `--mode real` |
| `--api-key` / `--admin-key` | `""` | only used in `--mode real` |
| `--judge` | off | also run the LLM-judge pass on `judge_eligible` tasks |
| `--tasks-file` | `benchmark/tasks/tasks.yaml` | |
| `--out-dir` | `benchmark/results` | |
| `--limit N` | none | only run the first N tasks (smoke testing) |
| `--timeout` | `30.0` | per-request HTTP timeout, seconds |

## The task dataset (`tasks/tasks.yaml`)

34 fully synthetic tasks (no customer or proprietary data) across the 14
categories from spec section 26: `simple_summarization`,
`business_email_generation`, `sql_explanation`, `simple_sql_generation`,
`plsql_explanation`, `plsql_generation`, `oracle_error_explanation`,
`json_extraction`, `data_mapping`, `rest_payload_transformation`,
`text_classification`, `apex_validation_logic`,
`multi_step_business_rule_reasoning`, `longer_context_reasoning`. Every
SQL/PL-SQL task references the same small synthetic schema
(`T_CUSTOMERS`, `T_ORDERS`, `T_INVOICES`) so tasks stay self-consistent.
Each task carries a stable `id`, a `difficulty` (easy/medium/hard, spec
section 51), the `prompt` sent verbatim as the single user message, and a
`scoring_method` + `scoring_params` pair keyed into `scoring.py`'s
registry. 17 of the 34 are marked `judge_eligible: true` -- categories
where deterministic keyword-matching is only a coarse proxy for quality
(summarization, email generation, explanations, business-rule reasoning,
longer-context reasoning).

## Deterministic scoring (`scoring.py`)

Every scorer is a heuristic, not a real parser, compiler, or semantic
grader -- each one's docstring says exactly what it can and cannot verify,
and none of them ever raises on a malformed response (a response that
fails to parse is a *failed score*, not a harness crash):

- **`valid_json`** -- valid JSON, with required keys present (object or
  array-of-objects shape). Does not check value correctness.
- **`keyword_presence`** -- substring presence across required keywords.
  A model can include a keyword out of context and pass, or paraphrase
  correctly and fail; pair with the judge for a real quality signal.
- **`classification_exact_match`** -- strict exact-match on a single-word
  label. A correct label buried in a longer sentence is deliberately
  scored as a failure -- verbosity is itself a task-following failure here.
- **`sql_clauses`** -- regex/keyword clause-and-token presence, **not** a
  SQL parser. Cannot verify the query is syntactically valid or would
  actually execute.
- **`plsql_structure`** -- regex-based structural check (`CREATE OR
  REPLACE PROCEDURE`/`PACKAGE`/`PACKAGE BODY` plus required tokens),
  **not** a PL/SQL parser or compiler. Cannot verify the code compiles.
- **`regex_match`** -- every pattern in `patterns` must match somewhere in
  the response.

## The optional LLM-judge pass (`judge.py`)

The judge is a **real gateway request through `apex-capable`** by default
-- not a separate model integration. It goes through the same routing,
auth, and telemetry path as every other benchmark call, so its cost and
tokens are real, measured values and are reported in a separate table
(spec 27: "never hide the judge cost"). It asks the model to grade a
candidate response 0-10 against the task's `expected_characteristics` and
expects a bare JSON reply; a response that doesn't parse becomes a
`parse_error`, not a fabricated fallback score.

## Reconciliation (`runner.py`)

For every call, `runner.py` captures the gateway's own `X-Request-Id`
response header, then makes a single paginated `GET /admin/requests`
lookup (`limit=500`) after the whole run and matches rows back to calls by
that exact field -- the same two-call correlation pattern used by the demo
app's Playground page (`apex-demo/sql/demo_playground_pkg.pkb`). This is
where routing/timing/cost detail (`selected_target`, `selected_model`,
`routing_duration_ms`, `estimated_cost`, etc.) gets attached to each call
record for scoring and reporting.

## An important limitation: telemetry can't see past the Switchyard boundary

For a **fixed** route, `selected_target`/`selected_model` in
`/admin/requests` are exactly what you'd expect (`"efficient"`/
`"capable"`, `"mock-efficient-v1"`/`"mock-capable-v1"`, etc.). For the
**`apex-auto`** (`llm_classifier`) route, in every mode -- mock or real --
both fields are fixed literals, not the backend Switchyard actually
picked:

- `selected_target` is always `"switchyard"` -- the name of the
  gateway-level HTTP target it called (`routing/service.py`:
  `resolve_switchyard_route` always returns a `ResolvedTarget` named after
  the switchyard target itself).
- `selected_model` is always `"apex-auto"` -- `api/openai_chat.py` sets
  `selected_model = resolved.config.model`, and for a switchyard-routed
  call `resolved.config` is the *switchyard* target's own `TargetConfig`,
  whose `model` field is the fixed virtual model name `"apex-auto"` in
  `gateway/config/routing.yaml`.

In other words: **the gateway's own admin API currently has no way to
tell you which concrete backend model `apex-auto` actually selected for a
given request.** That decision is made entirely inside the
`switchyard-server` sidecar and never reported back across the HTTP
boundary. This surfaced empirically while building this harness, not from
reading a spec -- see `HANDOFF.md` for the suggested fix (the gateway
would need to inspect Switchyard's response, e.g. an `X-Switchyard-Target`
response header or the upstream response's own `model` field, and record
it as a distinct telemetry column).

In `--mode mock` only, this harness recovers the *real* choice with a
diagnostic that doesn't generalize to `--mode real`: the mock upstream
(`mocks/mock_model_server.py`) echoes whatever `model` string was actually
in the request it received back into its response content
(`"[mock:TIER:MODEL] response to: ..."`). Parsing that string out of
`response_text` for Auto-mode calls shows which backend Switchyard
actually forwarded to -- reported as the report's **"observed backend,
mock-mode diagnostic"** line, distinct from the gateway-telemetry line
above it. A real model's response text won't echo an internal routing
decision like this, so this diagnostic is mock-only by construction, not
just by current usage.

## Known limitations of a `--mode mock` run

Printed verbatim at the top of every mock-mode report, and worth
repeating here:

1. **Quality scores are not representative of real model quality.** The
   mock upstream returns a fixed, prompt-content-independent string for
   every request, so deterministic scores mostly reflect the mock's canned
   text, not what a real model would produce.
2. **`apex-auto` will show ~100% routing to the capable target.**
   Switchyard's `llm_classifier` routing fails open to the capable target
   on an invalid/unparseable classifier verdict, and the mock's canned
   response is never a valid one -- confirmed empirically (see the
   "observed backend" diagnostic above), not just asserted. This is
   correct behavior of the real routing logic under a mock upstream, not a
   bug, but it means a mock run cannot demonstrate real auto-routing
   distribution or cost savings.
3. **`$0.00` costs are the mock models' genuinely accurate price, not a
   placeholder.** `gateway/config/pricing.yaml` prices
   `mock-efficient-v1`/`mock-capable-v1`/`mock-judge-v1` at `$0.00`
   because the local mock server truly costs nothing to run. A mock run
   validates that cost-tracking and reconciliation wiring works
   end-to-end; it demonstrates nothing about real-world savings.
4. **Judge scores universally fail to parse.** The mock's canned response
   is never valid JSON in the judge's expected shape, so every judge call
   in a mock run ends with a `parse_error`, by design.

None of this is a defect in the harness -- it is why `--mode real` exists,
and why `results/mock-example/` is explicitly labeled as a mock run rather
than presented as a real benchmark result.

## Example report

`results/mock-example/` is a real, committed output of
`--mode mock --judge` against all 34 tasks (no `--limit`) -- not a hand-
written sample. It exists so a reader can see the exact shape of a report,
including every limitation above in context, without having to build and
run the harness first.

## Files

| File | Purpose |
|---|---|
| `runner.py` | CLI entry point; orchestrates subprocesses (mock mode), makes the real HTTP calls, reconciles telemetry |
| `scoring.py` | Deterministic scoring functions |
| `judge.py` | Optional LLM-judge pass |
| `report.py` | Markdown + JSON report generation |
| `tasks/tasks.yaml` | The 34-task dataset |
| `results/` | Committed example output only -- see `.gitignore` for the scratch-run exclusion pattern |
