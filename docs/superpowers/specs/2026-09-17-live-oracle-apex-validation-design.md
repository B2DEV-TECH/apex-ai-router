# Live Oracle and APEX Validation Design

**Date:** 2026-09-17

**Status:** Approved for implementation

## Purpose

Validate APEX AI Router 0.1.0 against the local Oracle Database and APEX
26.1 installation, close any compatibility gaps found during that validation,
and commit the generated plug-in and demo-application exports that are currently
missing from the repository.

The validation must prove the complete request path:

```text
APEX page or PL/SQL
  -> APEX Web Credential
  -> APEX_AI_ROUTER package or plug-in callback
  -> gateway on localhost:<GATEWAY_PORT>
  -> mock efficient/capable provider
  -> gateway telemetry
  -> Oracle/APEX response
```

## Environment Isolation

Create a dedicated test environment in the existing `FREEPDB1` pluggable
database:

- Database schema: `<SCHEMA>`
- APEX workspace: `APEX_AI_ROUTER`
- APEX developer administrator: `<APEX_ADMIN>`
- APEX/ORDS URL: `http://localhost:8080/ords/`
- Gateway host URL: `http://localhost:<GATEWAY_PORT>`
- Gateway API base URL stored in `AIR_CONFIG`:
  `http://localhost:<GATEWAY_PORT>/v1`

The schema and APEX account use newly generated, distinct passwords. Passwords,
API keys, workspace IDs, local container names, and machine-specific connection
details remain outside Git. The existing workspaces and schemas are not changed.

The schema receives only the object-creation privileges needed by the checked-in
SQL: session, table, view, sequence, procedure, and trigger creation, plus quota
on the local test tablespace. Network access is limited to the local gateway
host and port needed by the smoke test.

## Chosen Approach

Use a hybrid workflow:

1. Provision the schema, workspace, and developer with Oracle and APEX APIs.
2. Install and test database objects with SQL*Plus from the checked-in scripts.
3. Run the gateway and mock providers with Docker.
4. Use APEX Builder for Web Credentials, plug-in metadata, page construction,
   browser interaction, and APEX-generated exports.

This keeps repeatable infrastructure and database work scripted while using
Builder for artifacts whose canonical source is an APEX export. Reusing an
existing workspace would weaken isolation. Building everything manually in
Builder would make database provisioning and verification harder to reproduce.

## Port and Gateway Configuration

ORDS already owns host port 8080. The gateway container therefore publishes its
internal port 8080 on host port <GATEWAY_PORT>. This mapping is supplied through a local
Compose override or equivalent invocation that is not committed unless a
general, documented port override is needed by the project.

Local gateway configuration uses the committed mock-provider design:

- Separate inference and admin API keys
- `apex-efficient` routed to the efficient mock
- `apex-capable` routed to the capable mock
- Telemetry stored in the gateway's local test database
- Prompt and response content logging disabled

`apex-auto` is tested only after the pinned Switchyard sidecar is available. A
fixed-route end-to-end call is sufficient to validate the Oracle/APEX network,
credential, package, plug-in, and response path before Switchyard is introduced.

## Database Validation

Run `database/install.sql` as `<SCHEMA>`. Then run
`database/tests/smoke_test.sql` and require all of the following:

- `APEX_AI_ROUTER`, `AIR_MODEL_USAGE_V`, and `AIR_DAILY_USAGE_V` are valid.
- Required `AIR_CONFIG` keys exist.
- An invalid route raises `APEX_AI_ROUTER.E_UNKNOWN_ROUTE` before any HTTP call.
- `USER_ERRORS` has no unresolved errors for project objects.

Update `AIR_CONFIG.GATEWAY_BASE_URL` to the local gateway URL after the gateway
is ready. Create the inference Web Credential with static ID
`AIR_GATEWAY_CREDENTIAL`, then run
`database/tests/manual_gateway_test.sql`. A passing test returns the efficient
mock's response through `APEX_WEB_SERVICE` and writes the expected metadata row
without persisting prompt or response content.

If Oracle 23ai or APEX 26.1 exposes a compile or runtime incompatibility, capture
the exact error, add the smallest meaningful regression check available, and
change the source script rather than patching only the installed database
object.

