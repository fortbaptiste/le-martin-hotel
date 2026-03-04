-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Chambres & Suites du Le Martin Boutique Hotel          ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO rooms (slug, name, category, size_m2, bed_type, view_fr, view_en, floor, terrace, capacity_adults, capacity_children, description_fr, description_en, design_style, amenities, accessibility, is_communicating, communicating_with, price_low_season, price_high_season, sort_order) VALUES

-- MARIUS
('marius', 'Suite Marius', 'deluxe', 34, 'Queen (ou 2 lits simples)',
 'Vue jardin', 'Garden view',
 'Rez-de-chaussée', 'Grande terrasse adjacente à la piscine',
 2, 1,
 'Suite au rez-de-chaussée avec accès privé, adjacente à la piscine. Design minimaliste aux tons terre, noyer, terrazzo et marbre. Ambiance de studio indépendant. Seule suite accessible PMR. Lit bébé disponible (0-2 ans), lit d''appoint possible (2-17 ans).',
 'Ground-floor suite with private entrance, adjacent to the pool. Minimalist design with clean earth tones, walnut, terrazzo and marble. Feels like a self-contained studio. Only wheelchair-accessible suite. Cot available (0-2), extra bed possible (2-17).',
 'Minimaliste, tons terre, noyer, terrazzo, marbre',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Service de blanchisserie"]',
 TRUE, FALSE, NULL,
 294.00, 470.00, 1),

-- PIERRE
('pierre', 'Chambre Pierre', 'prestige', 22, 'Queen',
 'Vue jardin tropical avec aperçu mer', 'Tropical garden view with ocean glimpses',
 'Étage supérieur', 'Petite terrasse couverte',
 2, 2,
 'Chambre intime et bucolique à l''étage. Décoration minimaliste originale en bois, pierre, marbre et feuillage. Ambiance feutrée avec des senteurs subtiles de mousse. Fauteuil confortable inclus. Communicante avec la Suite Marcelle pour former la Suite Familiale.',
 'Intimate, bucolic upper-level room. Original minimalist decoration in wood, stone, marble and foliage. Hushed atmosphere with subtle moss scents. Easy chair included. Connects with Marcelle Suite to form the Family Suite.',
 'Original, feutré, bois, pierre, marbre, feuillage, bucolique',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Fauteuil confortable"]',
 FALSE, TRUE, 'marcelle',
 294.00, 410.00, 2),

-- MARCELLE
('marcelle', 'Suite Marcelle', 'deluxe', 30, 'Queen',
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Grande terrasse vue jardin',
 2, 2,
 'Suite lumineuse à l''étage avec vue mer. Décoration minimaliste originale en bois, pierre, marbre et feuillage. "Une chambre au bord d''une clairière, réveillée par la douce chaleur d''un rayon de soleil." Communicante avec la Chambre Pierre pour former la Suite Familiale.',
 'Bright upper-level suite with ocean view. Original minimalist decoration in wood, stone, marble and foliage. "A room at the edge of a clearing, awakened by the gentle warmth of a sunbeam." Connects with Pierre Room to form the Family Suite.',
 'Lumineux, minimaliste, bois, pierre, marbre, feuillage',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, TRUE, 'pierre',
 294.00, 470.00, 3),

-- RENÉ
('rene', 'Suite René', 'deluxe', 41, 'Queen',
 'Vue mer panoramique', 'Panoramic ocean view',
 'Étage supérieur', 'Grande terrasse avec salon, table, chaises, bains de soleil',
 2, 0,
 'La plus spacieuse de l''hôtel (41 m²). Vue mer panoramique. "L''ambiance calme et feutrée d''un atelier d''artiste" — peintures éparses, jeux d''ombre et de lumière. Une ode à la rêverie. Idéale pour les lunes de miel. La mer murmure à votre fenêtre au réveil.',
 'The most spacious suite in the hotel (41 m²). Panoramic ocean view. "The quiet, hushed ambience of an artist''s studio" — scattered paintings, interplay of shadow and light. An ode to reverie. Ideal for honeymoons. The sea whispers at your window as you greet the day.',
 'Atelier d''artiste, peintures, jeux d''ombre et lumière, rêverie',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Salon terrasse avec mobilier"]',
 FALSE, FALSE, NULL,
 329.00, 540.00, 4),

-- MARTHE
('marthe', 'Suite Marthe', 'deluxe', 28, 'Queen',
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Terrasse vue mer avec table, chaises, bains de soleil',
 2, 0,
 'Suite intime et chaleureuse avec vue mer. Décoration chic et décontractée de style parisien. Terrasse avec vue sur l''océan pour des moments de détente parfaits.',
 'Intimate and warm suite with ocean view. Chic, relaxed Parisian-style decor. Terrace with ocean views for perfect moments of relaxation.',
 'Chic parisien, décontracté, intime, chaleureux',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, FALSE, NULL,
 294.00, 470.00, 5),

-- GEORGETTE
('georgette', 'Suite Georgette', 'deluxe', 28, 'Queen',
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Grande terrasse vue jardin',
 2, 0,
 'Suite élégante avec vue mer et grande terrasse sur le jardin. Décoration chic et décontractée de style parisien. Un havre de paix élégant baigné de lumière naturelle.',
 'Elegant suite with ocean view and large garden terrace. Chic, relaxed Parisian-style decor. An elegant haven of peace bathed in natural light.',
 'Élégant, chic parisien, décontracté, lumineux',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, FALSE, NULL,
 294.00, 470.00, 6),

-- FAMILY SUITE (Marcelle + Pierre)
('family-suite', 'Suite Familiale (Marcelle & Pierre)', 'family_suite', 52, '2 Queen',
 'Vue mer + vue jardin', 'Ocean view + garden view',
 'Étage supérieur', '2 grandes terrasses couvertes et meublées',
 4, 2,
 'Combinaison des 2 chambres communicantes Marcelle (30 m²) et Pierre (22 m²) pour former une suite familiale de 52 m². 2 chambres, 2 salles de bain, 2 terrasses. Jusqu''à 3 lits d''appoint possibles. Idéale pour les familles.',
 'Combination of the connecting Marcelle (30 m²) and Pierre (22 m²) rooms forming a 52 m² family suite. 2 bedrooms, 2 bathrooms, 2 terraces. Up to 3 extra beds available. Ideal for families.',
 'Familial, spacieux, double espace, 2 ambiances',
 '["Tout Marcelle + tout Pierre", "2 salles de bain", "2 terrasses", "Jusqu''à 3 lits d''appoint"]',
 FALSE, FALSE, NULL,
 382.00, 750.00, 7);
