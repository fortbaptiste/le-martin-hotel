-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Système email IA complet                               ║
-- ║  Templates · Partenaires · Transports · Exemples · Règles IA   ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  1. EMAIL TEMPLATES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO email_templates (category, name, language, channel, subject_line, body, variables, notes) VALUES

-- ── Restaurant Reco EN (email) ──
('restaurant_reco', 'Recommandations restaurants — Email EN', 'en', 'email',
 'Our curated restaurant & experience recommendations',
 'Dear {guest_name},

We are delighted to share with you a selection of carefully chosen restaurants and experiences, perfectly aligned with the spirit of the Martin Boutique Hotel.

These are places we genuinely love, that we frequent ourselves, and that we are happy to introduce to you during your stay with us. Of course, these suggestions are just a starting point: as you know, we also enjoy guiding you day by day, according to your mood and desires, and whispering along the way a few of our best-kept secrets.

This selection blends French gastronomy, intimate addresses, unexpected spots, and authentic local experiences.
At Saint-Martin, each day has its own ambiance… and every table tells a story.

For Lunch

Karibuni – Ilet Pinel
An unmissable experience. If you set off directly from the hotel by kayak, nothing compares to watching turtles and fish before arriving at the beach. A joyful, relaxed atmosphere, feet in the sand — simple, lively luxury.

Coco Beach – Orient Bay
A chic classic by the sea, perfect for a sunny and elegant lunch, with refined cuisine and a gentle, summery ambiance.

Aloha – Orient Bay
A friendly, modern, and relaxed spot, ideal for a lunch by the sea in a light and pleasant atmosphere.

Anse Marcel Beach Restaurant – Anse Marcel
A splendid, peaceful, and elegant natural setting for a timeless lunch, between the turquoise bay and refined cuisine.

For Dinner

Calmos Cafe – Grand Case
By the water, with a casual and relaxed atmosphere, impeccable service, and one of the island''s most beautiful sunsets. Not to be missed.

Le Java – Grand Case
In the same spirit, a warm and welcoming atmosphere, perfect for a dinner by the sea at dusk.

Maison Mere – Orient Bay
A contemporary, elegant, and creative table, where the cuisine is generous and inspired.

L''Atelier – Orient Bay
Refined cuisine in an elegant and intimate setting, perfect for a gentle, memorable dinner.

Le Cottage – Grand Case
An iconic gastronomic address, offering a timeless and sophisticated French dining experience.

Les Galets – Grand Case
Our absolute favorite. A very intimate, sincere place, perfectly aligned with our hotel''s spirit: sensitive cuisine, a cozy atmosphere, and truly moving moments at the table.

L''Astrolabe – Grand Case
Famous for its lobster nights, an elegant and warm institution for lovers of fine dining.

Les Lolos – Grand Case
Typical Creole cuisine, BBQ, local ambiance, and authentic flavors: a true immersion into the soul of Saint-Martin.

We remain, of course, at your full disposal to make reservations, refine these suggestions, or guide you according to your desires in the moment.

We look forward to sharing these wonderful addresses with you,
and to continuing to craft together an experience that truly reflects you.

Warm regards,
Marion / Idalia
The Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Template principal envoyé à tous les clients avant ou pendant le séjour. Utilisé systématiquement dans les threads Richard, Jon, Rosenberg.'),


-- ── Restaurant Reco FR (email) ──
('restaurant_reco', 'Recommandations restaurants — Email FR', 'fr', 'email',
 'Nos recommandations gourmandes & expériences locales',
 'Chers {guest_name},

Nous sommes ravis de vous proposer une sélection de restaurants et d''expériences soigneusement choisis, en parfaite harmonie avec l''ADN du Martin Boutique Hotel.

Il s''agit de lieux que nous aimons sincèrement, que nous fréquentons, et que nous sommes heureux de vous faire découvrir au fil de votre séjour parmi nous. Bien entendu, ces suggestions ne sont qu''un point de départ : comme vous le savez, nous aimons aussi vous accompagner jour après jour, selon vos envies, votre humeur, et vous chuchoter, au fil de votre séjour, quelques-uns de nos secrets les mieux gardés.

Cette sélection mêle gastronomie française, adresses intimistes, lieux surprenants et expériences plus locales.
A Saint-Martin, chaque jour a son ambiance… et chaque table raconte une histoire.

Pour le déjeuner

Karibuni – Ilet Pinel
Une expérience incontournable. Si vous partez directement de l''hôtel en kayak, rien de plus magique que d''observer tortues et poissons avant de rejoindre la plage. Une ambiance joyeuse, décontractée, les pieds dans le sable : le luxe simple et vivant.

Coco Beach – Orient Bay
Un classique chic en bord de mer, idéal pour un déjeuner élégant, ensoleillé, avec une cuisine raffinée et une atmosphère douce et estivale.

Aloha – Orient Bay
Une adresse conviviale, moderne et décontractée, parfaite pour un lunch face à la mer dans une ambiance légère et agréable.

Anse Marcel Beach Restaurant – Anse Marcel
Un cadre naturel splendide, paisible et élégant, pour un déjeuner hors du temps, entre baie turquoise et cuisine soignée.

Pour le dîner

Calmos Cafe – Grand Case
Au bord de l''eau, une ambiance casual et décontractée, un service impeccable et l''un des plus beaux couchers de soleil de l''île. A ne pas manquer.

Le Java – Grand Case
Dans le même esprit, une atmosphère chaleureuse et conviviale, idéale pour profiter d''un dîner face à la mer au crépuscule.

Maison Mere – Orient Bay
Une table contemporaine, élégante et créative, où la cuisine se veut généreuse et inspirée.

L''Atelier – Orient Bay
Une cuisine fine et maîtrisée, dans un cadre élégant et intimiste, parfait pour un dîner tout en douceur.

Le Cottage – Grand Case
Une adresse gastronomique emblématique, pour une expérience française raffinée et intemporelle.

Les Galets – Grand Case
Notre coup de coeur absolu. Un lieu très intimiste, sincère, profondément aligné avec notre ADN : une cuisine sensible, une atmosphère feutrée, et une vraie émotion à table.

L''Astrolabe – Grand Case
Réputé pour ses soirées langoustes, une institution élégante et chaleureuse pour les amateurs de belles tables.

Les Lolos – Grand Case
Cuisine créole typique, BBQ, ambiance locale et authentique : une immersion gourmande au coeur de l''âme de Saint-Martin.

Nous restons bien entendu à votre entière disposition pour effectuer les réservations, affiner ces suggestions ou vous guider selon vos envies du moment.

Au plaisir de partager avec vous ces belles adresses,
et de continuer à façonner ensemble une expérience qui vous ressemble.

Chaleureusement,
Marion / Idalia
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Version française du template restaurant.'),


-- ── Restaurant Reco EN (WhatsApp) ──
('restaurant_reco', 'Recommandations restaurants — WhatsApp EN', 'en', 'whatsapp',
 NULL,
 'Hello {guest_name},

We''re delighted to share a few restaurants and experiences that we love and think you''ll enjoy during your stay at the Martin Boutique Hotel.

For lunch:
- Karibuni – Ilet Pinel: Kayak trip from the hotel, watch turtles & fish before the beach, joyful and relaxed.
- Coco Beach – Orient Bay: Chic, sunny, feet in the sand.
- Aloha – Orient Bay: Friendly, modern, casual.
- Anse Marcel Beach Restaurant: Peaceful, elegant, with a turquoise bay.

For dinner:
- Calmos Cafe – Grand Case: Casual, impeccable service, one of the most beautiful sunsets.
- Le Java – Grand Case: Warm, relaxed, perfect for a sunset dinner by the sea.
- Maison Mere – Orient Bay: Contemporary, elegant & creative.
- L''Atelier – Orient Bay: Refined cuisine in an intimate setting.
- Le Cottage – Grand Case: Iconic French gastronomy.
- Les Galets – Grand Case: Intimate, sincere, our favorite.
- L''Astrolabe – Grand Case: Famous for lobster nights, elegant & warm.
- Les Lolos – Grand Case: Authentic Creole BBQ, lively local atmosphere.

Of course, we''re happy to help with reservations or guide you day by day according to your mood and desires.

Warm regards,
Marion / Idalia',
 ARRAY['guest_name'],
 'Version courte WhatsApp pour envoi mobile.'),


-- ── Restaurant Reco FR (WhatsApp) ──
('restaurant_reco', 'Recommandations restaurants — WhatsApp FR', 'fr', 'whatsapp',
 NULL,
 'Bonjour {guest_name},

Nous sommes ravis de partager avec vous quelques adresses de restaurants et expériences que nous aimons et qui feront briller votre séjour au Martin Boutique Hotel.

Pour le déjeuner :
- Karibuni – Ilet Pinel : Départ en kayak depuis l''hôtel, tortues et poissons avant la plage, ambiance joyeuse et détendue.
- Coco Beach – Orient Bay : Chic, ensoleillé, pieds dans le sable.
- Aloha – Orient Bay : Convivial, moderne et décontracté.
- Anse Marcel Beach Restaurant : Cadre paisible et élégant, avec la baie turquoise.

Pour le dîner :
- Calmos Cafe – Grand Case : Casual, service impeccable, coucher de soleil magnifique.
- Le Java – Grand Case : Chaleureux et décontracté, idéal pour le soir.
- Maison Mere – Orient Bay : Contemporain, élégant et créatif.
- L''Atelier – Orient Bay : Cuisine raffinée dans un cadre intimiste.
- Le Cottage – Grand Case : Gastronomie française emblématique.
- Les Galets – Grand Case : Intime et sincère, notre coup de coeur.
- L''Astrolabe – Grand Case : Réputé pour ses soirées langoustes, élégant et chaleureux.
- Les Lolos – Grand Case : Cuisine créole authentique, BBQ et ambiance locale.

Nous sommes à votre disposition pour réserver vos tables ou vous guider au fil du séjour selon vos envies.

Chaleureusement,
Marion / Idalia',
 ARRAY['guest_name'],
 'Version courte WhatsApp FR.'),


-- ── Location voiture EN ──
('car_rental', 'Forward location voiture — Email EN', 'en', 'email',
 'Car rental request — Le Martin Boutique Hotel guest',
 'Dear Sébastien & Eve,

I hope this message finds you well.

Please find below the contact details of our valued guest, {guest_name} (in copy) who will be staying with us at Le Martin Boutique Hotel from {arrival_date} to {departure_date}.

Could you kindly prepare and send them a quote covering the full duration of their stay?

{special_requests}

Thank you very much for your kind assistance.

Warm regards,
Marion / Idalia
Le Martin Boutique Hotel',
 ARRAY['guest_name', 'arrival_date', 'departure_date', 'special_requests'],
 'Email envoyé à Escale Mail (Sébastien & Eve) avec le client en copie. Le loueur livre la voiture à l''aéroport. special_requests = ex: siège auto enfant.'),


-- ── Location voiture FR ──
('car_rental', 'Forward location voiture — Email FR', 'fr', 'email',
 'Demande de location — Client Le Martin Boutique Hotel',
 'Cher Sébastien, chère Eve,

J''espère que vous allez bien.

Vous trouverez ci-dessous les coordonnées de notre client, {guest_name} (en copie), qui séjournera au Martin Boutique Hotel du {arrival_date} au {departure_date}.

Pourriez-vous, s''il vous plaît, lui préparer et lui adresser un devis couvrant l''intégralité de son séjour ?

{special_requests}

Je vous remercie sincèrement pour votre précieuse assistance.

Bien chaleureusement,
Marion / Idalia
Le Martin Boutique Hotel',
 ARRAY['guest_name', 'arrival_date', 'departure_date', 'special_requests'],
 'Version FR du forward Escale Mail.'),


-- ── Annulation EN ──
('cancellation', 'Modèle annulation — Email EN', 'en', 'email',
 'Re: Your reservation at Le Martin Boutique Hotel',
 'Dear {guest_name},

We are truly sorry to hear that you will not be able to join us in Saint Martin for your stay.

In accordance with our cancellation policy and the terms of your reservation:

1) Advance Purchase Reservation
This booking is non-cancellable, non-modifiable, and non-refundable.

2) Flexible Reservation
- Cancellation more than 30 days prior to arrival: 100% refund.
- Cancellation between 30 and 16 days prior to arrival: 50% refund.
- Cancellation between 15 days and the day of arrival, or in case of no-show: the reservation is non-refundable.

However, we will do our utmost to rebook your room and refund any nights successfully reallocated as quickly as possible.

We hope to have the pleasure of welcoming you to Le Martin Boutique Hotel on a future occasion, and remain at your disposal for any questions or assistance.

Warm regards,
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'IMPORTANT: Ce template est envoyé UNIQUEMENT après validation humaine. L''IA ne doit JAMAIS confirmer une annulation/remboursement de manière autonome. Toujours escalader.'),


