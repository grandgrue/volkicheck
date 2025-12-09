<?php
/**
 * VOLKICHECK - Konfiguration
 */

// .env Datei laden (falls vorhanden)
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        // Kommentare ignorieren
        if (strpos(trim($line), '#') === 0) continue;
        
        // KEY=VALUE parsen
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            // Anführungszeichen entfernen
            $value = trim($value, '"\'');
            $_ENV[$key] = $value;
            putenv("$key=$value");
        }
    }
}

// Datenbank-Verbindung aus Umgebungsvariablen
define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'volkicheck');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');

// Session-Einstellungen
define('SESSION_LIFETIME', 86400 * 7);  // 7 Tage

// Score-Mapping
define('SCORE_MAP', [
    'sehr_wichtig' => 3,
    'wichtig' => 2,
    'egal' => 1,
    'unwichtig' => 0
]);

// Dimensionen mit ihren Fragen-IDs (kuratierte Auswahl)
define('DIMENSIONS', [
    'klima' => [42, 38, 41, 37, 44, 83, 82],           // Umwelt + Landwirtschaft
    'quartier' => [11, 10, 17, 99, 63],                // Wohnen + Ortsentwicklung
    'familie' => [21, 18, 22, 52, 55, 57, 81, 70],     // Bildung + Soziales + Generationen + Sicherheit
    'mobilitaet' => [109, 2, 3],                       // Verkehr
    'demokratie' => [32, 30, 72, 71, 92, 77, 91]       // Wirtschaft + Finanzen + Politik + Digital
]);

// Persönlichkeitstypen
define('PERSONALITY_TYPES', [
    'klima' => [
        'name_m' => 'Klima-Champion',
        'name_f' => 'Klima-Champion',
        'name_d' => 'Klima-Champion',
        'emoji' => '🌱',
        'description' => 'Du setzt dich für Klimaschutz, Biodiversität und nachhaltige Landwirtschaft ein. Grünräume, Bäume und regionale Produkte liegen dir am Herzen.',
        'color' => '#16A34A'
    ],
    'quartier' => [
        'name_m' => 'Quartier-Gestalter',
        'name_f' => 'Quartier-Gestalterin',
        'name_d' => 'Quartier-Gestalter*in',
        'emoji' => '🏘️',
        'description' => 'Dir liegt die Entwicklung lebenswerter Quartiere am Herzen. Bezahlbarer Wohnraum, schöne Plätze und ein lebendiges Zentrum sind deine Themen.',
        'color' => '#0891B2'
    ],
    'familie' => [
        'name_m' => 'Familien-Anwalt',
        'name_f' => 'Familien-Anwältin',
        'name_d' => 'Familien-Anwält*in',
        'emoji' => '👨‍👩‍👧',
        'description' => 'Kinder, Familien und ältere Menschen stehen bei dir im Mittelpunkt. Sichere Schulwege, Krippenplätze und gute Altersversorgung sind dir wichtig.',
        'color' => '#DB2777'
    ],
    'mobilitaet' => [
        'name_m' => 'Mobilitäts-Held',
        'name_f' => 'Mobilitäts-Heldin',
        'name_d' => 'Mobilitäts-Held*in',
        'emoji' => '🚴',
        'description' => 'Du willst Volketswil sicherer und nachhaltiger mobil machen. Velowege, besserer ÖV und Tempo-30-Zonen sind deine Prioritäten.',
        'color' => '#EA580C'
    ],
    'demokratie' => [
        'name_m' => 'Demokratie-Stärker',
        'name_f' => 'Demokratie-Stärkerin',
        'name_d' => 'Demokratie-Stärker*in',
        'emoji' => '🤝',
        'description' => 'Transparenz, Mitbestimmung und faire Finanzen sind dir wichtig. Du willst, dass alle mitreden können und Ressourcen gerecht verteilt werden.',
        'color' => '#7C3AED'
    ],
    'balanced' => [
        'name_m' => 'Ausgewogener Denker',
        'name_f' => 'Ausgewogene Denkerin',
        'name_d' => 'Ausgewogene*r Denker*in',
        'emoji' => '⚖️',
        'description' => 'Du wägst alle Themen sorgfältig ab und suchst ausgewogene Lösungen. Kein einzelnes Thema dominiert – du siehst das grosse Ganze.',
        'color' => '#64748B'
    ]
]);

// Low-Score Schwellenwert
define('LOW_SCORE_THRESHOLD', 1.2);

// Balanced-Type Schwellenwert (Standardabweichung)
define('BALANCED_THRESHOLD', 0.3);

// Datenbank-Verbindung herstellen
function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
                ]
            );
        } catch (PDOException $e) {
            http_response_code(500);
            die(json_encode(['error' => 'Database connection failed']));
        }
    }
    return $pdo;
}

// Session-ID generieren
function generateSessionId() {
    return bin2hex(random_bytes(32));
}

// IP hashen (Datenschutz)
function hashIP($ip) {
    return hash('sha256', $ip . 'volkicheck_salt_2024');
}
