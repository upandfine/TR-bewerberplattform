// API-/E2E-Test fuer /api_stellen: HTTP-Durchstich durch alle
// Schichten, im Container gegen http://localhost:3000.

const { test, afterEach } = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("crypto");
const db = require("../db");

const BASE = "http://localhost:3000/api_stellen";
let titel;

afterEach(async () => {
  if (!titel) return;
  const conn = await db.connect();
  await conn.execute("DELETE FROM stellenangebot WHERE titel = ?", [titel]);
  await conn.end();
  titel = undefined;
});

test("POST legt Stelle mit Status ENTWURF an", async () => {
  titel = `nodeapi-${crypto.randomUUID()}`;
  const res = await fetch(BASE, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      titel,
      art: "WERKSTUDENT",
      // Versucht ENTWURF zu umgehen - Service-Regel ignoriert das.
      status: "VEROEFFENTLICHT",
    }),
  });
  assert.equal(res.status, 201);
  const body = await res.json();
  assert.equal(body.status, "ENTWURF");
  assert.equal(body.art, "WERKSTUDENT");
  assert.equal(typeof body.id, "number");
});

test("GET listet die angelegte Stelle", async () => {
  titel = `nodeapi-${crypto.randomUUID()}`;
  await fetch(BASE, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ titel, art: "PRAKTIKUM" }),
  });

  const res = await fetch(BASE + "?status=ENTWURF");
  assert.equal(res.status, 200);
  const body = await res.json();
  const titelListe = body.stellen.map((s) => s.titel);
  assert.ok(titelListe.includes(titel));
});

test("POST ohne Titel liefert 400", async () => {
  titel = undefined;
  const res = await fetch(BASE, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ art: "AZUBI" }),
  });
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.ok(body.details);
});
