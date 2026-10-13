# Zettlr PDF Export Theme

> Clean, client-ready PDFs from Zettlr notes – plus a matching Zettlr editor theme, built on Adobe's Source type family.

[![CI](https://github.com/jcmx9/zettlr_PDF-Export-Theme/actions/workflows/ci.yml/badge.svg)](https://github.com/jcmx9/zettlr_PDF-Export-Theme/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Version 26.10.18** ([CalVer](https://calver.org/)) · English · [Deutsch](README.md)

Write meeting notes live in Zettlr – topic, agenda, participants, notes, tasks – and export them with one click as a calm, typographic A4 PDF. Everything involved is free and open source: Zettlr, Pandoc (ships with Zettlr) and [Typst](https://typst.app).

![Example meeting note as PDF](docs/example-meeting.png)

| Element     | Font            |
| ----------- | --------------- |
| Headings    | Source Serif 4  |
| Body        | Source Sans 3   |
| Code        | Source Code Pro |
| Emoji       | Noto Emoji      |

The Source fonts are Adobe's variable OTF builds; only Mermaid diagrams use the static Source Sans 3 Regular, because Typst draws SVG text without variable weights. Emoji use the monochrome Noto Emoji, so they follow the text color and weight in the PDF and in Zettlr. All fonts are bundled with the theme; nothing is loaded from the internet at runtime.

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

The installer

1. downloads the latest release and verifies its SHA-256 checksum,
2. downloads Typst into its own folder if needed (no system changes),
3. sets up **Zettlr**: editor theme, export profile **Source PDF**, snippets **meeting**, **telefonnotiz**, **aufgabe**, **newpage** and **header**. Snippets of earlier versions are removed on update unless you changed them.

Existing rules in Zettlr's `custom.css` are kept; a timestamped backup is written before every change.

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
   - `:newpage` – page break in the PDF (`<!-- pagebreak -->`)
   - `:aufgabe` – one task line `- [ ] Task – Name, bis Date` with three tab stops
   - `:header` – every front matter field with a default and a comment; empty fields are ignored on export
3. Export: **File → Export…** (<kbd>Cmd</kbd>/<kbd>Ctrl</kbd> + <kbd>E</kbd>), profile **Source PDF**.

Where the PDF is saved is set under *Preferences → Import and Export*.

### What the PDF supports

- **Title and headings:** title and subtitle live in the front matter (`title`, `subtitle`); `#`, `##`, … in the text are real section headings, as many as needed. Quote titles that contain a colon: `title: "Relaunch: Kick-off"`. Older notes without `title:` that start with `# Title` keep working: that heading becomes the title and the others move up one level
- **Front matter (optional):**
  - `title`, `subtitle`, `client`, `author`
  - `date` – shown below the title; without it no date appears
  - `logo` – image next to the title (PNG, JPG or SVG), path as for images (see below). It keeps its proportions and fits into 20 mm height and 60 mm width
  - `logo-height` – maximum logo height instead of 20 mm, e.g. `logo-height: 15mm`
  - `lang: en` – English labels (Page, alert and table titles); German is the default
- **Line breaks:** every line break in the note is kept
- **Tasks:** a list made only of tasks (`- [ ]` / `- [x]`) becomes a table *Aufgabe · Wer · Bis · Status*. Owner and due date come from `– Name, bis Date`; columns that would be empty everywhere are dropped. In mixed lists the box replaces the bullet:
  ```markdown
  - [ ] Draft the sitemap – jcmx9, bis 17.10.
  - [x] Book the review – Anna Beispiel
  ```
- **Alerts:** `> [!NOTE]` (Info), `[!TIP]` (Tipp), `[!IMPORTANT]` (Wichtig), `[!WARNING]` (Hinweis, calm orange), `[!CAUTION]` (Achtung); German keywords such as `> [!HINWEIS]` work as well
- **Images:** `![Caption](bilder/screen.png){width=50%}` with caption below. Paths relative to the note or absolute; `~`, `$USER`, `$HOME`, `${VAR}` and `%USERPROFILE%` are expanded, e.g. `~/Pictures/logo.svg`. On Windows absolute paths must be on the note's drive. A missing image does not break the export; the PDF shows “[Bild fehlt: …]” instead
- **Diagrams:** ` ```mermaid ` code blocks are drawn in the theme's colors (flowcharts, sequence diagrams, …), offline
- **Date lines:** `18. Oktober 2026` at the start of a line stays a date; Markdown would otherwise turn it into a list starting at 18 (applies to every line starting with number, period and month name)
- **Page breaks:** `\newpage` or `<!-- pagebreak -->` on a line of its own
- **Long tables** continue on the next page with their header repeated
- **Text:** `==highlight==`, footnotes, code with syntax colors, math, typographic quotes, German hyphenation, emoji (monochrome, in text color)
- **Footer:** at most two of client, title and subtitle, in this order (e.g. “Client · Title”, without client “Title · Subtitle”), and the page number
- **PDF/A-2u:** the PDF meets the archiving standard. Images and diagrams carry alt texts; full PDF/UA accessibility is not enforced, because it would make exports fail on everyday notes (e.g. a note starting with `###`)

### Editor theme

The editor theme works with every built-in Zettlr theme; Zettlr's *Appearance → Editor theme* setting no longer matters. Light and dark follow Zettlr's dark mode. It sets fonts, heading sizes (the same proportions as the PDF: level 1 15/11, level 2 13/11, body size from level 3), spacing and colors. To try Zettlr without it, comment out the first line of `custom.css` in Zettlr's *Assets Manager*.

Tags are shown in the accent color including their `#`. Zettlr does not support tag hierarchies: in Obsidian-style tags such as `#project/client` only `#project` is recognized and colored; the note itself stays unchanged.

## Typography

- Old-style figures in running text and headings, lining tabular figures in tables, neutral figures in code – in the PDF and in Zettlr. Source Sans draws its old-style figures subtly, so they are easiest to spot in the Source Serif headings
- Emoji are monochrome and follow the weight of the surrounding text. Exception in Zettlr: emoji written with an explicit color selector (e.g. ⚠️, ❤️) stay in color, because Chromium always renders those with the system color font
- All text colors meet WCAG AA contrast, checked by `scripts/check_contrast.py`

## Development

```bash
# Lint tooling
npm install
npm run lint:css
shellcheck install.sh scripts/*.sh
uvx ruff check scripts/

# Color contrast of the Zettlr palette (WCAG AA)
python3 scripts/check_contrast.py

# Re-download fonts (Adobe releases, Noto Emoji from google/fonts)
uv run scripts/fetch_fonts.py

# Re-download the bundled Typst packages (Mermaid renderer)
python3 scripts/fetch_packages.py

# End-to-end test: export tests/fixtures/*.md and all snippets like Zettlr
# does (needs pandoc, typst and pdftotext or mutool)
./scripts/test_pdf.sh

# Build the release bundle and install it locally
./scripts/package.sh
./install.sh --bundle dist/zettlr-pdf-export-theme.tar.gz

# PDF from the command line
pandoc note.md -f commonmark_x+hard_line_breaks+implicit_figures-smart-fancy_lists -t pdf --pdf-engine=typst \
  --pdf-engine-opt=--ignore-system-fonts --pdf-engine-opt=--font-path=typst/fonts \
  --pdf-engine-opt=--package-cache-path=typst/packages --pdf-engine-opt=--root=/ \
  --template=typst/source.typst --lua-filter=typst/source.lua -o note.pdf
```

CI lints everything, runs the installer on Ubuntu, macOS and Windows (PowerShell 5.1) and exports the test notes with Zettlr's Pandoc version through the installed profile.

## Project Structure

```
install.sh, install.ps1   – Installers (macOS/Linux, Windows)
VERSION                   – Release version (CalVer)
typst/source.typst        – Pandoc template for the PDF
typst/source.lua          – Pandoc filter (title, alerts, quotes, image paths, logo, task tables, date lines, highlights, page breaks)
typst/fonts/              – Fonts for Typst (variable OTF, Noto Emoji, static Regular for diagrams)
typst/packages/           – Bundled Typst packages (mmdr for Mermaid)
typst/example-meeting.md  – Example meeting note
zettlr/                   – Zettlr editor theme, embedded fonts, export profile template, snippets
scripts/                  – Font and package download, contrast check, bundle build, PDF test
tests/fixtures/           – Test notes for the end-to-end PDF test
docs/                     – README images
README.md, README.en.md   – Documentation (German, English)
```

## Versioning

[CalVer](https://calver.org/) in the format `YY.M.MICRO` (year, month, running number within the month), stored in `VERSION` and shown at the top of both READMEs; CI checks that they match. Pushing a tag `v<version>` builds the bundle and creates a GitHub release; the installers always fetch the latest release.

## Contributing, security, changelog

- Workflow and checks: [CONTRIBUTING.md](CONTRIBUTING.md)
- Reporting vulnerabilities: [SECURITY.md](SECURITY.md)
- Changes per version: [CHANGELOG.md](CHANGELOG.md)

## License

Code and theme: MIT – see [LICENSE](LICENSE).
Fonts: SIL Open Font License 1.1 – see `typst/fonts/OFL-*.txt`. Source is a trademark of Adobe; Noto is a trademark of Google.
mmdr (Mermaid renderer): MIT – see `typst/packages/preview/mmdr/0.2.2/LICENSE`.
