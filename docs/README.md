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

Architecture, routing modes, provider configuration, telemetry, and the
security model are covered directly in the root `../README.md` rather than
as separate files here, to avoid two copies drifting apart — see its table
of contents. `plugin-installation.md` duplicate content lives in
`../apex-plugin/README.md`; `benchmark.md` duplicate content lives in
`../benchmark/README.md`. A standalone `deployment.md` and
`troubleshooting.md` do not exist yet — see `../HANDOFF.md`.
