"""Test cost calculation."""

from src.services.cost_tracker import compute_cost_eur


class TestCostTracker:
    def test_zero_tokens(self):
        assert compute_cost_eur("claude-sonnet-4-20250514", 0, 0) == 0.0

    def test_sonnet_pricing(self):
        # 1000 input + 500 output on Sonnet 4
        # Input: 1000/1M * $3.0 = $0.003
        # Output: 500/1M * $15.0 = $0.0075
        # Total USD: $0.0105 * 0.92 = ~0.00966 EUR
        cost = compute_cost_eur("claude-sonnet-4-20250514", 1000, 500)
        assert 0.009 < cost < 0.011

    def test_haiku_cheaper_than_sonnet(self):
        haiku = compute_cost_eur("claude-haiku-4-5-20251001", 1000, 500)
        sonnet = compute_cost_eur("claude-sonnet-4-20250514", 1000, 500)
        assert haiku < sonnet

    def test_opus_most_expensive(self):
        opus = compute_cost_eur("claude-opus-4-20250514", 1000, 500)
        sonnet = compute_cost_eur("claude-sonnet-4-20250514", 1000, 500)
        assert opus > sonnet

    def test_unknown_model_uses_default(self):
        cost = compute_cost_eur("unknown-model", 1000, 500)
        sonnet_cost = compute_cost_eur("claude-sonnet-4-20250514", 1000, 500)
        assert cost == sonnet_cost

    def test_typical_email_cost(self):
        # Typical email: ~2000 input, ~800 output on Sonnet
        cost = compute_cost_eur("claude-sonnet-4-20250514", 2000, 800)
        # Should be well under 0.02 EUR
        assert cost < 0.02
        assert cost > 0

    def test_large_conversation_cost(self):
        # Large conversation: 50K input, 4K output
        cost = compute_cost_eur("claude-sonnet-4-20250514", 50000, 4000)
        # ~$0.15 + $0.06 = ~$0.21 * 0.92 = ~0.19 EUR
        assert 0.1 < cost < 0.3
