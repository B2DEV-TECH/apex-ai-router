"""Routing strategy identifiers (spec section 11).

A plain enum, kept separate from `service.py` so a future strategy (stage
router, escalation, composite) can be registered without growing the
dispatch function into a large conditional.
"""

from enum import StrEnum


class RouteStrategy(StrEnum):
    FIXED = "fixed"
    LLM_CLASSIFIER = "llm_classifier"
