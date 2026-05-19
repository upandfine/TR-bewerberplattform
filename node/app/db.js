// Persistenz-Verbindung. Zugangsdaten aus den Umgebungsvariablen
// (DB_HOST/DB_NAME/DB_USER/DB_PASS, aus der .env).

const mysql = require("mysql2/promise");

async function connect() {
  return mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
  });
}

module.exports = { connect };
