const express  = require('express');
const router   = express.Router();
const { createBooking, getMyBookings, cancelBooking } = require('../controllers/bookingController');
const { authenticate, requirePassenger }              = require('../middleware/auth');

// Toutes les routes bookings sont protégées
router.use(authenticate);
router.use(requirePassenger);

router.post('/',               createBooking);   // créer une réservation
router.get('/my',              getMyBookings);   // mes réservations
router.patch('/:id/cancel',    cancelBooking);   // annuler une réservation

module.exports = router;
