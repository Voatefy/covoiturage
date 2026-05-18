require('dotenv').config();
const express  = require('express');
const cors     = require('cors');
const pool     = require('./config/db');

const authRoutes    = require('./routes/auth');
const tripRoutes    = require('./routes/trips');
const bookingRoutes = require('./routes/bookings');
const reviewRoutes  = require('./routes/reviews');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

app.use('/api/auth',     authRoutes);
app.use('/api/trips',    tripRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews',  reviewRoutes);

app.get('/api/health', (_req, res) => {
  res.status(200).json({
    status:  'ok',
    message: 'TaRide API opérationnelle',
    time:    new Date().toISOString(),
  });
});

app.use((_req, res) => {
  res.status(404).json({ message: 'Route introuvable' });
});

// ── Job automatique : passe les trajets à finished ──────────────────────────
const finishExpiredTrips = async () => {
  try {
    const result = await pool.query(
      `UPDATE trips
       SET status = 'finished', updated_at = NOW()
       WHERE status = 'active'
         AND departure_datetime < NOW()
       RETURNING id, departure, destination, departure_datetime`
    );
    if (result.rows.length > 0) {
      console.log(`✅ ${result.rows.length} trajet(s) passé(s) à finished`);
    }
  } catch (err) {
    console.error('❌ Erreur job finishExpiredTrips :', err.message);
  }
};

// Lance le job au démarrage puis toutes les heures
finishExpiredTrips();
setInterval(finishExpiredTrips, 60 * 60 * 1000);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 TaRide API démarrée sur http://localhost:${PORT}`);
  console.log(`📋 Routes disponibles :`);
  console.log(`   POST   /api/auth/register`);
  console.log(`   POST   /api/auth/login`);
  console.log(`   GET    /api/auth/me`);
  console.log(`   GET    /api/trips`);
  console.log(`   GET    /api/trips/:id`);
  console.log(`   POST   /api/bookings`);
  console.log(`   GET    /api/bookings/my`);
  console.log(`   PATCH  /api/bookings/:id/cancel`);
  console.log(`   POST   /api/reviews`);
  console.log(`   GET    /api/reviews/check/:trip_id`);
  console.log(`   GET    /api/health\n`);
});