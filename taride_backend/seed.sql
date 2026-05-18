-- ============================================================
-- SEED — Données de test pour TaRide
-- Lance ce script APRÈS avoir créé le schéma (carpooling_schema.sql)
-- ============================================================

-- Mot de passe pour tous les comptes de test : "password123"
-- Hash bcrypt de "password123" avec 10 rounds
-- Tu peux le regénérer avec : node -e "console.log(require('bcryptjs').hashSync('password123', 10))"

-- ── Chauffeurs vérifiés ─────────────────────────────────────────────────────
INSERT INTO users (id, full_name, phone, email, password_hash, role, average_rating, is_verified)
VALUES
  ('11111111-0000-0000-0000-000000000001',
   'Rakoto Ny',
   '+261341111111',
   'rakoto@example.mg',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'driver', 4.9, true),

  ('11111111-0000-0000-0000-000000000002',
   'Hery Andry',
   '+261342222222',
   'hery@example.mg',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'driver', 4.2, true),

  ('11111111-0000-0000-0000-000000000003',
   'Soa Mialy',
   '+261343333333',
   null,
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'driver', 4.7, true)
ON CONFLICT (phone) DO NOTHING;

-- ── Passager de test ────────────────────────────────────────────────────────
INSERT INTO users (id, full_name, phone, email, password_hash, role, is_verified)
VALUES
  ('22222222-0000-0000-0000-000000000001',
   'Tefy Passager',
   '+261344444444',
   'tefy@example.mg',
   '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
   'passenger', true)
ON CONFLICT (phone) DO NOTHING;

-- ── Trajets disponibles ─────────────────────────────────────────────────────
INSERT INTO trips (driver_id, departure, destination, departure_datetime, available_seats, price_per_passenger, status)
VALUES
  -- Rakoto Ny : Analakely → Ivato demain matin
  ('11111111-0000-0000-0000-000000000001',
   'Analakely', 'Ivato',
   NOW() + INTERVAL '1 day' + TIME '07:30:00',
   2, 2000, 'active'),

  -- Rakoto Ny : Analakely → Ivato après-demain
  ('11111111-0000-0000-0000-000000000001',
   'Analakely', 'Ivato',
   NOW() + INTERVAL '2 days' + TIME '08:00:00',
   3, 2000, 'active'),

  -- Hery Andry : Antaninarenina → Ambohimanarina
  ('11111111-0000-0000-0000-000000000002',
   'Antaninarenina', 'Ambohimanarina',
   NOW() + INTERVAL '1 day' + TIME '08:00:00',
   1, 1500, 'active'),

  -- Soa Mialy : 67 Ha → Andravoahangy
  ('11111111-0000-0000-0000-000000000003',
   '67 Ha', 'Andravoahangy',
   NOW() + INTERVAL '1 day' + TIME '09:00:00',
   3, 2500, 'active'),

  -- Hery Andry : Analakely → Ivato (concurrent)
  ('11111111-0000-0000-0000-000000000002',
   'Analakely', 'Ivato',
   NOW() + INTERVAL '1 day' + TIME '08:00:00',
   1, 1500, 'active'),

  -- Soa Mialy : Analakely → Ivato (concurrent)
  ('11111111-0000-0000-0000-000000000003',
   'Analakely', 'Ivato',
   NOW() + INTERVAL '1 day' + TIME '10:00:00',
   3, 2500, 'active')
ON CONFLICT DO NOTHING;
