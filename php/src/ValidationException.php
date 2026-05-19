<?php

declare(strict_types=1);

namespace App;

use RuntimeException;

/**
 * Fachlicher Validierungsfehler -> wird im HTTP-Handler zu 400.
 * Trägt eine Liste der konkreten Feld-Fehler.
 */
final class ValidationException extends RuntimeException
{
    /** @param array<int,string> $errors */
    public function __construct(public readonly array $errors)
    {
        parent::__construct('Validierung fehlgeschlagen');
    }
}
