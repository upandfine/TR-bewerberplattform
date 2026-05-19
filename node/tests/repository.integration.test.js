// INTEGRATION-Test gegen die ECHTE MariaDB.
// Jeder Test in einer Transaktion, die zurückgerollt wird.

const { test, beforeEach, afterEach } = require("node:test");
const assert = require("node:assert/strict");
const db = require("../db");
const { MysqlBewerbungRepository } = require("../repository");

let conn;
let repo;

beforeEach(async () => {
  conn = await db.connect();
  await conn.beginTransaction();
  repo = new MysqlBewerbungRepository(conn);
});

afterEach(async () => {
  await conn.rollback();
  await conn.end();
});

async function eineStelleId() {
  const [res] = await conn.execute(
    "INSERT INTO stellenangebot (titel, art, status) " +
      "VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')"
  );
  return Number(res.insertId);
}

test("Bewerber anlegen und per E-Mail finden", async () => {
  const id = await repo.insertBewerber({
    vorname: "Erika", nachname: "Mustermann",
    email: "node-int@example.com", telefon: null,
  });
  assert.equal(await repo.findBewerberIdByEmail("node-int@example.com"), id);
  assert.equal(await repo.findBewerberIdByEmail("nope@example.com"), null);
});

test("Bewerbung anlegen funktioniert", async () => {
  const stelleId = await eineStelleId();
  const bid = await repo.insertBewerber({
    vorname: "Max", nachname: "M", email: "node-m@example.com", telefon: null,
  });
  const aid = await repo.insertBewerbung(bid, stelleId, "BEW-2026-NDAB01", null);
  assert.ok(aid > 0);
});

test("Fremdschlüssel verhindert ungültige Stelle", async () => {
  const bid = await repo.insertBewerber({
    vorname: "A", nachname: "B", email: "node-fk@example.com", telefon: null,
  });
  await assert.rejects(
    () => repo.insertBewerbung(bid, 999999, "BEW-2026-NDFK01", null),
    (e) => e.errno === 1452
  );
});

test("Vorgangsnummer ist eindeutig", async () => {
  const stelleId = await eineStelleId();
  const bid = await repo.insertBewerber({
    vorname: "C", nachname: "D", email: "node-uq@example.com", telefon: null,
  });
  await repo.insertBewerbung(bid, stelleId, "BEW-2026-NDDUP1", null);
  await assert.rejects(
    () => repo.insertBewerbung(bid, stelleId, "BEW-2026-NDDUP1", null),
    (e) => e.errno === 1062
  );
});
