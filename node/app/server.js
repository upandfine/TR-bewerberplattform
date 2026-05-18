// ============================================================
//  Demo-App: zeigt, dass Node.js/Express läuft und die DB
//  erreichbar ist. Eigenen Code hier erweitern.
//  Änderungen werden nach "docker compose restart node"
//  übernommen.
// ============================================================

const express = require("express");
const mysql = require("mysql2/promise");

const app = express();

async function dbStatus() {
  try {
    const conn = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
    });
    const [rows] = await conn.query("SELECT VERSION() AS v");
    await conn.end();
    return `<p style="color:green">Datenbank-Verbindung OK - MariaDB ${rows[0].v}</p>`;
  } catch (e) {
    return `<p style="color:red">Keine DB-Verbindung: ${e.message}</p>`;
  }
}

app.get("/", async (req, res) => {
  const status = await dbStatus();
  res.send(`<h1>Node.js / Express läuft </h1>${status}`);
});

// 0.0.0.0 ist wichtig, damit der Container von außen erreichbar ist
app.listen(3000, "0.0.0.0", () => {
  console.log("Node-Server läuft auf Port 3000");
});
