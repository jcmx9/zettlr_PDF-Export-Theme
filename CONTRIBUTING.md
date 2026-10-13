# Contributing

Thanks for your interest in improving the Zettlr rfdoc Export. This project only connects Zettlr to [real-fast-document](https://github.com/jcmx9/real-fast-document) and ships Zettlr snippets; everything about the PDF itself belongs in real-fast-document.

## Prerequisites

- Git and a GitHub account
- [Pandoc](https://pandoc.org) (Zettlr ships 3.10.1) and shellcheck
- Optional: [real-fast-document](https://github.com/jcmx9/real-fast-document) for a real end-to-end run

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
   shellcheck install.sh scripts/*.sh
   ./scripts/test_messenger.sh
   ```
4. Commit with a [Conventional Commits](https://www.conventionalcommits.org/) message in English.
5. Push and open a pull request against `dev`.

Feature branches are squash-merged into `dev`; releases are rebase-merged from `dev` into `main` and tagged `v<version>`.

## PR checklist

- [ ] All checks above pass
- [ ] README.md (German) and README.en.md (English) updated together, same structure
- [ ] CHANGELOG.md updated under `[Unreleased]`
- [ ] `VERSION` bumped for user-visible changes, together with the version line in both READMEs

## Code standards

- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, quoted `"${variables}"`, shellcheck clean, compatible with macOS bash 3.2
- PowerShell: compatible with Windows PowerShell 5.1
- Lua filter: plain Lua as embedded in Pandoc 3.x, no extra modules

## Issues

Bug reports should include the Zettlr version, the operating system and the full export error message.

## Code of conduct

We expect respectful, constructive interaction. Harassment, discrimination or trolling will result in exclusion.
