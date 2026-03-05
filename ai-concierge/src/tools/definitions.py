"""12 tool schemas for Claude tool_use — the concierge knowledge toolkit."""

from __future__ import annotations

TOOLS: list[dict] = [
    # 1 — Room availability (Thais PMS)
    {
        "name": "check_room_availability",
        "description": (
            "Check real-time room availability and EXACT pricing from Thais PMS. "
            "You MUST call this tool before quoting any price. Never invent a price."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "checkin": {
                    "type": "string",
                    "description": "Check-in date (YYYY-MM-DD)",
                },
                "checkout": {
                    "type": "string",
                    "description": "Check-out date (YYYY-MM-DD)",
                },
                "room_type_id": {
                    "type": "string",
                    "description": "Optional Thais room type ID to filter",
                },
            },
            "required": ["checkin", "checkout"],
        },
    },
    # 2 — Room details (Supabase)
    {
        "name": "get_room_details",
        "description": (
            "Get detailed information about a specific room or all rooms: "
            "size, view, amenities, bed type, accessibility, design style, "
            "public_category_fr/en (the name to use with guests — NEVER use internal room names like 'Suite Marius'). "
            "Also includes bed_twinable (always false — beds are NOT separable), "
            "extra_bed_price (115€/night for extra single bed), "
            "and child_supplement (150€/night per child)."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "room_slug": {
                    "type": "string",
                    "description": "Room slug (e.g. 'rene', 'marius', 'marcelle', 'pierre', 'marthe', 'georgette', 'family-suite'). "
                                   "Omit to get all rooms.",
                },
            },
            "required": [],
        },
    },
    # 3 — Restaurants
    {
        "name": "search_restaurants",
        "description": (
            "Search the curated restaurant guide (66 restaurants). "
            "Filter by area, cuisine type, or partner status."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "area": {
                    "type": "string",
                    "description": "Area filter (e.g. 'Grand Case', 'Orient Bay', 'Marigot')",
                },
                "cuisine": {
                    "type": "string",
                    "description": "Cuisine type (e.g. 'french', 'creole', 'italian', 'seafood')",
                },
                "best_for": {
                    "type": "string",
                    "description": "Occasion (e.g. 'romantic', 'family', 'sunset', 'business')",
                },
            },
            "required": [],
        },
    },
    # 4 — Beaches
    {
        "name": "search_beaches",
        "description": "Search the beach guide (22 beaches). Filter by side (french/dutch).",
        "input_schema": {
            "type": "object",
            "properties": {
                "side": {
                    "type": "string",
                    "enum": ["french", "dutch"],
                    "description": "Island side filter",
                },
                "best_for": {
                    "type": "string",
                    "description": "Activity filter (e.g. 'snorkeling', 'family', 'quiet')",
                },
            },
            "required": [],
        },
    },
    # 5 — Activities
    {
        "name": "search_activities",
        "description": "Search activities and excursions (41 options). Filter by category.",
        "input_schema": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "enum": [
                        "water_sport", "boat_trip", "island_trip", "land_activity",
                        "wellness", "shopping", "nightlife", "cultural", "family",
                    ],
                    "description": "Activity category",
                },
            },
            "required": [],
        },
    },
    # 6 — Hotel services
    {
        "name": "get_hotel_services",
        "description": "Get hotel services with prices (36 services). Filter by category.",
        "input_schema": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "enum": [
                        "wellness", "transport", "dining", "activity",
                        "room_extra", "concierge", "event",
                    ],
                    "description": "Service category filter",
                },
            },
            "required": [],
        },
    },
    # 7 — FAQ
    {
        "name": "search_faq",
        "description": "Search frequently asked questions (15 FAQ entries). Filter by category.",
        "input_schema": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "description": "FAQ category (e.g. 'general', 'policy', 'dining', 'activity', 'transport', 'amenities')",
                },
            },
            "required": [],
        },
    },
    # 8 — Transport schedules
    {
        "name": "get_transport_schedules",
        "description": "Get ferry and shuttle schedules between islands.",
        "input_schema": {
            "type": "object",
            "properties": {
                "route": {
                    "type": "string",
                    "description": "Route filter (e.g. 'marigot_to_anguilla', 'sxm_to_sbh')",
                },
            },
            "required": [],
        },
    },
    # 9 — Partners
    {
        "name": "get_partner_info",
        "description": "Get information about trusted hotel partners (car rental, excursions, etc.).",
        "input_schema": {
            "type": "object",
            "properties": {
                "service_type": {
                    "type": "string",
                    "description": "Partner service type (e.g. 'car_rental', 'snorkeling', 'boat_tour', 'taxi')",
                },
            },
            "required": [],
        },
    },
    # 10 — Client history
    {
        "name": "get_client_history",
        "description": (
            "Get the guest's profile, preferences, past stays and reservation history. "
            "Use this to personalize the response."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "client_email": {
                    "type": "string",
                    "description": "Client email address",
                },
            },
            "required": ["client_email"],
        },
    },
    # 11 — Email templates
    {
        "name": "get_email_template",
        "description": (
            "Get pre-written email templates by Marion for specific situations. "
            "Use as inspiration for tone and structure."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "description": "Template category (e.g. 'restaurant_reco', 'car_rental', 'cancellation', 'welcome_board', 'pre_arrival')",
                },
                "language": {
                    "type": "string",
                    "enum": ["fr", "en"],
                    "description": "Language filter",
                },
            },
            "required": ["category"],
        },
    },
    # 12 — Practical info
    {
        "name": "get_practical_info",
        "description": (
            "Get practical information: emergencies, hospitals, airports, ATMs, "
            "currency, timezone, weather, tips."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "description": "Info category (e.g. 'emergency', 'health', 'airport', 'transport', 'shopping', 'bank', 'info')",
                },
            },
            "required": [],
        },
    },
]
