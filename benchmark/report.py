"""Markdown + JSON report generation for the benchmark harness (spec
section 28).

This module only aggregates and formats numbers that `runner.py` actually
measured (real HTTP calls, real `/admin/requests` reconciliation, real
deterministic scoring, real optional judge calls) -- it never estimates,
interpolates, or backfills a number that was not observed. Where a value is
genuinely unavailable (e.g. a reconciliation match was not found, or a
gateway call errored), the report renders "n/a", never a fabricated zero or
placeholder.

Per spec section 28, a `--mode real` run against an unreachable gateway (or
one with no credentials) does not produce a comparison table at all --
`write_unmeasured_report` writes an explicit UNMEASURED template instead,
so the dataset/scorer/runner infrastructure is still demonstrably exercised
without inventing any numbers.
"""

from __future__ import annotations

import json
import re
import statistics
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path

# Must match the keys of `runner.py`'s MODES dict exactly -- kept as a
# separate mapping here (rather than importing runner.py) to avoid a
# circular import, since runner.py imports this module.
MODE_LABELS = {
    "A_fixed_efficient": "Efficient (fixed apex-efficient)",
    "B_fixed_capable": "Capable (fixed apex-capable)",
    "C_apex_auto": "Auto (apex-auto)",
}
MODE_ORDER = list(MODE_LABELS)

MOCK_LIMITATIONS = """\
## Known limitations of this mock-mode run

This run used the project's own local mock model server, not a real LLM
provider. Read every number in this report with these limitations in mind:

1. **Quality scores are not representative of real model quality.** The
   mock upstream returns a fixed, prompt-content-independent string
   (`"[mock:TIER:MODEL] response to: ..."`) for every single request, so
   deterministic scores mostly reflect the mock's canned text, not what a
   real model would produce for these prompts.
2. **`apex-auto` will show ~100% routing to the capable target, and the
   gateway's own telemetry cannot see this at all.** Switchyard's
   `llm_classifier` routing treats an invalid, inconsistent, or unparseable
   classifier verdict as a fail-open condition and routes to `strong_target`
   (see `docs/routing_algorithms/llm_classifier_routing.md` at the pinned
   Switchyard commit, and `gateway/tests/integration/test_switchyard_auto_routing.py`).
   Because the mock's canned response is never a parseable classifier
   verdict, every `apex-auto` call in mock mode deterministically fails open
   to `capable` -- confirmed empirically in this repo's own smoke runs by
   parsing the mock's echoed response text, not just asserted. This is
   correct behavior of the real routing logic under a mock upstream, not a
   bug -- but it means this run cannot demonstrate real auto-routing
   distribution or cost savings. Only `--mode real` with genuinely
   differentiated efficient/capable models can show that. Separately, and in
   every mode (mock or real): the gateway's own `/admin/requests` telemetry
   records `selected_target` and `selected_model` as the fixed literals
   `"switchyard"`/`"apex-auto"` for any classifier-routed call -- it never
   records which backend Switchyard actually picked, because the gateway
   only resolves to the switchyard HTTP target itself and never inspects
   what happens behind that boundary (`routing/service.py`,
   `api/openai_chat.py`). The "observed backend" line below recovers the
   real choice only in mock mode, only because the mock server happens to
   echo the model string it received back into its response content; there
   is currently no equivalent way to recover this from a real deployment's
   telemetry alone (see `HANDOFF.md`).
3. **$0.00 costs are the mock models' genuinely accurate price, not a
   placeholder.** `gateway/config/pricing.yaml` documents `$0.00` for
   `mock-efficient-v1`/`mock-capable-v1`/`mock-judge-v1` because the local
   mock server truly costs nothing to run. This run reuses that real
   pricing file unmodified. It validates that cost-tracking, reconciliation,
   and reporting wiring works end-to-end -- it demonstrates nothing about
   real-world cost savings. Run `--mode real` against priced models for a
   meaningful savings number.
4. **Judge scores, if requested, will universally fail to parse.** The
   mock's canned response is never valid JSON in the shape the judge prompt
   asks for, so every judge call in mock mode is expected to end with a
   `parse_error`, by design (see `benchmark/judge.py`'s module docstring).
   This is reported explicitly below rather than retried or defaulted to a
   fabricated score.
"""


