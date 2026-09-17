.PHONY: install lint test test-integration run docker-up docker-down benchmark-mock benchmark-real

install:
	cd gateway && uv sync

lint:
	cd gateway && uv run ruff check .

test:
	cd gateway && uv run pytest tests/unit tests/contract

test-integration:
	cd gateway && uv run pytest tests/integration

run:
	cd gateway && uv run uvicorn apex_ai_router.main:app --reload --port 8080

docker-up:
	docker compose up --build

docker-down:
	docker compose down

# Spawns a mock upstream, the gateway, and (if built -- see
# deploy/switchyard/README.md) switchyard-server as local subprocesses; no
# network access or API credentials required. See benchmark/README.md for
# what a mock run does and does not prove.
benchmark-mock:
	cd gateway && uv run python ../benchmark/runner.py --mode mock --judge --out-dir ../benchmark/results/latest-mock

# Runs against an already-running gateway with real credentials, e.g.:
#   make benchmark-real GATEWAY_URL=https://your-gateway-host API_KEY=... ADMIN_KEY=...
# If the gateway is unreachable or a key is missing, this writes an explicit
# UNMEASURED report instead of inventing numbers (spec section 28).
GATEWAY_URL ?= http://127.0.0.1:8080
API_KEY ?=
ADMIN_KEY ?=

benchmark-real:
	cd gateway && uv run python ../benchmark/runner.py --mode real \
		--gateway-url $(GATEWAY_URL) --api-key $(API_KEY) --admin-key $(ADMIN_KEY) \
		--judge --out-dir ../benchmark/results/latest-real
