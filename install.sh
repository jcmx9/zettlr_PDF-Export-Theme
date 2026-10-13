#!/usr/bin/env bash
# zettlr_PDF-Export-Theme installer for macOS and Linux.
#
# Install or update (run the same line again to update):
#   curl -fsSL https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.sh | bash
#
# Options (when piping, pass them after "bash -s --"):
#   --uninstall        remove everything this installer added
#   --bundle <file>    install from a local bundle (scripts/package.sh) instead
#                      of the latest GitHub release
#
# Sets up Zettlr: the export profile "Source PDF", which hands the note to
# rf-document (real-fast-document) for the PDF, and the snippets meeting,
# telefonnotiz, aufgabe, newpage and header. rf-document is installed
# separately: https://github.com/jcmx9/real-fast-document
set -euo pipefail
# bash 5.2 would treat & in ${var//pattern/replacement} as the match
shopt -u patsub_replacement 2>/dev/null || true

readonly REPO="jcmx9/zettlr_PDF-Export-Theme"
readonly BUNDLE="zettlr-pdf-export-theme"
readonly PROFILE_NAME="Source PDF.yaml"
readonly PROFILE_MARKER="zettlr_PDF-Export-Theme installer"

readonly APP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/zettlr-pdf-export-theme"
readonly CURRENT="${APP_DIR}/current"

OS=""
TMP_DIR=""
BUNDLE_FILE=""

info() { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "${TMP_DIR}" ]]; then
        rm -rf "${TMP_DIR}"
    fi
}
trap cleanup EXIT

need() {
    command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not installed"
}

download() {
    curl -fsSL --retry 3 -o "$2" "$1" || die "download failed: $1"
}

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d ' ' -f 1
    else
        shasum -a 256 "$1" | cut -d ' ' -f 1
    fi
}

detect_platform() {
    case "$(uname -s)" in
        Darwin) OS="macos" ;;
        Linux) OS="linux" ;;
        *) die "unsupported system: $(uname -s) (use install.ps1 on Windows)" ;;
    esac
}

# Zettlr keeps export profiles and snippets in its data folder.
zettlr_dirs() {
    local candidates
    if [[ "${OS}" == "macos" ]]; then
        candidates="${HOME}/Library/Application Support/zettlr"
    else
        local config="${XDG_CONFIG_HOME:-${HOME}/.config}"
        candidates="${config}/zettlr
${config}/Zettlr
${HOME}/.var/app/com.zettlr.Zettlr/config/zettlr"
    fi
    printf '%s\n' "${candidates}" | while IFS= read -r dir; do
        if [[ -d "${dir}" ]]; then
            printf '%s\n' "${dir}"
        fi
    done
}

backup() {
    local file="$1" stamp target n=1
    stamp="$(date +%Y%m%d-%H%M%S)"
    target="${file}.${stamp}.bak"
    while [[ -e "${target}" ]]; do
        target="${file}.${stamp}-${n}.bak"
        n=$((n + 1))
    done
    cp "${file}" "${target}"
    info "  backup: $(basename "${target}")"
}

# --- Bundle -------------------------------------------------------------------

fetch_bundle() {
    local archive="${TMP_DIR}/${BUNDLE}.tar.gz"
    if [[ -n "${BUNDLE_FILE}" ]]; then
        [[ -f "${BUNDLE_FILE}" ]] || die "bundle not found: ${BUNDLE_FILE}"
        cp "${BUNDLE_FILE}" "${archive}"
    else
        local base="https://github.com/${REPO}/releases/latest/download/${BUNDLE}.tar.gz"
        info "Downloading the latest release …"
        download "${base}" "${archive}"
        download "${base}.sha256" "${archive}.sha256"
        local expected actual
        expected="$(cut -d ' ' -f 1 < "${archive}.sha256")"
        actual="$(sha256_of "${archive}")"
        [[ "${expected}" == "${actual}" ]] || die "checksum mismatch for ${BUNDLE}.tar.gz"
    fi

    mkdir -p "${TMP_DIR}/bundle"
    tar -xzf "${archive}" -C "${TMP_DIR}/bundle"
    [[ -f "${TMP_DIR}/bundle/VERSION" ]] || die "invalid bundle: VERSION missing"

    local old="none" new
    new="$(cat "${TMP_DIR}/bundle/VERSION")"
    if [[ -f "${CURRENT}/VERSION" ]]; then
        old="$(cat "${CURRENT}/VERSION")"
    fi
    mkdir -p "${APP_DIR}"
    rm -rf "${CURRENT}.old"
    if [[ -d "${CURRENT}" ]]; then
        mv "${CURRENT}" "${CURRENT}.old"
    fi
    mv "${TMP_DIR}/bundle" "${CURRENT}"
    # The previous version stays in current.old until setup is done, so files
    # it installed can be told apart from the user's own
    if [[ "${old}" == "${new}" ]]; then
        info "Version ${new} (reinstalled)"
    else
        info "Version ${old} -> ${new}"
    fi
}

# rf-document's command, as GUI apps such as Zettlr may not find it on PATH
find_rf_document() {
    local candidate
    for candidate in "$(command -v rf-document 2>/dev/null || true)" \
        "${HOME}/.local/bin/rf-document" /opt/homebrew/bin/rf-document /usr/local/bin/rf-document; do
        if [[ -n "${candidate}" && -x "${candidate}" ]]; then
            printf '%s\n' "${candidate}"
            return
        fi
    done
}

