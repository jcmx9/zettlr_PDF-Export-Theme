<#
zettlr_rfdoc-Export installer for Windows (PowerShell 5.1 or later, no admin rights).

Install or update (run the same line again to update):
  irm https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.ps1 | iex

Uninstall:
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/jcmx9/zettlr_rfdoc-Export/main/install.ps1))) -Uninstall

Sets up Zettlr: the export profile "rf-doc", which hands the note to
rf-document (real-fast-document) for the PDF, an editor theme that mirrors
rf-document's layout (with rf-document's own fonts) and the snippets
meeting, telefonnotiz, aufgabe, newpage and header (rf-document's
header.md). rf-document is installed separately:
https://github.com/jcmx9/real-fast-document
#>
param(
    [switch]$Uninstall,
    # Install from a local bundle (scripts/package.sh) instead of the latest release
    [string]$Bundle = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = "jcmx9/zettlr_rfdoc-Export"
$BundleName = "zettlr-rfdoc-export"
$ProfileName = "rf-doc.yaml"
$ImportLine = '@import url("rfdoc-zettlr.css");'
$ProfileMarker = "zettlr_rfdoc-Export installer"

$AppDir = Join-Path $env:LOCALAPPDATA "zettlr-rfdoc-export"
$Current = Join-Path $AppDir "current"
$ZettlrDir = Join-Path $env:APPDATA "zettlr"
# rf-document's installation folder: fonts and header.md come from there
$RfdHome = Join-Path $env:LOCALAPPDATA "real-fast-document"

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Text([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, $Utf8NoBom)
}

function Read-Text([string]$Path) {
    return [IO.File]::ReadAllText($Path)
}

function Backup-File([string]$Path) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $target = "$Path.$stamp.bak"
    $n = 1
    while (Test-Path -LiteralPath $target) {
        $target = "$Path.$stamp-$n.bak"
        $n++
    }
    Copy-Item -LiteralPath $Path -Destination $target
    Write-Host "  backup: $(Split-Path $target -Leaf)"
}

function Get-File([string]$Url, [string]$Path) {
    Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing
}

# --- Bundle -------------------------------------------------------------------

function Install-Bundle([string]$Temp) {
    $archive = Join-Path $Temp "$BundleName.zip"
    if ($Bundle) {
        if (-not (Test-Path -LiteralPath $Bundle)) { throw "bundle not found: $Bundle" }
        Copy-Item -LiteralPath $Bundle -Destination $archive
    }
    else {
        $base = "https://github.com/$Repo/releases/latest/download/$BundleName.zip"
        Write-Host "Downloading the latest release ..."
        Get-File $base $archive
        Get-File "$base.sha256" "$archive.sha256"
        $expected = ((Get-Content -LiteralPath "$archive.sha256" -Raw).Trim() -split "\s+")[0]
        $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
        if ($expected -ne $actual.ToLower()) { throw "checksum mismatch for $BundleName.zip" }
    }

    $extracted = Join-Path $Temp "bundle"
    Expand-Archive -LiteralPath $archive -DestinationPath $extracted -Force
    $versionFile = Join-Path $extracted "VERSION"
    if (-not (Test-Path -LiteralPath $versionFile)) { throw "invalid bundle: VERSION missing" }

    $new = (Get-Content -LiteralPath $versionFile -Raw).Trim()
    $old = "none"
    if (Test-Path -LiteralPath (Join-Path $Current "VERSION")) {
        $old = (Get-Content -LiteralPath (Join-Path $Current "VERSION") -Raw).Trim()
    }
    New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
    # The previous version stays in current.old until setup is done, so files
    # it installed can be told apart from the user's own
    if (Test-Path -LiteralPath "$Current.old") { Remove-Item -LiteralPath "$Current.old" -Recurse -Force }
    if (Test-Path -LiteralPath $Current) { Move-Item -LiteralPath $Current -Destination "$Current.old" }
    Move-Item -LiteralPath $extracted -Destination $Current
    if ($old -eq $new) { Write-Host "Version $new (reinstalled)" } else { Write-Host "Version $old -> $new" }
}

