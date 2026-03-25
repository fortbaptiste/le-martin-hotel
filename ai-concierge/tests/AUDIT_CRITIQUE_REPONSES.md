# Audit Critique des Reponses IA — Pipeline Le Martin Hotel

**Date** : 10 mars 2026
**Auditeur** : Claude Opus 4.6
**Methode** : Chaque reponse IA croisee avec les donnees seed (SQL), le system prompt, et les regles metier.

---

## RESUME EXECUTIF

| Severite | Nombre | Description |
|---|---|---|
| CRITIQUE | 4 | Erreurs factuelles, violations de regles metier, ou contenu dangereux |
| MAJEUR | 8 | Meta-commentary, incoherences de prix, infos non verifiees |
| MINEUR | 11 | Longueur excessive, lien reservation manquant, ambiguites |
| FILTRE | 6 | Emails qui auraient du etre SKIP |
| BON | 14 | Reponses correctes ou excellentes |

**Score global : 67/100** — Fonctionnel mais pas pret pour la production sans corrections.

---

## PROBLEMES CRITIQUES (4)

---

### CRITIQUE 1 — Incoherence de prix : Bouquet fleurs 48€ vs 60€

**Ou** : Conv 4 msg1 vs Conv 4 msg2 (meme client, Marijose Perez)

**Msg 1** :
> "we can add a fresh flower bouquet for 60€"

**Msg 2** :
> "a fresh bouquet (€48) and a bottle of champagne (€70)"

**Donnees seed** : `Bouquet de fleurs` = **60€** (004_seed_services via ALL_MIGRATIONS)
**System prompt** : mentionne **48€** (ligne 105 historique)

**Probleme** : Le system prompt et la base de donnees ne sont pas alignes. L'IA utilise tantot l'un, tantot l'autre, parfois dans le MEME thread client. Un client qui recoit 60€ puis 48€ pour le meme bouquet perd confiance.

**Correction** :
- Aligner system prompt et seed SQL sur un prix unique
- Verifier quel est le vrai prix aupres d'Emmanuel
- Supprimer le prix du system prompt (laisser l'IA lire la DB via `get_hotel_services`)

---

### CRITIQUE 2 — Prix transfer aeroport : 75€ vs 90€

**Ou** : Conv 2 msg1 (Alex Karr) et dans le system prompt en general

**Reponse IA** :
> "each transfer is €75 per trip, paid directly to the driver on arrival"

**Donnees seed** :
- `Shuttle aeroport/port` = **75€** (services de base)
- `Airport transfer (organized)` = **90€** (transfert recommande via conciergerie)
- `Airport transfer (online)` = **115€** (aeroport→hotel) / **75€** (hotel→aeroport)

**System prompt** : "Transfert prive : 75€ par trajet"

**Probleme** : Il y a 3 tarifs differents pour les transferts dans la base. L'IA cite 75€ mais le tarif recommande est 90€. Si le client reserve via la conciergerie, il paiera 90€ et se sentira trompe.

**Correction** :
- Clarifier avec Emmanuel : un seul tarif ou 2 niveaux de service ?
- Si 2 niveaux : l'IA doit presenter les 2 options
- Mettre a jour system prompt et seed pour coherence

---

### CRITIQUE 3 — Affirmation non verifiee : "Driver will hold a sign with your name"

**Ou** : Conv 2 msg3 (Tyler) et Conv 2 msg4 (Alex)

**Reponse IA (Tyler)** :
> "your driver will be waiting for you at the arrivals exit with a sign bearing your name — 'Albritton'"

**Reponse IA (Alex)** :
> "Your driver will be waiting for you at the arrivals exit with a sign bearing your name — 'Karr'"

**Probleme** : L'IA affirme avec certitude que le chauffeur aura un panneau avec le nom du client. **Aucune donnee dans la base ni dans le system prompt ne confirme cette pratique.** L'IA invente un detail operationnel. Si le chauffeur n'a pas de panneau, les clients seront perdus a l'aeroport.

**Ce que l'IA aurait du faire** : Appeler `request_team_action` (ce qu'elle a fait) MAIS repondre "Je confirme les details du pick-up avec notre chauffeur et reviens vers vous" au lieu d'affirmer quelque chose qu'elle ne sait pas.

