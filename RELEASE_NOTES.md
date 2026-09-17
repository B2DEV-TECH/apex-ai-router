# APEX AI Router 0.1.0

First pre-release. Smart model routing for Oracle APEX: an OpenAI-compatible
gateway that lets APEX applications route AI requests between an "efficient"
and a "capable" model, automatically or on demand, without hard-coding any
particular vendor.

## What's in this release

- **Gateway** (`gateway/`): OpenAI-compatible `GET /v1/models` and
  `POST /v1/chat/completions`, backed by a real `httpx` provider adapter
  with bounded retries, timeouts, and OpenAI-shaped error mapping.
- **`apex-auto` routing**: requests are forwarded to a
  [NVIDIA NeMo Switchyard](https://github.com/NVIDIA-NeMo/Switchyard)
  sidecar (pinned commit, see `deploy/switchyard/README.md`), which
  classifies each request and picks the efficient or capable target.
  `apex-efficient`/`apex-capable` give fixed baselines to compare against.
- **Telemetry and cost estimation**: every request's route, target,
  provider, model, token counts, latency, retry count, and estimated cost
  are recorded to a local SQLite store and exposed via admin-key-gated
  `/admin/metrics/*` and `/admin/requests` endpoints. Prompt/response
  content is never stored unless an explicit dev-only opt-in is set.
- **Sanitized errors everywhere**: every documented failure mode —
  validation, provider, routing/pricing config, upstream timeouts —
  returns `{"error": {"code", "message", "request_id"}}`, never a raw
  stack trace. This release closes two gaps found via live smoke testing,
  not code review: `RoutingConfigError` escaping three endpoints uncaught,
  and a bare `pydantic.ValidationError` escaping the same config loader
  via a set-but-empty env var — see `CHANGELOG.md` for both writeups.
- **Oracle/PL-SQL integration** (`database/`): `AIR_CONFIG`/`AIR_REQUEST_LOG`
  tables, usage views, and an `APEX_AI_ROUTER` PL/SQL package
  (`generate()`/`chat()`) for calling the gateway from page processes.
- **APEX plug-in** (`apex-plugin/`): an "APEX AI Router - Generate" Dynamic
  Action for low-code usage, including an APEX 26.1 Builder export that was
  reimported into a clean application.
- **Demo application** (`apex-demo/`): an exported 4-page reference app
  (Playground, Dashboard, Request History, Configuration Help), validated
  in a browser and reimported under a different application ID.
- **Benchmark harness** (`benchmark/`): 34 synthetic, Oracle/APEX-flavored
  tasks across 14 categories, comparing fixed-efficient, fixed-capable, and
  `apex-auto` on cost, latency, and deterministic (plus optional
  LLM-judge) scoring. `benchmark/results/mock-example/` is a committed
  example run against the local mock upstream.
- 98 automated tests passing and one optional integration test skipped,
  `ruff` and `mypy` clean,
  a GitHub Actions CI pipeline (lint, type check, unit + integration tests,
  informational `pip-audit`).

## Live validation and remaining limits

The Oracle and APEX surfaces were validated on Oracle Database 23ai Free
and APEX 26.1. The database smoke test and manual PL/SQL gateway round trip
passed. The plug-in export and the demo application export
(`apex-demo/f1213.sql`, post-0.1.0) were each reimported; the demo's
Playground, Dynamic Action modes, Dashboard, Request History, and
Configuration Help pages passed a browser flow without console errors.
The full record, with screenshots, is `docs/live-validation-walkthrough.md`.

- The live validation used local mock model providers. Fixed Efficient and
  Capable routes succeeded. Auto routing ran through a live NeMo Switchyard
  sidecar (post-0.1.0): short prompts reached the efficient backend and
  long prompts the capable backend, and the backend that answered is
  recorded in the gateway's `upstream_model` telemetry.
- No benchmark has been run against a real model provider. Every cost or
  quality number in this repository comes from the mock-mode example run
  and is explicitly labeled as such — there is no cost-reduction or
  quality-preservation claim for real providers in this release.

NeMo Switchyard itself is, by NVIDIA's own description, experimental and
not recommended for production use; this project depends on it anyway,
pinned to a specific commit, and says so plainly (`SECURITY.md`).

See [`README.md`](README.md#limitations) for the full limitations list and
[`HANDOFF.md`](HANDOFF.md) for a prioritized list of what a follow-up
contributor should look at first.

## Upgrading from nothing

There is no prior release. See [`README.md`](README.md#quick-start) to get
started.

## Release assets

Built by `scripts/build_release_artifacts.py`:
`apex-ai-router-database.zip`, `docker-compose.yml`, `example.env`,
`benchmark-report.md` (the mock-mode example run). The repository also
contains the verified plug-in export under `apex-plugin/dist/` and the demo
application export at `apex-demo/f1213.sql`.
