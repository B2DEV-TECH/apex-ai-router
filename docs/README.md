# docs

Setup guides and design notes.

- `apex-ai-setup.md` — configuring an Oracle APEX Generative AI Service
  against this gateway (native `APEX_AI` integration) — the
  lowest-friction adoption path, no plug-in or PL/SQL package required.
  Explicitly flags exact APEX Builder field names as unverified against a
  live instance; confirm them against your installed APEX version.
- `smoke-test.md` — a step-by-step manual verification checklist to run
  against a real deployment (or the local Docker mock stack) before
  trusting a release.
- `live-validation-walkthrough.md` — the end-to-end validation that was
  actually run on 2026-09-17: mock providers, the NeMo Switchyard sidecar,
  Oracle Database 23ai Free, APEX 26.1 and the demo application, page by
  page with screenshots (`images/`), plus how to cross-check every routing
  decision outside APEX. Start here to reproduce the demo locally.

Architecture, routing modes, provider configuration, telemetry, and the
security model are covered directly in the root `../README.md` rather than
as separate files here, to avoid two copies drifting apart — see its table
of contents. `plugin-installation.md` duplicate content lives in
`../apex-plugin/README.md`; `benchmark.md` duplicate content lives in
`../benchmark/README.md`. A standalone `deployment.md` and
`troubleshooting.md` do not exist yet; the walkthrough above covers the
local (mock) deployment, and `../HANDOFF.md` lists what a production guide
would still need.
