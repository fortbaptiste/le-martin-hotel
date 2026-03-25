"""Test few-shot example selection."""

from src.prompts.few_shot import select_few_shot_examples, _keyword_matches, format_few_shot_messages


class TestKeywordMatching:
    """Word-start boundary prevents false positives while allowing prefix matches."""

    def test_exact_match(self):
        assert _keyword_matches("eat", "i want to eat dinner") is True

    def test_no_false_match_in_middle(self):
        assert _keyword_matches("eat", "the weather is nice") is False

    def test_prefix_match_activities(self):
        assert _keyword_matches("activit", "what activities are available") is True

    def test_prefix_match_snorkeling(self):
        assert _keyword_matches("snorkel", "we love snorkeling") is True

    def test_prefix_match_reservation(self):
        assert _keyword_matches("réserv", "je voudrais réserver") is True

    def test_no_false_hi(self):
        assert _keyword_matches("hi", "this is great") is False

    def test_hi_at_start(self):
        assert _keyword_matches("hi", "hi there!") is True

    def test_car_not_scare(self):
        assert _keyword_matches("car", "scare me") is False

    def test_car_rental(self):
        assert _keyword_matches("car", "car rental please") is True

    def test_book_matches_booking(self):
        assert _keyword_matches("book", "i want to book a room") is True


class TestExampleSelection:
    """Verify category matching and selection logic."""

    MOCK_EXAMPLES = [
        {"id": "e1", "category": "reservation_inquiry", "title": "Booking inquiry",
         "client_message": "Is there availability?", "marion_response": "Yes!",
         "language": "en"},
        {"id": "e2", "category": "concierge_restaurant", "title": "Restaurant reco",
         "client_message": "Best restaurant?", "marion_response": "Try Le Cottage!",
         "language": "en"},
        {"id": "e3", "category": "concierge_activity", "title": "Snorkeling",
         "client_message": "Where to snorkel?", "marion_response": "Pinel Island!",
         "language": "en"},
        {"id": "e4", "category": "special_occasion", "title": "Honeymoon",
         "client_message": "Planning honeymoon", "marion_response": "Congratulations!",
         "language": "en"},
        {"id": "e5", "category": "concierge_restaurant", "title": "Restaurant FR",
         "client_message": "Quel restaurant?", "marion_response": "Le Cottage!",
         "language": "fr"},
    ]

    def test_restaurant_email_selects_restaurant_example(self):
        examples = select_few_shot_examples(
            "Can you recommend a restaurant for dinner?",
            self.MOCK_EXAMPLES,
            language="en",
        )
        categories = [e.category for e in examples]
        assert "concierge_restaurant" in categories

    def test_activity_email_selects_activity_example(self):
        examples = select_few_shot_examples(
            "What activities are available? We love snorkeling and kayaking.",
            self.MOCK_EXAMPLES,
            language="en",
        )
        categories = [e.category for e in examples]
        assert "concierge_activity" in categories

    def test_availability_email(self):
        examples = select_few_shot_examples(
            "Is there availability for March 15 to 20? What is the price?",
            self.MOCK_EXAMPLES,
            language="en",
        )
        categories = [e.category for e in examples]
        assert "reservation_inquiry" in categories

    def test_honeymoon_email(self):
        examples = select_few_shot_examples(
            "We are celebrating our honeymoon anniversary!",
            self.MOCK_EXAMPLES,
            language="en",
        )
        categories = [e.category for e in examples]
        assert "special_occasion" in categories

    def test_max_examples_respected(self):
        examples = select_few_shot_examples(
            "restaurant dinner availability price snorkeling honeymoon",
            self.MOCK_EXAMPLES,
            language="en",
            max_examples=2,
        )
        assert len(examples) <= 2

    def test_empty_examples_returns_empty(self):
        examples = select_few_shot_examples("hello", [], language="en")
        assert len(examples) == 0


class TestFormatFewShot:
    def test_format_produces_user_assistant_pairs(self):
        from src.models.knowledge import EmailExample
        examples = [
            EmailExample(id="e1", category="test", title="T1",
                        client_message="Q", marion_response="A"),
        ]
        messages = format_few_shot_messages(examples)
        assert len(messages) == 2
        assert messages[0]["role"] == "user"
        assert messages[1]["role"] == "assistant"
        assert "Q" in messages[0]["content"]
        assert "A" in messages[1]["content"]
