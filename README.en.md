# Zettlr rfdoc Export

> Zettlr as a live view in the layout of [real-fast-document](https://github.com/jcmx9/real-fast-document): editor theme, snippets and PDF export through rf-document.

[![CI](https://github.com/jcmx9/zettlr_rfdoc-Export/actions/workflows/ci.yml/badge.svg)](https://github.com/jcmx9/zettlr_rfdoc-Export/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Version 26.10.25** ([CalVer](https://calver.org/)) · English · [Deutsch](README.md)

Write meeting notes live in Zettlr and create the client PDF with **File → Export → rf-doc**. The PDF is built by [real-fast-document](https://github.com/jcmx9/real-fast-document) (rf-document): layout, fonts, alerts, task tables and PDF/A come from there. This project takes care of three things on the Zettlr side:

1. **Live layout:** the editor looks like rf-document's PDF – same fonts (rf-document's own files), size ratios, weights, colors, alerts, tables and quotes.
2. **Snippets** for meetings, phone calls, tasks and page breaks; `:header` inserts every front matter key of rf-document.
3. **Export** to rf-document.

## Requirement

[real-fast-document](https://github.com/jcmx9/real-fast-document#installation) is installed (`rf-document` as a command). Zettlr already ships Pandoc.

## Install and update

One line per system. Run the same line again to update.

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.sh | bash
```

**Windows** (PowerShell, no admin rights needed)

```powershell
irm https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.ps1 | iex
```

The installer downloads the latest release (SHA-256 verified), looks for rf-document and sets up the editor theme, the export profile **rf-doc** and the snippets in Zettlr. It takes the theme's fonts from the rf-document installation, so run it again after updating rf-document. Your own rules in Zettlr's `custom.css` are kept and backed up before every change; so are snippets you changed.

| | macOS | Linux | Windows |
| --- | --- | --- | --- |
| Installer files | `~/.local/share/zettlr-rfdoc-export` | `~/.local/share/zettlr-rfdoc-export` | `%LOCALAPPDATA%\zettlr-rfdoc-export` |
| Zettlr | `~/Library/Application Support/zettlr` | `~/.config/zettlr` | `%APPDATA%\zettlr` |

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.sh | bash -s -- --uninstall
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.ps1))) -Uninstall
```

## Usage in Zettlr

1. Restart Zettlr after installing.
2. New note from a snippet: type its name and press Enter; Tab jumps from field to field, date and time are filled in automatically.
   - `:meeting` – meeting: client and topic (as title), then participants, agenda, notes, tasks
   - `:telefonnotiz` – phone call: company, person (in the title), time, phone, reason, notes, tasks
   - Both set `hard_breaks: true` (every line stays a line, as in the editor) and `embed_source: false` (no note inside the client PDF)
   - `:aufgabe` – one task line `- [ ] Task – Name, bis Date` with three tab stops
   - `:newpage` – page break in the PDF (`<!-- pagebreak -->`)
   - `:header` – every front matter key of rf-document with its default, one line each with a short comment; every value is a tab stop (Tab jumps from value to value), the date is today. CI checks that the keys match rf-document's `header.md`
3. Export: **File → Export…** (<kbd>Cmd</kbd>/<kbd>Ctrl</kbd> + <kbd>E</kbd>), profile **rf-doc**.

What the PDF supports (front matter, alerts, task tables, images, diagrams, …) is described in the [real-fast-document README](https://github.com/jcmx9/real-fast-document#readme).

### Editor theme

The theme (`rfdoc-zettlr.css`) takes its values from rf-document's `template.typ`: body text in Source Sans with old-style figures and justification, headings in Source Serif (`#` 1.4× with a hairline, `##` 1.2×, `###` underlined, italic from `####`), alerts in rf-document's colors, code on light grey, striped tables. The editor uses the nominal weights (400/500/600) – rf-document sets the PDF slightly lower because PDF viewers draw heavier, so both look the same. It works with every built-in Zettlr theme; light and dark follow Zettlr's dark mode.

Two things the editor cannot mirror: lists made only of tasks stay lists in the editor (in the PDF they become a table), and alerts with German keywords (`> [!HINWEIS]`) show as quotes in Zettlr – in the PDF both spellings look the same.

## How the export works

Zettlr always exports through Pandoc. The **rf-doc** profile uses Pandoc only as a messenger: a Lua filter (`zettlr/rf-document.lua`) runs `rf-document <note.md> <target.pdf>` and ends Pandoc with its result before Pandoc writes anything itself.

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
./install.sh --bundle dist/zettlr-rfdoc-export.tar.gz
```

CI checks the scripts, installs on Ubuntu, macOS and Windows (PowerShell 5.1) and tests the messenger with Zettlr's Pandoc version.

## Project Structure

```
install.sh, install.ps1        – Installers (macOS/Linux, Windows)
zettlr/rf-doc.yaml.in      – Export profile template
zettlr/rf-document.lua         – Messenger: hands the note to rf-document
zettlr/rfdoc-zettlr.css        – Editor theme in rf-document's layout
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
