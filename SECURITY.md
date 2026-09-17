# Security

## Reporting a vulnerability

Please report suspected security issues privately — open a
[GitHub security advisory](https://github.com/B2DEV-TECH/apex-ai-router/security/advisories/new)
on this repository, or email geefatec@gmail.com. Do not open a public issue
for anything that could be actively exploited.

## Threat model and boundaries

APEX AI Router is a gateway that sits between Oracle APEX and one or more
AI model providers. Its security responsibilities and their current status:

| Concern | Status |
|---|---|
| TLS in production | Expected to be provided by the deployment (reverse proxy / load balancer); the gateway itself does not terminate TLS. |
| Provider credentials never reach the browser | By design — Oracle APEX and any browser code only ever call the gateway, which holds provider credentials server-side. The APEX plug-in's browser code never calls a model provider directly. |
| Secrets in Git or logs | `.env.example` contains only placeholders. Provider credentials are referenced from routing config by environment variable name (`api_key_env: ...`), never inlined. There is no separate log-redaction step — the request-handling path has exactly one structured-logging call site (`api/openai_chat.py`) and it only ever includes route/target/provider/model metadata, never the `Authorization` header or prompt/response content, so there is nothing for a redaction pass to remove. Empirically verified (not just asserted) by `tests/integration/test_hardening.py`, which sends a request with a marked secret API key and prompt and asserts neither ever appears in a formatted log line. |
| Prompt/response retention | Disabled by default. Telemetry stores request metadata only (route, selected target, token counts, latency, estimated cost, retry count) — never prompt or response content — unless an explicit, clearly-labeled dev-only opt-in is enabled. |
| Admin vs. inference credentials | Kept separate. Admin endpoints require a distinct admin API key and never return any API key value. |
| Request size / timeouts / retries | The gateway enforces a request body size limit, an overall request timeout, an explicit provider timeout, and bounded (never indefinite) retries. Retry count is recorded in telemetry on both the success and failure path. |
| Input validation | Request bodies are validated against a typed schema; unsupported parameters produce a validation error rather than being silently dropped or passed through. |
| CORS | Disabled / restrictive by default. |
| Dependency pinning | Direct dependencies are pinned via the gateway's lockfile. |
| Telemetry data integrity under concurrent requests | `telemetry/store.py` uses a single sqlite3 connection per process, which is safe under this project's execution model (single asyncio event loop, no thread-pool offloading of the request handler). Empirically verified, not just asserted, by `tests/integration/test_hardening.py`, which fires 20 truly-concurrent requests via `httpx.ASGITransport` and confirms every one gets exactly one, correctly-matched telemetry row. This is a single-process design; it is not built for multi-process horizontal scaling of the gateway against one SQLite file — see `HANDOFF.md`. |

## What this project does **not** do

- It does not implement data loss prevention, PII detection, or prompt/response
  redaction. A narrow pre-routing/post-response middleware hook exists (or is
  planned) so such a capability could be added later without changing the
  routing core, but no masking is implemented today.
- It does not manage secrets beyond environment variables — it is not a
  replacement for a secrets manager.
- It does not implement authentication/authorization beyond simple API-key
  checks for the inference and admin surfaces; rate limiting is a deployment
  concern unless it can be added simply and reliably.

## NeMo Switchyard

The routing engine dependency, [NVIDIA NeMo Switchyard](https://github.com/NVIDIA-NeMo/Switchyard),
describes itself as experimental and not recommended for production use.
This project uses it anyway, pinned to a specific commit, and documents that
choice honestly rather than hiding it. See `docs/routing.md` for the exact
pinned version once written.
