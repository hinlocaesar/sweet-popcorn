# check-external.ps1 — verify every outbound URL in the published pages.
#
#   powershell -File tools\check-external.ps1
#
# Notes on the checks:
#   * YouTube IDs are checked with the oEmbed API (a dead video's /embed/ URL
#     still answers 200, and PowerShell 5.1 cannot follow 308 redirects, so
#     both the embed URLs and the http:// associate links need normalising).
#   * Vimeo's player URL returns 404 when the unlisted-video hash is wrong,
#     so the iframe src is fetched directly.
#   * Amazon and some CDNs 503 datacenter IPs; those come back as BLOCKED
#     rather than as broken links.
#   * Absolute sweetmagicpopcorn.com URLs are the og:url / og:image tags and
#     the legacy store link. They cannot resolve until the domain is moved
#     onto this host, so they are listed separately as PENDING.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

# ---- collect -------------------------------------------------------------
$urls = New-Object System.Collections.Generic.List[string]
Get-ChildItem -Path $root -Filter '*.html' -File | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
    foreach ($m in [regex]::Matches($text, 'https?://[^"''<>\s\)]+')) {
        $u = $m.Value -replace '&amp;', '&'
        if (-not $urls.Contains($u)) { $urls.Add($u) }
    }
}
$urls = @($urls | Sort-Object)

# ---- helpers -------------------------------------------------------------
function Get-Status([string]$url) {
    for ($try = 0; $try -lt 2; $try++) {
        try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25 `
                  -MaximumRedirection 10 -Headers @{ 'User-Agent' = $UA }
            return @{ code = [int]$r.StatusCode; final = $r.BaseResponse.ResponseUri.AbsoluteUri; note = '' }
        } catch {
            $resp = $_.Exception.Response
            if (-not $resp) { return @{ code = 0; final = ''; note = $_.Exception.Message } }
            $code = [int]$resp.StatusCode
            $final = ''
            try { $final = $resp.ResponseUri.AbsoluteUri } catch {}
            # PowerShell 5.1 will not follow a 308; retry the https scheme once.
            if (($code -eq 308 -or $code -eq 301) -and $url -match '^http://' -and $try -eq 0) {
                $url = $url -replace '^http://', 'https://'
                continue
            }
            return @{ code = $code; final = $final; note = 'redirect not followed' }
        }
    }
}

function Get-OEmbed([string]$url, [string]$endpoint) {
    $probe = $endpoint + '?format=json&url=' + [Uri]::EscapeDataString($url)
    try {
        $r = Invoke-RestMethod -Uri $probe -TimeoutSec 25 -Headers @{ 'User-Agent' = $UA }
        return @{ code = 200; title = $r.title }
    } catch {
        $resp = $_.Exception.Response
        $code = 0
        if ($resp) { $code = [int]$resp.StatusCode }
        return @{ code = $code; title = 'not found / unavailable' }
    }
}

# ---- check ---------------------------------------------------------------
$ok = 0; $bad = 0; $blocked = 0; $pending = 0; $legacy = 0
foreach ($u in $urls) {
    $label = $u
    if ($label.Length -gt 66) { $label = $label.Substring(0, 66) + '...' }

    if ($u -match 'youtube\.com/(watch|embed|shorts)/([\w-]+)') {
        # oEmbed only understands watch URLs.
        $watch = 'https://www.youtube.com/watch?v=' + $Matches[2]
        $v = Get-OEmbed $watch 'https://www.youtube.com/oembed'
        if ($v.code -eq 200) { $ok++; $status = 'OK    video: ' + $v.title }
        else { $bad++; $status = 'FAIL  video gone (HTTP ' + $v.code + ')' }

    } elseif ($u -match '^https?://player\.vimeo\.com/video/') {
        $r = Get-Status $u
        if ($r.code -eq 200) { $ok++; $status = 'OK    embed loads' }
        else { $bad++; $status = 'FAIL  HTTP ' + $r.code + ' (bad id or hash)' }

    } elseif ($u -match 'website-store|/m/account') {
        $legacy++
        $status = 'LEGACY   old GoDaddy store - open item 1'

    } elseif ($u -match '^https?://(www\.)?sweetmagicpopcorn\.com/') {
        $pending++
        $status = 'PENDING  resolves once the domain points at this host'

    } else {
        $r = Get-Status $u
        switch ($r.code) {
            200   { $ok++ }
            401   { $blocked++ }
            403   { $blocked++ }
            429   { $blocked++ }
            503   { $blocked++ }
            default { $bad++ }
        }
        $status = switch ($r.code) {
            200   { 'OK' }
            401   { 'BLOCKED (auth challenge)' }
            403   { 'BLOCKED (bot check)' }
            429   { 'BLOCKED (rate limit)' }
            503   { 'BLOCKED (service unavailable)' }
            0     { 'FAIL  ' + $r.note }
            default { 'FAIL  HTTP ' + $r.code }
        }
        if ($status -eq 'OK' -and $r.final -and ($r.final.TrimEnd('/') -ne $u.TrimEnd('/'))) {
            $status = 'OK    redirects -> ' + $r.final
        }
    }
    '{0,-68} {1}' -f $label, $status
}

''
"ok: $ok    broken: $bad    blocked (unverifiable): $blocked    legacy: $legacy    pending (domain move): $pending"
