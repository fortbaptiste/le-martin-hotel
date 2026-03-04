"""Daily summary — aggregate stats and send to Emmanuel at 18h AST."""

from __future__ import annotations

from datetime import date

import structlog

from src.config import settings
from src.services import outlook, supabase_client as db

log = structlog.get_logger()


async def generate_and_send_summary(target_date: date | None = None) -> dict:
    """Build the daily summary, store it, and email it to the owner."""
    today = target_date or date.today()
    date_str = today.isoformat()

    # Aggregate stats
    stats = await db.get_messages_stats_for_date(date_str)
    escalation_count = await db.get_escalations_count_for_date(date_str)

    summary_text = _build_summary_text(today, stats, escalation_count)

    # Upsert into daily_summaries
    await db.upsert_daily_summary({
        "date": date_str,
        "emails_received": stats["emails_received"],
        "emails_replied": stats["emails_replied"],
        "emails_escalated": escalation_count,
        "avg_response_time_ms": stats["avg_response_time_ms"],
        "avg_confidence_score": stats["avg_confidence_score"],
        "total_tokens_used": stats["total_tokens_used"],
        "total_cost_eur": stats["total_cost_eur"],
        "summary_text": summary_text,
        "sent_to_owner": True,
    })

    # OBSERVATION MODE: log summary locally, do NOT send email to Emmanuel
    log.info("daily_summary.generated", date=date_str, summary=summary_text)
    return {
        "date": date_str,
        "emails_received": stats["emails_received"],
        "emails_replied": stats["emails_replied"],
        "escalated": escalation_count,
        "cost_eur": stats["total_cost_eur"],
    }


def _build_summary_text(d: date, stats: dict, escalations: int) -> str:
    return (
        f"Résumé IA du {d.strftime('%d/%m/%Y')}\n"
        f"Emails reçus : {stats['emails_received']}\n"
        f"Emails traités : {stats['emails_replied']}\n"
        f"Escalations : {escalations}\n"
        f"Confiance moyenne : {stats['avg_confidence_score'] or 'N/A'}\n"
        f"Temps de réponse moyen : {stats['avg_response_time_ms'] or 'N/A'} ms\n"
        f"Tokens utilisés : {stats['total_tokens_used']}\n"
        f"Coût total : {stats['total_cost_eur']:.4f} €"
    )


def _build_summary_html(d: date, stats: dict, escalations: int) -> str:
    avg_conf = f"{stats['avg_confidence_score']:.0%}" if stats["avg_confidence_score"] else "N/A"
    avg_time = f"{stats['avg_response_time_ms']} ms" if stats["avg_response_time_ms"] else "N/A"

    return f"""
    <h2>Résumé IA — {d.strftime('%d/%m/%Y')}</h2>
    <table style="border-collapse:collapse; font-family:sans-serif;">
        <tr><td style="padding:6px 12px; border:1px solid #ddd;"><strong>Emails reçus</strong></td>
            <td style="padding:6px 12px; border:1px solid #ddd;">{stats['emails_received']}</td></tr>
        <tr><td style="padding:6px 12px; border:1px solid #ddd;"><strong>Emails traités (IA)</strong></td>
            <td style="padding:6px 12px; border:1px solid #ddd;">{stats['emails_replied']}</td></tr>
        <tr><td style="padding:6px 12px; border:1px solid #ddd;"><strong>Escalations</strong></td>
            <td style="padding:6px 12px; border:1px solid #ddd;">{escalations}</td></tr>
        <tr><td style="padding:6px 12px; border:1px solid #ddd;"><strong>Confiance moyenne</strong></td>
            <td style="padding:6px 12px; border:1px solid #ddd;">{avg_conf}</td></tr>
        <tr><td style="padding:6px 12px; border:1px solid #ddd;"><strong>Temps de réponse moyen</strong></td>
            <td style="padding:6px 12px; border:1px solid #ddd;">{avg_time}</td></tr>
        <tr><td style="padding:6px 12px; border:1px solid #ddd;"><strong>Tokens utilisés</strong></td>
            <td style="padding:6px 12px; border:1px solid #ddd;">{stats['total_tokens_used']:,}</td></tr>
        <tr><td style="padding:6px 12px; border:1px solid #ddd;"><strong>Coût total</strong></td>
            <td style="padding:6px 12px; border:1px solid #ddd;">{stats['total_cost_eur']:.4f} €</td></tr>
    </table>
    <br>
    <p style="color:#888; font-size:12px;">
        Mode actuel : <strong>{settings.app_mode}</strong> |
        Généré automatiquement par le système IA concierge du {settings.hotel_name}
    </p>
    """