def _mean(values: list[float]) -> float | None:
    present = [v for v in values if v is not None]
    return statistics.mean(present) if present else None


def _fmt(value: float | None, spec: str = ".2f", suffix: str = "") -> str:
    return "n/a" if value is None else f"{value:{spec}}{suffix}"


def _fmt_cost(value: float | None) -> str:
    return "n/a" if value is None else f"${value:.6f}"


def _group_by_mode(scored: list[dict]) -> dict[str, list[dict]]:
    groups: dict[str, list[dict]] = {mode: [] for mode in MODE_ORDER}
    for entry in scored:
        mode = entry["record"]["mode"]
        groups.setdefault(mode, []).append(entry)
    return groups


def _mode_stats(entries: list[dict]) -> dict:
    n = len(entries)
    n_errors = sum(1 for e in entries if e["record"]["error"] is not None)
    n_passed = sum(1 for e in entries if e["deterministic_score"]["passed"])
    scores = [e["deterministic_score"]["score"] for e in entries]
    costs = [e["record"]["estimated_cost"] for e in entries]
    latencies = [e["record"]["client_latency_ms"] for e in entries]
    input_tokens = [e["record"]["input_tokens"] for e in entries]
    output_tokens = [e["record"]["output_tokens"] for e in entries]

    # For a `fixed` route, `selected_target`/`selected_model` are informative
    # ("efficient"/"capable", "mock-efficient-v1"/"mock-capable-v1"). For the
    # `llm_classifier` route (`apex-auto`), BOTH fields from the gateway's own
    # telemetry are fixed literals, not the backend Switchyard actually chose:
    # `selected_target` is always "switchyard" (the name of the gateway-level
    # HTTP target), and `selected_model` is always "apex-auto" (`openai_chat.py`
    # sets `selected_model = resolved.config.model`, and for a switchyard-routed
    # call `resolved.config` is the *switchyard* target's own TargetConfig,
    # whose `model` field is the fixed virtual model name "apex-auto" in both
    # `gateway/config/routing.yaml` and this harness's generated routing.yaml --
    # confirmed by reading `routing/service.py` and `api/openai_chat.py` in
    # full). The real efficient/capable pick made *inside* the switchyard-server
    # sidecar is architecturally invisible to the gateway's own telemetry in
    # every mode, mock or real -- grouping by `selected_model` here still
    # produces a real, correct distribution (it just always collapses to
    # `{"apex-auto": n}` for the Auto mode); the mock-mode-only diagnostic in
    # `_mock_observed_backend_distribution()` below is what recovers the true
    # backend choice, and only because the mock server happens to echo the
    # model string it actually received into its response content.
    models: dict[str, int] = {}
    for e in entries:
        model = e["record"]["selected_model"]
        if model is not None:
            models[model] = models.get(model, 0) + 1

    return {
        "n": n,
        "n_errors": n_errors,
        "success_rate": (n - n_errors) / n if n else None,
        "pass_rate": n_passed / n if n else None,
        "avg_deterministic_score": _mean(scores),
        "avg_cost": _mean(costs),
        "avg_latency_ms": _mean(latencies),
        "avg_input_tokens": _mean(input_tokens),
        "avg_output_tokens": _mean(output_tokens),
        "selected_model_distribution": models,
    }


# Mock-mode-only diagnostic. `mocks/mock_model_server.py` echoes whatever
# `model` string was actually in the HTTP request it received back into the
# response content: `f"[mock:{TIER}:{model}] response to: {behavior}"`. For
# a switchyard-routed (`apex-auto`) call, that `model` is whatever backend
# id the switchyard-server sidecar put in the request it forwarded to the
# target it internally chose (e.g. "mock-capable-v1") -- this is the ONLY
# place that choice is observable, since neither `selected_target` nor
# `selected_model` in the gateway's own telemetry can see past the
# switchyard boundary (see the comment in `_mode_stats()`). This does not
# generalize to `--mode real`: a real model's response text will not echo
# an internal routing decision like this, so the diagnostic is mock-only by
# construction, not just by current usage.
_MOCK_ECHO_RE = re.compile(r"^\[mock:[^:]+:([^\]]+)\]")