# rf-document's command, as GUI apps such as Zettlr may not find it on PATH
function Find-RfDocument {
    $command = Get-Command "rf-document" -ErrorAction SilentlyContinue | Select-Object -First 1
    $candidates = @()
    if ($command) { $candidates += $command.Source }
    $candidates += [IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft", "WindowsApps", "rf-document.cmd")
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    return $null
}

# Write rf-document's path into the filter; the filter also searches itself
function Set-FilterPath {
    $filter = [IO.Path]::Combine($Current, "zettlr", "rf-document.lua")
    $path = Find-RfDocument
    if (-not $path) {
        Write-Warning "rf-document not found; install it before exporting: https://github.com/jcmx9/real-fast-document"
        return
    }
    # Lua string literal: escape backslashes and double quotes
    $escaped = $path.Replace("\", "\\").Replace('"', '\"')
    Write-Text $filter ((Read-Text $filter).Replace("@RFD@", $escaped))
    Write-Host "rf-document: $path"
}

# --- Zettlr -------------------------------------------------------------------

# @font-face with the font file embedded (Zettlr cannot load fonts by URL)
function Get-FontFace([string]$Family, [string]$Style, [string]$Weight, [string]$File) {
    if (-not (Test-Path -LiteralPath $File)) { return "" }
    $mime, $format = if ($File.EndsWith(".otf")) { "font/otf", "opentype" } else { "font/ttf", "truetype" }
    $data = [Convert]::ToBase64String([IO.File]::ReadAllBytes($File))
    return "@font-face {`n    font-family: `"$Family`";`n    font-style: $Style;`n    font-weight: $Weight;`n    font-display: swap;`n    src: url(`"data:$mime;base64,$data`") format(`"$format`");`n}`n`n"
}

# The editor theme's fonts: rf-document's own files, so both always match
function Write-FontsCss([string]$Out) {
    $fonts = Join-Path $RfdHome "fonts"
    if (-not (Test-Path -LiteralPath $fonts)) {
        Write-Warning "rf-document's fonts not found in $fonts; the editor uses fallback fonts"
        Write-Text $Out "/* rf-document fonts not found when installing */`n"
        return
    }
    $css = New-Object System.Text.StringBuilder
    [void]$css.Append("/* Generated by the zettlr_rfdoc-Export installer from rf-document's fonts. */`n`n")
    [void]$css.Append((Get-FontFace "rfdoc Sans" "normal" "200 900" (Join-Path $fonts "SourceSans3VF-Upright.otf")))
    [void]$css.Append((Get-FontFace "rfdoc Sans" "italic" "200 900" (Join-Path $fonts "SourceSans3VF-Italic.otf")))
    [void]$css.Append((Get-FontFace "rfdoc Serif" "normal" "200 900" (Join-Path $fonts "SourceSerif4Variable-Roman.otf")))
    [void]$css.Append((Get-FontFace "rfdoc Serif" "italic" "200 900" (Join-Path $fonts "SourceSerif4Variable-Italic.otf")))
    [void]$css.Append((Get-FontFace "rfdoc Code" "normal" "200 900" (Join-Path $fonts "SourceCodeVF-Upright.otf")))
    [void]$css.Append((Get-FontFace "rfdoc Code" "italic" "200 900" (Join-Path $fonts "SourceCodeVF-Italic.otf")))
    [void]$css.Append((Get-FontFace "rfdoc Emoji" "normal" "300 700" (Join-Path $fonts "NotoEmoji[wght].ttf")))
    Write-Text $Out $css.ToString()
}

# The header snippet is rf-document's header.md, so it always lists the
# front matter keys of the installed rf-document
function Write-HeaderSnippet {
    $header = Join-Path $RfdHome "header.md"
    if (Test-Path -LiteralPath $header) {
        Copy-Item -LiteralPath $header -Destination ([IO.Path]::Combine($Current, "zettlr", "snippets", "header.tpl.md")) -Force
    }
    else {
        Write-Warning "rf-document's header.md not found; no header snippet"
    }
}

function Add-Import([string]$Css) {
    if (-not (Test-Path -LiteralPath $Css)) {
        Write-Text $Css "$ImportLine`n"
        return
    }
    $text = Read-Text $Css
    if ($text.Contains($ImportLine)) { return }
    Backup-File $Css
    # @import must come before all other rules
    Write-Text $Css "$ImportLine`n`n$text"
}

function Remove-Import([string]$Css) {
    if (-not (Test-Path -LiteralPath $Css)) { return }
    $text = Read-Text $Css
    if (-not $text.Contains($ImportLine)) { return }
    Backup-File $Css
    foreach ($prefix in @("$ImportLine`n`n", "$ImportLine`r`n`r`n")) {
        if ($text.StartsWith($prefix)) {
            Write-Text $Css $text.Substring($prefix.Length)
            return
        }
    }
    $lines = $text -split "`r?`n" | Where-Object { $_ -ne $ImportLine }
    Write-Text $Css ($lines -join "`n")
}

function Convert-YamlPath([string]$Path) {
    # Forward slashes work for Pandoc; ' is escaped for single-quoted YAML
    return $Path.Replace("\", "/").Replace("'", "''")
}

function Install-Zettlr {
    Write-Host "Zettlr: $ZettlrDir"
    Copy-Item -LiteralPath ([IO.Path]::Combine($Current, "zettlr", "rfdoc-zettlr.css")) -Destination (Join-Path $ZettlrDir "rfdoc-zettlr.css") -Force
    Write-FontsCss (Join-Path $ZettlrDir "rfdoc-zettlr-fonts.css")
    Add-Import (Join-Path $ZettlrDir "custom.css")

    $template = Read-Text ([IO.Path]::Combine($Current, "zettlr", "rf-doc.yaml.in"))
    $content = $template.Replace("@DIR@", (Convert-YamlPath $Current))
    $defaults = Join-Path $ZettlrDir "defaults"
    New-Item -ItemType Directory -Force -Path $defaults | Out-Null
    Write-Text (Join-Path $defaults $ProfileName) $content

    $snippets = Join-Path $ZettlrDir "snippets"
    New-Item -ItemType Directory -Force -Path $snippets | Out-Null
    # Every snippet the bundle ships, so installer and bundle never disagree
    foreach ($file in Get-ChildItem -LiteralPath ([IO.Path]::Combine($Current, "zettlr", "snippets")) -Filter "*.tpl.md") {
        $name = $file.Name.Substring(0, $file.Name.Length - ".tpl.md".Length)
        $source = $file.FullName
        $target = Join-Path $snippets $file.Name
        # Keep a copy of a snippet with this name that is not one of ours
        $previous = ([IO.Path]::Combine("$Current.old", "zettlr", "snippets", "$name.tpl.md"))
        if ((Test-Path -LiteralPath $target) -and ((Read-Text $target) -ne (Read-Text $source)) -and
            -not ((Test-Path -LiteralPath $previous) -and ((Read-Text $target) -eq (Read-Text $previous)))) {
            Backup-File $target
        }
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
    # Snippets an earlier version installed but this one no longer ships:
    # remove them unless the user changed them
    $oldSnippets = ([IO.Path]::Combine("$Current.old", "zettlr", "snippets"))
    if (Test-Path -LiteralPath $oldSnippets) {
        foreach ($old in Get-ChildItem -LiteralPath $oldSnippets -Filter "*.tpl.md") {
            $target = Join-Path $snippets $old.Name
            $stillShipped = Test-Path -LiteralPath ([IO.Path]::Combine($Current, "zettlr", "snippets", $old.Name))
            if (-not $stillShipped -and (Test-Path -LiteralPath $target)) {
                if ((Read-Text $target) -eq (Read-Text $old.FullName)) {
                    Remove-Item -LiteralPath $target -Force
                }
                else {
                    Write-Warning "kept $target (changed; no longer shipped)"
                }
            }
        }
    }
    Write-Host '  editor theme, export profile "rf-doc" and snippets installed'
}

function Uninstall-Zettlr {
    Write-Host "Zettlr: $ZettlrDir"
    Remove-Import (Join-Path $ZettlrDir "custom.css")
    foreach ($file in @("rfdoc-zettlr.css", "rfdoc-zettlr-fonts.css")) {
        Remove-Item -LiteralPath (Join-Path $ZettlrDir $file) -Force -ErrorAction SilentlyContinue
    }
    $profilePath = ([IO.Path]::Combine($ZettlrDir, "defaults", $ProfileName))
    if ((Test-Path -LiteralPath $profilePath) -and (Read-Text $profilePath).Contains($ProfileMarker)) {
        Remove-Item -LiteralPath $profilePath -Force
    }
    $bundled = ([IO.Path]::Combine($Current, "zettlr", "snippets"))
    $ourSnippets = if (Test-Path -LiteralPath $bundled) { Get-ChildItem -LiteralPath $bundled -Filter "*.tpl.md" } else { @() }
    foreach ($file in $ourSnippets) {
        $snippet = ([IO.Path]::Combine($ZettlrDir, "snippets", $file.Name))
        $ours = $file.FullName
        if ((Test-Path -LiteralPath $snippet) -and ((Read-Text $snippet) -eq (Read-Text $ours))) {
            Remove-Item -LiteralPath $snippet -Force
        }
        elseif (Test-Path -LiteralPath $snippet) {
            Write-Warning "kept $snippet (changed or unknown)"
        }
    }
    Write-Host "  removed"
}

# --- Main ---------------------------------------------------------------------

if ($Uninstall) {
    if (Test-Path -LiteralPath $ZettlrDir) { Uninstall-Zettlr }
    if (Test-Path -LiteralPath $AppDir) { Remove-Item -LiteralPath $AppDir -Recurse -Force }
    Write-Host "Uninstalled."
    return
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ("$BundleName-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    Install-Bundle $temp
    Set-FilterPath
    Write-HeaderSnippet
    $found = $false
    if (Test-Path -LiteralPath $ZettlrDir) { Install-Zettlr; $found = $true }
    if (-not $found) {
        Write-Warning "Zettlr not found; start Zettlr once, then run this again"
    }
    Write-Host ""
    Write-Host "Done. Restart Zettlr, then:"
    Write-Host "  - new meeting note: type :meeting"
    Write-Host '  - PDF: File > Export, profile "rf-doc"'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "$Current.old" -Recurse -Force -ErrorAction SilentlyContinue
}
