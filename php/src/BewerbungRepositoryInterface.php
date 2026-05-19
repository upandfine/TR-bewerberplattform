<?php

declare(strict_types=1);

namespace App;

/**
 * Naht zwischen Service (reine Logik) und Persistenz.
 * Im Unit-Test wird diese Schnittstelle durch ein In-Memory-Fake
 * ersetzt -> Service-Tests brauchen keine Datenbank.
 */
interface BewerbungRepositoryInterface
{
    public function findBewerberIdByEmail(string $email): ?int;

    /** @param array<string,mixed> $bewerber */
    public function insertBewerber(array $bewerber): int;

    public function insertBewerbung(
        int $bewerberId,
        int $stelleId,
        string $vorgangsNr,
        ?string $bemerkung
    ): int;

    /** @return array<int,array<string,mixed>> */
    public function listBewerbungen(?string $status): array;
}
