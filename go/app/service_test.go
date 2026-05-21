package main

// UNIT-Test: reine Fachlogik OHNE Datenbank (Fake-Repository).
// Tests dieser Datei brauchen keine DB-Verbindung.

import (
	"errors"
	"regexp"
	"testing"
)

type fakeRepo struct {
	emails map[string]int
	nextID int
}

func newFakeRepo() *fakeRepo {
	return &fakeRepo{emails: map[string]int{}, nextID: 1}
}

func (r *fakeRepo) FindBewerberIDByEmail(email string) (*int, error) {
	if id, ok := r.emails[email]; ok {
		return &id, nil
	}
	return nil, nil
}

func (r *fakeRepo) InsertBewerber(b Bewerber) (int, error) {
	id := r.nextID
	r.nextID++
	r.emails[b.Email] = id
	return id, nil
}

func (r *fakeRepo) InsertBewerbung(
	bewerberID, stelleID int, vorgangsNr string, bemerkung *string,
) (int, error) {
	id := r.nextID
	r.nextID++
	return id, nil
}

func (r *fakeRepo) ListBewerbungen(status *string) ([]map[string]any, error) {
	return nil, nil
}

func stelleIDPtr(n int) *int { return &n }

func TestEinreichenLiefertVorgangsnummerImFormat(t *testing.T) {
	svc := NewService(newFakeRepo())
	res, err := svc.Einreichen(EinreichenInput{
		Vorname: "Erika", Nachname: "Mustermann",
		Email: "erika@example.com", StelleID: stelleIDPtr(1),
	})
	if err != nil {
		t.Fatalf("unerwarteter Fehler: %v", err)
	}
	if !regexp.MustCompile(`^BEW-\d{4}-[0-9A-F]{6}$`).MatchString(res.VorgangsNr) {
		t.Errorf("vorgangs_nr passt nicht: %s", res.VorgangsNr)
	}
	if res.BewerbungID <= 0 {
		t.Errorf("bewerbung_id sollte > 0 sein, war: %d", res.BewerbungID)
	}
}

func TestBekannteEmailWirdWiederverwendet(t *testing.T) {
	svc := NewService(newFakeRepo())
	a, err := svc.Einreichen(EinreichenInput{
		Vorname: "Max", Nachname: "M",
		Email: "max@example.com", StelleID: stelleIDPtr(1),
	})
	if err != nil {
		t.Fatal(err)
	}
	b, err := svc.Einreichen(EinreichenInput{
		Vorname: "Max", Nachname: "M",
		Email: "max@example.com", StelleID: stelleIDPtr(2),
	})
	if err != nil {
		t.Fatal(err)
	}
	if a.BewerberID != b.BewerberID {
		t.Errorf("bewerber_id sollte gleich sein: %d != %d", a.BewerberID, b.BewerberID)
	}
}

func TestFehlendePflichtfelderWerfenValidationError(t *testing.T) {
	svc := NewService(newFakeRepo())
	_, err := svc.Einreichen(EinreichenInput{
		Email: "kaputt", StelleID: stelleIDPtr(0),
	})
	var ve *ValidationError
	if !errors.As(err, &ve) {
		t.Fatalf("ValidationError erwartet, war: %v", err)
	}
	if len(ve.Errors) < 3 {
		t.Errorf("erwarte mindestens 3 Fehler, waren: %v", ve.Errors)
	}
}

func TestGenerateVorgangsNrFormat(t *testing.T) {
	if !regexp.MustCompile(`^BEW-\d{4}-[0-9A-F]{6}$`).MatchString(GenerateVorgangsNr()) {
		t.Errorf("Format passt nicht")
	}
}
