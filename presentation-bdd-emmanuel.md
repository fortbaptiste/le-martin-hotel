# Présentation de la base de données — Le Martin Boutique Hotel

**Pour Emmanuel**

---

## 1. C'est quoi cette base de données ?

Salut Emmanuel, la base de données Supabase c'est l'endroit où l'IA va chercher tout ce qu'elle a besoin de savoir pour répondre aux clients par email. C'est sa mémoire. Sans ça, elle ne sait rien sur l'hôtel, sur les chambres, sur les restaurants du coin, rien du tout. Tout ce que Marion sait de tête, l'IA le retrouve ici.

---

## 2. Comment on y accède ?

Tu vas sur supabase.com, tu te connectes sur le compte **fortbaptiste's Org**, puis tu sélectionnes le projet **le-martin-hotel**. Tu verras le badge vert **PRODUCTION** — ça veut dire que c'est la vraie base, celle que l'IA utilise en direct. Si tu changes quelque chose ici, l'IA le prend en compte.

---

## 3. Le Table Editor

C'est l'écran principal. À gauche, tu as la liste de toutes les tables (21 au total). Tu cliques sur une, et à droite tu vois son contenu en tableau, comme un fichier Excel. Tu peux chercher, trier, filtrer, et modifier directement.

---

## 4. Comment c'est organisé ?

Les 21 tables sont regroupées par rôle. En simplifiant, il y a 5 grands blocs :

- **Le savoir de l'hôtel** : rooms, hotel_services, faq, practical_info
- **Le guide local** : restaurants, beaches, activities, partners, transport_schedules
- **Les clients et réservations** : clients, reservations
- **La communication** : conversations, messages, email_templates, email_examples
- **Le pilotage de l'IA** : ai_rules, ai_corrections, escalations, daily_summaries, reviews, review_stats

---

## 5. La table `clients` — Qui sont les clients

Chaque personne qui contacte l'hôtel par email a sa fiche ici. On y trouve :

- **email** : son adresse email (c'est l'identifiant principal)
- **first_name / last_name** : prénom et nom
- **phone** : téléphone
- **language** : sa langue préférée (fr ou en) — l'IA répond dans cette langue
- **vip_score** : un score de 0 à 10 pour savoir si c'est un client fidèle ou particulier
- **total_stays** : combien de séjours il a fait
- **preferences** : ses préférences (stockées en JSON, format libre)
- **notes** : des notes manuelles
- **last_contact_at** : date du dernier contact — se met à jour automatiquement quand un message arrive

Quand un client envoie un email, l'IA cherche sa fiche ici pour savoir à qui elle parle.

---

## 6. La table `conversations` — Les fils d'emails

Chaque fil de discussion email (un thread Outlook) est enregistré ici. C'est le lien entre un client et ses échanges. Colonnes importantes :

- **client_id** : lié à la table `clients` — on sait quel client c'est
- **outlook_thread_id** : l'identifiant du thread Outlook, pour que le système retrouve le bon fil
- **subject** : l'objet de l'email
- **status** : `active`, `closed`, ou `escalated` (transféré à un humain)
- **category** : le sujet détecté par l'IA (availability, booking, restaurant, complaint, honeymoon, etc.)
- **assignee** : qui gère — `bot` par défaut, ou le nom d'un humain si c'est escaladé
- **message_count** : combien de messages dans ce fil — se met à jour tout seul

Le lien : une conversation appartient à **un client**. Un client peut avoir **plusieurs conversations**.

---

## 7. La table `messages` — Chaque email individuel

Chaque email reçu ou envoyé est stocké ici. C'est le détail fin de chaque conversation :

