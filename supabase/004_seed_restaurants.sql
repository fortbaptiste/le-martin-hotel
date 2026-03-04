-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Restaurants (66 restaurants)                            ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, website, rating, hours, closed_day, reservation_required, dress_code, specialties, vegetarian_options, ambiance, distance_km, driving_time_min, best_for, is_partner, sort_order) VALUES

-- ═══ CUL DE SAC / MONT VERNON (1-5 min) ═══
('La Villa Hibiscus', 'Cul de Sac', 'Gastronomique française', '€€€€', 90, NULL, NULL, 4.9, 'Mar-Sam dîner', 'Dimanche, Lundi', TRUE, 'smart casual', 'Menus dégustation du Chef Bastian Schenk (formé chez Joël Robuchon, Anne-Sophie Pic)', TRUE, 'Intime, gastronomique, jardin tropical', 1.5, 3, ARRAY['romantic', 'honeymoon', 'french', 'special_occasion'], TRUE, 1),
('Sol e Luna', 'Cul de Sac', 'Gastronomique française / Créole', '€€€', 70, '+590 590 29 08 29', NULL, 4.8, 'Dîner', NULL, TRUE, 'smart casual', 'Cuisine française revisitée, produits locaux', TRUE, 'Élégant, vue mer', 1.5, 3, ARRAY['romantic', 'french', 'seafood'], TRUE, 2),
('Le Taitu', 'Cul de Sac', 'Français-Créole', '€€', 35, '+590 590 87 43 23', NULL, 4.7, 'Lun-Sam 11h45-14h15 & 18h30-21h30', 'Dimanche', FALSE, 'casual', 'Cuisine locale fraîche, ambiance décontractée', TRUE, 'Décontracté, local', 1.0, 2, ARRAY['casual', 'local', 'budget'], FALSE, 3),
('Chez Hercule', 'Cul de Sac', 'Créole / BBQ', '€', 15, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Grillades créoles, poisson frais', FALSE, 'Local, simple, authentique', 1.0, 2, ARRAY['budget', 'local', 'family'], FALSE, 4),
('Lulu''s Corner', 'Mont Vernon', 'Café / Brunch', '€', 12, NULL, NULL, 4.6, 'Petit-déjeuner et déjeuner', NULL, FALSE, 'casual', 'Brunch, smoothies, bowls', TRUE, 'Cozy, healthy', 2.0, 4, ARRAY['budget', 'family', 'brunch'], FALSE, 5),
('SAO Asian Factory', 'Mont Vernon', 'Asiatique fusion', '€€', 30, NULL, NULL, 4.3, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Sushi, wok, noodles', TRUE, 'Moderne, asiatique', 2.0, 4, ARRAY['casual', 'family'], FALSE, 6),
('Papadan Pizza', 'Mont Vernon', 'Pizza / Italien', '€', 15, NULL, NULL, 4.4, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Pizzas artisanales', TRUE, 'Familial, décontracté', 2.0, 4, ARRAY['budget', 'family'], FALSE, 7),

-- ═══ ORIENT BAY (5 min) ═══
('L''Atelier', 'Orient Bay', 'Steakhouse français', '€€€', 60, '+590 690 22 10 22', 'latelier-sxm.com', 4.7, 'Tous les jours 17h30-22h30', NULL, TRUE, 'smart casual', 'Viandes maturées, côte de boeuf, tartares', FALSE, 'Chic, terrasse extérieure', 2.5, 5, ARRAY['romantic', 'meat', 'special_occasion'], FALSE, 10),
('Maison Mère', 'Orient Bay', 'Bistrot français', '€€', 40, '+590 690 38 11 39', 'maisonmere.restaurant', 4.6, 'Mer-Lun 18h-22h30', 'Mardi', TRUE, 'smart casual', 'Cuisine française bistrot, cocktails primés, ambiance coloniale', TRUE, 'Colonial, cocktails, élégant', 2.5, 5, ARRAY['romantic', 'french', 'cocktails'], TRUE, 11),
('Kontiki Beach', 'Orient Bay', 'Franco-asiatique fusion', '€€', 40, '+590 690 66 24 25', 'kontiki.restaurant', 4.3, 'Tous les jours 9h-18h', NULL, FALSE, 'casual beach', 'Fusion, beach club, DJ le dimanche', TRUE, 'Beach club, pieds dans le sable', 2.0, 5, ARRAY['beach', 'family', 'sunset'], FALSE, 12),
('KKO Beach', 'Orient Bay', 'Fusion / Nikkei', '€€', 40, '+590 690 75 41 39', NULL, 4.4, 'Tous les jours', NULL, FALSE, 'casual beach', 'Cuisine fusion, DJ sessions le dimanche', TRUE, 'Beach club tendance, DJ', 2.0, 5, ARRAY['beach', 'nightlife', 'sunset'], FALSE, 13),
('Coco Beach', 'Orient Bay', 'Gourmet beach', '€€', 40, NULL, 'cocobeach.restaurant', 4.4, 'Lun, Jeu-Dim 9h30-17h, Ven dîner 19h-21h30', 'Mardi, Mercredi', FALSE, 'casual beach', 'Cuisine beach gourmet, brunch', TRUE, 'Beach chic, pieds dans le sable', 2.0, 5, ARRAY['beach', 'brunch', 'family'], FALSE, 14),
('Bikini Beach', 'Orient Bay', 'Beach casual', '€€', 30, NULL, NULL, 4.2, 'Tous les jours 9h-21h30', NULL, FALSE, 'casual beach', 'Burgers, salades, poisson grillé', TRUE, 'Décontracté, vue mer', 2.0, 5, ARRAY['beach', 'family', 'casual', 'budget'], FALSE, 15),
('Wai Beach', 'Orient Bay', 'Beach dining haut de gamme', '€€€', 60, NULL, NULL, 4.5, 'Tous les jours', NULL, TRUE, 'smart casual', 'Gastronomie beach, musique live vendredi', FALSE, 'Haut de gamme, live music', 2.0, 5, ARRAY['romantic', 'beach', 'sunset', 'nightlife'], FALSE, 16),
('Joa Beach', 'Orient Bay', 'Beach club', '€€', 35, NULL, NULL, 4.3, 'Tous les jours', NULL, FALSE, 'casual beach', 'Beach club avec transats', TRUE, 'Tendance, musique', 2.0, 5, ARRAY['beach', 'nightlife'], FALSE, 17),
('Orange Fever', 'Orient Bay', 'Beach bar', '€', 20, NULL, NULL, 4.2, 'Tous les jours', NULL, FALSE, 'casual beach', 'Cocktails, snacks, ambiance', TRUE, 'Décontracté, fun', 2.0, 5, ARRAY['beach', 'budget', 'nightlife'], FALSE, 18),
('Le Piment', 'Orient Bay', 'Créole', '€€', 30, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine créole authentique', TRUE, 'Local, chaleureux', 2.5, 5, ARRAY['local', 'casual'], FALSE, 19),

-- ═══ GRAND CASE — Fine Dining (10 min) ═══
('Le Pressoir', 'Grand Case', 'Gastronomique française', '€€€€', 100, '+590 690 52 75 95', 'lepressoirsxm.com', 4.6, 'Lun-Sam dîner, 1er service 17h, dernier 22h', 'Dimanche', TRUE, 'smart casual', '"Caribbean Restaurant of the Year" 4 ans de suite. Cuisine française gastronomique dans une maison créole historique.', TRUE, 'Maison créole historique, romantique, élégant', 6.0, 10, ARRAY['romantic', 'honeymoon', 'french', 'special_occasion', 'seafood'], TRUE, 20),
('Le Cottage', 'Grand Case', 'Bistrot chic français', '€€€', 65, '+590 690 56 32 69', 'lecottagesxm.com', 4.7, 'Lun-Sam 18h-22h', 'Dimanche', TRUE, 'smart casual', 'Cuisine française bistrot chic, produits frais', TRUE, 'Chic, intime, terrasse', 6.0, 10, ARRAY['romantic', 'french'], FALSE, 21),
('Le Tastevin', 'Grand Case', 'Gastronomique française', '€€€', 70, NULL, NULL, 4.6, 'Dîner', NULL, TRUE, 'smart casual', 'Haute cuisine française, cave à vins', TRUE, 'Gastronomique, raffiné', 6.0, 10, ARRAY['romantic', 'french', 'special_occasion'], FALSE, 22),
('L''Auberge Gourmande', 'Grand Case', 'Gastronomique française', '€€€', 65, NULL, NULL, 4.5, 'Dîner', NULL, TRUE, 'smart casual', 'Classiques français revisités', TRUE, 'Traditionnel, élégant', 6.0, 10, ARRAY['romantic', 'french'], FALSE, 23),
('Spiga', 'Grand Case', 'Italien créatif', '€€€', 65, '+590 590 52 47 83', 'spigasxm.com', 4.7, 'Lun-Sam 18h-22h', 'Dimanche', TRUE, 'smart casual', 'Pâtes fraîches maison, cuisine italienne créative', TRUE, 'Cour intérieure, romantique, italien raffiné', 6.0, 10, ARRAY['romantic', 'italian', 'special_occasion'], FALSE, 24),
('Ocean 82', 'Grand Case', 'Seafood français', '€€€', 70, NULL, 'ocean82.fr', 4.6, 'Dîner', NULL, TRUE, 'smart casual', 'Fruits de mer, poissons, vue mer', TRUE, 'Vue mer, terrasse, élégant', 6.0, 10, ARRAY['romantic', 'seafood', 'sunset'], FALSE, 25),
('Bistrot Caraïbes', 'Grand Case', 'Français-Caribéen', '€€€', 60, '+590 590 29 08 29', 'bistrot-caraibes.com', 4.7, 'Lun-Dim 18h-22h', NULL, TRUE, 'smart casual', 'Fusion franco-caribéenne, produits locaux', TRUE, 'Terrasse, vue mer, chaleureux', 6.0, 10, ARRAY['romantic', 'french', 'seafood', 'sunset'], TRUE, 26),
('La Villa', 'Grand Case', 'Français-Caribéen élevé', '€€€', 65, '+590 690 50 12 04', 'lavillasxm.com', 4.7, 'Dîner à partir de 17h', 'Mercredi', TRUE, 'smart casual', 'Cuisine française élevée, ambiance raffinée', TRUE, 'Raffiné, vue mer', 6.0, 10, ARRAY['romantic', 'french', 'special_occasion'], FALSE, 27),
('L''Effet Mer', 'Grand Case', 'Seafood français', '€€€', 55, NULL, NULL, 4.5, 'Dîner', NULL, TRUE, 'smart casual', 'Fruits de mer frais, ambiance maritime', TRUE, 'Maritime, front de mer', 6.0, 10, ARRAY['seafood', 'romantic'], FALSE, 28),

-- ═══ GRAND CASE — Casual & Bars ═══
('Calmos Café', 'Grand Case', 'Beach bar & grill', '€€', 30, NULL, NULL, 4.8, 'Toute la journée', NULL, FALSE, 'casual beach', 'Cocktails, grillades, coucher de soleil légendaire', TRUE, 'Pieds dans le sable, sunset, décontracté', 6.0, 10, ARRAY['sunset', 'beach', 'casual', 'cocktails'], FALSE, 30),
('Rainbow Café', 'Grand Case', 'Bar restaurant', '€€', 25, NULL, NULL, 4.4, 'Toute la journée', NULL, FALSE, 'casual', 'Cocktails, ambiance festive', TRUE, 'Festif, coloré', 6.0, 10, ARRAY['nightlife', 'casual'], FALSE, 31),
('Nice SXM', 'Grand Case', 'Français', '€€', 30, NULL, NULL, 4.3, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine française simple et bonne', TRUE, 'Décontracté', 6.0, 10, ARRAY['casual', 'french', 'budget'], FALSE, 32),
('Blue Martini', 'Grand Case', 'Bar cocktails', '€€', 25, NULL, NULL, 4.4, 'Soirée', NULL, FALSE, 'casual', 'Cocktails, musique', FALSE, 'Bar ambiance, soirée', 6.0, 10, ARRAY['nightlife', 'cocktails'], FALSE, 33),

-- ═══ GRAND CASE — Lolos (BBQ créole, €8-14/assiette) ═══
('Sky''s the Limit', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.7, 'Soirée', NULL, FALSE, 'casual', 'Ribs, poulet grillé, langouste, sides créoles. Le plus célèbre des lolos.', FALSE, 'Extérieur, tables en bois, musique, authentique', 6.0, 10, ARRAY['budget', 'local', 'family', 'must_try'], FALSE, 35),
('Talk of the Town', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.6, 'Soirée', NULL, FALSE, 'casual', 'BBQ ribs, poulet, poisson grillé, lobster', FALSE, 'Local, convivial, file d''attente le soir', 6.0, 10, ARRAY['budget', 'local', 'family'], FALSE, 36),
('Rib Shack', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.5, 'Soirée', NULL, FALSE, 'casual', 'Ribs fumées, BBQ', FALSE, 'Authentique, fumoir', 6.0, 10, ARRAY['budget', 'local', 'meat'], FALSE, 37),
('Au Coin des Amis', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.4, 'Soirée', NULL, FALSE, 'casual', 'Grillades créoles', FALSE, 'Local, simple', 6.0, 10, ARRAY['budget', 'local'], FALSE, 38),
('Scooby''s', 'Grand Case', 'BBQ Créole (Lolo)', '€', 10, NULL, NULL, 4.3, 'Soirée', NULL, FALSE, 'casual', 'BBQ pas cher, ambiance locale', FALSE, 'Très local, prix mini', 6.0, 10, ARRAY['budget', 'local'], FALSE, 39),
('Le Ti Coin Créole', 'Grand Case', 'Créole traditionnel', '€', 15, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Plats créoles traditionnels', TRUE, 'Authentique, familial', 6.0, 10, ARRAY['budget', 'local', 'family'], FALSE, 40),

-- ═══ MARIGOT (15 min) ═══
('Le Tropicana', 'Marigot', 'Français élégant', '€€€', 45, '+590 590 87 79 07', NULL, 4.6, 'Mar-Sam 12h-14h30 & 18h-21h30', 'Dimanche, Lundi', TRUE, 'smart casual', '#3 de Marigot sur TripAdvisor. Restaurant préféré de Linda Thornton (cliente régulière).', TRUE, 'Élégant, front de mer', 9.0, 15, ARRAY['romantic', 'french', 'seafood'], TRUE, 41),
('Le Bistro de la Mer', 'Marigot', 'Français-Créole / Pizzas', '€€', 25, '+590 590 29 30 03', NULL, 3.8, 'Tous les jours 9h-22h', NULL, FALSE, 'casual', 'Cuisine franco-créole, pizzas, front de mer Marigot', TRUE, 'Front de mer, décontracté', 9.0, 15, ARRAY['casual', 'family', 'seafood', 'budget'], TRUE, 42),
('Enoch''s Place', 'Marigot', 'Créole local', '€', 12, NULL, NULL, 4.7, 'Petit-déjeuner et déjeuner uniquement', NULL, FALSE, 'casual', 'Marché de Marigot. Incontournable local. Poisson grillé, lambi.', FALSE, 'Marché, local, authentique', 9.0, 15, ARRAY['budget', 'local', 'must_try', 'brunch'], FALSE, 43),
('La Belle Époque', 'Marigot', 'Français classique', '€€€', 50, NULL, NULL, 4.4, 'Déjeuner et dîner', NULL, TRUE, 'smart casual', 'Cuisine française classique en bord de mer', TRUE, 'Classique, front de mer', 9.0, 15, ARRAY['romantic', 'french'], FALSE, 44),
('Le Marocain', 'Marigot', 'Marocain', '€€', 30, NULL, NULL, 4.3, 'Dîner', NULL, TRUE, 'casual', 'Tajines, couscous, pastilla', TRUE, 'Décor marocain, dépaysant', 9.0, 15, ARRAY['casual', 'exotic'], FALSE, 45),
('Rosemary''s', 'Marigot', 'Créole / International', '€€', 25, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine créole et internationale', TRUE, 'Local, chaleureux', 9.0, 15, ARRAY['casual', 'local', 'family'], FALSE, 46),

-- ═══ ANSE MARCEL (10 min) ═══
('Le Bistro du Port', 'Anse Marcel', 'Français / Marina', '€€', 35, NULL, NULL, 4.3, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine française face à la marina', TRUE, 'Marina, bateaux, calme', 5.0, 10, ARRAY['casual', 'family', 'seafood'], FALSE, 50),

-- ═══ FRIAR''S BAY (12 min) ═══
('Kali''s Beach Bar', 'Friar''s Bay', 'BBQ / Créole', '€', 15, NULL, NULL, 4.6, 'Toute la journée', NULL, FALSE, 'casual beach', 'Légendaire. Bush Rum maison. Full Moon Party mensuelle (feu de camp, reggae).', FALSE, 'Légendaire, pieds dans le sable, bohème', 10.0, 15, ARRAY['beach', 'nightlife', 'local', 'must_try', 'sunset'], FALSE, 55),
('978 Beach Lounge', 'Friar''s Bay', 'Caribéen fusion', '€€', 30, NULL, NULL, 4.4, 'Toute la journée', NULL, FALSE, 'casual beach', 'Cuisine caribéenne fusion, cocktails', TRUE, 'Tendance, beach, moderne', 10.0, 15, ARRAY['beach', 'casual', 'cocktails'], FALSE, 56),
('Friar''s Bay Beach Café', 'Friar''s Bay', 'Français', '€€', 30, NULL, NULL, 4.3, 'Déjeuner', NULL, FALSE, 'casual beach', 'Classique français sur le sable', TRUE, 'Pieds dans le sable, classique', 10.0, 15, ARRAY['beach', 'french', 'casual'], FALSE, 57),

-- ═══ TERRES BASSES / BAIE LONGUE (25 min) ═══
('La Samanna - L''Oursin', 'Baie Longue', 'Gastronomique méditerranéen', '€€€€', 120, NULL, NULL, 4.5, 'Dîner', NULL, TRUE, 'smart casual', 'Restaurant gastronomique du Belmond La Samanna. Vue mer spectaculaire.', TRUE, 'Luxe absolu, vue mer, Belmond', 17.0, 25, ARRAY['romantic', 'honeymoon', 'special_occasion', 'french', 'sunset'], TRUE, 60),
('La Samanna - Laplaj', 'Baie Longue', 'Beach fusion', '€€€', 60, NULL, NULL, 4.4, 'Déjeuner', NULL, TRUE, 'casual beach', 'Déjeuner pieds dans le sable au Belmond La Samanna', TRUE, 'Luxe, plage, Belmond', 17.0, 25, ARRAY['beach', 'romantic', 'special_occasion'], TRUE, 61),

-- ═══ SIMPSON BAY / MAHO (25 min) ═══
('SkipJack''s', 'Simpson Bay', 'Seafood / Grill', '€€', 35, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Poisson frais du jour, ambiance marina', TRUE, 'Marina, décontracté', 17.0, 25, ARRAY['seafood', 'casual', 'family'], FALSE, 65),
('IZI Ristorante', 'Maho', 'Italien', '€€€', 50, NULL, NULL, 4.4, 'Dîner', NULL, TRUE, 'smart casual', 'Cuisine italienne haut de gamme', TRUE, 'Élégant, italien', 20.0, 28, ARRAY['italian', 'romantic'], FALSE, 66),
('Sunset Bar & Grill', 'Maho', 'Grill / Bar', '€€', 25, NULL, NULL, 4.3, 'Toute la journée', NULL, FALSE, 'casual', 'Le bar emblématique de Maho Beach pour voir les avions atterrir', TRUE, 'Avions, iconique, fun', 20.0, 28, ARRAY['must_try', 'family', 'casual', 'nightlife'], FALSE, 67),
('Bamboo House', 'Maho', 'Asiatique', '€€', 30, NULL, NULL, 4.2, 'Dîner', NULL, FALSE, 'casual', 'Cuisine asiatique, sushis', TRUE, 'Moderne, asiatique', 20.0, 28, ARRAY['casual', 'exotic'], FALSE, 68),

-- ═══ PHILIPSBURG (20 min) ═══
('Ocean Lounge', 'Philipsburg', 'International', '€€€', 50, NULL, NULL, 4.4, 'Déjeuner et dîner', NULL, TRUE, 'smart casual', 'Vue sur Great Bay, boardwalk', TRUE, 'Vue mer, boardwalk, élégant', 15.0, 22, ARRAY['romantic', 'seafood', 'sunset'], FALSE, 70),
('Lazy Lizard', 'Philipsburg', 'Beach bar', '€', 15, NULL, NULL, 4.5, 'Toute la journée', NULL, FALSE, 'casual beach', 'Beach bar iconique du boardwalk', TRUE, 'Boardwalk, décontracté, fun', 15.0, 22, ARRAY['beach', 'budget', 'casual'], FALSE, 71),

-- ═══ PINEL ISLAND (5 min bateau) ═══
('Le Karibuni', 'Île Pinel', 'Créole / Seafood', '€€', 30, NULL, NULL, 4.5, '10h-16h', NULL, FALSE, 'casual beach', 'Restaurant sur l''île Pinel. Langouste grillée, pieds dans le sable, vue Anguilla.', FALSE, 'Île déserte, pieds dans le sable, paradisiaque', 1.7, NULL, ARRAY['beach', 'seafood', 'must_try', 'romantic'], FALSE, 75),
('Yellow Beach', 'Île Pinel', 'Créole / Beach', '€€', 25, NULL, NULL, 4.4, '10h-16h', NULL, FALSE, 'casual beach', 'Second restaurant de l''île Pinel. Vue sur St-Barth.', FALSE, 'Île, plage, vue St-Barth', 1.7, NULL, ARRAY['beach', 'budget', 'family'], FALSE, 76);
