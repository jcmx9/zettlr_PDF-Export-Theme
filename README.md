# Zettlr PDF Export Theme

> Saubere, kundentaugliche PDFs aus Zettlr-Notizen – dazu ein passendes Zettlr-Editor-Theme, gesetzt in Adobes Schriftfamilie Source.

[![CI](https://github.com/jcmx9/zettlr_PDF-Export-Theme/actions/workflows/ci.yml/badge.svg)](https://github.com/jcmx9/zettlr_PDF-Export-Theme/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Version 26.10.16** ([CalVer](https://calver.org/)) · Deutsch · [English](README.en.md)

Besprechungsnotizen live in Zettlr schreiben – Thema, Agenda, Teilnehmer, Mitschrift, Aufgaben – und mit einem Klick als ruhiges, typografisches A4-PDF exportieren. Alle Bausteine sind frei und quelloffen: Zettlr, Pandoc (in Zettlr enthalten) und [Typst](https://typst.app).

![Beispiel einer Besprechungsnotiz als PDF](docs/example-meeting.png)

| Element       | Schrift         |
| ------------- | --------------- |
| Überschriften | Source Serif 4  |
| Fließtext     | Source Sans 3   |
| Code          | Source Code Pro |
| Emoji         | Noto Emoji      |

Die Source-Schriften sind Adobes variable OTF-Fassungen; nur Mermaid-Diagramme nutzen die statische Source Sans 3 Regular, weil Typst SVG-Text ohne variable Strichstärken zeichnet. Emojis kommen aus der einfarbigen Noto Emoji und folgen deshalb im PDF und in Zettlr Textfarbe und Strichstärke. Alle Schriften liegen dem Theme bei; zur Laufzeit wird nichts aus dem Internet geladen.

## Installieren und aktualisieren

Eine Zeile pro System. Dieselbe Zeile aktualisiert auch.

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.sh | bash
```

**Windows** (PowerShell, ohne Administratorrechte)

```powershell
irm https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.ps1 | iex
```

Der Installer

1. lädt das neueste Release und prüft dessen SHA-256-Prüfsumme,
2. lädt bei Bedarf Typst in seinen eigenen Ordner (keine Systemänderungen),
3. richtet **Zettlr** ein: Editor-Theme, Exportprofil **Source PDF**, Snippets **meeting**, **telefonnotiz**, **aufgabe**, **newpage** und **header**. Snippets früherer Versionen werden beim Update entfernt, sofern du sie nicht geändert hast.

Eigene Regeln in Zettlrs `custom.css` bleiben erhalten; vor jeder Änderung wird eine Sicherung mit Zeitstempel angelegt.

| | macOS | Linux | Windows |
| --- | --- | --- | --- |
| Installer-Dateien | `~/.local/share/zettlr-pdf-export-theme` | `~/.local/share/zettlr-pdf-export-theme` | `%LOCALAPPDATA%\zettlr-pdf-export-theme` |
| Zettlr | `~/Library/Application Support/zettlr` | `~/.config/zettlr` | `%APPDATA%\zettlr` |

### Deinstallieren

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.sh | bash -s -- --uninstall
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.ps1))) -Uninstall
```

## Verwendung in Zettlr

1. Zettlr nach der Installation neu starten.
2. Neue Notiz aus einem Snippet: Name tippen und Enter drücken, Tab springt von Feld zu Feld, Datum und Uhrzeit werden automatisch eingesetzt.
   - `:meeting` – Besprechung: Kunde und Thema (als Titel), dann Teilnehmer, Agenda, Mitschrift, Aufgaben
   - `:telefonnotiz` – Telefonat: Firma, Gesprächspartner (im Titel), Uhrzeit, Telefon, Anlass, Notizen, Aufgaben
   - `:newpage` – Seitenumbruch im PDF (`<!-- pagebreak -->`)
   - `:aufgabe` – eine Aufgabenzeile `- [ ] Aufgabe – Name, bis Datum` mit drei Tab-Stopps
   - `:header` – alle Felder des Front Matters mit Standardwert und Kommentar; leere Felder werden beim Export ignoriert
3. Export: **Datei → Exportieren…** (<kbd>Cmd</kbd>/<kbd>Strg</kbd> + <kbd>E</kbd>), Profil **Source PDF**.

Wo das PDF gespeichert wird, legst du unter *Einstellungen → Import und Export* fest.

### Was das PDF kann

- **Titel und Überschriften:** Titel und Untertitel stehen im Front Matter (`title`, `subtitle`); `#`, `##`, … im Text sind echte Abschnittsüberschriften, beliebig oft. Titel mit Doppelpunkt in Anführungszeichen setzen: `title: "Relaunch: Kick-off"`. Ältere Notizen ohne `title:`, die mit `# Titel` beginnen, funktionieren weiter: Diese Überschrift wird zum Titel, die übrigen rücken eine Ebene hoch
- **Front Matter (optional):**
  - `title`, `subtitle`, `client`, `author`
  - `date` – steht unter dem Titel; ohne Angabe erscheint kein Datum
  - `logo` – Bild neben dem Titel (PNG, JPG oder SVG), Pfad wie bei Bildern (siehe unten). Es behält seine Proportionen und passt in 20 mm Höhe und 60 mm Breite
  - `logo-height` – maximale Logohöhe statt 20 mm, z. B. `logo-height: 15mm`
  - `lang: en` – englische Beschriftungen (Seite, Box- und Tabellentitel); Standard ist Deutsch
- **Zeilenumbrüche:** jeder Zeilenumbruch der Notiz bleibt erhalten
- **Aufgaben:** Eine Liste, die nur aus Aufgaben (`- [ ]` / `- [x]`) besteht, wird zur Tabelle *Aufgabe · Wer · Bis · Status*. Wer und Bis kommen aus `– Name, bis Datum`; Spalten, die überall leer wären, entfallen. In gemischten Listen ersetzt das Kästchen den Aufzählungspunkt:
  ```markdown
  - [ ] Sitemap-Entwurf erstellen – jcmx9, bis 17.10.
  - [x] Review-Termin festlegen – Anna Beispiel
  ```
- **Hinweisboxen:** `> [!NOTE]` (Info), `[!TIP]` (Tipp), `[!IMPORTANT]` (Wichtig), `[!WARNING]` (Hinweis, ruhiges Orange), `[!CAUTION]` (Achtung); deutsche Schlüsselwörter wie `> [!HINWEIS]` funktionieren ebenso
- **Bilder:** `![Bildunterschrift](bilder/screen.png){width=50%}` mit Unterschrift darunter. Pfade relativ zur Notiz oder absolut; `~`, `$USER`, `$HOME`, `${VAR}` und `%USERPROFILE%` werden ersetzt, z. B. `~/Bilder/logo.svg`. Unter Windows müssen absolute Pfade auf dem Laufwerk der Notiz liegen. Ein fehlendes Bild bricht den Export nicht ab, im PDF steht dann „[Bild fehlt: …]“
- **Diagramme:** ` ```mermaid `-Codeblöcke werden in den Farben des Themes gezeichnet (Flussdiagramme, Sequenzdiagramme, …), ohne Internet
- **Datumszeilen:** `18. Oktober 2026` am Zeilenanfang bleibt ein Datum; Markdown würde sonst eine Liste ab 18 daraus machen (gilt für alle Zeilen, die mit Zahl, Punkt und Monatsnamen beginnen)
- **Seitenumbrüche:** `\newpage` oder `<!-- pagebreak -->` auf einer eigenen Zeile
- **Lange Tabellen** laufen auf der nächsten Seite weiter und wiederholen dort ihre Kopfzeile
- **Text:** `==Markierung==`, Fußnoten, Code mit Syntaxfarben, Formeln, typografische Anführungszeichen, deutsche Silbentrennung, Emojis (einfarbig, in Textfarbe)
- **Fußzeile:** höchstens zwei Angaben aus Kunde, Titel und Untertitel in dieser Reihenfolge (z. B. „Kunde · Titel“, ohne Kunde „Titel · Untertitel“) und die Seitenzahl
- **PDF/A-2u:** das PDF erfüllt den Archivstandard. Bilder und Diagramme haben Alternativtexte; volle Barrierefreiheit nach PDF/UA wird nicht erzwungen, weil sonst alltägliche Notizen am Export scheitern würden (z. B. eine Notiz, die mit `###` beginnt)

### Editor-Theme

Das Editor-Theme wirkt mit jedem eingebauten Zettlr-Theme; die Einstellung *Darstellung → Editor-Theme* spielt keine Rolle mehr. Hell und dunkel folgen Zettlrs Dunkelmodus. Es setzt Schriften, Überschriftengrößen (dieselben Verhältnisse wie im PDF: Ebene 1 15/11, Ebene 2 13/11, ab Ebene 3 Fließtextgröße), Abstände und Farben. Um Zettlr ohne das Theme zu sehen, die erste Zeile der `custom.css` im *Assets Manager* von Zettlr auskommentieren.

Tags erscheinen samt `#` in der Akzentfarbe. Zettlr unterstützt keine Tag-Hierarchien: Bei Tags im Obsidian-Stil wie `#projekt/kunde` erkennt und färbt Zettlr nur `#projekt`; die Notiz selbst bleibt unverändert.

## Typografie

- Mediävalziffern im Fließtext und in Überschriften, Versalziffern in gleicher Breite in Tabellen, neutrale Ziffern im Code – im PDF und in Zettlr. Source Sans zeichnet ihre Mediävalziffern dezent, am deutlichsten sieht man sie in den Überschriften aus Source Serif
- Emojis sind einfarbig und folgen der Strichstärke des umgebenden Texts. Ausnahme in Zettlr: Emojis mit ausdrücklichem Farb-Selektor (z. B. ⚠️, ❤️) bleiben farbig, weil Chromium sie immer mit der farbigen Systemschrift zeichnet
- Alle Textfarben erfüllen den WCAG-AA-Kontrast, geprüft von `scripts/check_contrast.py`

## Entwicklung

```bash
# Prüfwerkzeuge
npm install
npm run lint:css
shellcheck install.sh scripts/*.sh
uvx ruff check scripts/

# Farbkontrast der Zettlr-Palette (WCAG AA)
python3 scripts/check_contrast.py

# Schriften neu laden (Adobe-Releases, Noto Emoji aus google/fonts)
uv run scripts/fetch_fonts.py

# Mitgelieferte Typst-Pakete neu laden (Mermaid-Renderer)
python3 scripts/fetch_packages.py

# Ende-zu-Ende-Test: tests/fixtures/*.md und alle Snippets so exportieren,
# wie Zettlr es tut (braucht pandoc, typst und pdftotext oder mutool)
./scripts/test_pdf.sh

# Release-Bundle bauen und lokal installieren
./scripts/package.sh
./install.sh --bundle dist/zettlr-pdf-export-theme.tar.gz

# PDF auf der Kommandozeile
pandoc note.md -f commonmark_x+hard_line_breaks+implicit_figures-smart-fancy_lists -t pdf --pdf-engine=typst \
  --pdf-engine-opt=--ignore-system-fonts --pdf-engine-opt=--font-path=typst/fonts \
  --pdf-engine-opt=--package-cache-path=typst/packages --pdf-engine-opt=--root=/ \
  --template=typst/source.typst --lua-filter=typst/source.lua -o note.pdf
```

Die CI prüft alles, führt den Installer unter Ubuntu, macOS und Windows (PowerShell 5.1) aus und exportiert die Testnotizen mit Zettlrs Pandoc-Version über das installierte Profil.

## Projektstruktur

```
install.sh, install.ps1   – Installer (macOS/Linux, Windows)
VERSION                   – Release-Version (CalVer)
typst/source.typst        – Pandoc-Vorlage für das PDF
typst/source.lua          – Pandoc-Filter (Titel, Hinweisboxen, Anführungszeichen, Bildpfade, Logo, Aufgabentabellen, Datumszeilen, Markierungen, Seitenumbrüche)
typst/fonts/              – Schriften für Typst (variable OTF, Noto Emoji, statische Regular für Diagramme)
typst/packages/           – Mitgelieferte Typst-Pakete (mmdr für Mermaid)
typst/example-meeting.md  – Beispiel einer Besprechungsnotiz
zettlr/                   – Zettlr-Editor-Theme, eingebettete Schriften, Vorlage des Exportprofils, Snippets
scripts/                  – Schrift- und Paket-Download, Kontrastprüfung, Bundle-Bau, PDF-Test
tests/fixtures/           – Testnotizen für den Ende-zu-Ende-Test
docs/                     – Bilder für die README
README.md, README.en.md   – Dokumentation (Deutsch, Englisch)
```

## Versionierung

[CalVer](https://calver.org/) im Format `YY.M.MICRO` (Jahr, Monat, laufende Nummer im Monat), gespeichert in `VERSION` und oben in beiden READMEs angegeben; die CI prüft, dass sie übereinstimmen. Ein Tag `v<Version>` baut das Bundle und erstellt ein GitHub-Release; die Installer holen immer das neueste Release.

## Mitarbeit, Sicherheit, Änderungen

- Ablauf und Prüfungen: [CONTRIBUTING.md](CONTRIBUTING.md)
- Sicherheitslücken melden: [SECURITY.md](SECURITY.md)
- Änderungen je Version: [CHANGELOG.md](CHANGELOG.md)

## Lizenz

Code und Theme: MIT – siehe [LICENSE](LICENSE).
Schriften: SIL Open Font License 1.1 – siehe `typst/fonts/OFL-*.txt`. Source ist eine Marke von Adobe; Noto ist eine Marke von Google.
mmdr (Mermaid-Renderer): MIT – siehe `typst/packages/preview/mmdr/0.2.2/LICENSE`.
