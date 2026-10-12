<#
zettlr_PDF-Export-Theme installer for Windows (PowerShell 5.1 or later, no admin rights).

Install or update (run the same line again to update):
  irm https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.ps1 | iex

Uninstall:
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/jcmx9/zettlr_PDF-Export-Theme/main/install.ps1))) -Uninstall

Sets up, for every app that is installed:
  Zettlr  - editor theme, PDF export profile "Source PDF", snippet "protokoll"
  Typora  - themes Source, Source Dark, Source Compact, Source Dark Compact
Typst is downloaded into the installer's own folder.
#>
param(
    [switch]$Uninstall,
    # Install from a local bundle (scripts/package.sh) instead of the latest release
    [string]$Bundle = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = "jcmx9/zettlr_PDF-Export-Theme"
$BundleName = "zettlr-pdf-export-theme"
$TypstVersion = "0.15.0"
$ImportLine = '@import url("source-zettlr.css");'
$ProfileName = "Source PDF.yaml"
$ProfileMarker = "zettlr_PDF-Export-Theme installer"
$SnippetName = "protokoll.tpl.md"
$TyporaThemes = @("source.css", "source-dark.css", "source-compact.css", "source-dark-compact.css")

$AppDir = Join-Path $env:LOCALAPPDATA "zettlr-pdf-export-theme"
$Current = Join-Path $AppDir "current"
$TypstExe = ([IO.Path]::Combine($AppDir, "bin", "typst.exe"))
$ZettlrDir = Join-Path $env:APPDATA "zettlr"
$TyporaDir = ([IO.Path]::Combine($env:APPDATA, "Typora", "themes"))

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
    if (Test-Path -LiteralPath $Current) { Remove-Item -LiteralPath $Current -Recurse -Force }
    Move-Item -LiteralPath $extracted -Destination $Current
    if ($old -eq $new) { Write-Host "Version $new (reinstalled)" } else { Write-Host "Version $old -> $new" }
}

function Install-Typst([string]$Temp) {
    if (Test-Path -LiteralPath $TypstExe) {
        try {
            $version = & $TypstExe --version 2>$null
            if ($version -match "typst $([regex]::Escape($TypstVersion))") { return }
        }
        catch {
            Write-Host "  existing Typst could not be started, downloading again"
        }
    }
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
    $target = "$arch-pc-windows-msvc"
    Write-Host "Downloading Typst $TypstVersion ..."
    $archive = Join-Path $Temp "typst.zip"
    Get-File "https://github.com/typst/typst/releases/download/v$TypstVersion/typst-$target.zip" $archive
    $extracted = Join-Path $Temp "typst"
    Expand-Archive -LiteralPath $archive -DestinationPath $extracted -Force
    New-Item -ItemType Directory -Force -Path (Split-Path $TypstExe) | Out-Null
    $exe = Get-ChildItem -LiteralPath $extracted -Recurse -Filter "typst.exe" | Select-Object -First 1
    if (-not $exe) { throw "typst.exe not found in the Typst download" }
    Copy-Item -LiteralPath $exe.FullName -Destination $TypstExe -Force
}

# --- Zettlr -------------------------------------------------------------------

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
    # Forward slashes work for Pandoc and Typst; ' is escaped for single-quoted YAML
    return $Path.Replace("\", "/").Replace("'", "''")
}

function Install-Zettlr {
    Write-Host "Zettlr: $ZettlrDir"
    Copy-Item -LiteralPath ([IO.Path]::Combine($Current, "zettlr", "source-zettlr.css")) -Destination (Join-Path $ZettlrDir "source-zettlr.css") -Force
    Copy-Item -LiteralPath ([IO.Path]::Combine($Current, "source", "fonts-embedded.css")) -Destination (Join-Path $ZettlrDir "source-zettlr-fonts.css") -Force
    Add-Import (Join-Path $ZettlrDir "custom.css")

    $template = Read-Text ([IO.Path]::Combine($Current, "zettlr", "Source PDF.yaml.in"))
    $content = $template.Replace("@TYPST@", (Convert-YamlPath $TypstExe)).Replace("@DIR@", (Convert-YamlPath $Current))
    $defaults = Join-Path $ZettlrDir "defaults"
    New-Item -ItemType Directory -Force -Path $defaults | Out-Null
    Write-Text (Join-Path $defaults $ProfileName) $content

    $snippets = Join-Path $ZettlrDir "snippets"
    New-Item -ItemType Directory -Force -Path $snippets | Out-Null
    Copy-Item -LiteralPath ([IO.Path]::Combine($Current, "zettlr", "snippets", $SnippetName)) -Destination (Join-Path $snippets $SnippetName) -Force
    Write-Host '  theme, export profile "Source PDF" and snippet "protokoll" installed'
}

