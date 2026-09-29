# One-off repair: re-decode a UTF-8 file whose bytes were re-encoded through
# Windows-1252 (mojibake such as a three-byte em dash rendered as three letters).
param([string]$Path)

$map = @{
  [char]0x20AC = 0x80; [char]0x201A = 0x82; [char]0x0192 = 0x83; [char]0x201E = 0x84
  [char]0x2026 = 0x85; [char]0x2020 = 0x86; [char]0x2021 = 0x87; [char]0x02C6 = 0x88
  [char]0x2030 = 0x89; [char]0x0160 = 0x8A; [char]0x2039 = 0x8B; [char]0x0152 = 0x8C
  [char]0x017D = 0x8E; [char]0x2018 = 0x91; [char]0x2019 = 0x92; [char]0x201C = 0x93
  [char]0x201D = 0x94; [char]0x2022 = 0x95; [char]0x2013 = 0x96; [char]0x2014 = 0x97
  [char]0x02DC = 0x98; [char]0x2122 = 0x99; [char]0x0161 = 0x9A; [char]0x203A = 0x9B
  [char]0x0153 = 0x9C; [char]0x017E = 0x9E; [char]0x0178 = 0x9F
}

$s = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
$ms = New-Object System.IO.MemoryStream

foreach ($ch in $s.ToCharArray()) {
    $c = [int]$ch
    if ($c -lt 0x80) { $ms.WriteByte([byte]$c) }
    elseif ($map.ContainsKey($ch)) { $ms.WriteByte([byte]$map[$ch]) }
    elseif ($c -ge 0x80 -and $c -le 0xFF) { $ms.WriteByte([byte]$c) }
    else { foreach ($b in [Text.Encoding]::UTF8.GetBytes([string]$ch)) { $ms.WriteByte($b) } }
}

$bytes = $ms.ToArray()
$fixed = [Text.Encoding]::UTF8.GetString($bytes)
[IO.File]::WriteAllText($Path, $fixed, (New-Object Text.UTF8Encoding($false)))

$sig = ([string][char]0xE2) + ([string][char]0x20AC)
$bad = 0
if ($fixed.Contains($sig)) { $bad = 1 }
Write-Output ("repaired " + $Path + " - " + $bytes.Length + " bytes, mojibake remaining: " + $bad)
