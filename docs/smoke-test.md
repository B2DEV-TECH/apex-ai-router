# Smoke test checklist

A manual, click-and-`curl`-along checklist to validate a deployment (or the
local Docker mock stack) before trusting it. Every command below is real —
copy/paste it. Expected outputs are described, not guaranteed byte-for-byte
(request IDs, timestamps, and latencies will differ every run).

This checklist has two parts: **Part A** exercises the gateway on its own
(no Oracle/APEX needed). **Part B** exercises the Oracle/APEX-side pieces
(`database/`, `apex-plugin/`, `apex-demo/`). Both parts were run against
the local mock stack; Part B used Oracle Database 23ai Free and APEX 26.1.

## Part A — gateway (mock stack, no real provider needed)

### A1. Bring up the mock stack

```sh
cp .env.example .env
```

Edit `.env` and set at minimum:

```
APEX_AI_ROUTER_API_KEYS=smoke-test-key
APEX_AI_ROUTER_ADMIN_API_KEY=smoke-test-admin-key
EFFICIENT_MODEL_ID=mock-efficient-v1
EFFICIENT_MODEL_BASE_URL=http://mock-efficient-model:9001
CAPABLE_MODEL_ID=mock-capable-v1
CAPABLE_MODEL_BASE_URL=http://mock-capable-model:9002
```

(`EFFICIENT_MODEL_API_KEY`/`CAPABLE_MODEL_API_KEY` can stay blank — the
mock servers don't check them.)

```sh
docker compose up --build
```

Expect three containers to start (`gateway`, `mock-efficient-model`,
`mock-capable-model`) with no restart loops.

### A2. Health and readiness

```sh
curl -s http://localhost:8080/health
curl -s http://localhost:8080/ready
```

**Expect:** `/health` returns `{"status":"ok"}` (or equivalent liveness
shape). `/ready` returns a `status` of `"ready"` once `.env` is filled in
correctly — if it instead says `"not_ready"`, read the accompanying
`checks` object; it names the exact missing/invalid setting (this is the
sanitized-error behavior confirmed in `CHANGELOG.md`'s `[0.1.0]` entry).

### A3. List virtual models

```sh
curl -s http://localhost:8080/v1/models \
  -H "Authorization: Bearer smoke-test-key"
```

**Expect:** an OpenAI-shaped `{"object":"list","data":[...]}` listing
`apex-auto`, `apex-efficient`, `apex-capable`.

**Also check the negative case** — no/garbage key should be rejected, not
silently allowed:

```sh
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/v1/models
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/v1/models \
  -H "Authorization: Bearer wrong-key"
```

**Expect:** both `401`.

### A4. Fixed routing — efficient and capable

```sh
curl -s http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer smoke-test-key" -H "Content-Type: application/json" \
  -d '{"model":"apex-efficient","messages":[{"role":"user","content":"hello"}]}'

curl -s http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer smoke-test-key" -H "Content-Type: application/json" \
  -d '{"model":"apex-capable","messages":[{"role":"user","content":"hello"}]}'
```

**Expect:** an OpenAI-shaped chat completion from each, with the mock's
canned `"[mock:TIER:MODEL] response to: ..."` content — `TIER` should say
`efficient` for the first call and `capable` for the second. If they're
swapped or identical, routing is broken.

### A5. `apex-auto` (optional — requires the Switchyard sidecar)

Only run this if you've built `switchyard-server` per
`deploy/switchyard/README.md` and rendered its config
(`scripts/render_switchyard_config.py`) and started it, with
`SWITCHYARD_BASE_URL` in `.env` pointing at it.

```sh
curl -s http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer smoke-test-key" -H "Content-Type: application/json" \
  -d '{"model":"apex-auto","messages":[{"role":"user","content":"hello"}]}'
```

**Expect:** a successful chat completion (either tier's mock response is
fine — see `HANDOFF.md` §2 for why you can't tell which tier from the
gateway's own telemetry).

### A6. Admin/telemetry surface

```sh
curl -s http://localhost:8080/admin/metrics/summary \
  -H "Authorization: Bearer smoke-test-admin-key"
curl -s http://localhost:8080/admin/requests \
  -H "Authorization: Bearer smoke-test-admin-key"
curl -s http://localhost:8080/admin/routes \
  -H "Authorization: Bearer smoke-test-admin-key"
```

**Expect:** `/admin/metrics/summary` and `/admin/requests` reflect the
requests made in A4/A5 (non-zero counts, estimated costs — `$0.00` is
correct for the mock models, see `gateway/config/pricing.yaml`).
`/admin/routes` echoes back the resolved `routing.yaml`.

**Also check that an inference key cannot read admin data:**

```sh
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/admin/requests \
  -H "Authorization: Bearer smoke-test-key"
```

**Expect:** `401` (the inference key must not work here).

### A7. Sanitized error handling

Temporarily break `EFFICIENT_MODEL_ID` in `.env` (e.g. set it to
`${NOT_A_REAL_VAR}`), restart the gateway, and repeat A3:

```sh
curl -s http://localhost:8080/v1/models -H "Authorization: Bearer smoke-test-key"
```

**Expect:** HTTP 500 with a clean
`{"error":{"code":"routing_failed","message":"...NOT_A_REAL_VAR...","request_id":"..."}}`
body — never a raw Python stack trace. Undo the change afterward.

### A8. Automated suite, lint, and the mock benchmark

```sh
cd gateway && uv run pytest && uv run ruff check . && uv run mypy src
cd .. && make benchmark-mock
```

**Expect:** all tests pass (99 at the time of the 0.1.0 release), lint and
type checks clean, and a benchmark report written under
`benchmark/results/` (compare its shape to the committed
`benchmark/results/mock-example/report.md`).

## Part B — Oracle / APEX

Needs a real Oracle Database (12.2+) and, for B3/B4, a real APEX workspace
(20.1+) with a Web Credential pointed at a running gateway instance.

### B1. Database objects

```sql
-- as a DBA-privileged user, in a disposable schema
@database/install.sql
@database/tests/smoke_test.sql
```

**Expect:** `install.sql` completes without error, creating
`AIR_CONFIG`/`AIR_REQUEST_LOG`, the two `AIR_*_V` views, and the
`APEX_AI_ROUTER` package. `smoke_test.sql` (self-contained, no gateway
call) should pass. If anything fails, start here — nothing downstream
works without these objects. Then run `database/grants/
grants_to_apex_schema.sql` if the APEX parsing schema differs from the
install schema.

### B2. PL/SQL package against a real gateway

Configure a Web Credential per `database/README.md`, then:

```sql
@database/tests/manual_gateway_test.sql
```

**Expect:** a real HTTP round trip to your gateway and back, returning
model-generated text (not a mock string, if pointed at a real provider).

### B3. Plug-in export

Compile the callback package, import
`apex-plugin/dist/dynamic_action_plugin_air_dynamic_action_generate.sql`,
then run `apex-plugin/README.md`'s manual QA checklist. The committed APEX
26.1 export was reimported successfully and exposes all eight attributes.

### B4. Demo application

Import `apex-demo/f1207.sql` after installing the database, plug-in, and
demo support packages. Click through Playground, Dashboard, Request
History, and Configuration Help against the gateway. The committed export
was reimported under another application ID and passed this flow against
the local mock providers.

## Sign-off

The 2026-09-17 sign-off covered Part A and B1-B4 on Oracle Database 23ai
Free / APEX 26.1 with local mock providers. Efficient and Capable routes
passed. Auto produced a controlled provider-unavailable error because the
Switchyard sidecar was not running. Repeat the checklist with the target
Oracle/APEX versions and real providers before production deployment.
