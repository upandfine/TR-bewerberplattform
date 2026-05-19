// Use-Case-Schicht: reine Fachlogik, kennt weder DB noch HTTP.
// Genau deshalb ohne Datenbank unit-testbar.

const crypto = require("crypto");
const { ValidationError } = require("./errors");

class BewerbungService {
  constructor(repo) {
    this.repo = repo;
  }

  async einreichen(input) {
    BewerbungService.#validate(input);

    const email = String(input.email).trim();

    let bewerberId = await this.repo.findBewerberIdByEmail(email);
    if (bewerberId === null) {
      bewerberId = await this.repo.insertBewerber({
        vorname: String(input.vorname).trim(),
        nachname: String(input.nachname).trim(),
        email,
        telefon: input.telefon ? String(input.telefon).trim() : null,
      });
    }

    const vorgangsNr = BewerbungService.generateVorgangsNr();
    const bewerbungId = await this.repo.insertBewerbung(
      bewerberId,
      parseInt(input.stelle_id, 10),
      vorgangsNr,
      input.bemerkung ? String(input.bemerkung).trim() : null
    );

    return {
      bewerbung_id: bewerbungId,
      bewerber_id: bewerberId,
      vorgangs_nr: vorgangsNr,
    };
  }

  async liste(status = null) {
    return this.repo.listBewerbungen(status);
  }

  static generateVorgangsNr() {
    const jahr = new Date().getFullYear();
    const hex = crypto
      .randomInt(0, 0x1000000)
      .toString(16)
      .toUpperCase()
      .padStart(6, "0");
    return `BEW-${jahr}-${hex}`;
  }

  static #validate(input) {
    const errors = [];

    for (const feld of ["vorname", "nachname"]) {
      if (!String(input?.[feld] ?? "").trim()) {
        errors.push(`Feld '${feld}' ist ein Pflichtfeld.`);
      }
    }

    const email = String(input?.email ?? "").trim();
    const at = email.indexOf("@");
    if (at < 1 || !email.slice(at + 1).includes(".")) {
      errors.push("Feld 'email' ist keine gültige E-Mail-Adresse.");
    }

    const stelle = Number(input?.stelle_id);
    if (!Number.isInteger(stelle) || stelle <= 0) {
      errors.push("Feld 'stelle_id' muss eine positive Zahl sein.");
    }

    if (errors.length) throw new ValidationError(errors);
  }
}

module.exports = { BewerbungService };
