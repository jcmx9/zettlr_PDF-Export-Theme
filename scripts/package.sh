#!/usr/bin/env bash
# Build the release bundle the installers download:
#   dist/zettlr-pdf-export-theme.tar.gz (+ .sha256)  – macOS / Linux
#   dist/zettlr-pdf-export-theme.zip    (+ .sha256)  – Windows
# The names carry no version, so releases/latest/download/<name> always
# points to the newest release; the version is inside the bundle (VERSION).
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_dir
readonly name="zettlr-pdf-export-theme"
readonly files=(
    VERSION LICENSE README.md README.en.md CHANGELOG.md
    "zettlr/rf-doc.yaml.in" zettlr/rf-document.lua zettlr/snippets
)

checksum() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$(dirname "${file}")" && sha256sum "$(basename "${file}")") > "${file}.sha256"
    else
        (cd "$(dirname "${file}")" && shasum -a 256 "$(basename "${file}")") > "${file}.sha256"
    fi
}

main() {
    local dist="${repo_dir}/dist"
    mkdir -p "${dist}"
    rm -f "${dist}/${name}".*

    cd "${repo_dir}"
    local tar_opts=(--exclude '.DS_Store')
    if tar --version 2>/dev/null | grep -q bsdtar; then
        # macOS: keep extended attributes out of the archive
        tar_opts+=(--no-xattrs --no-mac-metadata)
    fi
    COPYFILE_DISABLE=1 tar -czf "${dist}/${name}.tar.gz" "${tar_opts[@]}" "${files[@]}"
    zip -qr -X "${dist}/${name}.zip" "${files[@]}" -x '*.DS_Store'

    checksum "${dist}/${name}.tar.gz"
    checksum "${dist}/${name}.zip"
    echo "Built ${name} $(cat VERSION):"
    ls -1 "${dist}/${name}".*
}

main "$@"
