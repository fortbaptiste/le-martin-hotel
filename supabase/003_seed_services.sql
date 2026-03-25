-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Services du Le Martin Boutique Hotel                   ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO hotel_services (slug, name_fr, name_en, category, description_fr, description_en, price_eur, price_note, is_complimentary, sort_order) VALUES

-- INCLUS (gratuit)
('breakfast', 'Petit-déjeuner fait maison', 'Homemade breakfast', 'dining',
 'Servi au bord de la piscine, 8h-10h. Buffet froid (viennoiseries, pains artisanaux, confitures maison mangue/passion, pâte chocolat-noisette maison) + carte chaude (Martin''s Bagel, avocado toast, gaufres butternut au saumon, toasts healthy). Jus frais pressés, cappuccinos.',
 'Served poolside, 8am-10am. Cold buffet (French pastries, artisanal breads, homemade mango/passion fruit jams, homemade chocolate-hazelnut spread) + hot menu (Martin''s Bagel, avocado toast, butternut waffles with salmon, healthy toasts). Fresh-squeezed juices, cappuccinos.',
 0, 'Inclus dans le tarif', TRUE, 1),

('pool', 'Piscine chauffée eau de mer', 'Heated saltwater pool', 'activity',
 'Piscine chauffée à l''eau de mer avec entrée par marches, palmier central. Accès 24h/24. Parasols, bains de soleil, bouées.',
 'Heated saltwater pool with step entry, central palm tree. 24/7 access. Parasols, sunloungers, pool rings.',
 0, 'Inclus', TRUE, 2),

('kayaks', 'Kayaks', 'Kayaks', 'activity',
 'Kayaks en libre-service. Petit dock à 1 minute à pied de l''hôtel. Idéal pour rejoindre l''Île Pinel (20-25 min de pagaie).',
 'Complimentary kayaks. Small dock 1 minute walk from hotel. Perfect for paddling to Pinel Island (20-25 min).',
 0, 'Inclus', TRUE, 3),

('paddle', 'Stand-up paddle (SUP)', 'Stand-up paddle (SUP)', 'activity',
 'Planches de paddle en libre-service au petit dock de l''hôtel (1 min à pied).',
 'Complimentary stand-up paddle boards at the hotel''s small dock (1 min walk).',
 0, 'Inclus', TRUE, 4),

('snorkeling', 'Équipement de snorkeling', 'Snorkeling gear', 'activity',
 'Masques, tubas et palmes disponibles gratuitement.',
 'Masks, snorkels and fins available free of charge.',
 0, 'Inclus', TRUE, 5),

('wifi', 'WiFi haut débit', 'High-speed WiFi', 'room_extra',
 'WiFi gratuit dans toutes les chambres et espaces communs.',
 'Free WiFi in all rooms and common areas.',
 0, 'Inclus', TRUE, 7),

('parking', 'Parking privé', 'Private parking', 'transport',
 'Parking privé gratuit sur place.',
 'Free private on-site parking.',
 0, 'Inclus', TRUE, 8),

('honesty-bar', 'Honesty Bar', 'Honesty Bar', 'dining',
 'Bar en libre-service toute la journée et en soirée. G&T, bière, vin, digestifs, planches de fromages et charcuterie. Les consommations sont ajoutées à la note de chambre.',
 'Self-service bar throughout the day and evening. G&T, beer, wine, nightcaps, cheese and charcuterie boards. Extras charged to room.',
 0, 'Self-service, facturé à la chambre', FALSE, 9),

('concierge', 'Service conciergerie', 'Concierge service', 'concierge',
 'Marion et Emmanuel organisent personnellement vos restaurants, activités, excursions et transferts. Recommandations sur mesure.',
 'Marion and Emmanuel personally arrange your restaurants, activities, excursions and transfers. Bespoke recommendations.',
 0, 'Inclus', TRUE, 10),

('tea-coffee', 'Thé et café en libre-service', 'Self-service tea and coffee', 'dining',
 'Thé et café disponibles en libre-service toute la journée dans les espaces communs.',
 'Tea and coffee available self-service throughout the day in common areas.',
 0, 'Inclus', TRUE, 11),

('beach-bags', 'Sacs de plage et serviettes', 'Beach bags and towels', 'room_extra',
 'Sacs de plage en paille et serviettes de plage fournis dans chaque chambre.',
 'Straw beach bags and beach towels provided in each room.',
 0, 'Inclus', TRUE, 12),

('boutique', 'Boutique Le Martin', 'Le Martin Shop', 'concierge',
 'Petite boutique sur place avec articles Le Martin, crème solaire, accessoires.',
 'On-site designer store with Le Martin branded items, sunscreen, accessories.',
 0, 'Prix selon articles', FALSE, 13),

-- PAYANTS
('shuttle', 'Navette aéroport / port', 'Airport / port shuttle', 'transport',
 'Transfert privé depuis/vers l''aéroport Princess Juliana (SXM, environ 1h de route) ou l''aéroport Grand Case (SFG, 10 min) ou le port de Marigot.',
 'Private transfer to/from Princess Juliana Airport (SXM, approx. 1 hour drive) or Grand Case Airport (SFG, 10 min) or Marigot port.',
 70.00, 'Par trajet (aller simple) — 140€ aller-retour', FALSE, 20),

