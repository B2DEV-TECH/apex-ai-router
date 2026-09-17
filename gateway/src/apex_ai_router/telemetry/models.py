"""Row shape recorded for every request that reaches the chat-completions
handler (spec section 13). Metadata only, by design — see
`TelemetryStore.record_request` for the dev-only, off-by-default content
logging opt-in.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class RequestTelemetry:
    request_id: str
    route: str
    policy: str | None
    selected_target: str | None
    selected_provider: str | None
    selected_model: str | None
    routing_duration_ms: float | None
    provider_duration_ms: float | None
    total_duration_ms: float
    input_tokens: int | None
    output_tokens: int | None
    total_tokens: int | None
    estimated_cost: float | None
    estimated_baseline_cost: float | None
    estimated_savings: float | None
    success: bool
    http_status: int
    error_code: str | None
    # Retries actually performed against the upstream provider (spec section
    # 24). None when no provider call was attempted (e.g. routing_failed).
    retry_count: int | None = None
