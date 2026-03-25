-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  AUDIT V5 — Retours Marion 18 mars 2026                       ║
-- ║  - Enrichir partenaires (Scoobi Too, Hopfit)                  ║
-- ║  - Ajouter 4 restaurants (Java, Blue Martini, Galets, Cottage)║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  1. MISE À JOUR PARTENAIRES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Scoobi Too — enrichir avec limitations exactes (retour Marion 18/03)
UPDATE partners SET
    description_fr = 'Sorties bateau depuis Saint-Martin. Excursions à la journée ou demi-journée autour de l''île et vers Anguilla. LIMITATIONS : ne peut PAS aller à Saint-Barthélemy (trop loin pour ce type de bateau — semi-rigide). Destinations possibles : tour de l''île, Tintamarre, Pinel, Anguilla, Creole Rock, snorkeling spots. Ce n''est PAS du "private charter" — c''est un bateau semi-rigide avec skipper.',
    description_en = 'Boat trips from Saint-Martin. Full-day or half-day excursions around the island and to Anguilla. LIMITATIONS: CANNOT go to Saint-Barthélemy (too far for this type of boat — rigid inflatable). Possible destinations: island tour, Tintamarre, Pinel, Anguilla, Creole Rock, snorkeling spots. This is NOT a "private charter" — it is a rigid inflatable boat (RIB) with skipper.',
    pricing_info = 'Demi-journée (4h) : environ €800-€900. Journée complète (8h) avec Anguilla : environ €1400-€1500. Tarif exact sur devis selon itinéraire et saison.',
    notes = 'CONFIDENTIEL — NE JAMAIS donner le nom "Scoobi Too" au client (perte de commission). Dire "notre partenaire bateau". Ce n''est PAS du private charter. Ne peut PAS aller à St Barth — pour St Barth recommander le ferry Great Bay Express. Traversée Anguilla : environ 20 minutes par bateau.'
WHERE name = 'Scoobi Too';

-- Hopfit — ajouter le prix exact (€15/jour — validé Marion)
UPDATE partners SET
    pricing_info = 'Day pass : 15€ par personne. Accès à l''ensemble des équipements.',
    description_fr = 'Salle de sport bien équipée à seulement 5 minutes en voiture de l''hôtel. Day pass disponible.',
    description_en = 'Well-equipped gym just a 5-minute drive from the hotel. Day pass available.',
    notes = 'CONFIDENTIEL — NE JAMAIS donner le nom "Hopfit" au client (perte de commission). Dire "une salle de sport partenaire à 5 minutes en voiture". Prix confirmé par Marion : 15€/personne/jour.'
WHERE name = 'Hopfit Hope Estate';

-- Escale Car Rental — ajouter note confidentialité
UPDATE partners SET
    notes = 'CONFIDENTIEL — NE JAMAIS donner le nom "Escale Car Rental" au client (perte de commission). Dire "notre partenaire location de voiture" ou "a trusted car rental partner". Utiliser le template email "car_rental" pour la mise en relation. Toujours mettre le client en copie.'
WHERE name = 'Escale Car Rental';

-- Bubble Shop — ajouter note confidentialité
UPDATE partners SET
    notes = 'CONFIDENTIEL — NE JAMAIS donner le nom au client. Dire "un prestataire de snorkeling local" ou "a local snorkeling operator".'
WHERE name = 'Bubble Shop';

-- Lottery Farm — ajouter note confidentialité
UPDATE partners SET
    notes = 'CONFIDENTIEL — NE JAMAIS donner le nom au client. Dire "un site de randonnée et zipline" ou "a hiking and zipline site on the island". Recommandé spécialement pour les ados (zipline) et les amateurs de nature.'
