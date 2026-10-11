#!/usr/bin/env bash
# Build a release ZIP with everything Typora needs: dist/source-typora-theme-<version>.zip
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_dir
readonly files=(source.css source-dark.css source-compact.css source-dark-compact.css source LICENSE README.md)

read_version() {
    sed -n 's/^ \* Source — Typora theme · v\([0-9.]*\)$/\1/p' "${repo_dir}/source.css"
}

main() {
    local version
    version="$(read_version)"
    if [[ -z "${version}" ]]; then
        echo "Error: no version found in source.css header" >&2
        exit 1
    fi

    local archive="${repo_dir}/dist/source-typora-theme-${version}.zip"
    mkdir -p "${repo_dir}/dist"
    rm -f "${archive}"
    (cd "${repo_dir}" && zip -qr -X "${archive}" "${files[@]}" -x '*.DS_Store')
    echo "${archive}"
}

main "$@"
