//go:build integration

package main

// API-/E2E-Test: echter HTTP-Durchstich gegen den im Container
// laufenden Server (http://localhost:8080).

import (
	"bytes"
	crand "crypto/rand"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"
)

const base = "http://localhost:8080/api/bewerbungen"

func uniqueEmail(t *testing.T) string {
	t.Helper()
	buf := make([]byte, 12)
	_, _ = crand.Read(buf)
	return fmt.Sprintf("goapi+%x@example.com", buf)
}

func cleanupBewerber(t *testing.T, email string) {
	t.Helper()
	db, err := Connect()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	// ON DELETE RESTRICT -> erst Bewerbung, dann Bewerber loeschen.
	if _, err := db.Exec(
		"DELETE FROM bewerbung WHERE bewerberId IN (SELECT id FROM bewerber WHERE email = ?)",
		email,
	); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("DELETE FROM bewerber WHERE email = ?", email); err != nil {
		t.Fatal(err)
	}
}

func minStelleID(t *testing.T) int {
	t.Helper()
	db, err := Connect()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	var id sql.NullInt64
	if err := db.QueryRow("SELECT MIN(id) FROM stellenangebot").Scan(&id); err != nil {
		t.Skipf("Keine Stelle vorhanden - DB neu initialisieren: %v", err)
	}
	if !id.Valid || id.Int64 == 0 {
		t.Skip("Keine Stelle vorhanden - DB neu initialisieren.")
	}
	return int(id.Int64)
}

func httpReq(t *testing.T, method string, body any) (*http.Response, []byte) {
	t.Helper()
	var rdr io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		rdr = bytes.NewReader(b)
	}
	req, _ := http.NewRequest(method, base, rdr)
	req.Header.Set("Content-Type", "application/json")
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	out, _ := io.ReadAll(res.Body)
	_ = res.Body.Close()
	return res, out
}

func TestPostLegtAnUndGetListet(t *testing.T) {
	email := uniqueEmail(t)
	t.Cleanup(func() { cleanupBewerber(t, email) })

	stelle := minStelleID(t)
	res, body := httpReq(t, "POST", map[string]any{
		"vorname": "API", "nachname": "Tester",
		"email": email, "stelle_id": stelle,
	})
	if res.StatusCode != 201 {
		t.Fatalf("erwarte 201, war %d. Body: %s", res.StatusCode, body)
	}

	var post map[string]any
	if err := json.Unmarshal(body, &post); err != nil {
		t.Fatal(err)
	}
	nummer, _ := post["vorgangs_nr"].(string)
	if nummer == "" {
		t.Fatal("vorgangs_nr fehlt")
	}

	res, body = httpReq(t, "GET", nil)
	if res.StatusCode != 200 {
		t.Fatalf("erwarte 200, war %d", res.StatusCode)
	}
	var list struct {
		Bewerbungen []map[string]any `json:"bewerbungen"`
	}
	if err := json.Unmarshal(body, &list); err != nil {
		t.Fatal(err)
	}
	found := false
	for _, b := range list.Bewerbungen {
		if b["vorgangs_nr"] == nummer {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("vorgangs_nr %s nicht in Liste gefunden", nummer)
	}
}

func TestPostMitUngueltigenDaten400(t *testing.T) {
	res, body := httpReq(t, "POST", map[string]any{
		"email": "kaputt", "stelle_id": 0,
	})
	if res.StatusCode != 400 {
		t.Fatalf("erwarte 400, war %d", res.StatusCode)
	}
	var b map[string]any
	if err := json.Unmarshal(body, &b); err != nil {
		t.Fatal(err)
	}
	if _, ok := b["details"]; !ok {
		t.Error("details fehlen in Antwort")
	}
}
