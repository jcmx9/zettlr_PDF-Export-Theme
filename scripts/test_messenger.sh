#!/usr/bin/env bash
# Tests the export profile as Zettlr runs it: Pandoc in the note's folder with
# the profile, the Lua filter hands the note to rf-document.
#
# Usage: scripts/test_messenger.sh [profile.yaml]
#   Without an argument the profile is built from the repository. A stub
#   stands in for rf-document and records how it was called. If a real
#   rf-document is installed, one export runs through it as well.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_dir
work=""

cleanup() {
    if [[ -n "${work}" ]]; then
        rm -rf "${work}"
    fi
}
trap cleanup EXIT

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

# Pandoc defaults from the repository's template; the filter is
# ${work}/zettlr/rf-document.lua
profile() {
    local q="'" content
    content="$(cat "${repo_dir}/zettlr/rf-doc.yaml.in")"
    printf '%s\n' "${content//@DIR@/${work//${q}/${q}${q}}}" > "${work}/profile.yaml"
}

# filter_with <rf-document path>: the filter as the installer configures it
filter_with() {
    local content
    mkdir -p "${work}/zettlr"
    content="$(cat "${repo_dir}/zettlr/rf-document.lua")"
    printf '%s\n' "${content//@RFD@/$1}" > "${work}/zettlr/rf-document.lua"
}

main() {
    # Physical path: on macOS /var is a symlink to /private/var
    work="$(cd "$(mktemp -d)" && pwd -P)"
    mkdir -p "${work}/Notizen mit Leerzeichen" "${work}/temp" "${work}/out"
    local note_dir="${work}/Notizen mit Leerzeichen"
    printf -- '---\ntitle: "Bote"\n---\n\n# Test\n\nText.\n' > "${note_dir}/notiz.md"

    # Stub: records arguments and environment, writes the PDF, exits with $STUB_EXIT
    cat > "${work}/rf-document" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${STUB_LOG}"
printf 'RFD_NO_OPEN=%s\nRFD_BASE_DIR=%s\nPWD=%s\n' "${RFD_NO_OPEN:-}" "${RFD_BASE_DIR:-}" "${PWD}" >> "${STUB_LOG}"
if [[ "${STUB_EXIT:-0}" -ne 0 ]]; then
    echo "stub: export failed on purpose" >&2
    exit "${STUB_EXIT}"
fi
printf '%%PDF-1.7 stub\n' > "$2"
STUB
    chmod +x "${work}/rf-document"
    export STUB_LOG="${work}/stub.log"

    filter_with "${work}/rf-document"
    if [[ $# -gt 0 ]]; then
        # An installed profile, pointed at the test filter
        sed "s#path: '.*rf-document.lua'#path: '${work}/zettlr/rf-document.lua'#" "$1" > "${work}/profile.yaml"
    else
        profile
    fi

    # 1. Saved note: input in the note's folder
    (cd "${note_dir}" && pandoc -d "${work}/profile.yaml" notiz.md -o "${work}/out/notiz.pdf") ||
        die "export of a saved note failed"
    [[ -s "${work}/out/notiz.pdf" ]] || die "no PDF at the target path"
    grep -qx "${note_dir}/notiz.md" "${STUB_LOG}" || die "input path not absolute"
    grep -qx "${work}/out/notiz.pdf" "${STUB_LOG}" || die "output path not passed"
    grep -qx "RFD_NO_OPEN=1" "${STUB_LOG}" || die "RFD_NO_OPEN not set"
    grep -qx "RFD_BASE_DIR=${note_dir}" "${STUB_LOG}" || die "RFD_BASE_DIR is not the note's folder"
    echo "ok   saved note"

    # 2. Unsaved note: Zettlr passes a temporary copy, cwd stays the note's folder
    cp "${note_dir}/notiz.md" "${work}/temp/notiz.md"
    (cd "${note_dir}" && pandoc -d "${work}/profile.yaml" "${work}/temp/notiz.md" -o "${work}/out/temp.pdf") ||
        die "export of a temporary copy failed"
    grep -qx "${work}/temp/notiz.md" "${STUB_LOG}" || die "temporary copy not passed"
    grep -qx "RFD_BASE_DIR=${note_dir}" "${STUB_LOG}" || die "RFD_BASE_DIR lost for a temporary copy"
    echo "ok   unsaved note (temporary copy)"

    # 3. rf-document fails: Pandoc ends with its exit code, the message reaches stderr
    local status=0 err
    err="$(cd "${note_dir}" && STUB_EXIT=3 pandoc -d "${work}/profile.yaml" notiz.md -o "${work}/out/fail.pdf" 2>&1)" || status=$?
    [[ "${status}" -eq 3 ]] || die "exit code ${status} instead of 3"
    grep -q "export failed on purpose" <<<"${err}" || die "rf-document's message not shown"
    echo "ok   failure is passed on"

    # 4. rf-document missing: clear message, no PDF
    filter_with "${work}/gibt-es-nicht"
    status=0
    err="$(cd "${note_dir}" && env PATH="/usr/bin:/bin" HOME="${work}" RF_DOCUMENT= \
        "$(command -v pandoc)" -d "${work}/profile.yaml" notiz.md -o "${work}/out/missing.pdf" 2>&1)" || status=$?
    [[ "${status}" -ne 0 ]] || die "export without rf-document succeeded"
    grep -q "rf-document wurde nicht gefunden" <<<"${err}" || die "no hint when rf-document is missing"
    echo "ok   missing rf-document"

    # 5. Real rf-document, if installed
    local real
    real="$(command -v rf-document || true)"
    if [[ -n "${real}" ]]; then
        filter_with "${real}"
        (cd "${note_dir}" && pandoc -d "${work}/profile.yaml" notiz.md -o "${work}/out/real.pdf" >/dev/null) ||
            die "export through the real rf-document failed"
        head -c 5 "${work}/out/real.pdf" | grep -q '%PDF' || die "rf-document wrote no PDF"
        echo "ok   real rf-document (${real})"
    else
        echo "skip real rf-document (not installed)"
    fi
}

main "$@"
