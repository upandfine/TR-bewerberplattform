<?php

declare(strict_types=1);

namespace App;

/**
 * Naht zwischen Service (reine Logik) und Persistenz.
 * Im Unit-Test wird diese Schnittstelle durch ein In-Memory-Fake
 * ersetzt -> Service-Tests brauchen keine Datenbank.
 */
interface StellenangebotRepositoryInterface
{
    /**
     * @param array{titel:string,beschreibung:?string,art:string,status:string} $stelle
     */
    public function insertStelle(array $stelle): int;

    /** @return array<int,array<string,mixed>> */
    public function listStellen(?string $status): array;
}
