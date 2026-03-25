"""14 tool schemas for Claude tool_use — the concierge knowledge toolkit."""

from __future__ import annotations

TOOLS: list[dict] = [
    # 1 — Room availability (Thais PMS)
    {
        "name": "check_room_availability",
        "description": (
            "Check real-time room availability and EXACT pricing from Thais PMS. "
            "Returns availability for each room type along with nightly prices, totals, "
            "and rooms_left (number of rooms still available for that type — important for groups). "
            "Two rate plans returned: Best Flexible Rate and Advance Purchase Rate (-10%, non-refundable). "
            "You MUST call this tool before quoting any price. Never invent a price. "
            "All dates MUST be in the future (2026 or later). Never use past dates. "
            "IMPORTANT for stay extensions: when a guest wants to extend an existing booking, "
            "set checkin to their CURRENT checkout date and checkout to their DESIRED new checkout date. "
            "Do NOT check the full date range including already-booked nights — the guest's own booking "
            "will make those nights appear unavailable."
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
    # 1b — Lookup existing reservation (Thais PMS)
    {
        "name": "lookup_reservation",
        "description": (
            "Look up a guest's EXISTING reservation in Thais PMS by name or email. "
            "You must provide at least guest_email OR guest_name. "
            "Returns booking details: dates, room type, number of adults, number of children, status. "
            "You MUST call this tool BEFORE proposing changes when a guest mentions an existing booking. "
            "CRITICAL: Compare what Thais shows (e.g. '2 adults, 0 children') with what the guest claims "
            "(e.g. '2 adults + 2 children'). If there is ANY discrepancy, DO NOT propose solutions — "
            "say you are checking the reservation and escalate to the team."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "guest_email": {
                    "type": "string",
                    "description": "Guest email address to search",
                },
                "guest_name": {
                    "type": "string",
                    "description": "Guest last name to search (use if email not available)",
                },
            },
            "required": [],
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
                    "description": (
                        "Use room_slug from previous get_room_details results, "
                        "or omit to get all rooms."
                    ),
                },
            },
            "required": [],
        },
    },
    # 3 — Restaurants
    {
        "name": "search_restaurants",
        "description": (
            "Search our curated restaurant guide. "
            "Filter by area, cuisine type, or occasion (best_for). "
            "You MUST call this tool before recommending any restaurant. Never recommend a restaurant from memory. "
            "If this tool returns no results or few results, do NOT invent restaurant names. "
            "Only recommend restaurants returned by this tool. "
            "IMPORTANT: NO restaurant is walkable from the hotel (Cul de Sac). "
            "All restaurants require a car (5-25 min drive). Always use access_note and driving_time_min, "
            "NEVER say 'X minutes walk'."
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
        "description": "Search our curated beach guide. Filter by side (french/dutch) or activity.",
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
    # 5 — Hotel services
    {
        "name": "get_hotel_services",
        "description": (
            "Get hotel services with exact prices. Use this tool for: "
            "extra bed price (room_extra), child supplement (room_extra), "
            "airport transfers (transport), breakfast (dining), "
            "massage/yoga (wellness), kayak/paddle (activity), "
            "laundry (concierge), baby-sitting (concierge), "
            "private events (event). "
            "You MUST call this tool before quoting any service price."
        ),
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
    # 6 — Activities & excursions
    {
        "name": "search_activities",
        "description": (
            "Search activities and excursions available on Saint-Martin. "
            "Includes water sports, boat trips, island excursions, land activities, "
            "wellness, shopping, nightlife, cultural visits, and family activities. "
            "Returns operator name, location, prices, duration, and booking requirements. "
            "You MUST call this tool before recommending any activity or excursion."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "enum": [
                        "water_sport", "boat_trip", "island_trip",
                        "land_activity", "wellness", "shopping",
                        "nightlife", "cultural", "family",
                    ],
                    "description": "Activity category filter",
                },
            },
            "required": [],
        },
    },
    # 7 — FAQ
    {
        "name": "search_faq",
        "description": "Search frequently asked questions. Filter by category.",
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
        "description": "Get INTERNAL information about hotel partners (car rental, boat tours, gym, etc.). "
            "CRITICAL: Partner names are CONFIDENTIAL — NEVER include them in the client response. "
            "The hotel loses its commission if guests contact partners directly. "
            "In your reply to the guest, use generic terms: 'our boat partner', 'a nearby gym', "
            "'our car rental partner'. Use partner names ONLY in request_team_action calls for internal team follow-up. "
            "DO NOT invent capabilities, destinations, or travel times not explicitly stated in the partner data.",
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
    # 13 — Check availability range (night-by-night)
    {
        "name": "check_availability_range",
        "description": (
            "Check room availability night-by-night over a date range. "
            "Returns a table showing which nights have availability, at what price, and how many rooms left. "
            "Use this when the hotel is full on the guest's exact dates and you need to find partial availability "
            "or nearby dates for a counter-proposal. Maximum 14 nights. "
            "This is optimized — it makes a single API call for the full range. "
            "All dates MUST be in the future (2026 or later)."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "start_date": {
                    "type": "string",
                    "description": "Start of the range to check (YYYY-MM-DD). Can be 1-2 days before the guest's requested dates.",
                },
                "end_date": {
                    "type": "string",
                    "description": "End of the range to check (YYYY-MM-DD). Can be 1-2 days after the guest's requested dates.",
                },
            },
            "required": ["start_date", "end_date"],
        },
    },
    # 14 — Request team action
    {
        "name": "request_team_action",
        "description": (
            "Request an action from the hotel team (Emmanuel/Marion). "
            "Use this when you promise the guest that someone will contact them, "
            "introduce them to a partner, or when an action requires a human "
            "(e.g. 'Contact the car rental partner to arrange a vehicle for the guest', "
            "'I'll ask the team to check on this'). "
            "The team will receive a notification with your request. "
            "You MUST call this tool whenever your response implies a follow-up action by the team."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "action": {
                    "type": "string",
                    "description": "What needs to be done (e.g. 'Contact Escale Car Rental to arrange a car for the guest')",
                },
                "partner_name": {
                    "type": "string",
                    "description": "Name of the partner to contact, if applicable",
                },
                "guest_name": {
                    "type": "string",
                    "description": "Guest name for context",
                },
                "urgency": {
                    "type": "string",
                    "enum": ["normal", "urgent"],
                    "description": "Urgency level (default: normal)",
                },
            },
            "required": ["action"],
        },
    },
]
