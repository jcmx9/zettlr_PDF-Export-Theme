#!/usr/bin/env python3
"""Check WCAG contrast ratios of the theme's color variables.

Reads the :root variables of source.css and source-dark.css (the dark theme
inherits from the light one) and fails if a text/background pair is below the
required ratio. Also verifies that the Zettlr palette mirrors these colors.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

AA_TEXT = 4.5
AA_LARGE = 3.0

# (foreground, background, minimum ratio)
PAIRS = [
    ("--text-color", "--bg-color", AA_TEXT),
    ("--heading-color", "--bg-color", AA_TEXT),
    ("--text-muted", "--bg-color", AA_TEXT),
    ("--accent", "--bg-color", AA_TEXT),
    ("--text-color", "--code-bg", AA_TEXT),
    ("--text-color", "--table-stripe", AA_TEXT),
    ("--text-color", "--mark-bg", AA_TEXT),
    ("--text-color", "--select-text-bg-color", AA_TEXT),
    ("--alert-note", "--bg-color", AA_TEXT),
    ("--alert-tip", "--bg-color", AA_TEXT),
    ("--alert-important", "--bg-color", AA_TEXT),
    ("--alert-warning", "--bg-color", AA_TEXT),
    ("--alert-caution", "--bg-color", AA_TEXT),
    ("--syntax-keyword", "--code-bg", AA_TEXT),
    ("--syntax-def", "--code-bg", AA_TEXT),
    ("--syntax-type", "--code-bg", AA_TEXT),
    ("--syntax-string", "--code-bg", AA_TEXT),
    ("--syntax-number", "--code-bg", AA_TEXT),
    ("--syntax-comment", "--code-bg", AA_TEXT),
    ("--syntax-meta", "--code-bg", AA_TEXT),
    ("--syntax-operator", "--code-bg", AA_TEXT),
    # Markdown syntax chars, line numbers and focus-mode fading are meant to
    # recede, but must stay readable as large/non-text elements.
    ("--text-faint", "--bg-color", AA_LARGE),
    ("--text-faint", "--code-bg", AA_LARGE),
]

# Zettlr palette name (without --src-) -> Typora variable, if not --<same name>
ZETTLR_NAMES = {
    "text": "--text-color",
    "heading": "--heading-color",
    "bg": "--bg-color",
    "selection": "--select-text-bg-color",
}

VAR_RE = re.compile(r"(--[\w-]+)\s*:\s*(#[0-9a-fA-F]{6})\s*;")


def root_vars(css: str) -> dict[str, str]:
    """Return hex color variables of the first top-level :root block."""
    block = re.search(r"^:root\s*\{(.*?)^\}", css, re.DOTALL | re.MULTILINE)
    return dict(VAR_RE.findall(block.group(1))) if block else {}


def block_vars(css: str, selector: str) -> dict[str, str]:
    """Return hex color variables of the block with the given selector."""
    block = re.search(
        rf"^{re.escape(selector)}\s*\{{(.*?)^\}}", css, re.DOTALL | re.MULTILINE
    )
    return dict(VAR_RE.findall(block.group(1))) if block else {}


def check_zettlr(name: str, palette: dict[str, str], colors: dict[str, str]) -> int:
    failures = 0
    for var, value in palette.items():
        short = var.removeprefix("--src-")
        typora = ZETTLR_NAMES.get(short, f"--{short}")
        if colors.get(typora, "").lower() != value.lower():
            failures += 1
            print(
                f"  FAIL Zettlr {name}: {var} {value} != {typora} {colors.get(typora)}"
            )
    return failures


def luminance(hex_color: str) -> float:
    channels = [int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [
        c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def ratio(fg: str, bg: str) -> float:
    light, dark = sorted((luminance(fg), luminance(bg)), reverse=True)
    return (light + 0.05) / (dark + 0.05)


def check(name: str, colors: dict[str, str]) -> int:
    failures = 0
    print(f"{name}")
    for fg, bg, minimum in PAIRS:
        value = ratio(colors[fg], colors[bg])
        ok = value >= minimum
        failures += not ok
        mark = "ok  " if ok else "FAIL"
        print(f"  {mark} {value:5.2f} ≥ {minimum:<3}  {fg} on {bg}")
    return failures


def main() -> int:
    light = root_vars((ROOT / "source.css").read_text())
    dark = light | root_vars((ROOT / "source-dark.css").read_text())
    failures = check("Source", light) + check("Source Dark", dark)

    zettlr = (ROOT / "zettlr" / "source-zettlr.css").read_text()
    print("Zettlr palette")
    failures += check_zettlr("light", block_vars(zettlr, "html:root"), light)
    failures += check_zettlr("dark", block_vars(zettlr, "html body.dark"), dark)
    print(f"{failures} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
