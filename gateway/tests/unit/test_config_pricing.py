import pytest

from apex_ai_router.config import PricingConfigError, load_pricing_config

_VALID_TEMPLATE = """
pricing:
  mock-efficient-v1:
    effective_date: 2026-01-01
    input_per_million: {input_price}
    output_per_million: 0.00
"""


def test_load_pricing_config_happy_path(tmp_path):
    path = tmp_path / "pricing.yaml"
    path.write_text(_VALID_TEMPLATE.format(input_price="0.50"), encoding="utf-8")

    config = load_pricing_config(path)

    assert config.pricing["mock-efficient-v1"].input_per_million == 0.50


def test_load_pricing_config_missing_file_raises(tmp_path):
    missing = tmp_path / "nope.yaml"

    with pytest.raises(PricingConfigError, match="not found"):
        load_pricing_config(missing)


def test_load_pricing_config_malformed_shape_raises_pricing_config_error(tmp_path):
    """Mirrors the routing.yaml case: `PricingConfig.model_validate` used to
    raise a bare `pydantic.ValidationError` with no try/except around it,
    bypassing the sanitized `PricingConfigError` handling entirely. Here, a
    non-numeric price is a type mismatch pydantic rejects."""
    path = tmp_path / "pricing.yaml"
    path.write_text(_VALID_TEMPLATE.format(input_price="not-a-number"), encoding="utf-8")

    with pytest.raises(PricingConfigError, match="Invalid pricing config"):
        load_pricing_config(path)
