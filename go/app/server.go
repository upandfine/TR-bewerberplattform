package main

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-sql-driver/mysql"
)

// HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.
//
//   GET  /                  -> kleiner Health-Check
//   POST /api/bewerbungen   -> Bewerbung einreichen
//   GET  /api/bewerbungen   -> Bewerbungen auflisten (?status=...)

func main() {
	r := chi.NewRouter()

	r.Get("/", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_, _ = w.Write([]byte(
			"<h1>Go / chi laeuft</h1><p>API unter /api/bewerbungen</p>"))
	})

	r.Post("/api/bewerbungen", einreichen)
	r.Get("/api/bewerbungen", liste)

	log.Println("Go-Server laeuft auf :8080")
	if err := http.ListenAndServe(":8080", r); err != nil {
		log.Fatal(err)
	}
}

func einreichen(w http.ResponseWriter, r *http.Request) {
	var in EinreichenInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest,
			map[string]any{"fehler": "Body muss gueltiges JSON sein."})
		return
	}

	db, err := Connect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError,
			map[string]any{"fehler": "Datenbankfehler."})
		return
	}
	defer db.Close()

	svc := NewService(NewSQLRepository(db))
	result, err := svc.Einreichen(in)

	var ve *ValidationError
	if errors.As(err, &ve) {
		writeJSON(w, http.StatusBadRequest,
			map[string]any{"fehler": ve.Error(), "details": ve.Errors})
		return
	}

	var me *mysql.MySQLError
	if errors.As(err, &me) {
		switch me.Number {
		case 1452:
			writeJSON(w, http.StatusUnprocessableEntity,
				map[string]any{"fehler": "Angegebene stelle_id existiert nicht."})
			return
		case 1062:
			writeJSON(w, http.StatusConflict,
				map[string]any{"fehler": "Vorgangsnummer-Kollision, bitte erneut senden."})
			return
		}
		writeJSON(w, http.StatusInternalServerError,
			map[string]any{"fehler": "Datenbankfehler."})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError,
			map[string]any{"fehler": "Datenbankfehler."})
		return
	}

	writeJSON(w, http.StatusCreated, result)
}

func liste(w http.ResponseWriter, r *http.Request) {
	var status *string
	if s := r.URL.Query().Get("status"); s != "" {
		status = &s
	}

	db, err := Connect()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError,
			map[string]any{"fehler": "Datenbankfehler."})
		return
	}
	defer db.Close()

	svc := NewService(NewSQLRepository(db))
	rows, err := svc.Liste(status)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError,
			map[string]any{"fehler": "Datenbankfehler."})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"bewerbungen": rows})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
