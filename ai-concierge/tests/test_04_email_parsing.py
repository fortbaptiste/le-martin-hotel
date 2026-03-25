"""Test email parsing — HTML stripping, latest message extraction, skip logic."""

import pytest

from src.services.email_processor import (
    _parse_body,
    _extract_latest_message,
    _should_skip,
    _has_attachment_indicators,
    _extract_first_name,
    _extract_last_name,
    _text_to_html,
)
from tests.conftest import make_email


class TestParseBody:
    """HTML → clean text extraction."""

    def test_plain_text_passthrough(self):
        email = make_email(body_text="Hello world", body_html="")
        result = _parse_body(email)
        assert "Hello world" in result

    def test_html_stripped(self):
        email = make_email(
            body_html="<html><body><p>Bonjour</p><p>Comment allez-vous ?</p></body></html>"
        )
        result = _parse_body(email)
        assert "Bonjour" in result
        assert "Comment allez-vous" in result
        assert "<p>" not in result
        assert "<html>" not in result

    def test_script_tags_removed(self):
        email = make_email(
            body_html="<html><script>alert('xss')</script><p>Safe content</p></html>"
        )
        result = _parse_body(email)
        assert "alert" not in result
        assert "Safe content" in result

    def test_truncation_at_8000_chars(self):
        long_body = "x" * 10000
        email = make_email(body_text=long_body, body_html="")
        result = _parse_body(email)
        assert len(result) < 10000
        assert "tronqu\u00e9" in result

    def test_attachment_indicator_detected(self):
        email = make_email(
            body_html='<html><body>See attached. Content-Disposition: attachment; filename="doc.pdf"</body></html>'
        )
        result = _parse_body(email)
        assert "pi\u00e8ces jointes" in result

    def test_multiple_newlines_collapsed(self):
        email = make_email(body_text="Hello\n\n\n\n\n\nWorld", body_html="")
        result = _parse_body(email)
        assert "\n\n\n" not in result


class TestExtractLatestMessage:
    """Strip quoted replies, keep only the latest message."""

    def test_outlook_quoted_reply(self):
        email = make_email(body_html="""
            <html><body>
            <p>New message here</p>
            <div id="appendonsend">
            <p>Old quoted content</p>
            </div>
            </body></html>
        """)
        result = _extract_latest_message(email)
        assert "New message here" in result
        assert "Old quoted content" not in result

    def test_gmail_quoted_reply(self):
        email = make_email(body_html="""
            <html><body>
            <p>Latest reply</p>
            <div class="gmail_quote">
                <p>Previous message from hotel</p>
            </div>
            </body></html>
        """)
        result = _extract_latest_message(email)
        assert "Latest reply" in result
        assert "Previous message" not in result

    def test_text_based_reply_marker(self):
        email = make_email(body_text="""
Thanks for the info!

-- Original Message --
From: info@lemartinhotel.com
Sent: March 1, 2026
Previous content here
        """, body_html="")
        result = _extract_latest_message(email)
        assert "Thanks for the info" in result
        assert "Previous content" not in result

    def test_truncation_at_3000(self):
        long_msg = "x" * 5000
        email = make_email(body_text=long_msg, body_html="")
        result = _extract_latest_message(email)
        assert len(result) <= 3000

    def test_hr_separator_strips_thread(self):
        email = make_email(body_html="""
            <html><body>
            <p>New message</p>
            <hr>
            <p>Old thread</p>
            </body></html>
        """)
        result = _extract_latest_message(email)
        assert "New message" in result
        assert "Old thread" not in result


class TestShouldSkip:
    """Skip auto-replies, internal emails, suppliers."""

    def test_noreply_skipped(self):
        email = make_email(from_email="noreply@booking.com")
        assert _should_skip(email) is True

    def test_auto_reply_subject_skipped(self):
        email = make_email(subject="Automatic Reply: Out of office")
        assert _should_skip(email) is True

    def test_hotel_email_skipped(self):
        email = make_email(from_email="info@lemartinhotel.com")
        assert _should_skip(email) is True

    def test_internal_domain_skipped(self):
        email = make_email(from_email="marion@lemartinhotel.com")
        assert _should_skip(email) is True

    def test_supplier_email_skipped(self):
        email = make_email(from_email="instant.floral@yahoo.com")
        assert _should_skip(email) is True

    def test_supplier_domain_skipped(self):
        email = make_email(from_email="reports@hm2.tripadvisor.com")
        assert _should_skip(email) is True

    def test_real_guest_not_skipped(self):
        email = make_email(from_email="guest@gmail.com", subject="Room inquiry")
        assert _should_skip(email) is False

    def test_payline_notification_skipped(self):
        email = make_email(from_email="notification@payline.com")
        assert _should_skip(email) is True

    # ── Non-guest content: job, ads, press, real estate ──

    def test_job_application_skipped(self):
        email = make_email(body_text="Bonjour, je cherche du travail en cuisine")
        assert _should_skip(email) is True

    def test_job_english_skipped(self):
        email = make_email(subject="Job application - housekeeping", body_text="I am looking for a job")
        assert _should_skip(email) is True

    def test_cv_skipped(self):
        email = make_email(body_text="Veuillez trouver ci-joint mon CV et ma lettre de motivation")
        assert _should_skip(email) is True

    def test_commercial_proposition_skipped(self):
        email = make_email(subject="PROPOSITION - REAL ESTATE", body_text="Programme immobilier à Cul de Sac")
        assert _should_skip(email) is True

    def test_press_skipped(self):
        email = make_email(body_text="Je suis journaliste, je voudrais faire un partenariat.")
        assert _should_skip(email) is True

    def test_newsletter_skipped(self):
        email = make_email(body_text="Pour vous désabonner de cette newsletter, cliquez ici.")
        assert _should_skip(email) is True

    def test_partnership_skipped(self):
        email = make_email(body_text="We'd like to propose a partnership with your hotel.")
        assert _should_skip(email) is True

    def test_real_guest_with_questions_not_skipped(self):
        """Guest mentioning 'travail' in a non-job context should NOT be skipped."""
        email = make_email(body_text="Bonjour, à quelle heure est le check-in ? Merci !")
        assert _should_skip(email) is False


class TestHelpers:
    def test_extract_first_name(self):
        assert _extract_first_name("Jean Dupont") == "Jean"
        assert _extract_first_name("Marie") == "Marie"
        assert _extract_first_name(None) is None
        assert _extract_first_name("") is None

    def test_extract_last_name(self):
        assert _extract_last_name("Jean Dupont") == "Dupont"
        assert _extract_last_name("Marie") is None
        assert _extract_last_name("Jean Pierre Dupont") == "Pierre Dupont"

    def test_text_to_html(self):
        html = _text_to_html("Hello\n\nWorld")
        assert "<p>" in html
        assert "&" not in html or "&amp;" in html

    def test_text_to_html_escapes_xss(self):
        html = _text_to_html("<script>alert('xss')</script>")
        assert "<script>" not in html
        assert "&lt;script&gt;" in html

    def test_has_attachment_indicators(self):
        assert _has_attachment_indicators('Content-Disposition: attachment; filename="a.pdf"')
        assert not _has_attachment_indicators('<p>Normal email</p>')
