"""Send recap email to Emmanuel."""
import asyncio
from src.services import outlook

SUBJECT = "[RECAP IA] Rapport systeme - 13 mars 2026"

BODY = """
<div style="font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; color: #333;">

<h2 style="color: #2C3E50; border-bottom: 2px solid #3498DB; padding-bottom: 8px;">Rapport IA Concierge &mdash; 13 mars 2026</h2>

<h3 style="color: #3498DB;">1. Performance globale</h3>
<table style="border-collapse: collapse; width: 100%; margin-bottom: 20px;">
    <tr style="background: #f8f9fa;">
        <td style="padding: 8px; border: 1px solid #ddd;"><strong>Emails re&ccedil;us</strong></td>
        <td style="padding: 8px; border: 1px solid #ddd;">8 entrants</td>
    </tr>
    <tr>
        <td style="padding: 8px; border: 1px solid #ddd;"><strong>R&eacute;ponses g&eacute;n&eacute;r&eacute;es</strong></td>
        <td style="padding: 8px; border: 1px solid #ddd;">7 brouillons cr&eacute;&eacute;s dans Outlook</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 8px; border: 1px solid #ddd;"><strong>Confiance moyenne</strong></td>
        <td style="padding: 8px; border: 1px solid #ddd;">0.87 / 1.0</td>
    </tr>
    <tr>
        <td style="padding: 8px; border: 1px solid #ddd;"><strong>Tokens consomm&eacute;s</strong></td>
        <td style="padding: 8px; border: 1px solid #ddd;">50 917 input + 2 516 output (~53k tokens)</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 8px; border: 1px solid #ddd;"><strong>Temps moyen / email</strong></td>
        <td style="padding: 8px; border: 1px solid #ddd;">11.9 secondes</td>
    </tr>
    <tr>
        <td style="padding: 8px; border: 1px solid #ddd;"><strong>Erreurs</strong></td>
        <td style="padding: 8px; border: 1px solid #ddd;">0</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 8px; border: 1px solid #ddd;"><strong>Escalades</strong></td>
        <td style="padding: 8px; border: 1px solid #ddd;">1 (meta-commentary d&eacute;tect&eacute; sur Voyages de R&ecirc;ve)</td>
    </tr>
</table>

<h3 style="color: #3498DB;">2. D&eacute;tail des emails trait&eacute;s</h3>
<table style="border-collapse: collapse; width: 100%; margin-bottom: 20px; font-size: 13px;">
    <tr style="background: #2C3E50; color: white;">
        <th style="padding: 8px; border: 1px solid #ddd;">#</th>
        <th style="padding: 8px; border: 1px solid #ddd;">Client</th>
        <th style="padding: 8px; border: 1px solid #ddd;">Sujet</th>
        <th style="padding: 8px; border: 1px solid #ddd;">Cat.</th>
        <th style="padding: 8px; border: 1px solid #ddd;">Conf.</th>
        <th style="padding: 8px; border: 1px solid #ddd;">Temps</th>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">1</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Jonathan Kron</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Groupe 4 familles, 7 chambres, 22-26 d&eacute;c</td>
        <td style="padding: 6px; border: 1px solid #ddd;">availability</td>
        <td style="padding: 6px; border: 1px solid #ddd;">0.89</td>
        <td style="padding: 6px; border: 1px solid #ddd;">13.5s</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 6px; border: 1px solid #ddd;">2</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Kelsey (Milk &amp; Honey Travels)</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Activit&eacute;s &amp; transferts s&eacute;jour Parrott</td>
        <td style="padding: 6px; border: 1px solid #ddd;">info_request</td>
        <td style="padding: 6px; border: 1px solid #ddd;">0.87</td>
        <td style="padding: 6px; border: 1px solid #ddd;">12.4s</td>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">3</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Susan McCormick</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Confirmation r&eacute;sa ref. 8708</td>
        <td style="padding: 6px; border: 1px solid #ddd;">booking</td>
        <td style="padding: 6px; border: 1px solid #ddd;">0.92</td>
        <td style="padding: 6px; border: 1px solid #ddd;">6.9s</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 6px; border: 1px solid #ddd;">4</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Michael Dias</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Agent de voyage, tarif + dispo avril</td>
        <td style="padding: 6px; border: 1px solid #ddd;">availability</td>
        <td style="padding: 6px; border: 1px solid #ddd;">0.87</td>
        <td style="padding: 6px; border: 1px solid #ddd;">17.4s</td>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">5</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Restaurant Karibuni</td>
        <td style="padding: 6px; border: 1px solid #ddd;">R&eacute;servation restaurant</td>
        <td style="padding: 6px; border: 1px solid #ddd;">restaurant</td>
        <td style="padding: 6px; border: 1px solid #ddd;">0.78</td>
        <td style="padding: 6px; border: 1px solid #ddd;">5.9s</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 6px; border: 1px solid #ddd;">6</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Felix Feygin</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Location voiture Escale Car Rental</td>
        <td style="padding: 6px; border: 1px solid #ddd;">transfer</td>
        <td style="padding: 6px; border: 1px solid #ddd;">0.85</td>
        <td style="padding: 6px; border: 1px solid #ddd;">10.4s</td>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">7</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Michael Dias (2e mail)</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Suivi tarifs agent de voyage</td>
        <td style="padding: 6px; border: 1px solid #ddd;">pricing</td>
        <td style="padding: 6px; border: 1px solid #ddd;">0.89</td>
        <td style="padding: 6px; border: 1px solid #ddd;">16.9s</td>
    </tr>
</table>

<h3 style="color: #3498DB;">3. Am&eacute;liorations d&eacute;ploy&eacute;es</h3>
<table style="border-collapse: collapse; width: 100%; margin-bottom: 20px; font-size: 13px;">
    <tr style="background: #27AE60; color: white;">
        <th style="padding: 8px; border: 1px solid #ddd;">Module</th>
        <th style="padding: 8px; border: 1px solid #ddd;">Am&eacute;lioration</th>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">Scoring confiance</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Signature Marion seule accept&eacute;e, p&eacute;nalit&eacute; lien r&eacute;sa supprim&eacute;e, formules corporate FR d&eacute;tect&eacute;es</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 6px; border: 1px solid #ddd;">D&eacute;tection groupes</td>
        <td style="padding: 6px; border: 1px solid #ddd;">D&eacute;tecte 4+ chambres/rooms + nombres &eacute;crits (quatre, five...)</td>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">Contre-propositions</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Nouvel outil : v&eacute;rifie dispo nuit par nuit (15 outils au total)</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 6px; border: 1px solid #ddd;">Cache base de donn&eacute;es</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Cache 5 min sur donn&eacute;es statiques &mdash; r&eacute;duit la latence</td>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">R&eacute;silience Outlook</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Retry auto avec backoff (1s, 2s, 4s) sur erreurs r&eacute;seau</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 6px; border: 1px solid #ddd;">S&eacute;curit&eacute;</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Max 10 emails/h par exp&eacute;diteur. Secrets retir&eacute;s du code.</td>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">Langues</td>
        <td style="padding: 6px; border: 1px solid #ddd;">D&eacute;tection du portugais ajout&eacute;e (7 langues au total)</td>
    </tr>
    <tr style="background: #f8f9fa;">
        <td style="padding: 6px; border: 1px solid #ddd;">Monitoring</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Endpoint /api/stats pour suivi temps r&eacute;el</td>
    </tr>
    <tr>
        <td style="padding: 6px; border: 1px solid #ddd;">Escalades</td>
        <td style="padding: 6px; border: 1px solid #ddd;">Notifications envoy&eacute;es &agrave; Emmanuel ET Marion</td>
    </tr>
</table>

<h3 style="color: #3498DB;">4. &Eacute;tat du syst&egrave;me</h3>
<ul style="line-height: 1.8;">
    <li><strong>Mode :</strong> BROUILLON (aucun email envoy&eacute; automatiquement)</li>
    <li><strong>Mod&egrave;le IA :</strong> Claude Sonnet 4.6</li>
    <li><strong>Outils :</strong> 15 disponibles</li>
    <li><strong>Polling :</strong> toutes les 60 secondes</li>
    <li><strong>Statut :</strong> en ligne, 0 erreur</li>
</ul>

<hr style="margin-top: 30px;">
<p style="font-size: 12px; color: #888;">Rapport g&eacute;n&eacute;r&eacute; automatiquement par le syst&egrave;me IA Concierge &mdash; Le Martin Boutique Hotel</p>
</div>
"""

async def main():
    await outlook.send_email(
        to="emmanuel@lemartinhotel.com",
        subject=SUBJECT,
        body_html=BODY,
    )
    print("Email envoye a emmanuel@lemartinhotel.com")

asyncio.run(main())
