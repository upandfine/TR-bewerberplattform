<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Database;
use PHPUnit\Framework\TestCase;

/**
 * API-/E2E-Test: echter HTTP-Durchstich durch alle Schichten
 * (Apache -> api_stellen.php -> Service -> Repository -> MariaDB).
 * Laeuft im PHP-Container gegen http://localhost/api_stellen.php.
 */
final class StellenangebotApiTest extends TestCase
{
    private const BASE = 'http://localhost/api_stellen.php';
    private string $titel;

    protected function setUp(): void
    {
        $this->titel = 'APITest-' . uniqid();
    }

    protected function tearDown(): void
    {
        // Stellen ohne abhaengige Bewerbungen koennen weg.
        Database::connect()
            ->prepare('DELETE FROM stellenangebot WHERE titel = :t')
            ->execute([':t' => $this->titel]);
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

    public function testPostLegtStelleMitStatusEntwurfAn(): void
    {
        [$status, $post] = $this->request('POST', self::BASE, [
            'titel' => $this->titel,
            'art'   => 'WERKSTUDENT',
            // Versucht, ENTWURF zu umgehen - Service-Regel ignoriert es.
            'status' => 'VEROEFFENTLICHT',
        ]);

        $this->assertSame(201, $status);
        $this->assertSame('ENTWURF', $post['status']);
        $this->assertSame('WERKSTUDENT', $post['art']);
        $this->assertIsInt($post['id']);
    }

    public function testGetListetDieAngelegteStelle(): void
    {
        $this->request('POST', self::BASE, [
            'titel' => $this->titel,
            'art'   => 'PRAKTIKUM',
        ]);

        [$status, $get] = $this->request('GET', self::BASE . '?status=ENTWURF');
        $this->assertSame(200, $status);

        $titel = array_column($get['stellen'], 'titel');
        $this->assertContains($this->titel, $titel);
    }

    public function testPostOhneTitelLiefert400(): void
    {
        [$status, $body] = $this->request('POST', self::BASE, ['art' => 'AZUBI']);

        $this->assertSame(400, $status);
        $this->assertArrayHasKey('details', $body);
    }
}
