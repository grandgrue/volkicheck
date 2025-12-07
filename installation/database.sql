-- =====================================================
-- VOLKICHECK Datenbank-Schema
-- Neues Projekt basierend auf Volkiswipe-Konzept
-- =====================================================

CREATE DATABASE IF NOT EXISTS volkicheck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE volkicheck;

-- -----------------------------------------------------
-- Tabelle: questions (30 kuratierte Fragen)
-- -----------------------------------------------------
CREATE TABLE questions (
    id INT PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    dimension VARCHAR(20) NOT NULL,
    question_text TEXT NOT NULL,
    pilot_score DECIMAL(3,2) DEFAULT NULL,
    sort_order INT DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- Tabelle: participants
-- -----------------------------------------------------
CREATE TABLE participants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL UNIQUE,
    gender ENUM('m', 'f', 'd') DEFAULT NULL,
    personality_type VARCHAR(20) DEFAULT NULL,
    avg_score DECIMAL(3,2) DEFAULT NULL,
    is_low_score BOOLEAN DEFAULT FALSE,
    ip_hash VARCHAR(64) DEFAULT NULL,
    user_agent TEXT DEFAULT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    
    INDEX idx_session (session_id),
    INDEX idx_personality (personality_type),
    INDEX idx_completed (completed_at)
);

-- -----------------------------------------------------
-- Tabelle: responses
-- -----------------------------------------------------
CREATE TABLE responses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    participant_id INT NOT NULL,
    question_id INT NOT NULL,
    response ENUM('sehr_wichtig', 'wichtig', 'egal', 'unwichtig') NOT NULL,
    responded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    UNIQUE KEY unique_response (participant_id, question_id)
);

-- -----------------------------------------------------
-- Tabelle: dimension_scores (berechnete Werte pro Teilnehmer)
-- -----------------------------------------------------
CREATE TABLE dimension_scores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    participant_id INT NOT NULL,
    dimension VARCHAR(20) NOT NULL,
    score DECIMAL(3,2) NOT NULL,
    
    FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE,
    UNIQUE KEY unique_dim_score (participant_id, dimension)
);

-- =====================================================
-- FRAGEN EINFÜGEN (30 kuratierte aus Pilot)
-- =====================================================

INSERT INTO questions (id, category, dimension, question_text, pilot_score, sort_order) VALUES

-- 🌱 Klima & Natur (Dimension: klima)
(42, 'Natur, Umwelt & Energie', 'klima', 'Volketswil soll eine Klimastrategie mit konkreten Massnahmen entwickeln.', 2.92, 1),
(38, 'Natur, Umwelt & Energie', 'klima', 'Die Gemeinde soll aktiv Grünflächen und Biodiversität fördern.', 2.85, 2),
(41, 'Natur, Umwelt & Energie', 'klima', 'Die Gemeinde soll erneuerbare Energien (z.B. Solar auf öffentlichen Gebäuden) ausbauen.', 2.77, 3),
(37, 'Natur, Umwelt & Energie', 'klima', 'Bestehende Bäume und Grünräume sollen besser geschützt werden.', 2.69, 4),
(44, 'Natur, Umwelt & Energie', 'klima', 'Volketswil soll umweltfreundliches Bauen und Sanieren stärker fördern.', 2.46, 5),

-- 🌾 Landwirtschaft (Dimension: klima)
(83, 'Landwirtschaft', 'klima', 'Die Gemeinde soll regionale und biologische Landwirtschaft unterstützen.', 2.46, 6),
(82, 'Landwirtschaft', 'klima', 'Landwirtschaftsland soll erhalten und vor Überbauung geschützt werden.', 2.31, 7),

-- 🏘️ Wohnen (Dimension: quartier)
(11, 'Wohnen & Raumplanung', 'quartier', 'Die Gemeinde soll sich für bezahlbaren Wohnraum einsetzen.', 2.46, 8),
(10, 'Wohnen & Raumplanung', 'quartier', 'Die Quartiere sollen lebendig und durchmischt bleiben (Altersdurchmischung, Gewerbe, Wohnen).', 2.38, 9),
(17, 'Wohnen & Raumplanung', 'quartier', 'Volketswil soll ein lebendiges Zentrum mit Begegnungsorten entwickeln.', 2.31, 10),

-- 🏛️ Ortsentwicklung (Dimension: quartier)
(99, 'Ortsentwicklung & Identität', 'quartier', 'Das Zentrum von Volketswil soll attraktiver werden.', 2.38, 11),
(63, 'Ortsentwicklung & Identität', 'quartier', 'Die verschiedenen Ortsteile (Volketswil, Kindhausen, Zimikon, etc.) sollen ihre eigene Identität behalten.', 2.00, 12),

