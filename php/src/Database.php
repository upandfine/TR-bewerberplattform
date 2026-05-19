<?php

declare(strict_types=1);

namespace App;

use PDO;

/**
 * Liefert eine PDO-Verbindung anhand der Umgebungsvariablen
 * (DB_HOST/DB_NAME/DB_USER/DB_PASS) - kommen aus der .env.
 */
final class Database
{
    public static function connect(): PDO
    {
        $host = getenv('DB_HOST');
        $name = getenv('DB_NAME');
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASS');

        return new PDO(
            "mysql:host={$host};dbname={$name};charset=utf8mb4",
            $user,
            $pass,
            [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]
        );
    }
}
