"""Configuration — Pydantic Settings loaded from .env."""

from __future__ import annotations

from pathlib import Path
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


# .env lives in the parent project directory
_ENV_FILE = Path(__file__).resolve().parent.parent.parent / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── Azure / Outlook ──
    azure_client_id: str
    azure_tenant_id: str
    azure_client_secret: str
    azure_authority: str = "https://login.microsoftonline.com/common"
    azure_scopes: str = "https://graph.microsoft.com/.default"
    graph_api_base_url: str = "https://graph.microsoft.com/v1.0"
    email_address: str = "info@lemartinhotel.com"

    # ── Anthropic ──
    anthropic_api_key: str
    anthropic_model: str = "claude-sonnet-4-20250514"
    anthropic_max_tokens: int = 4096
    anthropic_temperature: float = 0.3

    # ── Thais PMS ──
    thais_api_url: str = "https://demo.thais-hotel.com"
    thais_api_user: str = ""
    thais_api_password: str = ""
    thais_user_agent: str = "VisionIA-LeMartin/1.0"
    thais_hotel_id: str = ""

    # ── Supabase ──
    supabase_url: str
    supabase_service_role_key: str = ""
    supabase_anon_key: str = ""

    # ── Hotel info ──
    hotel_name: str = "Le Martin Boutique Hotel"
    hotel_location: str = "Saint-Martin (Antilles françaises)"

    # ── Application behaviour ──
    app_mode: Literal["draft", "auto"] = "draft"
    poll_interval: int = 60
    default_language: str = "fr"
    supported_languages: str = "fr,en"
    email_signature_name: str = "Marion"
    email_signature_role: str = "Réception"
    max_emails_per_cycle: int = 10
    log_level: str = "info"
    response_delay_min: int = 300
    response_delay_max: int = 420

    # ── Escalation ──
    escalation_confidence_threshold: float = 0.7
    escalation_email: str = "emmanuel@lemartinhotel.com"

    # ── Notifications ──
    notify_email: str = "emmanuel@lemartinhotel.com"
    daily_summary_hour: int = 18
    daily_summary_timezone: str = "America/Guadeloupe"
    notify_webhook_url: str = ""

    # ── Environment ──
    environment: Literal["development", "staging", "production"] = "production"


settings = Settings()  # type: ignore[call-arg]
