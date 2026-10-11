# Source — Typora Theme

> A calm, typographic Typora theme built on Adobe's Source superfamily.

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

Download the ZIP from the [latest release](https://github.com/jcmx9/Typora_Theme-Source/releases/latest), open Typora's theme folder (*Preferences → Appearance → Open Theme Folder*) and copy all `.css` files and the `source/` folder into it.

### With symlinks (macOS)

```bash
git clone https://github.com/jcmx9/Typora_Theme-Source.git
cd Typora_Theme-Source
./scripts/install.sh
```

The script links all theme files and the `source/` folder into Typora's theme folder. Changes in the repository take effect after reloading Typora. Existing files with the same name are moved to `*.bak`.

Then restart Typora and choose a theme from the **Themes** menu. To switch automatically with the system appearance, enable *Preferences → Appearance → Use separate theme in dark mode* and select **Source Dark**.

## PDF export

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

# Build the release ZIP in dist/
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
source/fonts.css          – Generated @font-face rules
source/fonts/             – Variable OTF fonts (woff2) and OFL licenses
sample.md                 – Sample document with all elements
scripts/                  – Install, package, font download and contrast check
.github/workflows/        – CI (lint, contrast) and release (ZIP on tag)
```

## Versioning

This project uses [CalVer](https://calver.org/) in the format `YY.M.MICRO`. The version lives in the header comment of `source.css`. Pushing a tag `v<version>` builds the ZIP and creates a GitHub release.

## License

Theme: MIT – see [LICENSE](LICENSE).
Fonts: SIL Open Font License 1.1 – see `source/fonts/OFL-*.txt`.