-- ── Annulation FR ──
('cancellation', 'Modèle annulation — Email FR', 'fr', 'email',
 'Re: Votre réservation au Le Martin Boutique Hotel',
 'Cher(e) {guest_name},

Nous sommes sincèrement désolés d''apprendre que vous ne pourrez pas vous rendre à Saint-Martin et profiter de votre séjour parmi nous.

Conformément à notre politique d''annulation et aux conditions tarifaires de votre réservation :

1) Réservation « Advance Purchase »
Cette réservation est non annulable, non modifiable et non remboursable.

2) Réservation « Flexible »
- Annulation plus de 30 jours avant votre arrivée : remboursement intégral de votre séjour.
- Annulation entre 30 et 16 jours avant votre arrivée : remboursement de 50 % de votre séjour.
- Annulation entre 15 jours avant et le jour de votre arrivée, ou en cas de non-présentation : la réservation n''est pas remboursable.

Cependant, nous mettrons tout en oeuvre pour relouer votre chambre et vous rembourser les nuitées concernées dans les meilleurs délais.

Nous espérons avoir le plaisir de vous accueillir une prochaine fois au Martin Boutique Hotel, et restons à votre disposition pour toute question ou assistance.

Avec nos meilleures salutations,
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'IMPORTANT: Toujours escalader les annulations. Ce template sert de base après décision humaine.'),


