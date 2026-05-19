// API-/E2E-Test: echter HTTP-Durchstich durch alle Schichten
// (Express -> Service -> Repository -> MariaDB), im Container gegen
// http://localhost:3000.

const { test, afterEach } = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("crypto");
const db = require("../db");

const BASE = "http://localhost:3000/api/bewerbungen";
let email;

afterEach(async () => {
  if (!email) return;
  const conn = await db.connect();
  // ON DELETE RESTRICT -> erst Bewerbung, dann Bewerber löschen
  await conn.execute(
    "DELETE FROM bewerbung WHERE bewerberId IN " +
      "(SELECT id FROM bewerber WHERE email = ?)",
    [email]
  );
  await conn.execute("DELETE FROM bewerber WHERE email = ?", [email]);
  await conn.end();
  email = undefined;
});

async function stelleId() {
  const conn = await db.connect();
  const [rows] = await conn.execute("SELECT MIN(id) AS m FROM stellenangebot");
  await conn.end();
  return rows[0].m;
}

test("POST legt Bewerbung an und GET listet sie", async () => {
  email = `nodeapi+${crypto.randomUUID()}@example.com`;
  const sid = await stelleId();
  assert.ok(sid, "Keine Stelle vorhanden - DB neu initialisieren.");

  const postRes = await fetch(BASE, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      vorname: "API", nachname: "Tester", email, stelle_id: sid,
    }),
  });
  assert.equal(postRes.status, 201);
  const post = await postRes.json();
  assert.ok(post.vorgangs_nr);

  const getRes = await fetch(BASE);
  assert.equal(getRes.status, 200);
  const get = await getRes.json();
  const nummern = get.bewerbungen.map((b) => b.vorgangs_nr);
  assert.ok(nummern.includes(post.vorgangs_nr));
});

test("POST mit ungültigen Daten liefert 400", async () => {
  email = `nodeapi+${crypto.randomUUID()}@example.com`; // wird nicht angelegt
  const res = await fetch(BASE, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "kaputt", stelle_id: 0 }),
  });
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.ok(body.details);
});
