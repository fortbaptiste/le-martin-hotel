-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Infos pratiques, FAQ & Règles IA                       ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  INFOS PRATIQUES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO practical_info (category, name, address, phone, distance_km, driving_time_min, hours, notes, sort_order) VALUES

-- Urgences
('emergency', 'Police (côté français)', NULL, '17', NULL, NULL, '24/7', 'Gendarmerie nationale', 1),
('emergency', 'SAMU / Ambulance', NULL, '15', NULL, NULL, '24/7', 'Urgences médicales', 2),
('emergency', 'Pompiers', NULL, '18', NULL, NULL, '24/7', NULL, 3),
('emergency', 'Numéro européen d''urgence', NULL, '112', NULL, NULL, '24/7', 'Fonctionne partout', 4),
('emergency', 'Police (côté hollandais)', NULL, '911', NULL, NULL, '24/7', 'Sint Maarten police', 5),

-- Santé
('health', 'Hôpital Louis Constant Fleming', 'Concordia, est de Marigot', '+590 590 52 25 25', 8.0, 12, '24/7 urgences', 'Hôpital principal côté français', 10),
('health', 'Pharmacie Cul de Sac', 'Route de Cul de Sac', NULL, 1.5, 2, 'Lun-Sam 8h-19h', 'Pharmacie la plus proche de l''hôtel', 11),

-- Aéroports
('airport', 'Aéroport Princess Juliana (SXM)', 'Simpson Bay, côté hollandais', NULL, 15.0, 25, '24/7', 'Aéroport international principal. 27+ compagnies aériennes. Vols directs USA, Europe, Caraïbes. Shuttle hôtel : 75€.', 20),
('airport', 'Aéroport Grand Case-Espérance (SFG)', 'Grand Case, côté français', NULL, 6.0, 10, 'Horaires de vol', 'Aéroport régional. Vols vers St-Barth (15 min), Guadeloupe. Pratique pour arrivées inter-îles.', 21),

-- Transport
('transport', 'Ferry Marigot → Anguilla', 'Port de Marigot', '+590 590 87 10 68', 9.0, 15, '8h30-18h, toutes les 30-45 min', '30$ aller + 7€ taxe. Passeport obligatoire. 20 min traversée.', 25),
('transport', 'Ferry Marigot → St-Barth (Voyager)', 'Port de Marigot', NULL, 9.0, 15, 'Jusqu''à 5 départs/jour', 'ECO 108€ A/R, SMART 131€, BUSINESS 162€. 1h traversée.', 26),
('transport', 'Taxis', 'Partout sur l''île', NULL, NULL, NULL, '24/7', 'Tarifs fixes par zone. Supplément 25% 22h-minuit, 50% minuit-6h. Pas de Uber/Lyft.', 27),
('transport', 'Location de voitures', 'Aéroports et hôtels', NULL, NULL, NULL, 'Variable', 'À partir de ~20$/jour. Conduite à droite. Permis français ou international.', 28),
('transport', 'Pas de Uber / VTC', NULL, NULL, NULL, NULL, NULL, 'Il n''y a pas de Uber ni de VTC sur l''île. Uniquement des taxis (tarifs fixes par zone) et des loueurs de voitures.', 29),

-- Commerce
('shopping', 'Supermarché Gocci', 'Route de Cul de Sac', NULL, 1.5, 2, 'Lun-Sam', 'Supermarché moderne le plus proche de l''hôtel.', 30),
('shopping', 'Super U', 'Près de Grand Case', NULL, 5.0, 8, 'Lun-Sam 8h-20h', 'Grand supermarché complet.', 31),
('shopping', 'Marché de Marigot', 'Waterfront, Marigot', NULL, 9.0, 15, 'Tous les jours sauf dim, 8h-13h', 'Meilleurs jours : mercredi et samedi.', 32),

-- Banques
('bank', 'Distributeur ATM le plus proche', 'Cul de Sac / Grand Case', NULL, 2.0, 4, '24/7', 'ATMs français : EUR. ATMs hollandais : USD. La plupart des commerces acceptent les deux.', 35),

-- Divers
-- Livraison repas
('dining', 'Delifood Island SXM', NULL, NULL, NULL, NULL, NULL, 'Service de livraison de repas, le UberEats de Saint-Martin. Possibilité de se faire livrer le soir à l''hôtel. Site : https://www.delifood-sxm.com', 50),

