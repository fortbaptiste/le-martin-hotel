"""
50 scénarios de test — appel direct au moteur IA sans Outlook.
Usage: python -m tests.test_scenarios [--scenario N] [--category CAT]
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
import time
from dataclasses import dataclass

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

SCENARIOS: list[dict] = [
    # ═══════════════════════════════════════════════════
    #  DISPONIBILITÉ & PRIX (1-8)
    # ═══════════════════════════════════════════════════
    {
        "id": 1,
        "category": "availability",
        "name": "Dispo dates précises",
        "from_name": "Sophie Martin",
        "from_email": "sophie.martin@gmail.com",
        "subject": "Disponibilités juillet",
        "body": "Bonjour,\n\nNous souhaiterions savoir si vous avez des disponibilités du 15 au 22 juillet 2026 pour 2 adultes.\n\nMerci,\nSophie",
        "language": "fr",
        "expect_tools": ["check_room_availability"],
        "expect_short": True,
    },
    {
        "id": 2,
        "category": "availability",
        "name": "Dispo sans dates",
        "from_name": "John Smith",
        "from_email": "john.smith@outlook.com",
        "subject": "Room availability",
        "body": "Hi,\n\nWhat are your room rates? We're thinking about visiting sometime in April.\n\nThanks,\nJohn",
        "language": "en",
        "expect_tools": [],
        "expect_short": True,
    },
    {
        "id": 3,
        "category": "availability",
        "name": "Dispo chambre spécifique",
        "from_name": "Marie Dupont",
        "from_email": "marie.dupont@yahoo.fr",
        "subject": "Suite vue mer",
        "body": "Bonjour Marion,\n\nEst-ce que la suite avec vue mer est disponible du 1er au 8 mai 2026 ?\n\nCordialement,\nMarie",
        "language": "fr",
        "expect_tools": ["check_room_availability"],
        "expect_no_internal_names": True,
    },
    {
        "id": 4,
        "category": "pricing",
        "name": "Demande de prix uniquement",
        "from_name": "David Brown",
        "from_email": "david.brown@gmail.com",
        "subject": "Pricing inquiry",
        "body": "Hello,\n\nCould you let me know your nightly rates for a sea view suite for 2 adults from June 10 to June 15?\n\nDavid",
        "language": "en",
        "expect_tools": ["check_room_availability"],
    },
    {
        "id": 5,
        "category": "availability",
        "name": "Haute saison complet",
        "from_name": "Pierre Leroy",
        "from_email": "pierre.leroy@free.fr",
        "subject": "Noël à Saint-Martin",
        "body": "Bonjour,\n\nAvez-vous encore de la place pour les fêtes de Noël, du 22 décembre 2026 au 2 janvier 2027 ?\n\nMerci,\nPierre",
        "language": "fr",
        "expect_tools": ["check_room_availability"],
    },
    {
        "id": 6,
        "category": "availability",
        "name": "Fermeture annuelle",
        "from_name": "Lisa Wong",
        "from_email": "lisa.wong@gmail.com",
        "subject": "September stay",
        "body": "Hi there,\n\nWe'd love to visit from September 1 to September 10. Do you have availability?\n\nLisa",
        "language": "en",
        "expect_tools": [],
    },
    {
        "id": 7,
        "category": "pricing",
        "name": "Demande réduction fidélité",
        "from_name": "Thomas Müller",
        "from_email": "thomas.muller@web.de",
        "subject": "Returning guest discount?",
        "body": "Dear Le Martin team,\n\nWe stayed with you last year and loved it. Do you offer any returning guest discount for a week in March?\n\nBest,\nThomas",
        "language": "en",
        "expect_no_discount": True,
    },
    {
        "id": 8,
        "category": "availability",
        "name": "Dates flexibles",
        "from_name": "Camille Roux",
        "from_email": "camille.roux@hotmail.fr",
        "subject": "Séjour flexible",
        "body": "Bonjour,\n\nNous sommes flexibles sur les dates, entre mi-mars et fin avril. Quelle serait la période la moins chère pour 4 nuits ?\n\nMerci,\nCamille",
        "language": "fr",
    },

    # ═══════════════════════════════════════════════════
    #  CHAMBRES & LITS (9-14)
    # ═══════════════════════════════════════════════════
    {
        "id": 9,
        "category": "rooms",
        "name": "Demande lits séparés (twin)",
        "from_name": "Anna Johnson",
        "from_email": "anna.johnson@gmail.com",
        "subject": "Twin beds request",
        "body": "Hi,\n\nDo you have rooms with twin beds? My sister and I are traveling together and would prefer separate beds.\n\nAnna",
        "language": "en",
        "expect_tools": ["get_room_details"],
        "expect_no_twin": True,
    },
    {
        "id": 10,
        "category": "rooms",
        "name": "Chambre PMR",
        "from_name": "Jacques Bernard",
        "from_email": "jacques.bernard@orange.fr",
        "subject": "Accessibilité",
        "body": "Bonjour,\n\nMon épouse est en fauteuil roulant. Avez-vous une chambre accessible PMR ?\n\nCordialement,\nJacques",
        "language": "fr",
        "expect_tools": ["get_room_details"],
    },
    {
        "id": 11,
        "category": "rooms",
        "name": "Détails chambre",
        "from_name": "Emma Davis",
        "from_email": "emma.davis@yahoo.com",
        "subject": "Room amenities",
        "body": "Hello,\n\nCan you tell me what amenities are included in your sea view suites? Is there a minibar? A coffee machine?\n\nThanks,\nEmma",
        "language": "en",
        "expect_tools": ["get_room_details"],
    },
    {
        "id": 12,
        "category": "rooms",
        "name": "Minibar = frigo ?",
        "from_name": "Roberto Sanchez",
        "from_email": "roberto.s@gmail.com",
        "subject": "Fridge in room",
        "body": "Hi,\n\nIs there a fridge in the room where we can store baby food and milk?\n\nRoberto",
        "language": "en",
    },
    {
        "id": 13,
        "category": "rooms",
        "name": "Lit d'appoint enfant",
        "from_name": "Nathalie Petit",
        "from_email": "nathalie.petit@gmail.com",
        "subject": "Lit supplémentaire pour enfant",
        "body": "Bonjour,\n\nNous venons avec notre fille de 8 ans. Est-il possible d'ajouter un lit dans la chambre ? Quel est le tarif ?\n\nNathalie",
        "language": "fr",
    },
    {
        "id": 14,
        "category": "rooms",
        "name": "Différence entre chambres",
        "from_name": "Sarah Taylor",
        "from_email": "sarah.taylor@gmail.com",
        "subject": "Room categories",
        "body": "Hi,\n\nWhat's the difference between the Privilege Room and the Deluxe Sea View Suite? We're trying to decide.\n\nSarah",
        "language": "en",
        "expect_tools": ["get_room_details"],
        "expect_no_internal_names": True,
    },

    # ═══════════════════════════════════════════════════
    #  RESTAURANTS (15-19)
    # ═══════════════════════════════════════════════════
    {
        "id": 15,
        "category": "restaurant",
        "name": "Resto romantique",
        "from_name": "Marc Duval",
        "from_email": "marc.duval@gmail.com",
        "subject": "Restaurant recommendation",
        "body": "Bonjour Marion,\n\nPouvez-vous nous recommander un bon restaurant pour un dîner romantique pendant notre séjour ?\n\nMarc",
        "language": "fr",
        "expect_tools": ["search_restaurants"],
        "expect_no_walkable": True,
    },
    {
        "id": 16,
        "category": "restaurant",
        "name": "Resto à pied ?",
        "from_name": "Claire Adams",
        "from_email": "claire.adams@hotmail.com",
        "subject": "Walking distance restaurants",
        "body": "Hi,\n\nAre there any good restaurants within walking distance from the hotel?\n\nClaire",
        "language": "en",
        "expect_tools": ["search_restaurants"],
        "expect_no_walkable": True,
    },
    {
        "id": 17,
        "category": "restaurant",
        "name": "Resto poisson/fruits de mer",
        "from_name": "Hans Weber",
        "from_email": "hans.weber@gmx.de",
        "subject": "Seafood restaurant",
        "body": "Hello,\n\nWe love seafood. Can you recommend the best seafood restaurant on the island?\n\nHans",
        "language": "en",
        "expect_tools": ["search_restaurants"],
    },
    {
        "id": 18,
        "category": "restaurant",
        "name": "Resto famille avec enfants",
        "from_name": "Julie Moreau",
        "from_email": "julie.moreau@yahoo.fr",
        "subject": "Restaurant enfants",
        "body": "Bonjour,\n\nNous venons avec 2 enfants (5 et 8 ans). Quel restaurant nous conseillez-vous ?\n\nJulie",
        "language": "fr",
        "expect_tools": ["search_restaurants"],
    },
    {
        "id": 19,
        "category": "restaurant",
        "name": "Livraison repas hôtel",
        "from_name": "Alex Chen",
        "from_email": "alex.chen@gmail.com",
        "subject": "Food delivery",
        "body": "Hi,\n\nIs it possible to order food delivery to the hotel in the evening? We might be too tired to go out some nights.\n\nAlex",
        "language": "en",
    },

    # ═══════════════════════════════════════════════════
    #  ACTIVITÉS & PLAGES (20-25)
    # ═══════════════════════════════════════════════════
    {
        "id": 20,
        "category": "activity",
        "name": "Île Pinel",
        "from_name": "Laura Martin",
        "from_email": "laura.martin@gmail.com",
        "subject": "Pinel Island",
        "body": "Hi Marion,\n\nWe heard about Pinel Island. How do we get there from the hotel? Is it walkable?\n\nLaura",
        "language": "en",
        "expect_dock_rules": True,
    },
    {
        "id": 21,
        "category": "activity",
        "name": "Snorkeling",
        "from_name": "Philippe Blanc",
        "from_email": "philippe.blanc@free.fr",
        "subject": "Snorkeling spots",
        "body": "Bonjour,\n\nQuels sont les meilleurs spots de snorkeling près de l'hôtel ? L'équipement est-il fourni ?\n\nPhilippe",
        "language": "fr",
        "expect_tools": ["search_activities", "search_beaches"],
    },
    {
        "id": 22,
        "category": "activity",
        "name": "Excursion bateau",
        "from_name": "Michael Lee",
        "from_email": "michael.lee@outlook.com",
        "subject": "Boat trip",
        "body": "Hello,\n\nAre there any boat trips or catamaran excursions you'd recommend? We'd love a full day on the water.\n\nMichael",
        "language": "en",
        "expect_tools": ["search_activities"],
    },
    {
        "id": 23,
        "category": "activity",
        "name": "Plages calmes",
        "from_name": "Isabelle Renard",
        "from_email": "isabelle.renard@gmail.com",
        "subject": "Plages tranquilles",
        "body": "Bonjour,\n\nNous cherchons une plage calme, pas trop de monde, pour nous relaxer. Que conseillez-vous ?\n\nIsabelle",
        "language": "fr",
        "expect_tools": ["search_beaches"],
    },
    {
        "id": 24,
        "category": "activity",
        "name": "Kayak & paddle",
        "from_name": "Tom Wilson",
        "from_email": "tom.wilson@gmail.com",
        "subject": "Water sports at the hotel",
        "body": "Hi,\n\nDo you have kayaks or paddleboards available? Are they free for guests?\n\nTom",
        "language": "en",
        "expect_tools": ["get_hotel_services"],
    },
    {
        "id": 25,
        "category": "activity",
        "name": "Activités enfants",
        "from_name": "Carla Rossi",
        "from_email": "carla.rossi@libero.it",
        "subject": "Activities for kids",
        "body": "Hello,\n\nWe're traveling with our 2 children (ages 6 and 10). What activities would you suggest for them on the island?\n\nCarla",
        "language": "en",
        "expect_tools": ["search_activities"],
    },

    # ═══════════════════════════════════════════════════
    #  TRANSPORT (26-31)
    # ═══════════════════════════════════════════════════
    {
        "id": 26,
        "category": "transport",
        "name": "Transfert aéroport SXM",
        "from_name": "François Morel",
        "from_email": "francois.morel@gmail.com",
        "subject": "Transfert aéroport",
        "body": "Bonjour,\n\nNotre vol arrive à Princess Juliana à 14h. Proposez-vous un transfert depuis l'aéroport ? Combien de temps faut-il ?\n\nFrançois",
        "language": "fr",
        "expect_airport_1h": True,
    },
    {
        "id": 27,
        "category": "transport",
        "name": "Location voiture",
        "from_name": "Lily Zeltser",
        "from_email": "lzeltser@milbank.com",
        "subject": "Car rental",
        "body": "Hi,\n\nIs it possible to rent a car to be available at the hotel upon our arrival?\n\nLily",
        "language": "en",
        "expect_tools": ["get_partner_info", "request_team_action"],
    },
    {
        "id": 28,
        "category": "transport",
        "name": "Taxi / Uber",
        "from_name": "Elena Volkov",
        "from_email": "elena.volkov@mail.ru",
        "subject": "Taxi service",
        "body": "Hello,\n\nIs Uber available on the island? How do we get around?\n\nElena",
        "language": "en",
    },
    {
        "id": 29,
        "category": "transport",
        "name": "Ferry Saint-Barth",
        "from_name": "Olivier Faure",
        "from_email": "olivier.faure@gmail.com",
        "subject": "Excursion Saint-Barth",
        "body": "Bonjour,\n\nNous aimerions passer une journée à Saint-Barth. Comment s'y rendre depuis Saint-Martin ?\n\nOlivier",
        "language": "fr",
        "expect_tools": ["get_transport_schedules"],
    },
    {
        "id": 30,
        "category": "transport",
        "name": "Aéroport Grand Case",
        "from_name": "Paul Mercier",
        "from_email": "paul.mercier@free.fr",
        "subject": "Aéroport Grand Case",
        "body": "Bonjour,\n\nNous arrivons par Grand Case (vol inter-îles). C'est loin de l'hôtel ?\n\nPaul",
        "language": "fr",
        "expect_airport_gc_10min": True,
    },
    {
        "id": 31,
        "category": "transport",
        "name": "Voiture nécessaire ?",
        "from_name": "Karen White",
        "from_email": "karen.white@yahoo.com",
        "subject": "Do we need a car?",
        "body": "Hi,\n\nIs it necessary to rent a car during our stay, or can we manage with taxis?\n\nKaren",
        "language": "en",
    },

    # ═══════════════════════════════════════════════════
    #  OCCASIONS SPÉCIALES (32-35)
    # ═══════════════════════════════════════════════════
    {
        "id": 32,
        "category": "honeymoon",
        "name": "Lune de miel",
        "from_name": "Julie & Thomas Berger",
        "from_email": "julie.berger@gmail.com",
        "subject": "Honeymoon trip",
        "body": "Bonjour,\n\nNous venons de nous marier et nous cherchons un endroit paradisiaque pour notre lune de miel du 20 au 27 avril. Que proposez-vous ?\n\nJulie & Thomas",
        "language": "fr",
        "expect_tools": ["check_room_availability", "get_hotel_services"],
    },
    {
        "id": 33,
        "category": "honeymoon",
        "name": "Anniversaire surprise",
        "from_name": "James Clark",
        "from_email": "james.clark@gmail.com",
        "subject": "Anniversary surprise",
        "body": "Hi,\n\nIt's our 10th anniversary and I'd like to surprise my wife. Can you arrange champagne and flowers in the room on arrival?\n\nJames",
        "language": "en",
        "expect_tools": ["get_hotel_services"],
    },
    {
        "id": 34,
        "category": "family",
        "name": "Famille 2 adultes + 2 enfants",
        "from_name": "Stéphanie Laurent",
        "from_email": "stephanie.laurent@gmail.com",
        "subject": "Séjour en famille",
        "body": "Bonjour,\n\nNous sommes 2 adultes et 2 enfants (4 et 9 ans). Quelle chambre nous conseillez-vous ? Et quelles activités pour les enfants ?\n\nStéphanie",
        "language": "fr",
        "expect_tools": ["get_room_details", "check_room_availability"],
    },
    {
        "id": 35,
        "category": "family",
        "name": "Bébé 18 mois",
        "from_name": "Rachel Green",
        "from_email": "rachel.green@gmail.com",
        "subject": "Traveling with a baby",
        "body": "Hi,\n\nWe have an 18-month-old baby. Do you have a crib available? Is the pool safe for toddlers?\n\nRachel",
        "language": "en",
    },

    # ═══════════════════════════════════════════════════
    #  RÉSERVATION & MODIFICATION (36-41)
    # ═══════════════════════════════════════════════════
    {
        "id": 36,
        "category": "booking",
        "name": "Demande de réservation directe",
        "from_name": "Nicolas Garnier",
        "from_email": "nicolas.garnier@gmail.com",
        "subject": "Réservation",
        "body": "Bonjour,\n\nJe souhaite réserver une chambre avec vue mer du 5 au 12 juin 2026 pour 2 adultes. Comment procéder ?\n\nNicolas",
        "language": "fr",
        "expect_tools": ["check_room_availability"],
        "expect_booking_link": True,
    },
    {
        "id": 37,
        "category": "booking",
        "name": "Conditions annulation",
        "from_name": "Emily Watson",
        "from_email": "emily.watson@gmail.com",
        "subject": "Cancellation policy",
        "body": "Hi,\n\nWhat is your cancellation policy? We might need to change our dates.\n\nEmily",
        "language": "en",
        "expect_tools": ["search_faq"],
    },
    {
        "id": 38,
        "category": "booking_modification",
        "name": "Modifier dates (ESCALADE)",
        "from_name": "Vincent Leroy",
        "from_email": "vincent.leroy@yahoo.fr",
        "subject": "Modification réservation",
        "body": "Bonjour,\n\nJ'ai une réservation du 10 au 15 mai, mais nous aimerions décaler au 12-17 mai. Est-ce possible ?\n\nVincent",
        "language": "fr",
        "expect_escalation": True,
    },
    {
        "id": 39,
        "category": "booking_modification",
        "name": "Annulation (ESCALADE)",
        "from_name": "Mark Thompson",
        "from_email": "mark.thompson@outlook.com",
        "subject": "Cancel reservation",
        "body": "Hi,\n\nI'm sorry but I need to cancel my reservation for next month. Can you help?\n\nMark",
        "language": "en",
        "expect_escalation": True,
    },
    {
        "id": 40,
        "category": "booking_modification",
        "name": "Extension séjour (cas Tait Allen)",
        "from_name": "Tait Allen",
        "from_email": "tait.allen@gmail.com",
        "subject": "Extending our stay",
        "body": "Hi Marion,\n\nWe're having such a wonderful time! Is it possible to extend our stay by 2 more nights?\n\nTait",
        "language": "en",
        "expect_escalation": True,
    },
    {
        "id": 41,
        "category": "booking",
        "name": "Résa via Booking.com",
        "from_name": "Andrea Müller",
        "from_email": "andrea.muller@web.de",
        "subject": "Booking confirmation",
        "body": "Hello,\n\nI booked through Booking.com for March 20-25. Can you confirm you received our reservation? We are 2 adults and 2 children.\n\nAndrea",
        "language": "en",
        "expect_tools": ["lookup_reservation"],
    },

    # ═══════════════════════════════════════════════════
    #  PLAINTES & ESCALADES (42-44)
    # ═══════════════════════════════════════════════════
    {
        "id": 42,
        "category": "complaint",
        "name": "Plainte (ESCALADE)",
        "from_name": "Gérard Dupuis",
        "from_email": "gerard.dupuis@free.fr",
        "subject": "Déception",
        "body": "Bonjour,\n\nJe suis très déçu de mon séjour. La climatisation ne fonctionnait pas et personne n'est venu la réparer malgré mes 3 demandes. Je demande un remboursement partiel.\n\nGérard Dupuis",
        "language": "fr",
        "expect_escalation": True,
    },
    {
        "id": 43,
        "category": "complaint",
        "name": "Menace annulation OTA (ESCALADE)",
        "from_name": "Patricia Hall",
        "from_email": "patricia.hall@gmail.com",
        "subject": "Canceling through Expedia",
        "body": "Hi,\n\nIf you can't fix this issue I will cancel through Expedia and dispute the charge on my credit card.\n\nPatricia",
        "language": "en",
        "expect_escalation": True,
    },
    {
        "id": 44,
        "category": "complaint",
        "name": "Problème paiement (ESCALADE)",
        "from_name": "Antoine Morel",
        "from_email": "antoine.morel@gmail.com",
        "subject": "Problème carte bancaire",
        "body": "Bonjour,\n\nJ'ai été débité 2 fois pour ma réservation. Le montant est incorrect. Merci de vérifier.\n\nAntoine",
        "language": "fr",
        "expect_escalation": True,
    },

    # ═══════════════════════════════════════════════════
    #  INFOS PRATIQUES (45-48)
    # ═══════════════════════════════════════════════════
    {
        "id": 45,
        "category": "info",
        "name": "Check-in / check-out",
        "from_name": "Diana Ross",
        "from_email": "diana.ross@gmail.com",
        "subject": "Check-in time",
        "body": "Hi,\n\nWhat time is check-in and check-out? Our flight arrives at 11am.\n\nDiana",
        "language": "en",
    },
    {
        "id": 46,
        "category": "info",
        "name": "Animaux acceptés ?",
        "from_name": "Luc Perrin",
        "from_email": "luc.perrin@orange.fr",
        "subject": "Chien",
        "body": "Bonjour,\n\nAcceptez-vous les animaux de compagnie ? Nous avons un petit chien.\n\nLuc",
        "language": "fr",
        "expect_tools": ["search_faq"],
    },
    {
        "id": 47,
        "category": "info",
        "name": "Pièce jointe",
        "from_name": "Sandra Koch",
        "from_email": "sandra.koch@gmx.de",
        "subject": "Documents for our stay",
        "body": "[Note: cet email contient des pièces jointes qui ne sont pas visibles ici]\n\nHello,\n\nPlease find attached our passport copies and flight details as requested.\n\nSandra",
        "language": "en",
    },
    {
        "id": 48,
        "category": "info",
        "name": "Petit-déjeuner inclus ?",
        "from_name": "Martine Gauthier",
        "from_email": "martine.gauthier@gmail.com",
        "subject": "Petit-déjeuner",
        "body": "Bonjour,\n\nLe petit-déjeuner est-il inclus dans le tarif de la chambre ?\n\nMartine",
        "language": "fr",
    },

    # ═══════════════════════════════════════════════════
    #  REMERCIEMENTS & COMPLIMENTS (49-50)
    # ═══════════════════════════════════════════════════
    {
        "id": 49,
        "category": "compliment",
        "name": "Remerciement post-séjour",
        "from_name": "Catherine Blanc",
        "from_email": "catherine.blanc@gmail.com",
        "subject": "Merci !",
        "body": "Chère Marion,\n\nNous tenions à vous remercier pour ce séjour merveilleux. Tout était parfait, de l'accueil à la vue depuis notre chambre. Nous reviendrons sans aucun doute !\n\nCatherine & Pierre",
        "language": "fr",
    },
    {
        "id": 50,
        "category": "compliment",
        "name": "Compliment en anglais",
        "from_name": "Robert Mitchell",
        "from_email": "robert.mitchell@yahoo.com",
        "subject": "Thank you!",
        "body": "Dear Marion,\n\nJust wanted to say thank you for an amazing stay. The hotel was beautiful and you made us feel right at home. We'll definitely be back!\n\nRobert & Susan",
        "language": "en",
    },
]


async def run_scenario(scenario: dict, verbose: bool = True) -> dict:
    """Run a single scenario through the AI engine."""
    from src.config import settings
    from src.models.ai import AIRule
    from src.services import supabase_client as db
    from src.services.ai_engine import generate_response
    from src.services.confidence import compute_confidence
    from src.services.escalation import check_pre_escalation
    from src.tools.handlers import clear_session_state, get_pending_team_actions

    clear_session_state()

    result = {
        "id": scenario["id"],
        "name": scenario["name"],
        "category": scenario["category"],
        "language": scenario["language"],
    }

    # Check pre-escalation first
    pre_esc = check_pre_escalation(scenario["body"], scenario.get("subject", ""))
    if pre_esc:
        result["pre_escalation"] = pre_esc.reason
        # For booking modifications, continue (deferred escalation)
        from src.models.enums import EscalationReason
        if pre_esc.reason != EscalationReason.BOOKING_MODIFICATION.value:
            result["status"] = "escalated"
            result["response"] = f"[ESCALADE: {pre_esc.reason} — {pre_esc.details}]"
            if verbose:
                _print_result(scenario, result)
            return result
        else:
            result["deferred_escalation"] = True

    # Load rules from DB
    try:
        raw_rules = await db.get_active_rules()
        rules = [AIRule(**r) for r in raw_rules]
    except Exception:
        rules = []

    # Build escalation hint if deferred
    escalation_hint = None
    if result.get("deferred_escalation"):
        escalation_hint = (
            "Ce client demande une MODIFICATION/ANNULATION de réservation. "
            "L'équipe va s'en occuper. "
            "Écris juste un accusé de réception bref et chaleureux."
        )

    # Generate AI response
    try:
        ai_response = await generate_response(
            email_body=scenario["body"],
            email_subject=scenario.get("subject", ""),
            from_email=scenario["from_email"],
            detected_language=scenario["language"],
            rules=rules,
            client_context=None,
            conversation_history=None,
            escalation_hint=escalation_hint,
        )

        # Confidence scoring
        confidence = compute_confidence(
            ai_response_text=ai_response.response_text,
            llm_self_score=ai_response.confidence_score,
            tools_used=ai_response.tools_used,
            email_body=scenario["body"],
            rules_count=len(rules),
        )

        # Team actions
        team_actions = get_pending_team_actions()

        result["status"] = "ok"
        result["response"] = ai_response.response_text
        result["tools_used"] = ai_response.tools_used
        result["team_actions"] = team_actions
        result["confidence"] = round(confidence.weighted_score, 2)
        result["llm_confidence"] = ai_response.confidence_score
        result["category_detected"] = ai_response.category
        result["tokens_in"] = ai_response.tokens_input
        result["tokens_out"] = ai_response.tokens_output
        result["time_ms"] = ai_response.response_time_ms
        result["word_count"] = len(ai_response.response_text.split())

    except Exception as exc:
        result["status"] = "error"
        result["error"] = str(exc)

    if verbose:
        _print_result(scenario, result)

    return result


def _print_result(scenario: dict, result: dict):
    """Pretty-print a test result."""
    status_icon = {
        "ok": "OK",
        "escalated": "ESCALADE",
        "error": "ERREUR",
    }.get(result.get("status", "?"), "?")

    print(f"\n{'='*70}")
    print(f"#{scenario['id']:02d} [{status_icon}] {scenario['name']}")
    print(f"    De: {scenario['from_name']} <{scenario['from_email']}>")
    print(f"    Langue: {scenario['language']} | Cat: {scenario['category']}")
    print(f"-"*70)

    if result.get("pre_escalation"):
        label = "DIFFEREE" if result.get("deferred_escalation") else "BLOQUANTE"
        print(f"    >> ESCALADE {label}: {result['pre_escalation']}")

    if result.get("status") == "error":
        print(f"    ERREUR: {result.get('error', '?')}")
        return

    if result.get("response"):
        # Truncate long responses for display
        resp = result["response"]
        print(f"\n    REPONSE ({result.get('word_count', '?')} mots):")
        print(f"    {'-'*60}")
        for line in resp.split("\n"):
            print(f"    {line}")
        print(f"    {'-'*60}")

    if result.get("tools_used"):
        print(f"    Outils: {', '.join(result['tools_used'])}")
    if result.get("team_actions"):
        for a in result["team_actions"]:
            print(f"    >> ACTION EQUIPE: {a['action']}")
    if result.get("confidence"):
        print(f"    Confiance: {result['confidence']} (LLM: {result.get('llm_confidence', '?')})")
    if result.get("tokens_in"):
        print(f"    Tokens: {result['tokens_in']} in / {result['tokens_out']} out | {result.get('time_ms', '?')}ms")


async def run_all(category: str | None = None, scenario_id: int | None = None):
    """Run all scenarios (or filtered)."""
    filtered = SCENARIOS
    if category:
        filtered = [s for s in filtered if s["category"] == category]
    if scenario_id:
        filtered = [s for s in filtered if s["id"] == scenario_id]

    print(f"\n{'#'*70}")
    print(f"  TEST IA CONCIERGE — {len(filtered)} scenarios")
    print(f"  Modele: claude-sonnet-4-6")
    print(f"{'#'*70}")

    results = []
    total_tokens_in = 0
    total_tokens_out = 0
    total_time = 0
    errors = 0
    escalated = 0

    for scenario in filtered:
        result = await run_scenario(scenario)
        results.append(result)
        if result.get("status") == "error":
            errors += 1
        elif result.get("status") == "escalated":
            escalated += 1
        total_tokens_in += result.get("tokens_in", 0)
        total_tokens_out += result.get("tokens_out", 0)
        total_time += result.get("time_ms", 0)

    # Summary
    ok_results = [r for r in results if r.get("status") == "ok"]
    avg_words = sum(r.get("word_count", 0) for r in ok_results) / max(len(ok_results), 1)
    avg_confidence = sum(r.get("confidence", 0) for r in ok_results) / max(len(ok_results), 1)

    from src.services.cost_tracker import compute_cost_eur
    total_cost = compute_cost_eur("claude-sonnet-4-6", total_tokens_in, total_tokens_out)

    print(f"\n{'#'*70}")
    print(f"  RESULTATS")
    print(f"{'#'*70}")
    print(f"  OK: {len(ok_results)} | Escalades: {escalated} | Erreurs: {errors}")
    print(f"  Mots moyen/reponse: {avg_words:.0f}")
    print(f"  Confiance moyenne: {avg_confidence:.2f}")
    print(f"  Tokens total: {total_tokens_in} in / {total_tokens_out} out")
    print(f"  Cout total: {total_cost:.4f} EUR")
    print(f"  Temps total: {total_time/1000:.1f}s")

    # Flag issues
    print(f"\n  ALERTES:")
    for r in ok_results:
        issues = []
        if r.get("word_count", 0) > 150:
            issues.append(f"TROP LONG ({r['word_count']} mots)")
        if r.get("confidence", 1) < 0.7:
            issues.append(f"CONFIANCE BASSE ({r['confidence']})")
        if issues:
            print(f"    #{r['id']:02d} {r['name']}: {', '.join(issues)}")

    no_alerts = all(
        r.get("word_count", 0) <= 150 and r.get("confidence", 1) >= 0.7
        for r in ok_results
    )
    if no_alerts:
        print(f"    Aucune alerte.")

    return results


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Test AI Concierge scenarios")
    parser.add_argument("--scenario", "-s", type=int, help="Run a single scenario by ID")
    parser.add_argument("--category", "-c", type=str, help="Filter by category")
    parser.add_argument("--list", "-l", action="store_true", help="List all scenarios")
    args = parser.parse_args()

    if args.list:
        print(f"\n{'ID':>3} {'Category':<22} {'Name'}")
        print(f"{'-'*3} {'-'*22} {'-'*40}")
        for s in SCENARIOS:
            esc = " [ESCALADE]" if s.get("expect_escalation") else ""
            print(f"{s['id']:>3} {s['category']:<22} {s['name']}{esc}")
        sys.exit(0)

    asyncio.run(run_all(category=args.category, scenario_id=args.scenario))
