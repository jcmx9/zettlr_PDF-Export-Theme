# Changelog

All notable changes to this project are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [CalVer](https://calver.org/) `YY.M.MICRO`.

## [Unreleased]

## [26.10.13] - 2026-10-13

### Added
- Snippet `aufgabe`: one task line with tab stops for task, owner and due date
- SVG logos are covered by the tests

### Fixed
- A line such as `18. Oktober 2026` stays a date instead of becoming a numbered list starting at 18

## [26.10.12] - 2026-10-13

### Fixed
- Notes are read as CommonMark, like Zettlr's editor shows them: a `#` heading directly after a list (without a blank line) is a heading again instead of list text, and lists may follow text without a blank line
- A task item at the end of a list no longer spreads the whole list apart

### Changed
- `==highlight==` and `\newpage` are handled by the Lua filter (the CommonMark reader has neither)

## [26.10.11] - 2026-10-13

### Changed
- Calmer type scale in the PDF (factor 1.2 on 10.5 pt body): title 18 pt (was 22 pt), subtitle 12.5 pt, `#` 15 pt, `##` 12.5 pt, `###` body size in bold

### Removed
- Front matter `next` (next meeting) and its line at the end of the PDF; removed from the snippets

## [26.10.10] - 2026-10-12

### Changed
- Snippets reorganized: `meeting` (topic as title, participants, agenda, notes, tasks), `telefonnotiz` (phone call with time) and `header` (every front matter field, formerly `kopfdaten`). `protokoll`, `jourfixe`, `workshop` and `entscheidung` are gone
- Updating removes snippets of earlier versions unless the user changed them

## [26.10.9] - 2026-10-12

### Changed
- Title and subtitle come from the front matter (`title`, `subtitle`); `#` headings in the text are real section headings. Notes without `title:` that start with `# Title` keep the old behavior
- Footer shows at most two of client, title and subtitle, in this order
- All snippets put the title into the front matter and use `#` for sections; client, title and subtitle are quoted so a colon cannot break the front matter

### Fixed
- A second `#` heading no longer turns into plain text in the PDF

## [26.10.8] - 2026-10-12

### Added
- Snippet `kopfdaten`: every front matter field with a default and a comment

### Fixed
- An empty `logo: ""` no longer breaks the export

## [26.10.7] - 2026-10-12

### Added
- German README (`README.md`) next to the English one (`README.en.md`), both with version line and language link; CI checks the version
- Front matter `logo-height` sets the maximum logo height

### Changed
- The logo keeps its proportions and fits into 20 mm height and 60 mm width (was a fixed 14 mm height)
- Typst 0.15.1 (was 0.15.0); the installer updates it automatically

## [26.10.6] - 2026-10-12

### Added
- Front matter `logo` (image next to the title), `next` (next meeting at the end) and `lang: en` (English labels)
- Task lists with owners (`- [ ] Task – Name, bis 17.10.`) become a table *Aufgabe · Wer · Bis · Status*
- Mermaid diagrams in the PDF, drawn offline in the theme's colors with the bundled mmdr package
- Page breaks with `\newpage` or `<!-- pagebreak -->`; long tables continue on the next page with their header
- PDFs conform to PDF/A-2u; images and diagrams carry alt texts
- Snippets `jourfixe`, `workshop` and `entscheidung`; `protokoll` gained owner, due date and next meeting
- End-to-end PDF test (`scripts/test_pdf.sh`), run in CI on Linux, macOS and Windows with Zettlr's Pandoc 3.10.1
- CHANGELOG, CONTRIBUTING, SECURITY and CODEOWNERS; monthly check for new Typst releases

### Fixed
- Notes with images could not be exported: Pandoc's temporary image copies were outside Typst's root
- Updating no longer backs up the installer's own previous snippets, only snippets the user changed
- The installer takes the snippet list from the bundle, so it cannot fail while a release is being built

### Changed
- GitHub Actions and stylelint updated to their current major versions

## [26.10.5] - 2026-10-12

### Removed
- Typora themes; the project covers Zettlr, Pandoc, Lua, Typst and the PDF only. The installer removes Typora themes installed by earlier versions (only its own files)

## [26.10.4] - 2026-10-12

### Fixed
- The `#` of a tag keeps the tag color in Zettlr

## [26.10.3] - 2026-10-12

### Changed
- Larger paragraph spacing in the PDF (1.4em), so blank-line paragraphs stand out from line breaks

## [26.10.2] - 2026-10-12

### Added
- Monochrome Noto Emoji in the Zettlr editor theme

### Fixed
- Documentation: Typst does apply old-style figures for Source Sans

## [26.10.1] - 2026-10-12

### Added
- Monochrome Noto Emoji as emoji fallback in the PDF

## [26.10.0] - 2026-10-12

### Added
- Zettlr export profile "Source PDF" (Pandoc, Lua filter, Typst) with alerts, task boxes, typographic quotes and old-style figures
- Zettlr editor theme with Adobe's variable Source fonts
- One-line installers for macOS, Linux and Windows

[Unreleased]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.13...HEAD
[26.10.13]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.12...v26.10.13
[26.10.12]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.11...v26.10.12
[26.10.11]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.10...v26.10.11
[26.10.10]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.9...v26.10.10
[26.10.9]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.8...v26.10.9
[26.10.8]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.7...v26.10.8
[26.10.7]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.6...v26.10.7
[26.10.6]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.5...v26.10.6
[26.10.5]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.4...v26.10.5
[26.10.4]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.3...v26.10.4
[26.10.3]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.2...v26.10.3
[26.10.2]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.1...v26.10.2
[26.10.1]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/compare/v26.10.0...v26.10.1
[26.10.0]: https://github.com/jcmx9/zettlr_PDF-Export-Theme/releases/tag/v26.10.0
