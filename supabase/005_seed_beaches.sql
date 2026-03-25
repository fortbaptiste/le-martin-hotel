-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Plages de Saint-Martin (20+)                           ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO beaches (name, side, distance_km, driving_time_min, walking_time_min, characteristics, facilities, crowd_level, best_for, description_fr, description_en, sort_order) VALUES

-- ═══ CÔTÉ FRANÇAIS ═══
('Cul de Sac Bay', 'french', 0, 0, 0,
 'Baie calme, dock de l''hôtel, départ kayak/paddle vers Pinel', 'Dock hôtel, kayaks gratuits, paddle gratuits', 'Calme',
 ARRAY['kayak', 'paddle', 'snorkeling', 'calm'],
 'La baie de l''hôtel. Petit dock à 1 minute à pied pour les kayaks et paddles. Le ferry vers Pinel part d''un autre dock (2-3 min en voiture ou 15 min à pied).',
 'The hotel''s own bay. Small dock 1 minute walk for kayaks and paddleboards. The ferry to Pinel departs from a different dock (2-3 min drive or 15 min walk).', 1),

('Orient Bay Beach', 'french', 1.9, 5, 18,
 'La plus célèbre de l''île. 2 km de sable blanc, beach clubs, sports nautiques', 'Beach clubs, transats, restaurants, jet ski, kitesurf, parasailing, toilettes, douches', 'Animé',
 ARRAY['beach_clubs', 'water_sports', 'nightlife', 'family', 'snorkeling'],
 'Le "Saint-Tropez des Caraïbes". Plage la plus animée de l''île avec beach clubs (Kontiki, KKO, Bikini Beach, Wai Beach), restaurants, sports nautiques. Section naturiste au sud.',
 'The "Saint-Tropez of the Caribbean". Liveliest beach with beach clubs (Kontiki, KKO, Bikini Beach, Wai Beach), restaurants, water sports. Naturist section at south end.', 2),

('Île Pinel', 'french', 1.7, 0, 0,
 'Îlot paradisiaque en face de Cul de Sac. Snorkeling exceptionnel, tortues', 'Restaurants (Karibuni, Yellow Beach), snorkeling, pas de transats', 'Modéré',
 ARRAY['snorkeling', 'romantic', 'must_visit', 'kayak', 'family'],
 'Petit îlot accessible en ferry (10€ A/R, 5 min) ou kayak gratuit hôtel (20-25 min). Sentier de snorkeling balisé, tortues, raies. 2 restaurants pieds dans le sable. Vue sur Anguilla et St-Barth depuis le sommet.',
 'Small island accessible by ferry (€10 round trip, 5 min) or free hotel kayak (20-25 min). Marked snorkeling trail, turtles, rays. 2 feet-in-the-sand restaurants. Views of Anguilla and St Barth from hilltop.', 3),

('Galion Beach (Le Galion)', 'french', 7.0, 10, 0,
 'Protégée par récif, eau peu profonde, vent constant', 'Windsurf, kitesurf, toilettes', 'Calme',
 ARRAY['family', 'windsurf', 'kitesurf', 'calm', 'children'],
 'Plage familiale protégée par un récif. Eau calme et peu profonde, idéale pour les enfants. Spot de windsurf et kitesurf grâce au vent constant.',
 'Family-friendly reef-protected beach. Calm, shallow water ideal for children. Windsurf and kitesurf spot thanks to constant wind.', 4),

('Grand Case Beach', 'french', 6.0, 10, 0,
 'Sable blanc, eau calme, adjacente à la capitale gastronomique', 'Restaurants à 50m, transats, calme', 'Modéré',
 ARRAY['calm', 'romantic', 'sunset', 'snorkeling'],
 'Belle plage calme de sable blanc. Idéale avant ou après un dîner dans les restaurants de Grand Case. Snorkeling à Creole Rock accessible en bateau.',
 'Beautiful calm white sand beach. Ideal before or after dinner at Grand Case restaurants. Snorkeling at Creole Rock accessible by boat.', 5),