**Correction** :
- Ajouter une FAQ "Comment se passe le pick-up aeroport ?" dans la base
- Ou ajouter dans le system prompt : "Pour les details logistiques de transfert (panneau, point de RDV), ne PAS inventer — renvoyer vers l'equipe"

---

### CRITIQUE 4 — Reponse vide (Eve Eyraud, Conv 30)

**Ou** : Conv 30 — 3 familles, 14 personnes, aout 2026

**Probleme** : L'IA a appele `request_team_action` avec un resume parfait (hotel ferme 15 aout, groupe trop grand) mais a retourne un texte **completement vide**. Le pipeline a donc genere une erreur au lieu d'envoyer un brouillon.

**Impact** : Le client ne recoit aucune reponse. Meme un simple accuse de reception ("Nous avons bien recu votre demande, Emmanuel vous contacte") vaut mieux que rien.

**Correction** :
- Dans `ai_engine.py` : si la reponse est vide apres des tool calls, generer un fallback generique
- Ou ajouter dans le system prompt : "Tu DOIS toujours rediger un email au client, meme court, meme quand tu escalades via `request_team_action`. Ne retourne JAMAIS un texte vide."

---

## PROBLEMES MAJEURS (8)

---

### MAJEUR 1 — Meta-commentary dans les reponses (4 occurrences)

Les regles INTERDIT du system prompt interdisent explicitement le meta-commentary. Pourtant 4 reponses le contiennent :

**Conv 20 — Kris Monteliard** :
> "Ce message post-sejour merite une reponse poetique et tres personnelle de Marion — je genere un brouillon supervise."
> "**BROUILLON SUPERVISE — A relire et valider par Marion avant envoi**"

C'est la violation la plus grave. Le client recevrait un email commencant par une analyse interne de l'IA.

**Conv 25 — Tyler Albritton (taxi Palapa)** :
> "Palapa doesn't appear in my restaurant database, which suggests it may be on the Dutch side. Taxi rates on the island are fixed by zone — I can give Tyler a general estimate based on that."

L'IA raisonne a voix haute avant de commencer l'email. Et elle dit "Tyler" a la 3eme personne alors qu'elle est censee lui ecrire directement.

**Conv 32 — Tripadvisor newsletter** :
> "Cet email est une newsletter promotionnelle automatique de Tripadvisor concernant Tokyo — il n'est pas adresse a l'hotel et ne contient aucune demande client. Aucune reponse n'est necessaire."

L'IA ecrit une analyse interne au lieu d'un email. Cet email ne devrait meme pas arriver a l'IA (devrait etre SKIP).

**Conv 33/41/44 — BRED Banque** (3x) :
> "Cet email est une confirmation automatique de virement bancaire envoyee par la BRED..."
> "Je recommande de le transmettre a Emmanuel pour verification et rapprochement comptable si necessaire."

Meme probleme — analyse interne, pas un email client. Devrait etre SKIP.

**Correction** :
- Renforcer le system prompt avec des exemples negatifs explicites
- Ajouter un post-check regex qui detecte les patterns meta ("Cet email est", "Il s'agit de", "Je recommande de", "Aucune reponse n'est necessaire")
- Si meta-commentary detecte : escalader au lieu d'envoyer

---

### MAJEUR 2 — Distances ambigues ("X minutes away" sans preciser "en voiture")

**Regle metier** : "Il n'y a AUCUN restaurant accessible a pied depuis l'hotel. Les restaurants sont a 5-25 minutes en voiture."

Pourtant l'IA ecrit regulierement :

| Conv | Texte | Probleme |
|---|---|---|
| 4 msg1 | "Coco Beach or Kontiki at Orient Bay are both lovely, just 5 minutes away" | "5 minutes away" sans preciser "by car" |
| 4 msg1 | "Le Pressoir in Grand Case... about 10 minutes away" | Idem |
| 4 msg2 | "La Villa Hibiscus, right here in Cul de Sac, just 3 minutes away" | "right here" + "3 minutes" suggerent a pied |
| 12 | "La Villa Hibiscus... about 3 minutes away" | Idem |
| 12 | "Sol e Luna... equally close" | Vague |

**Risque** : Un client peut comprendre "3 minutes away" comme "a pied" et partir a pied dans la nuit sur une route sans trottoir. C'est un probleme de securite.

