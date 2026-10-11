#!/usr/bin/env bash
# Link the Source theme into Typora's theme folder (macOS).
# Existing non-symlink files are moved aside to <name>.bak first.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_dir
readonly theme_dir="${TYPORA_THEME_DIR:-${HOME}/Library/Application Support/abnerworks.Typora/themes}"
readonly items=(source.css source-dark.css source-compact.css source-dark-compact.css source)

link_item() {
    local name="$1"
    local target="${theme_dir}/${name}"

    if [[ -e "${target}" && ! -L "${target}" ]]; then
        mv "${target}" "${target}.bak"
        echo "Backed up ${name} -> ${name}.bak"
    fi
    ln -sfn "${repo_dir}/${name}" "${target}"
    echo "Linked ${name}"
}

main() {
    if [[ ! -d "${theme_dir}" ]]; then
        echo "Error: Typora theme folder not found: ${theme_dir}" >&2
        exit 1
    fi
    for item in "${items[@]}"; do
        link_item "${item}"
    done
    echo "Done. Restart Typora and pick Themes → Source or Source Dark."
}

main "$@"
