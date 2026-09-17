# database

Oracle database objects and the `APEX_AI_ROUTER` PL/SQL package (project
prefix `AIR_`) that let PL/SQL and APEX applications call the APEX AI Router
gateway (Phases 1-4, under `gateway/`) without ever handling the gateway's
API key directly.

> **Status:** compiled and exercised on Oracle Database 23ai Free with APEX
> 26.1. `install.sql`, `tests/smoke_test.sql`, and
> `tests/manual_gateway_test.sql` passed against the local mock gateway.
> The live test used disposable credentials and mock model providers; repeat
> it in the target environment before production deployment.

## Objects

| Object | Kind | Purpose |
|---|---|---|
| `AIR_CONFIG` | table | Non-secret key/value config: gateway base URL, HTTP timeout, Web Credential name. Never holds a secret value. |
| `AIR_REQUEST_LOG` | table | APEX application-context log (app id, page id, session id, route, HTTP status, success flag, error, duration). Never duplicates gateway telemetry and never stores prompt/response content. |
| `AIR_MODEL_USAGE_V` | view | Request counts, success rate, and average latency by route, from `AIR_REQUEST_LOG`. |
| `AIR_DAILY_USAGE_V` | view | Request counts by calendar day and route, from `AIR_REQUEST_LOG`. |
| `APEX_AI_ROUTER` | package | `generate()` and `chat()` functions that call the gateway's `POST /v1/chat/completions` and return the assistant's response text. |

`AIR_CONFIG` and `AIR_REQUEST_LOG` are plain tables with no dependency on
APEX being installed; only the package's use of `APEX_WEB_SERVICE` and
`V('APP_ID')`/`V('APP_SESSION')` requires an APEX workspace/session context
(see "Running outside APEX" below).

### Why a separate log from the gateway's own telemetry

The gateway (`gateway/src/apex_ai_router/telemetry/store.py`, Phase 4)
already records routing, provider, token, and cost detail per request in
its own SQLite store. `AIR_REQUEST_LOG` deliberately does **not** repeat any
of that -- it only records what the gateway cannot know: which APEX
application, page, and session made the call. The two logs are correlated
loosely, by timestamp, route, and the gateway's own OpenAI-style response
`id` (stored in `AIR_REQUEST_LOG.gateway_response_id`) -- this is
best-effort operational correlation, not a foreign key, since they are two
separate storage systems. See `AIR_MODEL_USAGE_V` for route-level counts and
the gateway's `/admin/*` endpoints (Phase 4) for cost data.

## Installing

Run as (or grant appropriate object-creation privileges to) the schema that
should own the `AIR_` objects -- typically your APEX workspace's parsing
schema, so the package can be called directly from application pages
without cross-schema grants:

```
sqlplus <user>/<password>@<connect_string> @database/install.sql
```

`install.sql` creates the tables, views, and package, and seeds `AIR_CONFIG`
with placeholder values (`GATEWAY_BASE_URL` = `https://CHANGE-ME.example.com/v1`,
`CREDENTIAL_STATIC_ID` = `AIR_GATEWAY_CREDENTIAL`, `HTTP_TIMEOUT_SECONDS` =
`30`) that **must** be edited before real use. It does not create a database
user, tablespace, or APEX workspace.

After installing:

1. Create a **Web Credential** (APEX Builder > Shared Components > Web
   Credentials) named to match `AIR_CONFIG.CREDENTIAL_STATIC_ID`
   (`AIR_GATEWAY_CREDENTIAL` by default), of type "HTTP Header", holding
   your gateway's inference API key as `Authorization: Bearer <key>`. The
   package only ever references this credential *by name* via
   `APEX_WEB_SERVICE.MAKE_REST_REQUEST(p_credential_static_id => ...)` --
   it never reads, stores, or logs the key itself.
2. Update `AIR_CONFIG.GATEWAY_BASE_URL` to your real gateway's base URL,
   **including** the `/v1` path segment (e.g.
   `https://router.example.com/v1`) -- the package appends only
   `/chat/completions` to it.
