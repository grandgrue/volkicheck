<?php
/**
 * VOLKICHECK - API Endpunkt
 * 
 * Endpoints:
 * GET  ?action=questions     - Alle Fragen laden
 * GET  ?action=start         - Neue Session starten
 * POST ?action=respond       - Antwort speichern
 * POST ?action=complete      - Umfrage abschliessen (mit Geschlecht)
 * GET  ?action=result&sid=X  - Ergebnis abrufen
 * GET  ?action=stats         - Statistiken für Vergleich
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'config.php';

$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'questions':
            echo json_encode(getQuestions());
            break;
            
        case 'start':
            echo json_encode(startSession());
            break;
            
        case 'respond':
            $input = json_decode(file_get_contents('php://input'), true);
            echo json_encode(saveResponse($input));
            break;
            
        case 'complete':
            $input = json_decode(file_get_contents('php://input'), true);
            echo json_encode(completeSession($input));
            break;
            
        case 'result':
            $sessionId = $_GET['sid'] ?? '';
            echo json_encode(getResult($sessionId));
            break;
            
        case 'stats':
            echo json_encode(getStats());
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['error' => 'Unknown action']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

// =====================================================
// API Funktionen
// =====================================================

function getQuestions() {
    $db = getDB();
    $stmt = $db->query('
        SELECT id, category, dimension, question_text 
        FROM questions 
        WHERE active = TRUE 
        ORDER BY sort_order
    ');
    return ['questions' => $stmt->fetchAll()];
}

function startSession() {
    $db = getDB();
    $sessionId = generateSessionId();
    
    $stmt = $db->prepare('
        INSERT INTO participants (session_id, ip_hash, user_agent) 
        VALUES (?, ?, ?)
    ');
    $stmt->execute([
        $sessionId,
        hashIP($_SERVER['REMOTE_ADDR'] ?? ''),
        $_SERVER['HTTP_USER_AGENT'] ?? ''
    ]);
    
    return [
        'session_id' => $sessionId,
        'participant_id' => $db->lastInsertId()
    ];
}

function saveResponse($input) {
    $db = getDB();
    
    $sessionId = $input['session_id'] ?? '';
    $questionId = $input['question_id'] ?? 0;
    $response = $input['response'] ?? '';
    
    // Validierung
    if (!$sessionId || !$questionId || !in_array($response, ['sehr_wichtig', 'wichtig', 'egal', 'unwichtig'])) {
        throw new Exception('Invalid input');
    }
    
    // Participant ID holen
    $stmt = $db->prepare('SELECT id FROM participants WHERE session_id = ?');
    $stmt->execute([$sessionId]);
    $participant = $stmt->fetch();
    
    if (!$participant) {
        throw new Exception('Session not found');
    }
    
    // Antwort speichern (UPSERT)
    $stmt = $db->prepare('
        INSERT INTO responses (participant_id, question_id, response) 
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE response = VALUES(response), responded_at = CURRENT_TIMESTAMP
    ');
    $stmt->execute([$participant['id'], $questionId, $response]);
    
    return ['success' => true];
}

function completeSession($input) {
    $db = getDB();
    
    $sessionId = $input['session_id'] ?? '';
    $gender = $input['gender'] ?? 'd';
    
    if (!in_array($gender, ['m', 'f', 'd'])) {
        $gender = 'd';
    }
    
    // Participant holen
    $stmt = $db->prepare('SELECT id FROM participants WHERE session_id = ?');
    $stmt->execute([$sessionId]);
    $participant = $stmt->fetch();
    
    if (!$participant) {
        throw new Exception('Session not found');
    }
    
    $participantId = $participant['id'];
    
    // Alle Antworten holen
    $stmt = $db->prepare('
        SELECT q.dimension, r.response
        FROM responses r
        JOIN questions q ON r.question_id = q.id
        WHERE r.participant_id = ?
    ');
    $stmt->execute([$participantId]);
    $responses = $stmt->fetchAll();
    
    // Dimension Scores berechnen
    $dimensionTotals = [];
    $dimensionCounts = [];
    $totalScore = 0;
    $totalCount = 0;
    
    foreach ($responses as $r) {
        $dim = $r['dimension'];
        $score = SCORE_MAP[$r['response']];
        
        if (!isset($dimensionTotals[$dim])) {
            $dimensionTotals[$dim] = 0;
            $dimensionCounts[$dim] = 0;
        }
        
        $dimensionTotals[$dim] += $score;
        $dimensionCounts[$dim]++;
        $totalScore += $score;
        $totalCount++;
    }
    
    // Durchschnitte berechnen
    $dimensionScores = [];
    foreach ($dimensionTotals as $dim => $total) {
        $dimensionScores[$dim] = $total / $dimensionCounts[$dim];
    }
    
    $avgScore = $totalCount > 0 ? $totalScore / $totalCount : 0;
    $isLowScore = $avgScore < LOW_SCORE_THRESHOLD;
    
    // Typ bestimmen
    $personalityType = determinePersonalityType($dimensionScores);
    
    // Dimension Scores speichern
    $stmt = $db->prepare('
        INSERT INTO dimension_scores (participant_id, dimension, score) 
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE score = VALUES(score)
    ');
    foreach ($dimensionScores as $dim => $score) {
        $stmt->execute([$participantId, $dim, $score]);
    }
    
    // Participant aktualisieren
    $stmt = $db->prepare('
        UPDATE participants 
        SET gender = ?, personality_type = ?, avg_score = ?, is_low_score = ?, completed_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ');
    $stmt->execute([$gender, $personalityType, $avgScore, $isLowScore ? 1 : 0, $participantId]);
    
    return [
        'success' => true,
        'personality_type' => $personalityType,
        'dimension_scores' => $dimensionScores,
        'avg_score' => $avgScore,
        'is_low_score' => $isLowScore
    ];
}

function determinePersonalityType($dimensionScores) {
    // Standardabweichung berechnen
    $values = array_values($dimensionScores);
    $mean = array_sum($values) / count($values);
    $variance = array_sum(array_map(function($x) use ($mean) {
        return pow($x - $mean, 2);
    }, $values)) / count($values);
    $stdDev = sqrt($variance);
    
    // Wenn sehr ausgeglichen → balanced
    if ($stdDev < BALANCED_THRESHOLD) {
        return 'balanced';
    }
    
    // Höchste Dimension finden
    $maxDim = null;
    $maxScore = -1;
    foreach ($dimensionScores as $dim => $score) {
        if ($score > $maxScore) {
            $maxScore = $score;
            $maxDim = $dim;
        }
    }
    
    return $maxDim;
}

function getResult($sessionId) {
    $db = getDB();
    
    // Participant holen
    $stmt = $db->prepare('
        SELECT id, gender, personality_type, avg_score, is_low_score, completed_at
        FROM participants 
        WHERE session_id = ?
    ');
    $stmt->execute([$sessionId]);
    $participant = $stmt->fetch();
    
    if (!$participant || !$participant['completed_at']) {
        throw new Exception('Result not found or not completed');
    }
    
    // Dimension Scores holen
    $stmt = $db->prepare('
        SELECT dimension, score 
        FROM dimension_scores 
        WHERE participant_id = ?
    ');
    $stmt->execute([$participant['id']]);
    $dimensionScores = [];
    foreach ($stmt->fetchAll() as $row) {
        $dimensionScores[$row['dimension']] = floatval($row['score']);
    }
    
    // Vergleichsprozent berechnen
    $comparePercent = calculateComparePercent($participant['personality_type']);
    
    // Typ-Infos
    $typeInfo = PERSONALITY_TYPES[$participant['personality_type']] ?? PERSONALITY_TYPES['balanced'];
    $gender = $participant['gender'] ?? 'd';
    $nameKey = 'name_' . $gender;
    
    return [
        'personality_type' => $participant['personality_type'],
        'type_name' => $typeInfo[$nameKey],
        'type_emoji' => $typeInfo['emoji'],
        'type_description' => $typeInfo['description'],
        'type_color' => $typeInfo['color'],
        'dimension_scores' => $dimensionScores,
        'avg_score' => floatval($participant['avg_score']),
        'is_low_score' => (bool)$participant['is_low_score'],
        'compare_percent' => $comparePercent,
        'gender' => $gender
    ];
}

function calculateComparePercent($personalityType) {
    $db = getDB();
    
    // Zähle wie viele den gleichen Typ haben
    $stmt = $db->prepare('
        SELECT 
            COUNT(*) as same_type,
            (SELECT COUNT(*) FROM participants WHERE completed_at IS NOT NULL) as total
        FROM participants 
        WHERE personality_type = ? AND completed_at IS NOT NULL
    ');
    $stmt->execute([$personalityType]);
    $result = $stmt->fetch();
    
    if ($result['total'] < 5) {
        // Zu wenig Daten, simulierten Wert zurückgeben
        return rand(65, 85);
    }
    
    return round(($result['same_type'] / $result['total']) * 100);
}

function getStats() {
    $db = getDB();
    
    // Gesamtstatistiken
    $stmt = $db->query('
        SELECT 
            COUNT(*) as total_participants,
            COUNT(CASE WHEN completed_at IS NOT NULL THEN 1 END) as completed,
            AVG(CASE WHEN completed_at IS NOT NULL THEN avg_score END) as avg_score
        FROM participants
    ');
    $overall = $stmt->fetch();
    
    // Typen-Verteilung
    $stmt = $db->query('
        SELECT personality_type, COUNT(*) as count
        FROM participants
        WHERE completed_at IS NOT NULL
        GROUP BY personality_type
        ORDER BY count DESC
    ');
    $typeDistribution = $stmt->fetchAll();
    
    return [
        'total_participants' => (int)$overall['total_participants'],
        'completed' => (int)$overall['completed'],
        'avg_score' => round(floatval($overall['avg_score']), 2),
        'type_distribution' => $typeDistribution
    ];
}
