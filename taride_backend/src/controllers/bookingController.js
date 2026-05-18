const pool = require("../config/db");

// ── POST /api/bookings ──────────────────────────────────────────────────────
// Route PROTÉGÉE — passager connecté uniquement
const createBooking = async (req, res) => {
  const { trip_id, seats_booked = 1, payment_method } = req.body;
  const passenger_id = req.user.id;

  if (!trip_id || !payment_method) {
    return res.status(400).json({
      message: "trip_id et payment_method sont requis",
    });
  }

  if (!["cash", "mobile_money"].includes(payment_method)) {
    return res.status(400).json({
      message: "payment_method invalide : cash ou mobile_money",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // 1. Vérifie que le trajet existe et est actif
    const tripResult = await client.query(
      `SELECT t.id, t.driver_id, t.available_seats, t.price_per_passenger,
              t.status, t.departure, t.destination, t.departure_datetime,
              u.full_name AS driver_name
       FROM trips t
       JOIN users u ON u.id = t.driver_id
       WHERE t.id = $1
       FOR UPDATE`,
      [trip_id],
    );

    if (tripResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ message: "Trajet introuvable" });
    }

    const trip = tripResult.rows[0];

    if (trip.status !== "active") {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Ce trajet n'est plus disponible",
      });
    }

    // 2. Vérifie qu'il y a assez de places
    if (trip.available_seats < seats_booked) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: `Seulement ${trip.available_seats} place(s) disponible(s)`,
      });
    }

    // 3. Vérifie que le passager ne réserve pas son propre trajet
    if (trip.driver_id === passenger_id) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Tu ne peux pas réserver ton propre trajet",
      });
    }

    // 4. Vérifie que le passager n'a pas déjà réservé ce trajet
    const existingBooking = await client.query(
      `SELECT id FROM bookings
       WHERE trip_id = $1
         AND passenger_id = $2
         AND status NOT IN ('rejected', 'cancelled')`,
      [trip_id, passenger_id],
    );

    if (existingBooking.rows.length > 0) {
      await client.query("ROLLBACK");
      return res.status(409).json({
        message: "Tu as déjà une réservation pour ce trajet",
      });
    }

    // 5. Crée la réservation
    const totalAmount = trip.price_per_passenger * seats_booked;

    const bookingResult = await client.query(
      `INSERT INTO bookings (trip_id, passenger_id, seats_booked, status)
       VALUES ($1, $2, $3, 'pending')
       RETURNING id, trip_id, passenger_id, seats_booked, status, created_at`,
      [trip_id, passenger_id, seats_booked],
    );

    const booking = bookingResult.rows[0]; // ← déclaré ICI avant toute utilisation

    // 6. Crée l'entrée de paiement
    await client.query(
      `INSERT INTO payments (booking_id, amount, method, status)
       VALUES ($1, $2, $3, 'pending')`,
      [booking.id, totalAmount, payment_method],
    );

    // 7. Décrémente les places disponibles du trajet
    await client.query(
      `UPDATE trips
       SET available_seats = available_seats - $1
       WHERE id = $2`,
      [seats_booked, trip_id],
    );

    await client.query("COMMIT");

    return res.status(201).json({
      id: booking.id,
      trip_id: booking.trip_id,
      passenger_id: booking.passenger_id,
      seats_booked: booking.seats_booked,
      status: booking.status,
      created_at: booking.created_at,
      payment_method,
      total_amount: totalAmount,
      trip: {
        departure: trip.departure,
        destination: trip.destination,
        departure_datetime: trip.departure_datetime,
        driver_name: trip.driver_name,
      },
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("Erreur createBooking :", err.message);
    return res.status(500).json({ message: "Erreur serveur" });
  } finally {
    client.release();
  }
};

// ── GET /api/bookings/my ────────────────────────────────────────────────────
// Route PROTÉGÉE — retourne les réservations du passager connecté
const getMyBookings = async (req, res) => {
  const passenger_id = req.user.id;

  try {
    const result = await pool.query(
      `SELECT
    b.id,
    b.trip_id,
    b.seats_booked,
    b.status,
    b.created_at,
    p.method      AS payment_method,
    p.amount      AS total_amount,
    t.departure,
    t.destination,
    t.departure_datetime,
    t.status      AS trip_status,
    u.full_name   AS driver_name
   FROM bookings b
   JOIN trips t    ON t.id = b.trip_id
   JOIN users u    ON u.id = t.driver_id
   LEFT JOIN payments p ON p.booking_id = b.id
   WHERE b.passenger_id = $1
   ORDER BY b.created_at DESC`,
      [passenger_id],
    );

    const bookings = result.rows.map((row) => ({
      id: row.id,
      trip_id: row.trip_id,
      seats_booked: row.seats_booked,
      status: row.status,
      payment_method: row.payment_method,
      total_amount: parseFloat(row.total_amount),
      created_at: row.created_at,
      trip: {
        departure: row.departure,
        destination: row.destination,
        departure_datetime: row.departure_datetime,
        trip_status: row.trip_status,
        driver_name: row.driver_name,
      },
    }));

    return res.status(200).json(bookings);
  } catch (err) {
    console.error("Erreur getMyBookings :", err.message);
    return res.status(500).json({ message: "Erreur serveur" });
  }
};

// ── PATCH /api/bookings/:id/cancel ──────────────────────────────────────────
// Route PROTÉGÉE — annuler sa propre réservation + remet les places
const cancelBooking = async (req, res) => {
  const { id } = req.params;
  const passenger_id = req.user.id;

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // 1. Annule la réservation
    const result = await client.query(
      `UPDATE bookings
       SET status = 'cancelled'
       WHERE id = $1
         AND passenger_id = $2
         AND status = 'pending'
       RETURNING id, status, seats_booked, trip_id`,
      [id, passenger_id],
    );

    if (result.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Réservation introuvable ou déjà traitée",
      });
    }

    const { seats_booked, trip_id } = result.rows[0];

    // 2. Remet les places disponibles dans le trajet
    await client.query(
      `UPDATE trips
       SET available_seats = available_seats + $1
       WHERE id = $2`,
      [seats_booked, trip_id],
    );

    await client.query("COMMIT");

    return res.status(200).json({
      message: "Réservation annulée",
      booking: result.rows[0],
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("Erreur cancelBooking :", err.message);
    return res.status(500).json({ message: "Erreur serveur" });
  } finally {
    client.release();
  }
};

module.exports = { createBooking, getMyBookings, cancelBooking };
