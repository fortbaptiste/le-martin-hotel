"""Test webhook endpoint — rate limiting, validation, clientState."""

import time
from unittest.mock import patch, AsyncMock

import pytest
from fastapi.testclient import TestClient

from src.api.webhooks import router, _call_timestamps, _is_rate_limited, _verify_client_state


class TestRateLimiting:
    def setup_method(self):
        _call_timestamps.clear()

    def test_first_call_not_limited(self):
        assert _is_rate_limited() is False

    def test_limit_reached(self):
        # Fill up to the limit
        for _ in range(30):
            _is_rate_limited()
        assert _is_rate_limited() is True

    def test_old_timestamps_purged(self):
        # Add timestamps that are "old" (> 60s ago)
        _call_timestamps.clear()
        old_time = time.monotonic() - 120
        for _ in range(30):
            _call_timestamps.append(old_time)
        # Should not be limited since old timestamps get purged
        assert _is_rate_limited() is False


class TestClientStateVerification:
    def test_no_secret_configured_passes(self):
        with patch("src.api.webhooks.settings") as mock_settings:
            mock_settings.webhook_client_state = ""
            assert _verify_client_state({}) is True

    def test_correct_secret_passes(self):
        with patch("src.api.webhooks.settings") as mock_settings:
            mock_settings.webhook_client_state = "my-secret-123"
            assert _verify_client_state({"clientState": "my-secret-123"}) is True

    def test_wrong_secret_fails(self):
        with patch("src.api.webhooks.settings") as mock_settings:
            mock_settings.webhook_client_state = "my-secret-123"
            assert _verify_client_state({"clientState": "wrong-secret"}) is False

    def test_missing_secret_fails(self):
        with patch("src.api.webhooks.settings") as mock_settings:
            mock_settings.webhook_client_state = "my-secret-123"
            assert _verify_client_state({}) is False
