const express  = require('express');
const router   = express.Router();
const { createReview, checkReview } = require('../controllers/reviewController');
const { authenticate, requirePassenger } = require('../middleware/auth');

router.use(authenticate);
router.use(requirePassenger);

router.post('/',                createReview);
router.get('/check/:trip_id',   checkReview);

module.exports = router;