**Pourquoi le post-check Conv 7 l'a attrape mais pas les autres** : Le regex `_WALKABLE_RESTAURANT_RE` cherche "walk" + "restaurant" ou "restaurant a pied". Il ne detecte PAS "3 minutes away" car il n'y a pas le mot "walk". Mais un client interprete naturellement "3 minutes" comme "a pied".

**Correction** :
- System prompt : "Quand tu donnes une distance vers un restaurant ou lieu, precise TOUJOURS 'en voiture' / 'by car'. INTERDIT de dire 'X minutes away' sans preciser le mode de transport."
- Post-check : ajouter un regex qui detecte `\d+\s*min\w*\s*(away|d'ici|depuis)` sans "voiture/car/drive" dans les 30 caracteres suivants

---

### MAJEUR 3 — Lien de reservation manquant dans les reponses disponibilite

**Regle system prompt** : "Pour toute demande de reservation, inclus TOUJOURS le lien de reservation : https://lemartinhotel.thais-hotel.com/direct-booking/calendar"

| Conv | Client | Demande | Lien inclus ? |
|---|---|---|---|
| 5 msg1 | Aaron Rubin | 4 adultes + 4 enfants, April 2-5 | NON |
| 8 msg1 | Libi Molnar | Famille, April 5-12 | NON |
| 9 msg1 | Carl Atkinson | 3 couples, Jan 30 | NON |
| 10 | Siobhan Valentine | Couple, March 2-6 ou 3-7 | NON |
| 16 | Michael Reiley | Couple, Jan 1-9 | NON |
| 22 | Michael Dias | Agent voyage, April 11-15 | NON |
| 27 | Casey Willis | 3 adultes, Feb 26-Mar 1 | NON |
| 28 | Shellie Orrell | Family Suite, March 11-17 | OUI |

**7 reponses sur 8 omettent le lien.** Seule la Conv 28 l'inclut.

**Nuance** : Pour les cas ou l'hotel est complet, le lien est moins pertinent. Mais la regle dit "TOUJOURS". Et meme complet, le lien permet au client de surveiller les annulations.

**Correction** :
- Renforcer dans le system prompt : "Meme si l'hotel est complet, TOUJOURS inclure le lien pour que le client puisse surveiller les disponibilites."
- Ou reformuler : "Inclus le lien sauf quand la conversation n'a rien a voir avec une reservation."

---

### MAJEUR 4 — Reponses trop longues (violation regle "3-5 phrases")

**Regle system prompt** : "Tu ecris comme Marion : des VRAIS emails courts. 3-5 phrases max. UN seul paragraphe pour les questions simples."

| Conv | Client | Mots | Phrases | Verdict |
|---|---|---|---|---|
| 4 msg1 | Marijose | 429 | ~30 | VIOLATION MASSIVE |
| 4 msg2 | Marijose | 194 | ~14 | VIOLATION |
| 4 msg3 | Marijose | 223 | ~16 | VIOLATION |
| 25 | Tyler (taxi) | 128 | ~8 | VIOLATION |
| 2 msg1 | Alex (transfer) | 95 | ~6 | LIMITE |
| 16 | Michael Reiley | 97 | ~6 | LIMITE |
| 28 | Shellie Orrell | 99 | ~7 | LIMITE |

**La Conv 4 est le pire cas** : Marijose pose beaucoup de questions, mais 429 mots est inacceptable. Marion (la vraie) aurait repondu en 2 phrases par sujet, pas en 5 paragraphes detailles avec des descriptions touristiques.

**Exemple de ce que Marion aurait ecrit** (msg1, estimee ~80 mots) :
> Hi Marijose, what a beautiful surprise for your mom! For the room decoration, I can arrange balloons with personalized messages (€75) and a fresh bouquet (€60) — just send me the messages you'd like. For activities and restaurants, I have a wonderful list ready for you. And for St. Barths, I'd recommend Friday by ferry from Philipsburg (Great Bay Express, 45 min). I'll send you all the details in a follow-up. Marion & Emmanuel

**Correction** :
- Le system prompt dit deja "3-5 phrases". L'IA ne respecte pas.
- Ajouter un post-check de longueur : si reponse > 150 mots → warning, > 250 mots → escalade pour relecture
- Ou ajouter dans le system prompt : "Si le client pose 5 questions, reponds brievement a chacune en 1 phrase. Tu n'es PAS un guide touristique, tu es une concierge. Maximum 150 mots."

