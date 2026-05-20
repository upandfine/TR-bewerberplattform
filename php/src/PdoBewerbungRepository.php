<?php

declare(strict_types=1);

namespace App;

use PDO;

/**
 * Konkrete Persistenz gegen MariaDB. Integration-testbar gegen
 * die laufende DB (FK-RESTRICT auf Stelle, UNIQUE vorgangs_nr).
 */
final class PdoBewerbungRepository implements BewerbungRepositoryInterface
{
    public function __construct(private readonly PDO $pdo) {}

    public function findBewerberIdByEmail(string $email): ?int
    {
        $stmt = $this->pdo->prepare(
            'SELECT id FROM bewerber WHERE email = :email'
        );
        $stmt->execute([':email' => $email]);
        $id = $stmt->fetchColumn();

        return $id === false ? null : (int) $id;
    }

    /** @param array<string,mixed> $bewerber */
    public function insertBewerber(array $bewerber): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO bewerber (vorname, nachname, email, telefon)
             VALUES (:vorname, :nachname, :email, :telefon)'
        );
        $stmt->execute([
            ':vorname'  => $bewerber['vorname'],
            ':nachname' => $bewerber['nachname'],
            ':email'    => $bewerber['email'],
            ':telefon'  => $bewerber['telefon'] ?? null,
        ]);


        return (int) $this->pdo->lastInsertId();
    }

    public function insertBewerbung(
        int $bewerberId,
        int $stelleId,
        string $vorgangsNr,
        ?string $bemerkung
    ): int {
        $stmt = $this->pdo->prepare(
            'INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung)
             VALUES (:bewerber_id, :stelle_id, :vorgangs_nr, :bemerkung)'
        );
        $stmt->execute([
            ':bewerber_id' => $bewerberId,
            ':stelle_id'   => $stelleId,
            ':vorgangs_nr' => $vorgangsNr,
            ':bemerkung'   => $bemerkung,
        ]);

        return (int) $this->pdo->lastInsertId();
    }

    /** @return array<int,array<string,mixed>> */
    public function listBewerbungen(?string $status): array
    {
        // Spalten heißen in der DB camelCase; nach außen liefern wir
        // stabile snake_case-Schlüssel (API-/Test-Vertrag bleibt gleich).
        $sql =
            'SELECT b.id,
                    b.vorgangsNr AS vorgangs_nr,
                    b.status,
                    b.eingangAm  AS eingang_am,
                    bw.vorname, bw.nachname, bw.email,
                    s.titel AS stelle
             FROM bewerbung b
             JOIN bewerber bw       ON bw.id = b.bewerberId
             JOIN stellenangebot s  ON s.id  = b.stelleId';

        if ($status !== null) {
            $sql .= ' WHERE b.status = :status';
        }
        $sql .= ' ORDER BY b.eingangAm DESC';

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($status !== null ? [':status' => $status] : []);

        return $stmt->fetchAll();
    }
}
