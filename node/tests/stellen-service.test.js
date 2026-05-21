// UNIT-Test fuer StellenangebotService: reine Fachlogik OHNE Datenbank.

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { StellenangebotService } = require("../stellen-service");
const { ValidationError } = require("../errors");

function fakeRepo() {
  const rows = [];
  let nextId = 1;
  return {
    rows,
    async insertStelle(s) {
      const id = nextId++;
      rows.push({ id, ...s });
      return id;
    },
    async listStellen(status) {
      if (status == null) return rows.slice();
      return rows.filter((r) => r.status === status);
    },
  };
}

test("neue Stelle startet immer als ENTWURF", async () => {
  const repo = fakeRepo();
  const svc = new StellenangebotService(repo);
  const res = await svc.anlegen({
    titel: "Senior Backend",
    art: "FESTANSTELLUNG",
    // Versucht ENTWURF zu umgehen - Service ignoriert das.
    status: "VEROEFFENTLICHT",
  });
  assert.equal(res.status, "ENTWURF");
  assert.equal(repo.rows[0].status, "ENTWURF");
});

test("Standard-Art ist FESTANSTELLUNG", async () => {
  const svc = new StellenangebotService(fakeRepo());
  const res = await svc.anlegen({ titel: "Praktikant:in" });
  assert.equal(res.art, "FESTANSTELLUNG");
});

test("Titel ist Pflicht", async () => {
  const svc = new StellenangebotService(fakeRepo());
  await assert.rejects(
    () => svc.anlegen({ titel: "   " }),
    (e) => e instanceof ValidationError
  );
});

test("ungueltige Art wird abgelehnt", async () => {
  const svc = new StellenangebotService(fakeRepo());
  await assert.rejects(
    () => svc.anlegen({ titel: "Stelle", art: "KEIN_ECHTER_TYP" }),
    (e) => e instanceof ValidationError
  );
});

test("liste filtert nach status", async () => {
  const repo = fakeRepo();
  const svc = new StellenangebotService(repo);
  await svc.anlegen({ titel: "A" });
  await svc.anlegen({ titel: "B" });
  await repo.insertStelle({
    titel: "C", beschreibung: null,
    art: "FESTANSTELLUNG", status: "VEROEFFENTLICHT",
  });
  const entwuerfe = await svc.liste("ENTWURF");
  assert.equal(entwuerfe.length, 2);
});

test("liste mit ungueltigem status wirft", async () => {
  const svc = new StellenangebotService(fakeRepo());
  await assert.rejects(
    () => svc.liste("UNBEKANNT"),
    (e) => e instanceof ValidationError
  );
});
