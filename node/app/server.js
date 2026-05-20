// HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.
//
//   GET  /                  -> kleiner Health-Check
//   POST /api/bewerbungen   -> Bewerbung einreichen
//   GET  /api/bewerbungen   -> Bewerbungen auflisten (?status=...)

const express = require("express");
const db = require("./db");
const { BewerbungService } = require("./service");
const { MysqlBewerbungRepository } = require("./repository");
const { ValidationError } = require("./errors");

const app = express();
app.use(express.json());

// CORS: erlaubt dem Vue-Frontend (anderer Origin) den Zugriff.
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  res.header("Access-Control-Max-Age", "86400");
  if (req.method === "OPTIONS") return res.status(204).end();
  next();
});

async function service() {
  return new BewerbungService(new MysqlBewerbungRepository(await db.connect()));
}

app.get("/", (_req, res) => {
  res.send("<h1>Node.js / Express läuft</h1><p>API unter /api/bewerbungen</p>");
});

app.post("/api/bewerbungen", async (req, res) => {
  try {
    const result = await (await service()).einreichen(req.body ?? {});
    res.status(201).json(result);
  } catch (e) {
    if (e instanceof ValidationError) {
      return res.status(400).json({ fehler: e.message, details: e.errors });
    }
    if (e && e.errno === 1452) {
      return res.status(422).json({ fehler: "Angegebene stelle_id existiert nicht." });
    }
    if (e && e.errno === 1062) {
      return res.status(409).json({ fehler: "Vorgangsnummer-Kollision, bitte erneut senden." });
    }
    res.status(500).json({ fehler: "Datenbankfehler." });
  }
});

app.get("/api/bewerbungen", async (req, res) => {
  const status = req.query.status ?? null;
  res.status(200).json({ bewerbungen: await (await service()).liste(status) });
});

// 0.0.0.0 ist wichtig, damit der Container von außen erreichbar ist
app.listen(3000, "0.0.0.0", () => {
  console.log("Node-Server läuft auf Port 3000");
});