('info', 'Fuseau horaire', NULL, NULL, NULL, NULL, NULL, 'AST (Atlantic Standard Time) = UTC-4. Pas de changement d''heure.', 40),
('info', 'Monnaie', NULL, NULL, NULL, NULL, NULL, 'EUR côté français, USD/ANG côté hollandais. Les deux acceptés presque partout. Cartes Visa/Mastercard largement acceptées.', 41),
('info', 'Langues', NULL, NULL, NULL, NULL, NULL, 'Français (côté FR), anglais (côté NL), créole, espagnol. L''anglais est compris partout.', 42),
('info', 'Électricité', NULL, NULL, NULL, NULL, NULL, '220V côté français (prises EU), 110V côté hollandais (prises US). L''hôtel fournit prises USB-C et USB-D.', 43),
('info', 'Saison cyclonique', NULL, NULL, NULL, NULL, 'Juin - Novembre', 'Pic : août-octobre. L''hôtel ferme du 15 août au 30 septembre. Réouverture le 1er octobre.', 44),
('info', 'Meilleure période', NULL, NULL, NULL, NULL, 'Décembre - Avril', 'Haute saison. Temps sec, 27-30°C. Février-mars idéal.', 45),
('info', 'Pourboires', NULL, NULL, NULL, NULL, NULL, 'Côté FR : service compris (15%), pourboire supplémentaire apprécié. Côté NL : style américain, 15-20% attendu.', 46);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FAQ
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO faq (question_fr, question_en, answer_fr, answer_en, category, sort_order) VALUES

('Quels sont les horaires de check-in et check-out ?', 'What are the check-in and check-out times?',
 'Check-in : 15h00 - 18h00. Check-out : 11h00. En cas d''arrivée anticipée ou de départ tardif, nous proposons un espace de stockage des bagages et un accès au salon.',
 'Check-in: 3:00 PM - 6:00 PM. Check-out: 11:00 AM. For early arrivals or late departures, we offer luggage storage and lounge access.',
 'general', 1),

('Le petit-déjeuner est-il inclus ?', 'Is breakfast included?',
 'Oui ! Le petit-déjeuner fait maison est inclus dans tous nos tarifs. Servi au bord de la piscine de 8h à 10h : buffet froid (viennoiseries, pains artisanaux, confitures maison) + carte chaude (bagel, avocado toast, gaufres). Jus frais pressés et cappuccinos.',
 'Yes! Homemade breakfast is included in all our rates. Served poolside from 8am to 10am: cold buffet (pastries, artisanal breads, homemade jams) + hot menu (bagel, avocado toast, waffles). Fresh-squeezed juices and cappuccinos.',
 'dining', 2),

('Acceptez-vous les animaux ?', 'Do you accept pets?',
 'Non, malheureusement les animaux ne sont pas acceptés à l''hôtel.',
 'No, unfortunately pets are not accepted at the hotel.',
 'policy', 3),

('L''hôtel est-il fumeur ?', 'Is smoking allowed?',
 'L''hôtel est entièrement non-fumeur. Des frais de nettoyage de 70€ seront facturés en cas de non-respect.',
 'The hotel is entirely non-smoking. A €70 cleaning fee will be charged for any violation.',
 'policy', 4),

('Comment rejoindre l''île Pinel ?', 'How do I get to Pinel Island?',
 'Depuis l''hôtel, c''est très simple ! Le dock est à 20 secondes à pied. Option 1 : Ferry (10€ A/R, toutes les 30 min, 5 min de traversée). Option 2 : Nos kayaks gratuits (20-25 min de pagaie). On recommande d''y aller le matin pour le snorkeling avec les tortues.',
 'From the hotel, it''s very easy! The dock is a 20-second walk. Option 1: Ferry (€10 round trip, every 30 min, 5-min crossing). Option 2: Our free kayaks (20-25 min paddle). We recommend going in the morning for turtle snorkeling.',
 'activity', 5),

('Quelle est la politique d''annulation ?', 'What is the cancellation policy?',
 'Plus de 30 jours avant : annulation gratuite, remboursement intégral. 16-29 jours : 50% de l''acompte retenu. 15 jours ou moins : 100% de l''acompte retenu. No-show : totalité du séjour facturée.',
 '30+ days before: free cancellation, full refund. 16-29 days: 50% of deposit retained. 15 days or fewer: 100% of deposit retained. No-show: full stay amount charged.',
 'policy', 6),

('Proposez-vous un transfert aéroport ?', 'Do you offer airport transfers?',
 'Oui, nous organisons des transferts privés depuis/vers l''aéroport Princess Juliana (SXM) pour 75€ par trajet. Le trajet dure environ 20-30 minutes.',
 'Yes, we arrange private transfers to/from Princess Juliana Airport (SXM) for €75 per trip. The journey takes approximately 20-30 minutes.',
 'transport', 7),