- **conversation_id** : lié à la table `conversations` — on sait à quel fil il appartient
- **direction** : `inbound` (email du client) ou `outbound` (réponse de l'IA ou de l'équipe)
- **from_email / to_email** : qui a envoyé, qui a reçu
- **body_text** : le contenu de l'email
- **ai_draft** : le brouillon que l'IA a généré
- **final_text** : le texte final envoyé (peut être différent si Marion a corrigé)
- **was_edited** : est-ce que Marion a modifié le brouillon avant envoi
- **confidence_score** : de 0 à 1, à quel point l'IA est sûre de sa réponse. En dessous de 0.7, ça escalade
- **tokens_input / tokens_output / cost_eur** : combien ça a coûté en utilisation de l'IA
- **detected_language** : la langue détectée

Le lien : un message appartient à **une conversation**. Une conversation contient **plusieurs messages**.

Quand un nouveau message arrive, un **trigger automatique** met à jour la conversation (message_count + 1, last_message_at) et le client (last_contact_at).

---

## 8. La table `reservations` — Les réservations

Chaque réservation est stockée ici, synchronisée avec le PMS Thais :

- **client_id** : lié à `clients`
- **conversation_id** : lié à `conversations` — quelle conversation a mené à cette réservation
- **thais_reservation_id** : l'identifiant dans le système Thais (le PMS de l'hôtel)
- **room_slug** : quelle chambre (lié à `rooms` via le slug : "marius", "rene", "marcelle", etc.)
- **checkin_date / checkout_date** : dates d'arrivée et de départ
- **nights** : calculé automatiquement (checkout - checkin)
- **guests_adults / guests_children** : nombre d'adultes et d'enfants
- **total_price / currency** : le montant
- **rate** : le type de tarif — `advance_purchase` (non remboursable), `flexible`, `honeymoon`, etc.
- **status** : `pending`, `confirmed`, `cancelled`, `completed`, `no_show`
- **special_requests** : demandes spéciales du client

Le lien : une réservation est liée à **un client** et à **une conversation**. Le `room_slug` fait le lien avec la table `rooms`.

---

## 9. La table `rooms` — Les chambres

Les 7-8 chambres/suites du Martin. Pour chacune :

- **slug** : identifiant court (ex : "marius", "pierre", "marcelle", "rene", "marthe")
- **name** : le nom complet (Suite Marius, Chambre Pierre, etc.)
- **category** : `prestige`, `deluxe` ou `family_suite`
- **size_m2** : la surface (de 22 m² pour Pierre à 41 m² pour René)
- **bed_type** : type de lit (Queen, ou Queen/2 lits simples pour Marius)
- **view_fr / view_en** : la vue en français et anglais
- **capacity_adults / capacity_children** : combien de personnes max
- **description_fr / description_en** : les descriptions bilingues
- **amenities** : tous les équipements en JSON (clim, Apple TV, Nespresso, etc.)
- **is_communicating / communicating_with** : est-ce que la chambre peut se connecter à une autre (Pierre + Marcelle = Suite Familiale)
- **price_low_season / price_high_season** : les fourchettes de prix
- **accessibility** : si c'est accessible PMR (seule Marius l'est)

Quand un client demande une chambre, l'IA regarde ici pour proposer la bonne. Par exemple :
- Famille avec enfants → elle voit que Pierre + Marcelle sont communicantes = Suite Familiale (52 m²)
- Lune de miel → elle propose René (la plus grande, vue mer panoramique)
- Mobilité réduite → elle propose Marius (RDC, accessible)

---

## 10. La table `hotel_services` — Ce que l'hôtel propose

Tous les services, gratuits ou payants :

