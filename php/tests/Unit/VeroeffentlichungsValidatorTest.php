<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\VeroeffentlichungsValidator;
use PHPUnit\Framework\TestCase;

/**
 * TDD-UEBUNG fuer die Schulung (Showcase, granular).
 *
 * Ziel:
 *   Implementiert die Klasse App\VeroeffentlichungsValidator mit der Methode
 *
 *     public function pruefe(array $stelle): array
 *
 *   $stelle hat genau die Struktur, die das Repository ohnehin liefert:
 *     [
 *       'titel'        => string,
 *       'beschreibung' => string|null,
 *       'art'          => string,   // z.B. 'FESTANSTELLUNG'
 *       'status'       => string,   // 'ENTWURF' | 'VEROEFFENTLICHT' | ...
 *     ]
 *
 *   Rueckgabe: Map feldname => Fehlertext. Leeres Array = "darf veroeffentlicht werden".
 *
 * Geschaeftsregeln:
 *   - Titel muss vorhanden sein und >= 10 Zeichen lang.
 *   - Beschreibung muss vorhanden und nicht leer sein.
 *   - Nur Stellen im Status ENTWURF duerfen veroeffentlicht werden.
 *
 * Vorgehen (TDD, sieben kleine Schritte):
 *   1. Tests laufen lassen -> alle ROT.
 *   2. Genau eine Aufgabe implementieren -> EIN Test wird GRUEN, Rest bleibt rot.
 *   3. Wiederholen, bis alle gruen sind.
 *   4. KI darf zum Generieren des Codes genutzt werden -
 *      die Tests sind die Spezifikation, die ihr ihr gebt.
 *
 * Tests einzeln laufen lassen:
 *   vendor/bin/phpunit --filter testKlasseExistiert \
 *                      tests/Unit/VeroeffentlichungsValidatorTest.php
 */
final class VeroeffentlichungsValidatorTest extends TestCase
{
    /**
     * Liefert eine fachlich gueltige Stelle, von der wir in den
     * jeweiligen Tests gezielt EINE Eigenschaft kaputt machen.
     *
     * @return array<string,mixed>
     */
    private function valideStelle(): array
    {
        return [
            'titel'        => 'Senior Backend-Entwickler:in',
            'beschreibung' => 'Wir suchen Unterstuetzung im Team Plattform.',
            'art'          => 'FESTANSTELLUNG',
            'status'       => 'ENTWURF',
        ];
    }

    // --- Schritt 1: Klasse anlegen -------------------------------------

    public function testKlasseExistiert(): void
    {
        // Wird gruen, sobald die Datei src/VeroeffentlichungsValidator.php
        // mit "namespace App;" und "class VeroeffentlichungsValidator" existiert.
        $this->assertTrue(class_exists(VeroeffentlichungsValidator::class));
    }

    // --- Schritt 2: Methode mit Rueckgabetyp ---------------------------

    public function testPruefeGibtArrayZurueck(): void
    {
        // Methode muss aufrufbar sein und ein Array zurueckliefern.
        // Inhalt egal - das pruefen die folgenden Tests.
        $validator = new VeroeffentlichungsValidator();

        $ergebnis = $validator->pruefe($this->valideStelle());

        $this->assertIsArray($ergebnis);
    }

    // --- Schritt 3: Happy Path -----------------------------------------

    public function testValideStelleErgibtKeineFehler(): void
    {
        $validator = new VeroeffentlichungsValidator();

        $ergebnis = $validator->pruefe($this->valideStelle());

        $this->assertSame([], $ergebnis, 'gueltige Stelle darf keine Fehler ergeben');
    }

    // --- Schritt 4: Einzelregel "Titel" --------------------------------

    public function testFehlenderTitelWirdGemeldet(): void
    {
        $validator = new VeroeffentlichungsValidator();
        $stelle = $this->valideStelle();
        $stelle['titel'] = 'kurz'; // < 10 Zeichen

        $ergebnis = $validator->pruefe($stelle);

        $this->assertArrayHasKey('titel', $ergebnis);
    }

    // --- Schritt 5: Einzelregel "Beschreibung" -------------------------

    public function testFehlendeBeschreibungWirdGemeldet(): void
    {
        $validator = new VeroeffentlichungsValidator();
        $stelle = $this->valideStelle();
        $stelle['beschreibung'] = null;

        $ergebnis = $validator->pruefe($stelle);

        $this->assertArrayHasKey('beschreibung', $ergebnis);
    }

    // --- Schritt 6: Einzelregel "Status" -------------------------------

    public function testNurEntwurfDarfVeroeffentlichtWerden(): void
    {
        $validator = new VeroeffentlichungsValidator();
        $stelle = $this->valideStelle();
        $stelle['status'] = 'VEROEFFENTLICHT'; // schon raus

        $ergebnis = $validator->pruefe($stelle);

        $this->assertArrayHasKey('status', $ergebnis);
    }

    // --- Schritt 7: Fehler sammeln, nicht abbrechen --------------------

    public function testMehrereFehlerWerdenGesammelt(): void
    {
        $validator = new VeroeffentlichungsValidator();
        $kaputt = [
            'titel'        => '',
            'beschreibung' => '',
            'art'          => 'FESTANSTELLUNG',
            'status'       => 'ARCHIVIERT',
        ];

        $ergebnis = $validator->pruefe($kaputt);

        // Alle drei Probleme muessen gemeldet werden - nicht beim ersten abbrechen.
        $this->assertArrayHasKey('titel', $ergebnis);
        $this->assertArrayHasKey('beschreibung', $ergebnis);
        $this->assertArrayHasKey('status', $ergebnis);
    }
}
