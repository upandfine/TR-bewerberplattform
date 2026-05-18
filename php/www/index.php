<?php
// ============================================================
//  Demo-Seite: zeigt, dass PHP läuft und die DB erreichbar ist.
//  Eigenen Code einfach in dieser Datei oder neuen Dateien
//  im Ordner php/www/ ablegen.
// ============================================================

header('Content-Type: text/html; charset=utf-8');

// Zugangsdaten kommen als Umgebungsvariablen aus der .env
$host = getenv('DB_HOST');
$db   = getenv('DB_NAME');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');

echo "<h1>PHP " . phpversion() . " läuft </h1>";

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$db;charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $version = $pdo->query('SELECT VERSION()')->fetchColumn();
    echo "<p style='color:green'>Datenbank-Verbindung OK - MariaDB $version</p>";
} catch (PDOException $e) {
    echo "<p style='color:red'>Keine DB-Verbindung: "
        . htmlspecialchars($e->getMessage()) . "</p>";
}
