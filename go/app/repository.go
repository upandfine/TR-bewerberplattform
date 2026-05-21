package main

import (
	"database/sql"
	"time"
)

// Bewerber ist die Eingabe-Struktur fuer insertBewerber.
type Bewerber struct {
	Vorname  string
	Nachname string
	Email    string
	Telefon  *string
}

// BewerbungRepository ist die Naht zwischen Service (reine Logik)
// und Persistenz. Im Unit-Test wird diese Schnittstelle durch ein
// In-Memory-Fake ersetzt -> Service-Tests ohne Datenbank.
type BewerbungRepository interface {
	FindBewerberIDByEmail(email string) (*int, error)
	InsertBewerber(b Bewerber) (int, error)
	InsertBewerbung(bewerberID, stelleID int, vorgangsNr string, bemerkung *string) (int, error)
	ListBewerbungen(status *string) ([]map[string]any, error)
}

// queryable wird von *sql.DB und *sql.Tx erfuellt - damit das
// Repository in Tests gegen eine offene Transaktion arbeiten kann,
// die am Ende rollbackt wird.
type queryable interface {
	Query(query string, args ...any) (*sql.Rows, error)
	QueryRow(query string, args ...any) *sql.Row
	Exec(query string, args ...any) (sql.Result, error)
}

// SQLBewerbungRepository ist die konkrete Persistenz gegen MariaDB.
// Spalten in der DB sind camelCase; nach aussen liefern wir stabile
// snake_case-Schluessel (gleicher Vertrag wie PHP/Python/Node/.NET).
type SQLBewerbungRepository struct {
	db queryable
}

func NewSQLRepository(db queryable) *SQLBewerbungRepository {
	return &SQLBewerbungRepository{db: db}
}

func (r *SQLBewerbungRepository) FindBewerberIDByEmail(email string) (*int, error) {
	var id int
	err := r.db.QueryRow("SELECT id FROM bewerber WHERE email = ?", email).Scan(&id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &id, nil
}

func (r *SQLBewerbungRepository) InsertBewerber(b Bewerber) (int, error) {
	res, err := r.db.Exec(
		"INSERT INTO bewerber (vorname, nachname, email, telefon) VALUES (?, ?, ?, ?)",
		b.Vorname, b.Nachname, b.Email, nullable(b.Telefon),
	)
	if err != nil {
		return 0, err
	}
	id, _ := res.LastInsertId()
	return int(id), nil
}

func (r *SQLBewerbungRepository) InsertBewerbung(
	bewerberID, stelleID int, vorgangsNr string, bemerkung *string,
) (int, error) {
	res, err := r.db.Exec(
		"INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung) VALUES (?, ?, ?, ?)",
		bewerberID, stelleID, vorgangsNr, nullable(bemerkung),
	)
	if err != nil {
		return 0, err
	}
	id, _ := res.LastInsertId()
	return int(id), nil
}

func (r *SQLBewerbungRepository) ListBewerbungen(status *string) ([]map[string]any, error) {
	sqlStr := `SELECT b.id,
                      b.vorgangsNr AS vorgangs_nr,
                      b.status,
                      b.eingangAm  AS eingang_am,
                      bw.vorname, bw.nachname, bw.email,
                      s.titel AS stelle
               FROM bewerbung b
               JOIN bewerber bw      ON bw.id = b.bewerberId
               JOIN stellenangebot s ON s.id  = b.stelleId`
	args := []any{}
	if status != nil {
		sqlStr += " WHERE b.status = ?"
		args = append(args, *status)
	}
	sqlStr += " ORDER BY b.eingangAm DESC"

	rows, err := r.db.Query(sqlStr, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	cols, err := rows.Columns()
	if err != nil {
		return nil, err
	}

	out := make([]map[string]any, 0)
	for rows.Next() {
		vals := make([]any, len(cols))
		ptrs := make([]any, len(cols))
		for i := range vals {
			ptrs[i] = &vals[i]
		}
		if err := rows.Scan(ptrs...); err != nil {
			return nil, err
		}
		row := make(map[string]any, len(cols))
		for i, c := range cols {
			v := vals[i]
			// []byte aus MySQL VARCHAR -> string fuer JSON.
			if b, ok := v.([]byte); ok {
				v = string(b)
			}
			// DateTime einheitlich wie in den anderen Stacks formatieren.
			if t, ok := v.(time.Time); ok {
				v = t.Format("2006-01-02 15:04:05")
			}
			row[c] = v
		}
		out = append(out, row)
	}
	return out, rows.Err()
}

func nullable(s *string) any {
	if s == nil {
		return nil
	}
	return *s
}