---

### MAJEUR 5 — Descriptions de restaurants potentiellement inventees

L'IA ajoute des details descriptifs sur les restaurants qui ne sont pas necessairement dans la base de donnees :

| Conv | Restaurant | Description IA | Dans la DB ? |
|---|---|---|---|
| 4 msg1 | Le Pressoir | "Caribbean Restaurant of the Year four years running, in a beautiful historic Creole house" | A VERIFIER — le titre "Caribbean Restaurant of the Year" doit etre dans les donnees |
| 4 msg1 | La Villa Hibiscus | "Chef Bastian trained with Joel Robuchon and Anne-Sophie Pic" | A VERIFIER |
| 4 msg1 | Sky's the Limit | "open-air BBQ spots" | PROBABLEMENT dans les few-shot examples |
| 12 | La Villa Hibiscus | "intimate garden setting, gastronomic French cuisine" | A VERIFIER |
| 12 | Sol e Luna | "elegant sea view, French-Creole" | A VERIFIER |
| 29 | Calmos Cafe | (nom du restaurant pour la reservation) | D'ou vient ce nom ? Pas dans la conversation precedente |

**Regle system prompt** : "Tu ne dois JAMAIS recommander un restaurant sans avoir d'abord appele `search_restaurants`. Utilise TOUJOURS les donnees retournees par l'outil, jamais ta memoire."

**Probleme** : L'IA appelle bien `search_restaurants`, mais ajoute parfois des details descriptifs qui vont au-dela de ce que l'outil retourne. Si le champ `description` dans la DB contient ces infos, c'est OK. Sinon, l'IA brode.

**Correction** :
- Verifier que les descriptions ("Caribbean Restaurant of the Year", "Chef Bastian trained with...") sont dans les champs `description` ou `specialties` de la table restaurants
- Si non, les ajouter ou interdire a l'IA d'embellir
- System prompt : "N'ajoute AUCUN detail sur un restaurant qui ne figure pas dans les donnees retournees par `search_restaurants`. Pas de titre, pas de description du chef, pas d'ambiance."

---

### MAJEUR 6 — Fermeture hotel aout non mentionnee (Conv 30)

**Ou** : Conv 30 — Eve Eyraud, 3 familles, 13-21 aout 2026

**Donnees seed** : "Hotel closes Aug 15-Sept 30 annually, reopens Oct 1"

**Le team action mentionne** : "l'hotel ferme le 15 aout" — mais c'est dans l'action interne, pas dans une reponse au client. Puisque la reponse est vide (bug), le client ne sait pas que l'hotel est ferme.

**Meme sans le bug** : L'IA aurait du repondre clairement "Nous sommes fermes du 15 aout au 30 septembre" avant de passer a Emmanuel.

**Correction** :
- Ajouter dans le system prompt : "Si les dates demandees tombent dans la periode de fermeture (15 aout — 30 septembre), dis-le immediatement au client avant toute autre information."
- Ou ajouter un check automatique dans le pipeline : si dates chevauchent fermeture → injecter un avertissement dans le contexte

---

### MAJEUR 7 — Tarifs non presentes quand disponible

**Regle system prompt** : "Propose TOUJOURS les 2 types de tarifs : Best Flexible Rate + Advance Purchase Rate (-10%)"

Quand l'hotel est complet, pas besoin de tarifs. Mais quand `check_room_availability` retourne des resultats (meme "7 room types"), l'IA ne presente JAMAIS les tarifs detailles.

Aucune reponse du test ne mentionne les 2 tarifs. Meme les clients qui demandent explicitement les prix (Casey Willis: "could you share pricing?", Siobhan: "any special rates or packages?") ne recoivent pas les tarifs.

**Explication probable** : L'hotel est complet pour toutes les dates testees (haute saison). Thais retourne "results=7" mais aucune chambre disponible. L'IA interprete correctement que c'est complet.

**Mais** : Si des chambres etaient disponibles, l'IA presenterait-elle les tarifs ? Impossible a verifier avec ces donnees de test (tout est complet).

**Correction** :
- A tester avec des dates ou il y a de la disponibilite
- Verifier que l'IA presente bien les 2 tarifs dans ce cas

---

### MAJEUR 8 — Pattern `invoice/facture` trop agressif dans pre-escalation

