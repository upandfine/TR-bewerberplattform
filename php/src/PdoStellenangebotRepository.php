<?php

declare(strict_types=1);

namespace App;

use PDO;

/**
 * Konkrete Persistenz gegen MariaDB. Alle SQL-Statements nutzen
 * Prepared Statements mit benannten Platzhaltern -> Schutz vor
 * SQL-Injection.
 *
 * Spalten heissen in der DB camelCase; nach aussen liefern wir
 * stabile snake_case-Schluessel (gleicher Vertrag wie bei Bewerbung).
 */
final class PdoStellenangebotRepository implements StellenangebotRepositoryInterface
{
    public function __construct(private readonly PDO $pdo) {}

    /** @param array{titel:string,beschreibung:?string,art:string,status:string} $stelle */
    public function insertStelle(array $stelle): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO stellenangebot (titel, beschreibung, art, status)
             VALUES (:titel, :beschreibung, :art, :status)'
        );
        $stmt->execute([
            ':titel'        => $stelle['titel'],
            ':beschreibung' => $stelle['beschreibung'],
            ':art'          => $stelle['art'],
            ':status'       => $stelle['status'],
        ]);

        return (int) $this->pdo->lastInsertId();
    }

    /** @return array<int,array<string,mixed>> */
    public function listStellen(?string $status): array
    {
        $sql =
            'SELECT id,
                    titel,
                    beschreibung,
                    art,
                    status,
                    erstelltAm         AS erstellt_am,
                    veroeffentlichtAm  AS veroeffentlicht_am
             FROM stellenangebot';

        if ($status !== null) {
            $sql .= ' WHERE status = :status';
        }
        $sql .= ' ORDER BY erstelltAm DESC';

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($status !== null ? [':status' => $status] : []);

        return $stmt->fetchAll();
    }
}
