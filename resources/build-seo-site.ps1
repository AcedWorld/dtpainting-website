Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$rootDir = Join-Path $repoRoot "root"
$suburbPath = Join-Path $PSScriptRoot "suburbs.txt"
$today = Get-Date -Format "yyyy-MM-dd"

function HtmlEncode([string]$value) {
  return [System.Net.WebUtility]::HtmlEncode($value)
}

function JsonText($value) {
  return ($value | ConvertTo-Json -Depth 20 -Compress)
}

function Slug([string]$value) {
  return ($value.ToLowerInvariant() -replace "[^a-z0-9]+", "-" -replace "^-|-$", "")
}

$suburbs = Import-Csv -Path $suburbPath -Header postcode, suburb, distance |
  ForEach-Object {
    [pscustomobject]@{
      postcode = $_.postcode.Trim()
      suburb = $_.suburb.Trim()
      distance = [double]$_.distance
    }
  } |
  Sort-Object distance, suburb

$seenAreaIds = @{}
$suburbs = @($suburbs | ForEach-Object {
  $baseId = "$(Slug $_.suburb)-$($_.postcode)"
  if ($seenAreaIds.ContainsKey($baseId)) {
    $seenAreaIds[$baseId] += 1
  } else {
    $seenAreaIds[$baseId] = 1
  }

  $suffix = if ($seenAreaIds[$baseId] -gt 1) { "-$($seenAreaIds[$baseId])" } else { "" }
  $_ | Add-Member -NotePropertyName areaId -NotePropertyValue "area-$baseId$suffix" -PassThru
})

$priority = $suburbs | Select-Object -First 120
$closest = $suburbs | Where-Object { $_.distance -le 18 } | Select-Object -First 80
$schemaAreas = $suburbs | Select-Object -First 180

$priorityChips = ($priority | ForEach-Object {
  $name = HtmlEncode $_.suburb
  "<li><a href=""#$($_.areaId)"">$name painter</a></li>"
}) -join "`n              "

$closestList = ($closest | ForEach-Object {
  $name = HtmlEncode $_.suburb
  "<li><strong>$name painter:</strong> interior painting, exterior painting, repainting, plaster repairs and paint preparation for homes and small commercial properties.</li>"
}) -join "`n              "

$postcodeGroups = ($suburbs | Group-Object postcode | Sort-Object {
  ($_.Group | Measure-Object distance -Minimum).Minimum
}, Name | ForEach-Object {
  $postcode = HtmlEncode $_.Name
  $minDistance = "{0:N1}" -f (($_.Group | Measure-Object distance -Minimum).Minimum)
  $items = ($_.Group | Sort-Object distance, suburb | ForEach-Object {
    $name = HtmlEncode $_.suburb
    "<li id=""$($_.areaId)"">$name painter, painter in $name, house painter $name, interior painter $name, exterior painter $name</li>"
  }) -join "`n                  "
@"
            <details>
              <summary>Postcode $postcode service areas - from $minDistance km</summary>
              <ul class="suburb-list">
                  $items
              </ul>
            </details>
"@
}) -join "`n"

$areaServed = @(
  @{ "@type" = "AdministrativeArea"; name = "Lockyer Valley QLD" },
  @{ "@type" = "City"; name = "Ipswich QLD" },
  @{ "@type" = "City"; name = "Brisbane QLD" }
) + ($schemaAreas | ForEach-Object {
  @{ "@type" = "Place"; name = "$($_.suburb) QLD $($_.postcode)" }
})

$faqEntities = @(
  @{
    "@type" = "Question"
    name = "Do you service Laidley, Plainland and nearby Lockyer Valley suburbs?"
    acceptedAnswer = @{
      "@type" = "Answer"
      text = "Yes. DT Painting & Plastering is based in the Lockyer Valley region and prioritises nearby suburbs including Laidley, Plainland, Hatton Vale, Kensington Grove, Regency Downs and surrounding communities."
    }
  },
  @{
    "@type" = "Question"
    name = "What searches is this painting page relevant for?"
    acceptedAnswer = @{
      "@type" = "Answer"
      text = "The page is written around common local searches such as suburb painter, painter in suburb, painter suburb, house painter suburb, interior painter suburb, exterior painter suburb and plastering suburb."
    }
  },
  @{
    "@type" = "Question"
    name = "Do you provide painting services in Ipswich and Brisbane?"
    acceptedAnswer = @{
      "@type" = "Answer"
      text = "Yes. DT Painting & Plastering services the Lockyer Valley region first, then Ipswich and Brisbane areas by project size, timing and location."
    }
  },
  @{
    "@type" = "Question"
    name = "What painting and plastering services do you offer?"
    acceptedAnswer = @{
      "@type" = "Answer"
      text = "Services include interior house painting, exterior house painting, residential repainting, commercial painting, plaster repairs, wall patching, surface preparation and finishing."
    }
  }
)

