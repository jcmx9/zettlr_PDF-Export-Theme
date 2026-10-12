# Source — Typora Theme

> A calm, typographic theme for Typora and Zettlr, plus a Typst PDF export, built on Adobe's Source superfamily.

[![CI](https://github.com/jcmx9/Typora_Theme-Source/actions/workflows/ci.yml/badge.svg)](https://github.com/jcmx9/Typora_Theme-Source/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Version 26.10.0

| Element  | Font            |
| -------- | --------------- |
| Headings | Source Serif 4  |
| Body     | Source Sans 3   |
| Code     | Source Code Pro |

## Themes

| Theme               | File                      | Description                          |
| ------------------- | ------------------------- | ------------------------------------ |
| Source              | `source.css`              | Light, 17 px base size               |
| Source Dark         | `source-dark.css`         | Dark, 17 px base size                |
| Source Compact      | `source-compact.css`      | Light, 15 px, tighter margins        |
| Source Dark Compact | `source-dark-compact.css` | Dark, 15 px, tighter margins         |

All fonts are bundled as variable OTF (CFF2) fonts in `woff2` format, taken from Adobe's official releases. They cover Latin, Greek and Cyrillic and keep all OpenType features such as old-style figures, which the Google Fonts builds strip. The theme works offline and makes no network requests.

## Features

- Size scale of 1.25 for `h1`–`h3`; `h4`–`h6` stay at body size and differ by weight and style
- More space above headings than below, reduced gaps for stacked headings
- Old-style figures in running text, lining tabular figures in tables
- All text colors meet WCAG AA contrast (checked by `scripts/check_contrast.py`)
- Styled alerts (`> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`)
- Custom syntax highlighting for light and dark
- Mermaid diagrams use the theme font and a matching Mermaid theme
- Focus mode fades all blocks except the one being edited
- Print rules for PDF export: A4 margins, no page breaks inside code blocks, tables or quotes

## Installation

### Release ZIP

Download the Typora ZIP from the [latest release](https://github.com/jcmx9/Typora_Theme-Source/releases/latest), open Typora's theme folder (*Preferences → Appearance → Open Theme Folder*) and copy all `.css` files and the `source/` folder into it.

### With symlinks (macOS)

```bash
git clone https://github.com/jcmx9/Typora_Theme-Source.git
cd Typora_Theme-Source
./scripts/install.sh
```

The script links all theme files and the `source/` folder into Typora's theme folder. Changes in the repository take effect after reloading Typora. Existing files with the same name are moved to `*.bak`.

Then restart Typora and choose a theme from the **Themes** menu. To switch automatically with the system appearance, enable *Preferences → Appearance → Use separate theme in dark mode* and select **Source Dark**.

## Zettlr

The same typography and colors are available for [Zettlr](https://www.zettlr.com) (tested against 4.8). Zettlr has no theme menu for custom themes; instead its `custom.css` imports `source-zettlr.css`. Light and dark follow Zettlr's dark mode, and the theme works with every built-in Zettlr theme.

```bash
./scripts/install-zettlr.sh              # link theme and fonts, add the import to custom.css
./scripts/install-zettlr.sh --uninstall  # remove import and links again
```

Existing rules in `custom.css` are kept, and a timestamped backup is written before every change. Without the script, unpack the Zettlr ZIP from the release into Zettlr's data folder (macOS: `~/Library/Application Support/zettlr`) and add `@import url("source-zettlr.css");` as the first line of `custom.css`.

Differences to Typora:

- Zettlr is an editor with visible Markdown syntax, so the theme sets fonts, sizes, spacing and colors, not the layout of tables or code blocks.
- Zettlr runs on Chromium, so it uses the TTF fonts, which are embedded in `source/fonts-ttf.css`; Zettlr's file protocol cannot serve font files across origins.
- Exports run through Pandoc and are not affected by the theme.

## PDF export with Zettlr, Pandoc and Typst

For client-ready PDFs (e.g. meeting notes written live during a call), Zettlr exports through Pandoc and [Typst](https://typst.app). Everything involved is free and open source, Pandoc ships with Zettlr, and Typst is a single binary without further dependencies.

![Example meeting note as PDF](docs/example-meeting.png)

- **Layout:** A4, client name and title block, section headings in Source Serif, body in Source Sans, footer with client, title and page numbers, German hyphenation
- **Line breaks:** every line break in the note is kept in the PDF
- **Title:** `# Topic` becomes the document title, `## Agenda`, `## Teilnehmer` … become the sections
- **Front matter (optional):** `client`, `date` (defaults to the export date), `subtitle`, `author`
- **Tasks:** `- [ ]` / `- [x]` lists render as check boxes

`./scripts/install-zettlr.sh` writes the export profile **Source PDF (Typst)** with the absolute paths of this repository and of `typst` (from `PATH`, `~/.local/bin`, `~/.cargo/bin` or Homebrew). It also links the snippet `protokoll`: type `:protokoll` in a new note to get the structure with client, date, topic, agenda, participants, notes and tasks.

Without the script (e.g. on another machine), copy `zettlr/Source PDF (Typst).yaml.in` to Zettlr's `defaults/` folder as `Source PDF (Typst).yaml`, replace `@TYPST@` with the path of the typst binary and `@REPO@` with the folder that contains `typst/`, and copy `zettlr/snippets/protokoll.tpl.md` to Zettlr's `snippets/` folder.

Export from the command line:

```bash
pandoc note.md -f markdown+hard_line_breaks -t pdf --pdf-engine=typst \
  --pdf-engine-opt=--ignore-system-fonts --pdf-engine-opt=--font-path=typst/fonts \
  --template=typst/source.typst --shift-heading-level-by=-1 -o note.pdf
```

## PDF export from Typora

Paper size (A4) and page margins come from the theme. Headers and footers are set in Typora under *Preferences → Export → PDF*:

| Setting | Example                          |
| ------- | -------------------------------- |
| Header  | `${title}`                       |
| Footer  | `${pageNo} / ${totalPages}`      |

The PDF uses the active theme, so exporting with **Source Dark** produces a dark PDF.

## Known limitations

- Typora on macOS renders with WebKit, where the variable OTF fonts look as intended. Typora on Windows and Linux uses Chromium, which renders CFF2 fonts slightly lighter.
- Source Code Pro Italic has no Greek or Cyrillic glyphs; those characters fall back to the next monospace font.
- Hyphenation is not enabled: Typora sets the document language to English, so `hyphens: auto` would split German words incorrectly.

## Development

```bash
# Install lint tooling
npm install

# Lint CSS, shell scripts and Python scripts
npm run lint:css
shellcheck scripts/*.sh
uvx ruff check scripts/

# Check color contrast (WCAG AA)
python3 scripts/check_contrast.py

# Re-download fonts from Adobe's releases and regenerate source/fonts.css
python3 scripts/fetch_fonts.py

# Build the release ZIPs (Typora, Zettlr) in dist/
./scripts/package.sh

# Preview every element
open -a Typora sample.md
```

All colors are CSS variables in `:root` of `source.css`. `source-dark.css` imports the light theme and overrides only those variables; the compact variants override `--base-size` and `--content-width`.

## Project Structure

```
source.css                – Light theme (layout, typography, colors)
source-dark.css           – Dark theme (color overrides only)
source-compact.css        – Compact light variant
source-dark-compact.css   – Compact dark variant
zettlr/source-zettlr.css  – Zettlr theme (light and dark)
source/fonts.css          – Generated @font-face rules (OTF files, Typora)
source/fonts-ttf.css      – Generated @font-face rules (embedded TTF, Zettlr)
typst/source.typst        – Pandoc template for the Typst PDF export
typst/fonts/              – Variable TTF fonts for Typst
typst/example-meeting.md  – Example meeting note
zettlr/                   – Zettlr export profile template and snippet
source/fonts/             – Variable OTF fonts (woff2) and OFL licenses
sample.md                 – Sample document with all elements
scripts/                  – Install (Typora, Zettlr), package, font download, contrast check
.github/workflows/        – CI (lint, contrast) and release (ZIP on tag)
```

## Versioning

This project uses [CalVer](https://calver.org/) in the format `YY.M.MICRO`. The version lives in the header comment of `source.css`. Pushing a tag `v<version>` builds one ZIP for Typora and one for Zettlr and creates a GitHub release.

## License

Theme: MIT – see [LICENSE](LICENSE).
Fonts: SIL Open Font License 1.1 – see `source/fonts/OFL-*.txt`.
