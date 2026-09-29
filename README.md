# Sweet Magic Popcorn — website rebuild

A complete static rebuild of [sweetmagicpopcorn.com](https://sweetmagicpopcorn.com):
plain HTML, one CSS file, one JS file, no framework and no build step required to
publish. The page files in this folder are ready to upload as-is.

## What's here

```
index.html … terms.html     the 15 published pages (generated — see "Building")
assets/css/style.css        the whole design system
assets/css/fonts.css        @font-face rules for the local font files
assets/fonts/               Fraunces + Outfit woff2 files (self-hosted)
assets/img/                 57 photographs and product/label images
assets/js/main.js           nav, tabs, scroll reveals, demo forms
assets/docs/order-form.pdf  the mail-in order form (money order / cashier's check)
favicon.svg
robots.txt  sitemap.xml

partials/                    shared <head>, header and footer markup
content/                     the <main> markup for each page
tools/build.ps1              assembles partials + content into the root pages
tools/validate.ps1           link / asset / encoding / tag-balance checks
tools/fix-encoding.ps1       one-off repair for double-encoded UTF-8 files
tools/fix-spelling.ps1       one-off normalise of copy to US spelling
```

`partials/` and `content/` and `tools/` are source files, not part of the
published site — upload only the root `*.html`, `assets/`, `favicon.svg`,
`robots.txt` and `sitemap.xml`.

## Building

```powershell
powershell -File tools/build.ps1     # writes the 15 pages + sitemap.xml
powershell -File tools/validate.ps1  # checks links, images, anchors, encoding
```

The build script exists purely so the header and footer are identical on every
page. Editing a page means editing its file in `content/` and re-running the
build; editing the nav or footer means editing `partials/` and re-running it.

**Encoding:** everything is UTF-8. The scripts read and write UTF-8 explicitly
because Windows PowerShell 5.1 otherwise assumes the system code page for files
without a BOM and mangles every em dash and accented character. If you add a
`.ps1` with non-ASCII characters, save it with a UTF-8 BOM.

## Previewing locally

Any static server works. With Python:

```powershell
py -3 -m http.server 8765
# then open http://127.0.0.1:8765/index.html
```

## Hosting on GitHub Pages

The site is live at **https://hinlocaesar.github.io/sweet-popcorn/**.

Pages is enabled for this repository as *Deploy from a branch → `main` / root*,
so publishing is just a push:

```powershell
powershell -File tools\build.ps1     # regenerate the pages
powershell -File tools\validate.ps1  # sanity-check them
git add -A ; git commit -m "Update site" ; git push
```

The first build after a push takes about 30–60 seconds. `.nojekyll` is included
so GitHub serves the files as-is instead of running them through Jekyll.

### Pointing sweetmagicpopcorn.com at it

1. Add a `CNAME` file containing `sweetmagicpopcorn.com` (or set the domain in
   the repository's *Settings → Pages → Custom domain*).
2. At your DNS registrar, point the domain at `hinlocaesar.github.io` —
   an `A` record per GitHub's published IPs for the apex, or a `CNAME` for `www`.
3. Tick *Enforce HTTPS* once the DNS check passes.
4. Keep the old URLs working by adding the redirect table below at the same time.

## Design notes

- **Direction:** playful & premium — carnival marquee bulbs, red gingham,
  popcorn-puff SVGs and a scrolling ticker over a navy / red / gold / cream
  palette. Type is Fraunces (display) + Outfit (text), both self-hosted.
- **Tokens** live at the top of `style.css`: `--navy-900 #0A1330`,
  `--red #D9232B`, `--gold #F7C948`, `--cream #FFF8EA`.
- Product photography is the original artwork from the live site, downloaded so
  the site is self-contained. Package photos were matched to product names by
  checking what is actually in the picture — note the old site's own photo/heading
  order for Sweet Magic and Western is swapped; the mapping here is the correct one.
- Nutrition and seasoning label scans use `object-fit: contain` (`.nutrition-card--contain`,
  `.nutrition-card.label-card`) so nothing on the label is cropped.

## Redirects from the old GoDaddy site

Set these up on the host so existing links and search results keep working:

| Old URL | New URL |
| --- | --- |
| `/` | `/index.html` |
| `/amazon-store-%26-reviews` | `/shop.html#amazon` |
| `/website-store` | `/shop.html#website-store` |
| `/packages-in-detail` | `/packages.html` |
| `/kernel-facts` | `/kernels.html` |
| `/salt-%26-seasonings` | `/seasonings.html` |
| `/nutrition-labels` | `/nutrition.html` |
| `/cooking-popcorn` | `/cooking.html` |
| `/our-story` | `/story.html` |
| `/evas-documentary` | `/documentary.html` |
| `/motivational-speaking` | `/speaking.html` |
| `/commercials-%26-media` | `/media.html` |
| `/social-media` | `/media.html` |
| `/associates` | `/associates.html` |
| `/contact` | `/contact.html` |
| `/privacy-policy` | `/privacy.html` |
| `/terms-and-conditions` | `/terms.html` |
| `/m/account` | drop (GoDaddy customer account pages, not rebuilt) |

## Before you launch — open items

1. **Website store link.** The "Open the website store" button still points at
   the legacy GoDaddy store:
   `https://sweetmagicpopcorn.com/website-store?olsPage=cart`.
   Update it in `content/shop.html` (and the header/footer if you add it there)
   once the new store exists.
2. **Forms are front-end only.** The contact form and the newsletter sign-up use
   `data-demo-form` in `assets/js/main.js`, which just shows a success message.
   Point them at your form service or a real endpoint.
3. **Legal pages need a review.** `content/privacy.html` and `content/terms.html`
   were written for this rebuild from scratch — have a lawyer confirm them before
   publishing.
4. **The order form PDF is 23 MB.** Re-export or downsample
   `assets/docs/order-form.pdf` before launch if you can.
5. **External destinations** still point at the old YouTube, Vimeo, Amazon and
   associate URLs — verify each one as part of the migration.
