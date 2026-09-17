# Live validation walkthrough

This is the end-to-end validation of APEX AI Router that was run on
2026-09-17 against Oracle Database 23ai Free, APEX 26.1 and a **running
NVIDIA NeMo Switchyard sidecar**, written so that you can repeat it on your
own machine step by step. Everything below was executed as described; the
screenshots in `images/` come from the automated browser run at the end,
not from a mock-up.

The point of the exercise is not "the pages render". It is that one
`apex-auto` request leaves a consistent trace in four places that do not
share code, so the routing decision can be checked without trusting any
single component:

```text
APEX page (demo app or plug-in)
  -> PL/SQL: APEX_AI_ROUTER_DEMO / APEX_AI_ROUTER (APEX_WEB_SERVICE)
  -> gateway  POST /v1/chat/completions  model = apex-auto
  -> Switchyard sidecar: classifier call to the judge, then the backend it picked
  -> mock efficient or mock capable model (echoes which one answered)

Evidence, per request:
  1. the demo's decision card / Request History  (reads gateway telemetry)
  2. gateway telemetry: /admin/requests -> upstream_model
  3. the sidecar's own routing log (JSON lines)
  4. the response text itself: [mock:<tier>:<model>] response to: ...
```

All model providers in this walkthrough are the repository's **mock
servers**. The routing is real; the quality and cost figures are not (see
[What this proves, and what it does not](#what-this-proves-and-what-it-does-not)).

## Prerequisites

| Component | Used on 2026-09-17 | Notes |
|---|---|---|
| Docker with Compose v2 | Docker Desktop on Windows 11 | Runs the gateway and the two mock model servers. |
| Rust toolchain (`cargo`) | stable | Only to build `switchyard-server`; there is no binary release. |
| Python 3.12 + `uv` | 3.12 | Renders the Switchyard config from `gateway/config/routing.yaml`. |
| Oracle Database | 23ai Free, local install (not in a container) | Any edition with APEX 26.1 works; adjust the URLs in step 4 if the database runs in a container. |
| Oracle APEX + ORDS | APEX 26.1.0, ORDS on `http://localhost:8080/ords` | A workspace with a parsing schema you can install packages into. |
| Node 22 + Google Chrome | Node 22.16, Chrome stable | Only for the automated browser QA (`apex-demo/qa/`). |

Port `8080` is used twice on a single machine: by the gateway
(`docker-compose.yml`) and, typically, by ORDS. Move one of them. In the
validated setup the gateway was published on another host port through an
ignored `docker-compose.override.yml`; the tracked documentation keeps the
default `8080`. Whatever you choose, use it consistently in
`AIR_CONFIG.GATEWAY_BASE_URL` (step 4) and the `curl` commands below.

## 1. Start the gateway and the mock providers

```sh
cp .env.example .env
```

Set at least these values in `.env` (the mock servers ignore API keys, so
`*_MODEL_API_KEY` can stay blank):

```text
APEX_AI_ROUTER_API_KEYS=smoke-test-key
APEX_AI_ROUTER_ADMIN_API_KEY=smoke-test-admin-key
EFFICIENT_MODEL_ID=mock-efficient-v1
EFFICIENT_MODEL_BASE_URL=http://mock-efficient-model:9001
CAPABLE_MODEL_ID=mock-capable-v1
CAPABLE_MODEL_BASE_URL=http://mock-capable-model:9002
JUDGE_MODEL_ID=mock-judge-v1
JUDGE_MODEL_BASE_URL=http://mock-capable-model:9002
SWITCHYARD_BASE_URL=http://host.docker.internal:4000
```

`SWITCHYARD_BASE_URL` is the one value that differs from `.env.example`:
the sidecar runs on the host in step 2, and from inside the gateway
container `localhost` would be the container itself. The judge is served
by the capable mock, which also implements the classifier endpoint.

```sh
docker compose up --build
curl -s http://localhost:8080/health
curl -s http://localhost:8080/ready
```

Expect three containers (`gateway`, `mock-efficient-model`,
`mock-capable-model`), `{"status":"ok"}` from `/health` and a `status` of
`ready` from `/ready`. `/ready` names any missing setting in its `checks`
object, so a `not_ready` here is a configuration problem, not a network
one.

## 2. Build and run the NeMo Switchyard sidecar

`apex-auto` is not implemented inside the gateway: the gateway forwards it
to `switchyard-server`, which classifies the prompt with the judge model
and then calls the efficient or capable backend itself.
`deploy/switchyard/README.md` is the reference; the short version:

```sh
# 2a. build the pinned commit into .tools/switchyard (once, ~ a few minutes)
cargo install --locked \
  --git https://github.com/NVIDIA-NeMo/Switchyard.git \
  --rev 1759dfdff95ed2718f6dd2afef6541654bbd0116 \
  switchyard-server \
  --root .tools/switchyard

# 2b. render the config from routing.yaml + .env, validate it, run the sidecar
scripts/run_switchyard_local.sh --dry-run     # Linux/macOS/Git Bash
scripts/run_switchyard_local.sh
```

```powershell
scripts\run_switchyard_local.ps1 -DryRun      # Windows PowerShell
scripts\run_switchyard_local.ps1
```

The helper points the sidecar at the mock ports Docker publishes on the
host (`9001` efficient, `9002` capable and judge), writes
`deploy/switchyard/routes.generated.toml`, validates it with `--dry-run`,
and runs the server in the foreground on `127.0.0.1:4000` with
`--routing-log-file .tools/switchyard/routing.jsonl`. Leave it running in
its own terminal. The `-DryRun` / `--dry-run` pass is worth doing first: it
fails loudly when a model id or base URL in `.env` does not match what the
config expects, before anything touches APEX.

**How the mock judge decides.** The mock judge is deliberately simple and
documented: a prompt of 40 words or fewer is classified as a task the
efficient model supports; anything longer is sent to the capable model
(`MOCK_JUDGE_WORD_LIMIT` on the mock server, default `40`). That is what
makes the walkthrough deterministic: a short prompt must land on
`mock-efficient-v1`, a long one on `mock-capable-v1`, every time.

## 3. Prove the routing from the command line first

Before involving Oracle, make the same two requests the demo app will make:

```sh
# short prompt -> expected: efficient
curl -s http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer smoke-test-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"apex-auto","messages":[{"role":"user","content":"Explain what an Oracle sequence is in one sentence."}]}'

# long prompt (more than 40 words) -> expected: capable
curl -s http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer smoke-test-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"apex-auto","messages":[{"role":"user","content":"Review the following PL/SQL package for correctness, performance and security. It loads invoices in bulk, validates the customer, applies tax rules per state, writes an audit row per line and raises a business exception when the total differs from the header. Explain every problem you find and propose a corrected version with bind variables and explicit exception handling."}]}'
```

The `content` of the first answer starts with
`[mock:efficient:mock-efficient-v1] response to:` and the second with
`[mock:capable:mock-capable-v1] response to:`. The mock models echo their
own tier and model id, which is evidence item 4 in the diagram above.

Now read the gateway's record of the same two requests (evidence item 2):

```sh
curl -s "http://localhost:8080/admin/requests?limit=2" \
  -H "Authorization: Bearer smoke-test-admin-key"
```

Each entry has `route` = `apex-auto`, `selected_target` = `switchyard`
and — new in this validation — `upstream_model` = `mock-efficient-v1` or
`mock-capable-v1`. `upstream_model` is the model id the sidecar reports in
its OpenAI-compatible response; the gateway stores it verbatim and exposes
it here and in `/admin/metrics/backends` (counts per route and backend).

And the sidecar's own account (evidence item 3):

```sh
tail -n 4 .tools/switchyard/routing.jsonl
```

Every `apex-auto` request appends two JSON lines: the classifier call to
the judge, then the call to the backend it chose, with `model` and `tier`
(`efficient` / `capable`). Requests to `apex-efficient` or `apex-capable`
never appear here, because they never reach the sidecar — a useful
negative check later.

## 4. Oracle side: database objects, credentials, demo application

Run these as the workspace's parsing schema (SQL*Plus or SQLcl, from the
repository root):

```sql
@database/install.sql                        -- AIR_CONFIG, AIR_REQUEST_LOG, APEX_AI_ROUTER
@database/tests/smoke_test.sql               -- offline checks, no gateway needed
@apex-plugin/sql/install_plugin_package.sql  -- APEX_AI_ROUTER_DA (plug-in callbacks)
@apex-demo/sql/install_demo.sql              -- APEX_AI_ROUTER_DEMO + ADMIN_CREDENTIAL_STATIC_ID
```

Then point the package at your gateway. Keep the `/v1` suffix; the demo
package derives the `/health`, `/ready` and `/admin/*` URLs from it:

```sql
update air_config
   set config_value = 'http://localhost:8080/v1'   -- the URL as seen FROM THE DATABASE HOST
 where config_key = 'GATEWAY_BASE_URL';
commit;
```

If the database itself runs in a container, `localhost` is that container;
use `http://host.docker.internal:8080/v1` (Docker Desktop) or the host's
address on the Docker network instead. If the first call from PL/SQL fails
with `ORA-24247` (network access denied), the APEX engine schema still
needs a network ACL for the gateway host — the standard APEX post-install
step, done by your DBA in the Oracle documentation's own words.

### Two Web Credentials

The gateway has two kinds of key, and the PL/SQL side keeps them apart on
purpose: an inference key can never read telemetry. Create two **HTTP
Header** Web Credentials (Shared Components > Workspace Utilities > Web
Credentials), each with header name `Authorization` and value
`Bearer <key>`:

| Static ID | Holds | Read by |
|---|---|---|
| `AIR_GATEWAY_CREDENTIAL` | one of `APEX_AI_ROUTER_API_KEYS` (`smoke-test-key` above) | `APEX_AI_ROUTER.generate` — Playground, plug-in |
| `AIR_GATEWAY_ADMIN_CREDENTIAL` | `APEX_AI_ROUTER_ADMIN_API_KEY` (`smoke-test-admin-key`) | the demo's Dashboard, Request History and Configuration Help |

The same can be scripted with `APEX_CREDENTIAL` (APEX 24.2+), which is how
the validated instance was configured; the values were typed at a prompt,
never stored in a file:

```sql
begin
    apex_util.set_workspace(p_workspace => '<WORKSPACE>');
    apex_credential.create_credential(
        p_credential_name      => 'APEX AI Router Inference',
        p_credential_static_id => 'AIR_GATEWAY_CREDENTIAL',
        p_authentication_type  => apex_credential.c_type_http_header,
        p_allowed_urls         => apex_t_varchar2('http://localhost:8080/'));
    apex_credential.set_persistent_credentials(
        p_credential_static_id => 'AIR_GATEWAY_CREDENTIAL',
        p_key                  => 'Authorization',
        p_value                => 'Bearer ' || '<inference key>');
    -- repeat for AIR_GATEWAY_ADMIN_CREDENTIAL with the admin key
    commit;
end;
/
```

### Import the demo application

`apex-demo/f1213.sql` is the sanitized APEX 26.1 export of the four-page
demo (the plug-in is inside it; only its callback package needs to exist,
which step 4 already did). Import it from App Builder > Import (choose the
parsing schema, keep or reassign the application id), or from SQL:

```sql
begin
    apex_application_install.set_workspace('<WORKSPACE>');
    apex_application_install.set_schema('<PARSING_SCHEMA>');
    apex_application_install.set_application_id(1213);      -- or any free id
    apex_application_install.generate_offset;
    apex_application_install.set_application_alias('APEX-AI-ROUTER-DEMO');
end;
/
@apex-demo/f1213.sql
```

The export was produced with `scripts/sanitize_apex_export.py`, which
neutralizes the workspace id, owner schema and exporter name so nothing
from the validation environment is baked into it (see `apex-demo/README.md`).
It was reimported under another application id and passed the same browser
QA as the original — that is the validation record at the end of this page.

## 5. Walk through the application

Log in to the application with any workspace user that can run it. The
navigation has four pages: Playground, Dashboard, Request History and
Configuration Help.

### Page 1 — Playground

![Playground, short prompt answered by the efficient model](images/01-playground-auto-efficient.png)

1. Click **Short example**. It fills the prompt with a one-sentence
   question and sets the route to *Auto*. Click **Send**.
   - The response text starts with `[mock:efficient:mock-efficient-v1]`.
   - The decision card shows route `apex-auto`, target `switchyard`,
     upstream `mock-efficient-v1`, tier `efficient`, plus latency, token
     count, estimated cost and the gateway request id.
2. Click **Long example** (a review request well over 40 words) and
   **Send**.
   - The response starts with `[mock:capable:mock-capable-v1]`; the card
     shows upstream `mock-capable-v1`, tier `capable`, still through
     `switchyard`.

   ![Playground, long prompt answered by the capable model](images/02-playground-auto-capable.png)

3. Type any prompt, change the route to *Efficient* and **Send**.
   - Route `apex-efficient`, target `efficient`: no classifier involved,
     and nothing new appears in the sidecar's routing log.
4. The three **Plug-in** buttons exercise the reusable Dynamic Action
   plug-in with its three prompt sources, not the demo package:
   - **Plug-in: Static / Auto** — a three-word static prompt, route Auto:
     answered by the efficient model (the same Switchyard path as step 1).
   - **Plug-in: Item / Efficient** — the prompt item, fixed efficient route.
   - **Plug-in: JavaScript / Capable** — a JavaScript expression, fixed
     capable route.
   The processing indicator is shown for Static and Item and deliberately
   switched off for JavaScript (plug-in attribute 07), and each success
   fires the `apexairouter:success` event on the button.

   ![Playground after the plug-in checks](images/03-playground-plugin-checks.png)

Behind **Send** is a single Ajax Callback (`PLAYGROUND_RUN`) that calls
`APEX_AI_ROUTER_DEMO.ajax_run`, which calls `APEX_AI_ROUTER.generate` and
then fetches the request's telemetry row from the gateway to fill the card.
The browser never talks to the gateway or to a model.

### Page 2 — Dashboard

![Dashboard](images/04-dashboard.png)

- Two pills show the gateway's `/health` (`ok`) and `/ready` (`ready`).
- Six KPI tiles from `/admin/metrics/summary`: Requests, Success rate,
  Estimated cost, Estimated capable-model baseline, Estimated savings, and
  **Auto requests answered by the efficient model** — the share that only
  became observable with `upstream_model`.
- Four native APEX (JET) charts, all `json_table` views over the gateway's
  JSON: *Backend that answered, per route* (`/admin/metrics/backends`),
  *Requests by route*, *Requests per day (UTC)* (`/admin/metrics/daily`)
  and *Tokens per backend*.
- A backends table with the same breakdown as numbers.

With the mock providers every cost is `$0.00`; the tiles prove the
arithmetic and the wiring, not a saving.

### Page 3 — Request History

![Request History](images/05-request-history.png)

A native Interactive Report over `/admin/requests?limit=500` (again
`json_table` over the gateway JSON, so filtering, sorting, highlighting and
download are the standard IR features). The **Backend** column is a badge
coloured by tier: `efficient` or `capable`, taken from `upstream_model`.
After the Playground steps above you should see both colours, and the most
recent rows should match the decision cards you just saw, request id for
request id.

### Page 4 — Configuration Help

![Configuration Help](images/06-configuration-help.png)

Read-only: the gateway base URL from `AIR_CONFIG`, the health/readiness
pills, the routes the gateway advertises (`apex-auto` with the
`llm_classifier` policy, `apex-efficient` and `apex-capable` fixed), the
resolved targets (efficient, capable, judge and `switchyard`) and links to
this walkthrough, `docs/apex-ai-setup.md` and
`deploy/switchyard/README.md`. It is the page to open when something on
the other three does not look right: an empty routes table means the admin
credential or the base URL is wrong, and it says so.

## 6. Cross-check outside APEX

After clicking through Page 1, run the three commands from step 3 again.
For every request the demo made:

| Where | What to look for |
|---|---|
| `/admin/requests` | the same `request_id` as the decision card, `selected_target` = `switchyard` for Auto, `upstream_model` = the badge in Request History |
| `/admin/metrics/backends` | the per-route counts move by the number of requests you sent, under the right backend |
| `.tools/switchyard/routing.jsonl` | two new lines per Auto request (judge, then backend), none for the fixed routes |
| the response text | `[mock:<tier>:<model>]` agrees with all of the above |

This is the check that matters for the "does Switchyard really route it?"
question: the gateway cannot fabricate the sidecar's log, and the sidecar
cannot write the gateway's telemetry.

## 7. Automated browser QA

The same walkthrough is scripted with Playwright in `apex-demo/qa/`, and it
is what produced `images/01..06`. It logs in, runs the Playground steps
(including the plug-in buttons, counting spinners and events), then checks
the Dashboard, Request History and Configuration Help, and exits `1` if
any expectation fails.

```sh
cd apex-demo/qa
npm install                                  # playwright-core only; uses the installed Chrome
APEX_USER=<workspace user> APEX_PASSWORD=<password> APP_ID=1213 node browser_qa.mjs
```

Optional: `APEX_BASE_URL` (default `http://localhost:8080/ords`),
`SCREENSHOT_DIR` to regenerate the six screenshots, `CHROME_PATH` for an
explicit browser binary. The password is read from the environment only;
screenshots mask the navigation bar and the gateway URL.

## What this proves, and what it does not

**Proven on 2026-09-17:**

- The full path APEX page → PL/SQL → gateway → NeMo Switchyard → backend
  works, for the demo package and for the Dynamic Action plug-in, with the
  sidecar actually running and actually deciding.
- The decision is observable end to end: the backend that answered is
  recorded in the gateway's telemetry (`upstream_model`), shown in APEX,
  and agrees with the sidecar's routing log and with the model's own echo.
- Fixed routes bypass the classifier, as designed.
- The exported application imports cleanly into another application id and
  passes the same automated checks.

**Not proven, and not claimed:**

- Any quality, latency or cost result with real model providers. The judge
  is a word-count rule and the models echo the prompt; every cost is zero.
  `benchmark/README.md` explains how to measure that against your own
  providers.
- Production readiness of Switchyard, which NVIDIA describes as
  experimental; this project pins one commit and says so.
- `upstream_model` is what the sidecar reports; the gateway does not see
  the classifier's score or threshold. For that level of detail read the
  routing log.

## Validation record — 2026-09-17

| Check | Result |
|---|---|
| Gateway test suite (`pytest`, unit + contract + integration) | 106 passed; `ruff` and `mypy` clean |
| Plug-in client test (`node --test`) | 10 passed |
| Sidecar config (`run_switchyard_local.ps1 -DryRun`, then run) | valid; sidecar on `127.0.0.1:4000`, routing log written per request |
| `apex-auto` from `curl` | short → `mock-efficient-v1`, long → `mock-capable-v1`, consistent in telemetry, routing log and response text |
| Browser QA, application 1213 | passed three times (two during the build, once with the tracked `apex-demo/qa/browser_qa.mjs`): 0 failed expectations, 0 browser console errors; Auto short = efficient, Auto long = capable, fixed Efficient = efficient; plug-in 3 successes / 0 errors; 4 charts, 6 tiles; Request History rows all badged, both tiers present |
| Export → sanitize → reimport | `f1213.sql` reimported as application 1214, same QA passed; 1214 then removed |
| Database packages (`apex_ai_router`, `apex_ai_router_da`, `apex_ai_router_demo`) + `database/tests/smoke_test.sql` | recompiled with no errors, all objects VALID; required `AIR_CONFIG` keys present; unknown route raises `e_unknown_route` |

The first three rows can be reproduced without Oracle; the rest need the
setup in step 4. Numbers such as row counts and latencies will differ on
your machine and are not part of the claim.
