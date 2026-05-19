<?php

declare(strict_types=1);

namespace App;

/**
 * Use-Case-Schicht: reine Fachlogik, kennt weder PDO noch HTTP.
 * Genau deshalb ohne Datenbank unit-testbar.
 */
final class BewerbungService
{
    public function __construct(
        private readonly BewerbungRepositoryInterface $repo
    ) {}

    /**
     * Use-Case "Bewerbung einreichen".
     *
     * @param array<string,mixed> $input
     * @return array{bewerbung_id:int,bewerber_id:int,vorgangs_nr:string}
     */
    public function einreichen(array $input): array
    {
        $this->validate($input);

        $email = trim((string) $input['email']);

        // Person wiederverwenden, wenn E-Mail bereits bekannt ist.
        $bewerberId = $this->repo->findBewerberIdByEmail($email);
        if ($bewerberId === null) {
            $bewerberId = $this->repo->insertBewerber([
                'vorname'  => trim((string) $input['vorname']),
                'nachname' => trim((string) $input['nachname']),
                'email'    => $email,
                'telefon'  => isset($input['telefon'])
                    ? trim((string) $input['telefon'])
                    : null,
            ]);
        }

        $vorgangsNr  = self::generateVorgangsNr();
        $bewerbungId = $this->repo->insertBewerbung(
            $bewerberId,
            (int) $input['stelle_id'],
            $vorgangsNr,
            isset($input['bemerkung']) ? trim((string) $input['bemerkung']) : null
        );

        return [
            'bewerbung_id' => $bewerbungId,
            'bewerber_id'  => $bewerberId,
            'vorgangs_nr'  => $vorgangsNr,
        ];
    }

    /** @return array<int,array<string,mixed>> */
    public function liste(?string $status = null): array
    {
        return $this->repo->listBewerbungen($status);
    }

    public static function generateVorgangsNr(): string
    {
        return sprintf(
            'BEW-%s-%06X',
            date('Y'),
            random_int(0, 0xFFFFFF)
        );
    }

    /** @param array<string,mixed> $input */
    private function validate(array $input): void
    {
        $errors = [];

        foreach (['vorname', 'nachname'] as $feld) {
            if (trim((string) ($input[$feld] ?? '')) === '') {
                $errors[] = "Feld '{$feld}' ist ein Pflichtfeld.";
            }
        }

        $email = trim((string) ($input['email'] ?? ''));
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            $errors[] = "Feld 'email' ist keine gültige E-Mail-Adresse.";
        }

        $stelle = $input['stelle_id'] ?? null;
        if (!is_numeric($stelle) || (int) $stelle <= 0) {
            $errors[] = "Feld 'stelle_id' muss eine positive Zahl sein.";
        }

        if ($errors !== []) {
            throw new ValidationException($errors);
        }
    }
}