('Anse Marcel', 'french', 5.0, 10, 0,
 'Crique protégée très calme, marina, eau turquoise', 'Marina, restaurants, jet ski, plongée', 'Calme',
 ARRAY['calm', 'family', 'snorkeling', 'romantic'],
 'Crique protégée et très calme. Marina avec restaurants. Eau turquoise limpide. Idéale pour les familles et le snorkeling.',
 'Protected, very calm cove. Marina with restaurants. Crystal-clear turquoise water. Ideal for families and snorkeling.', 6),

('Happy Bay', 'french', 4.4, 10, 15,
 'Plage secrète accessible uniquement à pied depuis Friar''s Bay (15 min de marche)', 'Aucune installation', 'Très calme',
 ARRAY['secluded', 'romantic', 'hiking', 'quiet'],
 'Plage secrète et isolée. Accessible uniquement par un sentier de 15 min depuis Friar''s Bay. Aucune installation — apporter eau et nourriture. Vue sur Anguilla.',
 'Secret, secluded beach. Only accessible via 15-min trail from Friar''s Bay. No facilities — bring water and food. Views of Anguilla.', 7),

('Friar''s Bay (Baie des Pères)', 'french', 10.0, 15, 0,
 'Plage bohème avec bars de plage légendaires, Full Moon Party', 'Kali''s Beach Bar, 978 Beach Lounge, restaurants, transats', 'Modéré',
 ARRAY['nightlife', 'local', 'sunset', 'bohemian'],
 'Plage bohème et emblématique. Kali''s Beach Bar et son Bush Rum maison sont légendaires. Full Moon Party mensuelle avec feu de camp et reggae.',
 'Bohemian, iconic beach. Kali''s Beach Bar and its homemade Bush Rum are legendary. Monthly Full Moon Party with bonfire and reggae.', 8),

('Baie Rouge', 'french', 15.0, 20, 0,
 'Sable rosé, grotte pour snorkeling, romantique', 'Quelques transats, bar de plage saisonnier', 'Calme',
 ARRAY['romantic', 'snorkeling', 'quiet', 'secluded'],
 'Plage au sable rosé-rouge. Grotte accessible à la nage menant à une plage cachée. Excellent snorkeling. Très romantique.',
 'Pink-red sand beach. Swim-through cave leading to hidden beach. Excellent snorkeling. Very romantic.', 9),

('Baie Longue (Long Bay)', 'french', 17.0, 25, 0,
 'Plage préservée, Belmond La Samanna, très calme', 'La Samanna resort', 'Très calme',
 ARRAY['quiet', 'romantic', 'luxury', 'secluded'],
 'Longue plage préservée bordée par le Belmond La Samanna. Très calme, presque déserte. Idéale pour une marche romantique.',
 'Long, pristine beach bordered by Belmond La Samanna. Very quiet, almost deserted. Ideal for a romantic walk.', 10),

('Baie Nettle', 'french', 12.0, 18, 0,
 'Côté lagune, hôtels, kitesurf', 'Hôtels, restaurants, kitesurf', 'Animé',
 ARRAY['kitesurf', 'hotels'],
 'Plage côté lagune, bordée d''hôtels. Spot de kitesurf.',
 'Lagoon-side beach, lined with hotels. Kitesurfing spot.', 11),

('Tintamarre Island', 'french', 8.0, 0, 0,
 'Île inhabitée, réserve naturelle, tortues marines, piste d''atterrissage abandonnée', 'Aucune — apporter tout', 'Désert',
 ARRAY['snorkeling', 'nature', 'secluded', 'adventure'],
 'Île totalement inhabitée à 25 min en bateau. Réserve naturelle : tortues marines, raies, récif préservé. Ancienne piste d''atterrissage. Tintamarre Express depuis Cul de Sac : 25€ A/R.',
 'Totally uninhabited island 25 min by boat. Nature reserve: sea turtles, rays, pristine reef. Abandoned airstrip. Tintamarre Express from Cul de Sac: €25 round trip.', 12),

