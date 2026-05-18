const express  = require('express');
const router   = express.Router();
const { searchTrips, getTripById } = require('../controllers/tripController');

// Routes PUBLIQUES — aucun token requis
router.get('/',    searchTrips);
router.get('/:id', getTripById);

module.exports = router;
