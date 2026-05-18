const pool = require('../config/db');

// ── POST /api/reviews ───────────────────────────────────────────────────────
const createReview = async (req, res) => {
  const { trip_id, rating, comment } = req.body;
  const reviewer_id = req.user.id;

  if (!trip_id || !rating) {
    return res.status(400).json({
      message: 'trip_id et rating sont requis',
    });
  }

  if (rating < 1 || rating > 5) {
    return res.status(400).json({
      message: 'La note doit être entre 1 et 5',
    });
  }

  try {
    // Vérifie que le passager a bien un booking accepted sur ce trajet
    const bookingCheck = await pool.query(
      `SELECT b.id FROM bookings b
       JOIN trips t ON t.id = b.trip_id
       WHERE b.trip_id    = $1
         AND b.passenger_id = $2
         AND b.status     = 'accepted'
         AND t.status     = 'finished'`,
      [trip_id, reviewer_id]
    );

    if (bookingCheck.rows.length === 0) {
      return res.status(403).json({
        message: 'Tu ne peux évaluer que les trajets terminés que tu as effectués',
      });
    }

    // Récupère le driver_id du trajet
    const tripResult = await pool.query(
      'SELECT driver_id FROM trips WHERE id = $1',
      [trip_id]
    );

    if (tripResult.rows.length === 0) {
      return res.status(404).json({ message: 'Trajet introuvable' });
    }

    const reviewed_id = tripResult.rows[0].driver_id;

    // Vérifie qu'il n'a pas déjà noté ce trajet
    const existingReview = await pool.query(
      `SELECT id FROM reviews
       WHERE reviewer_id = $1 AND trip_id = $2`,
      [reviewer_id, trip_id]
    );

    if (existingReview.rows.length > 0) {
      return res.status(409).json({
        message: 'Tu as déjà évalué ce trajet',
      });
    }

    // Crée l'évaluation
    const result = await pool.query(
      `INSERT INTO reviews (reviewer_id, reviewed_id, trip_id, rating, comment)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, rating, comment, created_at`,
      [reviewer_id, reviewed_id, trip_id, rating, comment || null]
    );

    return res.status(201).json({
      message: 'Évaluation enregistrée',
      review:  result.rows[0],
    });

  } catch (err) {
    console.error('Erreur createReview :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── GET /api/reviews/check/:trip_id ─────────────────────────────────────────
// Vérifie si le passager a déjà noté ce trajet
const checkReview = async (req, res) => {
  const { trip_id } = req.params;
  const reviewer_id = req.user.id;

  try {
    const result = await pool.query(
      `SELECT id, rating, comment FROM reviews
       WHERE reviewer_id = $1 AND trip_id = $2`,
      [reviewer_id, trip_id]
    );

    return res.status(200).json({
      has_reviewed: result.rows.length > 0,
      review:       result.rows[0] || null,
    });

  } catch (err) {
    console.error('Erreur checkReview :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { createReview, checkReview };