-- ═══ CÔTÉ HOLLANDAIS ═══
('Maho Beach', 'dutch', 20.0, 28, 0,
 'Célèbre pour les avions qui atterrissent à quelques mètres au-dessus de la plage', 'Sunset Bar & Grill, boutiques, casinos à proximité', 'Très animé',
 ARRAY['must_visit', 'family', 'nightlife', 'unique'],
 'La plage la plus célèbre au monde pour les avions. Les jets atterrissent à 10-20 mètres au-dessus de la plage (aéroport Princess Juliana). Sunset Bar & Grill pour regarder le spectacle.',
 'The world''s most famous plane-spotting beach. Jets land 10-20 meters above the beach (Princess Juliana Airport). Sunset Bar & Grill to watch the show.', 15),

('Mullet Bay Beach', 'dutch', 19.0, 25, 0,
 'Sable blanc fin, vagues douces, coucher de soleil', 'Limité — apporter provisions', 'Modéré',
 ARRAY['quiet', 'sunset', 'swimming'],
 'Belle plage de sable blanc fin. Vagues douces. Magnifique coucher de soleil. Peu d''installations — apporter eau et nourriture.',
 'Beautiful fine white sand beach. Gentle waves. Magnificent sunset. Few facilities — bring water and food.', 16),

('Cupecoy Beach', 'dutch', 18.0, 25, 0,
 'Falaises de grès spectaculaires, grottes, isolé', 'Aucune', 'Calme',
 ARRAY['secluded', 'romantic', 'photography', 'unique'],
 'Plage dramatique avec falaises de grès et grottes naturelles. Section isolée. Paysage unique sur l''île.',
 'Dramatic beach with sandstone cliffs and natural caves. Secluded sections. Unique landscape on the island.', 17),

('Simpson Bay Beach', 'dutch', 17.0, 22, 0,
 'Longue plage calme, proche aéroport', 'Bars, restaurants à proximité', 'Calme',
 ARRAY['calm', 'quiet', 'swimming'],
 'Longue plage calme près de l''aéroport. Idéale pour une dernière baignade avant le vol.',
 'Long, quiet beach near the airport. Ideal for a last swim before your flight.', 18),

('Great Bay Beach', 'dutch', 15.0, 22, 0,
 'Boardwalk de Philipsburg, shopping, bateaux de croisière', 'Boardwalk, restaurants, shopping duty-free, toilettes', 'Très animé',
 ARRAY['shopping', 'family', 'casual'],
 'Plage du boardwalk de Philipsburg. Shopping duty-free à 50m. Très animé les jours de croisière.',
 'Philipsburg boardwalk beach. Duty-free shopping 50m away. Very busy on cruise ship days.', 19),

('Dawn Beach', 'dutch', 8.0, 12, 0,
 'Côte est, lever de soleil, vagues', 'Hôtel Westin, restaurant', 'Calme',
 ARRAY['sunrise', 'surfing', 'quiet'],
 'Plage de la côte est, parfaite pour le lever de soleil. Quelques vagues. Près d''Oyster Bay.',
 'East coast beach, perfect for sunrise. Some waves. Near Oyster Bay.', 20),

('Little Bay Beach', 'dutch', 14.0, 20, 0,
 'Parc de sculptures sous-marines, Sea Trek', 'Sea Trek diving, snorkeling', 'Modéré',
 ARRAY['snorkeling', 'diving', 'unique', 'family'],
 'Parc de sculptures sous-marines unique. Activité Sea Trek (marche sous l''eau avec casque). Excellent snorkeling.',
 'Unique underwater sculpture park. Sea Trek activity (underwater walking with helmet). Excellent snorkeling.', 21),

('Kim Sha Beach', 'dutch', 17.0, 22, 0,
 'Plage calme protégée par récif, proche vie nocturne', 'Bars, restaurants', 'Modéré',
 ARRAY['calm', 'nightlife', 'family'],
 'Plage calme protégée par un récif. Proche des bars et de la vie nocturne de Simpson Bay.',
 'Calm reef-protected beach. Close to Simpson Bay bars and nightlife.', 22);
