# volkicheck 🏘️

Ein interaktives Umfrage-Tool im Tinder-Swipe-Stil für lokale Politik. Entwickelt für die Gemeinde Volketswil (ZH), aber einfach anpassbar für andere Gemeinden oder Themen.

## Was ist volkicheck?

volkicheck stellt 30 Fragen zu lokalen Themen wie Klima, Quartierentwicklung, Familie, Mobilität und Demokratie. Nutzer bewerten jede Aussage durch Swipen oder Tippen:

- ⬆️ **Sehr wichtig**
- ➡️ **Wichtig** 
- ⬇️ **Egal**
- ⬅️ **Unwichtig**

Am Ende erhalten sie einen "Persönlichkeitstyp" (z.B. Klima-Champion, Quartier-Gestalter) mit einem Radar-Chart ihrer Prioritäten und einem teilbaren Ergebnisbild.

## Features

- 📱 Mobile-first Design mit Swipe-Gesten
- 🎯 Gamification-Elemente (Achievements, Animationen)
- 📊 Radar-Chart Visualisierung
- 🖼️ Generiertes Share-Bild für Social Media
- 📈 Anonyme Statistik-Erfassung
- ↩️ Zurück-Funktion zum Korrigieren

## Installation

### Voraussetzungen

- PHP 7.4+ mit PDO MySQL
- MySQL/MariaDB
- Webserver (Apache/Nginx)

### Setup

1. **Dateien hochladen**
   ```bash
   git clone https://github.com/grandgrue/volkicheck.git
   cd volkicheck
   ```

2. **Datenbank einrichten**
   ```bash
   mysql -u root -p < database.sql
   ```

3. **Umgebungsvariablen konfigurieren**
   ```bash
   cp .env.example .env
   nano .env  # DB_USER und DB_PASS anpassen
   chmod 600 .env
   ```

4. **Webserver konfigurieren**
   
   Document Root auf den volkicheck-Ordner setzen oder als Subdomain/Unterordner einbinden.

## Anpassung für andere Gemeinden

1. **Fragen anpassen** in `database.sql`:
   - Ändere die `question_text` Felder
   - Passe die Dimensionen (`dimension`) an

2. **Persönlichkeitstypen anpassen** in `config.php`:
   - Namen, Emojis und Beschreibungen unter `PERSONALITY_TYPES`

3. **Branding anpassen** in `index.html`:
   - Suche nach "volkicheck" und "Volketswil"
   - Ersetze das Wappen (SVG in `VolketswilWappen` Komponente)

## Datenschutz

- Keine persönlichen Daten erforderlich
- IP-Adressen werden gehasht gespeichert
- Geschlecht wird nur für grammatikalische Anpassungen verwendet
- Alle Daten können anonymisiert exportiert werden

## Technologie

- Frontend: React (via CDN), Tailwind CSS
- Backend: PHP mit PDO
- Datenbank: MySQL
- Alles in einer einzigen HTML-Datei (kein Build-Prozess nötig)

## Lizenz

MIT License - frei verwendbar, auch für kommerzielle Zwecke.

## Autor

Ein Projekt von [Michael Grüebler](https://github.com/grandgrue) – [grue.ch](https://www.grue.ch)

---

*Gebaut mit Unterstützung von Claude (Anthropic)*
