# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Older releases | No |

The installers always install the latest release, so updating means running the install line again.

## Reporting a vulnerability

Please do **not** report security vulnerabilities via public issues.

Use GitHub's private vulnerability reporting instead: **Security → Report a vulnerability** in this repository. Include a description and, if possible, steps to reproduce.

We aim to acknowledge reports within 48 hours and to provide a fix within 14 days. After the fix is released, the vulnerability is documented in the CHANGELOG and release notes, with credit if desired.

## Scope notes

- The installers download the release bundle and Typst over HTTPS from GitHub and verify the bundle's SHA-256 checksum.
- The export profile lets Typst read files from `/` (on Windows: the root of the note's drive), so images anywhere on the disk can be included. Typst only reads files the note references.
- `npm audit` reports issues in stylelint's dependencies. stylelint is used for linting in CI only; it is not part of the release bundle and never runs on users' machines.