3. Run `database/tests/smoke_test.sql` to confirm the objects are valid and
   `AIR_CONFIG` is complete (no network call required).
4. Optionally run `database/tests/manual_gateway_test.sql` to exercise a
   real call end to end, once the gateway is reachable from the database
   host and the Web Credential is in place.

If the `AIR_` objects live in a different schema than your APEX parsing
schema, also run `database/grants/grants_to_apex_schema.sql <apex_schema>`
and create synonyms as it prompts.

To remove everything: `database/grants/revoke_from_apex_schema.sql` (if
applied) then `database/uninstall.sql`.

## Using the package

```sql
declare
    v_answer clob;
begin
    v_answer := apex_ai_router.generate(
        p_prompt     => 'Summarize this support ticket in one sentence.',
        p_route      => apex_ai_router.c_route_efficient,
        p_session_id => v('APP_SESSION')
    );
end;
```

`p_route` accepts `AUTO`, `EFFICIENT`, or `CAPABLE` (case-insensitive; also
exposed as the `c_route_auto` / `c_route_efficient` / `c_route_capable`
package constants), mapped internally to the gateway's `apex-auto` /
`apex-efficient` / `apex-capable` virtual models (Phase 3 Switchyard) --
callers never need to know that naming convention. `chat()` takes a full
OpenAI-style `messages` JSON array (as a CLOB) instead of a single prompt,
for multi-turn or system-prompt use cases.

Both functions return the assistant's response text (the parsed
`choices[0].message.content` field), not the raw gateway JSON body. That is
an implementation decision made in this package, not something the product
spec itself requires -- see `HANDOFF.md` if a raw-JSON variant turns out to
be needed later.

Named, reserved exceptions (`-20050`..`-20052`) let callers handle specific
failure modes:

| Exception | Error | Meaning |
|---|---|---|
| `apex_ai_router.e_unknown_route` | ORA-20050 | `p_route` was not `AUTO`/`EFFICIENT`/`CAPABLE`. Raised before any HTTP call. |
| `apex_ai_router.e_gateway_error` | ORA-20051 | The gateway returned a non-2xx HTTP status. |
| `apex_ai_router.e_missing_config` | ORA-20052 | A required `AIR_CONFIG` key is missing or blank. |

## Running outside APEX

`APEX_WEB_SERVICE` and `V()` are APEX-supplied packages/functions, so the
`APEX_AI_ROUTER` package as written requires an installed APEX instance
(APEX ships `APEX_WEB_SERVICE` as part of the core schema, independent of
having a workspace/application actually built). Calling `generate()`/
`chat()` from a plain SQL*Plus session with no APEX session context still
works for the HTTP call itself; `V('APP_ID')`/`V('APP_SESSION')` simply
return null in that context, which is a valid, non-secret log value.

## Compatibility notes

This was validated against the behavior of `JSON_OBJECT_T`/
`JSON_ARRAY_T` (native since Oracle Database 12.2) and
`APEX_WEB_SERVICE.MAKE_REST_REQUEST` with `p_credential_static_id` (Web
Credentials, available since APEX 20.1) on Oracle Database 23ai Free and
APEX 26.1. Verify the behavior on the target Oracle/APEX version before a
production rollout. See `docs/apex-ai-setup.md` for the native `APEX_AI`
integration path.

## Tests

- `tests/smoke_test.sql` -- no network calls, no gateway required. Checks
  object validity, required `AIR_CONFIG` keys, and that an unknown route
  raises `e_unknown_route` (route mapping happens before any HTTP call, so
  this is verifiable offline). Passed on Oracle Database 23ai Free.
- `tests/manual_gateway_test.sql` -- exercises `generate()` against a real,
  reachable gateway. Requires a configured `AIR_CONFIG` + Web Credential and
  network access from the database host; prints its result for manual
  inspection rather than asserting on it, since the response text depends
  on whichever model is actually configured behind the gateway. Passed
  against the local mock gateway; it remains outside the automated suite.
