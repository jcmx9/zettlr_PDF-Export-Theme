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

- The installers download the release bundle over HTTPS from GitHub and verify its SHA-256 checksum.
- The export profile runs a Lua filter that starts `rf-document` with the note's path. It uses the path the installer found or looks in a fixed list of places (`RF_DOCUMENT`, `~/.local/bin`, Homebrew, `%LOCALAPPDATA%\Microsoft\WindowsApps`, `PATH`); anyone who can place a program there can run code in your session anyway.
