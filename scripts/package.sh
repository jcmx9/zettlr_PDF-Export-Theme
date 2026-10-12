#!/usr/bin/env bash
# Build the release ZIPs in dist/:
#   source-typora-theme-<version>.zip  – Typora themes and OTF fonts
#   source-zettlr-theme-<version>.zip  – Zettlr theme, Typst PDF export, snippet
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_dir
readonly typora_files=(source.css source-dark.css source-compact.css source-dark-compact.css source/fonts.css source/fonts LICENSE README.md)
stage=""
readonly zettlr_files=(source-zettlr.css source/fonts-ttf.css source/fonts/OFL-SourceCodePro.txt source/fonts/OFL-SourceSans3.txt source/fonts/OFL-SourceSerif4.txt typst "Source PDF (Typst).yaml.in" snippets LICENSE README.md)

read_version() {
    sed -n 's/^ \* Source — Typora theme · v\([0-9.]*\)$/\1/p' "${repo_dir}/source.css"
}

build_zip() {
    local archive="$1"
    shift
    rm -f "${archive}"
    zip -qr -X "${archive}" "$@" -x '*.DS_Store'
    echo "${archive}"
}

main() {
    local version
    version="$(read_version)"
    if [[ -z "${version}" ]]; then
        echo "Error: no version found in source.css header" >&2
        exit 1
    fi
    mkdir -p "${repo_dir}/dist"

    cd "${repo_dir}"
    build_zip "${repo_dir}/dist/source-typora-theme-${version}.zip" "${typora_files[@]}"

    # Zettlr expects source-zettlr.css next to the source/ folder
    stage="$(mktemp -d)"
    trap 'rm -rf "${stage:-}"' EXIT
    mkdir -p "${stage}/source/fonts"
    cp zettlr/source-zettlr.css LICENSE README.md "${stage}/"
    cp source/fonts-ttf.css "${stage}/source/"
    cp source/fonts/OFL-*.txt "${stage}/source/fonts/"
    cp -R typst zettlr/snippets "zettlr/Source PDF (Typst).yaml.in" "${stage}/"
    rm -f "${stage}/typst/example-meeting.md"
    cd "${stage}"
    build_zip "${repo_dir}/dist/source-zettlr-theme-${version}.zip" "${zettlr_files[@]}"
}

main "$@"
