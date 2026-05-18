const jwt = require('jsonwebtoken');

// Middleware qui vérifie le token JWT sur les routes protégées
const authenticate = (req, res, next) => {
  // Le token arrive dans le header : "Authorization: Bearer <token>"
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Token manquant — connecte-toi d\'abord',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    // Vérifie la signature et l'expiration du token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, phone, role } disponible dans la route
    next();
  } catch (err) {
    return res.status(401).json({
      message: 'Token invalide ou expiré — reconnecte-toi',
    });
  }
};

// Middleware qui vérifie que l'utilisateur est un passager
const requirePassenger = (req, res, next) => {
  if (req.user.role !== 'passenger') {
    return res.status(403).json({
      message: 'Accès réservé aux passagers',
    });
  }
  next();
};

// Middleware qui vérifie que l'utilisateur est un chauffeur
const requireDriver = (req, res, next) => {
  if (req.user.role !== 'driver') {
    return res.status(403).json({
      message: 'Accès réservé aux chauffeurs',
    });
  }
  next();
};

module.exports = { authenticate, requirePassenger, requireDriver };
