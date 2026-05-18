# TaRide — Backend API

API REST Node.js + Express + PostgreSQL pour l'application de covoiturage TaRide.

## Prérequis

- Node.js >= 18
- PostgreSQL >= 14 (déjà installé selon toi)

## Installation

```bash
# 1. Installe les dépendances
npm install

# 2. Crée ton fichier d'environnement
cp .env.example .env

# 3. Remplis .env avec tes infos PostgreSQL
nano .env
```

## Configuration PostgreSQL

```bash
# Crée la base de données
psql -U postgres -c "CREATE DATABASE taride_db;"

# Applique le schéma (fichier généré précédemment)
psql -U postgres -d taride_db -f carpooling_schema.sql

# Insère les données de test
psql -U postgres -d taride_db -f seed.sql
```

## Lancement

```bash
# Développement (redémarre automatiquement à chaque modification)
npm run dev

# Production
npm start
```

Le serveur tourne sur http://localhost:3000

## Endpoints

### Publics (sans token)
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | /api/auth/register | Inscription |
| POST | /api/auth/login | Connexion |
| GET | /api/trips | Recherche de trajets |
| GET | /api/trips/:id | Détail d'un trajet |
| GET | /api/health | Santé de l'API |

### Protégés (token JWT requis)
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | /api/auth/me | Mon profil |
| POST | /api/bookings | Créer une réservation |
| GET | /api/bookings/my | Mes réservations |
| PATCH | /api/bookings/:id/cancel | Annuler une réservation |

## Tester l'API

```bash
# Santé
curl http://localhost:3000/api/health

# Inscription
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Test User","phone":"+261340000001","password":"test123","role":"passenger"}'

# Connexion
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"+261340000001","password":"test123"}'

# Recherche de trajets (public)
curl "http://localhost:3000/api/trips?departure=Analakely&destination=Ivato"

# Réserver (remplace TOKEN par le token reçu à la connexion)
curl -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"trip_id":"ID_DU_TRAJET","seats_booked":1,"payment_method":"cash"}'
```

## Compte de test (après seed.sql)

| Rôle | Téléphone | Mot de passe |
|------|-----------|--------------|
| Passager | +261344444444 | password123 |
| Chauffeur | +261341111111 | password123 |
| Chauffeur | +261342222222 | password123 |
