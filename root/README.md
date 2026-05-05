# DT Painting & Plastering static SEO site

This folder is the Cloudflare Pages-ready static site for `dtpaintingandplastering.com`.

Cloudflare Pages should publish the `root` directory. The repository root includes `wrangler.toml` with:

```toml
pages_build_output_dir = "root"
```

## SEO setup

- `index.html` is generated from `../resources/suburbs.txt`.
- Nearby suburbs are prioritised first by the `distance` column.
- The homepage includes title/meta tags, service content, local search phrase coverage, priority suburb links, all target suburbs grouped by postcode, FAQ content and JSON-LD structured data.
- `sitemap.xml` and `robots.txt` are ready for Google Search Console submission.
- `_headers` and `_redirects` are set for Cloudflare Pages.

## Rebuild after suburb changes

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File resources\build-seo-site.ps1
```

The script regenerates:

- `root/index.html`
- `root/sitemap.xml`

## Cloudflare Pages settings

Use these settings if deploying from Git:

- Build command: leave blank
- Build output directory: `root`
- Root directory: repository root

If deploying manually with Wrangler:

```powershell
wrangler pages deploy root --project-name dtpaintingandplastering
```

## Replace before publishing

Search `TODO` in `index.html` and add:

- Real phone number
- Quote email
- Real business suburb/address or service-area wording
- ABN and licence details if you want them displayed
- Real project images when photos are ready

## Next SEO step

Do not create hundreds of near-identical suburb pages. For the highest value suburbs, create unique landing pages only when you can add local proof:

- Original project photos from that suburb or nearby
- A short job description
- Real review or testimonial
- Common property types in that area
- Nearby service context
- Unique title, description, H1, FAQs and internal links

Strong first candidates are Laidley, Plainland, Hatton Vale, Kensington Grove, Regency Downs, Rosewood, Forest Hill, Glenore Grove, Lockrose, Gatton, Grantham, Helidon, Ipswich and Springfield.
