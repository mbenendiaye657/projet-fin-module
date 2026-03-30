/**
 * mbened-dev — Application Node.js (VM2 Serveur Web)
 * Nginx reverse proxy -> Node.js -> MySQL (VM3)
 * mbenendiaye657 — projet-fin-module
 */

const express = require('express');
const mysql   = require('mysql2');
const app     = express();
const port    = process.env.PORT || 3000;

// Configuration de la connexion MySQL vers VM3
const db = mysql.createConnection({
  host:     process.env.DB_HOST     || '192.168.10.10',
  user:     process.env.DB_USER     || 'appuser',
  password: process.env.DB_PASSWORD || 'apppassword123',
  database: process.env.DB_NAME     || 'appdb'
});

// Connexion à MySQL
db.connect(err => {
  if (err) {
    console.error('Erreur connexion MySQL:', err.message);
  } else {
    console.log('Connecté à MySQL sur VM3 (192.168.10.10)');
  }
});

app.use(express.json());

// Page principale
app.get('/', (req, res) => {
  db.query('SELECT * FROM messages ORDER BY created_at DESC', (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Erreur base de données', details: err.message });
    }
    const html = `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Architecture 3-Tiers — mbened-dev</title>
  <style>
    body { background: #0a0a1a; color: #fff; font-family: Arial, sans-serif; text-align: center; padding: 40px; }
    h1 { color: #ff4444; font-size: 2.5em; }
    h2 { color: #00bfff; }
    .info { background: #1a1a2e; border-radius: 10px; padding: 20px; margin: 20px auto; max-width: 600px; }
    .tag { display: inline-block; background: #00ff88; color: #000; padding: 4px 12px; border-radius: 20px; margin: 4px; font-weight: bold; }
    table { margin: 20px auto; border-collapse: collapse; min-width: 400px; }
    th { background: #1f3864; padding: 10px 20px; }
    td { padding: 8px 20px; border-bottom: 1px solid #333; }
    tr:hover { background: #1a1a2e; }
  </style>
</head>
<body>
  <h1>Architecture 3-Tiers sur OpenShift</h1>
  <div class="info">
    <p>
      <span class="tag">VM1 — Firewall</span>
      <span class="tag">VM2 — Web (Nginx)</span>
      <span class="tag">VM3 — MySQL</span>
    </p>
    <p style="color:#00ff88; font-size:1.2em;">Déployé par <strong>mbenendiaye657</strong> — mbened-dev</p>
    <p>Serveur : <strong>192.168.100.10</strong> (Zone DMZ)</p>
  </div>
  <h2>Messages depuis MySQL (VM3)</h2>
  <table>
    <tr><th>#</th><th>Message</th><th>Date</th></tr>
    ${results.map(r => `<tr><td>${r.id}</td><td>${r.contenu}</td><td>${new Date(r.created_at).toLocaleString('fr-FR')}</td></tr>`).join('')}
  </table>
</body>
</html>`;
    res.send(html);
  });
});

// API : liste des messages
app.get('/api/messages', (req, res) => {
  db.query('SELECT * FROM messages ORDER BY created_at DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'OK', data: results });
  });
});

// API : ajouter un message
app.post('/api/messages', (req, res) => {
  const { contenu } = req.body;
  if (!contenu) return res.status(400).json({ error: 'Champ contenu requis' });
  db.query('INSERT INTO messages (contenu) VALUES (?)', [contenu], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ status: 'OK', id: result.insertId });
  });
});

// Health check
app.get('/health', (req, res) => {
  db.ping(err => {
    res.json({
      status: err ? 'DB_ERROR' : 'OK',
      vm: 'vm2-web',
      db_host: process.env.DB_HOST || '192.168.10.10',
      db_connected: !err
    });
  });
});

app.listen(port, () => {
  console.log(`mbened-dev app démarrée sur le port ${port}`);
  console.log(`DB : ${process.env.DB_HOST || '192.168.10.10'}:3306`);
});
