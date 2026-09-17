"""Optional LLM-judge scoring pass (spec section 27) for the subjective
categories flagged `judge_eligible: true` in tasks.yaml (summarization,
email generation, explanations, business-rule reasoning, longer-context
reasoning) -- categories where the deterministic `keyword_presence` scorer
in `scoring.py` is only a coarse proxy for actual quality.

The judge is a real gateway request through `apex-capable` by default, not
a separate model integration -- it goes through the same routing, auth, and
telemetry path as every other benchmark call, so its cost and tokens are
real, measured values (spec 27: "Never hide the judge cost"). `runner.py`
reconciles judge calls against `/admin/requests` exactly like task calls,
but keeps their cost/token totals in a separate bucket in the report.

In `--mode mock`, judge calls are still made for real over real HTTP, but
the mock upstream (`mocks/mock_model_server.py`) always returns a fixed
`"[mock:TIER:MODEL] response to: ..."` string regardless of the grading
prompt, which is never valid JSON in the shape this module expects. Every
judge score in a mock run therefore fails to parse by design -- this is
reported explicitly as a known mock-mode limitation, not silently retried
or papered over with a fabricated fallback score.
"""

from __future__ import annotations

import json
import re
import time
from dataclasses import dataclass

import httpx

_STRIP_FENCE = re.compile(r"^```[a-zA-Z0-9_-]*\n(.*)\n```$", re.DOTALL)

JUDGE_SYSTEM_PROMPT = (
    "You are a strict grading assistant. You will be shown a TASK PROMPT, a set "
    "of EXPECTED CHARACTERISTICS the ideal answer should have, and a candidate "
    "RESPONSE. Score how well the RESPONSE satisfies the EXPECTED CHARACTERISTICS "
    "on a 0-10 integer scale (0 = does not address the task at all, 10 = fully "
    "satisfies every expected characteristic). Reply with ONLY a JSON object of "
    'the exact shape {"score": <integer 0-10>, "rationale": "<one short sentence>"} '
    "and nothing else -- no markdown fence, no extra text."
)


@dataclass
class JudgeResult:
    task_id: str
    mode: str | None
    request_id: str | None
    score: int | None
    rationale: str | None
    parse_error: str | None
    input_tokens: int | None
    output_tokens: int | None
    latency_ms: float
    http_status: int | None


def _build_grading_prompt(task: dict, response_text: str) -> str:
    characteristics = task.get("expected_characteristics", [])
    characteristics_text = "\n".join(f"- {c}" for c in characteristics)
    return (
        f"TASK PROMPT:\n{task['prompt']}\n\n"
        f"EXPECTED CHARACTERISTICS:\n{characteristics_text}\n\n"
        f"RESPONSE:\n{response_text}"
    )


def run_judge(
    client: httpx.Client,
    gateway_url: str,
    api_key: str,
    task: dict,
    response_text: str,
    mode: str | None = None,
    judge_route: str = "apex-capable",
    timeout: float = 60.0,
) -> JudgeResult:
    grading_prompt = _build_grading_prompt(task, response_text)
    body = {
        "model": judge_route,
        "messages": [
            {"role": "system", "content": JUDGE_SYSTEM_PROMPT},
            {"role": "user", "content": grading_prompt},
        ],
    }

    started = time.perf_counter()
    try:
        response = client.post(
            f"{gateway_url}/v1/chat/completions",
            headers={"Authorization": f"Bearer {api_key}"},
            json=body,
            timeout=timeout,
        )
    except httpx.HTTPError as exc:
        latency_ms = (time.perf_counter() - started) * 1000
        return JudgeResult(
            task_id=task["id"],
            mode=mode,
            request_id=None,
            score=None,
            rationale=None,
            parse_error=f"transport error: {exc}",
            input_tokens=None,
            output_tokens=None,
            latency_ms=latency_ms,
            http_status=None,
        )
    latency_ms = (time.perf_counter() - started) * 1000
    request_id = response.headers.get("X-Request-Id")

    if response.status_code != 200:
        return JudgeResult(
            task_id=task["id"],
            mode=mode,
            request_id=request_id,
            score=None,
            rationale=None,
            parse_error=f"HTTP {response.status_code}: {response.text[:200]}",
            input_tokens=None,
            output_tokens=None,
            latency_ms=latency_ms,
            http_status=response.status_code,
        )

    payload = response.json()
    usage = payload.get("usage", {})
    content = payload["choices"][0]["message"]["content"]
    candidate = content.strip()
    match = _STRIP_FENCE.match(candidate)
    if match:
        candidate = match.group(1).strip()

    try:
        parsed = json.loads(candidate)
        score = int(parsed["score"])
        rationale = str(parsed.get("rationale", ""))
        parse_error = None
        if not 0 <= score <= 10:
            parse_error = f"score {score} out of expected 0-10 range"
            score = None
    except (json.JSONDecodeError, KeyError, TypeError, ValueError) as exc:
        score = None
        rationale = None
        parse_error = f"judge response not in the expected JSON shape: {exc} (raw: {content[:200]!r})"

    return JudgeResult(
        task_id=task["id"],
        mode=mode,
        request_id=request_id,
        score=score,
        rationale=rationale,
        parse_error=parse_error,
        input_tokens=usage.get("prompt_tokens"),
        output_tokens=usage.get("completion_tokens"),
        latency_ms=latency_ms,
        http_status=response.status_code,
    )
