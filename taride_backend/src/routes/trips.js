const express  = require('express');
const router   = express.Router();
const {
  searchTrips,
  getTripById,
  getDepartures,
  getDestinations,
} = require('../controllers/tripController');

// Routes publiques
router.get('/locations/departures',   getDepartures);
router.get('/locations/destinations', getDestinations);
router.get('/',                       searchTrips);
router.get('/:id',                    getTripById);

module.exports = router;