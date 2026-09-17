"""Estimated-cost calculation (spec section 12).

Every number here is explicitly an *estimate*: token counts come from
whatever the upstream provider reports in its own `usage` block (never
independently metered), and pricing is whatever the operator configured in
`config/pricing.yaml`. A model with no pricing entry has **unknown**
pricing, and every field below for it must be `None` — this module never
substitutes `0.0` for "we don't know", per spec section 12 and the wording
constraints in section 29 ("Estimated cost", never a guaranteed figure).
"""

from dataclasses import dataclass

from apex_ai_router.domain.pricing import PricingConfig


@dataclass(frozen=True)
class CostEstimate:
    input_cost: float | None
    output_cost: float | None
    total_cost: float | None
    price_effective_date: str | None


_UNKNOWN_COST = CostEstimate(
    input_cost=None, output_cost=None, total_cost=None, price_effective_date=None
)


def estimate_cost(
    model: str, input_tokens: int, output_tokens: int, pricing: PricingConfig
) -> CostEstimate:
    entry = pricing.pricing.get(model)
    if entry is None:
        return _UNKNOWN_COST

    input_cost = (input_tokens / 1_000_000) * entry.input_per_million
    output_cost = (output_tokens / 1_000_000) * entry.output_per_million
    return CostEstimate(
        input_cost=input_cost,
        output_cost=output_cost,
        total_cost=input_cost + output_cost,
        price_effective_date=entry.effective_date.isoformat(),
    )


@dataclass(frozen=True)
class BaselineComparison:
    estimated_capable_baseline_cost: float | None
    estimated_savings: float | None
    estimated_savings_percent: float | None


_UNKNOWN_BASELINE = BaselineComparison(
    estimated_capable_baseline_cost=None, estimated_savings=None, estimated_savings_percent=None
)


def estimate_baseline_comparison(
    actual: CostEstimate, baseline: CostEstimate
) -> BaselineComparison:
    """Compares an already-computed cost against what the same request would
    have cost on the route's capable target, using the *same observed token
    counts* for both sides — the capable model would not necessarily produce
    the same token counts in reality, so this is a deliberate approximation
    of "same input, same rough output size", not a claim about what the
    capable model actually would have generated. See HANDOFF.md.
    """
    if actual.total_cost is None or baseline.total_cost is None:
        return _UNKNOWN_BASELINE

    savings = baseline.total_cost - actual.total_cost
    savings_percent = (savings / baseline.total_cost * 100) if baseline.total_cost > 0 else None
    return BaselineComparison(
        estimated_capable_baseline_cost=baseline.total_cost,
        estimated_savings=savings,
        estimated_savings_percent=savings_percent,
    )
