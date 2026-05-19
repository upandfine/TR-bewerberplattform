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
