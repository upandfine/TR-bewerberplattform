<?php

declare(strict_types=1);

namespace App\Tests\Integration;

use App\Database;
use App\PdoBewerbungRepository;
use PDO;
use PDOException;
use PHPUnit\Framework\TestCase;

/**
 * INTEGRATION-Test: läuft gegen die ECHTE MariaDB.
 * Jeder Test in einer Transaktion, die am Ende zurückgerollt
 * wird -> die Datenbank bleibt unverändert.
 */
final class PdoBewerbungRepositoryTest extends TestCase
{
    private PDO $pdo;
    private PdoBewerbungRepository $repo;

    protected function setUp(): void
    {
        $this->pdo = Database::connect();
        $this->pdo->beginTransaction();
        $this->repo = new PdoBewerbungRepository($this->pdo);
    }

    protected function tearDown(): void
    {
        if ($this->pdo->inTransaction()) {
            $this->pdo->rollBack();
        }
    }

    private function eineStelleId(): int
    {
        $this->pdo->exec(
            "INSERT INTO stellenangebot (titel, art, status)
             VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')"
        );
        return (int) $this->pdo->lastInsertId();
    }

    public function testBewerberAnlegenUndPerEmailFinden(): void
    {
        $id = $this->repo->insertBewerber([
            'vorname'  => 'Erika',
            'nachname' => 'Mustermann',
            'email'    => 'integration@example.com',
            'telefon'  => null,
        ]);

        $this->assertSame(
            $id,
            $this->repo->findBewerberIdByEmail('integration@example.com')
        );
        $this->assertNull(
            $this->repo->findBewerberIdByEmail('unbekannt@example.com')
        );
    }

    public function testBewerbungAnlegenFunktioniert(): void
    {
        $stelleId   = $this->eineStelleId();
        $bewerberId = $this->repo->insertBewerber([
            'vorname' => 'Max', 'nachname' => 'M',
            'email' => 'm@example.com', 'telefon' => null,
        ]);

        $id = $this->repo->insertBewerbung(
            $bewerberId, $stelleId, 'BEW-2026-ABCDEF', null
        );

        $this->assertGreaterThan(0, $id);
    }

    public function testFremdschluesselVerhindertUngueltigeStelle(): void
    {
        $bewerberId = $this->repo->insertBewerber([
            'vorname' => 'A', 'nachname' => 'B',
            'email' => 'fk@example.com', 'telefon' => null,
        ]);

        try {
            $this->repo->insertBewerbung(
                $bewerberId, 999999, 'BEW-2026-000001', null
            );
            $this->fail('FK-Verletzung erwartet');
        } catch (PDOException $e) {
            $this->assertSame(1452, (int) $e->errorInfo[1]);
        }
    }

    public function testVorgangsnummerIstEindeutig(): void
    {
        $stelleId   = $this->eineStelleId();
        $bewerberId = $this->repo->insertBewerber([
            'vorname' => 'C', 'nachname' => 'D',
            'email' => 'uq@example.com', 'telefon' => null,
        ]);

        $this->repo->insertBewerbung($bewerberId, $stelleId, 'BEW-2026-DUP001', null);

        try {
            $this->repo->insertBewerbung($bewerberId, $stelleId, 'BEW-2026-DUP001', null);
            $this->fail('UNIQUE-Verletzung erwartet');
        } catch (PDOException $e) {
            $this->assertSame(1062, (int) $e->errorInfo[1]);
        }
    }
}