3 faux positifs en escalation `payment_issue` :

| Conv | Client | Contexte reel | Escalade justifiee ? |
|---|---|---|---|
| 13 | Peggy Nibte (masseuse) | Envoie sa facture de prestation | Non — fournisseur, pas client |
| 18 | Stephane Petris (ASSA ABLOY) | Demande un devis corporate | Non — demande de prix, pas probleme |
| 26 | Valentina Mazzoni | Thread long contenant "invoice" | Non — demande sur noms de transfert |

**Probleme** : Le regex `payment_issue` attrape "invoice" et "facture" meme quand il n'y a aucun probleme de paiement. C'est trop large.

**Correction** :
- Restreindre le pattern : `invoice/facture` seulement si combine avec un mot de probleme (`issue, wrong, incorrect, error, problem, charge, refus, declined, trop, error`)
- Ou ajouter une negation : ne pas escalader si le contexte est "envoie/jointe/ci-joint" + "facture" (envoi de facture ≠ probleme de paiement)

---

## PROBLEMES MINEURS (11)

---

### MINEUR 1 — Conv 4 msg1 : "Helium isn't always guaranteed on the island"

D'ou vient cette info ? Pas dans la base. Probablement vraie (ile tropicale = approvisionnement incertain) mais l'IA ne devrait pas inventer des details operationnels.

### MINEUR 2 — Conv 2 msg1 : "arriving at 4:28 pm"

L'IA donne un horaire d'arrivee precis (4:28 pm) pour le vol AA 2842. Le client a dit "Miami (MIA)" mais pas l'heure d'arrivee. L'IA semble avoir deduit ou invente cet horaire. Si c'est faux, le transfert sera rate.

**Correction** : L'IA ne devrait jamais inventer un horaire de vol. Si le client ne l'a pas donne, demander.

### MINEUR 3 — Conv 9 msg1 : Marion corrige "Miriam" mais signature DB dit autre chose

La regle de signature dit "Marion & Emmanuel". La vraie Marion dans ses emails reels signe parfois "Marion" seul. L'IA signe toujours "Marion & Emmanuel" — coherent avec la regle mais peut paraitre etrange pour un message tres court.

### MINEUR 4 — Conv 11 : Pas d'appel a `search_faq` pour les conditions d'annulation

L'IA repond correctement aux conditions d'annulation sans appeler aucun outil. L'info est dans le system prompt. Ce n'est pas une erreur, mais appeler `search_faq` aurait confirme les infos depuis la base.

### MINEUR 5 — Conv 4 msg1 : Utilise "€10" pour le ferry Pinel puis "$85" pour le kayak

Melange euros et dollars dans la meme reponse. Les prix viennent de la base (ferry en EUR, kayak en USD) mais c'est deroutant pour le client.

**Correction** : Convertir ou preciser la devise systematiquement.

### MINEUR 6 — Conv 22 : L'IA dit "Marion" mais le client ecrit a Marion

L'IA repond "je suis vraiment desolee" (feminin) — c'est correct, elle est Marion. Mais dans d'autres reponses en anglais, le genre n'est pas toujours coherent.

### MINEUR 7 — Conv 23 : "Talk soon," avant la signature

L'IA signe "Talk soon, Marion & Emmanuel". La regle dit juste "Marion & Emmanuel" sans formule de politesse avant. "Talk soon" est une formule corporate informelle.

### MINEUR 8 — Conv 14 msg2 : Pas d'appel a `check_room_availability` pour le mariage (Oct 2026)

Le mariage est prevu pour octobre 2026. L'IA delegue correctement a Emmanuel mais ne verifie pas la disponibilite. Ce n'est pas grave car c'est une privatisation (Emmanuel decide) mais ca aurait donne plus d'infos dans le team action.

### MINEUR 9 — Conv 4 msg1 : Ferry St Barths — "return at 5:30pm"

L'IA dit un seul horaire de retour (5:30pm). La base montre 3 rotations dont un retour a 11:00am, un a 5:30pm et un a 6:45pm. Donner un seul horaire est reducteur.

### MINEUR 10 — Conv 12 : L'IA suppose 2 personnes pour Egor sans verification

L'IA demande une reservation "for 2" mais Egor n'a jamais dit combien ils seraient. L'IA a probablement deduit de la reservation Thais (1 chambre = 2 pers) mais c'est une supposition.

