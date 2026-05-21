<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\StellenangebotRepositoryInterface;
use App\StellenangebotService;
use App\ValidationException;
use PHPUnit\Framework\TestCase;

/**
 * UNIT-Test: prueft reine Fachlogik OHNE Datenbank.
 * Das Repository wird durch ein In-Memory-Fake ersetzt.
 */
final class StellenangebotServiceTest extends TestCase
{
    private function fakeRepo(): StellenangebotRepositoryInterface
    {
        return new class implements StellenangebotRepositoryInterface {
            /** @var array<int,array<string,mixed>> */
            public array $rows = [];
            public int $naechsteId = 1;

            public function insertStelle(array $stelle): int
            {
                $id = $this->naechsteId++;
                $this->rows[] = ['id' => $id] + $stelle;
                return $id;
            }

            public function listStellen(?string $status): array
            {
                if ($status === null) return $this->rows;
                return array_values(array_filter(
                    $this->rows,
                    fn(array $r) => $r['status'] === $status
                ));
            }
        };
    }

    public function testNeueStelleStartetImmerAlsEntwurf(): void
    {
        $repo    = $this->fakeRepo();
        $service = new StellenangebotService($repo);

        $result = $service->anlegen([
            'titel' => 'Senior Backend-Entwickler:in',
            'art'   => 'FESTANSTELLUNG',
            // Aufrufer versucht, einen anderen Status zu setzen -
            // der Service muss das ignorieren.
            'status' => 'VEROEFFENTLICHT',
        ]);

        $this->assertSame('ENTWURF', $result['status']);
        $this->assertSame('ENTWURF', $repo->rows[0]['status']);
    }

    public function testStandardArtIstFestanstellung(): void
    {
        $service = new StellenangebotService($this->fakeRepo());

        $result = $service->anlegen(['titel' => 'Praktikant:in IT']);

        $this->assertSame('FESTANSTELLUNG', $result['art']);
    }

    public function testTitelIstPflicht(): void
    {
        $service = new StellenangebotService($this->fakeRepo());

        try {
            $service->anlegen(['titel' => '   ']);
            $this->fail('ValidationException erwartet');
        } catch (ValidationException $e) {
            $this->assertNotEmpty($e->errors);
        }
    }

    public function testUngueltigeArtWirdAbgelehnt(): void
    {
        $service = new StellenangebotService($this->fakeRepo());

        $this->expectException(ValidationException::class);
        $service->anlegen(['titel' => 'Stelle', 'art' => 'KEIN_ECHTER_TYP']);
    }

    public function testListeFiltertNachStatus(): void
    {
        $repo    = $this->fakeRepo();
        $service = new StellenangebotService($repo);

        $service->anlegen(['titel' => 'A']);
        $service->anlegen(['titel' => 'B']);
        // Stelle "C" haendisch in den Fake schieben, damit wir
        // verschiedene Status sehen koennen.
        $repo->insertStelle([
            'titel' => 'C', 'beschreibung' => null,
            'art' => 'FESTANSTELLUNG', 'status' => 'VEROEFFENTLICHT',
        ]);

        $entwurf = $service->liste('ENTWURF');
        $this->assertCount(2, $entwurf);
    }

    public function testListeMitUngueltigemStatusWirft(): void
    {
        $service = new StellenangebotService($this->fakeRepo());
        $this->expectException(ValidationException::class);
        $service->liste('UNBEKANNT');
    }
}
