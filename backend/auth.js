const fs = require('fs');
const path = require('path');

// Tokens valides = ceux des utilisateurs de db.json (lus une seule fois).
const db = JSON.parse(fs.readFileSync(path.join(__dirname, 'db.json'), 'utf8'));
const validTokens = new Set(db.users.map((u) => u.token));

module.exports = (req, res, next) => {
  // La route de connexion reste publique.
  if (req.path.startsWith('/users')) return next();

  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';

  if (validTokens.has(token)) return next();

  res.status(401).jsonp({ error: 'Non autorisé' });
};