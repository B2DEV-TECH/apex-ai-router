from apex_ai_router.domain.pricing import PricingConfig
from apex_ai_router.telemetry.cost import estimate_baseline_comparison, estimate_cost


def _pricing() -> PricingConfig:
    return PricingConfig.model_validate(
        {
            "pricing": {
                "efficient-model": {
                    "effective_date": "2026-01-01",
                    "input_per_million": 1.0,
                    "output_per_million": 2.0,
                },
                "capable-model": {
                    "effective_date": "2026-01-01",
                    "input_per_million": 10.0,
                    "output_per_million": 20.0,
                },
                "free-model": {
                    "effective_date": "2026-01-01",
                    "input_per_million": 0.0,
                    "output_per_million": 0.0,
                },
            }
        }
    )


def test_pricing_math_computes_input_output_and_total_cost():
    result = estimate_cost("efficient-model", 1_000_000, 500_000, _pricing())

    assert result.input_cost == 1.0
    assert result.output_cost == 1.0
    assert result.total_cost == 2.0
    assert result.price_effective_date == "2026-01-01"


def test_pricing_math_scales_with_token_count():
    result = estimate_cost("capable-model", 100_000, 50_000, _pricing())

    assert result.input_cost == 1.0
    assert result.output_cost == 1.0
    assert result.total_cost == 2.0


def test_zero_priced_model_reports_real_zero_not_unknown():
    result = estimate_cost("free-model", 1_000, 1_000, _pricing())

    assert result.total_cost == 0.0
    assert result.price_effective_date == "2026-01-01"


def test_unknown_model_reports_none_never_zero():
    result = estimate_cost("some-model-with-no-pricing-entry", 1_000, 1_000, _pricing())

    assert result.input_cost is None
    assert result.output_cost is None
    assert result.total_cost is None
    assert result.price_effective_date is None


def test_baseline_comparison_computes_savings_and_percent():
    actual = estimate_cost("efficient-model", 1_000_000, 500_000, _pricing())
    baseline = estimate_cost("capable-model", 1_000_000, 500_000, _pricing())

    comparison = estimate_baseline_comparison(actual, baseline)

    assert comparison.estimated_capable_baseline_cost == baseline.total_cost
    assert comparison.estimated_savings == baseline.total_cost - actual.total_cost
    assert comparison.estimated_savings_percent == (
        comparison.estimated_savings / baseline.total_cost * 100
    )


def test_baseline_comparison_is_none_when_actual_pricing_unknown():
    actual = estimate_cost("unknown-model", 1_000, 1_000, _pricing())
    baseline = estimate_cost("capable-model", 1_000, 1_000, _pricing())

    comparison = estimate_baseline_comparison(actual, baseline)

    assert comparison.estimated_capable_baseline_cost is None
    assert comparison.estimated_savings is None
    assert comparison.estimated_savings_percent is None


def test_baseline_comparison_is_none_when_baseline_pricing_unknown():
    actual = estimate_cost("efficient-model", 1_000, 1_000, _pricing())
    baseline = estimate_cost("unknown-model", 1_000, 1_000, _pricing())

    comparison = estimate_baseline_comparison(actual, baseline)

    assert comparison.estimated_savings is None
