-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Activités & Excursions                                 ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO activities (name_fr, name_en, category, operator, location, distance_km, price_from_eur, price_to_eur, duration, phone, website, description_fr, description_en, best_for, booking_required, sort_order) VALUES

-- ═══ SPORTS NAUTIQUES ═══
('Jet ski', 'Jet ski', 'water_sport', 'Bikini Watersports', 'Orient Bay', 2.0, 70, 110, '30-60 min', NULL, 'bikini-watersports.com',
 'Location de jet ski sur Orient Bay. 70€/30min, 110€/1h.', 'Jet ski rental on Orient Bay. €70/30min, €110/1h.',
 ARRAY['adventure', 'couples'], FALSE, 1),

('Kitesurf — cours', 'Kitesurfing — lessons', 'water_sport', 'SXM Kiteschool', 'Cul de Sac (Pinel Jetty)', 0.5, 150, 417, '2-6h', NULL, 'sxmkiteschool.com',
 'École de kitesurf à 500m de l''hôtel ! Cours 2h : 162$, 4h : 293$, initiation 6h : 417$. Location : 103$/jour.',
 'Kitesurfing school 500m from hotel! 2h lesson: $162, 4h: $293, 6h initiation: $417. Rental: $103/day.',
 ARRAY['adventure', 'sport'], TRUE, 2),

('Kitesurf & Windsurf', 'Kitesurf & Windsurf', 'water_sport', 'Wind Adventures', 'Orient Bay', 2.0, 55, 350, '1h-1 semaine', NULL, 'wind-adventures.com',
 'Cours kitesurf, windsurf et location. Windsurf : 60$/2h cours, 86$/jour location. Kite cruises disponibles.',
 'Kitesurf, windsurf lessons and rental. Windsurf: $60/2h lesson, $86/day rental. Kite cruises available.',
 ARRAY['adventure', 'sport'], TRUE, 3),

('Parasailing', 'Parasailing', 'water_sport', 'Bikini Watersports', 'Orient Bay', 2.0, 50, 100, '12-15 min', NULL, 'bikini-watersports.com',
 'Vol en parasailing au-dessus d''Orient Bay. 50-100€/pers, 12-15 min de vol.',
 'Parasailing flight above Orient Bay. €50-100/person, 12-15 min flight.',
 ARRAY['adventure', 'family', 'couples'], FALSE, 4),

('Flyboard', 'Flyboard', 'water_sport', 'Bikini Watersports', 'Orient Bay', 2.0, 100, 100, '20 min', NULL, 'bikini-watersports.com',
 'Flyboard sur Orient Bay. 100€/20 min.',
 'Flyboard on Orient Bay. €100/20 min.',
 ARRAY['adventure'], TRUE, 5),

('Plongée sous-marine', 'Scuba diving', 'water_sport', 'Bubble Shop', 'Hope Estate (route Orient Bay)', 3.0, 55, 470, '1-4h', NULL, 'bubbleshopsxm.com',
 'Centre PADI & CMAS. Sites : Creole Rock, Tintamarre. Baptême ~60€, exploration ~55€, PADI Open Water ~470$. Mar-Sam 9h-13h.',
 'PADI & CMAS center. Sites: Creole Rock, Tintamarre. Discovery dive ~€60, exploration ~€55, PADI Open Water ~$470. Tue-Sat 9am-1pm.',
 ARRAY['adventure', 'nature', 'couples'], TRUE, 6),

('Snorkeling guidé', 'Guided snorkeling', 'water_sport', 'Caribbean Paddling', 'Cul de Sac', 0.5, 85, 85, '2-3h', NULL, 'caribbeanpaddling.com',
 'Kayak + snorkeling guidé vers Pinel Island. 85$/pers. Départ Cul de Sac.',
 'Guided kayak + snorkeling to Pinel Island. $85/person. Departure from Cul de Sac.',
 ARRAY['nature', 'family', 'couples'], TRUE, 7),

('Massage à la plage', 'Beach massage', 'wellness', 'Colibri Massage SXM', 'Orient Bay (KKO Beach & Coco Beach)', 2.0, 60, 120, '30-60 min', NULL, 'colibri-massage-sxm.com',
 '#1 activité Orient Bay (TripAdvisor). Techniques californiennes, thaï, reiki. 20 ans d''expérience.',
 '#1 activity in Orient Bay (TripAdvisor). Californian, Thai, Reiki techniques. 20 years experience.',
 ARRAY['wellness', 'couples', 'romantic'], TRUE, 8),

