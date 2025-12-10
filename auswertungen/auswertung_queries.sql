-- =====================================================
-- VOLKICHECK - Auswertungs-Queries für phpMyAdmin
-- =====================================================

-- =====================================================
-- 1. ZUSTIMMUNG PRO FRAGE (Ranking)
-- Zeigt welche Aussagen am meisten Zustimmung erhalten
-- =====================================================

SELECT 
    q.id,
    q.category,
    q.question_text,
    COUNT(r.id) AS anzahl_antworten,
    ROUND(AVG(
        CASE r.response 
            WHEN 'sehr_wichtig' THEN 3
            WHEN 'wichtig' THEN 2
            WHEN 'egal' THEN 1
            WHEN 'unwichtig' THEN 0
        END
    ), 2) AS durchschnitt_score,
    SUM(CASE WHEN r.response = 'sehr_wichtig' THEN 1 ELSE 0 END) AS sehr_wichtig,
    SUM(CASE WHEN r.response = 'wichtig' THEN 1 ELSE 0 END) AS wichtig,
    SUM(CASE WHEN r.response = 'egal' THEN 1 ELSE 0 END) AS egal,
    SUM(CASE WHEN r.response = 'unwichtig' THEN 1 ELSE 0 END) AS unwichtig,
    ROUND(
        (SUM(CASE WHEN r.response IN ('sehr_wichtig', 'wichtig') THEN 1 ELSE 0 END) / COUNT(r.id)) * 100
    , 1) AS zustimmung_prozent
FROM questions q
LEFT JOIN responses r ON q.id = r.question_id
GROUP BY q.id, q.category, q.question_text
ORDER BY durchschnitt_score DESC;


-- =====================================================
-- 2. TOP 10 - Höchste Zustimmung
-- =====================================================

SELECT 
    q.question_text,
    q.category,
    COUNT(r.id) AS antworten,
    ROUND(AVG(
        CASE r.response 
            WHEN 'sehr_wichtig' THEN 3
            WHEN 'wichtig' THEN 2
            WHEN 'egal' THEN 1
            WHEN 'unwichtig' THEN 0
        END
    ), 2) AS score,
    ROUND(
        (SUM(CASE WHEN r.response IN ('sehr_wichtig', 'wichtig') THEN 1 ELSE 0 END) / COUNT(r.id)) * 100
    , 1) AS zustimmung_pct
FROM questions q
LEFT JOIN responses r ON q.id = r.question_id
GROUP BY q.id
HAVING antworten > 0
ORDER BY score DESC
LIMIT 10;


-- =====================================================
-- 3. TOP 10 - Niedrigste Zustimmung (kontrovers)
-- =====================================================

SELECT 
    q.question_text,
    q.category,
    COUNT(r.id) AS antworten,
    ROUND(AVG(
        CASE r.response 
            WHEN 'sehr_wichtig' THEN 3
            WHEN 'wichtig' THEN 2
            WHEN 'egal' THEN 1
            WHEN 'unwichtig' THEN 0
        END
    ), 2) AS score,
    ROUND(
        (SUM(CASE WHEN r.response IN ('sehr_wichtig', 'wichtig') THEN 1 ELSE 0 END) / COUNT(r.id)) * 100
    , 1) AS zustimmung_pct
FROM questions q
LEFT JOIN responses r ON q.id = r.question_id
GROUP BY q.id
HAVING antworten > 0
ORDER BY score ASC
LIMIT 10;


-- =====================================================
-- 4. AUSWERTUNG PRO KATEGORIE/DIMENSION
-- =====================================================

SELECT 
    q.dimension,
    COUNT(DISTINCT r.session_id) AS teilnehmer,
    ROUND(AVG(
        CASE r.response 
            WHEN 'sehr_wichtig' THEN 3
            WHEN 'wichtig' THEN 2
            WHEN 'egal' THEN 1
            WHEN 'unwichtig' THEN 0
        END
    ), 2) AS durchschnitt_score
FROM questions q
LEFT JOIN responses r ON q.id = r.question_id
GROUP BY q.dimension
ORDER BY durchschnitt_score DESC;


-- =====================================================
-- 5. VERTEILUNG DER ANTWORTEN (Gesamt)
-- =====================================================

SELECT 
    response,
    COUNT(*) AS anzahl,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM responses), 1) AS prozent
FROM responses
GROUP BY response
ORDER BY FIELD(response, 'sehr_wichtig', 'wichtig', 'egal', 'unwichtig');


-- =====================================================
-- 6. PERSÖNLICHKEITSTYPEN - Verteilung
-- =====================================================

SELECT 
    personality_type,
    COUNT(*) AS anzahl,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM participants WHERE completed_at IS NOT NULL), 1) AS prozent
FROM participants
WHERE completed_at IS NOT NULL
GROUP BY personality_type
ORDER BY anzahl DESC;


-- =====================================================
-- 7. TEILNEHMER-STATISTIK
-- =====================================================

SELECT 
    COUNT(*) AS gesamt_gestartet,
    SUM(CASE WHEN completed_at IS NOT NULL THEN 1 ELSE 0 END) AS abgeschlossen,
    ROUND(SUM(CASE WHEN completed_at IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS abschlussrate_pct,
    SUM(CASE WHEN lives_in_volketswil = 1 THEN 1 ELSE 0 END) AS aus_volketswil,
    SUM(CASE WHEN lives_in_volketswil = 0 THEN 1 ELSE 0 END) AS auswaertig
FROM participants;


-- =====================================================
-- 8. GESCHLECHTERVERTEILUNG
-- =====================================================

SELECT 
    gender,
    COUNT(*) AS anzahl,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM participants WHERE completed_at IS NOT NULL), 1) AS prozent
FROM participants
WHERE completed_at IS NOT NULL
GROUP BY gender;


-- =====================================================
-- 9. ZEITLICHER VERLAUF (Teilnahmen pro Tag)
-- =====================================================

SELECT 
    DATE(created_at) AS datum,
    COUNT(*) AS neue_teilnehmer,
    SUM(CASE WHEN completed_at IS NOT NULL THEN 1 ELSE 0 END) AS abgeschlossen
FROM participants
GROUP BY DATE(created_at)
ORDER BY datum DESC;


-- =====================================================
-- 10. NUR VOLKETSWILER - Zustimmung pro Frage
-- =====================================================

SELECT 
    q.question_text,
    COUNT(r.id) AS antworten,
    ROUND(AVG(
        CASE r.response 
            WHEN 'sehr_wichtig' THEN 3
            WHEN 'wichtig' THEN 2
            WHEN 'egal' THEN 1
            WHEN 'unwichtig' THEN 0
        END
    ), 2) AS score
FROM questions q
JOIN responses r ON q.id = r.question_id
JOIN participants p ON r.session_id = p.session_id
WHERE p.lives_in_volketswil = 1
GROUP BY q.id
ORDER BY score DESC;
