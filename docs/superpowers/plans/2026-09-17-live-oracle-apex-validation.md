# Live Oracle and APEX Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate APEX AI Router end to end on the local Oracle 23ai/APEX 26.1 environment and commit tested APEX plug-in and demo-application exports.

**Architecture:** Provision an isolated `AIR_DEV` schema and `APEX_AI_ROUTER` workspace in `FREEPDB1`, run the existing gateway against local mock providers on host port 8081, then exercise database, plug-in, and four-page demo flows through APEX. Keep credentials and machine-specific overrides in ignored `.tools`/`.env` files; commit only source fixes, APEX-generated exports, and evidence-backed documentation.

**Tech Stack:** Oracle Database 23ai Free, Oracle APEX 26.1, ORDS, SQL*Plus, FastAPI/Python 3.12, Docker Compose, APEX Builder, JavaScript, PL/SQL.

**Spec:** `docs/superpowers/specs/2026-09-17-live-oracle-apex-validation-design.md`

## Global Constraints

- Database schema: `AIR_DEV`; APEX workspace: `APEX_AI_ROUTER`; APEX developer: `AIR_ADMIN`.
- ORDS remains on `http://localhost:8080/ords/`; the gateway uses `http://localhost:8081`.
- The gateway API base stored in `AIR_CONFIG` is `http://localhost:8081/v1`.
- Schema, APEX, SYS, inference, and admin credentials must never enter Git or committed logs.
- Prompt and response content telemetry remains disabled.
- Cost wording must use “Estimated cost,” “Estimated capable-model baseline,” and “Estimated savings.”
- No real-provider cost, quality, or savings claim is permitted without a real benchmark.
- Any source defect found during validation gets a failing regression test before its fix.

---

### Task 1: Establish a reproducible baseline and local gateway configuration

**Files:**
- Create, ignored: `.env`
- Create, ignored: `.tools/docker-compose.override.yml`
- Verify: `gateway/tests/`

**Interfaces:**
- Consumes: Docker Desktop 29.4.0 and the checked-in `gateway/uv.lock`.
- Produces: a passing Python 3.12 baseline and a mock gateway reachable at `http://localhost:8081`.

- [ ] **Step 1: Create the ignored Compose port override**

Create `.tools/docker-compose.override.yml` with:

```yaml
services:
  gateway:
    ports: !override
      - "8081:8080"
```

- [ ] **Step 2: Create the ignored local environment**

Create `.env` with the non-production values below:

```dotenv
APEX_AI_ROUTER_ENVIRONMENT=development
APEX_AI_ROUTER_LOG_LEVEL=info
APEX_AI_ROUTER_HOST=0.0.0.0
APEX_AI_ROUTER_PORT=8080
APEX_AI_ROUTER_API_KEYS=air-local-inference-20260917
APEX_AI_ROUTER_ADMIN_API_KEY=air-local-admin-20260917
APEX_AI_ROUTER_ROUTING_CONFIG=config/routing.yaml
APEX_AI_ROUTER_MAX_REQUEST_BODY_BYTES=1000000
APEX_AI_ROUTER_PRICING_CONFIG=config/pricing.yaml
APEX_AI_ROUTER_TELEMETRY_DB_PATH=data/telemetry.db
APEX_AI_ROUTER_TELEMETRY_LOG_CONTENT=false
EFFICIENT_MODEL_ID=mock-efficient-v1
CAPABLE_MODEL_ID=mock-capable-v1
JUDGE_MODEL_ID=mock-judge-v1
EFFICIENT_MODEL_API_KEY=
EFFICIENT_MODEL_BASE_URL=http://mock-efficient-model:9001
CAPABLE_MODEL_API_KEY=
CAPABLE_MODEL_BASE_URL=http://mock-capable-model:9002
JUDGE_MODEL_API_KEY=
JUDGE_MODEL_BASE_URL=http://mock-capable-model:9002
SWITCHYARD_BASE_URL=http://host.docker.internal:4000
MOCK_EFFICIENT_PORT=9001
MOCK_CAPABLE_PORT=9002
```

- [ ] **Step 3: Run the complete baseline in Python 3.12**

From the worktree root, run:

```powershell
docker run --rm `
  -v "${PWD}:/workspace" `
  -w /workspace/gateway `
  python:3.12-slim `
  sh -lc "pip install --no-cache-dir uv && uv sync --frozen --all-extras && uv run pytest && uv run ruff check . && uv run mypy src"
```

