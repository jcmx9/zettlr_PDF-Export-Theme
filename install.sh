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
# Sets up, for every app that is installed:
#   Zettlr  – editor theme, PDF export profile "Source PDF", snippet "protokoll"
#   Typora  – themes Source, Source Dark, Source Compact, Source Dark Compact
# Typst is downloaded into the installer's own folder; no admin rights needed.
set -euo pipefail

readonly REPO="jcmx9/zettlr_PDF-Export-Theme"
readonly BUNDLE="zettlr-pdf-export-theme"
readonly TYPST_VERSION="0.15.0"
readonly IMPORT_LINE='@import url("source-zettlr.css");'
readonly PROFILE_NAME="Source PDF.yaml"
readonly PROFILE_MARKER="zettlr_PDF-Export-Theme installer"
readonly SNIPPET_NAME="protokoll.tpl.md"
readonly TYPORA_THEMES="source.css source-dark.css source-compact.css source-dark-compact.css"

readonly APP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/zettlr-pdf-export-theme"
readonly CURRENT="${APP_DIR}/current"
readonly TYPST_BIN="${APP_DIR}/bin/typst"

OS=""
ARCH=""
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
    case "$(uname -m)" in
        x86_64 | amd64) ARCH="x86_64" ;;
        arm64 | aarch64) ARCH="aarch64" ;;
        *) die "unsupported processor: $(uname -m)" ;;
    esac
}

# Zettlr keeps custom.css, export profiles and snippets in its data folder.
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

typora_dir() {
    local dir
    if [[ "${OS}" == "macos" ]]; then
        dir="${HOME}/Library/Application Support/abnerworks.Typora/themes"
    else
        dir="${XDG_CONFIG_HOME:-${HOME}/.config}/Typora/themes"
    fi
    if [[ -d "${dir}" ]]; then
        printf '%s\n' "${dir}"
    fi
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
    rm -rf "${CURRENT}.old"
    if [[ "${old}" == "${new}" ]]; then
        info "Version ${new} (reinstalled)"
    else
        info "Version ${old} -> ${new}"
    fi
}

ensure_typst() {
    if [[ -x "${TYPST_BIN}" ]] && "${TYPST_BIN}" --version 2>/dev/null | grep -q "typst ${TYPST_VERSION}"; then
        return
    fi
    local target
    if [[ "${OS}" == "macos" ]]; then
        target="${ARCH}-apple-darwin"
    else
        target="${ARCH}-unknown-linux-musl"
        need xz
    fi
    info "Downloading Typst ${TYPST_VERSION} …"
    local archive="${TMP_DIR}/typst.tar.xz"
    download "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${target}.tar.xz" "${archive}"
    tar -xJf "${archive}" -C "${TMP_DIR}"
    mkdir -p "$(dirname "${TYPST_BIN}")"
    mv "${TMP_DIR}/typst-${target}/typst" "${TYPST_BIN}"
    chmod +x "${TYPST_BIN}"
}

# --- Zettlr -------------------------------------------------------------------

add_import() {
    local css="$1"
    if [[ ! -f "${css}" ]]; then
        printf '%s\n' "${IMPORT_LINE}" > "${css}"
    elif ! grep -qF "${IMPORT_LINE}" "${css}"; then
        backup "${css}"
        # @import must come before all other rules
        { printf '%s\n\n' "${IMPORT_LINE}"; cat "${css}"; } > "${css}.tmp"
        mv "${css}.tmp" "${css}"
    fi
}

remove_import() {
    local css="$1"
    if [[ -f "${css}" ]] && grep -qF "${IMPORT_LINE}" "${css}"; then
        backup "${css}"
        if [[ "$(head -n 2 "${css}")" == "${IMPORT_LINE}" ]]; then
            # Exactly what add_import wrote: import line plus one blank line
            tail -n +3 "${css}" > "${css}.tmp"
        else
            grep -vF "${IMPORT_LINE}" "${css}" > "${css}.tmp" || true
        fi
        mv "${css}.tmp" "${css}"
    fi
}

write_profile() {
    local dir="$1" template content
    template="$(cat "${CURRENT}/zettlr/Source PDF.yaml.in")"
    # Paths go into single-quoted YAML strings, where ' is written as ''
    local q="'" typst_path dir_path
    typst_path="${TYPST_BIN//${q}/${q}${q}}"
    dir_path="${CURRENT//${q}/${q}${q}}"
    content="${template//@TYPST@/${typst_path}}"
    content="${content//@DIR@/${dir_path}}"
    mkdir -p "${dir}/defaults"
    printf '%s\n' "${content}" > "${dir}/defaults/${PROFILE_NAME}"
}

