-- ============================================================
-- APPLICATION DE COVOITURAGE - SCHÉMA POSTGRESQL COMPLET DATABASE NAME IS taride_db
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE user_role AS ENUM ('driver', 'passenger');

CREATE TYPE document_type AS ENUM ('permis', 'carte_id');

CREATE TYPE document_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TYPE trip_status AS ENUM ('active', 'cancelled', 'finished');

CREATE TYPE booking_status AS ENUM ('pending', 'accepted', 'rejected', 'cancelled');

CREATE TYPE payment_method AS ENUM ('cash', 'mobile_money');

CREATE TYPE payment_status AS ENUM ('pending', 'paid');

-- ============================================================
-- TABLE : users
-- ============================================================

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       VARCHAR(150) NOT NULL,
    phone           VARCHAR(20) NOT NULL UNIQUE,
    email           VARCHAR(255) UNIQUE,
    password_hash   TEXT NOT NULL,
    role            user_role NOT NULL,
    average_rating  NUMERIC(3, 2) DEFAULT NULL CHECK (average_rating >= 1 AND average_rating <= 5),
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE : driver_documents
-- ============================================================

CREATE TABLE driver_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type   document_type NOT NULL,
    document_url    TEXT NOT NULL,
    status          document_status NOT NULL DEFAULT 'pending',
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at     TIMESTAMPTZ DEFAULT NULL,
    CONSTRAINT fk_driver_documents_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================================
-- TABLE : trips
-- ============================================================

CREATE TABLE trips (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id               UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    departure               VARCHAR(255) NOT NULL,
    departure_coords        POINT DEFAULT NULL,         -- (longitude, latitude) ex: POINT(47.5361, -18.9136)
    destination             VARCHAR(255) NOT NULL,
    destination_coords      POINT DEFAULT NULL,         -- (longitude, latitude)
    departure_datetime      TIMESTAMPTZ NOT NULL,
    available_seats         SMALLINT NOT NULL CHECK (available_seats >= 1),
    price_per_passenger     NUMERIC(10, 2) NOT NULL CHECK (price_per_passenger >= 0),
    status                  trip_status NOT NULL DEFAULT 'active',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_trips_driver FOREIGN KEY (driver_id) REFERENCES users(id)
);

-- ============================================================
-- TABLE : bookings
-- ============================================================

CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE RESTRICT,
    passenger_id    UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    seats_booked    SMALLINT NOT NULL DEFAULT 1 CHECK (seats_booked >= 1),
    status          booking_status NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_bookings_trip FOREIGN KEY (trip_id) REFERENCES trips(id),
    CONSTRAINT fk_bookings_passenger FOREIGN KEY (passenger_id) REFERENCES users(id),
    CONSTRAINT uq_booking_passenger_trip UNIQUE (trip_id, passenger_id)
);

-- ============================================================
-- TABLE : payments
-- ============================================================

CREATE TABLE payments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    amount      NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    method      payment_method NOT NULL,
    status      payment_status NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES bookings(id),
    CONSTRAINT uq_payment_booking UNIQUE (booking_id)
);

-- ============================================================
-- TABLE : reviews
-- ============================================================

CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reviewer_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewed_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    rating          SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment         TEXT DEFAULT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_id) REFERENCES users(id),
    CONSTRAINT fk_reviews_reviewed FOREIGN KEY (reviewed_id) REFERENCES users(id),
    CONSTRAINT fk_reviews_trip FOREIGN KEY (trip_id) REFERENCES trips(id),
    CONSTRAINT chk_no_self_review CHECK (reviewer_id <> reviewed_id),
    CONSTRAINT uq_review_per_trip UNIQUE (reviewer_id, reviewed_id, trip_id)
);

-- ============================================================
-- TRIGGERS : updated_at automatique
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_trips_updated_at
    BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TRIGGER : is_verified mis à jour selon document_status
-- ============================================================

CREATE OR REPLACE FUNCTION sync_driver_verification()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' THEN
        UPDATE users SET is_verified = TRUE, updated_at = NOW()
        WHERE id = NEW.user_id;
    ELSIF NEW.status = 'rejected' THEN
        UPDATE users SET is_verified = FALSE, updated_at = NOW()
        WHERE id = NEW.user_id;
    END IF;

    IF NEW.status IN ('approved', 'rejected') THEN
        NEW.reviewed_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_driver_document_status
    BEFORE UPDATE OF status ON driver_documents
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION sync_driver_verification();

-- ============================================================
-- TRIGGER : recalcul note moyenne après chaque review
-- ============================================================

CREATE OR REPLACE FUNCTION update_average_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users
    SET average_rating = (
        SELECT ROUND(AVG(rating)::NUMERIC, 2)
        FROM reviews
        WHERE reviewed_id = NEW.reviewed_id
    ),
    updated_at = NOW()
    WHERE id = NEW.reviewed_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_rating_after_review
    AFTER INSERT OR UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_average_rating();

-- ============================================================
-- FONCTION UTILITAIRE : distance approximative entre deux POINTs
-- Utilise la formule de Haversine simplifiée (précision suffisante en ville)
-- Retourne la distance en kilomètres
-- Usage : SELECT point_distance_km(departure_coords, POINT(47.5361, -18.9136)) FROM trips;
-- ============================================================

CREATE OR REPLACE FUNCTION point_distance_km(p1 POINT, p2 POINT)
RETURNS FLOAT AS $$
DECLARE
    lat1 FLOAT := radians(p1[1]);
    lat2 FLOAT := radians(p2[1]);
    dlat FLOAT := radians(p2[1] - p1[1]);
    dlng FLOAT := radians(p2[0] - p1[0]);
    a    FLOAT;
BEGIN
    a := sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlng/2)^2;
    RETURN 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- INDEX
-- ============================================================

-- users
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_verified ON users(is_verified);

-- trips
CREATE INDEX idx_trips_departure ON trips(departure);
CREATE INDEX idx_trips_destination ON trips(destination);
CREATE INDEX idx_trips_departure_datetime ON trips(departure_datetime);
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_search ON trips(departure, destination, departure_datetime);

-- Index GIST pour recherches géographiques sur les coordonnées POINT
CREATE INDEX idx_trips_departure_coords   ON trips USING GIST(departure_coords);
CREATE INDEX idx_trips_destination_coords ON trips USING GIST(destination_coords);

-- bookings
CREATE INDEX idx_bookings_trip_id ON bookings(trip_id);
CREATE INDEX idx_bookings_passenger_id ON bookings(passenger_id);
CREATE INDEX idx_bookings_status ON bookings(status);

-- driver_documents
CREATE INDEX idx_driver_documents_user_id ON driver_documents(user_id);
CREATE INDEX idx_driver_documents_status ON driver_documents(status);

-- payments
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(status);

-- reviews
CREATE INDEX idx_reviews_reviewed_id ON reviews(reviewed_id);
CREATE INDEX idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX idx_reviews_trip_id ON reviews(trip_id);
