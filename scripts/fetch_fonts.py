#!/usr/bin/env python3
"""Download the Source font family from Adobe's GitHub releases.

Unlike the Google Fonts builds, Adobe's variable fonts keep all OpenType
features, e.g. old-style figures. Three variants are generated:

- OTF (CFF2) files in source/fonts/ for Typora on macOS (WebKit),
  referenced by source/fonts.css
- TTF embedded as data URIs in source/fonts-ttf.css for Chromium-based apps
  such as Zettlr, whose custom scheme cannot serve fonts across origins
- Desktop TTF files in typst/fonts/ for the Pandoc/Typst PDF export

The OFL license texts are stored next to the font files.
"""

import base64
import io
import sys
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FONT_DIR = ROOT / "source" / "fonts"
TYPST_FONT_DIR = ROOT / "typst" / "fonts"
FONT_CSS = {
    "otf": ROOT / "source" / "fonts.css",
    "ttf": ROOT / "source" / "fonts-ttf.css",
}

RELEASES = "https://github.com/adobe-fonts/{repo}/releases/download/{tag}/{asset}"
LICENSE = "https://raw.githubusercontent.com/adobe-fonts/{repo}/release/LICENSE.md"

# family, repo, release tag, release asset, {style: member path without extension}
FAMILIES = [
    (
        "Source Serif 4",
        "source-serif",
        "4.005R",
        "source-serif-4.005_WOFF2.zip",
        {
            "normal": "source-serif-4.005_WOFF2/VAR/SourceSerif4Variable-Roman",
            "italic": "source-serif-4.005_WOFF2/VAR/SourceSerif4Variable-Italic",
        },
    ),
    (
        "Source Sans 3",
        "source-sans",
        "3.052R",
        "WOFF2-source-sans-3.052R.zip",
        {
            "normal": "WOFF2/VF/SourceSans3VF-Upright",
            "italic": "WOFF2/VF/SourceSans3VF-Italic",
        },
    ),
    (
        "Source Code Pro",
        "source-code-pro",
        "2.042R-u%2F1.062R-i%2F1.026R-vf",
        "WOFF2-source-code-pro-2.042R-u_1.062R-i_1.026Rvf.zip",
        {
            "normal": "WOFF2/VF/SourceCodeVF-Upright",
            "italic": "WOFF2/VF/SourceCodeVF-Italic",
        },
    ),
]

# Desktop variable TTFs for Typst: repo, release tag, release asset, members
TYPST_FONTS = [
    (
        "source-serif",
        "4.005R",
        "source-serif-4.005_Desktop.zip",
        [
            "source-serif-4.005_Desktop/VAR/SourceSerif4Variable-Roman.ttf",
            "source-serif-4.005_Desktop/VAR/SourceSerif4Variable-Italic.ttf",
        ],
    ),
    (
        "source-sans",
        "3.052R",
        "VF-source-sans-3.052R.zip",
        ["VF/SourceSans3VF-Upright.ttf", "VF/SourceSans3VF-Italic.ttf"],
    ),
    (
        "source-code-pro",
        "2.042R-u%2F1.062R-i%2F1.026R-vf",
        "VF-source-code-VF-1.026R.zip",
        ["VF/SourceCodeVF-Upright.ttf", "VF/SourceCodeVF-Italic.ttf"],
    ),
]

FACE = """@font-face {{
    font-family: "{family}";
    font-style: {style};
    font-weight: 200 900;
    font-display: swap;
    src: url("{src}") format("woff2");
}}
"""


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def fetch_typst_fonts() -> None:
    TYPST_FONT_DIR.mkdir(parents=True, exist_ok=True)
    for stale in TYPST_FONT_DIR.glob("*.ttf"):
        stale.unlink()
    for repo, tag, asset, members in TYPST_FONTS:
        url = RELEASES.format(repo=repo, tag=tag, asset=asset)
        with zipfile.ZipFile(io.BytesIO(fetch(url))) as archive:
            for member in members:
                filename = Path(member).name
                (TYPST_FONT_DIR / filename).write_bytes(archive.read(member))
                print(f"  typst/fonts/{filename}")
    for license_file in FONT_DIR.glob("OFL-*.txt"):
        (TYPST_FONT_DIR / license_file.name).write_bytes(license_file.read_bytes())


def main() -> int:
    FONT_DIR.mkdir(parents=True, exist_ok=True)
    for stale in FONT_DIR.glob("*.woff2"):
        stale.unlink()

    rules: dict[str, list[str]] = {fmt: [] for fmt in FONT_CSS}
    for family, repo, tag, asset, members in FAMILIES:
        url = RELEASES.format(repo=repo, tag=tag, asset=asset)
        with zipfile.ZipFile(io.BytesIO(fetch(url))) as archive:
            for style, member in members.items():
                filename = f"{family.replace(' ', '')}-{style}.otf.woff2"
                (FONT_DIR / filename).write_bytes(archive.read(f"{member}.otf.woff2"))
                rules["otf"].append(
                    FACE.format(family=family, style=style, src=f"fonts/{filename}")
                )
                print(f"  {filename}")

                ttf = base64.b64encode(archive.read(f"{member}.ttf.woff2")).decode()
                rules["ttf"].append(
                    FACE.format(
                        family=family,
                        style=style,
                        src=f"data:font/woff2;base64,{ttf}",
                    )
                )

        license_name = f"OFL-{family.replace(' ', '')}.txt"
        (FONT_DIR / license_name).write_bytes(fetch(LICENSE.format(repo=repo)))
        print(f"  {license_name}")

    header = "/* Generated by scripts/fetch_fonts.py — do not edit by hand. */\n\n"
    for fmt, path in FONT_CSS.items():
        path.write_text(header + "\n".join(rules[fmt]))
        print(f"{len(rules[fmt])} {fmt} fonts, CSS written to {path.relative_to(ROOT)}")

    fetch_typst_fonts()
    return 0


if __name__ == "__main__":
    sys.exit(main())
