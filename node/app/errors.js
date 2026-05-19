// Fachlicher Validierungsfehler -> wird im HTTP-Handler zu 400.

class ValidationError extends Error {
  constructor(errors) {
    super("Validierung fehlgeschlagen");
    this.name = "ValidationError";
    this.errors = errors;
  }
}

module.exports = { ValidationError };