Expected: all existing tests pass (the repository currently documents 99), Ruff reports no errors, and mypy reports success. If dependency download is blocked, rerun with approved network access rather than changing the lock file.

- [ ] **Step 4: Verify no local secrets are tracked**

Run:

```powershell
git status --short --ignored .env .tools
git check-ignore .env .tools/docker-compose.override.yml
```

Expected: both files are ignored and neither is staged. This task changes no tracked files and requires no commit.

---

### Task 2: Provision the isolated Oracle schema and APEX workspace

**Files:**
- Create, ignored: `.tools/provision_apex.sql`
- Verify: Oracle dictionary views and APEX workspace views

**Interfaces:**
- Consumes: SYS access to `localhost:1521/FREEPDB1`, APEX 26.1 APIs.
- Produces: schema `AIR_DEV`, workspace `APEX_AI_ROUTER`, administrator `AIR_ADMIN`.

- [ ] **Step 1: Create a secret-prompting provisioning script**

Create `.tools/provision_apex.sql`:

```sql
whenever sqlerror exit sql.sqlcode rollback
set define on verify off serveroutput on
accept air_schema_password char prompt 'New AIR_DEV database password: ' hide
accept air_admin_password char prompt 'New AIR_ADMIN APEX password: ' hide

declare
    l_count number;
begin
    select count(*) into l_count from dba_users where username = 'AIR_DEV';
    if l_count = 0 then
        execute immediate
            'create user AIR_DEV identified by "' ||
            replace('&air_schema_password', '"', '""') ||
            '" default tablespace USERS temporary tablespace TEMP quota unlimited on USERS';
    end if;
end;
/

grant create session, create table, create view, create sequence,
      create procedure, create trigger to AIR_DEV;

declare
    l_count number;
begin
    select count(*) into l_count
      from apex_workspaces
     where workspace = 'APEX_AI_ROUTER';
    if l_count = 0 then
        apex_instance_admin.add_workspace(
            p_workspace      => 'APEX_AI_ROUTER',
            p_primary_schema => 'AIR_DEV'
        );
    end if;
end;
/

declare
    l_workspace_id number;
    l_count        number;
begin
    l_workspace_id := apex_util.find_security_group_id(
        p_workspace => 'APEX_AI_ROUTER'
    );
    apex_util.set_security_group_id(l_workspace_id);

    select count(*) into l_count
      from apex_workspace_apex_users
     where workspace_name = 'APEX_AI_ROUTER'
       and user_name = 'AIR_ADMIN';

    if l_count = 0 then
        apex_util.create_user(
            p_user_name                    => 'AIR_ADMIN',
            p_email_address                => 'air-admin@localhost.invalid',
            p_web_password                 => '&air_admin_password',
            p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
            p_default_schema               => 'AIR_DEV',
            p_allow_app_building_yn        => 'Y',
            p_allow_sql_workshop_yn        => 'Y',
            p_change_password_on_first_use => 'N'
        );
    end if;
    commit;
end;
/

prompt Provisioning complete.
```

- [ ] **Step 2: Run provisioning as SYS**

Use the temporary client configuration with
`SQLNET.AUTHENTICATION_SERVICES=(NONE)` and run the script against
`localhost:1521/FREEPDB1` as SYSDBA. Enter newly generated, distinct passwords at the hidden prompts. Do not pass either new password as a SQL*Plus substitution argument.

- [ ] **Step 3: Verify the schema/workspace association and object privileges**

Run as SYS:

```sql
select username, account_status, default_tablespace
  from dba_users
 where username = 'AIR_DEV';

select workspace_name, schema
  from apex_workspace_schemas
 where workspace_name = 'APEX_AI_ROUTER';

select workspace_name, user_name, is_admin, is_application_developer
  from apex_workspace_apex_users
 where workspace_name = 'APEX_AI_ROUTER'
   and user_name = 'AIR_ADMIN';
```

Expected: `AIR_DEV` is open, `APEX_AI_ROUTER` maps only to `AIR_DEV`, and `AIR_ADMIN` is both administrator and application developer.

- [ ] **Step 4: Verify Builder login**

Open `http://localhost:8080/ords/`, sign in with workspace `APEX_AI_ROUTER` and user `AIR_ADMIN`, and confirm that App Builder and SQL Workshop are visible. This task changes only the disposable database/APEX instance and ignored files, so it requires no Git commit.

---

### Task 3: Install and smoke-test the Oracle objects

