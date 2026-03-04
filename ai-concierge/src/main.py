"""FastAPI application — entry point, lifespan, scheduler, polling loop."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from datetime import date
from pathlib import Path

import structlog
import uvicorn
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI

from src.api.health import router as health_router
from src.api.webhooks import router as webhooks_router
from src.config import settings
from src.services import outlook
from src.services.daily_summary import generate_and_send_summary
from src.services.email_processor import is_already_processed, process_email

# ---------------------------------------------------------------------------
# Structured logging — console + file
# ---------------------------------------------------------------------------

_LOG_FILE = Path(__file__).resolve().parent.parent / "concierge.log"

# File handler for persistent logs
file_handler = logging.FileHandler(str(_LOG_FILE), encoding="utf-8")
file_handler.setLevel(logging.DEBUG)

_LOG_LEVELS = {"debug": 10, "info": 20, "warning": 30, "error": 40}

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(
        _LOG_LEVELS.get(settings.log_level.lower(), 20)
    ),
)

# Also log to file via stdlib
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(message)s",
    handlers=[file_handler],
)

log = structlog.get_logger()

# ---------------------------------------------------------------------------
# Scheduler
# ---------------------------------------------------------------------------

scheduler = AsyncIOScheduler(timezone=settings.daily_summary_timezone)


async def _daily_summary_job():
    """Run daily summary at the configured hour."""
    try:
        await generate_and_send_summary(date.today())
    except Exception as exc:
        log.error("scheduler.daily_summary_failed", error=str(exc))


async def _polling_loop():
    """Continuously poll Outlook for unread emails."""
    log.info("polling.started", interval=settings.poll_interval, mode=settings.app_mode)
    while True:
        try:
            emails = await outlook.fetch_unread_emails(limit=settings.max_emails_per_cycle)
            new_emails = [e for e in emails if not is_already_processed(e.outlook_message_id)]
            if new_emails:
                log.info("polling.new_emails", total_unread=len(emails), new=len(new_emails))
                for email in new_emails:
                    try:
                        result = await process_email(email)
                        log.info("polling.processed", result=result)
                    except Exception as exc:
                        log.error("polling.process_error", email=email.from_email, error=str(exc))
            else:
                log.debug("polling.no_new_emails", unread=len(emails))
        except Exception as exc:
            log.error("polling.fetch_error", error=str(exc))

        await asyncio.sleep(settings.poll_interval)


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info(
        "startup",
        hotel=settings.hotel_name,
        mode=settings.app_mode,
        model=settings.anthropic_model,
        environment=settings.environment,
        log_file=str(_LOG_FILE),
    )

    # Schedule daily summary
    scheduler.add_job(
        _daily_summary_job,
        trigger="cron",
        hour=settings.daily_summary_hour,
        minute=0,
    )
    scheduler.start()

    # Start polling loop in background
    polling_task = asyncio.create_task(_polling_loop())

    yield

    # Shutdown
    polling_task.cancel()
    scheduler.shutdown(wait=False)
    log.info("shutdown")


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="IA Concierge — Le Martin Boutique Hotel",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(health_router)
app.include_router(webhooks_router)


if __name__ == "__main__":
    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.environment == "development",
    )