# --- Zettlr -------------------------------------------------------------------

write_profile() {
    local dir="$1" template content
    template="$(cat "${CURRENT}/zettlr/Source PDF.yaml.in")"
    # The path goes into a single-quoted YAML string, where ' is written as ''
    local q="'" dir_path
    dir_path="${CURRENT//${q}/${q}${q}}"
    content="${template//@DIR@/${dir_path}}"
    mkdir -p "${dir}/defaults"
    printf '%s\n' "${content}" > "${dir}/defaults/${PROFILE_NAME}"
}

# Write rf-document's path into the filter; the filter also searches itself
configure_filter() {
    local filter="${CURRENT}/zettlr/rf-document.lua" path
    path="$(find_rf_document)"
    if [[ -z "${path}" ]]; then
        warn "rf-document not found; install it before exporting: https://github.com/jcmx9/real-fast-document"
        return
    fi
    # Lua string literal: escape backslashes and double quotes
    path="${path//\\/\\\\}"
    path="${path//\"/\\\"}"
    local content
    content="$(cat "${filter}")"
    printf '%s\n' "${content//@RFD@/${path}}" > "${filter}"
    info "rf-document: ${path}"
}

setup_zettlr() {
    local dir="$1"
    info "Zettlr: ${dir}"
    write_profile "${dir}"
    mkdir -p "${dir}/snippets"
    local name target source
    # Every snippet the bundle ships, so installer and bundle never disagree
    for source in "${CURRENT}"/zettlr/snippets/*.tpl.md; do
        name="$(basename "${source}" .tpl.md)"
        target="${dir}/snippets/${name}.tpl.md"
        # Keep a copy of a snippet with this name that is not one of ours
        if [[ -f "${target}" ]] && ! cmp -s "${target}" "${source}" &&
            ! cmp -s "${target}" "${CURRENT}.old/zettlr/snippets/${name}.tpl.md"; then
            backup "${target}"
        fi
        rm -f "${target}"
        cp "${source}" "${target}"
    done
    # Snippets an earlier version installed but this one no longer ships:
    # remove them unless the user changed them
    local old
    for old in "${CURRENT}.old"/zettlr/snippets/*.tpl.md; do
        [[ -f "${old}" ]] || continue
        name="$(basename "${old}")"
        target="${dir}/snippets/${name}"
        if [[ ! -f "${CURRENT}/zettlr/snippets/${name}" && -f "${target}" ]]; then
            if cmp -s "${target}" "${old}"; then
                rm "${target}"
            else
                warn "kept ${target} (changed; no longer shipped)"
            fi
        fi
    done
    info "  export profile \"Source PDF\" and snippets installed"
}

remove_zettlr() {
    local dir="$1"
    info "Zettlr: ${dir}"
    local profile="${dir}/defaults/${PROFILE_NAME}"
    if [[ -f "${profile}" ]] && grep -q "${PROFILE_MARKER}" "${profile}"; then
        rm "${profile}"
    fi
    local ours snippet
    for ours in "${CURRENT}"/zettlr/snippets/*.tpl.md; do
        [[ -f "${ours}" ]] || continue
        snippet="${dir}/snippets/$(basename "${ours}")"
        if [[ -f "${snippet}" ]] && cmp -s "${snippet}" "${ours}"; then
            rm "${snippet}"
        elif [[ -e "${snippet}" ]]; then
            warn "kept ${snippet} (changed or unknown)"
        fi
    done
    info "  removed"
}

# --- Main ---------------------------------------------------------------------

install_all() {
    need curl
    need tar
    TMP_DIR="$(mktemp -d)"
    fetch_bundle
    configure_filter

    local found=0 dir
    while IFS= read -r dir; do
        [[ -n "${dir}" ]] || continue
        setup_zettlr "${dir}"
        found=1
    done <<EOF
$(zettlr_dirs)
EOF
    if [[ "${found}" -eq 0 ]]; then
        warn "Zettlr not found; start Zettlr once, then run this again"
    fi
    rm -rf "${CURRENT}.old"

    info ""
    info "Done. Restart Zettlr, then:"
    info "  - new meeting note: type :meeting"
    info "  - PDF: File > Export, profile \"Source PDF\""
}

uninstall_all() {
    local dir
    while IFS= read -r dir; do
        [[ -n "${dir}" ]] || continue
        remove_zettlr "${dir}"
    done <<EOF
$(zettlr_dirs)
EOF
    rm -rf "${APP_DIR}"
    info "Uninstalled."
}

main() {
    local mode="install"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall) mode="uninstall" ;;
            --bundle)
                [[ $# -ge 2 ]] || die "--bundle needs a file"
                BUNDLE_FILE="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
                shift
                ;;
            -h | --help)
                sed -n '2,15p' "$0" 2>/dev/null || true
                exit 0
                ;;
            *) die "unknown option: $1" ;;
        esac
        shift
    done

    detect_platform
    if [[ "${mode}" == "uninstall" ]]; then
        uninstall_all
    else
        install_all
    fi
}

main "$@"
