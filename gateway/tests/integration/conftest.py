import socket
import subprocess
import threading
import time
from pathlib import Path

import httpx
import pytest
import uvicorn

from apex_ai_router.domain.model_target import RoutingConfig
from apex_ai_router.mocks.mock_model_server import app as mock_app
from apex_ai_router.routing.switchyard_config import render_routes_toml

# gateway/tests/integration/conftest.py -> repo root
REPO_ROOT = Path(__file__).resolve().parents[3]
SWITCHYARD_BINARY = REPO_ROOT / ".tools" / "switchyard" / "bin" / "switchyard-server.exe"


@pytest.fixture
def mock_upstream():
    """Runs the real mock model server on a real loopback socket in a
    background thread, so gateway integration tests exercise an actual
    HTTP round trip end to end rather than an in-process ASGI transport."""
    config = uvicorn.Config(mock_app, host="127.0.0.1", port=0, log_level="warning")
    server = uvicorn.Server(config)
    thread = threading.Thread(target=server.run, daemon=True)
    thread.start()

    for _ in range(200):
        if server.started:
            break
        time.sleep(0.01)
    else:
        raise RuntimeError("mock upstream server did not start in time")

    port = server.servers[0].sockets[0].getsockname()[1]
    try:
        yield f"http://127.0.0.1:{port}"
    finally:
        server.should_exit = True
        thread.join(timeout=5)


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


@pytest.fixture
def switchyard_sidecar(mock_upstream, monkeypatch, tmp_path):
    """Runs the real, compiled `switchyard-server` binary (see
    deploy/switchyard/README.md) against the same mock upstream used by
    `mock_upstream`, using a routes.toml rendered by the project's own
    `render_routes_toml`. Skips (rather than failing) if the binary has not
    been built locally — it is a build artifact, not something checked into
    the repo."""
    if not SWITCHYARD_BINARY.exists():
        pytest.skip(
            f"switchyard-server binary not found at {SWITCHYARD_BINARY}; "
            "see deploy/switchyard/README.md to build it."
        )

    monkeypatch.setenv("EFFICIENT_MODEL_API_KEY", "test-efficient-key")
    monkeypatch.setenv("CAPABLE_MODEL_API_KEY", "test-capable-key")
    monkeypatch.setenv("JUDGE_MODEL_API_KEY", "test-judge-key")

    config = RoutingConfig.model_validate(
        {
            "routes": {
                "apex-auto": {
                    "strategy": "llm_classifier",
                    "switchyard_target": "switchyard",
                    "efficient_target": "efficient",
                    "capable_target": "capable",
                    "judge_target": "judge",
                    "threshold": 0.5,
                }
            },
            "targets": {
                "efficient": {
                    "provider": "openai_compatible",
                    "model": "mock-efficient-v1",
                    "base_url": mock_upstream,
                    "api_key_env": "EFFICIENT_MODEL_API_KEY",
                },
                "capable": {
                    "provider": "openai_compatible",
                    "model": "mock-capable-v1",
                    "base_url": mock_upstream,
                    "api_key_env": "CAPABLE_MODEL_API_KEY",
                },
                "judge": {
                    "provider": "openai_compatible",
                    "model": "mock-judge-v1",
                    "base_url": mock_upstream,
                    "api_key_env": "JUDGE_MODEL_API_KEY",
                },
                "switchyard": {
                    "provider": "switchyard",
                    "model": "apex-auto",
                    "base_url": "http://unused.invalid",
                },
            },
        }
    )
    routes_toml = tmp_path / "routes.generated.toml"
    routes_toml.write_text(render_routes_toml(config), encoding="utf-8")

    port = _free_port()
    process = subprocess.Popen(
        [
            str(SWITCHYARD_BINARY),
            "--config",
            str(routes_toml),
            "--host",
            "127.0.0.1",
            "--port",
            str(port),
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    base_url = f"http://127.0.0.1:{port}"
    try:
        for _ in range(200):
            if process.poll() is not None:
                output = process.stdout.read() if process.stdout else ""
                raise RuntimeError(
                    f"switchyard-server exited early (code {process.returncode}):\n{output}"
                )
            try:
                response = httpx.get(f"{base_url}/health", timeout=0.2)
                if response.status_code == 200:
                    break
            except httpx.TransportError:
                pass
            time.sleep(0.05)
        else:
            process.kill()
            raise RuntimeError("switchyard-server did not become healthy in time")

        yield base_url
    finally:
        process.kill()
        process.wait(timeout=5)