def _mock_observed_backend_distribution(entries: list[dict]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for e in entries:
        text = e["record"].get("response_text") or ""
        match = _MOCK_ECHO_RE.match(text)
        if match:
            model = match.group(1)
            counts[model] = counts.get(model, 0) + 1
    return counts


def _judge_stats_by_mode(judge_results: list) -> dict[str, dict]:
    grouped: dict[str, list] = {mode: [] for mode in MODE_ORDER}
    for jr in judge_results:
        grouped.setdefault(jr.mode, []).append(jr)

    stats = {}
    for mode, results in grouped.items():
        n = len(results)
        n_parse_errors = sum(1 for r in results if r.parse_error is not None)
        scores = [r.score for r in results if r.score is not None]
        stats[mode] = {
            "n": n,
            "n_parse_errors": n_parse_errors,
            "avg_score": _mean(scores),
        }
    return stats


def _comparison_table(mode_stats: dict[str, dict], modes_run: list[str]) -> str:
    lines = [
        "| Mode | Calls | Success Rate | Deterministic Pass Rate | Avg Score | Avg Cost | Avg Latency |",
        "|---|---|---|---|---|---|---|",
    ]
    for mode in modes_run:
        stats = mode_stats.get(mode, {})
        lines.append(
            "| {label} | {n} | {success} | {pass_rate} | {score} | {cost} | {latency} |".format(
                label=MODE_LABELS.get(mode, mode),
                n=stats.get("n", 0),
                success=_fmt(stats.get("success_rate"), ".0%"),
                pass_rate=_fmt(stats.get("pass_rate"), ".0%"),
                score=_fmt(stats.get("avg_deterministic_score"), ".2f"),
                cost=_fmt_cost(stats.get("avg_cost")),
                latency=_fmt(stats.get("avg_latency_ms"), ".0f", " ms"),
            )
        )
    return "\n".join(lines)


def _auto_vs_capable_block(
    mode_stats: dict[str, dict],
    run_mode: str,
    auto_entries: list[dict],
) -> str:
    auto = mode_stats.get("C_apex_auto")
    capable = mode_stats.get("B_fixed_capable")
    if not auto or not capable or not auto["n"] or not capable["n"]:
        return "_`apex-auto` was not exercised in this run (no Switchyard binary available) -- no Auto vs Capable comparison to show._"

    lines = ["## Auto vs Capable"]

    capable_cost = capable["avg_cost"]
    auto_cost = auto["avg_cost"]
    if capable_cost in (None, 0) or auto_cost is None:
        lines.append(
            "- **Estimated cost reduction:** n/a (capable's average cost is "
            f"{_fmt_cost(capable_cost)} in this run -- a $0.00 baseline makes a "
            "percentage reduction meaningless; see the mock-mode limitations above)"
        )
    else:
        reduction_pct = (capable_cost - auto_cost) / capable_cost * 100
        lines.append(f"- **Estimated cost reduction:** {reduction_pct:.1f}%")

    score_delta = (
        auto["avg_deterministic_score"] - capable["avg_deterministic_score"]
        if auto["avg_deterministic_score"] is not None and capable["avg_deterministic_score"] is not None
        else None
    )
    lines.append(f"- **Quality difference (deterministic score, auto - capable):** {_fmt(score_delta, '+.2f')}")

    capable_latency = capable["avg_latency_ms"]
    auto_latency = auto["avg_latency_ms"]
    if capable_latency:
        latency_pct = (auto_latency - capable_latency) / capable_latency * 100
        lines.append(f"- **Latency difference (auto vs capable):** {latency_pct:+.1f}%")
    else:
        lines.append("- **Latency difference (auto vs capable):** n/a")

    total_auto = sum(auto["selected_model_distribution"].values())
    if total_auto:
        dist_text = ", ".join(
            f"{model}: {count}/{total_auto} ({count / total_auto:.0%})"
            for model, count in sorted(auto["selected_model_distribution"].items())
        )
        lines.append(
            f"- **`apex-auto` gateway-telemetry model field (measured, this run):** {dist_text} "
            "-- for a classifier-routed call this field is always the fixed virtual model "
            'name "apex-auto" itself, not the backend Switchyard actually picked; see '
            "the next line for the real backend choice in this mock run."
        )
    else:
        lines.append(
            "- **`apex-auto` gateway-telemetry model field:** no reconciled `/admin/requests` "
            "rows were found for auto calls -- routing target unknown for this run."
        )

    if run_mode == "mock":
        observed = _mock_observed_backend_distribution(auto_entries)
        total_observed = sum(observed.values())
        if total_observed:
            observed_text = ", ".join(
                f"{model}: {count}/{total_observed} ({count / total_observed:.0%})"
                for model, count in sorted(observed.items())
            )
            lines.append(
                f"- **`apex-auto` observed backend, mock-mode diagnostic (parsed from the "
                f"mock's echoed response content, not from gateway telemetry):** {observed_text}"
            )
        else:
            lines.append(
                "- **`apex-auto` observed backend, mock-mode diagnostic:** could not parse "
                "the mock's echoed model from any auto-mode response content."
            )

    return "\n".join(lines)


def _category_breakdown(scored: list[dict], modes_run: list[str]) -> str:
    categories = sorted({e["task"]["category"] for e in scored})
    lines = ["| Category | " + " | ".join(MODE_LABELS.get(m, m) for m in modes_run) + " |"]
    lines.append("|---|" + "---|" * len(modes_run))
    for category in categories:
        row = [category]
        for mode in modes_run:
            entries = [
                e for e in scored if e["task"]["category"] == category and e["record"]["mode"] == mode
            ]
            passed = sum(1 for e in entries if e["deterministic_score"]["passed"])
            row.append(f"{passed}/{len(entries)}" if entries else "n/a")
        lines.append("| " + " | ".join(row) + " |")
    return "\n".join(lines)


def _judge_section(judge_results: list, judge_stats: dict[str, dict], modes_run: list[str]) -> str:
    if not judge_results:
        return ""

    lines = ["## LLM-judge results", "", "Judge calls are real gateway requests through `apex-capable`; their cost and tokens are tracked separately from task calls (spec 27: never hide the judge cost).", ""]
    lines.append("| Mode | Judge Calls | Parse Failures | Avg Judge Score (0-10) |")
    lines.append("|---|---|---|---|")
    for mode in modes_run:
        stats = judge_stats.get(mode, {"n": 0, "n_parse_errors": 0, "avg_score": None})
        lines.append(
            f"| {MODE_LABELS.get(mode, mode)} | {stats['n']} | {stats['n_parse_errors']} | "
            f"{_fmt(stats['avg_score'], '.2f')} |"
        )

    parse_failures = [jr for jr in judge_results if jr.parse_error is not None]
    if parse_failures:
        lines.append("")
        lines.append(f"<details><summary>{len(parse_failures)} judge parse failure(s) -- expand for detail</summary>")
        lines.append("")
        for jr in parse_failures[:20]:
            lines.append(f"- `{jr.task_id}` ({jr.mode}): {jr.parse_error}")
        if len(parse_failures) > 20:
            lines.append(f"- ... and {len(parse_failures) - 20} more")
        lines.append("")
        lines.append("</details>")

    return "\n".join(lines)


def _failed_calls_section(scored: list[dict]) -> str:
    failed = [e for e in scored if e["record"]["error"] is not None]
    if not failed:
        return ""
    lines = [f"## Failed calls ({len(failed)})", ""]
    for e in failed[:30]:
        record = e["record"]
        lines.append(f"- `{record['task_id']}` / {record['mode']}: {record['error']}")
    if len(failed) > 30:
        lines.append(f"- ... and {len(failed) - 30} more")
    return "\n".join(lines)


def _build_markdown(
    *,
    mode: str,
    tasks: list[dict],
    scored: list[dict],
    judge_results: list,
    modes_run: list[str],
    mode_stats: dict[str, dict],
    judge_stats: dict[str, dict],
) -> str:
    generated_at = datetime.now(timezone.utc).isoformat()
    categories = sorted({t["category"] for t in tasks})

    parts = [
        "# APEX AI Router -- Benchmark Report",
        "",
        f"- **Run mode:** `{mode}`",
        f"- **Generated at:** {generated_at}",
        f"- **Tasks:** {len(tasks)} across {len(categories)} categories",
        f"- **Execution modes run:** {', '.join(MODE_LABELS.get(m, m) for m in modes_run)}",
        "",
    ]
    if mode == "mock":
        parts.append(MOCK_LIMITATIONS)
        parts.append("")

    auto_entries = [e for e in scored if e["record"]["mode"] == "C_apex_auto"]

    parts.append("## Comparison")
    parts.append("")
    parts.append(_comparison_table(mode_stats, modes_run))
    parts.append("")
    parts.append(_auto_vs_capable_block(mode_stats, mode, auto_entries))
    parts.append("")
    parts.append("## By category (deterministic pass rate)")
    parts.append("")
    parts.append(_category_breakdown(scored, modes_run))

    judge_section = _judge_section(judge_results, judge_stats, modes_run)
    if judge_section:
        parts.append("")
        parts.append(judge_section)

    failed_section = _failed_calls_section(scored)
    if failed_section:
        parts.append("")
        parts.append(failed_section)

    parts.append("")
    parts.append(
        "_Every number above comes from a real HTTP call to a running gateway and, "
        "where applicable, a real `/admin/requests` reconciliation lookup by "
        "`X-Request-Id` -- see `benchmark/runner.py`. No numbers in this report were "
        "invented or interpolated._"
    )
    return "\n".join(parts)


def write_reports(
    *,
    out_dir: Path,
    mode: str,
    tasks: list[dict],
    scored: list[dict],
    judge_results: list,
    modes_run: list[str],
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    mode_stats = {m: _mode_stats(entries) for m, entries in _group_by_mode(scored).items()}
    judge_stats = _judge_stats_by_mode(judge_results)

    markdown = _build_markdown(
        mode=mode,
        tasks=tasks,
        scored=scored,
        judge_results=judge_results,
        modes_run=modes_run,
        mode_stats=mode_stats,
        judge_stats=judge_stats,
    )
    (out_dir / "report.md").write_text(markdown, encoding="utf-8")

    json_payload = {
        "mode": mode,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "task_count": len(tasks),
        "modes_run": modes_run,
        "mode_stats": mode_stats,
        "judge_stats": judge_stats,
        "scored": scored,
        "judge_results": [asdict(jr) for jr in judge_results],
    }
    (out_dir / "report.json").write_text(json.dumps(json_payload, indent=2), encoding="utf-8")


def write_unmeasured_report(*, out_dir: Path, tasks: list[dict], reason: str) -> None:
    """Spec section 28: 'If API credentials are unavailable, run
    infrastructure tests and produce an UNMEASURED benchmark report
    template rather than inventing numbers.'"""
    out_dir.mkdir(parents=True, exist_ok=True)
    generated_at = datetime.now(timezone.utc).isoformat()
    categories = sorted({t["category"] for t in tasks})

    markdown = "\n".join(
        [
            "# APEX AI Router -- Benchmark Report: UNMEASURED",
            "",
            f"- **Generated at:** {generated_at}",
            f"- **Requested mode:** `real`",
            f"- **Reason no numbers were collected:** {reason}",
            "",
            "This run did not produce any comparison numbers because a live, "
            "reachable gateway with valid `--api-key`/`--admin-key` credentials was "
            "not available. Per this project's policy of never fabricating "
            "benchmark numbers, this report intentionally contains none.",
            "",
            "## Infrastructure that *is* verified",
            "",
            f"- The task dataset loaded successfully: {len(tasks)} tasks across "
            f"{len(categories)} categories ({', '.join(categories)}).",
            "- `benchmark/scoring.py` and `benchmark/judge.py` import successfully "
            "and are exercised end-to-end by `--mode mock` (see `benchmark/reports/` "
            "for a mock-mode example report).",
            "",
            "## To collect real numbers",
            "",
            "```",
            "python benchmark/runner.py --mode real \\",
            "    --gateway-url https://your-gateway-host \\",
            "    --api-key <inference-key> --admin-key <admin-key>",
            "```",
        ]
    )
    (out_dir / "report.md").write_text(markdown, encoding="utf-8")

    json_payload = {
        "mode": "real",
        "measured": False,
        "reason": reason,
        "generated_at": generated_at,
        "task_count": len(tasks),
        "categories": categories,
    }
    (out_dir / "report.json").write_text(json.dumps(json_payload, indent=2), encoding="utf-8")
