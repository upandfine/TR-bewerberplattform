// Use-Case-Schicht fuer Stellenangebote: reine Fachlogik, kennt
// weder DB noch HTTP.
//
// Wichtigste Geschaeftsregel:
//   Eine neue Stelle startet IMMER mit Status 'ENTWURF'.
//   Ein vom Aufrufer gelieferter status wird bewusst ignoriert.

const { ValidationError } = require("./errors");

const STATUS_ENTWURF = "ENTWURF";
const ARTEN = ["FESTANSTELLUNG", "AZUBI", "MINIJOB", "WERKSTUDENT", "PRAKTIKUM"];
const STATI = ["ENTWURF", "VEROEFFENTLICHT", "GESCHLOSSEN", "ARCHIVIERT"];

class StellenangebotService {
  constructor(repo) {
    this.repo = repo;
  }

  async anlegen(input) {
    StellenangebotService.#validate(input);

    const titel = String(input.titel).trim();
    const beschreibung = input.beschreibung
      ? String(input.beschreibung).trim()
      : null;
    const art = input.art || "FESTANSTELLUNG";

    // Geschaeftsregel: neue Stellen starten IMMER als ENTWURF.
    const status = STATUS_ENTWURF;

    const id = await this.repo.insertStelle({
      titel,
      beschreibung,
      art,
      status,
    });

    return { id, titel, art, status };
  }

  async liste(status = null) {
    if (status != null && !STATI.includes(status)) {
      throw new ValidationError([
        "Parameter 'status' ist kein gueltiger Stellenstatus.",
      ]);
    }
    return this.repo.listStellen(status);
  }

  static #validate(input) {
    const errors = [];
    const titel = String(input?.titel ?? "").trim();
    if (!titel) {
      errors.push("Feld 'titel' ist ein Pflichtfeld.");
    } else if (titel.length > 120) {
      errors.push("Feld 'titel' darf maximal 120 Zeichen lang sein.");
    }

    if (input?.art && !ARTEN.includes(input.art)) {
      errors.push("Feld 'art' ist keine gueltige Stellenart.");
    }

    if (errors.length) throw new ValidationError(errors);
  }
}

module.exports = { StellenangebotService, STATUS_ENTWURF, ARTEN, STATI };
