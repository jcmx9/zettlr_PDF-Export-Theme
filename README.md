# Zettlr rfdoc Export

> Zettlr als Live-Ansicht im Layout von [real-fast-document](https://github.com/jcmx9/real-fast-document): Editor-Theme, Snippets und PDF-Export über rf-document.

[![CI](https://github.com/jcmx9/zettlr_rfdoc-Export/actions/workflows/ci.yml/badge.svg)](https://github.com/jcmx9/zettlr_rfdoc-Export/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Version 26.10.24** ([CalVer](https://calver.org/)) · Deutsch · [English](README.en.md)

Besprechungsnotizen live in Zettlr schreiben und mit **Datei → Exportieren → rf-doc** als PDF für den Kunden erzeugen. Das PDF baut [real-fast-document](https://github.com/jcmx9/real-fast-document) (rf-document): Layout, Schriften, Hinweisboxen, Aufgabentabellen und PDF/A kommen von dort. Dieses Projekt sorgt auf der Zettlr-Seite für drei Dinge:

1. **Live-Layout:** Der Editor sieht aus wie das PDF von rf-document – gleiche Schriften (rf-documents eigene Dateien), Größenverhältnisse, Strichstärken, Farben, Hinweisboxen, Tabellen und Zitate.
2. **Snippets** für Besprechungen, Telefonate, Aufgaben und Seitenumbrüche; `:header` setzt alle Front-Matter-Schlüssel von rf-document ein.
3. **Export** an rf-document.

## Voraussetzung

[real-fast-document](https://github.com/jcmx9/real-fast-document#installation) ist installiert (`rf-document` als Befehl). Zettlr bringt Pandoc bereits mit.

## Installieren und aktualisieren

Eine Zeile pro System. Dieselbe Zeile aktualisiert auch.

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.sh | bash
```

**Windows** (PowerShell, ohne Administratorrechte)

```powershell
irm https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.ps1 | iex
```

Der Installer lädt das neueste Release (mit SHA-256-Prüfung), sucht rf-document und richtet in Zettlr Editor-Theme, Exportprofil **rf-doc** und Snippets ein. Die Schriften des Themes übernimmt er aus der rf-document-Installation; deshalb nach einem Update von rf-document diesen Installer erneut ausführen. Eigene Regeln in Zettlrs `custom.css` bleiben erhalten, vor jeder Änderung wird eine Sicherung angelegt; Snippets, die du geändert hast, ebenso.

| | macOS | Linux | Windows |
| --- | --- | --- | --- |
| Installer-Dateien | `~/.local/share/zettlr-rfdoc-export` | `~/.local/share/zettlr-rfdoc-export` | `%LOCALAPPDATA%\zettlr-rfdoc-export` |
| Zettlr | `~/Library/Application Support/zettlr` | `~/.config/zettlr` | `%APPDATA%\zettlr` |

### Deinstallieren

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.sh | bash -s -- --uninstall
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.ps1))) -Uninstall
```

## Verwendung in Zettlr

1. Zettlr nach der Installation neu starten.
2. Neue Notiz aus einem Snippet: Name tippen und Enter drücken, Tab springt von Feld zu Feld, Datum und Uhrzeit werden automatisch eingesetzt.
   - `:meeting` – Besprechung: Kunde und Thema (als Titel), dann Teilnehmer, Agenda, Mitschrift, Aufgaben
   - `:telefonnotiz` – Telefonat: Firma, Gesprächspartner (im Titel), Uhrzeit, Telefon, Anlass, Notizen, Aufgaben
   - Beide setzen `hard_breaks: true` (jede Zeile bleibt eine Zeile, wie im Editor) und `embed_source: false` (keine Notiz im Kunden-PDF)
   - `:aufgabe` – eine Aufgabenzeile `- [ ] Aufgabe – Name, bis Datum` mit drei Tab-Stopps
   - `:newpage` – Seitenumbruch im PDF (`<!-- pagebreak -->`)
   - `:header` – alle Front-Matter-Schlüssel von rf-document mit Standardwert, je eine Zeile mit kurzem Kommentar; jedes Feld ist ein Tab-Stopp (Tab springt von Wert zu Wert), das Datum ist heute. Die CI prüft, dass es dieselben Schlüssel sind wie in rf-documents `header.md`
3. Export: **Datei → Exportieren…** (<kbd>Cmd</kbd>/<kbd>Strg</kbd> + <kbd>E</kbd>), Profil **rf-doc**.

Was im PDF möglich ist (Front Matter, Hinweisboxen, Aufgabentabellen, Bilder, Diagramme …), beschreibt die [README von real-fast-document](https://github.com/jcmx9/real-fast-document#readme).

### Editor-Theme

Das Theme (`rfdoc-zettlr.css`) übernimmt die Werte aus rf-documents `template.typ`: Fließtext in Source Sans mit Mediävalziffern und Blocksatz, Überschriften in Source Serif (`#` 1,4-fach mit Haarlinie, `##` 1,2-fach, `###` unterstrichen, ab `####` kursiv), Hinweisboxen in rf-documents Farben, Code auf hellgrauem Grund, Tabellen mit Streifen. Die Strichstärken sind im Editor die Nennwerte (400/500/600) – rf-document setzt das PDF bewusst leicht darunter, weil PDF-Viewer kräftiger zeichnen; so wirken beide gleich. Es wirkt mit jedem eingebauten Zettlr-Theme, hell und dunkel folgen Zettlrs Dunkelmodus.

Zwei Dinge kann der Editor nicht nachbilden: Reine Aufgabenlisten bleiben im Editor Listen (im PDF werden sie zur Tabelle), und Hinweisboxen mit deutschen Schlüsselwörtern (`> [!HINWEIS]`) zeigt Zettlr als Zitat – im PDF sind beide Schreibweisen gleich.

## So funktioniert der Export

Zettlr exportiert immer über Pandoc. Das Profil **rf-doc** nutzt Pandoc nur als Boten: Ein Lua-Filter (`zettlr/rf-document.lua`) ruft `rf-document <notiz.md> <ziel.pdf>` auf und beendet Pandoc mit dessen Ergebnis, bevor Pandoc selbst etwas schreibt.

- Das PDF landet dort, wo Zettlr es erwartet (*Einstellungen → Import und Export*).
- Bei ungespeicherten Änderungen übergibt Zettlr eine temporäre Kopie. Der Filter setzt `RFD_BASE_DIR` auf den Ordner der Notiz, damit relative Bildpfade stimmen.
- `RFD_NO_OPEN=1` verhindert, dass rf-document das PDF zusätzlich öffnet.
- Fehlt rf-document oder schlägt der Export fehl, zeigt Zettlr die Meldung von rf-document.
- rf-document wird gesucht: zuerst der vom Installer eingetragene Pfad, dann `RF_DOCUMENT`, `~/.local/bin`, Homebrew, `%LOCALAPPDATA%\Microsoft\WindowsApps` und `PATH`.

## Entwicklung

```bash
shellcheck install.sh scripts/*.sh

# Bote testen: Pandoc mit dem Profil, ein Platzhalter statt rf-document
# (plus ein echter Durchlauf, wenn rf-document installiert ist)
./scripts/test_messenger.sh

# Release-Bundle bauen und lokal installieren
./scripts/package.sh
./install.sh --bundle dist/zettlr-rfdoc-export.tar.gz
```

Die CI prüft die Skripte, installiert unter Ubuntu, macOS und Windows (PowerShell 5.1) und testet den Boten mit Zettlrs Pandoc-Version.

## Projektstruktur

```
install.sh, install.ps1        – Installer (macOS/Linux, Windows)
zettlr/rf-doc.yaml.in      – Vorlage des Exportprofils
zettlr/rf-document.lua         – Bote: übergibt die Notiz an rf-document
zettlr/rfdoc-zettlr.css        – Editor-Theme im Layout von rf-document
zettlr/snippets/               – Zettlr-Snippets
scripts/                       – Bundle-Bau, Test des Boten
VERSION                        – Release-Version (CalVer)
README.md, README.en.md        – Dokumentation (Deutsch, Englisch)
```

## Versionierung

[CalVer](https://calver.org/) im Format `YY.M.MICRO` (Jahr, Monat, laufende Nummer im Monat), gespeichert in `VERSION` und oben in beiden READMEs angegeben; die CI prüft, dass sie übereinstimmen. Ein Tag `v<Version>` baut das Bundle und erstellt ein GitHub-Release; die Installer holen immer das neueste Release.

## Mitarbeit, Sicherheit, Änderungen

- Ablauf und Prüfungen: [CONTRIBUTING.md](CONTRIBUTING.md)
- Sicherheitslücken melden: [SECURITY.md](SECURITY.md)
- Änderungen je Version: [CHANGELOG.md](CHANGELOG.md)

## Lizenz

MIT – siehe [LICENSE](LICENSE).
