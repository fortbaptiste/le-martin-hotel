# Documentation webhooks Thaïs PMS 

## Introduction

Les webhooks permettent aux partenaires d'être informés en temps réel des événements survenant dans notre PMS. Lorsque des événements spécifiques se produisent, une requête HTTP POST est envoyée à l'URL d'API distante définie par l'utilisateur, avec un payload JSON contenant les informations pertinentes et structurées.

## Structure Générale des Webhooks

### URL de Destination

Chaque partenaire peut configurer une ou plusieurs URLs d'API distante qui seront appelées lors d'événements prédéfinis.

Pour des raisons de sécurité, notre système de webhook est limité à l’appel de pages web utilisant exclusivement les ports standards 80 (HTTP) et 443 (HTTPS).

### Méthode HTTP

**POST** : Les données de l'événement sont transmises dans le corps de la requête.

### Format du Payload JSON

```json
{
  "instance": "xxxxxxx",
  "event_type": "<type d'événement>",
  "action": "<action spécifique>",
  "entity": "<entité concernée>",
  "entity_id": <ID de l'entité>,
  "operation": "<type d'opération>",
  "fields": [
    "<champs modifiés>"
  ],
  "data": {
    // Données additionnelles spécifiques à l'événement
  }
}
```

### Explication des Champs

- **`instance`** : Identifiant unique de l'instance liée à l'événement
- **`event_type`** : Type d'événement (%webhook.event_types%).
- **`action`** : Action spécifique déclenchée (%webhook.actions%).
- **`entity`** : Entité principale concernée par l'événement (par exemple, booking, booking\_rooms, `customers`, etc.).
- **`entity_id`** : Identifiant unique de l'entité affectée.
- **`operation`** : Type d'opération effectuée (par exemple, `update`, `create`, `delete`).
- **`fields`** : Liste des champs modifiés (si applicable).
- **`data`** : Objet contenant des données supplémentaires relatives à l'événement.

## Exemples de Payloads

### Exemple 1 : Mise à jour du rooming d'une réservation

```json
{
  "instance": "xxxxxxx",
  "event_type": "bookings",
  "action": "UPDATE_BOOKING",
  "entity": "booking_rooms",
  "entity_id": 52231,
  "operation": "update",
  "fields": [
    "rooming_customer_id"
  ],
  "data": {
    "booking_id": 35665
  }
}
```

### Exemple 2 : Mise à jour de l'état d'une réservation

```json
{
  "instance": "xxxxxxx",
  "event_type": "bookings",
  "action": "UPDATE_BOOKING",
  "entity": "booking_rooms",
  "entity_id": 52231,
  "operation": "update",
  "fields": [
    "state"
  ],
  "data": {
    "booking_id": 35665
  }
}
```

### Exemple 3 : Mise à jour des informations client

```json
{
  "instance": "xxxxxxx",
  "event_type": "customers",
  "action": "UPDATE_RESORT_CUSTOMER",
  "entity": "customers",
  "entity_id": 26218,
  "operation": "update",
  "fields": [
    "firstname",
    "updated_at"
  ],
  "data": []
}
```

## Gestion des Réponses

Pour indiquer que l'événement a été traité avec succès, l'endpoint distant doit retourner une réponse avec un statut HTTP **200 OK**. Si une erreur survient, un statut HTTP approprié (par exemple, 4xx ou 5xx) doit être renvoyé.

## Bonnes Pratiques

1. **Sécurité** : Configurez une clé d'API/token dans l'URL.
2. **Logs** : Enregistrez toutes les requêtes reçues pour faciliter le débogage.
3. **Retry** : Nous effectuons des retry automatiques si la réponse n'est pas une réponse avec un statut HTTP 200 OK.

## Support

Pour toute question ou assistance, veuillez contacter notre équipe technique via [support@thais-pms.com](mailto\:support@thais-pms.com).