<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\BewerbungsfristChecker;
use DateTimeImmutable;
use PHPUnit\Framework\TestCase;

/**
 * UNIT-Test (TDD-Uebung):
 *
 * Aufgabe fuer die TN:
 *   Implementiert die Klasse App\BewerbungsfristChecker mit der Methode
 *
 *     public function istAktiv(array $stelle, DateTimeImmutable $jetzt): bool
 *
 *   Eine Stelle ist "aktiv" (= Bewerbung moeglich), wenn:
 *     - status === 'VEROEFFENTLICHT' UND
 *     - bewerbungsfrist == null  ODER  bewerbungsfrist >= $jetzt (Tagesgenau)
 *
 *   Format von $stelle (so wie es aus dem Repository kommt):
 *     [
 *       'titel'           => string,
 *       'status'          => 'ENTWURF' | 'VEROEFFENTLICHT' | 'ARCHIVIERT',
 *       'bewerbungsfrist' => string|null,   // 'YYYY-MM-DD' oder null
 *     ]
 *
 * Vorgehen (TDD):
 *   1. Tests laufen lassen -> ROT (Klasse existiert noch nicht)
 *   2. Minimale Implementierung -> erster Test wird GRUEN
 *   3. Naechster Test -> wieder ROT -> Code erweitern -> GRUEN
 *   4. Refactor, wenn alles gruen ist
 */
final class BewerbungsfristCheckerTest extends TestCase
{
    private BewerbungsfristChecker $checker;
    private DateTimeImmutable $heute;

    protected function setUp(): void
    {
        $this->checker = new BewerbungsfristChecker();
        // "Heute" als fixer Stichtag - so sind die Tests reproduzierbar.
        $this->heute = new DateTimeImmutable('2026-05-21');
    }

    // --- Happy Path -----------------------------------------------------

    public function testVeroeffentlichtUndFristInZukunftIstAktiv(): void
    {
        $stelle = [
            'titel'           => 'Senior Backend-Entwickler:in',
            'status'          => 'VEROEFFENTLICHT',
            'bewerbungsfrist' => '2026-06-30',
        ];

        $this->assertTrue($this->checker->istAktiv($stelle, $this->heute));
    }

    // --- Abweichungen ---------------------------------------------------

    public function testOhneFristIstUnbefristetAktiv(): void
    {
        $stelle = [
            'titel'           => 'Werkstudent:in',
            'status'          => 'VEROEFFENTLICHT',
            'bewerbungsfrist' => null,
        ];

        $this->assertTrue($this->checker->istAktiv($stelle, $this->heute));
    }

    public function testFristInVergangenheitIstNichtAktiv(): void
    {
        $stelle = [
            'titel'           => 'Praktikant:in',
            'status'          => 'VEROEFFENTLICHT',
            'bewerbungsfrist' => '2026-05-20', // gestern
        ];

        $this->assertFalse($this->checker->istAktiv($stelle, $this->heute));
    }

    public function testFristGenauHeuteIstNochAktiv(): void
    {
        // Grenzfall: am letzten Tag soll man sich noch bewerben koennen.
        $stelle = [
            'titel'           => 'DevOps Engineer',
            'status'          => 'VEROEFFENTLICHT',
            'bewerbungsfrist' => '2026-05-21',
        ];

        $this->assertTrue($this->checker->istAktiv($stelle, $this->heute));
    }

    public function testEntwurfIstNieAktiv(): void
    {
        $stelle = [
            'titel'           => 'Noch nicht veroeffentlicht',
            'status'          => 'ENTWURF',
            'bewerbungsfrist' => '2026-12-31',
        ];

        $this->assertFalse($this->checker->istAktiv($stelle, $this->heute));
    }

    public function testArchiviertIstNichtAktivAuchOhneFrist(): void
    {
        $stelle = [
            'titel'           => 'Alte Stelle',
            'status'          => 'ARCHIVIERT',
            'bewerbungsfrist' => null,
        ];

        $this->assertFalse($this->checker->istAktiv($stelle, $this->heute));
    }
}
