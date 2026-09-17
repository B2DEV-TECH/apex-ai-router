.PHONY: install lint test test-integration run docker-up docker-down

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