**Files:**
- Execute: `database/install.sql`
- Execute: `database/tests/smoke_test.sql`
- Modify only if a live defect is found: files under `database/`
- Test only if a live defect is found: `database/tests/`

**Interfaces:**
- Consumes: `AIR_DEV` schema and APEX packages supplied by APEX 26.1.
- Produces: valid `AIR_*` tables/views and `APEX_AI_ROUTER` package objects.

- [ ] **Step 1: Install from the checked-in script**

Start SQL*Plus as `AIR_DEV` connected to `FREEPDB1`, change the working directory to `database`, and run:

```sql
@install.sql
```

Expected: every statement succeeds and both package spec and body show no errors.

- [ ] **Step 2: Run the offline smoke test**

From `database/tests`, run:

```sql
@smoke_test.sql
```

Expected output includes:

```text
OK: all expected objects are VALID.
OK: required AIR_CONFIG keys are present.
OK: unknown route correctly raised e_unknown_route.
== Smoke test complete ==
```

- [ ] **Step 3: Audit compilation and seeded configuration**

Run:

```sql
select name, type, line, position, text
  from user_errors
 order by name, type, sequence;

select config_key, config_value
  from air_config
 order by config_key;
```

Expected: `USER_ERRORS` is empty and only the documented placeholder URL remains to be replaced in Task 5.

- [ ] **Step 4: Handle any compatibility failure with a regression first**

If a source change is required, add the smallest SQL regression reproducing the exact Oracle/APEX 26.1 failure, run it to observe the failure, patch the checked-in source, rerun it to pass, then rerun `install.sql` and `smoke_test.sql`. Commit only that focused fix and test; do not commit installed-object output or credentials.

---

### Task 4: Start and verify the mock gateway on port 8081

**Files:**
- Consume, ignored: `.env`
- Consume, ignored: `.tools/docker-compose.override.yml`
- Verify: `docs/smoke-test.md` Part A

**Interfaces:**
- Consumes: mock efficient/capable servers and the local gateway image.
- Produces: authenticated OpenAI-compatible and admin endpoints for Oracle/APEX.

- [ ] **Step 1: Build and start the stack**

Run:

```powershell
docker compose `
  -f docker-compose.yml `
  -f .tools/docker-compose.override.yml `
  up --build -d
```

Expected: gateway, efficient mock, and capable mock containers are healthy/running; ORDS continues responding on port 8080.

- [ ] **Step 2: Verify health, readiness, and authentication**

Run:

```powershell
Invoke-RestMethod http://localhost:8081/health
Invoke-RestMethod http://localhost:8081/ready
Invoke-RestMethod http://localhost:8081/v1/models `
  -Headers @{ Authorization = 'Bearer air-local-inference-20260917' }