remove_legacy() {
    local dir="$1"
    # Development setups linked these into the data folder
    if [[ -L "${dir}/source" ]]; then
        rm "${dir}/source"
    fi
    local legacy="${dir}/defaults/Source PDF (Typst).yaml"
    if [[ -f "${legacy}" ]] && grep -q "install-zettlr.sh" "${legacy}"; then
        rm "${legacy}"
    fi
}

setup_zettlr() {
    local dir="$1"
    info "Zettlr: ${dir}"
    remove_legacy "${dir}"
    rm -f "${dir}/source-zettlr.css" "${dir}/source-zettlr-fonts.css"
    cp "${CURRENT}/zettlr/source-zettlr.css" "${dir}/source-zettlr.css"
    cp "${CURRENT}/source/fonts-embedded.css" "${dir}/source-zettlr-fonts.css"
    add_import "${dir}/custom.css"
    write_profile "${dir}"
    mkdir -p "${dir}/snippets"
    rm -f "${dir}/snippets/${SNIPPET_NAME}"
    cp "${CURRENT}/zettlr/snippets/${SNIPPET_NAME}" "${dir}/snippets/${SNIPPET_NAME}"
    info "  theme, export profile \"Source PDF\" and snippet \"protokoll\" installed"
}

remove_zettlr() {
    local dir="$1"
    info "Zettlr: ${dir}"
    remove_import "${dir}/custom.css"
    rm -f "${dir}/source-zettlr.css" "${dir}/source-zettlr-fonts.css"
    local profile="${dir}/defaults/${PROFILE_NAME}"
    if [[ -f "${profile}" ]] && grep -q "${PROFILE_MARKER}" "${profile}"; then
        rm "${profile}"
    fi
    local snippet="${dir}/snippets/${SNIPPET_NAME}"
    if [[ -f "${snippet}" && -f "${CURRENT}/zettlr/snippets/${SNIPPET_NAME}" ]] &&
        cmp -s "${snippet}" "${CURRENT}/zettlr/snippets/${SNIPPET_NAME}"; then
        rm "${snippet}"
    elif [[ -e "${snippet}" ]]; then
        warn "kept ${snippet} (changed or unknown)"
    fi
    info "  removed"
}

# --- Typora -------------------------------------------------------------------

setup_typora() {
    local dir="$1" theme
    info "Typora: ${dir}"
    for theme in ${TYPORA_THEMES}; do
        rm -f "${dir}/${theme}"
        cp "${CURRENT}/${theme}" "${dir}/${theme}"
    done
    if [[ -L "${dir}/source" ]]; then
        rm "${dir}/source"
    fi
    rm -rf "${dir}/source/fonts"
    mkdir -p "${dir}/source"
    cp "${CURRENT}/source/fonts.css" "${dir}/source/fonts.css"
    cp -R "${CURRENT}/source/fonts" "${dir}/source/fonts"
    info "  themes Source, Source Dark, Source Compact, Source Dark Compact installed"
}

remove_typora() {
    local dir="$1" theme
    info "Typora: ${dir}"
    for theme in ${TYPORA_THEMES}; do
        rm -f "${dir}/${theme}"
    done
    if [[ -L "${dir}/source" ]]; then
        rm "${dir}/source"
    elif [[ -f "${dir}/source/fonts.css" ]] && grep -q "scripts/fetch_fonts.py" "${dir}/source/fonts.css"; then
        rm -rf "${dir}/source"
    fi
    info "  removed"
}

# --- Main ---------------------------------------------------------------------

install_all() {
    need curl
    need tar
    TMP_DIR="$(mktemp -d)"
    fetch_bundle
    ensure_typst

    local found=0 dir
    while IFS= read -r dir; do
        [[ -n "${dir}" ]] || continue
        setup_zettlr "${dir}"
        found=1
    done <<EOF
$(zettlr_dirs)
EOF
    dir="$(typora_dir)"
    if [[ -n "${dir}" ]]; then
        setup_typora "${dir}"
        found=1
    fi
    if [[ "${found}" -eq 0 ]]; then
        warn "neither Zettlr nor Typora found; start Zettlr once, then run this again"
    fi

    info ""
    info "Done. Restart Zettlr, then:"
    info "  - new meeting note: type :protokoll"
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
    dir="$(typora_dir)"
    if [[ -n "${dir}" ]]; then
        remove_typora "${dir}"
    fi
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
                sed -n '2,17p' "$0" 2>/dev/null || true
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
