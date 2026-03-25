-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  012 — Mise à jour tarifs services (validés Marion mars 2026)  ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Transfert aéroport : 70€/trajet (= 140€ aller-retour)
UPDATE hotel_services SET
    price_eur = 70.00,
    price_note = 'Par trajet (aller simple) — 140€ aller-retour'
WHERE slug = 'shuttle';

-- Massage individuel : 120€ → 165€
UPDATE hotel_services SET
    price_eur = 165.00,
    description_fr = 'Massage d''une heure en chambre. Différentes techniques disponibles. Réservation 24h à l''avance.',
    description_en = 'One-hour in-room massage. Various techniques available. 24h advance booking required.'
WHERE slug = 'massage-solo';

-- Massage duo : 240€ → 330€
UPDATE hotel_services SET
    price_eur = 330.00,
    description_fr = 'Massage en duo d''une heure, en chambre. Réservation 24h à l''avance.',
    description_en = 'One-hour couples massage, in-room. 24h advance booking required.'
WHERE slug = 'massage-couple';

-- Yoga privé : 104€ → 110€
UPDATE hotel_services SET price_eur = 110.00 WHERE slug = 'yoga';

-- Coaching sportif : 80€ → 110€
UPDATE hotel_services SET price_eur = 110.00 WHERE slug = 'coaching';

-- Pilates : sur demande → 110€/séance
UPDATE hotel_services SET
    price_eur = 110.00,
    name_fr = 'Cours de Pilates privé (1h)',
    name_en = 'Private Pilates class (1h)',
    description_fr = 'Cours de Pilates privé d''une heure à l''hôtel.',
    description_en = 'One-hour private Pilates class at the hotel.',
    price_note = 'Par séance'
WHERE slug = 'pilates';

-- Facial Carita : ajout mention 24h
UPDATE hotel_services SET
    description_fr = 'Soin du visage professionnel par Carita. Réservation 24h à l''avance.',
    description_en = 'Professional Carita facial treatment. 24h advance booking required.'
WHERE slug = 'facial';

-- Yoga dans activities : 104€ → 110€
UPDATE activities SET
    price_from_eur = 110,
    price_to_eur = 110,
    description_fr = 'Cours privé au jardin, sur paddle ou au bord de la piscine. 110€/séance.',
    description_en = 'Private class in garden, on paddleboard or poolside. €110/session.'
WHERE name_fr = 'Yoga privé à l''hôtel';
