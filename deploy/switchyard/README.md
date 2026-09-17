# Switchyard sidecar deployment

`apex-auto` routing is not implemented in the gateway itself. The gateway
forwards `apex-auto` requests over HTTP to a `switchyard-server` sidecar
process (from [NVIDIA NeMo Switchyard](https://github.com/NVIDIA-NeMo/Switchyard)),
which classifies the request and calls the efficient or capable model
directly.

## 1. Build `switchyard-server`

There is no published binary release; install it with Cargo (needs a Rust
toolchain):

```sh
cargo install --locked \
  --git https://github.com/NVIDIA-NeMo/Switchyard.git \
  --rev 1759dfdff95ed2718f6dd2afef6541654bbd0116 \
  switchyard-server \
  --root .tools/switchyard
```

This pins the exact commit this project was built and tested against —
Switchyard is pre-1.0 and NVIDIA describes it as experimental. Do not track
its `main` branch without re-validating `deploy/switchyard/routes.example.toml`
against the new `docs/reference/toml_schema.md`.

## 2. Generate `routes.generated.toml`

```sh
uv run --project gateway python scripts/render_switchyard_config.py
```

This reads `gateway/config/routing.yaml` (already resolved against your
`.env`) and writes `deploy/switchyard/routes.generated.toml` — a real,
loadable Switchyard config, not checked into git because it embeds your
actual model ids and base URLs. Re-run it whenever routing.yaml changes.

## 3. Run the sidecar

```sh
.tools/switchyard/bin/switchyard-server \
  --config deploy/switchyard/routes.generated.toml \
  --port 4000
```

Point `SWITCHYARD_BASE_URL` (see `.env.example`) at this address —
`http://localhost:4000` by default. Validate a config without binding a
socket with `--dry-run`.

## 4. Run it locally against the mock models (helper scripts)

`scripts/run_switchyard_local.sh` (Linux/macOS/Git Bash) and
`scripts/run_switchyard_local.ps1` (Windows PowerShell) wrap steps 2 and 3
for the local Docker setup. They point the three `*_MODEL_BASE_URL`
variables at the mock model ports `docker-compose.yml` publishes (`9001`
for the efficient model, `9002` for the capable model and the judge), set a
placeholder for any unset `*_MODEL_API_KEY` (the server refuses to start
when the env var named in `api_key_env` is missing, and the mocks ignore
the value), render the config, validate it with `--dry-run`, and then run
the sidecar in the foreground on `127.0.0.1:4000` with
`--routing-log-file` pointing at `.tools/switchyard/routing.jsonl`.

```sh
scripts/run_switchyard_local.sh            # run
scripts/run_switchyard_local.sh --dry-run  # validate the config only
```

```powershell
scripts\run_switchyard_local.ps1           # run
scripts\run_switchyard_local.ps1 -DryRun   # validate the config only
```

Two things to keep straight:

- **Which side of Docker each URL is seen from.** The sidecar runs on the
  host, so it reaches the mocks through their *published* host ports. The
  gateway container reaches the sidecar through `SWITCHYARD_BASE_URL`,
  which under docker-compose must be `http://host.docker.internal:4000`
  rather than `http://localhost:4000` (inside the container, `localhost`
  is the container itself). Set it in `.env` before `docker compose up`.
- **The routing log is the sidecar's own evidence.** Every decision is
  appended as JSON lines: the classifier call to the judge followed by the
  call to the backend it picked. `docs/live-validation-walkthrough.md`
  uses it to show that the efficient/capable split recorded in the
  gateway's `upstream_model` telemetry came from Switchyard, not from the
  gateway.

## Notes

- All three `[llm_clients]` entries render with `format = "openai_chat"`.
  This is a deliberate V1 simplification: the gateway's own `TargetConfig`
  schema has no field to select `openai_responses` or `anthropic_messages`
  upstream wire formats yet (see `HANDOFF.md`).
- `base_threshold` comes straight from routing.yaml's `apex-auto.threshold`
  (default `0.5`). `threshold_step`, `classify_trigger`,
  `message_hash_fallback`, `recent_turn_window`, and a custom judge
  `prompt` are all real, documented Switchyard knobs this project does not
  yet expose — see `HANDOFF.md`.
