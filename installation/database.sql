-- =====================================================
-- VOLKICHECK Datenbank-Schema
-- Neues Projekt mit kuratierten links-grünen Fragen
-- =====================================================

CREATE DATABASE IF NOT EXISTS volkicheck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE volkicheck;

-- -----------------------------------------------------
-- Tabelle: questions (30 kuratierte links-grüne Fragen)
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
    lives_in_volketswil BOOLEAN DEFAULT NULL,
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
-- KURATIERTE FRAGEN (30 links-grüne Fragen)
-- =====================================================

INSERT INTO questions (id, category, dimension, question_text, pilot_score, sort_order) VALUES

-- 🌱 UMWELT & KLIMA (5 Fragen) - Dimension: klima
(42, 'Natur, Umwelt & Energie', 'klima', 'Volketswil braucht eine Klimastrategie mit klaren, festen Zielen und Massnahmen.', 2.50, 1),
(38, 'Natur, Umwelt & Energie', 'klima', 'Volketswil braucht mehr Naturschutzflächen und verbundene Grünräume für Tiere und Pflanzen.', 2.71, 2),
(41, 'Natur, Umwelt & Energie', 'klima', 'Volketswil sollte mehr Bäume pflanzen und den bestehenden Baumbestand konsequent schützen.', 2.50, 3),
(37, 'Natur, Umwelt & Energie', 'klima', 'Volketswil sollte eine Solarpflicht für Neubauten und Sanierungen einführen.', 2.14, 4),
(44, 'Natur, Umwelt & Energie', 'klima', 'Volketswil sollte weniger zubetonieren und mehr Asphalt wieder zu Grünflächen machen.', 2.43, 5),

-- 🌾 LANDWIRTSCHAFT (2 Fragen) - Dimension: klima
(83, 'Landwirtschaft & Landschaft', 'klima', 'Volketswil sollte Bio-Bauernhöfe und Produkte aus der Region aktiv fördern.', 2.79, 6),
(82, 'Landwirtschaft & Landschaft', 'klima', 'Volketswil sollte landwirtschaftliche Flächen vor Überbauung schützen.', 2.21, 7),

-- 🏘️ WOHNEN & SIEDLUNG (3 Fragen) - Dimension: quartier
(11, 'Wohnen & Siedlungsentwicklung', 'quartier', 'Beim Verdichten sollte Volketswil den Erhalt von Grünräumen und Bäumen priorisieren.', 2.50, 8),
(10, 'Wohnen & Siedlungsentwicklung', 'quartier', 'Volketswil sollte aktiv günstige Wohnungen für Familien und Menschen mit wenig Geld schaffen.', 1.93, 9),
(17, 'Wohnen & Siedlungsentwicklung', 'quartier', 'Volketswil sollte das Ortsbild schützen und gegen langweilige Einheitsbauten vorgehen.', 1.93, 10),

-- 🏛️ ORTSENTWICKLUNG (2 Fragen) - Dimension: quartier
(99, 'Zentrum & Ortsteile', 'quartier', 'Volketswil braucht einen attraktiven lebendigen Kern mit gleichzeitigem Erhalt der ländlichen Dorfteile.', 2.38, 11),
(63, 'Zentrum & Ortsteile', 'quartier', 'Volketswil sollte öffentliche Plätze einladender und lebendiger gestalten.', 2.00, 12),

-- 🚴 VERKEHR & MOBILITÄT (3 Fragen) - Dimension: mobilitaet
(109, 'Verkehr & Mobilität', 'mobilitaet', 'Volketswil braucht mehr Tempo-30-Zonen zum Schutz von Kindern und Anwohnenden.', 2.43, 13),
(2, 'Verkehr & Mobilität', 'mobilitaet', 'Volketswil sollte das Velowegnetz deutlich ausbauen und sicherer machen.', 2.21, 14),
(3, 'Verkehr & Mobilität', 'mobilitaet', 'Volketswil braucht mehr und bessere ÖV-Verbindungen mit höheren Taktfrequenzen.', 1.71, 15),

-- 👨‍👩‍👧 BILDUNG & KINDERBETREUUNG (3 Fragen) - Dimension: familie
(21, 'Bildung & Kinderbetreuung', 'familie', 'Volketswil sollte alle Schulwege konsequent sicherer machen.', 2.21, 16),
(18, 'Bildung & Kinderbetreuung', 'familie', 'Volketswil braucht mehr günstige Krippenplätze für alle Einkommensschichten.', 2.00, 17),
(22, 'Bildung & Kinderbetreuung', 'familie', 'Volketswil braucht mehr naturnahe Spiel- und Freiräume für Kinder.', 1.93, 18),

-- ❤️ GESUNDHEIT & SOZIALES (3 Fragen) - Dimension: familie
(52, 'Gesundheit & Soziales', 'familie', 'Volketswil sollte mehr investieren, damit Zugezogene sich einleben können und Deutsch lernen.', 2.36, 19),
(55, 'Gesundheit & Soziales', 'familie', 'Volketswil sollte die Pflege zu Hause (Spitex) sicherstellen und unterstützen.', 2.21, 20),
(57, 'Gesundheit & Soziales', 'familie', 'Die Gemeinde braucht kleinere, bezahlbare Alterswohnungen in allen Ortsteilen.', 2.21, 21),

-- 👴 GENERATIONEN (1 Frage) - Dimension: familie
(81, 'Generationen', 'familie', 'Volketswil sollte Programme gegen Einsamkeit im Alter auflegen.', 2.07, 22),

-- 💼 WIRTSCHAFT & ARBEIT (2 Fragen) - Dimension: demokratie
(32, 'Wirtschaft & Arbeit', 'demokratie', 'In Volketswil sollten Wohnen und Lebensqualität gleich wichtig sein wie neue Arbeitsplätze.', 2.57, 23),
(30, 'Wirtschaft & Arbeit', 'demokratie', 'Volketswil sollte beim Einkaufen konsequent auf faire und umweltfreundliche Produkte achten.', 2.07, 24),

-- 💰 FINANZEN & STEUERN (2 Fragen) - Dimension: demokratie
(72, 'Finanzen & Steuern', 'demokratie', 'Bei Sparmassnahmen sollte Volketswil soziale Leistungen und Bildung verschonen.', 2.29, 25),
(71, 'Finanzen & Steuern', 'demokratie', 'Volketswil sollte lieber in Soziales und Umwelt investieren als Steuern zu senken.', 2.14, 26),

-- 🤝 DEMOKRATIE & POLITIK (2 Fragen) - Dimension: demokratie
(92, 'Demokratie & Politik', 'demokratie', 'Volketswil braucht ein Parlament zur besseren demokratischen Vertretung bei fast 20''000 Einwohnenden.', 2.57, 27),
(77, 'Demokratie & Politik', 'demokratie', 'Volketswil sollte Informationen auch in einfacher Sprache und mehrsprachig bereitstellen.', 2.29, 28),

-- 💻 DIGITALISIERUNG (1 Frage) - Dimension: demokratie
(91, 'Digitalisierung', 'demokratie', 'Volketswil sollte Künstliche Intelligenz (KI) in der Verwaltung offen und verantwortungsvoll einsetzen.', 2.36, 29),

-- 🛡️ SICHERHEIT (1 Frage) - Dimension: familie
(70, 'Sicherheit', 'familie', 'Volketswil sollte Littering mit Mehrwegsystemen und mehr Abfalleimern bekämpfen.', 2.21, 30);

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
