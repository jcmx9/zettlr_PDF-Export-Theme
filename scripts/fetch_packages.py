#!/usr/bin/env python3
"""Download the Typst packages the PDF template imports.

They are stored in Typst's package cache layout under typst/packages/, which
the export profile passes as --package-cache-path, so exporting never needs
the internet.
"""

import io
import shutil
import sys
import tarfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "typst" / "packages"

# (namespace, name, version)
PACKAGES = [
    ("preview", "mmdr", "0.2.2"),
]

URL = "https://packages.typst.org/{namespace}/{name}-{version}.tar.gz"


def fetch(namespace: str, name: str, version: str) -> None:
    url = URL.format(namespace=namespace, name=name, version=version)
    with urllib.request.urlopen(url, timeout=120) as response:
        data = response.read()
    target = CACHE / namespace / name / version
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
        archive.extractall(target, filter="data")
    print(f"  {target.relative_to(ROOT)}")


def main() -> int:
    for package in PACKAGES:
        fetch(*package)
    return 0


if __name__ == "__main__":
    sys.exit(main())
