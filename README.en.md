# Zettlr PDF Export

> PDF export from Zettlr through [real-fast-document](https://github.com/jcmx9/real-fast-document) – plus snippets for meetings, phone calls and tasks.

[![CI](https://github.com/jcmx9/zettlr_PDF-Export-Theme/actions/workflows/ci.yml/badge.svg)](https://github.com/jcmx9/zettlr_PDF-Export-Theme/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Version 26.10.19** ([CalVer](https://calver.org/)) · English · [Deutsch](README.md)

Write meeting notes live in Zettlr and create the client PDF with **File → Export → Source PDF**. The PDF is built by [real-fast-document](https://github.com/jcmx9/real-fast-document) (rf-document): layout, fonts, alerts, task tables and PDF/A come from there. This project connects Zettlr to rf-document and ships the snippets.

## Requirement

[real-fast-document](https://github.com/jcmx9/real-fast-document#installation) is installed (`rf-document` as a command). Zettlr already ships Pandoc.

## Install and update

One line per system. Run the same line again to update.

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.sh | bash
```

**Windows** (PowerShell, no admin rights needed)

```powershell
irm https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.ps1 | iex
```

The installer downloads the latest release (SHA-256 verified), looks for rf-document and sets up the export profile **Source PDF** and the snippets in Zettlr. Snippets you changed are backed up before they are overwritten.

| | macOS | Linux | Windows |
| --- | --- | --- | --- |
| Installer files | `~/.local/share/zettlr-pdf-export-theme` | `~/.local/share/zettlr-pdf-export-theme` | `%LOCALAPPDATA%\zettlr-pdf-export-theme` |
| Zettlr | `~/Library/Application Support/zettlr` | `~/.config/zettlr` | `%APPDATA%\zettlr` |

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.sh | bash -s -- --uninstall
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.ps1))) -Uninstall
```

## Usage in Zettlr

1. Restart Zettlr after installing.
2. New note from a snippet: type its name and press Enter; Tab jumps from field to field, date and time are filled in automatically.
   - `:meeting` – meeting: client and topic (as title), then participants, agenda, notes, tasks
   - `:telefonnotiz` – phone call: company, person (in the title), time, phone, reason, notes, tasks
   - `:aufgabe` – one task line `- [ ] Task – Name, bis Date` with three tab stops
   - `:newpage` – page break in the PDF (`<!-- pagebreak -->`)
   - `:header` – every front matter field with a default and a comment
3. Export: **File → Export…** (<kbd>Cmd</kbd>/<kbd>Ctrl</kbd> + <kbd>E</kbd>), profile **Source PDF**.

What the PDF supports (front matter, alerts, task tables, images, diagrams, …) is described in the [real-fast-document README](https://github.com/jcmx9/real-fast-document#readme).

## How the export works

Zettlr always exports through Pandoc. The **Source PDF** profile uses Pandoc only as a messenger: a Lua filter (`zettlr/rf-document.lua`) runs `rf-document <note.md> <target.pdf>` and ends Pandoc with its result before Pandoc writes anything itself.

- The PDF ends up where Zettlr expects it (*Preferences → Import and Export*).
- With unsaved changes Zettlr passes a temporary copy. The filter sets `RFD_BASE_DIR` to the note's folder so relative image paths still work.
- `RFD_NO_OPEN=1` keeps rf-document from opening the PDF as well.
- If rf-document is missing or the export fails, Zettlr shows rf-document's message.
- rf-document is looked up in this order: the path the installer wrote, `RF_DOCUMENT`, `~/.local/bin`, Homebrew, `%LOCALAPPDATA%\Microsoft\WindowsApps` and `PATH`.

## Development

```bash
shellcheck install.sh scripts/*.sh

# Test the messenger: Pandoc with the profile, a stub instead of rf-document
# (plus a real run when rf-document is installed)
./scripts/test_messenger.sh

# Build the release bundle and install it locally
./scripts/package.sh
./install.sh --bundle dist/zettlr-pdf-export-theme.tar.gz
```

CI checks the scripts, installs on Ubuntu, macOS and Windows (PowerShell 5.1) and tests the messenger with Zettlr's Pandoc version.

## Project Structure

```
install.sh, install.ps1        – Installers (macOS/Linux, Windows)
zettlr/Source PDF.yaml.in      – Export profile template
zettlr/rf-document.lua         – Messenger: hands the note to rf-document
zettlr/snippets/               – Zettlr snippets
scripts/                       – Bundle build, messenger test
VERSION                        – Release version (CalVer)
README.md, README.en.md        – Documentation (German, English)
```

## Versioning

[CalVer](https://calver.org/) in the format `YY.M.MICRO` (year, month, running number within the month), stored in `VERSION` and shown at the top of both READMEs; CI checks that they match. Pushing a tag `v<version>` builds the bundle and creates a GitHub release; the installers always fetch the latest release.

## Contributing, security, changelog

- Workflow and checks: [CONTRIBUTING.md](CONTRIBUTING.md)
- Reporting vulnerabilities: [SECURITY.md](SECURITY.md)
- Changes per version: [CHANGELOG.md](CHANGELOG.md)

## License

MIT – see [LICENSE](LICENSE).