WHERE name = 'Lottery Farm';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  2. NOUVEAUX RESTAURANTS (retours Emmanuel 18/03)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Le Java — restaurant festif Grand Case (recommandé par Emmanuel pour anniversaires fun)
INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, reservation_required, specialties, ambiance, distance_km, driving_time_min, walkable, access_note_fr, access_note_en, best_for, description_fr, description_en, is_partner, sort_order) VALUES
('Le Java', 'Grand Case', 'french', '€€-€€€', 50,
 NULL, TRUE,
 'Cuisine française créative, ambiance festive',
 'Festif, animé, musique, soirée',
 6.0, 10, FALSE,
 'Environ 10 minutes en voiture depuis l''hôtel.',
 'About a 10-minute drive from the hotel.',
 ARRAY['birthday', 'fun', 'nightlife', 'group_dinner', 'celebration', 'lively'],
 'Restaurant festif à Grand Case. Ambiance animée et chaleureuse, idéal pour un anniversaire ou une soirée entre amis. Recommandé par Emmanuel pour les clients qui cherchent du fun.',
 'Lively restaurant in Grand Case. Warm and festive atmosphere, ideal for birthdays or a fun evening out. Recommended by Emmanuel for guests looking for a great time.',
 FALSE, 5);

-- Blue Martini — bar/lounge Grand Case (recommandé par Emmanuel pour continuer la soirée)
INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, reservation_required, specialties, ambiance, distance_km, driving_time_min, walkable, access_note_fr, access_note_en, best_for, description_fr, description_en, is_partner, sort_order) VALUES
('Blue Martini', 'Grand Case', 'bar', '€€', 30,
 NULL, FALSE,
 'Cocktails, bar lounge, tapas',
 'Bar lounge, cocktails, soirée, ambiance décontractée',
 6.0, 10, FALSE,
 'Environ 10 minutes en voiture depuis l''hôtel.',
 'About a 10-minute drive from the hotel.',
 ARRAY['nightlife', 'drinks', 'after_dinner', 'fun', 'birthday', 'bar', 'cocktails'],
 'Bar lounge à Grand Case. Parfait pour continuer la soirée après un dîner, bons cocktails et ambiance festive. Combinaison idéale : dîner au Java puis soirée au Blue Martini.',
 'Lounge bar in Grand Case. Perfect for continuing the evening after dinner, great cocktails and a festive atmosphere. Ideal combo: dinner at Le Java then drinks at Blue Martini.',
 FALSE, 6);

-- Les Galets — restaurant gastronomique romantique Grand Case (recommandé par Emmanuel)
INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, reservation_required, specialties, ambiance, distance_km, driving_time_min, walkable, access_note_fr, access_note_en, best_for, description_fr, description_en, is_partner, sort_order) VALUES
('Les Galets', 'Grand Case', 'french', '€€€', 65,
 NULL, TRUE,
 'Cuisine gastronomique française, pieds dans le sable',
 'Romantique, pieds dans le sable, intime, bord de mer',
 6.0, 10, FALSE,
 'Environ 10 minutes en voiture depuis l''hôtel.',
 'About a 10-minute drive from the hotel.',
 ARRAY['romantic', 'anniversary', 'gourmet', 'sunset', 'honeymoon', 'special_occasion'],
 'Restaurant gastronomique sur la plage de Grand Case. Tables pieds dans le sable, cadre intime et romantique face à la mer. Idéal pour les dîners en amoureux et les occasions spéciales.',
 'Gourmet beach restaurant on Grand Case beach. Tables in the sand, intimate and romantic setting facing the sea. Perfect for romantic dinners and special occasions.',
 FALSE, 7);

-- Le Cottage — restaurant intime romantique Grand Case (recommandé par Emmanuel)
INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, reservation_required, specialties, ambiance, distance_km, driving_time_min, walkable, access_note_fr, access_note_en, best_for, description_fr, description_en, is_partner, sort_order) VALUES
('Le Cottage', 'Grand Case', 'french', '€€€', 60,
 NULL, TRUE,
 'Cuisine française raffinée',
 'Intime, romantique, élégant, chaleureux',
 6.0, 10, FALSE,
 'Environ 10 minutes en voiture depuis l''hôtel.',
 'About a 10-minute drive from the hotel.',
 ARRAY['romantic', 'anniversary', 'intimate', 'gourmet', 'honeymoon'],
 'Restaurant intime et élégant à Grand Case. Cuisine française raffinée dans un cadre chaleureux et romantique. Recommandé par Emmanuel pour les dîners en amoureux.',
 'Intimate and elegant restaurant in Grand Case. Refined French cuisine in a warm and romantic setting. Recommended by Emmanuel for romantic dinners.',
 FALSE, 8);
