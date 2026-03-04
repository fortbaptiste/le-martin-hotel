"""Health check endpoint."""

from __future__ import annotations

from fastapi import APIRouter

from src.config import settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "hotel": settings.hotel_name,
        "mode": settings.app_mode,
        "model": settings.anthropic_model,
        "environment": settings.environment,
    }