('Avez-vous une piscine ?', 'Do you have a pool?',
 'Oui ! Notre piscine chauffée à l''eau de mer est accessible 24h/24. Parasols, bains de soleil et bouées sont à votre disposition.',
 'Yes! Our heated saltwater pool is accessible 24/7. Parasols, sunloungers and pool rings are available.',
 'amenities', 8),

('Quels moyens de paiement acceptez-vous ?', 'What payment methods do you accept?',
 'Nous acceptons Visa, Mastercard et espèces. Les chèques ne sont pas acceptés.',
 'We accept Visa, Mastercard and cash. Checks are not accepted.',
 'policy', 9),

('Proposez-vous des activités nautiques ?', 'Do you offer water activities?',
 'Oui, et gratuitement ! Kayaks, stand-up paddles et équipement de snorkeling sont à disposition. Le dock est à 20 secondes de l''hôtel. Vous pouvez pagayer jusqu''à l''île Pinel en 20 minutes !',
 'Yes, and they''re free! Kayaks, stand-up paddle boards and snorkeling gear are available. The dock is 20 seconds from the hotel. You can paddle to Pinel Island in 20 minutes!',
 'activity', 10),

('L''hôtel est-il adapté aux familles ?', 'Is the hotel family-friendly?',
 'Absolument ! Notre Suite Familiale (Marcelle & Pierre, 52 m²) combine 2 chambres communicantes avec 2 salles de bain — parfaite pour les familles. Lits bébé et lits d''appoint disponibles. Les enfants de tous âges sont les bienvenus.',
 'Absolutely! Our Family Suite (Marcelle & Pierre, 52 m²) combines 2 connecting rooms with 2 bathrooms — perfect for families. Cots and extra beds available. Children of all ages are welcome.',
 'general', 11),

('Avez-vous un restaurant ?', 'Do you have a restaurant?',
 'Nous n''avons pas de restaurant à proprement parler, mais notre Honesty Bar propose boissons (G&T, bières, vins) et planches (fromages, charcuterie) en libre-service. Le chef organise 1-2 dîners à thème par semaine (BBQ, fruits de mer) qui ressemblent à des soirées privées. Et nous sommes à 5-10 minutes des meilleurs restaurants de l''île !',
 'We don''t have a formal restaurant, but our Honesty Bar offers drinks (G&T, beers, wines) and boards (cheese, charcuterie) self-service. The chef organizes 1-2 themed dinners per week (BBQ, seafood) that feel like private parties. And we''re 5-10 minutes from the island''s best restaurants!',
 'dining', 12),

('Quand l''hôtel est-il fermé ?', 'When is the hotel closed?',
 'L''hôtel ferme chaque année du 15 août au 30 septembre (saison cyclonique). Nous rouvrons le 1er octobre.',
 'The hotel closes annually from August 15 to September 30 (hurricane season). We reopen on October 1st.',
 'general', 13),

('Peut-on privatiser l''hôtel ?', 'Can we book the entire hotel?',
 'Oui ! L''hôtel peut être réservé en exclusivité pour des réunions familiales, anniversaires, groupes d''amis ou séminaires intimes. Personnel dédié et partenaires locaux mobilisés. Contactez-nous pour un devis personnalisé.',
 'Yes! The hotel can be booked exclusively for family reunions, birthdays, friend groups or intimate seminars. Dedicated staff and local partners mobilized. Contact us for a custom quote.',
 'general', 14),

('Quels restaurants recommandez-vous ?', 'Which restaurants do you recommend?',
 'Cela dépend de vos envies ! Pour une soirée gastronomique : Le Pressoir ou La Villa Hibiscus. Pour une ambiance beach : Kontiki ou Calmos Café. Pour découvrir la cuisine locale : les lolos de Grand Case (Sky''s the Limit). Pour un dîner romantique : Spiga ou Ocean 82. Marion sera ravie de vous faire des recommandations personnalisées et de réserver pour vous !',
 'It depends on what you''re in the mood for! Gourmet evening: Le Pressoir or La Villa Hibiscus. Beach vibe: Kontiki or Calmos Café. Local cuisine: Grand Case lolos (Sky''s the Limit). Romantic dinner: Spiga or Ocean 82. Marion will be happy to give personalized recommendations and book for you!',
 'dining', 15);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RÈGLES IA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO ai_rules (rule_name, rule, condition_text, action_text, priority, is_active) VALUES

