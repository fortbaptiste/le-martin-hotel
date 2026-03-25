"""Test tool definitions and handler dispatch."""

import json
from datetime import date
from unittest.mock import AsyncMock, patch

import pytest

from src.tools.definitions import TOOLS
from src.tools.handlers import handle_tool_call


class TestToolDefinitions:
    """Verify all 14 tool schemas are correct."""

    def test_tool_count(self):
        assert len(TOOLS) == 15

    def test_all_tools_have_required_fields(self):
        for tool in TOOLS:
            assert "name" in tool, f"Tool missing name: {tool}"
            assert "description" in tool, f"Tool {tool['name']} missing description"
            assert "input_schema" in tool, f"Tool {tool['name']} missing input_schema"

    def test_tool_names_unique(self):
        names = [t["name"] for t in TOOLS]
        assert len(names) == len(set(names)), f"Duplicate tool names: {names}"

    def test_expected_tools_present(self):
        names = {t["name"] for t in TOOLS}
        expected = {
            "check_room_availability", "lookup_reservation", "get_room_details",
            "search_restaurants", "search_beaches", "search_activities",
            "get_hotel_services", "search_faq", "get_transport_schedules",
            "get_partner_info", "get_client_history", "get_email_template",
            "get_practical_info", "check_availability_range", "request_team_action",
        }
        assert expected == names

    def test_availability_requires_dates(self):
        avail_tool = next(t for t in TOOLS if t["name"] == "check_room_availability")
        assert "checkin" in avail_tool["input_schema"]["required"]
        assert "checkout" in avail_tool["input_schema"]["required"]

    def test_restaurant_description_mentions_tool_usage(self):
        rest_tool = next(t for t in TOOLS if t["name"] == "search_restaurants")
        desc = rest_tool["description"].lower()
        assert "must call" in desc or "must" in desc.lower()

    def test_no_internal_room_names_in_descriptions(self):
        """Internal names should not appear UNLESS it's in a 'never use' warning."""
        internal_names = ["marcelle", "sidonie", "théodore", "augustin", "raphaël"]
        for tool in TOOLS:
            desc_lower = tool["description"].lower()
            for name in internal_names:
                assert name not in desc_lower, (
                    f"Tool {tool['name']} description contains internal name '{name}'"
                )
        # 'marius' appears in get_room_details as a "never use" example — that's OK
        room_tool = next(t for t in TOOLS if t["name"] == "get_room_details")
        assert "never use internal room names" in room_tool["description"].lower()


class TestHandlerDispatch:
    """Test individual tool handlers with mocked backends."""

    @pytest.mark.asyncio
    async def test_unknown_tool_returns_error(self):
        result = await handle_tool_call("nonexistent_tool", {})
        data = json.loads(result)
        assert "error" in data

    @pytest.mark.asyncio
    async def test_availability_invalid_dates(self):
        result = await handle_tool_call("check_room_availability", {
            "checkin": "not-a-date", "checkout": "2026-03-20",
        })
        data = json.loads(result)
        assert "error" in data

    @pytest.mark.asyncio
    async def test_availability_checkin_after_checkout(self):
        result = await handle_tool_call("check_room_availability", {
            "checkin": "2026-03-20", "checkout": "2026-03-15",
        })
        data = json.loads(result)
        assert "error" in data
        assert "before" in data["error"].lower()

    @pytest.mark.asyncio
    async def test_lookup_reservation_no_params(self):
        result = await handle_tool_call("lookup_reservation", {})
        data = json.loads(result)
        assert "error" in data

    @pytest.mark.asyncio
    async def test_get_room_details_all(self, mock_supabase):
        result = await handle_tool_call("get_room_details", {})
        data = json.loads(result)
        assert isinstance(data, list)
        assert len(data) >= 1

    @pytest.mark.asyncio
    async def test_search_restaurants(self, mock_supabase):
        result = await handle_tool_call("search_restaurants", {"cuisine": "french"})
        data = json.loads(result)
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_search_beaches(self, mock_supabase):
        result = await handle_tool_call("search_beaches", {"side": "french"})
        data = json.loads(result)
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_search_activities(self, mock_supabase):
        """search_activities returns activity list."""
        mock_supabase["search_activities"] = AsyncMock(return_value=[
            {"id": "a1", "name_en": "Jet Ski", "category": "water_sport"},
        ])
        result = await handle_tool_call("search_activities", {"category": "water_sport"})
        data = json.loads(result)
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_hotel_services(self, mock_supabase):
        result = await handle_tool_call("get_hotel_services", {"category": "wellness"})
        data = json.loads(result)
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_search_faq(self, mock_supabase):
        result = await handle_tool_call("search_faq", {})
        data = json.loads(result)
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_practical_info(self, mock_supabase):
        result = await handle_tool_call("get_practical_info", {"category": "emergency"})
        data = json.loads(result)
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_client_history_not_found(self, mock_supabase):
        result = await handle_tool_call("get_client_history", {"client_email": "unknown@test.com"})
        data = json.loads(result)
        assert data["found"] is False

    @pytest.mark.asyncio
    async def test_get_client_history_found(self, mock_supabase):
        mock_supabase["get_client_by_email"].return_value = {
            "id": "c1", "email": "vip@test.com", "first_name": "Jean",
        }
        mock_supabase["get_client_reservations"].return_value = [
            {"id": "res1", "checkin_date": "2026-01-01"},
        ]
        result = await handle_tool_call("get_client_history", {"client_email": "vip@test.com"})
        data = json.loads(result)
        assert data["found"] is True
        assert "client" in data
        assert "reservations" in data
