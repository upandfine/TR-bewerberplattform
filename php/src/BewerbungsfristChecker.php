<?php

declare(strict_types=1);

namespace App;

use DateTimeImmutable;

/**
 * Reine Fachlogik: ist eine Stelle aktuell "bewerbbar"?
 *
 * Kennt weder DB noch HTTP - alles, was sie braucht, kommt als Parameter rein.
 * Deshalb ist sie unit-testbar ohne jegliches Setup.
 *
 * Regel:
 *   aktiv := status === 'VEROEFFENTLICHT'
 *            AND (bewerbungsfrist === null OR bewerbungsfrist >= heute)
 */
final class BewerbungsfristChecker
{
    /**
     * @param array{status:string, bewerbungsfrist:?string} $stelle
     */
    public function istAktiv(array $stelle, DateTimeImmutable $jetzt): bool
    {
        if ($stelle['status'] !== 'VEROEFFENTLICHT') {
            return false;
        }

        $frist = $stelle['bewerbungsfrist'] ?? null;
        if ($frist === null) {
            return true;
        }

        // Tagesgenauer Vergleich: ISO-Datum 'YYYY-MM-DD' laesst sich
        // lexikografisch korrekt vergleichen.
        return $frist >= $jetzt->format('Y-m-d');
    }
}