function Uninstall-Zettlr {
    Write-Host "Zettlr: $ZettlrDir"
    Remove-Import (Join-Path $ZettlrDir "custom.css")
    foreach ($file in @("source-zettlr.css", "source-zettlr-fonts.css")) {
        Remove-Item -LiteralPath (Join-Path $ZettlrDir $file) -Force -ErrorAction SilentlyContinue
    }
    $profilePath = ([IO.Path]::Combine($ZettlrDir, "defaults", $ProfileName))
    if ((Test-Path -LiteralPath $profilePath) -and (Read-Text $profilePath).Contains($ProfileMarker)) {
        Remove-Item -LiteralPath $profilePath -Force
    }
    $snippet = ([IO.Path]::Combine($ZettlrDir, "snippets", $SnippetName))
    $ours = ([IO.Path]::Combine($Current, "zettlr", "snippets", $SnippetName))
    if ((Test-Path -LiteralPath $snippet) -and (Test-Path -LiteralPath $ours) -and ((Read-Text $snippet) -eq (Read-Text $ours))) {
        Remove-Item -LiteralPath $snippet -Force
    }
    elseif (Test-Path -LiteralPath $snippet) {
        Write-Warning "kept $snippet (changed or unknown)"
    }
    Write-Host "  removed"
}

# --- Typora -------------------------------------------------------------------

function Install-Typora {
    Write-Host "Typora: $TyporaDir"
    foreach ($theme in $TyporaThemes) {
        Copy-Item -LiteralPath (Join-Path $Current $theme) -Destination (Join-Path $TyporaDir $theme) -Force
    }
    $target = Join-Path $TyporaDir "source"
    if (Test-Path -LiteralPath (Join-Path $target "fonts")) {
        Remove-Item -LiteralPath (Join-Path $target "fonts") -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -LiteralPath ([IO.Path]::Combine($Current, "source", "fonts.css")) -Destination (Join-Path $target "fonts.css") -Force
    Copy-Item -LiteralPath ([IO.Path]::Combine($Current, "source", "fonts")) -Destination (Join-Path $target "fonts") -Recurse -Force
    Write-Host "  themes Source, Source Dark, Source Compact, Source Dark Compact installed"
}

function Uninstall-Typora {
    Write-Host "Typora: $TyporaDir"
    foreach ($theme in $TyporaThemes) {
        Remove-Item -LiteralPath (Join-Path $TyporaDir $theme) -Force -ErrorAction SilentlyContinue
    }
    $fontsCss = ([IO.Path]::Combine($TyporaDir, "source", "fonts.css"))
    if ((Test-Path -LiteralPath $fontsCss) -and (Read-Text $fontsCss).Contains("scripts/fetch_fonts.py")) {
        Remove-Item -LiteralPath (Join-Path $TyporaDir "source") -Recurse -Force
    }
    Write-Host "  removed"
}

# --- Main ---------------------------------------------------------------------

if ($Uninstall) {
    if (Test-Path -LiteralPath $ZettlrDir) { Uninstall-Zettlr }
    if (Test-Path -LiteralPath $TyporaDir) { Uninstall-Typora }
    if (Test-Path -LiteralPath $AppDir) { Remove-Item -LiteralPath $AppDir -Recurse -Force }
    Write-Host "Uninstalled."
    return
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ("$BundleName-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    Install-Bundle $temp
    Install-Typst $temp
    $found = $false
    if (Test-Path -LiteralPath $ZettlrDir) { Install-Zettlr; $found = $true }
    if (Test-Path -LiteralPath $TyporaDir) { Install-Typora; $found = $true }
    if (-not $found) {
        Write-Warning "neither Zettlr nor Typora found; start Zettlr once, then run this again"
    }
    Write-Host ""
    Write-Host "Done. Restart Zettlr, then:"
    Write-Host "  - new meeting note: type :protokoll"
    Write-Host '  - PDF: File > Export, profile "Source PDF"'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