-- 🚴 Mobilität (Dimension: mobilitaet)
(109, 'Verkehr & Mobilität', 'mobilitaet', 'Schulwege sollen sicherer werden (z.B. durch Tempo-30-Zonen, bessere Übergänge).', 2.77, 13),
(2, 'Verkehr & Mobilität', 'mobilitaet', 'Fuss- und Velowege in Volketswil sollen ausgebaut werden.', 2.62, 14),
(3, 'Verkehr & Mobilität', 'mobilitaet', 'Der öffentliche Verkehr soll verbessert werden (z.B. Buslinien, Taktfrequenz).', 2.54, 15),

-- 👨‍👩‍👧 Familie & Bildung (Dimension: familie)
(21, 'Familie & Bildung', 'familie', 'Das Angebot an Krippenplätzen und schulergänzender Betreuung soll ausgebaut werden.', 2.54, 16),
(18, 'Familie & Bildung', 'familie', 'Spielplätze und Freizeitangebote für Kinder und Jugendliche sollen ausgebaut werden.', 2.46, 17),
(22, 'Familie & Bildung', 'familie', 'Die Volksschule soll weiterhin hohe Priorität haben.', 2.46, 18),

-- ❤️ Soziales (Dimension: familie)
(52, 'Soziales & Gesundheit', 'familie', 'Die Gemeinde soll Angebote für ältere Menschen (z.B. Begegnungsorte, Unterstützung) ausbauen.', 2.38, 19),
(55, 'Soziales & Gesundheit', 'familie', 'Volketswil soll ein gutes Angebot an Gesundheitsdiensten (z.B. Spitex, Ärzte) sicherstellen.', 2.31, 20),
(57, 'Soziales & Gesundheit', 'familie', 'Sportangebote sollen für alle Altersgruppen zugänglich und bezahlbar sein.', 2.15, 21),
(81, 'Soziales & Gesundheit', 'familie', 'Die Gemeinde soll die Integration und ein gutes Zusammenleben aller Bevölkerungsgruppen aktiv fördern.', 2.08, 22),

-- 💼 Wirtschaft (Dimension: demokratie)
(32, 'Wirtschaft & Gewerbe', 'demokratie', 'Das lokale Gewerbe soll gestärkt werden (z.B. durch Veranstaltungen, weniger Bürokratie).', 2.31, 23),
(30, 'Wirtschaft & Gewerbe', 'demokratie', 'Volketswil soll ein attraktiver Standort für KMU und Gewerbe bleiben.', 2.15, 24),

-- 💰 Finanzen (Dimension: demokratie)
(72, 'Finanzen & Steuern', 'demokratie', 'Die Gemeinde soll nachhaltig wirtschaften und keine Schulden anhäufen.', 2.46, 25),
(71, 'Finanzen & Steuern', 'demokratie', 'Die Steuern sollen nicht erhöht werden.', 2.08, 26),

-- 🤝 Demokratie (Dimension: demokratie)
(92, 'Gemeindepolitik & Verwaltung', 'demokratie', 'Die Bevölkerung soll bei wichtigen Projekten frühzeitig einbezogen werden.', 2.54, 27),
(77, 'Gemeindepolitik & Verwaltung', 'demokratie', 'Die Gemeindeverwaltung soll bürgernah und serviceorientiert arbeiten.', 2.08, 28),

-- 💻 Digitalisierung (Dimension: demokratie)
(91, 'Gemeindepolitik & Verwaltung', 'demokratie', 'Die Gemeinde soll digitale Dienstleistungen (z.B. Online-Schalter) ausbauen.', 2.23, 29),

-- 🛡️ Sicherheit (Dimension: familie)
(70, 'Sicherheit', 'familie', 'Volketswil soll ein sicherer Wohnort bleiben.', 2.15, 30);

-- =====================================================
-- VIEW für Statistiken
-- =====================================================

CREATE VIEW participant_stats AS
SELECT 
    personality_type,
    gender,
    COUNT(*) as count,
    AVG(avg_score) as avg_score
FROM participants
WHERE completed_at IS NOT NULL
GROUP BY personality_type, gender;

-- View für Vergleichsprozent-Berechnung
CREATE VIEW type_percentages AS
SELECT 
    personality_type,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM participants WHERE completed_at IS NOT NULL), 0) as percentage
FROM participants
WHERE completed_at IS NOT NULL
GROUP BY personality_type;
