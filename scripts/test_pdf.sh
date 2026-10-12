#!/usr/bin/env bash
# End-to-end test of the PDF export: renders tests/fixtures/*.md the way
# Zettlr does (Pandoc with the export profile, working directory = the note's
# folder) and checks the text of the resulting PDFs.
#
# Usage: scripts/test_pdf.sh [profile.yaml]
#   Without an argument the profile is built from the repository, using the
#   typst binary on PATH (or $TYPST). With an argument, e.g. the profile the
#   installer wrote, that profile is tested as installed.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_dir
readonly fixtures="${repo_dir}/tests/fixtures"
out_dir=""

cleanup() {
    if [[ -n "${out_dir}" ]]; then
        rm -rf "${out_dir}"
    fi
}
trap cleanup EXIT

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

pdf_text() {
    if command -v pdftotext >/dev/null 2>&1; then
        pdftotext -layout "$1" -
    elif command -v mutool >/dev/null 2>&1; then
        mutool draw -q -F txt "$1"
    else
        die "pdftotext (poppler) or mutool (mupdf) is required"
    fi
}

build_profile() {
    local typst="${TYPST:-$(command -v typst || true)}"
    [[ -n "${typst}" ]] || die "typst not found; set TYPST or add it to PATH"
    local content
    content="$(cat "${repo_dir}/zettlr/Source PDF.yaml.in")"
    content="${content//@TYPST@/${typst}}"
    content="${content//@DIR@/${repo_dir}}"
    content="${content//@ROOT@//}"
    printf '%s\n' "${content}" > "${out_dir}/profile.yaml"
    printf '%s\n' "${out_dir}/profile.yaml"
}

# render <fixture> <profile>: prints the PDF's text
render() {
    local name="$1" profile="$2" pdf="${out_dir}/${1%.md}.pdf"
    (cd "${fixtures}" && pandoc -d "${profile}" "${name}" -o "${pdf}") ||
        die "${name}: export failed"
    [[ -s "${pdf}" ]] || die "${name}: empty PDF"
    grep -aq 'pdfaid:part' "${pdf}" || die "${name}: no PDF/A metadata"
    pdf_text "${pdf}"
}

# expect <name> <text> <string>...: every string must occur in the text
expect() {
    local name="$1" text="$2" s
    shift 2
    for s in "$@"; do
        grep -qF -- "${s}" <<<"${text}" || die "${name}: missing \"${s}\""
    done
}

reject() {
    local name="$1" text="$2" s
    shift 2
    for s in "$@"; do
        if grep -qF -- "${s}" <<<"${text}"; then
            die "${name}: unexpected \"${s}\""
        fi
    done
}

main() {
    out_dir="$(mktemp -d)"
    local profile="${1:-}"
    if [[ -z "${profile}" ]]; then
        profile="$(build_profile)"
    fi

    local text
    text="$(render all-elements.md "${profile}")"
    expect all-elements.md "${text}" \
        "MUSTER GMBH" "Source – Elementtest" "Testdokument mit allen Elementen" \
        "INFO" "HINWEIS" "Deutsches Schlüsselwort" \
        "Screenshot aus dem Termin" "Kick-off" "Konzept ok?" \
        "Aufgabe" "Wer" "Bis" "Status" "Ben Probe" "15.10." \
        "Ohne Zuständigkeit bleibt es eine Liste" \
        "Nächster Termin:" "24.10.2026, 10:00 Uhr" \
        "Seite 1 /" "Muster GmbH · Source – Elementtest"
    # Typographic quotes must survive unchanged
    # shellcheck disable=SC1111,SC1112
    expect all-elements.md "${text}" '„Deutsche Anführungszeichen“' '‚einfache‘'
    reject all-elements.md "${text}" "\\newpage" "[!HINWEIS]" "flowchart LR" "– jcmx9"
    # The long table continues on page 3 with its header repeated
    local page3
    page3="$(awk 'BEGIN { RS = "\f" } NR == 3' <<<"${text}")"
    expect "all-elements.md page 3" "${page3}" "Position" "Betrag"
    echo "ok   all-elements.md"

    text="$(render english.md "${profile}")"
    expect english.md "${text}" "NOTE" "Task" "Owner" "Due" "17 Oct" "Next meeting:" "Page 1 /"
    reject english.md "${text}" "Seite" "Nächster"
    echo "ok   english.md"

    # Notes written in a hurry must never break the export
    text="$(render edge-cases.md "${profile}")"
    expect edge-cases.md "${text}" "Notiz ohne Titel" "leer links" "Aufgabe ohne alles"
    echo "ok   edge-cases.md"

    # Empty front matter fields (e.g. from the kopfdaten snippet) are ignored
    text="$(render empty-fields.md "${profile}")"
    expect empty-fields.md "${text}" "Leere Kopfdaten" "Alle optionalen Felder sind leer."
    reject empty-fields.md "${text}" "Nächster Termin"
    echo "ok   empty-fields.md"

    # Snippets with their placeholders filled in must export as well
    local snippet name
    # shellcheck disable=SC2016 # literal $ placeholders
    for snippet in "${repo_dir}"/zettlr/snippets/*.tpl.md; do
        name="snippet-$(basename "${snippet}" .tpl.md).md"
        sed -E -e 's/\$\{[0-9]+:([^}]*)\}/\1/g' -e 's/\$[0-9]+//g' \
            -e 's/\$CURRENT_DATE/12/; s/\$CURRENT_MONTH/10/; s/\$CURRENT_YEAR/2026/' \
            "${snippet}" > "${fixtures}/${name}"
        text="$(render "${name}" "${profile}")" || { rm -f "${fixtures}/${name}"; exit 1; }
        rm -f "${fixtures}/${name}"
        expect "${name}" "${text}" "12.10.2026" "Seite 1 /"
        reject "${name}" "${text}" '${' '$CURRENT'
        echo "ok   ${name}"
    done
}

main "$@"