-- ── Welcome Board EN ──
('welcome_board', 'Pré-arrivée Welcome Board — Email EN', 'en', 'email',
 'Getting ready for your stay at Le Martin Boutique Hotel',
 'Dear {guest_name},

Thank you very much for sharing your flight/boat schedule with us.

Please find attached all the instructions to reach the hotel smoothly.

We wish you a wonderful trip and look forward to welcoming you at Le Martin for a truly lovely stay.

Warm regards,
Marion & Emmanuel
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Envoyé avec le PDF/guide d''accès à l''hôtel (code portail, itinéraire). Déclenché quand le client communique ses horaires de vol.'),


-- ── Welcome Board FR ──
('welcome_board', 'Pré-arrivée Welcome Board — Email FR', 'fr', 'email',
 'Préparez votre arrivée au Le Martin Boutique Hotel',
 'Cher(e) {guest_name},

Nous vous remercions sincèrement de nous avoir communiqué vos horaires de vol/bateau.

Veuillez trouver en pièce jointe toutes les instructions pour rejoindre l''hôtel.

Nous vous souhaitons un excellent voyage et avons hâte de vous accueillir au Martin pour un séjour des plus agréables.

Cordialement,
Marion & Emmanuel
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Version FR du welcome board.'),


-- ── Décoration anniversaire EN ──
('birthday', 'Proposition décoration anniversaire — Email EN', 'en', 'email',
 'Re: Birthday Decoration',
 'Dear {guest_name},

Thank you for your lovely message!

We would be happy to organize a small birthday decoration for {birthday_person}. We usually prepare a setup with balloons to which we attach little notes — we place about ten balloons and you can send us 10 short messages you would like us to write for them.

We can also arrange a bouquet of flowers for the room.

Here are the rates:
- Birthday decoration (balloons + notes): 75 EUR
- Flower bouquet: 60 EUR
- In-room massage (1 hour): 165 EUR

Let me know what you would like us to prepare, and I will take care of everything for you.

Warm regards,
Marion',
 ARRAY['guest_name', 'birthday_person'],
 'Proposé quand un client mentionne un anniversaire, lune de miel, ou occasion spéciale. Adapter pour honeymoon/anniversary.'),


-- ── Décoration anniversaire FR ──
('birthday', 'Proposition décoration anniversaire — Email FR', 'fr', 'email',
 'Re: Décoration anniversaire',
 'Cher(e) {guest_name},

Merci pour votre adorable message !

Nous serions ravis d''organiser une petite décoration d''anniversaire pour {birthday_person}. Nous préparons habituellement un décor avec des ballons auxquels nous attachons de petites notes — nous plaçons environ dix ballons et vous pouvez nous envoyer 10 courts messages que vous souhaitez que nous écrivions.

Nous pouvons également préparer un bouquet de fleurs pour la chambre.

Voici nos tarifs :
- Décoration anniversaire (ballons + notes) : 75 EUR
- Bouquet de fleurs : 60 EUR
- Massage en chambre (1 heure) : 165 EUR

Dites-nous ce que vous souhaitez et nous nous occupons de tout.

Chaleureusement,
Marion',
 ARRAY['guest_name', 'birthday_person'],
 'Version FR. Adapter pour anniversaire de mariage / lune de miel.');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  2. PARTENAIRES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO partners (name, service_type, contact_name, contact_email, contact_phone, website, description_fr, description_en, pricing_info, notes) VALUES

('Escale Mail', 'car_rental',
 'Sébastien & Eve', NULL, NULL, NULL,
 'Société de location de voiture partenaire. Amis de Marion et Emmanuel. Super service, trouvent toujours des solutions pour les clients. Livraison possible à l''aéroport.',
 'Trusted car rental partner. Friends of Marion and Emmanuel. Excellent service, always find solutions for guests. Airport delivery available.',
 'Devis sur demande selon durée du séjour. Siège auto enfant disponible sur demande.',
 'Utiliser le template email "car_rental" pour mettre en relation client et Escale Mail. Toujours mettre le client en copie.'),

('Bubble Shop', 'snorkeling',
 NULL, NULL, NULL, NULL,
 'Excursion snorkeling de 3 heures au Rocher Créole. Exploration de la vie marine autour des récifs.',
 'Three-hour snorkeling excursion to Rocher Créole. Explore the beautiful marine life around the reefs.',
 'Tarif sur demande.',
 'Recommandé pour les amateurs de snorkeling. Excursion populaire.'),

('Hopfit Hope Estate', 'gym',
 NULL, NULL, NULL, NULL,
 'Salle de sport bien équipée à seulement 5 minutes en voiture de l''hôtel.',
 'Well-equipped gym just 5 minutes from the hotel.',
 'Accès à la séance.',
 'Recommander aux clients qui demandent des activités fitness.'),

('Scoobi Too', 'boat_tour',
 NULL, NULL, NULL, NULL,
 'Sorties bateau privées ou charter. Excursions vers les îles voisines.',
 'Private or charter boat trips. Excursions to neighboring islands.',
 'Tarif sur demande selon durée et destination.',
 'Pour les sorties bateau privées. Mentionné dans la FAQ.'),

('Lottery Farm', 'excursion',
 NULL, NULL, NULL, NULL,
 'Randonnée jusqu''au Pic Paradis, point culminant de l''île. Vue panoramique 180° sur la mer. Parcours zipline disponible.',
 'Hike to Pic Paradis, the island''s highest point. Breathtaking 180-degree sea views. Zipline course available.',
 'Tarif randonnée + zipline sur demande.',
 'Recommandé spécialement pour les ados (zipline) et les amateurs de nature. Combinable avec randonnée Pic Paradis.'),

('Great Bay Express', 'ferry',
 NULL, NULL, '+1-721-520-5015', 'https://www.greatbayexpress.com',
 'Ferry rapide entre Sint Maarten (côté hollandais) et Saint-Barthélemy. 3 rotations par jour, 7j/7.',
 'Fast ferry between Sint Maarten (Dutch side) and Saint-Barthélemy. 3 daily rotations, 7 days a week.',
 'Voir horaires dans transport_schedules. Réservation sur le site web ou par WhatsApp.',
 'Passeport obligatoire. Check-in 15 min avant départ. Départ depuis le côté hollandais (Simpson Bay).'),

('Ferry Marigot-Anguilla', 'ferry',
 NULL, NULL, NULL, NULL,
 'Ferry public Marigot (St-Martin) vers Blowing Point (Anguilla). 10 départs par jour. Traversée 20 minutes. Billetterie sur place uniquement.',
 'Public ferry from Marigot (St. Martin) to Blowing Point (Anguilla). 10 daily departures. 20-minute crossing. Tickets on-site only.',
 'Aller simple : $30/30 EUR ($15 enfants 2-11 ans) + 7 EUR redevance passagère (dès 4 ans). Taxe Anguilla : $11 (journée) ou $28 (séjour > 12h). Espèces à bord, carte pour la redevance uniquement.',
 'Passeport obligatoire. Gare maritime ouverte 7j/7 de 8h30 à 18h sauf intempéries. Billetterie sur place uniquement, pas de réservation en ligne.');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  3. HORAIRES TRANSPORT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Ferry Marigot → Anguilla (Blowing Point)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('marigot_to_anguilla', 'Ferry public Marigot', '08:30', '08:50', 'daily', 20, 30.00, 'EUR', 'Aller simple. +7 EUR redevance passagère. Enfants 2-11: 15 EUR.'),
('marigot_to_anguilla', 'Ferry public Marigot', '09:30', '09:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '10:30', '10:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '11:30', '11:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '12:30', '12:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '13:30', '13:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '15:00', '15:20', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '16:30', '16:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '17:15', '17:35', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '18:00', '18:20', 'daily', 20, 30.00, 'EUR', NULL);

-- Ferry Anguilla (Blowing Point) → Marigot
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('anguilla_to_marigot', 'Ferry public Anguilla', '07:30', '07:50', 'daily', 20, 30.00, 'USD', 'Taxe Anguilla en sus: $11 (journée) ou $28 (séjour > 12h).'),
('anguilla_to_marigot', 'Ferry public Anguilla', '08:30', '08:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '09:30', '09:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '10:30', '10:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '11:30', '11:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '12:30', '12:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '14:00', '14:20', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '15:30', '15:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '16:30', '16:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '17:15', '17:35', 'daily', 20, 30.00, 'USD', NULL);

-- Great Bay Express SXM → SBH (Tableau 1 — matin tôt)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'monday',    45, NULL, 'USD', 'Passeport obligatoire. Check-in 15 min avant. Réservation: greatbayexpress.com'),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'tuesday',   45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'wednesday', 45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'thursday',  45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'friday',    45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'saturday',  45, NULL, 'USD', NULL);

-- Great Bay Express SBH → SXM (Tableau 1 — matin tôt retour)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'monday',    45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'tuesday',   45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'wednesday', 45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'thursday',  45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'friday',    45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'saturday',  45, NULL, 'USD', NULL);