-- ═══ EXCURSIONS EN BATEAU ═══
('Ferry vers Île Pinel', 'Ferry to Pinel Island', 'island_trip', 'Ferry Cul de Sac', 'Dock Cul de Sac', 0.5, 10, 10, '5 min traversée, demi-journée sur place', NULL, NULL,
 'Ferry toutes les 30 min, 10h-16h. 10€ A/R. Cash uniquement. Dernier retour 16h30. Snorkeling, 2 restaurants, rando colline.',
 'Ferry every 30 min, 10am-4pm. €10 round trip. Cash only. Last return 4:30pm. Snorkeling, 2 restaurants, hilltop hike.',
 ARRAY['must_do', 'family', 'snorkeling', 'nature', 'couples'], FALSE, 10),

('Tintamarre Express', 'Tintamarre Express', 'island_trip', 'Tintamarre Express', 'Dock Cul de Sac', 0.5, 25, 25, 'Journée (9h30-15h30)', '0690 15 57 40', 'tintamarreexpress.com',
 'Excursion vers l''île inhabitée de Tintamarre. 25€ A/R. Départ 9h30, retour 15h30. Tortues, raies, récif préservé. Réservation obligatoire. APPORTER eau et nourriture.',
 'Trip to uninhabited Tintamarre Island. €25 round trip. Departs 9:30am, returns 3:30pm. Turtles, rays, pristine reef. Booking required. BRING water and food.',
 ARRAY['nature', 'snorkeling', 'adventure'], TRUE, 11),

('Ferry vers Anguilla', 'Ferry to Anguilla', 'island_trip', 'Marigot Ferry Terminal', 'Marigot', 9.0, 60, 70, 'Journée (20 min traversée)', '+590 590 87 10 68', 'anguillaferrytimes.com',
 'Ferry toutes les 30-45 min, 8h30-18h. 30$ aller + 7€ taxe départ. Passeport OBLIGATOIRE. 20 min traversée. Anguilla : Rendezvous Bay, Shoal Bay, restaurants world-class.',
 'Ferry every 30-45 min, 8:30am-6pm. $30 one-way + €7 departure tax. Passport REQUIRED. 20 min crossing. Anguilla: Rendezvous Bay, Shoal Bay, world-class restaurants.',
 ARRAY['must_do', 'beach', 'romantic', 'adventure'], FALSE, 12),

('Ferry vers Saint-Barth', 'Ferry to St. Barths', 'island_trip', 'Voyager / Great Bay Express', 'Marigot ou Philipsburg', 9.0, 90, 162, 'Journée (45-60 min traversée)', NULL, 'voy12.com',
 'Voyager depuis Marigot : ECO 108€ A/R, SMART 131€ A/R, BUSINESS 162€ A/R (1h). Great Bay Express depuis Philipsburg : 90$ journée (45min). Avion depuis Grand Case : 15 min, 100-150$ aller. Passeport obligatoire.',
 'Voyager from Marigot: ECO €108 RT, SMART €131 RT, BUSINESS €162 RT (1h). Great Bay Express from Philipsburg: $90 day trip (45min). Plane from Grand Case: 15 min, $100-150 one-way. Passport required.',
 ARRAY['luxury', 'shopping', 'romantic', 'must_do'], TRUE, 13),

('Catamaran partagé', 'Shared catamaran cruise', 'boat_trip', 'Divers opérateurs', 'Simpson Bay Marina', 17.0, 95, 195, '4-8h', NULL, NULL,
 'Croisières catamaran partagées. 95-195$/pers. Snorkeling, open bar, déjeuner inclus selon formule.',
 'Shared catamaran cruises. $95-195/person. Snorkeling, open bar, lunch included depending on package.',
 ARRAY['family', 'couples', 'snorkeling'], TRUE, 14),

('Croisière coucher de soleil', 'Sunset cruise', 'boat_trip', 'Divers opérateurs', 'Simpson Bay / Marigot', 9.0, 45, 150, '2-3h', NULL, NULL,
 'Croisières coucher de soleil. 45-150$/pers. Cocktails, canapés, musique.',
 'Sunset cruises. $45-150/person. Cocktails, canapés, music.',
 ARRAY['romantic', 'honeymoon', 'sunset'], TRUE, 15),

