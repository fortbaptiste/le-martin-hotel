"""Test pre/post escalation detection — the safety net."""

import pytest

from src.services.escalation import check_pre_escalation, check_post_escalation


class TestPreEscalation:
    """Pre-AI escalation: patterns detected BEFORE generating a response."""

    # ── Should escalate ──

    def test_complaint_french(self):
        r = check_pre_escalation("Je suis tr\u00e8s d\u00e9\u00e7u de mon s\u00e9jour, c'est inacceptable.")
        assert r is not None
        assert r.reason == "complaint"

    def test_complaint_english(self):
        r = check_pre_escalation("This is unacceptable, I want to complain about the service.")
        assert r is not None
        assert r.reason == "complaint"

    def test_refund_request(self):
        r = check_pre_escalation("Je demande un remboursement imm\u00e9diat.")
        assert r is not None
        assert r.reason == "complaint"

    def test_cancel_reservation(self):
        r = check_pre_escalation("Je voudrais annuler ma r\u00e9servation du 15 mars.")
        assert r is not None
        assert r.reason == "booking_modification"

    def test_cancel_booking_english(self):
        r = check_pre_escalation("I need to cancel my reservation please.")
        assert r is not None
        assert r.reason == "booking_modification"

    def test_modify_reservation(self):
        r = check_pre_escalation("Je souhaite modifier ma r\u00e9servation, changer les dates.")
        assert r is not None
        assert r.reason == "booking_modification"

    def test_change_booking_english(self):
        r = check_pre_escalation("Can I change my booking dates?")
        assert r is not None
        assert r.reason == "booking_modification"

    def test_payment_issue(self):
        r = check_pre_escalation("Le lien cassé, impossible de finaliser le payment failed.")
        assert r is not None
        assert r.reason == "payment_issue"

    def test_overcharged(self):
        r = check_pre_escalation("I was overcharged on my credit card!")
        assert r is not None
        assert r.reason == "payment_issue"

    def test_group_5_plus(self):
        r = check_pre_escalation("Nous sommes 8 personnes, avez-vous la place ?")
        assert r is not None
        assert r.reason == "group_request"

    def test_group_english(self):
        r = check_pre_escalation("We are a group of 12 guests visiting next week.")
        assert r is not None
        # 12 guests + "group" triggers either group_request or privatization
        assert r.reason in ("group_request", "privatization")

    def test_privatization(self):
        r = check_pre_escalation("Peut-on privatiser tout l'h\u00f4tel pour un mariage ?")
        assert r is not None
        assert r.reason == "privatization"

    def test_wedding_hotel(self):
        r = check_pre_escalation("We are looking for a wedding venue at your hotel.")
        assert r is not None
        assert r.reason == "privatization"

    def test_out_of_scope_press(self):
        # Press/job/ads are now SKIPPED (not escalated) — see test_04 TestShouldSkip
        r = check_pre_escalation("Je suis journaliste, je voudrais faire un partenariat.")
        assert r is None  # Handled by skip filter, not escalation

    def test_out_of_scope_job(self):
        r = check_pre_escalation("I saw a job posting, I'd like to send my application.")
        assert r is None  # Handled by skip filter, not escalation

    # ── Should NOT escalate (negation / false positives) ──

    def test_negated_french_complaint(self):
        r = check_pre_escalation("Je ne suis pas d\u00e9\u00e7u du tout, tout \u00e9tait parfait !")
        assert r is None, f"Should not escalate negated complaint, got: {r.reason if r else None}"

    def test_negated_english_complaint(self):
        r = check_pre_escalation("I am not disappointed at all, everything was wonderful.")
        assert r is None

    def test_negated_cancel(self):
        r = check_pre_escalation("Je ne veux pas annuler ma r\u00e9servation, juste poser une question.")
        assert r is None

    def test_simple_question(self):
        r = check_pre_escalation("What time is check-in? Do you have a pool?")
        assert r is None

    def test_restaurant_question(self):
        r = check_pre_escalation("Could you recommend a good restaurant for dinner?")
        assert r is None

    def test_availability_question(self):
        r = check_pre_escalation("Is there availability for March 15 to 20?")
        assert r is None

    def test_honeymoon_no_escalation(self):
        r = check_pre_escalation("We are on our honeymoon, any recommendations?")
        assert r is None

    def test_cancel_flight_no_escalation(self):
        """'cancel my flight' should not trigger — no booking context."""
        r = check_pre_escalation("I need to cancel my flight, will that affect check-in?")
        assert r is None

    def test_4_people_no_escalation(self):
        """Group < 5 should not trigger."""
        r = check_pre_escalation("Nous sommes 4 personnes.")
        assert r is None

    # ── Subject line detection ──

    def test_escalation_from_subject(self):
        r = check_pre_escalation("Merci pour les infos", "R\u00e9clamation urgente")
        assert r is not None
        assert r.reason == "complaint"

    # ── Multilingual ──

    def test_spanish_complaint(self):
        r = check_pre_escalation("Quiero hacer una queja formal.")
        assert r is not None

    def test_german_refund(self):
        r = check_pre_escalation("Ich m\u00f6chte eine Erstattung bitte.")
        assert r is not None


class TestPostEscalation:
    """Post-AI escalation: confidence too low or AI flags escalation."""

    def test_low_confidence_triggers(self):
        r = check_post_escalation("Some response text", 0.5, threshold=0.7)
        assert r is not None
        assert r.reason == "low_confidence"

    def test_high_confidence_passes(self):
        r = check_post_escalation("Some response text", 0.85, threshold=0.7)
        assert r is None

    def test_ai_flags_escalation_to_emmanuel(self):
        r = check_post_escalation(
            "Je recommande d'escalader ce cas \u00e0 Emmanuel pour traitement.",
            0.9,
        )
        assert r is not None

    def test_rock_climbing_no_escalation(self):
        """'escalade' as in rock climbing should NOT trigger."""
        r = check_post_escalation(
            "L'escalade est une activit\u00e9 populaire sur l'\u00eele.",
            0.9,
        )
        assert r is None

    # ── Partner name detection (commission protection) ──

    def test_partner_scoobi_too_detected(self):
        """Partner name 'Scoobi Too' must be caught — commission risk."""
        r = check_post_escalation(
            "I recommend Scoobi Too for a boat trip. Marion & Emmanuel", 0.85,
        )
        assert r is not None
        assert "partenaire" in r.details.lower() or "commission" in r.details.lower()

    def test_partner_escale_detected(self):
        """Partner name 'Escale Car Rental' must be caught."""
        r = check_post_escalation(
            "I will put you in touch with Escale Car Rental. Marion", 0.85,
        )
        assert r is not None

    def test_partner_hopfit_detected(self):
        """Partner name 'Hopfit' must be caught."""
        r = check_post_escalation(
            "The gym at Hopfit costs 15 EUR. Marion & Emmanuel", 0.85,
        )
        assert r is not None

    def test_generic_partner_reference_ok(self):
        """Generic references ('our boat partner') should NOT trigger."""
        r = check_post_escalation(
            "I am reaching out to our boat partner for pricing. Marion & Emmanuel",
            0.85,
        )
        assert r is None

    def test_generic_gym_reference_ok(self):
        """Generic gym reference should NOT trigger."""
        r = check_post_escalation(
            "There is a well-equipped gym about 5 minutes by car. Day pass is 15 EUR. Marion & Emmanuel",
            0.85,
        )
        assert r is None