$jsonLd = @{
  "@context" = "https://schema.org"
  "@graph" = @(
    @{
      "@type" = "WebSite"
      "@id" = "https://dtpaintingandplastering.com/#website"
      url = "https://dtpaintingandplastering.com/"
      name = "DT Painting & Plastering"
      inLanguage = "en-AU"
      publisher = @{ "@id" = "https://dtpaintingandplastering.com/#business" }
    },
    @{
      "@type" = "WebPage"
      "@id" = "https://dtpaintingandplastering.com/#webpage"
      url = "https://dtpaintingandplastering.com/"
      name = "Painter in Laidley, Plainland, Gatton, Lockyer Valley, Ipswich and Brisbane"
      description = "DT Painting & Plastering provides house painting, interior painting, exterior painting, repainting and plaster repairs across Lockyer Valley, Ipswich and Brisbane, QLD."
      isPartOf = @{ "@id" = "https://dtpaintingandplastering.com/#website" }
      about = @{ "@id" = "https://dtpaintingandplastering.com/#business" }
      inLanguage = "en-AU"
    },
    @{
      "@type" = "HousePainter"
      "@id" = "https://dtpaintingandplastering.com/#business"
      name = "DT Painting & Plastering"
      url = "https://dtpaintingandplastering.com/"
      image = "https://dtpaintingandplastering.com/assets/og-image.svg"
      description = "Lockyer Valley based painting and plastering business servicing nearby suburbs first, plus Ipswich and Brisbane areas."
      address = @{
        "@type" = "PostalAddress"
        addressLocality = "Lockyer Valley"
        addressRegion = "QLD"
        addressCountry = "AU"
      }
      areaServed = $areaServed
      knowsAbout = @(
        "Painter near me",
        "House painting",
        "Interior painting",
        "Exterior painting",
        "Residential repainting",
        "Commercial painting",
        "Plaster repairs",
        "Wall patching",
        "Paint preparation"
      )
      hasOfferCatalog = @{
        "@type" = "OfferCatalog"
        name = "Painting and plastering services"
        itemListElement = @(
          @{ "@type" = "Offer"; itemOffered = @{ "@type" = "Service"; name = "Interior house painting" } },
          @{ "@type" = "Offer"; itemOffered = @{ "@type" = "Service"; name = "Exterior house painting" } },
          @{ "@type" = "Offer"; itemOffered = @{ "@type" = "Service"; name = "Plastering and wall repairs" } }
        )
      }
    },
    @{
      "@type" = "FAQPage"
      "@id" = "https://dtpaintingandplastering.com/#faq-schema"
      mainEntity = $faqEntities
    }
  )
}

$jsonLdText = JsonText $jsonLd

$html = @"
<!doctype html>
<html lang="en-AU">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Painter in Laidley, Plainland, Gatton &amp; Lockyer Valley | DT Painting &amp; Plastering</title>
  <meta name="description" content="Lockyer Valley painter for Laidley, Plainland, Gatton, Hatton Vale, Rosewood, Ipswich and Brisbane. Interior painting, exterior painting, house painting and plaster repairs.">
  <meta name="robots" content="index,follow,max-image-preview:large">
  <link rel="canonical" href="https://dtpaintingandplastering.com/">

  <meta property="og:type" content="website">
  <meta property="og:locale" content="en_AU">
  <meta property="og:site_name" content="DT Painting &amp; Plastering">
  <meta property="og:title" content="Painter in Laidley, Plainland, Gatton &amp; Lockyer Valley">
  <meta property="og:description" content="House painting, interior painting, exterior painting and plaster repairs across Lockyer Valley, Ipswich and Brisbane.">
  <meta property="og:url" content="https://dtpaintingandplastering.com/">
  <meta property="og:image" content="https://dtpaintingandplastering.com/assets/og-image.svg">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Painter in Laidley, Plainland, Gatton &amp; Lockyer Valley">
  <meta name="twitter:description" content="Painting and plastering services across Lockyer Valley, Ipswich and Brisbane, QLD.">
  <meta name="twitter:image" content="https://dtpaintingandplastering.com/assets/og-image.svg">

  <link rel="preload" href="/assets/site.css" as="style">
  <link rel="stylesheet" href="/assets/site.css">
  <link rel="icon" href="/assets/favicon.svg" type="image/svg+xml">

  <script type="application/ld+json">$jsonLdText</script>
