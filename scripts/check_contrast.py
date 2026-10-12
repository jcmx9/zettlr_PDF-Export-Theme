#!/usr/bin/env python3
"""Check WCAG contrast ratios of the Zettlr theme's color palette.

Reads the --src-* variables of zettlr/source-zettlr.css (light: html:root,
dark: html body.dark) and fails if a text/background pair is below the
required ratio.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

AA_TEXT = 4.5
AA_LARGE = 3.0

# (foreground, background, minimum ratio), names without the --src- prefix
PAIRS = [
    ("text", "bg", AA_TEXT),
    ("heading", "bg", AA_TEXT),
    ("text-muted", "bg", AA_TEXT),
    ("accent", "bg", AA_TEXT),
    ("text", "code-bg", AA_TEXT),
    ("text", "mark-bg", AA_TEXT),
    ("text", "selection", AA_TEXT),
    ("alert-note", "bg", AA_TEXT),
    ("alert-tip", "bg", AA_TEXT),
    ("alert-important", "bg", AA_TEXT),
    ("alert-warning", "bg", AA_TEXT),
    ("alert-caution", "bg", AA_TEXT),
    ("syntax-keyword", "code-bg", AA_TEXT),
    ("syntax-def", "code-bg", AA_TEXT),
    ("syntax-type", "code-bg", AA_TEXT),
    ("syntax-string", "code-bg", AA_TEXT),
    ("syntax-number", "code-bg", AA_TEXT),
    ("syntax-comment", "code-bg", AA_TEXT),
    ("syntax-meta", "code-bg", AA_TEXT),
    # Markdown syntax chars are meant to recede, but must stay readable as
    # large/non-text elements.
    ("text-faint", "bg", AA_LARGE),
    ("text-faint", "code-bg", AA_LARGE),
]

VAR_RE = re.compile(r"--src-([\w-]+)\s*:\s*(#[0-9a-fA-F]{6})\s*;")


def block_vars(css: str, selector: str) -> dict[str, str]:
    """Return the hex --src-* variables of the block with the given selector."""
    block = re.search(
        rf"^{re.escape(selector)}\s*\{{(.*?)^\}}", css, re.DOTALL | re.MULTILINE
    )
    return dict(VAR_RE.findall(block.group(1))) if block else {}


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
        if fg not in colors or bg not in colors:
            failures += 1
            print(f"  FAIL missing --src-{fg} or --src-{bg}")
            continue
        value = ratio(colors[fg], colors[bg])
        ok = value >= minimum
        failures += not ok
        mark = "ok  " if ok else "FAIL"
        print(f"  {mark} {value:5.2f} ≥ {minimum:<3}  {fg} on {bg}")
    return failures


def main() -> int:
    css = (ROOT / "zettlr" / "source-zettlr.css").read_text()
    light = block_vars(css, "html:root")
    dark = light | block_vars(css, "html body.dark")
    failures = check("Light", light) + check("Dark", dark)
    print(f"{failures} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
