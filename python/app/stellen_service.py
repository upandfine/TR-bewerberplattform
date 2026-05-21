"""Use-Case-Schicht fuer Stellenangebote.

Wichtigste Geschaeftsregel:
    Eine neue Stelle startet IMMER mit Status 'ENTWURF'.
    Ein vom Aufrufer gelieferter status wird bewusst ignoriert.
"""

from errors import ValidationError
from stellen_repository import StellenangebotRepository


STATUS_ENTWURF = "ENTWURF"

ARTEN = ("FESTANSTELLUNG", "AZUBI", "MINIJOB", "WERKSTUDENT", "PRAKTIKUM")
STATI = ("ENTWURF", "VEROEFFENTLICHT", "GESCHLOSSEN", "ARCHIVIERT")


class StellenangebotService:
    def __init__(self, repo: StellenangebotRepository) -> None:
        self.repo = repo

    def anlegen(self, data: dict) -> dict:
        self._validate(data)

        titel = str(data["titel"]).strip()
        beschreibung = (
            str(data["beschreibung"]).strip() if data.get("beschreibung") else None
        )
        art = data.get("art") or "FESTANSTELLUNG"

        # Geschaeftsregel: neue Stellen starten IMMER als ENTWURF.
        status = STATUS_ENTWURF

        stelle_id = self.repo.insert_stelle({
            "titel": titel,
            "beschreibung": beschreibung,
            "art": art,
            "status": status,
        })

        return {
            "id": stelle_id,
            "titel": titel,
            "art": art,
            "status": status,
        }

    def liste(self, status: str | None = None) -> list[dict]:
        if status is not None and status not in STATI:
            raise ValidationError(
                ["Parameter 'status' ist kein gueltiger Stellenstatus."]
            )
        return self.repo.list_stellen(status)

    @staticmethod
    def _validate(data: dict) -> None:
        errors: list[str] = []

        titel = str(data.get("titel", "")).strip()
        if not titel:
            errors.append("Feld 'titel' ist ein Pflichtfeld.")
        elif len(titel) > 120:
            errors.append("Feld 'titel' darf maximal 120 Zeichen lang sein.")

        art = data.get("art")
        if art and art not in ARTEN:
            errors.append("Feld 'art' ist keine gueltige Stellenart.")

        if errors:
            raise ValidationError(errors)