- **slug** : identifiant (breakfast, pool, kayaks, massage-chambre, etc.)
- **name_fr / name_en** : le nom bilingue
- **category** : wellness, transport, dining, activity, room_extra, concierge, event
- **price_eur** : le prix (0 si c'est gratuit)
- **is_complimentary** : vrai si c'est inclus dans le séjour
- **description_fr / description_en** : la description

Exemples concrets : petit-déjeuner fait maison (inclus), piscine chauffée eau de mer (inclus), kayaks (inclus), transfert aéroport (90€), décoration anniversaire (75€), massage en chambre (165€).

Quand un client demande "vous avez un spa ?", l'IA cherche ici.

---

## 11. La table `faq` — Les questions fréquentes

Les réponses toutes faites aux questions classiques, en français et en anglais :

- **question_fr / question_en** : la question
- **answer_fr / answer_en** : la réponse
- **category** : general, dining, policy, activity, amenities, transport

On y retrouve par exemple : les horaires de check-in/check-out, la politique d'annulation, les animaux acceptés ou non, les activités nautiques, etc.

C'est la première source que l'IA consulte quand elle reçoit une question classique. Si la réponse est là, elle s'en sert directement.

---

## 12. La table `restaurants` — Le guide restos

Les restos recommandés autour de l'île. Pour chacun :

- **name** : le nom (Les Galets, Calmos Café, Kontiki, etc.)
- **area** : le quartier (Grand Case, Orient Bay, Marigot, etc.)
- **cuisine** : le type de cuisine
- **price** : la fourchette (€, €€, €€€, €€€€)
- **avg_price_eur** : prix moyen par personne
- **rating** : la note
- **hours / closed_day** : horaires et jour de fermeture
- **reservation_required** : faut-il réserver ?
- **specialties** : les spécialités
- **best_for** : pour qui c'est adapté (couples, familles, romantique, etc.)
- **description_fr / description_en** : descriptions bilingues
- **distance_km / driving_time_min** : à combien de l'hôtel
- **is_partner** : est-ce un partenaire de l'hôtel

Quand un client demande "quel restaurant pour un dîner romantique ?", l'IA filtre ici par `best_for` et propose. C'est le même savoir que Marion a en tête, mais structuré.

---

## 13. La table `beaches` — Le guide plages

Les plages de l'île, côté français et côté hollandais :

- **name** : le nom (Orient Bay, Happy Bay, Baie Rouge, etc.)
- **side** : `french` ou `dutch`
- **distance_km / driving_time_min / walking_time_min** : à combien de l'hôtel
- **characteristics** : ce qui la rend spéciale
- **facilities** : les équipements sur place
- **crowd_level** : le monde qu'il y a (low, moderate, high)
- **best_for** : pour qui (couples, familles, snorkeling, etc.)
- **description_fr / description_en** : descriptions bilingues

Quand un client demande "quelle plage avec peu de monde ?", l'IA filtre par `crowd_level` et recommande.

---

## 14. La table `activities` — Les activités

Les activités et excursions à faire sur l'île :

- **name_fr / name_en** : le nom bilingue
- **category** : water_sport, boat_trip, island_trip, land_activity, wellness, shopping, nightlife, cultural, family
- **operator** : qui organise l'activité
- **location** : où ça se passe
- **price_from_eur / price_to_eur** : fourchette de prix
- **duration** : la durée
- **phone / website** : pour contacter
- **best_for** : pour qui
- **booking_required** : faut-il réserver à l'avance

L'IA mentionne d'abord les activités gratuites de l'hôtel (kayak, paddle, snorkeling) avant de recommander les activités extérieures.

---

## 15. La table `partners` — Les partenaires de confiance

Les prestataires avec qui l'hôtel travaille régulièrement :

- **name** : le nom (Escale Mail, Bubble Shop, Scoobi Too, etc.)
- **service_type** : car_rental, snorkeling, gym, boat_tour, excursion, ferry
- **contact_name / contact_email / contact_phone** : les coordonnées
- **forward_template_fr / forward_template_en** : les modèles d'emails pour mettre en relation le client et le partenaire
- **pricing_info** : les infos tarifaires
- **notes** : des notes internes

Par exemple, quand un client demande une location de voiture, l'IA sait qu'il faut contacter **Escale Mail** (Sébastien & Eve) et utilise le template email pour les mettre en relation.

---

## 16. La table `transport_schedules` — Les horaires de transport

Les horaires des ferries et navettes :

- **route** : marigot_to_anguilla, anguilla_to_marigot, sxm_to_sbh, sbh_to_sxm
- **operator** : qui opère (Ferry public Marigot, Great Bay Express, etc.)
- **departure_time / arrival_time** : les heures
- **day_of_week** : daily, ou un jour précis
- **duration_minutes** : la durée
- **price_amount / price_currency** : le tarif

Quand un client demande "comment aller à Saint-Barth ?", l'IA consulte cette table et donne les horaires exacts du Great Bay Express. Quand il demande Anguilla, elle donne les horaires du ferry de Marigot.

---

## 17. La table `practical_info` — Les infos pratiques

Tout ce qui est utile pour les clients pendant leur séjour :

- **category** : emergency, health, airport, transport, shopping, bank, info
- **name** : le nom (Police, SAMU, Hôpital, Aéroport SXM, Pharmacie, Supermarché, etc.)
- **phone** : le numéro
- **distance_km / driving_time_min** : à combien de l'hôtel
- **hours** : les horaires
- **notes** : des détails (ex : "passeport obligatoire", "la plupart des commerces acceptent EUR et USD")

On y trouve les numéros d'urgence (17, 15, 18, 112, 911 côté hollandais), les pharmacies, les aéroports, les infos sur le fuseau horaire, la monnaie, l'électricité, la saison cyclonique, etc.

---

## 18. La table `email_templates` — Les modèles d'emails

Les emails types que l'IA peut utiliser ou adapter :

- **category** : restaurant_reco, car_rental, cancellation, welcome_board, birthday
- **name** : le nom du modèle
- **language** : fr ou en
- **channel** : email ou whatsapp
- **subject_line** : l'objet
- **body** : le contenu avec des variables ({guest_name}, {arrival_date}, etc.)
- **variables** : la liste des variables dynamiques
- **notes** : des consignes pour l'IA

Par exemple, le template **restaurant_reco** c'est le mail de recommandations restos que Marion envoie à chaque client. Il existe en 4 versions : FR email, EN email, FR WhatsApp, EN WhatsApp. L'IA choisit la bonne version selon la langue du client et le canal.

Le template **cancellation** a une note importante : l'IA ne doit JAMAIS confirmer une annulation seule, elle doit toujours escalader.

---

## 19. La table `email_examples` — Les exemples de conversations réelles

C'est de l'apprentissage par l'exemple. On a pris des vrais échanges entre Marion et des clients, et on les a stockés ici :

- **category** : concierge_activity, reservation_inquiry, concierge_restaurant, etc.
- **title** : un résumé
- **client_message** : ce que le client a écrit
- **marion_response** : ce que Marion a répondu
- **context** : le contexte (ex : "Client avec contrainte horaire serrée")
- **learnings** : les leçons que l'IA doit retenir de cet exemple

Par exemple : un client demande s'il peut aller à Pinel avant son vol de 13h. Marion calcule le timing (1h de trajet + 1h30 de check-in) et prévient gentiment que c'est serré. Le **learning** : "toujours calculer le timing réel quand un client a un vol".

C'est comme ça que l'IA apprend le style Marion — pas juste quoi dire, mais comment le dire.

---

## 20. La table `ai_rules` — Les règles de l'IA

Le manuel de conduite de l'IA. Chaque règle a :

- **rule_name** : le nom (Plainte/Litige, Famille détectée, Ton général, etc.)
- **rule** : le type — `escalation`, `response`, `tone`, `signature`, `availability`, `pricing`
- **condition_text** : quand appliquer cette règle
- **action_text** : quoi faire
- **priority** : de 0 à 100, plus c'est haut plus c'est prioritaire
- **is_active** : activée ou pas

Quelques règles concrètes :

**Règles d'escalation** (= transférer à un humain) :
- Plainte ou demande de remboursement → escalader à Emmanuel (priorité 100)
- Modification de réservation → escalader à l'équipe (priorité 95)
- Groupe de 4+ personnes → escalader à Emmanuel (priorité 90)
- Problème de paiement → escalader (priorité 95)
- Score de confiance < 0.7 → escalader (priorité 85)

**Règles de réponse** :
- Famille détectée → proposer la Suite Familiale Marcelle+Pierre
- Lune de miel détectée → proposer la Suite René + forfait honeymoon
- Mobilité réduite → recommander la Suite Marius (RDC, PMR)
- Demande de dispo → consulter l'API Thais, ne JAMAIS inventer un prix

**Règles de ton** :
- Ton chaleureux, professionnel mais pas guindé, comme Marion
- Vouvoiement en français, prénom du client mentionné
- En anglais : warm, professional, mention first name

---

## 21. La table `escalations` — Quand l'IA passe la main

Quand l'IA décide de transférer une conversation à un humain, un enregistrement est créé ici :

- **conversation_id** : quelle conversation est concernée (lien vers `conversations`)
- **message_id** : quel message a déclenché l'escalation (lien vers `messages`)
- **reason** : pourquoi — complaint, refund_request, booking_modification, group_request, payment_issue, low_confidence, etc.
- **confidence_score** : le score de confiance de l'IA au moment de l'escalation
- **details** : des détails sur le pourquoi
- **handled_by** : qui a pris en charge (toi, Marion, etc.)
- **resolved** : est-ce que c'est résolu
- **resolved_at** : quand
- **resolution_notes** : ce qui a été fait

C'est le suivi des cas que l'IA n'a pas pu gérer seule. Ça permet de voir combien de fois elle escalade, pour quelles raisons, et si c'est résolu.

---

## 22. La table `ai_corrections` — Quand on corrige l'IA

Si Marion modifie un brouillon de l'IA avant de l'envoyer, la correction est enregistrée ici :

- **message_id** : quel message a été corrigé (lien vers `messages`)
- **original_draft** : ce que l'IA avait écrit
- **corrected_text** : ce que Marion a mis à la place
- **correction** : le type — `tone` (ton pas bon), `factual` (erreur de fait), `missing_info` (info manquante), `wrong_info` (mauvaise info), `grammar`, `policy`
- **correction_note** : une explication
- **corrected_by** : qui a corrigé (Marion par défaut)

C'est comme ça que l'IA s'améliore avec le temps. Plus on corrige, plus elle apprend.

---

## 23. La table `reviews` — Les avis clients

Les avis Google et Tripadvisor importés :

- **source** : google ou tripadvisor
- **author_name** : qui a laissé l'avis
- **rating** : la note (1 à 5)
- **review_text** : le texte de l'avis
- **original_language** : la langue d'origine
- **travel_group** : couple, famille, solo, amis
- **visit_type** : vacances ou affaires
- **sub_rating_rooms / sub_rating_service / sub_rating_location** : les sous-notes
- **highlights** : les points forts mentionnés
- **owner_response** : la réponse de l'hôtel

L'IA peut utiliser ces avis pour savoir ce que les clients apprécient le plus, et adapter ses réponses. Par exemple, si beaucoup d'avis mentionnent le petit-déjeuner, elle le met en avant.

---

## 24. La table `review_stats` — Les stats des avis

Un résumé par plateforme :

- **platform** : google, tripadvisor
- **total_reviews** : nombre total d'avis
- **average_rating** : note moyenne
- **rating_5_count / rating_4_count / ...** : combien d'avis par note

Pour l'instant : 5.0 de moyenne sur Google avec 219 avis. L'IA peut mentionner ça dans ses réponses si c'est pertinent.

---

## 25. La table `daily_summaries` — Les rapports quotidiens

Un résumé automatique chaque jour :

- **date** : le jour
- **emails_received** : combien d'emails reçus
- **emails_replied** : combien l'IA a répondu
- **emails_escalated** : combien ont été escaladés
- **avg_response_time_ms** : temps de réponse moyen
- **avg_confidence_score** : score de confiance moyen
- **total_tokens_used / total_cost_eur** : ce que ça a coûté
- **summary_text** : un résumé texte
- **sent_to_owner** : est-ce que le résumé t'a été envoyé

C'est ton tableau de bord quotidien.

---

## 26. Comment les tables se parlent entre elles

Voici les relations principales :

```
clients
  └── conversations (un client a plusieurs conversations)
        ├── messages (une conversation a plusieurs messages)
        │     ├── ai_corrections (un message peut avoir des corrections)
        │     └── escalations (un message peut déclencher une escalation)
        └── reservations (une conversation peut mener à une réservation)
              └── rooms (via room_slug)
```

Et les tables de "connaissance" que l'IA consulte :
```
faq ─────────────────── réponses rapides aux questions classiques
rooms ───────────────── pour recommander la bonne chambre
hotel_services ──────── pour parler des services
restaurants ─────────── pour recommander un resto
beaches ─────────────── pour recommander une plage
activities ──────────── pour recommander une activité
partners ────────────── pour mettre en relation avec un partenaire
transport_schedules ──── pour donner des horaires de ferry
practical_info ──────── pour les infos pratiques (urgences, pharmacie, etc.)
email_templates ─────── pour utiliser les bons modèles d'email
email_examples ──────── pour apprendre le style Marion
ai_rules ────────────── pour savoir comment réagir
```

---

## 27. Le parcours d'un email client — de A à Z

Voici ce qui se passe quand un client envoie un email :

1. L'email arrive sur Outlook
2. Le système cherche le **client** dans la table `clients` (ou le crée)
3. Il cherche la **conversation** existante dans `conversations` (ou en crée une)
4. Le message est enregistré dans `messages` (direction = inbound)
5. L'IA consulte les **ai_rules** pour savoir comment réagir
6. Elle vérifie si c'est une question classique dans la **faq**
7. Si besoin, elle cherche dans **rooms**, **restaurants**, **beaches**, **activities**, etc.
8. Elle regarde les **email_templates** et **email_examples** pour le format
9. Elle génère un brouillon (stocké dans `messages.ai_draft`)
10. Si le score de confiance est trop bas, elle crée une **escalation**
11. Sinon, le brouillon est envoyé (ou relu par Marion qui peut corriger → **ai_corrections**)
12. En fin de journée, un **daily_summary** est généré

---

## 28. Ce que tu peux modifier toi-même

Les tables que tu peux modifier sans risque :

- **faq** : ajouter/modifier des questions-réponses. Si tu vois que les clients posent toujours la même question, ajoute-la ici
- **ai_rules** : ajuster le comportement de l'IA. Par exemple, ajouter une nouvelle règle d'escalation
- **hotel_services** : mettre à jour les prix, ajouter un nouveau service
- **rooms** : mettre à jour les descriptions ou les prix saisonniers
- **restaurants** : ajouter un nouveau resto ou mettre à jour les infos
- **email_templates** : modifier le texte des emails types
- **practical_info** : mettre à jour un numéro de téléphone, un horaire

Les tables que tu ne touches pas (elles se remplissent automatiquement) :
- clients, conversations, messages, escalations, ai_corrections, daily_summaries

---

## 29. Le bouton Insert et la modification

- **Ajouter une ligne** : bouton vert **Insert** en haut → ça ouvre un formulaire vide
- **Modifier une valeur** : double-clic sur une cellule → tu changes → c'est enregistré
- **Supprimer** : sélectionne une ligne, clic droit, Delete

Les changements sont immédiats. Pas de bouton "sauvegarder", c'est en direct.

---

## 30. En résumé

La base de données, c'est tout ce que l'IA sait. Elle ne sait rien d'autre que ce qui est dedans.

- Tu veux qu'elle réponde différemment ? → Modifie les **ai_rules**
- Elle dit un truc faux sur l'hôtel ? → Corrige dans **rooms**, **hotel_services**, ou **faq**
- Tu veux qu'elle recommande un nouveau resto ? → Ajoute-le dans **restaurants**
- Un horaire de ferry a changé ? → Mets à jour **transport_schedules**
- Un nouveau partenaire ? → Ajoute-le dans **partners**

Tout part de là. Si l'info est bonne ici, l'IA répond bien. Si l'info est fausse ou manquante, l'IA se plante ou escalade.

---

*Document préparé pour Emmanuel — Mars 2026*
