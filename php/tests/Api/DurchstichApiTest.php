<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Database;
use PDO;
use PHPUnit\Framework\TestCase;

/**
 * API-/E2E-Test: echter HTTP-Durchstich durch alle Schichten
 * (Apache -> api.php -> Service -> Repository -> MariaDB).
 * Läuft im PHP-Container gegen http://localhost/api.php.
 */
final class DurchstichApiTest extends TestCase
{
    private const BASE = 'http://localhost/api.php';
    private string $email;

    protected function setUp(): void
    {
        $this->email = 'apitest+' . uniqid() . '@example.com';
    }

    protected function tearDown(): void
    {
        // Testdaten wieder entfernen (CASCADE löscht die Bewerbung mit).
        // Schema nutzt ON DELETE RESTRICT -> abhängige Bewerbung
        // zuerst löschen, dann den Bewerber.
        $pdo = Database::connect();
        $pdo->prepare(
            'DELETE FROM bewerbung
             WHERE bewerberId IN (SELECT id FROM bewerber WHERE email = :e)'
        )->execute([':e' => $this->email]);
        $pdo->prepare('DELETE FROM bewerber WHERE email = :e')
            ->execute([':e' => $this->email]);
    }

    private function stelleId(): int
    {
        $pdo = Database::connect();
        $id  = $pdo->query('SELECT MIN(id) FROM stellenangebot')->fetchColumn();
        if ($id === null || $id === false) {
            $this->markTestSkipped(
                'Keine Stelle vorhanden - DB ggf. neu initialisieren (down -v && up -d).'
            );
        }
        return (int) $id;
    }

    /** @return array{0:int,1:array} */
    private function request(string $method, string $url, ?array $body = null): array
    {
        $ctx = stream_context_create(['http' => [
            'method'        => $method,
            'header'        => "Content-Type: application/json\r\n",
            'content'       => $body !== null ? json_encode($body) : '',
            'ignore_errors' => true,
        ]]);
        $raw    = file_get_contents($url, false, $ctx);
        $status = (int) explode(' ', $http_response_header[0])[1];

        return [$status, json_decode($raw, true)];
    }

    public function testPostLegtBewerbungAnUndGetListetSie(): void
    {
        [$status, $post] = $this->request('POST', self::BASE, [
            'vorname'   => 'API',
            'nachname'  => 'Tester',
            'email'     => $this->email,
            'stelle_id' => $this->stelleId(),
        ]);

        $this->assertSame(201, $status);
        $this->assertArrayHasKey('vorgangs_nr', $post);

        [$status, $get] = $this->request('GET', self::BASE);
        $this->assertSame(200, $status);

        $nummern = array_column($get['bewerbungen'], 'vorgangs_nr');
        $this->assertContains($post['vorgangs_nr'], $nummern);
    }

    public function testPostMitUngueltigenDatenLiefert400(): void
    {
        [$status, $body] = $this->request('POST', self::BASE, [
            'email' => 'kaputt', 'stelle_id' => 0,
        ]);

        $this->assertSame(400, $status);
        $this->assertArrayHasKey('details', $body);
    }
}
