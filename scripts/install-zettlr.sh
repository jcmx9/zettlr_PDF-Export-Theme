#!/usr/bin/env bash
# Link the Source theme into Zettlr's data folder (macOS) and import it from
# custom.css. Existing custom.css rules are kept; a backup is written first.
#
# Usage: install-zettlr.sh [--uninstall]
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_dir
readonly data_dir="${ZETTLR_DATA_DIR:-${HOME}/Library/Application Support/zettlr}"
readonly custom_css="${data_dir}/custom.css"
readonly import_line='@import url("source-zettlr.css");'

link_item() {
    local source="$1"
    local target="$2"

    if [[ -e "${target}" && ! -L "${target}" ]]; then
        mv "${target}" "${target}.bak"
        echo "Backed up $(basename "${target}") -> $(basename "${target}").bak"
    fi
    ln -sfn "${source}" "${target}"
    echo "Linked $(basename "${target}")"
}

backup_custom_css() {
    local stamp backup n=1
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="${custom_css}.${stamp}.bak"
    while [[ -e "${backup}" ]]; do
        backup="${custom_css}.${stamp}-${n}.bak"
        n=$((n + 1))
    done
    cp "${custom_css}" "${backup}"
    echo "Backed up custom.css -> $(basename "${backup}")"
}

install_theme() {
    link_item "${repo_dir}/zettlr/source-zettlr.css" "${data_dir}/source-zettlr.css"
    link_item "${repo_dir}/source" "${data_dir}/source"

    if [[ ! -f "${custom_css}" ]]; then
        printf '%s\n' "${import_line}" > "${custom_css}"
        echo "Created custom.css"
    elif grep -qF "${import_line}" "${custom_css}"; then
        echo "custom.css already imports the theme"
    else
        backup_custom_css
        # @import must come before all other rules
        { printf '%s\n\n' "${import_line}"; cat "${custom_css}"; } > "${custom_css}.tmp"
        mv "${custom_css}.tmp" "${custom_css}"
        echo "Added import to custom.css"
    fi
    echo "Done. Zettlr picks up custom.css changes; otherwise restart Zettlr."
}

uninstall_theme() {
    if [[ -f "${custom_css}" ]] && grep -qF "${import_line}" "${custom_css}"; then
        backup_custom_css
        if [[ "$(head -n 2 "${custom_css}")" == "${import_line}" ]]; then
            # Exactly what install added: import line plus one blank line
            tail -n +3 "${custom_css}" > "${custom_css}.tmp"
        else
            grep -vF "${import_line}" "${custom_css}" > "${custom_css}.tmp" || true
        fi
        mv "${custom_css}.tmp" "${custom_css}"
        echo "Removed import from custom.css"
    fi
    for target in "${data_dir}/source-zettlr.css" "${data_dir}/source"; do
        if [[ -L "${target}" ]]; then
            rm "${target}"
            echo "Removed link $(basename "${target}")"
        fi
    done
}

main() {
    if [[ ! -d "${data_dir}" ]]; then
        echo "Error: Zettlr data folder not found: ${data_dir}" >&2
        exit 1
    fi
    case "${1:-}" in
        "") install_theme ;;
        --uninstall) uninstall_theme ;;
        *)
            echo "Usage: $(basename "$0") [--uninstall]" >&2
            exit 2
            ;;
    esac
}

main "$@"
