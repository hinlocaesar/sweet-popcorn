<#
  Sweet Magic Popcorn — static site assembler.

  The published site is plain HTML: every page in this folder is complete,
  self-contained HTML that can be uploaded to any host. This script only
  exists so the shared <header>/<footer> stay identical across pages.

  Usage:  powershell -File tools/build.ps1
#>
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Read and write UTF-8 explicitly: Windows PowerShell 5.1 otherwise assumes the
# system code page for files without a BOM and mangles every accented character.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Read-Utf8([string]$p) { [IO.File]::ReadAllText((Join-Path $root $p), [Text.Encoding]::UTF8) }
function Write-Utf8([string]$p, [string]$v) { [IO.File]::WriteAllText((Join-Path $root $p), $v, $utf8NoBom) }

$head    = Read-Utf8 'partials/head.html'
$headerT = Read-Utf8 'partials/header.html'
$footer  = Read-Utf8 'partials/footer.html'

$pages = @(
    @{ out = 'index.html';       nav = 'home';    content = 'content/index.html';
       title = 'Sweet Magic Popcorn — Every Bite Is A Main Event';
       desc  = 'Non-GMO popcorn kernels, buttery salt and five savory seasonings grown in Indiana by American farmers. Limited-edition gift packages that support Eva''s documentary.';
       image = 'assets/img/pkg-hero.jpg' },

    @{ out = 'shop.html';        nav = 'shop';    content = 'content/shop.html';
       title = 'Shop Popcorn, Kernels & Seasonings | Sweet Magic Popcorn';
       desc  = 'Order Sweet Magic Popcorn on Amazon or through our website store — limited-edition gift packages, one-pound kernel bags and every seasoning blend.';
       image = 'assets/img/pkg-hero.jpg' },

    @{ out = 'packages.html';    nav = 'shop';    content = 'content/packages.html';
       title = 'Limited-Edition Gift Packages | Sweet Magic Popcorn';
       desc  = 'Five limited-edition gift packages — Patriot, Celebration, Sweet Magic, Glorious Day and Western — each with a personalized autograph from Eva D. Jones-Young.';
       image = 'assets/img/pkg-patriot.jpg' },

    @{ out = 'kernels.html';     nav = 'shop';    content = 'content/kernels.html';
       title = 'Six Natural Popcorn Kernel Varieties | Sweet Magic Popcorn';
       desc  = 'Red, white, blue, purple, mushroom and rainbow popcorn kernels — non-GMO, nut free, no dyes or preservatives, grown in Indiana.';
       image = 'assets/img/home-kernels.jpg' },

    @{ out = 'seasonings.html';  nav = 'shop';    content = 'content/seasonings.html';
       title = 'Buttery Salt & Five Seasonings | Sweet Magic Popcorn';
       desc  = 'Our savory Buttery Popcorn Salt plus Hickory Smoke BBQ, White Cheddar, Ranch, Cinnamon Bun and Sour Cream & Onion seasonings.';
       image = 'assets/img/seasonings-group.jpg' },

    @{ out = 'nutrition.html';   nav = 'shop';    content = 'content/nutrition.html';
       title = 'Nutrition Labels | Sweet Magic Popcorn';
       desc  = 'Full nutrition labels for every Sweet Magic Popcorn kernel variety, buttery salt and seasoning blend.';
       image = 'assets/img/nutrition-red.jpg' },

    @{ out = 'cooking.html';     nav = 'shop';    content = 'content/cooking.html';
       title = 'How to Cook Our Popcorn | Sweet Magic Popcorn';
       desc  = 'The best way to cook popcorn kernels is in a pan. Three simple steps to perfect stovetop popcorn every time.';
       image = 'assets/img/photo-cooking.jpg' },

    @{ out = 'story.html';       nav = 'story';   content = 'content/story.html';
       title = 'Our Story | Sweet Magic Popcorn';
       desc  = 'Eva and Larry are hands on when it comes to their popcorn. Only the finest natural kernels come from their hometown and state of Indiana.';
       image = 'assets/img/story.jpg' },

    @{ out = 'documentary.html'; nav = 'story';   content = 'content/documentary.html';
       title = "Eva's Documentary | Sweet Magic Popcorn";
       desc  = 'Learn about the Sweet Magic documentary in the making — every limited-edition purchase helps promote Eva''s story.';
       image = 'assets/img/hero-video-poster.jpg' },

    @{ out = 'speaking.html';    nav = 'story';   content = 'content/speaking.html';
       title = 'Motivational Speaking with Eva D. Jones-Young | Sweet Magic Popcorn';
       desc  = 'Eva D. Jones-Young — 3X world boxing champion and 14X martial arts world champion — is available for motivational speaking.';
       image = 'assets/img/speaking.jpg' },

    @{ out = 'media.html';       nav = 'story';   content = 'content/media.html';
       title = 'Commercials & Media | Sweet Magic Popcorn';
       desc  = 'The Sweet Magic Popcorn jingle, original commercials and videos from friends and fans across the country.';
       image = 'assets/img/photo-media-1.jpg' },

    @{ out = 'associates.html';  nav = 'story';   content = 'content/associates.html';
       title = 'Associates | Sweet Magic Popcorn';
       desc  = 'Friends and associates of Sweet Magic Popcorn and the Sweet Magic documentary.';
       image = 'assets/img/associate-1.jpg' },

    @{ out = 'contact.html';     nav = 'contact'; content = 'content/contact.html';
       title = 'Contact Sweet Magic Popcorn';
       desc  = 'Drop us a line about orders, packages, wholesale or motivational speaking. Orders@SweetMagicPopcorn.com — PO BOX 9487, West Hills, CA 91309.';
       image = 'assets/img/logo.png' },

    @{ out = 'privacy.html';     nav = '';        content = 'content/privacy.html';
       title = 'Privacy Policy | Sweet Magic Popcorn';
       desc  = 'How Sweet Magic Popcorn LLC collects, uses and protects your information.';
       image = 'assets/img/logo.png' },

    @{ out = 'terms.html';       nav = '';        content = 'content/terms.html';
       title = 'Terms & Conditions | Sweet Magic Popcorn';
       desc  = 'The terms and conditions that govern orders placed with Sweet Magic Popcorn LLC.';
       image = 'assets/img/logo.png' }
)

