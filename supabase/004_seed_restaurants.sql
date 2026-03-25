-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Restaurants (vrais restaurants validés par Marion)    ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Restaurants confirmés dans les vrais emails de Marion & Emmanuel.
-- IMPORTANT : Aucun restaurant n'est accessible à pied depuis l'hôtel.
-- Tous nécessitent une voiture (5-25 min).

INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, reservation_required, specialties, ambiance, distance_km, driving_time_min, walkable, access_note_fr, access_note_en, best_for, description_fr, description_en, is_partner, sort_order) VALUES

-- Restaurants confirmés par Marion (email Linda Thornton, fév. 2026)
('Ristorante Del Arti', 'Orient Bay', 'italian', '€€€', 55,
 '+590 690 73 96 33', TRUE,
 'Cuisine italienne gastronomique',
 'Élégant, en plein air',
 3.5, 8, FALSE,
 'Environ 8 minutes en voiture depuis l''hôtel.',
 'About 8 minutes drive from the hotel.',
 ARRAY['romantic', 'anniversary', 'gourmet', 'outdoor'],
 'Restaurant italien recommandé par Marion pour les dîners spéciaux et anniversaires. Tables en extérieur disponibles.',
 'Italian restaurant recommended by Marion for special dinners and anniversaries. Outdoor tables available.',
 FALSE, 1),

('Le Tropicana', 'Orient Bay', 'french', '€€', 40,
 '+590 590 87 79 07', TRUE,
 'Cuisine française et créole',
 'Décontracté, convivial',
 3.5, 8, FALSE,
 'Environ 8 minutes en voiture depuis l''hôtel.',
 'About 8 minutes drive from the hotel.',
 ARRAY['lunch', 'casual', 'returning_guests'],
 'Restaurant apprécié des habitués. Recommandé par Marion pour le déjeuner. Salle intérieure et terrasse.',
 'A favorite among returning guests. Recommended by Marion for lunch. Indoor and terrace seating.',
 FALSE, 2),

('Le Terrasse Rooftop Restaurant', 'Marigot', 'french', '€€€', 60,
 '+590 690 66 99 99', TRUE,
 'Cuisine gastronomique, vue mer',
 'Rooftop, vue sur l''eau, élégant',
 9.0, 15, FALSE,
 'Environ 15 minutes en voiture depuis l''hôtel.',
 'About 15 minutes drive from the hotel.',
 ARRAY['romantic', 'sunset', 'waterside', 'anniversary', 'gourmet'],
 'Restaurant rooftop avec vue sur l''eau. Tables au bord de l''eau demandées. Idéal pour un dîner romantique.',
 'Rooftop restaurant with water view. Waterside tables available on request. Ideal for a romantic dinner.',
 FALSE, 3),

('Lulu''s Corner', 'Grand Case', 'french', '€€', 35,
 '+590 690 77 87 81', TRUE,
 'Cuisine française bistrot',
 'Chaleureux, climatisé',
 6.0, 10, FALSE,
 'Environ 10 minutes en voiture depuis l''hôtel.',
 'About 10 minutes drive from the hotel.',
 ARRAY['lunch', 'casual', 'family'],
 'Bistrot à Grand Case recommandé par Marion pour le déjeuner. Salle climatisée et tables ombragées disponibles.',
 'Grand Case bistro recommended by Marion for lunch. Air-conditioned and shaded tables available.',
 FALSE, 4);