```

Expected: health and readiness are positive and the model list contains `apex-auto`, `apex-efficient`, and `apex-capable`. Requests with no key and with `Bearer wrong-key` must both return HTTP 401.

- [ ] **Step 3: Verify both fixed routes**

POST the body below once with `model` set to `apex-efficient` and once with `apex-capable`:

```json
{
  "model": "apex-efficient",
  "messages": [{"role": "user", "content": "hello from live APEX validation"}]
}
```

Expected: the response contains `[mock:efficient:mock-efficient-v1]` for the first request and `[mock:capable:mock-capable-v1]` for the second.

- [ ] **Step 4: Verify telemetry isolation**

Call `/admin/metrics/summary` and `/admin/requests` with `Bearer air-local-admin-20260917`. Confirm an inference key receives 401 on `/admin/*`, request metadata is present, and no prompt or response content appears. Preserve request IDs in local notes only. No Git commit is required.

---

### Task 5: Configure Oracle network access and APEX Web Credentials

**Files:**
- Create, ignored: `.tools/configure_apex_gateway.sql`
- Execute: `database/tests/manual_gateway_test.sql`

**Interfaces:**
- Consumes: gateway on `localhost:8081`, workspace `APEX_AI_ROUTER`.
- Produces: inference credential `AIR_GATEWAY_CREDENTIAL`, admin credential `AIR_GATEWAY_ADMIN_CREDENTIAL`, and a successful live PL/SQL call.

- [ ] **Step 1: Grant the local outbound-network ACE**

Run as SYS:

```sql
begin
    dbms_network_acl_admin.append_host_ace(
        host       => 'localhost',
        lower_port => 8081,
        upper_port => 8081,
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect'),
            principal_name => 'AIR_DEV',
            principal_type => xs_acl.ptype_db
        )
    );
    dbms_network_acl_admin.append_host_ace(
        host => 'localhost',
        ace  => xs$ace_type(
            privilege_list => xs$name_list('resolve'),
            principal_name => 'AIR_DEV',
            principal_type => xs_acl.ptype_db
        )
    );
end;
/
```

- [ ] **Step 2: Create Web Credentials through the public APEX API**

Create `.tools/configure_apex_gateway.sql`:

```sql
whenever sqlerror exit sql.sqlcode rollback
set define on verify off serveroutput on
accept inference_key char prompt 'Inference API key: ' hide
accept admin_key char prompt 'Admin API key: ' hide

declare
    l_workspace_id number;
begin
    l_workspace_id := apex_util.find_security_group_id(
        p_workspace => 'APEX_AI_ROUTER'
    );
    apex_util.set_security_group_id(l_workspace_id);

    apex_credential.create_credential(
        p_credential_name      => 'APEX AI Router Inference',
        p_credential_static_id => 'AIR_GATEWAY_CREDENTIAL',
        p_authentication_type  => 'HTTP_HEADER'
    );
    apex_credential.set_persistent_credentials(
        p_credential_static_id => 'AIR_GATEWAY_CREDENTIAL',
        p_key                  => 'Authorization',
        p_value                => 'Bearer ' || '&inference_key'
    );

    apex_credential.create_credential(
        p_credential_name      => 'APEX AI Router Admin',
        p_credential_static_id => 'AIR_GATEWAY_ADMIN_CREDENTIAL',
        p_authentication_type  => 'HTTP_HEADER'
    );
    apex_credential.set_persistent_credentials(
        p_credential_static_id => 'AIR_GATEWAY_ADMIN_CREDENTIAL',
        p_key                  => 'Authorization',
        p_value                => 'Bearer ' || '&admin_key'
    );
    commit;
end;
/
```

Run it as `AIR_DEV`, supplying the two values from Task 1 at the hidden prompts.

- [ ] **Step 3: Point `AIR_CONFIG` to the local gateway**

Run as `AIR_DEV`:

```sql
update air_config
   set config_value = 'http://localhost:8081/v1'
 where config_key = 'GATEWAY_BASE_URL';
commit;
```

- [ ] **Step 4: Run the live gateway test**

From `database/tests`, run:

```sql
@manual_gateway_test.sql
```

Expected: the response text identifies the efficient mock, the gateway telemetry contains the matching request, and `AIR_REQUEST_LOG` contains metadata without prompt/response content.

- [ ] **Step 5: Verify credential boundaries**

Confirm the inference credential cannot read `/admin/requests`, the admin credential is never sent to `/v1/chat/completions`, and neither secret can be selected from normal APEX views. No Git commit is required.

---

### Task 6: Build, validate, and export the Dynamic Action plug-in

**Files:**
- Execute: `apex-plugin/sql/install_plugin_package.sql`
- Upload: `apex-plugin/static/apex_ai_router_generate.js`
- Create: `apex-plugin/dist/dynamic_action_plugin_air_dynamic_action_generate.sql`
- Modify only if a defect is found: `apex-plugin/src/*`, `apex-plugin/static/*`

**Interfaces:**
- Consumes: `APEX_AI_ROUTER` package and `AIR_GATEWAY_CREDENTIAL`.
- Produces: installable Dynamic Action plug-in export and browser-tested callback behavior.

- [ ] **Step 1: Compile the plug-in package**

Run as `AIR_DEV`:

```sql
@apex-plugin/sql/install_plugin_package.sql
select name, type, line, position, text
  from user_errors
 where name = 'APEX_AI_ROUTER_DA'
 order by type, sequence;
```

Expected: package spec/body are valid and the error query returns no rows.

- [ ] **Step 2: Create the demo application shell in Builder**

In workspace `APEX_AI_ROUTER`, create application ID `1200` named
`APEX AI Router Demo` using Universal Theme. Keep authentication as APEX
Accounts and create an initially empty home page; the four documented pages
replace or extend this shell in Task 7.

- [ ] **Step 3: Create the plug-in metadata exactly**

Under Shared Components → Plug-ins, create a Dynamic Action plug-in named `APEX AI Router - Generate`, internal name `AIR.DYNAMIC_ACTION.GENERATE`, render function `apex_ai_router_da.render`, and Ajax function `apex_ai_router_da.ajax`. Upload `apex_ai_router_generate.js` as a plug-in file.

Create these attributes in order:

1. Prompt Source Type: select list `STATIC`, `ITEM`, `JS_EXPRESSION`; required.
2. Prompt Source Value: text; required.
3. Route: select list `AUTO`, `EFFICIENT`, `CAPABLE`; required; default `AUTO`.
4. Result Page Item: page item; optional.
5. Temperature: number; optional.
6. Session ID Page Item: page item; optional.
7. Show Processing Indicator: checkbox Y/N; optional; default `Y`.
8. Error Page Item: page item; optional.

- [ ] **Step 4: Build a plug-in QA region**

On the Playground page, add prompt/result/error items and a Send button wired to the plug-in. Exercise static, item, and JavaScript-expression prompt sources; all three routes; spinner on/off; success/error events; and an unreachable-gateway error. Restore `AIR_CONFIG.GATEWAY_BASE_URL` immediately after the negative test.

- [ ] **Step 5: Fix discovered defects test-first**

For JavaScript defects, add a focused Node test around the failing resolver/callback behavior before changing `apex_ai_router_generate.js`. For PL/SQL defects, add a reproducible SQL test or extend the manual QA script before changing the package. Rerun the focused test and the full applicable checklist.

- [ ] **Step 6: Export and reimport the plug-in**

Export the plug-in from Builder and save or rename the generated SQL as
`apex-plugin/dist/dynamic_action_plugin_air_dynamic_action_generate.sql`.
Remove or rename the current plug-in in the disposable app, import that exported
file, and repeat one successful callback plus one controlled-error callback.

- [ ] **Step 7: Commit the validated plug-in artifact**

Run:

```powershell
git add apex-plugin/dist apex-plugin/src apex-plugin/static
git diff --cached --check
git commit -m "feat: add validated APEX dynamic action plugin export"
```

Only include source files if live validation required a fix.

---

### Task 7: Build and validate the four-page demo application

**Files:**
- Execute: `apex-demo/sql/install_demo.sql`
- Upload: `apex-demo/static/playground.js`
- Consume: `apex-demo/pages/01-playground.md` through `04-configuration-help.md`
- Create: `apex-demo/f1200.sql`
- Modify only if a defect is found: `apex-demo/sql/*`, `apex-demo/static/*`, page docs

**Interfaces:**
- Consumes: inference/admin Web Credentials, gateway OpenAI/admin APIs, plug-in.
- Produces: four working pages and an import-tested APEX application export.

- [ ] **Step 1: Install and validate the demo support package**

Run as `AIR_DEV`:

```sql
@apex-demo/sql/install_demo.sql
select name, type, line, position, text
  from user_errors
 where name = 'APEX_AI_ROUTER_DEMO'
 order by type, sequence;
```

Expected: package spec/body are valid and `ADMIN_CREDENTIAL_STATIC_ID` equals `AIR_GATEWAY_ADMIN_CREDENTIAL`.

- [ ] **Step 2: Build Page 1 — Playground**

Create `P1_PROMPT`, `P1_ROUTE`, `P1_SEND`, `P1_RESULT`, `P1_ERROR`,
`P1_SELECTED_TIER`, `P1_SELECTED_MODEL`, `P1_LATENCY_MS`,
`P1_INPUT_TOKENS`, `P1_OUTPUT_TOKENS`, `P1_ESTIMATED_COST`,
`P1_ESTIMATED_BASELINE_COST`, `P1_ESTIMATED_SAVINGS`, and
`P1_REQUEST_ID` with the types and labels in `apex-demo/pages/01-playground.md`.
Create Ajax callback `PLAYGROUND_RUN` calling `apex_ai_router_demo.ajax_run`, upload
`playground.js`, and wire the Send click to `apexDemoPlayground.run()`.

Verify auto/fixed route behavior, enrichment values, controlled gateway failure,
and graceful loss of admin enrichment exactly as specified by the page checklist.

- [ ] **Step 3: Create the shared REST Data Sources**

Create:

- `AIR_METRICS_SUMMARY` → `/admin/metrics/summary`
- `AIR_METRICS_MODELS` → `/admin/metrics/models`, root `models[]`
- `AIR_METRICS_DAILY` → `/admin/metrics/daily`, root `daily[]`
- `AIR_ROUTES` → `/admin/routes`
- `AIR_REQUESTS` → `/admin/requests`, root `requests[]`
- `AIR_HEALTH` → `/health`, no credential
- `AIR_READY` → `/ready`, no credential

Use base URL `http://localhost:8081`, admin credential
`AIR_GATEWAY_ADMIN_CREDENTIAL` where required, and the exact response fields in
the page documents. Test each operation in Shared Components before using it.

- [ ] **Step 4: Build Page 2 — Dashboard**

Add cards for requests, success rate, estimated cost, estimated baseline, and
estimated savings. Add model request/cost bar charts and daily request/estimated
savings line charts. Omit the all-time latency card because the API does not
provide the metric; do not fabricate or relabel the documented approximation.

Verify empty telemetry renders `n/a`, populated telemetry renders real values,
and refreshes pick up additional Playground requests.

- [ ] **Step 5: Build Page 3 — Request History**

Create an Interactive Report over `AIR_REQUESTS` with timestamp, route, selected
target, selected model, total latency, input/output tokens, estimated cost,
estimated savings, success, HTTP status, and error code. Render status as a green
OK badge or red failure badge. Confirm prompt/response content is absent from the
report, filters, downloads, and source metadata.

- [ ] **Step 6: Build Page 4 — Configuration Help**

Display `AIR_CONFIG.GATEWAY_BASE_URL`, resolved target model IDs from
`AIR_ROUTES`, a link to `docs/apex-ai-setup.md`, and health/readiness values from
`AIR_HEALTH`/`AIR_READY`. Stop the gateway once, verify a readable failure state,
restart it, and confirm the page recovers. Inspect the page and browser network
responses to ensure no API key or Authorization value appears.

- [ ] **Step 7: Run all page checklists and repair source-first**

Complete every checkbox in all four page documents. If a package or JavaScript
source changes, reproduce the failure outside Builder when possible, update the
checked-in source, reinstall/upload it, and rerun the affected checklist plus one
neighboring success path.

- [ ] **Step 8: Export, reimport, and commit the application**

Export application `1200` with supporting objects as `apex-demo/f1200.sql`.
Import it into the same workspace as application `1201`, then verify
login, navigation across all four pages, one Playground request, Dashboard data,
Request History, and Configuration Help.

Run:

```powershell
git add apex-demo
git diff --cached --check
git commit -m "feat: add validated APEX demo application export"
```

---

### Task 8: Complete verification and evidence-backed documentation

**Files:**
- Modify: `HANDOFF.md`
- Modify: `README.md`
- Modify: `RELEASE_NOTES.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/smoke-test.md`
- Verify: all tracked source and generated exports

**Interfaces:**
- Consumes: results and exact versions from Tasks 1–7.
- Produces: an auditable statement of what passed, what changed, and what remains unvalidated.

- [ ] **Step 1: Rerun automated gateway checks from a clean container**

Repeat Task 1 Step 3. Expected: pytest, Ruff, and mypy all pass on the final tree.

- [ ] **Step 2: Rerun both smoke-test parts**

Repeat every applicable command/check in `docs/smoke-test.md` Part A on port 8081
and Part B against `AIR_DEV`. Record pass/fail facts without recording secrets,
workspace IDs, schema passwords, or container IDs.

- [ ] **Step 3: Scan the repository for leaked local values**

Run searches for the actual SYS/schema/APEX passwords, local API keys, workspace
ID, and machine-specific absolute paths. Expected: no tracked match. Also inspect:

```powershell
git status --short
git diff --check
git diff --stat main...HEAD
```

- [ ] **Step 4: Update documentation with observed evidence**

Record Oracle Database 23ai Free and APEX 26.1.0, the exact database/plug-in/page
checks that passed, the tested exports, and every source adjustment made. Remove
the blanket “never validated against Oracle/APEX” limitation while preserving
remaining Switchyard, real-provider benchmark, SQLite multiprocess, streaming,
and deployment-guide limitations.

- [ ] **Step 5: Review generated exports and final diff**

Confirm the exports contain no credentials, local hostnames beyond documented
localhost examples, workspace IDs presented as reusable configuration, or
machine paths. Confirm cost wording and security boundaries remain consistent.

- [ ] **Step 6: Commit the validation record**

Run:

```powershell
git add HANDOFF.md README.md RELEASE_NOTES.md CHANGELOG.md docs/smoke-test.md
git diff --cached --check
git commit -m "docs: record live Oracle and APEX validation"
```

- [ ] **Step 7: Final branch verification**

Run `git status --short --branch` and review `git log --oneline main..HEAD`.
Expected: clean branch containing the design, validated exports, any focused
compatibility fixes, and the documentation record.
