<?php

declare(strict_types=1);

namespace App\Tests\Integration;

use App\Database;
use App\PdoStellenangebotRepository;
use PDO;
use PHPUnit\Framework\TestCase;

/**
 * INTEGRATION-Test: laeuft gegen die ECHTE MariaDB.
 * Jeder Test in einer Transaktion, die am Ende zurueckgerollt
 * wird -> die Datenbank bleibt unveraendert.
 */
final class PdoStellenangebotRepositoryTest extends TestCase
{
    private PDO $pdo;
    private PdoStellenangebotRepository $repo;

    protected function setUp(): void
    {
        $this->pdo = Database::connect();
        $this->pdo->beginTransaction();
        $this->repo = new PdoStellenangebotRepository($this->pdo);
    }

    protected function tearDown(): void
    {
        if ($this->pdo->inTransaction()) {
            $this->pdo->rollBack();
        }
    }

    public function testStelleAnlegenLiefertId(): void
    {
        $id = $this->repo->insertStelle([
            'titel'        => 'Integration: Backend-Entwickler:in',
            'beschreibung' => 'PHP/MariaDB',
            'art'          => 'FESTANSTELLUNG',
            'status'       => 'ENTWURF',
        ]);

        $this->assertGreaterThan(0, $id);
    }

    public function testListePartiellGefiltertNachStatus(): void
    {
        $this->repo->insertStelle([
            'titel' => 'I-A', 'beschreibung' => null,
            'art'   => 'FESTANSTELLUNG', 'status' => 'ENTWURF',
        ]);
        $this->repo->insertStelle([
            'titel' => 'I-B', 'beschreibung' => null,
            'art'   => 'WERKSTUDENT', 'status' => 'VEROEFFENTLICHT',
        ]);

        $entwurf = $this->repo->listStellen('ENTWURF');
        $titel   = array_column($entwurf, 'titel');

        $this->assertContains('I-A', $titel);
        $this->assertNotContains('I-B', $titel);
    }

    public function testPreparedStatementVerhindertSqlInjection(): void
    {
        // Klassischer Injection-Versuch: wuerde bei naivem
        // Concat eine zweite Anweisung anhaengen. Da wir Prepared
        // Statements nutzen, wird der gesamte String als Titelwert
        // behandelt.
        $boeserTitel = "Hacker'); DROP TABLE stellenangebot; --";

        $id = $this->repo->insertStelle([
            'titel'        => $boeserTitel,
            'beschreibung' => null,
            'art'          => 'FESTANSTELLUNG',
            'status'       => 'ENTWURF',
        ]);

        $alle  = $this->repo->listStellen(null);
        $titel = array_column($alle, 'titel');

        $this->assertContains($boeserTitel, $titel);
        // Tabelle existiert noch und enthaelt unseren Datensatz.
        $this->assertGreaterThan(0, $id);
    }
}