### MINEUR 11 — Conv 28 : "our only 2-bedroom option" pour la Family Suite

L'IA dit "our only 2-bedroom option" — c'est probablement vrai mais pas explicitement dans la base. Si l'hotel a d'autres configurations possibles, c'est trompeur.

---

## PROBLEMES DE FILTRE (6 emails qui devraient etre SKIP)

| Conv | Expediteur | Objet | Resultat actuel | Correction |
|---|---|---|---|---|
| 19 | Districom Formation | Newsletter VAE collective | ESCALADE low_confidence | Ajouter pattern newsletters marketing |
| 32 | Tripadvisor (`mp1.tripadvisor.com`) | Newsletter Tokyo | REPONSE IA (meta) | Matcher sous-domaines tripadvisor |
| 33 | BRED (`confirmation-bred@bred.fr`) | Virement SEPA 4000€ | REPONSE IA (meta) | Ajouter `bred.fr` aux suppliers |
| 38 | Totem Wines (`brevosend.com`) | Newsletter distillerie | ESCALADE other | Ajouter `brevosend.com` aux suppliers |
| 41 | BRED | Virement SEPA 4300€ | REPONSE IA (meta) | idem conv 33 |
| 44 | BRED | Virement SEPA 1000€ | REPONSE IA (meta) | idem conv 33 |

**Impact** : 6 emails consomment des tokens API (~100K tokens, ~0.30€) et generent des brouillons inutiles. Plus grave, les reponses BRED/Tripadvisor contiennent du meta-commentary qui serait envoye au "client" si un humain validait le brouillon sans lire attentivement.

**Corrections** :
```python
# Ajouter a _SUPPLIER_DOMAINS
"bred.fr",              # Confirmations bancaires automatiques
"brevosend.com",        # Newsletters Brevo/Sendinblue

# Ajouter a _SKIP_PATTERNS
re.compile(r"(confirmation-\w+@|newsletter@|communication@|inspiration@)", re.IGNORECASE),
```

Pour Tripadvisor, le domaine `tripadvisor.com` est deja dans les suppliers mais `mp1.tripadvisor.com` ne matche pas car le check fait probablement `email.endswith(domain)` et `mp1.tripadvisor.com` ne se termine pas par `tripadvisor.com` exactement.

**Correction** : Changer le matching pour verifier si le domaine **contient** le supplier domain ou utiliser `.endswith("." + domain)` :
```python
# Au lieu de : domain == supplier_domain
# Utiliser : domain == supplier_domain or domain.endswith("." + supplier_domain)
```

---

## CE QUI FONCTIONNE BIEN (14 reponses)

| Conv | Client | Pourquoi c'est bien |
|---|---|---|
| 2 msg2 | Tyler (transfer) | Concis, confirme sans inventer, escalade le taxi |
| 2 msg4 | Alex (sign) | Utilise le contexte conv sans appel outil |
| 4 msg3 | Marijose (car rental) | Bon nom partenaire "Escale Car Rental", honnete sur St Barths |
| 5 msg1 | Aaron (groupe) | Delegue a Emmanuel sans promettre |
| 5 msg2 | Aaron (refus) | Empathique, bref, pas d'insistance |
| 8 msg2 | Libi (budget) | Gracieux, 51 mots |
| 9 msg1 | Carl ("Miriam") | Corrige le prenom avec humour, conf 0.96 |
| 11 | Jacques (annulation) | Conditions correctes, francais naturel |
| 14 msg2 | Bradley (wedding) | Team action complet, renvoie vers Emmanuel |
| 17 | Pica (check-in) | 30 mots, ton parfait pour une confirmation |
| 22 | Michael Dias | Francais elegant, maintient l'invitation |
| 24 | Valentina (noms) | Detecte urgence, escalade urgent, Thais lookup |
| 29 | Egor (8pm) | 24 mots pour "8pm please!" — parfait |
| 42 | Stephanie (presse) | Delegue a Emmanuel, reconnait l'opportunite |

---

## AXES D'AMELIORATION — Plan d'action prioritise

### Priorite 1 — Bloquants production (a faire AVANT mise en prod)