-- Great Bay Express SXM → SBH (Tableau 2 — milieu de journée, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Great Bay Express', '09:45', '10:30', 'daily', 45, NULL, 'USD', NULL);

-- Great Bay Express SBH → SXM (Tableau 2 — milieu de journée retour, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sbh_to_sxm', 'Great Bay Express', '11:00', '11:45', 'daily', 45, NULL, 'USD', NULL);

-- Great Bay Express SXM → SBH (Tableau 3 — soir, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Great Bay Express', '17:30', '18:15', 'daily', 45, NULL, 'USD', NULL);

-- Great Bay Express SBH → SXM (Tableau 3 — soir retour, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sbh_to_sxm', 'Great Bay Express', '18:45', '19:30', 'daily', 45, NULL, 'USD', NULL);

-- Ferry côté français SXM → SBH (navette)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Navette côté français', '00:00', NULL, 'daily', 50, NULL, 'EUR', 'Passeport ou carte d''identité obligatoire. 2 à 3 navettes par jour. Horaires et billetterie: 05 90 87 10 68 ou sur place. Moins intéressant que Great Bay Express selon Emmanuel.');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  4. SERVICES ADDITIONNELS (ajout à hotel_services existant)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO hotel_services (slug, name_fr, name_en, category, description_fr, description_en, price_eur, price_note, is_complimentary, is_active, sort_order) VALUES

('transfert-aeroport-hotel', 'Transfert aéroport (organisé par l''hôtel)', 'Airport transfer (arranged by the hotel)', 'concierge',
 'L''hôtel organise le transfert avec un chauffeur partenaire. Le client paie le chauffeur directement à l''arrivée. Trajet environ 1 heure.',
 'The hotel arranges the transfer with a trusted driver partner. The guest pays the driver directly upon arrival. Approximately 1 hour drive.',
 90.00, 'Option recommandée. Demander: ville de départ, compagnie, vol, heure arrivée. Taxi direct ~50 EUR.', FALSE, TRUE, 100),

('transfert-aeroport-enligne', 'Transfert aéroport (réservation en ligne)', 'Airport transfer (online booking)', 'concierge',
 'Réservation du transfert via le site web de l''hôtel.',
 'Transfer booking via the hotel website.',
 115.00, '115 EUR depuis aéroport → hôtel. 75 EUR depuis hôtel → aéroport. Proposer l''option à 90 EUR en priorité.', FALSE, TRUE, 101),

('kayak-double-pinel', 'Location kayak double (Pinel)', 'Double kayak rental (Pinel Island)', 'activity',
 'Location de kayak double pour rejoindre l''Ilet Pinel depuis le ponton de l''hôtel. Observation des tortues marines en chemin.',
 'Double kayak rental to paddle to Pinel Island from the hotel dock. Watch sea turtles along the way.',
 40.00, 'Par kayak double. Distinguer de la mise à dispo gratuite des kayaks/paddles pour loisir.', FALSE, TRUE, 102),

('decoration-anniversaire', 'Décoration chambre anniversaire', 'Birthday room decoration', 'event',
 'Décoration de la chambre avec ballons et petits messages personnalisés. Environ 10 ballons avec notes attachées.',
 'Room decoration with balloons and personalized notes. About 10 balloons with attached messages.',
 75.00, 'Demander 10 messages courts. Adaptable pour mariage/lune de miel. Hélium non garanti (île).', FALSE, TRUE, 103),

('bouquet-fleurs', 'Bouquet de fleurs en chambre', 'Flower bouquet in room', 'event',
 'Bouquet de fleurs frais disposé dans la chambre pour une occasion spéciale.',
 'Fresh flower bouquet placed in the room for a special occasion.',
 60.00, 'Complément idéal à la décoration anniversaire. Commander 48h avant.', FALSE, TRUE, 104),

('massage-chambre', 'Massage en chambre', 'In-room massage', 'wellness',
 'Massage bien-être réalisé dans l''intimité de votre chambre par un(e) praticien(ne) professionnel(le). 1 heure.',
 'Wellness massage in the privacy of your room by a professional therapist. 1 hour.',
 165.00, 'Prix actualisé 2026. Réservation 24h à l''avance. Proposer après anniversaire ou occasion spéciale.', FALSE, TRUE, 105);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  5. EXEMPLES DE CONVERSATIONS (few-shot pour l'IA)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO email_examples (category, title, client_message, marion_response, context, learnings, language) VALUES

-- Exemple 1 : Activité + logistique timing
('concierge_activity', 'Kayak vers Pinel + contrainte horaire avion',
 'Our group has 2 rooms booked for 1 night, Sunday May 17th. Does the hotel offer 2 person Kayaks for us to padel over to Pinel island. Our Winair flight leaves St Barts at 1, so I am not sure what time we will arrive at the hotel. We are considering visiting Pinel island, but I think the shuttle boats might not give us enough time.',
 'Dear Scott,

Thank you for your message.

We would be delighted to rent you double kayaks to paddle over to Pinel Island (the rate is 40 EUR per kayak). It''s a lovely experience and a beautiful way to reach the island.

However, if your Winair flight to St. Barths departs at 1:00 PM (from Princess Juliana Airport, I presume), you would need to be at the airport approximately 1 hour and 30 minutes before departure. The drive from the hotel to the airport takes about 1 hour, which means you would need to leave the hotel around 10:30 AM.

While it is technically possible to go to Pinel Island in the morning, I do feel it may be a bit tight in terms of timing and could feel rushed.

Please let me know how you would like to plan your morning. I''m happy to help you organize it in the most relaxed way possible.

Warm regards,
Marion',
 'Client avec contrainte horaire serrée (vol à 13h, trajet 1h vers aéroport, check-in 1h30 avant).',
 ARRAY[
   'Toujours calculer le timing réel quand un client a un vol',
   'Trajet hôtel → aéroport Princess Juliana = environ 1 heure',
   'Check-in aéroport = 1h30 avant le vol',
   'Ne jamais hésiter à prévenir que le timing est serré plutôt que de laisser le client stressé',
   'Proposer d''organiser la matinée de manière détendue'
 ], 'en'),


-- Exemple 2 : Demande de réservation (client qui revient)
('reservation_inquiry', 'Client fidèle demande extension de séjour',
 'We are looking to add another night (7th night) on to our existing reservation (February 6) is that possible to do without moving rooms? Let me know.',
 'Hi,

Thank you for your message — I''m happy to share some good news.

Yes, it is absolutely possible to add an additional night on February 6th to your existing reservation without changing rooms. I do have one room remaining, which allows me to extend your stay seamlessly.

That said, I wanted to let you know that I have had to adjust our planning to make this possible, and reservations are currently very active. Availability can change quickly, and it is possible that this room may no longer be available if not confirmed soon.

Please let me know if you would like me to go ahead and secure this extra night for you, and I will take care of the rest.

Warm regards,
Marion',
 'Client fidèle (Richard) qui revient pour la 2e année. Réservation existante dans la chambre Marcelle.',
 ARRAY[
   'Créer un sentiment d''urgence subtil sans être pushy',
   'Mentionner que des ajustements ont été faits = valorise l''effort',
   'Proposer de tout gérer pour le client',
   'Pour les clients fidèles, ton plus chaleureux et familier'
 ], 'en'),


-- Exemple 3 : Recommandation restaurant personnalisée
('concierge_restaurant', 'Client demande conseil restaurant spécifique',
 'We were hoping you could help us with a beach club reservation this coming Sunday. We really enjoyed Coco Beach last year but understand they are under new ownership. Would you still recommend? We want more of a French vibe than an American vibe. Do they still have French DJs on Sunday? Also, how is the new place, Babacool in Simpson Bay?',
 'Dear Richard,

We are looking forward to seeing you soon!

Coco Beach is still a wonderful spot — the change in ownership has been very positive, and the atmosphere remains fantastic. The French DJ on Sunday evenings is still there, so you''ll get the same French vibe you enjoyed last year.

Your reservation is confirmed for Sunday!

Regarding Babacool in Simpson Bay, I haven''t personally been, and the feedback I''ve heard hasn''t been very strong. If you''re looking for a better experience, I would recommend Kalatua instead — it''s more reliable and enjoyable.

[... suivi du template restaurant complet ...]

Warm regards,
Marion',
 'Client fidèle qui connaît déjà l''île. Demande conseil sur un lieu spécifique + comparaison.',
 ARRAY[
   'Répondre d''abord à la question spécifique AVANT d''envoyer le template',
   'Être honnête sur les endroits non recommandés (Babacool: feedback pas très fort)',
   'Proposer une alternative concrète (Kalatua au lieu de Babacool)',
   'Confirmer la réservation directement quand c''est possible',
   'Ajouter le template restaurant complet après la réponse personnalisée'
 ], 'en'),


-- Exemple 4 : Booking multi-chambres
('reservation_inquiry', 'Pas de chambre unique dispo — proposition alternative',
 'We would love to book one room for Feb 19-26 for 2 people (for my wife''s birthday). It seems that there is no one room available for that whole time but we would be happy to move rooms during the holiday. Would you be able to accommodate us?',
 'Bonsoir Jon,

Thank you very much for your message and for your interest in the Martin Boutique Hotel. We would be truly delighted to welcome you and your wife to celebrate her birthday with us.

Indeed, we no longer have availability for the entire stay in the same room. However, we would be very happy to offer you the following alternative, which will allow you to fully enjoy your time with us:

From February 19th to 23rd: the Deluxe Suite – Garden View, also known as La Chambre de Marius.
From February 23rd to 26th: the Privilege Room – La Chambre de Pierre.

I will send you, in a separate email, a detailed quotation including our Advance Purchase rate, which offers a 10% discount. Please note that this rate is non-refundable, non-changeable, and non-cancellable.

Please feel free to let me know if this arrangement suits you or if you have any questions at all.

Warm regards,
Marion',
 'Client souhaite 1 chambre sur 7 nuits mais aucune chambre n''est dispo sur toute la période.',
 ARRAY[
   'Quand pas de dispo en 1 chambre, proposer 2 chambres consécutives',
   'Nommer les chambres par leur nom (Marius, Pierre) + lien site web',
   'Mentionner le tarif Advance Purchase (-10%) dès le début',
   'Préciser les conditions (non remboursable, non modifiable)',
   'Envoyer le devis dans un email séparé',
   'Reconnaître l''occasion spéciale (anniversaire)'
 ], 'en'),


-- Exemple 5 : Pré-arrivée concierge complet
('pre_arrival', 'Questions pré-arrivée multiples (voiture, fitness, activités, dîners)',
 'We arrive on Feb 19 on DL1887 at 12.13pm. Just some thoughts / questions: Should we hire a car or is it easy to get around? Would you be able to arrange some evening dinners for us? We also would love to do some fitness activities - what do you recommend? What other activities do you recommend? (We like rum :-)) If we do not hire a car, can you arrange transfers from the airport?',
 'Dear Jon & Cass,

We are so excited to welcome you on Thursday!

Thank you for sharing your arrival details. We have noted that you land on February 19 at 12:13 pm on DL1887.

Car rental: I can put you in contact with our trusted car rental partner who can deliver your vehicle directly at the airport on the day of your arrival.

Fitness: There is a very nice gym just 5 minutes from the hotel: Hopfit Hope Estate.

Nature & outdoor: We highly recommend a kayak outing directly from the hotel to Ilet Pinel. For snorkeling, we can organize a 3-hour excursion with Bubble Shop to Rocher Créole. For hiking, I recommend Lottery Farm up to Pic Paradis with breathtaking 180-degree views.

Rum: We have a lovely selection of infused rums at the hotel which you can enjoy by the pool. We can also recommend tastings around the island.

[... suivi du template restaurant complet ...]

Warmest regards,
Marion & Idalia',
 'Client arrivant bientôt, multiple questions pratiques d''un coup.',
 ARRAY[
   'Toujours noter le numéro de vol et l''heure d''arrivée',
   'Structurer la réponse par thème (voiture, fitness, activités, restaurants)',
   'Pour la voiture: proposer le partenaire Escale Mail avec livraison aéroport',
   'Pour le fitness: recommander Hopfit Hope Estate (5 min)',
   'Pour les activités: kayak Pinel, snorkeling Bubble Shop, rando Lottery Farm',
   'Finir par le template restaurant complet',
   'Adapter le ton quand le client montre de l''humour (le rum :-) )'
 ], 'en'),


-- Exemple 6 : Modification réservation non remboursable
('modification', 'Raccourcir un séjour Advance Purchase',
 'Thank you for confirming the reservation, I am looking forward to our stay at your beautiful property. I am in need of a change to the reservation please…we will need to leave on Saturday February 14. Is a change possible?',
 'Dear Mary Beth,

Thank you very much for your message, and we are delighted to know that you are looking forward to your stay with us.

Regarding your request to shorten your stay and depart on Saturday, February 14th, your reservation was made under our Advance Purchase Offer – Breakfast Included, which offers a 10% discount on the room rate. As indicated in the rate conditions, this offer is non-refundable and non-modifiable, with a 100% deposit taken at the time of booking.

That said, I completely understand your situation and will do my best to assist you. I can exceptionally open availability for the two nights in question, and should these nights be rebooked by other guests, I will be happy to refund you the corresponding amount.

Please let me know if you wish to proceed in this way, and I will take care of everything.

Warm regards,
Marion Dufaur
Le Martin Boutique Hotel',
 'Réservation Advance Purchase (non remboursable). Client veut raccourcir de 2 nuits.',
 ARRAY[
   'TOUJOURS ESCALADER les demandes de modification/annulation/remboursement',
   'Rappeler les conditions du tarif (Advance Purchase = non remboursable)',
   'Montrer de l''empathie et proposer une solution: rembourser si les nuits sont rebookées',
   'Ne jamais promettre un remboursement direct — conditionner au rebooking',
   'Utiliser le nom complet avec titre (Marion Dufaur) pour les sujets importants'
 ], 'en'),


-- Exemple 7 : Décoration anniversaire + transfert
('special_occasion', 'Organisation anniversaire + transfert aéroport',
 'We have a reservation under the name Erica Shepperd-Debnam for February 26-28th. We are celebrating Erica''s birthday and I wanted to inquire about decorating the room for her birthday. Is this something that the hotel is able to help facilitate?',
 'Dear Nneka,

Thank you for your lovely message!

We would be happy to organize a small birthday decoration for Erica. We usually prepare a setup with balloons to which we attach little notes — we place about ten balloons and you can send us 10 short messages you would like us to write for her.

We can also arrange a bouquet of flowers for the room.

Please note that I cannot fully guarantee the balloon floating effect, as it requires a helium tank and, on a small island, it can sometimes be challenging to source certain supplies… but I will absolutely do my best to make it beautiful.

Here are the rates:
- Birthday decoration: 75 EUR
- Flower bouquet: 60 EUR
- Massage (1 hour): 165 EUR

Let me know what you would like us to prepare, and I will take care of everything for you.

Warm regards,
Marion',
 'Réservation au nom d''une personne, mais c''est son amie qui organise la surprise.',
 ARRAY[
   'Répondre avec enthousiasme aux occasions spéciales',
   'Détailler le process (10 ballons, 10 messages)',
   'Être transparente sur les limitations (hélium sur une petite île)',
   'Proposer des extras (fleurs, massage) en upsell naturel',
   'Tarifs transfert: 90 EUR (hôtel organise), 115 EUR (via site), ~50 EUR (taxi direct)',
   'Pour le transfert: demander ville de départ, compagnie, numéro de vol, heure d''arrivée'
 ], 'en'),


-- Exemple 8 : Planning restaurant complet sur séjour long
('concierge_restaurant', 'Organisation complète lunch + dîner sur 10 jours',
 'Thank you for sharing your preferred restaurants for dinner. [Client a envoyé sa liste de restaurants souhaités pour chaque jour de son séjour de 10 nuits]',
 'Dear Joseph and Phil,

We are delighted to welcome you back and look forward to having you with us again.

Please note that dinner seatings are typically available at 6:00 or 6:30 p.m., and 8:00 or 8:30 p.m. However, we were able to secure one of your reservations for 7:30 p.m.

We are pleased to confirm that all of your lunch & dinner reservations have been secured as follows:

Friday, February 27
Lunch: Coco Beach – Beach chairs and lunch confirmed for 12:30 p.m.
Dinner: Maison Mere – Confirmed for 8:00 p.m.

Saturday, February 28
Lunch: Joa Beach – Beach chairs and lunch confirmed for 12:30 p.m.
Dinner: Le Pressoir – Confirmed for 8:00 p.m.

[... suite du planning jour par jour ...]

Please do not hesitate to let us know if there is anything further we may assist you with.

Kind regards,
Idalia',
 'Clients fidèles (3e séjour). Planning lunch + dîner sur 10 jours avec beach chairs.',
 ARRAY[
   'Pour les séjours longs (>7 nuits), proposer d''organiser tous les repas',
   'Mentionner les créneaux disponibles (18h/18h30 et 20h/20h30)',
   'Inclure les beach chairs pour les déjeuners en bord de mer',
   'Format: jour par jour, Lunch + Dinner, nom du restaurant, heure confirmée',
   'Si un restaurant nécessite une carte bancaire (ex: Rainbow Cafe), le préciser',
   'Idalia signe ce type de mail opérationnel (pas Marion)'
 ], 'en'),


-- Exemple 9 : Message post-séjour chaleureux
('post_stay', 'Message d''attention post-séjour',
 'I am most grateful, Marion! We are currently enduring a blizzard and I so wish we were still there! I look forward to returning to your beautiful island and of course staying at your peaceful oasis!',
 'Dear Mary Beth,

Oh my goodness… a blizzard! I can only imagine how cold it must be. I wish I could send you a little box of Caribbean sunshine right now.

We miss you already and would absolutely love to welcome you back to our peaceful oasis whenever you are ready to escape the snow. St. Martin will be here, warm and glowing, waiting for you.

Until then, stay cozy and safe — and keep dreaming of turquoise waters and gentle island breezes.

With warmest thoughts,
Marion',
 'Client post-séjour qui mentionne la météo chez elle (blizzard). Marion répond avec chaleur et poésie.',
 ARRAY[
   'Les messages post-séjour sont très personnels — l''IA doit ESCALADER ou générer un brouillon supervisé',
   'Rebondir sur ce que dit le client (météo, souvenirs)',
   'Utiliser des images poétiques (box of Caribbean sunshine, turquoise waters)',
   'Toujours laisser la porte ouverte pour un retour',
   'Ce type d''échange construit la fidélité — ne jamais répondre de manière générique'
 ], 'en');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  6. NOUVELLES RÈGLES IA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO ai_rules (rule_name, rule, condition_text, action_text, priority, is_active) VALUES

-- Classification des emails
('Classification email — restaurant', 'response',
 'Le client demande des recommandations de restaurants, des suggestions pour déjeuner ou dîner, ou mentionne qu''il cherche où manger.',
 'Utiliser le template email_templates.category = "restaurant_reco" dans la langue du client. Personnaliser l''introduction avant le template. Répondre d''abord aux questions spécifiques si le client mentionne un restaurant précis.',
 30, TRUE),

('Classification email — location voiture', 'response',
 'Le client demande comment se déplacer, s''il faut louer une voiture, ou demande un transfert depuis l''aéroport.',
 'Recommander la location de voiture avec le partenaire Escale Mail (Sébastien & Eve). Utiliser le template email_templates.category = "car_rental". Mettre le client en copie du mail au partenaire.',
 31, TRUE),

('Classification email — occasion spéciale', 'response',
 'Le client mentionne un anniversaire, une lune de miel, un anniversaire de mariage ou toute occasion spéciale.',
 'Proposer la décoration chambre (75 EUR), le bouquet de fleurs (60 EUR) et le massage (165 EUR/h). Utiliser le template email_templates.category = "birthday". Adapter le message selon l''occasion.',
 32, TRUE),

('Classification email — activités', 'response',
 'Le client demande des activités, des choses à faire, ou des expériences sur l''île.',
 'Répondre avec les données de la table activities + partners. Recommander en priorité : kayak vers Pinel (40 EUR/kayak double), snorkeling avec Bubble Shop (Rocher Créole, 3h), randonnée Lottery Farm/Pic Paradis. Pour les ados : insister sur kayak, jet ski Orient Bay, zipline Lottery Farm.',
 33, TRUE),

('Classification email — transport inter-îles', 'response',
 'Le client demande comment aller à Anguilla ou Saint-Barthélemy.',
 'Consulter la table transport_schedules. Pour Anguilla: ferry depuis Marigot, 20 min, 30 EUR. Pour St. Barth: recommander Great Bay Express (côté hollandais, 45 min, 3 rotations/jour). Toujours mentionner le passeport obligatoire.',
 34, TRUE),

('Classification email — transfert aéroport', 'response',
 'Le client demande un transfert aéroport ou comment se rendre à l''hôtel depuis l''aéroport.',
 'Proposer 3 options. Recommandée: hôtel organise (90 EUR). Alternative: en ligne (115 EUR aéroport, 75 EUR hôtel). Taxi direct: ~50 EUR. Trajet Princess Juliana → hôtel = 1h. Demander: ville départ, compagnie, vol, heure arrivée.',
 35, TRUE),

('Classification email — pré-arrivée', 'response',
 'Le client communique ses horaires de vol ou demande comment rejoindre l''hôtel.',
 'Envoyer le template welcome_board avec instructions d''accès et code portail. Noter le numéro de vol et l''heure d''arrivée. Si arrivée après 19h, demander au client de prévenir à l''avance.',
 36, TRUE),

-- Escalades supplémentaires
('Escalade — réservation restaurant', 'escalation',
 'Le client demande de réserver une table dans un restaurant spécifique.',
 'L''IA peut recommander des restaurants mais ne doit JAMAIS confirmer une réservation. Les réservations nécessitent un appel téléphonique par l''équipe. Formuler : "I will take care of the reservation and confirm the details shortly."',
 82, TRUE),

('Escalade — mise en relation partenaire', 'escalation',
 'L''email nécessite un contact avec un partenaire externe (Escale Mail, Bubble Shop, etc.).',
 'L''IA peut rédiger un brouillon de mail vers un partenaire mais ne doit JAMAIS l''envoyer directement. Toujours passer en mode brouillon supervisé pour les mails vers des partenaires externes.',
 83, TRUE),

('Escalade — post-séjour et fidélisation', 'escalation',
 'Le client envoie un message de remerciement post-séjour ou exprime le souhait de revenir.',
 'Générer un brouillon supervisé. Ne JAMAIS envoyer automatiquement un message post-séjour. Marion y met une touche très personnelle et poétique. Ces échanges construisent la fidélité.',
 84, TRUE),

-- Règles de ton
('Ton — anticipation proactive', 'tone',
 'Le client mentionne un timing serré (vol, ferry, activité) ou une logistique complexe.',
 'Toujours anticiper les problèmes logistiques (timing kayak+vol, trajet aéroport, horaires ferry). Prévenir le client plutôt que de le laisser découvrir seul. Formuler comme un conseil bienveillant, pas comme un refus.',
 42, TRUE),

('Ton — upsell naturel', 'tone',
 'L''occasion se présente pour proposer des services additionnels (anniversaire, lune de miel, long séjour).',
 'Proposer naturellement décoration, fleurs, massage, restaurants sans être commercial. Le ton doit être "nous serions ravis de..." et non "nous proposons aussi...". L''upsell doit sembler un cadeau, pas une vente.',
 43, TRUE),

('Ton — honnêteté recommandations', 'tone',
 'Le client demande un avis sur un lieu ou restaurant spécifique.',
 'Toujours être honnête. Si un lieu n''est pas recommandé, formuler diplomatiquement: "the feedback I''ve heard hasn''t been very strong" et proposer une alternative. Les Galets = favori absolu. Kalatua = recommandé. Babacool = pas recommandé.',
 44, TRUE);
