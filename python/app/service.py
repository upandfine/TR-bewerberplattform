"""Use-Case-Schicht: reine Fachlogik, kennt weder DB noch HTTP.
Genau deshalb ohne Datenbank unit-testbar."""

import datetime
import secrets

from errors import ValidationError
from repository import BewerbungRepository


class BewerbungService:
    def __init__(self, repo: BewerbungRepository) -> None:
        self.repo = repo

    def einreichen(self, data: dict) -> dict:
        self._validate(data)

        email = str(data["email"]).strip()

        bewerber_id = self.repo.find_bewerber_id_by_email(email)
        if bewerber_id is None:
            bewerber_id = self.repo.insert_bewerber({
                "vorname": str(data["vorname"]).strip(),
                "nachname": str(data["nachname"]).strip(),
                "email": email,
                "telefon": str(data["telefon"]).strip()
                if data.get("telefon") else None,
            })

        vorgangs_nr = self.generate_vorgangs_nr()
        bewerbung_id = self.repo.insert_bewerbung(
            bewerber_id,
            int(data["stelle_id"]),
            vorgangs_nr,
            str(data["bemerkung"]).strip() if data.get("bemerkung") else None,
        )

        return {
            "bewerbung_id": bewerbung_id,
            "bewerber_id": bewerber_id,
            "vorgangs_nr": vorgangs_nr,
        }

    def liste(self, status: str | None = None) -> list[dict]:
        return self.repo.list_bewerbungen(status)

    @staticmethod
    def generate_vorgangs_nr() -> str:
        return "BEW-{}-{:06X}".format(
            datetime.date.today().year, secrets.randbelow(0x1000000)
        )

    @staticmethod
    def _validate(data: dict) -> None:
        errors: list[str] = []

        for feld in ("vorname", "nachname"):
            if not str(data.get(feld, "")).strip():
                errors.append(f"Feld '{feld}' ist ein Pflichtfeld.")

        email = str(data.get("email", "")).strip()
        if "@" not in email or "." not in email.split("@")[-1]:
            errors.append("Feld 'email' ist keine gültige E-Mail-Adresse.")

        stelle = data.get("stelle_id")
        try:
            ok = int(stelle) > 0
        except (TypeError, ValueError):
            ok = False
        if not ok:
            errors.append("Feld 'stelle_id' muss eine positive Zahl sein.")

        if errors:
            raise ValidationError(errors)
