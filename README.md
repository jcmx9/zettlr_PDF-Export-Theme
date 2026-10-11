# Source — Typora Theme

> A calm, typographic Typora theme built on Adobe's Source superfamily.

| Element  | Font            |
| -------- | --------------- |
| Headings | Source Serif 4  |
| Body     | Source Sans 3   |
| Code     | Source Code Pro |

Two themes are included: **Source** (light) and **Source Dark**. All fonts are bundled as variable `woff2` files, so the theme works offline and makes no requests to Google.

## Features

- Size scale of 1.25 for `h1`–`h3`; `h4`–`h6` stay at body size and differ by weight and style
- More space above headings than below, reduced gaps for stacked headings
- Styled alerts (`> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`)
- Custom syntax highlighting for light and dark
- Focus mode fades all blocks except the one being edited
- Print rules for PDF export: A4 margins, no page breaks inside code blocks, tables or quotes

## Installation

### With symlinks (recommended)

```bash
git clone https://github.com/jcmx9/Typora_Theme-Source.git
cd Typora_Theme-Source
./scripts/install.sh
```

The script links `source.css`, `source-dark.css` and the `source/` folder into Typora's theme folder. Changes in the repository take effect after reloading Typora. Existing files with the same name are moved to `*.bak`.

### Manual

Copy `source.css`, `source-dark.css` and the `source/` folder into Typora's theme folder (*Preferences → Appearance → Open Theme Folder*).

Then restart Typora and choose **Themes → Source** or **Themes → Source Dark**.

## PDF export

Page margins come from the theme. Page numbers and headers/footers are set in Typora under *Preferences → Export → PDF*, for example `${pageNo} / ${totalPages}` in the footer.

## Development

```bash
# Re-download fonts and regenerate source/fonts.css
python3 scripts/fetch_fonts.py

# Preview every element
open -a Typora sample.md
```

All colors are CSS variables in `:root` of `source.css`. `source-dark.css` imports the light theme and overrides only those variables.

## Project Structure

```
source.css          – Light theme (layout, typography, colors)
source-dark.css     – Dark theme (color overrides only)
source/fonts.css    – Generated @font-face rules
source/fonts/       – Variable woff2 fonts and OFL licenses
sample.md           – Sample document with all elements
scripts/            – Install and font download scripts
```

## License

Theme: MIT – see [LICENSE](LICENSE).
Fonts: SIL Open Font License 1.1 – see `source/fonts/OFL-*.txt`.
