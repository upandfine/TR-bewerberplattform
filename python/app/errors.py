"""Fachlicher Validierungsfehler -> wird im HTTP-Handler zu 400."""


class ValidationError(Exception):
    def __init__(self, errors: list[str]) -> None:
        super().__init__("Validierung fehlgeschlagen")
        self.errors = errors