$built = @()

foreach ($p in $pages) {
    if (-not (Test-Path $p.content)) { throw "Missing content file: $($p.content)" }
    $body = Read-Utf8 ($p.content)

    # ---- mark the active primary nav item ----------------------------------
    $nav = $p.nav
    $file = $p.out
    $headerHtml = $headerT

    if ($nav) {
        $headerHtml = [regex]::Replace($headerHtml, '<a class="nav__link" data-nav="(?<n>[a-z]+)"', {
            param($m)
            if ($m.Groups['n'].Value -eq $nav) { '<a class="nav__link is-active" data-nav="' + $m.Groups['n'].Value + '"' }
            else { $m.Value }
        })
    }

    # ---- mark the page itself inside its dropdown --------------------------
    $headerHtml = [regex]::Replace($headerHtml, '<a data-nav="(?<n>[a-z]+)" href="(?<f>[^"]+)"', {
        param($m)
        if ($m.Groups['f'].Value -eq $file) {
            '<a class="is-active" data-nav="' + $m.Groups['n'].Value + '" href="' + $m.Groups['f'].Value + '"'
        } else { $m.Value }
    })

    $headHtml = $head.
        Replace('{{TITLE}}', $p.title).
        Replace('{{DESC}}', $p.desc).
        Replace('{{OGIMAGE}}', 'https://sweetmagicpopcorn.com/' + $p.image).
        Replace('{{URL}}', 'https://sweetmagicpopcorn.com/' + $p.out)

    Write-Utf8 ($p.out) ($headHtml + $headerHtml + $body + $footer)
    $built += $p.out
    Write-Output "built  $($p.out)"
}

# ---------------------------------------------------------------- sitemap --
$loc = ($pages | ForEach-Object { "  <url><loc>https://sweetmagicpopcorn.com/$($_.out)</loc><changefreq>monthly</changefreq></url>" }) -join "`n"
$sitemap = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n$loc`n</urlset>`n"
Write-Utf8 'sitemap.xml' $sitemap

Write-Output ("done - " + $built.Count + " pages")
