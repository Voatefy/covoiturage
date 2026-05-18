const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const pool     = require('../config/db');

// ── Génère un token JWT pour un utilisateur ─────────────────────────────────
const generateToken = (user) => {
  return jwt.sign(
    { id: user.id, phone: user.phone, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// ── POST /api/auth/register ─────────────────────────────────────────────────
const register = async (req, res) => {
  const { full_name, phone, email, password, role } = req.body;

  // Validation des champs obligatoires
  if (!full_name || !phone || !password || !role) {
    return res.status(400).json({
      message: 'Champs obligatoires manquants : full_name, phone, password, role',
    });
  }

  if (!['driver', 'passenger'].includes(role)) {
    return res.status(400).json({ message: 'Rôle invalide' });
  }

  try {
    // Vérifie si le téléphone est déjà utilisé
    const existing = await pool.query(
      'SELECT id FROM users WHERE phone = $1',
      [phone]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({
        message: 'Ce numéro de téléphone est déjà utilisé',
      });
    }

    // Vérifie si l'email est déjà utilisé (si fourni)
    if (email) {
      const existingEmail = await pool.query(
        'SELECT id FROM users WHERE email = $1',
        [email]
      );
      if (existingEmail.rows.length > 0) {
        return res.status(409).json({
          message: 'Cette adresse email est déjà utilisée',
        });
      }
    }

    // Hash du mot de passe — jamais stocker en clair
    // Le "10" = nombre de rounds de salage, bon équilibre sécurité/performance
    const passwordHash = await bcrypt.hash(password, 10);

    // Insertion en base
    const result = await pool.query(
      `INSERT INTO users (full_name, phone, email, password_hash, role)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, full_name, phone, email, role, is_verified, created_at`,
      [full_name, phone, email || null, passwordHash, role]
    );

    const user = result.rows[0];
    const token = generateToken(user);

    return res.status(201).json({
      token,
      user: {
        id:          user.id,
        full_name:   user.full_name,
        phone:       user.phone,
        email:       user.email,
        role:        user.role,
        is_verified: user.is_verified,
      },
    });

  } catch (err) {
    console.error('Erreur register :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── POST /api/auth/login ────────────────────────────────────────────────────
const login = async (req, res) => {
  const { phone, password } = req.body;

  if (!phone || !password) {
    return res.status(400).json({
      message: 'Téléphone et mot de passe requis',
    });
  }

  try {
    // Cherche l'utilisateur par téléphone
    const result = await pool.query(
      `SELECT id, full_name, phone, email, role,
              password_hash, is_verified
       FROM users
       WHERE phone = $1`,
      [phone]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        message: 'Téléphone ou mot de passe incorrect',
      });
    }

    const user = result.rows[0];

    // Compare le mot de passe avec le hash stocké
    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatch) {
      return res.status(401).json({
        message: 'Téléphone ou mot de passe incorrect',
      });
    }

    const token = generateToken(user);

    return res.status(200).json({
      token,
      user: {
        id:          user.id,
        full_name:   user.full_name,
        phone:       user.phone,
        email:       user.email,
        role:        user.role,
        is_verified: user.is_verified,
      },
    });

  } catch (err) {
    console.error('Erreur login :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── GET /api/auth/me ────────────────────────────────────────────────────────
// Retourne le profil de l'utilisateur connecté
const me = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, full_name, phone, email, role,
              average_rating, is_verified, created_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }

    return res.status(200).json(result.rows[0]);

  } catch (err) {
    console.error('Erreur me :', err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
};

module.exports = { register, login, me };
