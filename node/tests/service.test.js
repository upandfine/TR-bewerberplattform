// UNIT-Test: reine Fachlogik OHNE Datenbank (Fake-Repository).

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { BewerbungService } = require("../service");
const { ValidationError } = require("../errors");

function fakeRepo() {
  const emails = new Map();
  let nextId = 1;
  return {
    async findBewerberIdByEmail(email) {
      return emails.has(email) ? emails.get(email) : null;
    },
    async insertBewerber(b) {
      const id = nextId++;
      emails.set(b.email, id);
      return id;
    },
    async insertBewerbung() {
      return nextId++;
    },
    async listBewerbungen() {
      return [];
    },
  };
}

test("einreichen liefert Vorgangsnummer im korrekten Format", async () => {
  const svc = new BewerbungService(fakeRepo());
  const res = await svc.einreichen({
    vorname: "Erika",
    nachname: "Mustermann",
    email: "erika@example.com",
    stelle_id: 1,
  });
  assert.match(res.vorgangs_nr, /^BEW-\d{4}-[0-9A-F]{6}$/);
  assert.equal(typeof res.bewerbung_id, "number");
});

test("bekannte E-Mail wird wiederverwendet", async () => {
  const svc = new BewerbungService(fakeRepo());
  const a = await svc.einreichen({
    vorname: "Max", nachname: "M", email: "max@example.com", stelle_id: 1,
  });
  const b = await svc.einreichen({
    vorname: "Max", nachname: "M", email: "max@example.com", stelle_id: 2,
  });
  assert.equal(a.bewerber_id, b.bewerber_id);
});

test("fehlende Pflichtfelder werfen ValidationError", async () => {
  const svc = new BewerbungService(fakeRepo());
  await assert.rejects(
    () => svc.einreichen({ email: "kaputt", stelle_id: 0 }),
    (e) => e instanceof ValidationError && e.errors.length >= 3
  );
});

test("generateVorgangsNr Format", () => {
  assert.match(
    BewerbungService.generateVorgangsNr(),
    /^BEW-\d{4}-[0-9A-F]{6}$/
  );
});
