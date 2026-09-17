# Page 4 — Configuration Help

Spec section 20: a static-ish reference page for whoever is setting up
this application, showing configuration facts — explicitly **no secret
values**.

> The validated `f1207.sql` export loads these same read-only endpoints
> through allowlisted APEX Ajax Callback processes. The REST Data Source
> mappings below remain a declarative alternative.

## Sections and sources

| Section | Source | Notes |
|---|---|---|
| Gateway endpoint | `AIR_CONFIG.GATEWAY_BASE_URL` (a simple SQL region: `select config_value from air_config where config_key = 'GATEWAY_BASE_URL'`) | Display as-is; it is a URL, not a secret. |
| Expected model IDs | `GET /admin/routes` → `targets.efficient.model` / `targets.capable.model` / `targets.judge.model` | REST Data Source `AIR_ROUTES` (same one from Page 2's routing-distribution join, reusable here), credential `AIR_GATEWAY_ADMIN_CREDENTIAL`. These are the **resolved** model ids from `${EFFICIENT_MODEL_ID}` etc. — not the placeholder text — since `get_routing_config()` substitutes environment variables before `/admin/routes` returns them. `api_key_env` (the environment variable *name* holding each target's key) is also present in the response and is safe to display — it names where the secret lives, it is not the secret. |
| How to configure `APEX_AI` | Static text region linking to `docs/apex-ai-setup.md` (rendered as a note or a link, not duplicated here — single source of truth). | |
| Health status | `GET /health` and `GET /ready` | Neither endpoint requires authentication (confirmed in `gateway/src/apex_ai_router/api/health.py` — no `Depends(require_admin_key)`/`require_api_key` on this router). REST Data Source `AIR_HEALTH` / `AIR_READY` with credential "None". Display `/health`'s `status` and `/ready`'s `status` + `checks.routes_configured`; if `/ready` returns HTTP 503, show its `checks.routing_config_error` text (safe — it's a config parse error message, never a secret) so a misconfigured deployment is diagnosable from this page alone. |

## Explicitly excluded

- No `AIR_CONFIG.CREDENTIAL_STATIC_ID` / `ADMIN_CREDENTIAL_STATIC_ID`
  *values* need hiding (they're credential **names**, not secrets — see
  `database/tables/air_config.sql`'s own column comment), but do not add
  a page item or report that reads the Web Credential's actual stored
  secret — APEX does not expose that through any normal API and this page
  must not attempt to work around that.
- No API keys, no `Authorization` header values, anywhere on this page.

## Manual QA (requires a live gateway + APEX instance — not run in this repository)

- [ ] Page renders the real configured gateway URL and resolved model ids,
      with no placeholder text left over from `CHANGE-ME.example.com`
      defaults (a sign install.sql's placeholders were never edited).
- [ ] Stopping the gateway process and reloading the page shows `/health`
      or `/ready` as failing, with a human-readable reason, not a raw
      connection-error stack trace.
- [ ] No credential value, API key, or `Authorization` header text appears
      anywhere on this page under any condition, including error states.
