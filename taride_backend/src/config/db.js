const { Pool } = require('pg');
require('dotenv').config();

// Pool de connexions PostgreSQL
// Un pool réutilise les connexions au lieu d'en créer une nouvelle à chaque requête
const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     parseInt(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Test de connexion au démarrage
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Erreur connexion PostgreSQL :', err.message);
  } else {
    console.log('✅ PostgreSQL connecté');
    release();
  }
});

module.exports = pool;
