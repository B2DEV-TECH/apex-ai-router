import threading
import time

import pytest
import uvicorn

from apex_ai_router.mocks.mock_model_server import app as mock_app


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
