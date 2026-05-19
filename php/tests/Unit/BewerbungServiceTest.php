<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\BewerbungRepositoryInterface;
use App\BewerbungService;
use App\ValidationException;
use PHPUnit\Framework\TestCase;

/**
 * UNIT-Test: prüft reine Fachlogik OHNE Datenbank.
 * Das Repository wird durch ein In-Memory-Fake ersetzt.
 */
final class BewerbungServiceTest extends TestCase
{
    private function fakeRepo(): BewerbungRepositoryInterface
    {
        return new class implements BewerbungRepositoryInterface {
            /** @var array<string,int> */
            public array $emails = [];
            public int $naechsteId = 1;
            public ?int $letzteStelleId = null;

            public function findBewerberIdByEmail(string $email): ?int
            {
                return $this->emails[$email] ?? null;
            }

            public function insertBewerber(array $bewerber): int
            {
                $id = $this->naechsteId++;
                $this->emails[$bewerber['email']] = $id;
                return $id;
            }

            public function insertBewerbung(
                int $bewerberId,
                int $stelleId,
                string $vorgangsNr,
                ?string $bemerkung
            ): int {
                $this->letzteStelleId = $stelleId;
                return $this->naechsteId++;
            }

            public function listBewerbungen(?string $status): array
            {
                return [];
            }
        };
    }

    public function testEinreichenLiefertVorgangsnummerImKorrektenFormat(): void
    {
        $service = new BewerbungService($this->fakeRepo());

        $result = $service->einreichen([
            'vorname'   => 'Erika',
            'nachname'  => 'Mustermann',
            'email'     => 'erika@example.com',
            'stelle_id' => 1,
        ]);

        $this->assertMatchesRegularExpression(
            '/^BEW-\d{4}-[0-9A-F]{6}$/',
            $result['vorgangs_nr']
        );
        $this->assertIsInt($result['bewerbung_id']);
    }

    public function testBekannteEmailWirdWiederverwendet(): void
    {
        $repo = $this->fakeRepo();
        $service = new BewerbungService($repo);

        $a = $service->einreichen([
            'vorname' => 'Max', 'nachname' => 'M',
            'email' => 'max@example.com', 'stelle_id' => 1,
        ]);
        $b = $service->einreichen([
            'vorname' => 'Max', 'nachname' => 'M',
            'email' => 'max@example.com', 'stelle_id' => 2,
        ]);

        $this->assertSame($a['bewerber_id'], $b['bewerber_id']);
    }

    public function testFehlendePflichtfelderWerfenValidationException(): void
    {
        $service = new BewerbungService($this->fakeRepo());

        try {
            $service->einreichen(['email' => 'kein-email', 'stelle_id' => 0]);
            $this->fail('ValidationException erwartet');
        } catch (ValidationException $e) {
            $this->assertNotEmpty($e->errors);
            $this->assertGreaterThanOrEqual(3, count($e->errors));
        }
    }

    public function testGenerateVorgangsNrFormat(): void
    {
        $this->assertMatchesRegularExpression(
            '/^BEW-\d{4}-[0-9A-F]{6}$/',
            BewerbungService::generateVorgangsNr()
        );
    }
}
