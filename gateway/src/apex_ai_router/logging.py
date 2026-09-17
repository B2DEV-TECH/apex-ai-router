"""Structured JSON logging.

Log records never include prompt or response content. The extra fields
listed in `_TELEMETRY_FIELDS` match the observability field set from the
project specification (section 33) and are populated by later phases via
`logging.LoggerAdapter` / `extra=`; at this phase nothing populates them yet.
"""

import json
import logging
import sys
from datetime import UTC, datetime

_TELEMETRY_FIELDS = (
    "request_id",
    "route",
    "selected_target",
    "provider",
    "model",
    "duration_ms",
    "status",
    "error_code",
)


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "timestamp": datetime.fromtimestamp(record.created, tz=UTC).isoformat(),
            "level": record.levelname.lower(),
            "logger": record.name,
            "message": record.getMessage(),
        }
        for field in _TELEMETRY_FIELDS:
            value = getattr(record, field, None)
            if value is not None:
                payload[field] = value
        if record.exc_info:
            payload["exc_info"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def configure_logging(level: str = "info") -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level.upper())