('Bateau privé charter', 'Private boat charter', 'boat_trip', 'Divers opérateurs', 'Simpson Bay / Marigot', 9.0, 600, 2500, '4-8h', NULL, NULL,
 'Location bateau privé avec skipper. Demi-journée : 600-900€, journée : 1000-2500€. Destinations : Pinel, Tintamarre, Anguilla, St-Barth.',
 'Private boat hire with skipper. Half-day: €600-900, full day: €1000-2500. Destinations: Pinel, Tintamarre, Anguilla, St Barth.',
 ARRAY['luxury', 'romantic', 'honeymoon', 'adventure'], TRUE, 16),

('Pêche au gros', 'Deep sea fishing', 'boat_trip', 'St Maarten Fishing Charters', 'Simpson Bay Marina', 17.0, 110, 1400, '4-12h', NULL, NULL,
 'Pêche sportive. Partagé : dès 110$/pers. Privé : 400-1400$ le bateau.',
 'Sport fishing. Shared: from $110/person. Private: $400-1400 per boat.',
 ARRAY['adventure', 'sport'], TRUE, 17),

-- ═══ ACTIVITÉS TERRESTRES ═══
('Randonnée Pic Paradis', 'Pic Paradis hike', 'land_activity', NULL, 'Loterie Farm', 8.0, 10, 10, '2-2h30', NULL, 'loteriefarm.com',
 'Point culminant de l''île (424m). Entrée Loterie Farm : 10€. Difficulté modérée. Vue panoramique 360° sur l''île et les îles voisines.',
 'Highest point on the island (424m). Loterie Farm entry: €10. Moderate difficulty. 360° panoramic view of the island and neighbors.',
 ARRAY['hiking', 'nature', 'adventure', 'photography'], FALSE, 20),

('Loterie Farm — Zipline', 'Loterie Farm — Zipline', 'land_activity', 'Loterie Farm', 'Pic Paradis', 8.0, 55, 85, '1-2h', NULL, 'loteriefarm.com',
 'Tyrolienne dans la canopée tropicale. Fly Zone : 55-65€, Extreme : 85€. Cabana pool : 190€, Cabanita : 40€.',
 'Zipline through tropical canopy. Fly Zone: €55-65, Extreme: €85. Cabana pool: €190, Cabanita: €40.',
 ARRAY['adventure', 'family', 'nature'], TRUE, 21),

('Rainforest Adventures — Zipline', 'Rainforest Adventures — Zipline', 'land_activity', 'Rockland Estate', 'Côté hollandais', 15.0, 52, 139, '2-3h', NULL, 'rainforestadventure.com',
 'All Rides Pass : 139$. Flying Dutchman (tyrolienne géante) : 99$. Sky Explorer (téléphérique) : 52$.',
 'All Rides Pass: $139. Flying Dutchman (giant zipline): $99. Sky Explorer (chairlift): $52.',
 ARRAY['adventure', 'family'], TRUE, 22),

('Butterfly Farm', 'Butterfly Farm', 'cultural', 'Butterfly Farm', 'Route d''Orient Bay', 2.5, 15, 15, '45 min', NULL, NULL,
 'Ferme aux papillons tropicaux. ~15$/pers. Retour illimité avec le même billet. 9h-15h30.',
 'Tropical butterfly farm. ~$15/person. Unlimited returns with same ticket. 9am-3:30pm.',
 ARRAY['family', 'children', 'nature'], FALSE, 23),

('Fort Louis', 'Fort Louis', 'cultural', NULL, 'Marigot', 9.0, 0, 0, '45 min-1h', NULL, NULL,
 'Fort historique surplombant Marigot et la baie. Entrée gratuite. Vue panoramique. 15 min de montée.',
 'Historic fort overlooking Marigot and the bay. Free entry. Panoramic view. 15 min climb.',
 ARRAY['cultural', 'photography', 'family', 'free'], FALSE, 24),

('Dégustation de rhum — Topper''s', 'Rum tasting — Topper''s', 'cultural', 'Topper''s Rhum', 'Côté hollandais', 15.0, 24, 33, '90 min', NULL, 'toppers.sx',
 'Dégustation illimitée de 20+ rhums. 24-33$/pers. 90 min. Histoire du rhum caribéen.',
 'Unlimited tasting of 20+ rums. $24-33/person. 90 min. History of Caribbean rum.',
 ARRAY['cultural', 'couples', 'must_try'], TRUE, 25),

('Cours de cuisine créole', 'Creole cooking class', 'cultural', 'Creole Culinary Classroom', 'Saint-Martin', 8.0, 109, 139, '3-4h', NULL, 'creoleculinaryclassroom.com',
 'Apprenez à cuisiner créole avec des ingrédients locaux. 109-139$/pers.',
 'Learn Creole cooking with local ingredients. $109-139/person.',
 ARRAY['cultural', 'couples', 'family', 'foodie'], TRUE, 26),

