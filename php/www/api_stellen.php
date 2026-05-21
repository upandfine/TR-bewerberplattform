<?php

declare(strict_types=1);

// HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.
// Erreichbar unter  http://localhost:8080/api_stellen.php

require '/var/www/vendor/autoload.php';

use App\Database;
use App\PdoStellenangebotRepository;
use App\StellenangebotService;
use App\ValidationException;

header('Content-Type: application/json; charset=utf-8');

// CORS: erlaubt dem Vue-Frontend (anderer Origin) den Zugriff.
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function json(int $status, array $body): never
{
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

try {
    $service = new StellenangebotService(
        new PdoStellenangebotRepository(Database::connect())
    );

    switch ($_SERVER['REQUEST_METHOD']) {
        case 'POST':
            $input = json_decode(file_get_contents('php://input') ?: '', true);
            if (!is_array($input)) {
                json(400, ['fehler' => 'Body muss gueltiges JSON sein.']);
            }
            json(201, $service->anlegen($input));

        case 'GET':
            $status = $_GET['status'] ?? null;
            json(200, ['stellen' => $service->liste($status)]);

        default:
            json(405, ['fehler' => 'Methode nicht erlaubt.']);
    }
} catch (ValidationException $e) {
    json(400, ['fehler' => $e->getMessage(), 'details' => $e->errors]);
} catch (PDOException $e) {
    // 1265 = falscher ENUM-Wert (sollte durch Validierung verhindert sein)
    json(500, ['fehler' => 'Datenbankfehler.']);
}
