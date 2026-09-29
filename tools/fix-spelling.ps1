# One-off pass: normalise the new copy to US spelling (the brand and the old
# site both use "savory", "personalized", "color", ...).  Keeps capitalisation.
$pairs = @(
    @('savory', 'savory'),
    @('flavor', 'flavor'),
    @('color', 'color'),
    @('personaliz', 'personaliz'),
    @('organiz', 'organiz'),
    @('favor', 'favor'),
    @('center\b', 'center'),
    @('theater\b', 'theater'),
    @('fulfillment\b', 'fulfillment'),
    @('fulfill\b', 'fulfill')
)

$files = @(Get-ChildItem 'content\*.html') + @(Get-ChildItem 'partials\*.html') +
         @(Get-ChildItem 'tools\*.ps1') + @(Get-Item 'README.md')

$total = 0
foreach ($f in $files) {
    $text = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
    $orig = $text
    foreach ($p in $pairs) {
        $from = $p[0]; $to = $p[1]
        $text = [regex]::Replace($text, ('(?i)\b' + $from), {
            param($m)
            $r = $to
            if ([char]::IsUpper($m.Value[0])) { $r = $r.Substring(0, 1).ToUpper() + $r.Substring(1) }
            $r
        })
    }
    if ($text -ne $orig) {
        # .ps1 files keep their UTF-8 BOM so Windows PowerShell 5.1 reads them right.
        $enc = if ($f.Extension -eq '.ps1') { New-Object Text.UTF8Encoding($true) }
               else { New-Object Text.UTF8Encoding($false) }
        [IO.File]::WriteAllText($f.FullName, $text, $enc)
        Write-Output ("spelling: " + $f.Name)
        $total++
    }
}
Write-Output ("updated " + $total + " files")
