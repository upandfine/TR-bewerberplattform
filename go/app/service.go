package main

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"strings"
	"time"
)

// EinreichenInput ist die Eingabe der POST-API. JSON-Tags = snake_case,
// gleicher Vertrag wie PHP/Python/Node/.NET/Java/Kotlin.
type EinreichenInput struct {
	Vorname   string  `json:"vorname"`
	Nachname  string  `json:"nachname"`
	Email     string  `json:"email"`
	Telefon   *string `json:"telefon,omitempty"`
	StelleID  *int    `json:"stelle_id,omitempty"`
	Bemerkung *string `json:"bemerkung,omitempty"`
}

// EinreichenResult ist die Antwort auf einen erfolgreichen POST.
type EinreichenResult struct {
	BewerbungID int    `json:"bewerbung_id"`
	BewerberID  int    `json:"bewerber_id"`
	VorgangsNr  string `json:"vorgangs_nr"`
}

// BewerbungService ist die Use-Case-Schicht: reine Fachlogik,
// kennt weder DB noch HTTP. Genau deshalb ohne Datenbank
// unit-testbar (Fake-Repository).
type BewerbungService struct {
	repo BewerbungRepository
}

func NewService(repo BewerbungRepository) *BewerbungService {
	return &BewerbungService{repo: repo}
}

func (s *BewerbungService) Einreichen(in EinreichenInput) (*EinreichenResult, error) {
	if err := validate(in); err != nil {
		return nil, err
	}

	email := strings.TrimSpace(in.Email)

	bewerberID, err := s.repo.FindBewerberIDByEmail(email)
	if err != nil {
		return nil, err
	}
	if bewerberID == nil {
		id, err := s.repo.InsertBewerber(Bewerber{
			Vorname:  strings.TrimSpace(in.Vorname),
			Nachname: strings.TrimSpace(in.Nachname),
			Email:    email,
			Telefon:  trimmedPtr(in.Telefon),
		})
		if err != nil {
			return nil, err
		}
		bewerberID = &id
	}

	vorgangsNr := GenerateVorgangsNr()
	id, err := s.repo.InsertBewerbung(
		*bewerberID, *in.StelleID, vorgangsNr, trimmedPtr(in.Bemerkung),
	)
	if err != nil {
		return nil, err
	}

	return &EinreichenResult{
		BewerbungID: id, BewerberID: *bewerberID, VorgangsNr: vorgangsNr,
	}, nil
}

func (s *BewerbungService) Liste(status *string) ([]map[string]any, error) {
	return s.repo.ListBewerbungen(status)
}

// GenerateVorgangsNr liefert BEW-YYYY-XXXXXX mit kryptographischer
// Zufallsquelle.
func GenerateVorgangsNr() string {
	n, _ := rand.Int(rand.Reader, big.NewInt(0x1000000))
	return fmt.Sprintf("BEW-%d-%06X", time.Now().Year(), n.Int64())
}

func validate(i EinreichenInput) error {
	var errors []string

	if strings.TrimSpace(i.Vorname) == "" {
		errors = append(errors, "Feld 'vorname' ist ein Pflichtfeld.")
	}
	if strings.TrimSpace(i.Nachname) == "" {
		errors = append(errors, "Feld 'nachname' ist ein Pflichtfeld.")
	}

	email := strings.TrimSpace(i.Email)
	at := strings.Index(email, "@")
	if at < 1 || !strings.Contains(email[at+1:], ".") {
		errors = append(errors, "Feld 'email' ist keine gueltige E-Mail-Adresse.")
	}

	if i.StelleID == nil || *i.StelleID <= 0 {
		errors = append(errors, "Feld 'stelle_id' muss eine positive Zahl sein.")
	}

	if len(errors) > 0 {
		return &ValidationError{Errors: errors}
	}
	return nil
}

func trimmedPtr(s *string) *string {
	if s == nil {
		return nil
	}
	t := strings.TrimSpace(*s)
	if t == "" {
		return nil
	}
	return &t
}
