const express    = require('express');
const router     = express.Router();
const { register, login, me } = require('../controllers/authController');
const { authenticate }        = require('../middleware/auth');

// Routes publiques
router.post('/register', register);
router.post('/login',    login);

// Route protégée — profil de l'utilisateur connecté
router.get('/me', authenticate, me);

module.exports = router;
