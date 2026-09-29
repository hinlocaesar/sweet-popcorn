# Static checks for the built site: encoding, placeholders, link + image targets,
# fragment anchors and rough tag balance.  Usage: powershell -File tools/validate.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$utf8 = [Text.Encoding]::UTF8
$pages = Get-ChildItem -Filter '*.html' -File | Where-Object { $_.Name -notlike '.*' }
$issues = @()

function Add-Issue([string]$file, [string]$msg) {
    $script:issues += ("{0}: {1}" -f $file, $msg)
}

foreach ($f in $pages) {
    $text = [IO.File]::ReadAllText($f.FullName, $utf8)

    # ---- encoding / template leftovers -------------------------------------
    $moji = @(
        (([string][char]0xE2) + ([string][char]0x20AC))   # double-encoded bytes
        (([string][char]0xC2) + ([string][char]0xB7))     # double-encoded middot
        (([string][char]0xE2) + ([string][char]0x2018))   # double-encoded quote
        '{{'
        '}}'
    )
    foreach ($bad in $moji) {
        if ($text.Contains($bad)) { Add-Issue $f.Name ("suspicious sequence found: " + $bad.Length + " chars") }
    }

    # ---- internal hrefs -----------------------------------------------------
    foreach ($m in [regex]::Matches($text, 'href="([^"]+)"')) {
        $href = $m.Groups[1].Value
        if ($href -match '^(https?:|mailto:|tel:|javascript:)') { continue }
        $file = $href; $frag = ''
        if ($href -match '^(.*?)#(.*)$') { $file = $Matches[1]; $frag = $Matches[2] }
        if ($file -eq '') { continue }
        if (-not (Test-Path $file)) { Add-Issue $f.Name "broken link -> $href"; continue }
        if ($frag) {
            $target = [IO.File]::ReadAllText((Resolve-Path $file).Path, $utf8)
            if ($target -notmatch ('id="' + [regex]::Escape($frag) + '"')) {
                Add-Issue $f.Name "missing anchor -> $href"
            }
        }
    }

    # ---- local src targets --------------------------------------------------
    foreach ($m in [regex]::Matches($text, 'src="([^"]+)"')) {
        $src = $m.Groups[1].Value
        if ($src -match '^(https?:|data:)') { continue }
        if (-not (Test-Path $src)) { Add-Issue $f.Name "missing asset -> $src" }
    }

    # ---- rough block-tag balance -------------------------------------------
    foreach ($tag in @('div', 'section', 'main', 'article', 'header', 'footer', 'nav', 'form', 'ul', 'figure')) {
        $open = ([regex]::Matches($text, ('<' + $tag + '(?=[\s>])'))).Count
        $close = ([regex]::Matches($text, ('</' + $tag + '>'))).Count
        if ($open -ne $close) { Add-Issue $f.Name ("unbalanced <{0}>: {1} open / {2} close" -f $tag, $open, $close) }
    }

    # ---- image alts ---------------------------------------------------------
    foreach ($m in [regex]::Matches($text, '<img\b[^>]*>')) {
        if ($m.Value -notmatch 'alt="[^"]*"') { Add-Issue $f.Name ("img without alt: " + $m.Value.Substring(0, [Math]::Min(70, $m.Value.Length))) }
    }
}

# ---- assets referenced anywhere but missing -------------------------------
$imgCount = (Get-ChildItem 'assets\img' -File).Count
Write-Output ("checked {0} pages, {1} images" -f $pages.Count, $imgCount)

if ($issues.Count) {
    $issues | Sort-Object -Unique | ForEach-Object { Write-Output "ISSUE  $_" }
    exit 1
}
Write-Output "no issues"