('massage-solo', 'Massage individuel (1h)', 'Individual massage (1h)', 'wellness',
 'Massage d''une heure en chambre. Différentes techniques disponibles. Réservation 24h à l''avance.',
 'One-hour in-room massage. Various techniques available. 24h advance booking required.',
 165.00, 'Par séance', FALSE, 21),

('massage-couple', 'Massage en duo (1h)', 'Couples massage (1h)', 'wellness',
 'Massage en duo d''une heure, en chambre. Réservation 24h à l''avance.',
 'One-hour couples massage, in-room. 24h advance booking required.',
 330.00, 'Par séance', FALSE, 22),

('yoga', 'Cours de yoga privé (1h)', 'Private yoga class (1h)', 'wellness',
 'Cours de yoga privé d''une heure — au jardin, sur paddle ou au bord de la piscine.',
 'One-hour private yoga class — in the garden, on paddle board or poolside.',
 110.00, 'Par séance', FALSE, 23),

('facial', 'Soin visage Carita', 'Carita facial treatment', 'wellness',
 'Soin du visage professionnel par Carita. Réservation 24h à l''avance.',
 'Professional Carita facial treatment. 24h advance booking required.',
 180.00, 'Par séance', FALSE, 24),

('coaching', 'Coaching sportif privé (1h)', 'Private coaching session (1h)', 'wellness',
 'Séance de coaching sportif privée d''une heure — à l''hôtel ou en découverte de l''île.',
 'One-hour private coaching session — at the hotel or discovering the island.',
 110.00, 'Par séance', FALSE, 25),

('champagne', 'Champagne en chambre', 'Champagne in room', 'room_extra',
 'Bouteille de champagne déposée en chambre.',
 'Bottle of champagne placed in room.',
 70.00, 'Par bouteille', FALSE, 26),

('flowers', 'Bouquet de fleurs en chambre', 'Flower bouquet in room', 'room_extra',
 'Bouquet de fleurs fraîches déposé en chambre.',
 'Fresh flower bouquet placed in room.',
 48.00, 'Par bouquet', FALSE, 27),

('breakfast-room', 'Petit-déjeuner en chambre', 'In-room breakfast', 'dining',
 'Petit-déjeuner servi directement en chambre ou sur votre terrasse privée.',
 'Breakfast served directly in your room or on your private terrace.',
 15.00, 'Supplément par personne', FALSE, 28),

('cooking-class', 'Cours de cuisine privé', 'Private cooking class', 'activity',
 'Le chef vous initie à la cuisine saint-martinoise avec des produits locaux.',
 'The chef introduces you to Saint-Martin cuisine with locally sourced ingredients.',
 0, 'Sur devis', FALSE, 29),

('themed-dinner', 'Dîner à thème', 'Themed dinner', 'dining',
 'Dîners organisés 1 à 2 fois par semaine par le chef — barbecues, fruits de mer. Ambiance de soirée privée.',
 'Dinners organized 1-2 times per week by the chef — barbecues, seafood cook-ups. Feels like a private party.',
 0, 'Inclus selon le programme', FALSE, 30),

('private-chef', 'Chef privé', 'Private chef', 'dining',
 'Dîner privé préparé par un chef à l''hôtel, sur votre terrasse ou au bord de la piscine.',
 'Private dinner prepared by a chef at the hotel, on your terrace or poolside.',
 0, 'Sur devis', FALSE, 31),

('car-rental', 'Location de voiture', 'Car rental', 'transport',
 'Arrangement de location de voiture via la conciergerie.',
 'Car rental arrangement through concierge.',
 0, 'Via conciergerie, prix selon modèle', FALSE, 32),

('laundry', 'Blanchisserie', 'Laundry service', 'room_extra',
 'Service de blanchisserie et pressing.',
 'Laundry and dry cleaning service.',
 0, 'Prix selon articles', FALSE, 33),

('privatization', 'Privatisation de l''hôtel', 'Full hotel privatization', 'event',
 'Réservation exclusive de l''hôtel entier pour réunions familiales, anniversaires, séminaires intimes. Personnel dédié, partenaires locaux mobilisés.',
 'Exclusive booking of the entire hotel for family reunions, birthdays, intimate seminars. Dedicated staff, local partners mobilized.',
 0, 'Sur devis personnalisé', FALSE, 34),

('honeymoon', 'Forfait Lune de Miel', 'Honeymoon package', 'event',
 'Package personnalisé avec champagne, douceurs sucrées, bouquet de fleurs. Conçu sur mesure avec les mariés.',
 'Customized package with champagne, sweet treats, flower bouquet. Designed with you, for you.',
 896.00, 'À partir de, par nuit (Suite Deluxe vue mer panoramique)', FALSE, 35),

('pilates', 'Cours de Pilates privé (1h)', 'Private Pilates class (1h)', 'wellness',
 'Cours de Pilates privé d''une heure à l''hôtel.',
 'One-hour private Pilates class at the hotel.',
 110.00, 'Par séance', FALSE, 36);
