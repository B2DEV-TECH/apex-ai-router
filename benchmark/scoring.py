"""Deterministic scoring functions for the benchmark harness (spec section 27).

Every scorer here is a heuristic, not a real parser, compiler, or semantic
grader -- each docstring says exactly what it can and cannot verify. Spec
section 27 prefers deterministic scoring over an LLM judge wherever
practical; `benchmark/judge.py` implements the optional, separately-tracked
judge pass for the subjective categories these scorers can only weakly
approximate (`judge_eligible: true` in tasks.yaml).

Every scorer returns a `ScoreResult` and never raises for a malformed model
response -- a response that fails to parse is a *failed score*, not a
harness crash.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field


@dataclass
class ScoreResult:
    method: str
    passed: bool
    score: float  # 0.0-1.0
    detail: str


def _strip_code_fence(text: str) -> str:
    """Models very commonly wrap JSON/SQL/PL-SQL in a markdown code fence
    even when asked not to. Stripping one *optional* fence is a reasonable
    accommodation for every scorer below that parses structured output; it
    does not change what is actually being checked."""
    stripped = text.strip()
    match = re.match(r"^```[a-zA-Z0-9_-]*\n(.*)\n```$", stripped, re.DOTALL)
    return match.group(1).strip() if match else stripped


def score_valid_json(response_text: str, params: dict) -> ScoreResult:
    """Checks the response is valid JSON and, when given, that every
    required key is present. With `expect_array: true`, the top level must
    be a non-empty array and every element must carry every required key
    (a data-mapping/extraction task producing a list of objects); otherwise
    the top level itself must carry every required key. Does not check
    value *correctness* beyond key presence and basic array-of-objects
    shape -- it cannot know a business-specific expected value."""
    required_keys = params.get("required_keys", [])
    expect_array = bool(params.get("expect_array", False))
    candidate = _strip_code_fence(response_text)

    try:
        parsed = json.loads(candidate)
    except json.JSONDecodeError as exc:
        return ScoreResult("valid_json", False, 0.0, f"not valid JSON: {exc}")

    if expect_array:
        if not isinstance(parsed, list) or not parsed:
            return ScoreResult("valid_json", False, 0.0, "expected a non-empty JSON array")
        missing_any = []
        for i, item in enumerate(parsed):
            if not isinstance(item, dict):
                return ScoreResult(
                    "valid_json", False, 0.0, f"array element {i} is not a JSON object"
                )
            missing = [k for k in required_keys if k not in item]
            if missing:
                missing_any.append((i, missing))
        if missing_any:
            return ScoreResult(
                "valid_json", False, 0.0, f"elements missing required keys: {missing_any}"
            )
        return ScoreResult("valid_json", True, 1.0, f"valid JSON array, {len(parsed)} element(s)")

    if not isinstance(parsed, dict):
        return ScoreResult("valid_json", False, 0.0, "expected a JSON object at the top level")
    missing = [k for k in required_keys if k not in parsed]
    if missing:
        return ScoreResult("valid_json", False, 0.0, f"missing required keys: {missing}")
    return ScoreResult("valid_json", True, 1.0, "valid JSON object with all required keys")


def score_keyword_presence(response_text: str, params: dict) -> ScoreResult:
    """Coarse substring-presence check across `required_keywords`. This is a
    weak proxy for whether the response actually addresses the task: a model
    could include a keyword out of context and pass, or paraphrase correctly
    and be marked as failing. Categories marked `judge_eligible: true` in
    tasks.yaml pair this with `benchmark/judge.py` for a real quality
    signal; this scorer alone should be read as "did the response even
    mention the load-bearing facts," not "is the response good.\""""
    required = params.get("required_keywords", [])
    case_sensitive = bool(params.get("case_sensitive", False))
    min_fraction = float(params.get("min_fraction", 1.0))

    haystack = response_text if case_sensitive else response_text.lower()
    found = []
    missing = []
    for kw in required:
        needle = kw if case_sensitive else kw.lower()
        (found if needle in haystack else missing).append(kw)

    fraction = len(found) / len(required) if required else 1.0
    passed = fraction >= min_fraction
    detail = f"found {found}, missing {missing}" if missing else f"found all: {found}"
    return ScoreResult("keyword_presence", passed, fraction, detail)


def score_classification_exact_match(response_text: str, params: dict) -> ScoreResult:
    """Strict exact-match classification check: the response, once
    stripped of surrounding whitespace and a single trailing period, must
    equal `expected_label` case-insensitively and contain nothing else. A
    correct label buried in a longer sentence is deliberately scored as a
    failure -- the task explicitly asks for a single-word answer, so
    verbosity here is itself a task-following failure, not a scoring bug."""
    expected = params.get("expected_label", "")
    allowed = params.get("allowed_labels", [])
    candidate = response_text.strip().rstrip(".").strip()

    if candidate.upper() == expected.upper():
        return ScoreResult("classification_exact_match", True, 1.0, f"matched '{expected}'")
    if allowed and candidate.upper() in [a.upper() for a in allowed]:
        return ScoreResult(
            "classification_exact_match",
            False,
            0.0,
            f"answered a valid label '{candidate}' but expected '{expected}'",
        )
    return ScoreResult(
        "classification_exact_match",
        False,
        0.0,
        f"response {candidate!r} is not the expected single-word label '{expected}'",
    )


def score_sql_clauses(response_text: str, params: dict) -> ScoreResult:
    """Regex/keyword clause-presence heuristic, NOT a real SQL parser. It
    can only confirm that expected clause keywords (`required_clauses`,
    matched as whole words, case-insensitive) and identifier/token
    substrings (`required_tokens`) appear somewhere in the response -- it
    cannot verify the query is syntactically valid, would actually execute,
    or joins/filters correctly."""
    candidate = _strip_code_fence(response_text)
    lowered = candidate.lower()

    missing_clauses = [
        c for c in params.get("required_clauses", []) if not re.search(rf"\b{re.escape(c)}\b", lowered)
    ]
    missing_tokens = [t for t in params.get("required_tokens", []) if t.lower() not in lowered]

    if missing_clauses or missing_tokens:
        return ScoreResult(
            "sql_clauses",
            False,
            0.0,
            f"missing clauses: {missing_clauses}, missing tokens: {missing_tokens}",
        )
    return ScoreResult("sql_clauses", True, 1.0, "all required clauses and tokens present")


def score_plsql_structure(response_text: str, params: dict) -> ScoreResult:
    """Regex-based structural heuristic, NOT a PL/SQL parser or compiler. It
    checks for a top-level `CREATE OR REPLACE PROCEDURE`/`PACKAGE` (and, for
    packages, a matching `PACKAGE BODY`) plus `required_tokens` as
    case-insensitive substrings. It cannot verify the generated code
    actually compiles in Oracle, has correct syntax, or is logically
    correct -- only that the expected shape and identifiers are present."""
    candidate = _strip_code_fence(response_text)
    lowered = candidate.lower()
    kind = params.get("kind", "procedure")

    if kind == "package":
        has_spec = re.search(r"create\s+or\s+replace\s+package\s+(?!body)", lowered) is not None
        has_body = re.search(r"create\s+or\s+replace\s+package\s+body", lowered) is not None
        structural_ok = has_spec and has_body
        structural_detail = f"package spec present: {has_spec}, package body present: {has_body}"
    else:
        structural_ok = re.search(r"create\s+or\s+replace\s+procedure", lowered) is not None
        structural_detail = f"procedure header present: {structural_ok}"

    missing_tokens = [t for t in params.get("required_tokens", []) if t.lower() not in lowered]

    if not structural_ok or missing_tokens:
        return ScoreResult(
            "plsql_structure",
            False,
            0.0,
            f"{structural_detail}; missing tokens: {missing_tokens}",
        )
    return ScoreResult("plsql_structure", True, 1.0, f"{structural_detail}; all tokens present")


def score_regex_match(response_text: str, params: dict) -> ScoreResult:
    """Every pattern in `patterns` must match somewhere in the response
    (`re.search`, case-insensitive unless `case_sensitive: true`). A
    thin, explicit wrapper around regex matching -- no semantic
    understanding of what the pattern is meant to prove."""
    case_sensitive = bool(params.get("case_sensitive", False))
    flags = 0 if case_sensitive else re.IGNORECASE
    patterns = params.get("patterns", [])

    unmatched = [p for p in patterns if not re.search(p, response_text, flags)]
    if unmatched:
        return ScoreResult("regex_match", False, 0.0, f"unmatched patterns: {unmatched}")
    return ScoreResult("regex_match", True, 1.0, "all patterns matched")


SCORERS = {
    "valid_json": score_valid_json,
    "keyword_presence": score_keyword_presence,
    "classification_exact_match": score_classification_exact_match,
    "sql_clauses": score_sql_clauses,
    "plsql_structure": score_plsql_structure,
    "regex_match": score_regex_match,
}


def score_task(method: str, response_text: str, params: dict) -> ScoreResult:
    scorer = SCORERS.get(method)
    if scorer is None:
        return ScoreResult(method, False, 0.0, f"unknown scoring method: {method}")
    return scorer(response_text, params or {})
