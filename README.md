# Zettlr rfdoc Export

> PDF-Export aus Zettlr über [real-fast-document](https://github.com/jcmx9/real-fast-document) – dazu Snippets für Besprechungen, Telefonate und Aufgaben.

[![CI](https://github.com/jcmx9/zettlr_rfdoc-Export/actions/workflows/ci.yml/badge.svg)](https://github.com/jcmx9/zettlr_rfdoc-Export/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Version 26.10.21** ([CalVer](https://calver.org/)) · Deutsch · [English](README.en.md)

Besprechungsnotizen live in Zettlr schreiben und mit **Datei → Exportieren → rf-doc** als PDF für den Kunden erzeugen. Das PDF baut [real-fast-document](https://github.com/jcmx9/real-fast-document) (rf-document): Layout, Schriften, Hinweisboxen, Aufgabentabellen und PDF/A kommen von dort. Dieses Projekt verbindet Zettlr mit rf-document und bringt die Snippets mit.

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

Der Installer lädt das neueste Release (mit SHA-256-Prüfung), sucht rf-document und richtet in Zettlr das Exportprofil **rf-doc** und die Snippets ein. Snippets, die du geändert hast, werden vor dem Überschreiben gesichert.

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
   - `:aufgabe` – eine Aufgabenzeile `- [ ] Aufgabe – Name, bis Datum` mit drei Tab-Stopps
   - `:newpage` – Seitenumbruch im PDF (`<!-- pagebreak -->`)
   - `:header` – alle Felder des Front Matters mit Standardwert und Kommentar
3. Export: **Datei → Exportieren…** (<kbd>Cmd</kbd>/<kbd>Strg</kbd> + <kbd>E</kbd>), Profil **rf-doc**.

Was im PDF möglich ist (Front Matter, Hinweisboxen, Aufgabentabellen, Bilder, Diagramme …), beschreibt die [README von real-fast-document](https://github.com/jcmx9/real-fast-document#readme).

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