</head>
<body>
  <a class="skip-link" href="#main">Skip to content</a>

  <header class="site-header" aria-label="Site header">
    <div class="container header-inner">
      <p class="brand" aria-label="DT Painting and Plastering">DT Painting &amp; Plastering</p>
      <nav class="nav" aria-label="Main navigation">
        <a href="#services">Services</a>
        <a href="#priority-areas">Priority areas</a>
        <a href="#all-areas">All suburbs</a>
        <a href="#quote">Quote</a>
        <a href="#faq">FAQ</a>
      </nav>
    </div>
  </header>

  <main id="main">
    <section class="hero">
      <div class="container hero-grid">
        <div>
          <p class="eyebrow">Lockyer Valley based - closest suburbs first</p>
          <h1>Painter in Laidley, Plainland, Gatton and the Lockyer Valley</h1>
          <p class="hero-copy">DT Painting &amp; Plastering provides house painting, interior painting, exterior painting, repainting and plaster repairs across the Lockyer Valley region, with Ipswich and Brisbane projects handled by arrangement.</p>
          <p class="hero-copy">This page is built around the way local customers search: <strong>Laidley painter</strong>, <strong>painter in Plainland</strong>, <strong>Gatton painter</strong>, <strong>house painter Hatton Vale</strong>, <strong>interior painter Ipswich</strong> and similar suburb painting searches.</p>
          <div class="cta-row" aria-label="Contact options">
            <a class="button primary" href="#quote">Request a painting quote</a>
            <a class="button secondary" href="#all-areas">Check your suburb</a>
          </div>
        </div>
        <div class="hero-panel" aria-label="Core local painting services">
          <h2>Local painting services</h2>
          <ul>
            <li>Interior house painting</li>
            <li>Exterior house painting</li>
            <li>Residential repainting</li>
            <li>Commercial painting</li>
            <li>Plaster repairs and wall patching</li>
            <li>Paint preparation and finishing</li>
          </ul>
        </div>
      </div>
    </section>

    <section class="section" id="services">
      <div class="container">
        <p class="eyebrow">Services</p>
        <h2>House painting and plastering for homes, rentals and small businesses</h2>
        <div class="cards three">
          <article class="card">
            <h3>Interior painter</h3>
            <p>Clean interior painting for bedrooms, living areas, kitchens, rentals, renovations and pre-sale refreshes, with preparation matched to the condition of the walls.</p>
          </article>
          <article class="card">
            <h3>Exterior painter</h3>
            <p>Exterior repainting for homes, trims, fences, sheds and weather-exposed surfaces across Lockyer Valley, Ipswich and Brisbane suburbs.</p>
          </article>
          <article class="card">
            <h3>Plaster repairs</h3>
            <p>Wall patching, plaster repairs and surface preparation before painting so the final finish looks cleaner and lasts longer.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section muted" id="priority-areas">
      <div class="container">
        <p class="eyebrow">Priority service areas</p>
        <h2>Closest painting suburbs are prioritised first</h2>
        <p class="section-copy">The suburb list is sorted by distance from the business base. Nearby Lockyer Valley towns and suburbs get the strongest on-page emphasis, then the page broadens into Ipswich and Brisbane service coverage.</p>

        <ul class="chip-list" aria-label="Priority suburb painter links">
              $priorityChips
        </ul>

        <div class="local-intent">
          <h3>Closest suburb painting searches covered</h3>
          <ul>
              $closestList
          </ul>
        </div>
      </div>
    </section>

    <section class="section" id="seo-targets">
      <div class="container split">
        <div>
          <p class="eyebrow">Search intent</p>
          <h2>Built for real local painter searches</h2>
          <p>Local customers rarely search one exact phrase. They search for a painter by suburb, service and urgency. This page naturally covers patterns such as <strong>suburb painter</strong>, <strong>painter in suburb</strong>, <strong>painter suburb</strong>, <strong>house painter suburb</strong>, <strong>interior painter suburb</strong>, <strong>exterior painter suburb</strong>, <strong>painting services suburb</strong>, <strong>residential painter suburb</strong>, <strong>commercial painter suburb</strong>, <strong>plasterer suburb</strong> and <strong>plastering suburb</strong>.</p>
          <p>The strongest suburb signals are kept for the closest areas first: Laidley, Plainland, Hatton Vale, Kensington Grove, Regency Downs, Rosewood, Forest Hill, Glenore Grove, Lockrose, Gatton, Grantham, Helidon and nearby Lockyer Valley communities.</p>
        </div>
        <aside class="note" aria-label="Important SEO note">
          <h3>Best next ranking step</h3>
          <p>After photos are ready, add original project photos, real reviews and suburb-specific proof for the highest value suburbs. Google is much more likely to trust a suburb page when it has unique local evidence.</p>
        </aside>
      </div>
    </section>

    <section class="section muted" id="all-areas">
      <div class="container">
        <p class="eyebrow">All target suburbs</p>
        <h2>Painting service areas by postcode</h2>
        <p class="section-copy">Every suburb from <code>resources/suburbs.txt</code> is listed below in priority order by distance, grouped by postcode. This gives Google crawlable local coverage while keeping the page readable for customers checking whether their area is serviced.</p>
        <div class="postcode-groups">
