#!/usr/bin/env sh
# Renders deploy/switchyard/routes.generated.toml and runs the NVIDIA NeMo
# Switchyard sidecar on this machine against the docker-compose mock models.
# Same behaviour as scripts/run_switchyard_local.ps1 (documented there);
# override the defaults through the environment variables below.
#
#   EFFICIENT_URL / CAPABLE_URL / JUDGE_URL  model base URLs as seen from the host
#   BIND_HOST / PORT                         where the sidecar listens (4000 matches .env.example)
#   ROUTING_LOG                              JSON-lines file with every routing decision
#   PYTHON                                   interpreter able to import the gateway package
#
# Pass --dry-run to only render and validate the config.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BINARY="$ROOT/.tools/switchyard/bin/switchyard-server"
[ -x "$BINARY" ] || BINARY="$BINARY.exe"
if [ ! -x "$BINARY" ]; then
    echo "switchyard-server not found under .tools/switchyard/bin - build it first (deploy/switchyard/README.md, section 1)" >&2
    exit 1
fi

# The mock models ignore API keys, but Switchyard refuses to start while an
# api_key_env variable is unset, so the mock targets get a placeholder.
: "${EFFICIENT_MODEL_API_KEY:=mock-local}"
: "${CAPABLE_MODEL_API_KEY:=mock-local}"
: "${JUDGE_MODEL_API_KEY:=mock-local}"
export EFFICIENT_MODEL_API_KEY CAPABLE_MODEL_API_KEY JUDGE_MODEL_API_KEY
export EFFICIENT_MODEL_BASE_URL="${EFFICIENT_URL:-http://127.0.0.1:9001}"
export CAPABLE_MODEL_BASE_URL="${CAPABLE_URL:-http://127.0.0.1:9002}"
export JUDGE_MODEL_BASE_URL="${JUDGE_URL:-http://127.0.0.1:9002}"

BIND_HOST="${BIND_HOST:-127.0.0.1}"
PORT="${PORT:-4000}"
ROUTING_LOG="${ROUTING_LOG:-$ROOT/.tools/switchyard/routing.jsonl}"

PYTHON="${PYTHON:-}"
if [ -z "$PYTHON" ]; then
    for candidate in "$ROOT/gateway/.venv/bin/python" "$ROOT/gateway/.venv/Scripts/python.exe" "$ROOT/.tools/venv312/Scripts/python.exe"; do
        if [ -x "$candidate" ]; then PYTHON="$candidate"; break; fi
    done
    [ -n "$PYTHON" ] || PYTHON="uv run --project $ROOT/gateway python"
fi

$PYTHON "$ROOT/scripts/render_switchyard_config.py"
CONFIG="$ROOT/deploy/switchyard/routes.generated.toml"

"$BINARY" --config "$CONFIG" --dry-run
if [ "${1:-}" = "--dry-run" ]; then exit 0; fi

mkdir -p "$(dirname "$ROUTING_LOG")"
echo "switchyard-server listening on http://$BIND_HOST:$PORT (routing log: $ROUTING_LOG). Ctrl+C stops it."
exec "$BINARY" --config "$CONFIG" --host "$BIND_HOST" --port "$PORT" --routing-log-file "$ROUTING_LOG"
