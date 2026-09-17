"""Model pricing schema (spec section 12).

`config/pricing.yaml` is keyed by the *actual* model id a target resolves to
(`TargetConfig.model`), not by target name or route name — the same model
can be reached through more than one target, and pricing is a property of
the model, not of how it's wired up.

Prices are never fabricated here: entries for real commercial models must be
filled in by the operator from their own provider's current price sheet.
Any model with no entry (or no entry effective on or before the request's
date) has unknown pricing, and every cost field in `CostEstimate` for it
must be `None` — never `0.0`.
"""

from datetime import date

from pydantic import BaseModel, ConfigDict


class ModelPricing(BaseModel):
    model_config = ConfigDict(extra="forbid")

    effective_date: date
    input_per_million: float
    output_per_million: float


class PricingConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")

    pricing: dict[str, ModelPricing] = {}
