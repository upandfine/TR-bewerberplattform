// INTEGRATION-Test fuer das Stellenangebot-Repository: laeuft gegen
// die echte MariaDB. Jeder Test in einer Transaktion mit Rollback.

const { test } = require("node:test");
const assert = require("node:assert/strict");
const db = require("../db");
const { MysqlStellenangebotRepository } = require("../stellen-repository");

async function withRollback(fn) {
  const conn = await db.connect();
  await conn.beginTransaction();
  try {
    await fn(new MysqlStellenangebotRepository(conn));
  } finally {
    await conn.rollback();
    await conn.end();
  }
}

test("Stelle anlegen liefert ID", async () => {
  await withRollback(async (repo) => {
    const id = await repo.insertStelle({
      titel: "Integration: Backend",
      beschreibung: "Node/MariaDB",
      art: "FESTANSTELLUNG",
      status: "ENTWURF",
    });
    assert.ok(id > 0);
  });
});

test("Liste filtert nach Status", async () => {
  await withRollback(async (repo) => {
    await repo.insertStelle({
      titel: "I-A", beschreibung: null,
      art: "FESTANSTELLUNG", status: "ENTWURF",
    });
    await repo.insertStelle({
      titel: "I-B", beschreibung: null,
      art: "WERKSTUDENT", status: "VEROEFFENTLICHT",
    });
    const entwurf = await repo.listStellen("ENTWURF");
    const titel = entwurf.map((r) => r.titel);
    assert.ok(titel.includes("I-A"));
    assert.ok(!titel.includes("I-B"));
  });
});

test("Prepared Statement verhindert SQL-Injection", async () => {
  await withRollback(async (repo) => {
    // Klassischer Injection-Versuch: bei naivem Concat
    // wuerde hier eine zweite Anweisung ausgefuehrt.
    const boese = "Hacker'); DROP TABLE stellenangebot; --";
    const id = await repo.insertStelle({
      titel: boese, beschreibung: null,
      art: "FESTANSTELLUNG", status: "ENTWURF",
    });
    const alle = await repo.listStellen(null);
    const titel = alle.map((r) => r.titel);
    assert.ok(titel.includes(boese));
    assert.ok(id > 0);
  });
});