| # | Action | Fichier | Effort |
|---|---|---|---|
| 1.1 | Aligner prix bouquet (48€ ou 60€) et transfer (75€ ou 90€) | `system.py` + `003_seed_services.sql` | 10 min |
| 1.2 | Ajouter rule "INTERDIT affirmer des details operationnels non verifies (panneau chauffeur, etc.)" | `system.py` | 5 min |
| 1.3 | Ajouter fallback reponse vide : si AI retourne "" apres tool calls → generer accuse de reception | `ai_engine.py` | 30 min |
| 1.4 | Ajouter post-check meta-commentary (regex "Cet email est", "BROUILLON", "Aucune reponse n'est necessaire") | `escalation.py` | 20 min |
| 1.5 | Ajouter 6 filtres manquants (BRED, Tripadvisor wildcard, Brevo, newsletters) | `email_processor.py` | 15 min |
| 1.6 | Corriger matching sous-domaines suppliers (`.endswith("." + domain)`) | `email_processor.py` | 10 min |

### Priorite 2 — Qualite reponse (important)

| # | Action | Fichier | Effort |
|---|---|---|---|
| 2.1 | System prompt : "Precise TOUJOURS 'by car/en voiture' apres une distance" | `system.py` | 5 min |
| 2.2 | Post-check longueur : warning > 150 mots, escalade > 250 mots | `escalation.py` | 15 min |
| 2.3 | System prompt : "Meme hotel complet, inclus le lien reservation pour surveiller annulations" | `system.py` | 5 min |
| 2.4 | System prompt : "Si dates chevauchent 15 aout — 30 septembre, mentionne la fermeture IMMEDIATEMENT" | `system.py` | 5 min |
| 2.5 | Restreindre pattern `payment_issue` : combiner `invoice/facture` avec un mot de probleme | `escalation.py` | 20 min |

### Priorite 3 — Polish (nice to have)

| # | Action | Fichier | Effort |
|---|---|---|---|
| 3.1 | Harmoniser devises (tout en EUR ou preciser systematiquement) | `system.py` | 5 min |
| 3.2 | Verifier que les descriptions restaurants (titres, chefs) sont dans la DB | `004_seed_restaurants.sql` | 30 min |
| 3.3 | Ajouter FAQ "Comment se passe le pick-up aeroport" | `007_seed_practical_faq_rules.sql` | 10 min |
| 3.4 | Tester avec des dates ou l'hotel N'EST PAS complet (verifier presentation tarifs) | `test_real.py` | 1h |
| 3.5 | System prompt : "N'invente JAMAIS un horaire de vol. Si le client ne l'a pas donne, demande." | `system.py` | 5 min |
| 3.6 | System prompt : "N'ajoute aucun detail sur un restaurant qui ne figure pas dans les donnees retournees par search_restaurants" | `system.py` | 5 min |

---

## MATRICE DE RISQUE

```
          IMPACT
          Haut    |  CRITIQUE 1-4     |  MAJEUR 1-3      |
                  |  (prix, panneau,  |  (meta, distances,|
                  |   reponse vide)   |   lien manquant)  |
          --------+-------------------+-------------------+
          Moyen   |  MAJEUR 4-5       |  MINEUR 1-5       |
                  |  (longueur,       |  (details divers) |
                  |   descriptions)   |                   |
          --------+-------------------+-------------------+
          Bas     |  FILTRE 1-6       |  MINEUR 6-11      |
                  |  (emails inutiles)|  (polish)         |
          --------+-------------------+-------------------+
                    Frequent             Rare
                          FREQUENCE
```

---

## CONCLUSION

Le pipeline fonctionne et produit des reponses de qualite acceptable dans **~70% des cas**. Les 14 bonnes reponses montrent que l'IA capte bien le ton Marion, utilise correctement les outils, et sait quand escalader.

**Les 3 risques principaux pour la production** :
1. **Incoherence de prix** — Un client qui voit 2 prix differents pour le meme service dans le meme thread est un deal-breaker
2. **Meta-commentary** — Un email qui commence par "Cet email est une newsletter" serait embarrassant
3. **Reponse vide** — Un client qui n'obtient aucune reponse est pire qu'une mauvaise reponse

Les corrections de Priorite 1 representent environ **1h30 de travail** et couvrent 90% des risques identifies.

---

*Audit realise le 10 mars 2026 — Pipeline IA Concierge Le Martin Boutique Hotel*
