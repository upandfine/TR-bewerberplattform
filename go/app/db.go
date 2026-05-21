package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

// Connect oeffnet eine MariaDB-Verbindung anhand der Umgebungs-
// variablen DB_HOST/DB_NAME/DB_USER/DB_PASS (kommen aus der .env).
func Connect() (*sql.DB, error) {
	dsn := fmt.Sprintf(
		"%s:%s@tcp(%s:3306)/%s?charset=utf8mb4&parseTime=true",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASS"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_NAME"),
	)
	return sql.Open("mysql", dsn)
}
