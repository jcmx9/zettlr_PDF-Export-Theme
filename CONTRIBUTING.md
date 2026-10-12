# Contributing

Thanks for your interest in improving the Zettlr PDF Export Theme. This guide describes the workflow.

## Prerequisites

- Git and a GitHub account
- [Pandoc](https://pandoc.org) (Zettlr ships 3.10.1) and [Typst](https://typst.app) 0.15
- Node.js (stylelint), [uv](https://docs.astral.sh/uv/) (ruff, font download), shellcheck
- `pdftotext` (poppler) or `mutool` (mupdf) for the PDF test

## Workflow

1. Create a branch from `dev`:
   ```bash
   git checkout dev && git pull origin dev
   git checkout -b feature/<short-description>
   ```
   Prefixes: `feature/`, `bugfix/`, `docs/`, `refactor/`, `chore/`.
2. Implement your changes.
3. Make sure all checks pass:
   ```bash
   npm install && npm run lint:css
   shellcheck install.sh scripts/*.sh
   uvx ruff check scripts/
   python3 scripts/check_contrast.py
   ./scripts/test_pdf.sh
   ```
4. Commit with a [Conventional Commits](https://www.conventionalcommits.org/) message in English, e.g. `feat(pdf): add signature block`.
5. Push and open a pull request against `dev`.

Feature branches are squash-merged into `dev`; releases are rebase-merged from `dev` into `main` and tagged `v<version>`.

## PR checklist

- [ ] All checks above pass
- [ ] New PDF features are covered by `tests/fixtures/` and `scripts/test_pdf.sh`
- [ ] README updated (if applicable)
- [ ] CHANGELOG.md updated under `[Unreleased]`
- [ ] `VERSION` bumped for user-visible changes

## Code standards

- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, quoted `"${variables}"`, shellcheck clean, compatible with macOS bash 3.2
- PowerShell: compatible with Windows PowerShell 5.1
- Python: ruff clean, standard library where possible
- CSS: stylelint clean; colors live in the `--src-*` palette and must pass `check_contrast.py`
- Keep colors and fonts consistent between `zettlr/source-zettlr.css` and `typst/source.typst`

## Issues

Bug reports should include the Zettlr version, the operating system, the note (or a minimal excerpt) and the full export error message.

## Code of conduct

We expect respectful, constructive interaction. Harassment, discrimination or trolling will result in exclusion.