## Plug-in Validation

Compile `apex-plugin/sql/install_plugin_package.sql`, then create the Dynamic
Action plug-in from `apex-plugin/README.md` using the eight documented attributes
in their specified order. Upload `apex_ai_router_generate.js` as a plug-in file.

The manual checks are:

- A successful callback updates the configured result page item.
- Static text, page item, and JavaScript-expression prompt sources resolve.
- Auto, efficient, and capable route settings map to the documented values.
- The processing indicator follows the attribute setting.
- A controlled gateway failure populates the error item and emits
  `apexairouter:error` without a raw HTML error or uncaught JavaScript exception.
- Success emits `apexairouter:success`.

Export the validated plug-in from Builder into `apex-plugin/dist/`. Import that
export into the same disposable environment after removing or renaming the
Builder copy, so the committed artifact itself receives an import check.

## Demo Application Validation

Compile `apex-demo/sql/install_demo.sql`. Create a separate read-only admin Web
Credential with static ID `AIR_GATEWAY_ADMIN_CREDENTIAL`; it must not reuse the
inference key.

Build the four documented pages without redesigning their contracts or wording:

1. Playground
2. Dashboard
3. Request History
4. Configuration Help

Use the page documents under `apex-demo/pages/` as the component-level source of
truth. Upload `apex-demo/static/playground.js` as an application static file.
Create the documented REST Data Sources against the gateway on port <GATEWAY_PORT>.

Each page's manual checklist must pass. Cost labels remain "Estimated cost",
"Estimated capable-model baseline", and "Estimated savings". The application
must not display or persist API keys, prompt content, or response content outside
the Playground's current browser session.

Export the finished application as `apex-demo/f<app_id>.sql`. Reimport the
export into the disposable workspace under a different application ID and
repeat a minimal navigation and Playground check so the committed export is
known to be installable.

## Error Handling and Diagnostics

Every failure is recorded with its layer and original evidence:

- Oracle compile failures: `USER_ERRORS`
- Oracle network failures: HTTP status, Oracle error code, and ACL/credential
  configuration, excluding secrets
- Gateway failures: sanitized API response and container logs
- APEX Ajax failures: browser console/network result and server debug output,
  excluding credential values
- REST Data Source failures: APEX test result and corresponding gateway request
  ID

Credentials are never copied into issue text, test output committed to Git, or
documentation. Any local `.env` and Compose override remain ignored and are
removed or retained locally at the user's discretion after validation.

## Verification and Documentation

Before claiming completion:

- Run the gateway unit, contract, and integration suites in a Python 3.12
  container because the pre-existing local virtual environment points to a
  removed interpreter.
- Run Ruff and mypy using the locked dependencies.
- Complete gateway smoke-test Part A on host port <GATEWAY_PORT>.
- Complete smoke-test Part B against `<SCHEMA>` and `APEX_AI_ROUTER`.
- Verify the database, plug-in, and application exports install cleanly.
- Review the Git diff for secrets and machine-specific identifiers.

Update `HANDOFF.md`, `README.md`, `RELEASE_NOTES.md`, `CHANGELOG.md`, and
`docs/smoke-test.md` with what was actually run, the observed versions, any
source changes, and any remaining limitations. Statements about cost savings or
model quality remain prohibited without a real-provider benchmark.

## Completion Criteria

The work is complete when:

1. The isolated schema, workspace, and developer account exist and Builder login
   works.
2. Database installation and offline smoke tests pass on Oracle 23ai with APEX
   26.1.
3. A live PL/SQL request reaches the mock gateway and returns successfully.
4. The Dynamic Action plug-in passes its manual checklist and has a tested APEX
   export committed under `apex-plugin/dist/`.
5. All four demo pages pass their checklists and a tested application export is
   committed under `apex-demo/`.
6. Automated gateway checks pass in the reproducible Python 3.12 environment.
7. Documentation accurately distinguishes validated behavior from remaining
   gaps.

## Non-goals

This validation does not add streaming, new provider formats, production
deployment guidance, multi-process telemetry, real-provider quality claims, or
Switchyard backend-selection telemetry. Bugs that block the validated path are
fixed; unrelated roadmap work remains outside this effort.