-- Escalation rules
('Plainte / Litige', 'escalation', 'Le client exprime une plainte, un mécontentement, ou demande un remboursement', 'Escalader immédiatement à Emmanuel. Ne PAS tenter de résoudre. Répondre avec empathie et indiquer qu''Emmanuel reviendra personnellement.', 100, TRUE),
('Modification réservation', 'escalation', 'Le client demande une modification ou annulation de réservation existante', 'Vérifier la disponibilité sur Thais, puis escalader à l''équipe pour validation dans Thais. L''IA ne modifie PAS les réservations.', 95, TRUE),
('Groupe 4+ personnes', 'escalation', 'Le client mentionne un groupe de plus de 4 personnes', 'Escalader à Emmanuel pour devis personnalisé (privatisation possible).', 90, TRUE),
('Demande privatisation', 'escalation', 'Le client veut réserver l''hôtel entier / privatisation / événement', 'Escalader à Emmanuel pour devis personnalisé.', 90, TRUE),
('Problème de paiement', 'escalation', 'Le client mentionne un problème de paiement, lien cassé, montant incorrect', 'Escalader immédiatement. L''IA ne gère PAS les paiements.', 95, TRUE),
('Hors périmètre', 'escalation', 'Le sujet n''est pas lié à l''hôtel ou au séjour (partenariat, presse, emploi)', 'Escalader à Emmanuel.', 80, TRUE),
('Doute IA', 'escalation', 'Le score de confiance de l''IA est inférieur à 0.7', 'Escalader plutôt que de risquer une réponse incorrecte.', 85, TRUE),
('Action physique requise', 'escalation', 'Le client demande une réservation restaurant, transfert, ou arrangement nécessitant une action physique', 'Confirmer au client que c''est noté, puis notifier l''équipe (equipe@lemartinhotel.com) pour exécution.', 75, TRUE),

-- Response rules
('Famille détectée', 'response', 'Le client mentionne enfants, famille, bébé, ou 3-4 personnes', 'Suggérer automatiquement la Suite Familiale (Marcelle & Pierre, 52 m², 2 chambres communicantes).', 70, TRUE),
('Lune de miel détectée', 'response', 'Le client mentionne lune de miel, honeymoon, mariage, anniversaire de mariage', 'Proposer le forfait Lune de Miel (Suite René, champagne, fleurs) et mentionner les expériences romantiques.', 70, TRUE),
('PMR détectée', 'response', 'Le client mentionne mobilité réduite, fauteuil roulant, handicap, accessibility', 'Recommander la Suite Marius (RDC, accès PMR, douche adaptée, entrée privée).', 80, TRUE),
('Demande de disponibilité', 'response', 'Le client demande la disponibilité pour des dates spécifiques', 'Consulter l''API Thais pour les disponibilités et tarifs exacts du jour. Ne JAMAIS inventer un prix.', 90, TRUE),
('Dates flexibles', 'response', 'Le client ne donne pas de dates précises mais demande des infos générales', 'Donner les fourchettes de prix (à partir de 294€/nuit) et inviter à préciser les dates pour un tarif exact.', 60, TRUE),
('Restaurant demandé', 'response', 'Le client demande une recommandation de restaurant', 'Utiliser la table restaurants pour recommander selon le profil (romantique, famille, budget, cuisine). Proposer de réserver.', 65, TRUE),
('Activité demandée', 'response', 'Le client demande des idées d''activités ou excursions', 'Utiliser la table activities pour recommander selon le profil. Mentionner les activités gratuites de l''hôtel en premier.', 65, TRUE),

-- Tone rules
('Ton général', 'tone', 'Toutes les réponses', 'Ton chaleureux, professionnel mais pas guindé. Comme Marion : personnalisé, attentionné, jamais robotique. Tutoiement interdit. Vouvoiement systématique en français.', 100, TRUE),
('Ton anglais', 'tone', 'Email en anglais détecté', 'Répondre en anglais. Ton warm, professional, personalized. Mention guest by first name.', 100, TRUE),
('Ton français', 'tone', 'Email en français détecté', 'Répondre en français. Vouvoiement. Ton chaleureux et professionnel. Mentionner le prénom du client.', 100, TRUE),

-- Signature rules
('Signature email', 'signature', 'Toutes les réponses sortantes', 'Signer : Marion / Le Martin Boutique Hotel / Cul de Sac, Saint-Martin', 100, TRUE),

-- Availability rules
('Fermeture annuelle', 'availability', 'Demande pour des dates entre le 15 août et le 30 septembre', 'Informer poliment que l''hôtel est fermé du 15 août au 30 septembre (saison cyclonique) et que nous rouvrons le 1er octobre. Proposer les dates les plus proches disponibles.', 95, TRUE),
('Vérification prix Thais', 'pricing', 'Toute demande de prix', 'TOUJOURS consulter l''API Thais pour le tarif exact. Ne JAMAIS inventer, estimer ou arrondir un prix.', 100, TRUE);