('Tour en quad / ATV', 'ATV / Quad tour', 'land_activity', 'Divers opérateurs', 'Saint-Martin', 10.0, 70, 95, '2-3h', NULL, NULL,
 'Tour de l''île en quad. 70-95$/pers.',
 'Island tour by ATV/quad. $70-95/person.',
 ARRAY['adventure'], TRUE, 27),

('Équitation sur la plage', 'Horseback riding on the beach', 'land_activity', NULL, 'Côté hollandais', 15.0, 75, 75, '1-2h', NULL, NULL,
 'Balade à cheval sur la plage. ~75$/pers.',
 'Horseback riding on the beach. ~$75/person.',
 ARRAY['romantic', 'nature', 'couples'], TRUE, 28),

('Tour en hélicoptère', 'Helicopter tour', 'land_activity', 'Corail Hélicoptères', 'Aéroport', 15.0, 115, 300, '15-30 min', NULL, 'corailhelico-mu.com',
 'Survol de l''île en hélicoptère. À partir de 115$/pers.',
 'Helicopter flight over the island. From $115/person.',
 ARRAY['luxury', 'romantic', 'honeymoon', 'photography'], TRUE, 29),

-- ═══ WELLNESS ═══
('Yoga privé à l''hôtel', 'Private yoga at hotel', 'wellness', 'Le Martin Hotel', 'Hôtel', 0, 110, 110, '1h', NULL, NULL,
 'Cours privé au jardin, sur paddle ou au bord de la piscine. 110€/séance.',
 'Private class in garden, on paddleboard or poolside. €110/session.',
 ARRAY['wellness', 'couples'], TRUE, 30),

('Spa Gaia', 'Gaia Spa', 'wellness', 'Gaia Spa', 'Cul de Sac', 1.5, 80, 200, '1-2h', NULL, NULL,
 'Spa à proximité de l''hôtel. Massages, soins du visage, soins corporels.',
 'Spa near the hotel. Massages, facials, body treatments.',
 ARRAY['wellness', 'couples', 'romantic'], TRUE, 31),

-- ═══ SHOPPING ═══
('Marché de Marigot', 'Marigot Market', 'shopping', NULL, 'Marigot', 9.0, 0, 0, '1-2h', NULL, NULL,
 'Marché ouvert tous les jours sauf dimanche, 8h-13h. Meilleurs jours : mercredi et samedi (marché complet avec poisson, fruits, fermiers). Épices, rhum arrangé, artisanat.',
 'Open market daily except Sunday, 8am-1pm. Best days: Wednesday and Saturday (full market with fish, produce, farmers). Spices, rum, crafts.',
 ARRAY['cultural', 'family', 'shopping', 'free'], FALSE, 35),

('Shopping duty-free Philipsburg', 'Duty-free shopping Philipsburg', 'shopping', NULL, 'Philipsburg', 15.0, 0, 0, '2-4h', NULL, NULL,
 'Front Street : 1,5 km de boutiques duty-free. Bijoux (Cartier, Rolex, Dior), parfums, électronique, mode. Guavaberry Emporium pour la liqueur locale.',
 'Front Street: 1.5 km of duty-free shops. Jewelry (Cartier, Rolex, Dior), perfumes, electronics, fashion. Guavaberry Emporium for local liqueur.',
 ARRAY['shopping', 'luxury'], FALSE, 36),

-- ═══ VIE NOCTURNE ═══
('Casino Royale', 'Casino Royale', 'nightlife', 'Casino Royale', 'Maho Village', 20.0, 0, 0, 'Soirée', NULL, NULL,
 'Plus grand casino de l''île : 2000 m², 400+ machines, 21 tables. Côté hollandais.',
 'Largest casino on the island: 21,000 sq ft, 400+ slots, 21 tables. Dutch side.',
 ARRAY['nightlife'], FALSE, 40),

('Full Moon Party — Kali''s', 'Full Moon Party — Kali''s', 'nightlife', 'Kali''s Beach Bar', 'Friar''s Bay', 10.0, 0, 0, 'Soirée mensuelle', NULL, NULL,
 'Fête de la pleine lune mensuelle à Kali''s Beach Bar. Feu de camp, reggae, Bush Rum. Gratuit.',
 'Monthly full moon party at Kali''s Beach Bar. Bonfire, reggae, Bush Rum. Free.',
 ARRAY['nightlife', 'local', 'must_try', 'free'], FALSE, 41);
