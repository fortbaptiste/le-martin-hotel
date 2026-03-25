"""Token cost calculation per Claude model."""

from __future__ import annotations

# Pricing per 1M tokens (USD) — updated for Claude Sonnet 4
_PRICING: dict[str, tuple[float, float]] = {
    # (input_per_1M, output_per_1M)
    "claude-sonnet-4-6": (3.0, 15.0),
    "claude-sonnet-4-20250514": (3.0, 15.0),
    "claude-haiku-4-5-20251001": (0.80, 4.0),
    "claude-opus-4-6": (15.0, 75.0),
    "claude-opus-4-20250514": (15.0, 75.0),
}

# USD→EUR approximate rate
_USD_TO_EUR = 0.92


def compute_cost_eur(
    model: str,
    input_tokens: int,
    output_tokens: int,
) -> float:
    """Compute cost in EUR for a Claude API call."""
    input_rate, output_rate = _PRICING.get(model, (3.0, 15.0))

    cost_usd = (input_tokens / 1_000_000) * input_rate + (output_tokens / 1_000_000) * output_rate
    cost_eur = cost_usd * _USD_TO_EUR

    return round(cost_eur, 6)
