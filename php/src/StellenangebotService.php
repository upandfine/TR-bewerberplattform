<?php

declare(strict_types=1);

namespace App;

/**
 * Use-Case-Schicht: reine Fachlogik, kennt weder PDO noch HTTP.
 *
 * Wichtigste Geschaeftsregel:
 *   Eine neue Stelle startet IMMER mit Status 'ENTWURF'.
 *   Ein vom Aufrufer gelieferter status wird bewusst ignoriert.
 *   (Die DB hat zwar denselben Default - die Regel hier sichert,
 *    dass auch ein anderer Persistenz-Adapter sie einhaelt.)
 */
final class StellenangebotService
{
    public const STATUS_ENTWURF = 'ENTWURF';

    /** @var list<string> */
    public const ARTEN = [
        'FESTANSTELLUNG',
        'AZUBI',
        'MINIJOB',
        'WERKSTUDENT',
        'PRAKTIKUM',
    ];

    /** @var list<string> */
    public const STATI = [
        'ENTWURF',
        'VEROEFFENTLICHT',
        'GESCHLOSSEN',
        'ARCHIVIERT',
    ];

    public function __construct(
        private readonly StellenangebotRepositoryInterface $repo
    ) {}

    /**
     * Use-Case "Stelle anlegen".
     *
     * @param array<string,mixed> $input
     * @return array{id:int,titel:string,art:string,status:string}
     */
    public function anlegen(array $input): array
    {
        $this->validate($input);

        $titel        = trim((string) $input['titel']);
        $beschreibung = isset($input['beschreibung'])
            ? trim((string) $input['beschreibung'])
            : null;
        $art = isset($input['art']) && $input['art'] !== ''
            ? (string) $input['art']
            : 'FESTANSTELLUNG';

        // Geschaeftsregel: neue Stellen starten IMMER als ENTWURF.
        $status = self::STATUS_ENTWURF;

        $id = $this->repo->insertStelle([
            'titel'        => $titel,
            'beschreibung' => $beschreibung,
            'art'          => $art,
            'status'       => $status,
        ]);

        return [
            'id'     => $id,
            'titel'  => $titel,
            'art'    => $art,
            'status' => $status,
        ];
    }

    /** @return array<int,array<string,mixed>> */
    public function liste(?string $status = null): array
    {
        if ($status !== null && !in_array($status, self::STATI, true)) {
            throw new ValidationException([
                "Parameter 'status' ist kein gueltiger Stellenstatus.",
            ]);
        }
        return $this->repo->listStellen($status);
    }

    /** @param array<string,mixed> $input */
    private function validate(array $input): void
    {
        $errors = [];

        $titel = trim((string) ($input['titel'] ?? ''));
        if ($titel === '') {
            $errors[] = "Feld 'titel' ist ein Pflichtfeld.";
        } elseif (mb_strlen($titel) > 120) {
            $errors[] = "Feld 'titel' darf maximal 120 Zeichen lang sein.";
        }

        if (isset($input['art']) && $input['art'] !== ''
            && !in_array($input['art'], self::ARTEN, true)) {
            $errors[] = "Feld 'art' ist keine gueltige Stellenart.";
        }

        if ($errors !== []) {
            throw new ValidationException($errors);
        }
    }
}
