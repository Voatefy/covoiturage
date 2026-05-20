const pool = require('../config/db');

// ── GET /api/trips ──────────────────────────────────────────────────────────
// Route PUBLIQUE — aucun token requis
// Paramètres query : departure, destination, date (optionnels)
const searchTrips = async (req, res) => {
  const { departure, destination, date } = req.query;

  try {
    // Construction dynamique de la requête selon les filtres fournis
    let query = `
      SELECT
        t.id,
        t.departure,
        t.destination,
        t.departure_datetime,
        t.available_seats,
        t.price_per_passenger,
        t.status,
        u.full_name   AS driver_name,
        u.average_rating AS driver_rating,
        u.is_verified
      FROM trips t
      JOIN users u ON u.id = t.driver_id
      WHERE t.status = 'active'
        AND t.available_seats > 0
        AND t.departure_datetime > NOW()
    `;

    const params = [];
    let paramIndex = 1;

    // Filtre par départ (recherche insensible à la casse)
    if (departure) {
      query += ` AND t.departure ILIKE $${paramIndex}`;
      params.push(`%${departure}%`);
      paramIndex++;
    }

    // Filtre par destination
    if (destination) {
      query += ` AND t.destination ILIKE $${paramIndex}`;
      params.push(`%${destination}%`);
      paramIndex++;
    }

    // Filtre par date (toute la journée)
    if (date) {
      query += ` AND DATE(t.departure_datetime) = $${paramIndex}`;
      params.push(date);
      paramIndex++;
    }

    query += ' ORDER BY t.departure_datetime ASC';

    const result = await pool.query(query, params);

    return res.status(200).json(result.rows);

  } catch (err) {
    console.error('Erreur searchTrips :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── GET /api/trips/:id ──────────────────────────────────────────────────────
// Route PUBLIQUE — détail d'un trajet
const getTripById = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT
        t.id,
        t.departure,
        t.destination,
        t.departure_datetime,
        t.available_seats,
        t.price_per_passenger,
        t.status,
        u.full_name      AS driver_name,
        u.average_rating AS driver_rating,
        u.is_verified
       FROM trips t
       JOIN users u ON u.id = t.driver_id
       WHERE t.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Trajet introuvable' });
    }

    return res.status(200).json(result.rows[0]);

  } catch (err) {
    console.error('Erreur getTripById :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── GET /api/trips/locations/departures ─────────────────────────────────────
// Retourne tous les points de départ distincts des trajets actifs
const getDepartures = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT DISTINCT departure
       FROM trips
       WHERE status = 'active'
         AND departure_datetime > NOW()
         AND available_seats > 0
       ORDER BY departure ASC`
    );
    return res.status(200).json(result.rows.map((r) => r.departure));
  } catch (err) {
    console.error('Erreur getDepartures :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── GET /api/trips/locations/destinations ───────────────────────────────────
// Retourne les destinations disponibles depuis un départ donné
const getDestinations = async (req, res) => {
  const { departure } = req.query;

  if (!departure) {
    return res.status(400).json({ message: 'departure requis' });
  }

  try {
    const result = await pool.query(
      `SELECT DISTINCT destination
       FROM trips
       WHERE status = 'active'
         AND departure_datetime > NOW()
         AND available_seats > 0
         AND departure ILIKE $1
       ORDER BY destination ASC`,
      [departure]
    );
    return res.status(200).json(result.rows.map((r) => r.destination));
  } catch (err) {
    console.error('Erreur getDestinations :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { searchTrips, getTripById, getDepartures, getDestinations };