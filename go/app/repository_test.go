//go:build integration

package main

// INTEGRATION-Test gegen die ECHTE MariaDB.
// Jeder Test in einer Transaktion, die zurueckgerollt wird.

import (
	"database/sql"
	"errors"
	"testing"

	"github.com/go-sql-driver/mysql"
)

func openTx(t *testing.T) (*sql.DB, *sql.Tx) {
	t.Helper()
	db, err := Connect()
	if err != nil {
		t.Fatalf("DB-Verbindung: %v", err)
	}
	tx, err := db.Begin()
	if err != nil {
		_ = db.Close()
		t.Fatalf("Begin: %v", err)
	}
	t.Cleanup(func() {
		_ = tx.Rollback()
		_ = db.Close()
	})
	return db, tx
}

func eineStelleID(t *testing.T, tx *sql.Tx) int {
	t.Helper()
	res, err := tx.Exec(
		"INSERT INTO stellenangebot (titel, art, status) " +
			"VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')",
	)
	if err != nil {
		t.Fatalf("INSERT stelle: %v", err)
	}
	id, _ := res.LastInsertId()
	return int(id)
}

func TestBewerberAnlegenUndPerEmailFinden(t *testing.T) {
	_, tx := openTx(t)
	repo := NewSQLRepository(tx)
	id, err := repo.InsertBewerber(Bewerber{
		Vorname: "Erika", Nachname: "Mustermann",
		Email: "go-int@example.com",
	})
	if err != nil {
		t.Fatal(err)
	}
	got, err := repo.FindBewerberIDByEmail("go-int@example.com")
	if err != nil {
		t.Fatal(err)
	}
	if got == nil || *got != id {
		t.Errorf("erwarte %d, war %v", id, got)
	}
	got2, _ := repo.FindBewerberIDByEmail("unbekannt@example.com")
	if got2 != nil {
		t.Errorf("erwarte nil, war %v", got2)
	}
}

func TestBewerbungAnlegenFunktioniert(t *testing.T) {
	_, tx := openTx(t)
	stelleID := eineStelleID(t, tx)
	repo := NewSQLRepository(tx)
	bid, err := repo.InsertBewerber(Bewerber{
		Vorname: "Max", Nachname: "M", Email: "go-m@example.com",
	})
	if err != nil {
		t.Fatal(err)
	}
	aid, err := repo.InsertBewerbung(bid, stelleID, "BEW-2026-GOAB01", nil)
	if err != nil {
		t.Fatal(err)
	}
	if aid <= 0 {
		t.Errorf("erwarte >0, war %d", aid)
	}
}

func TestFremdschluesselVerhindertUngueltigeStelle(t *testing.T) {
	_, tx := openTx(t)
	repo := NewSQLRepository(tx)
	bid, err := repo.InsertBewerber(Bewerber{
		Vorname: "A", Nachname: "B", Email: "go-fk@example.com",
	})
	if err != nil {
		t.Fatal(err)
	}
	_, err = repo.InsertBewerbung(bid, 999999, "BEW-2026-GOFK01", nil)
	var me *mysql.MySQLError
	if !errors.As(err, &me) {
		t.Fatalf("MySQL-Fehler erwartet, war: %v", err)
	}
	if me.Number != 1452 {
		t.Errorf("Errno 1452 erwartet, war: %d", me.Number)
	}
}

func TestVorgangsnummerIstEindeutig(t *testing.T) {
	_, tx := openTx(t)
	stelleID := eineStelleID(t, tx)
	repo := NewSQLRepository(tx)
	bid, err := repo.InsertBewerber(Bewerber{
		Vorname: "C", Nachname: "D", Email: "go-uq@example.com",
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := repo.InsertBewerbung(bid, stelleID, "BEW-2026-GODUP1", nil); err != nil {
		t.Fatal(err)
	}
	_, err = repo.InsertBewerbung(bid, stelleID, "BEW-2026-GODUP1", nil)
	var me *mysql.MySQLError
	if !errors.As(err, &me) {
		t.Fatalf("MySQL-Fehler erwartet, war: %v", err)
	}
	if me.Number != 1062 {
		t.Errorf("Errno 1062 erwartet, war: %d", me.Number)
	}
}