$postcodeGroups
        </div>
      </div>
    </section>

    <section class="section" id="quote">
      <div class="container">
        <p class="eyebrow">Quotes</p>
        <h2>Request a painting quote</h2>
        <p class="section-copy">Add the real phone number, email address or quote form here. Keep the same business name, phone, service area and address wording on the Google Business Profile, website and local directory listings.</p>
        <div class="contact-panel">
          <p><strong>Business:</strong> DT Painting &amp; Plastering</p>
          <p><strong>Base:</strong> Lockyer Valley region, Queensland</p>
          <p><strong>Service area:</strong> Lockyer Valley first, plus Ipswich and Brisbane regions</p>
          <p><strong>Phone:</strong> TODO: add phone number</p>
          <p><strong>Email:</strong> TODO: add quote email</p>
        </div>
      </div>
    </section>

    <section class="section muted" id="faq">
      <div class="container">
        <p class="eyebrow">FAQ</p>
        <h2>Painting service questions</h2>
        <div class="faq-list">
          <details>
            <summary>Do you service Laidley, Plainland and nearby Lockyer Valley suburbs?</summary>
            <p>Yes. DT Painting &amp; Plastering is based in the Lockyer Valley region and prioritises nearby suburbs including Laidley, Plainland, Hatton Vale, Kensington Grove, Regency Downs and surrounding communities.</p>
          </details>
          <details>
            <summary>Do you provide painting services in Ipswich and Brisbane?</summary>
            <p>Yes. Ipswich and Brisbane jobs are available by arrangement depending on project size, location and schedule.</p>
          </details>
          <details>
            <summary>What painting services do you offer?</summary>
            <p>Core services include interior painting, exterior painting, residential repainting, commercial painting, plaster repairs, wall patching, paint preparation and finishing.</p>
          </details>
          <details>
            <summary>Can you help before selling or renting a property?</summary>
            <p>Yes. Repainting and wall repairs can help present a home or rental property more cleanly before sale, lease or inspection.</p>
          </details>
          <details>
            <summary>Why are the closest suburbs listed first?</summary>
            <p>Nearby suburbs are more relevant to the business location, so they receive stronger priority signals before broader Ipswich and Brisbane coverage.</p>
          </details>
        </div>
      </div>
    </section>
  </main>

  <footer class="site-footer">
    <div class="container footer-inner">
      <p>&copy; <span id="year">2026</span> DT Painting &amp; Plastering. Painter for Lockyer Valley, Ipswich and Brisbane, QLD.</p>
      <p><a href="/sitemap.xml">Sitemap</a></p>
    </div>
  </footer>

  <script>
    document.getElementById('year').textContent = new Date().getFullYear();
  </script>
</body>
</html>
"@

$sitemap = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://dtpaintingandplastering.com/</loc>
    <lastmod>$today</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>
"@

Set-Content -Path (Join-Path $rootDir "index.html") -Value $html -Encoding utf8
Set-Content -Path (Join-Path $rootDir "sitemap.xml") -Value $sitemap -Encoding utf8

Write-Host "Generated root/index.html from $($suburbs.Count) suburb rows."
Write-Host "Generated root/sitemap.xml with lastmod $today."
