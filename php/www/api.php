<?php

declare(strict_types=1);

// HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.
// Erreichbar unter  http://localhost:8080/api.php

require '/var/www/vendor/autoload.php';

use App\BewerbungService;
use App\Database;
use App\PdoBewerbungRepository;
use App\ValidationException;

header('Content-Type: application/json; charset=utf-8');

function json(int $status, array $body): never
{
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

try {
    $service = new BewerbungService(
        new PdoBewerbungRepository(Database::connect())
    );

    switch ($_SERVER['REQUEST_METHOD']) {
        case 'POST':
            $input = json_decode(file_get_contents('php://input') ?: '', true);
            if (!is_array($input)) {
                json(400, ['fehler' => 'Body muss gültiges JSON sein.']);
            }
            $result = $service->einreichen($input);
            json(201, $result);

        case 'GET':
            $status = $_GET['status'] ?? null;
            json(200, ['bewerbungen' => $service->liste($status)]);

        default:
            json(405, ['fehler' => 'Methode nicht erlaubt.']);
    }
} catch (ValidationException $e) {
    json(400, ['fehler' => $e->getMessage(), 'details' => $e->errors]);
} catch (PDOException $e) {
    // 1452 = FK schlägt fehl (Stelle existiert nicht)
    // 1062 = UNIQUE verletzt (vorgangs_nr-Kollision)
    $code = (int) ($e->errorInfo[1] ?? 0);
    if ($code === 1452) {
        json(422, ['fehler' => 'Angegebene stelle_id existiert nicht.']);
    }
    if ($code === 1062) {
        json(409, ['fehler' => 'Vorgangsnummer-Kollision, bitte erneut senden.']);
    }
    json(500, ['fehler' => 'Datenbankfehler.']);
}
