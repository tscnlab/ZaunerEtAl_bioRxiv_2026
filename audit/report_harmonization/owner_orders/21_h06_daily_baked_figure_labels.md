# REPORT-014 display-only order 21: H06 daily baked figure labels

Date: 2026-08-13

Owner task: `019fec6a-20d3-7710-ab9b-a035e0874182`

## Scope and exact identities

Order 20 source revision is independently accepted at:

- `notebooks/hypotheses/H06_daily.qmd`:
  `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`;
- `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`:
  `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`.

Do not edit either QMD in this order. Do not edit main H06, shared
configuration, a central ledger, an accepted scientific script or manifest,
or any source-data file.

Repair only the baked reader terminology in:

`artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.png`

Accepted pre-repair identity:
`69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c`,
475439 bytes, 3070 by 4251 pixels.

The sole plot-data input is the already frozen CSV:

`artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_deviation_figure.csv`

It must remain byte-identical at
`12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc`.
The site display registry must remain byte-identical at
`3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.

## Authorized implementation

Create one dedicated H06-daily-owned display refresh script rather than
running or editing the broad Stage 3 builder. It may read only the frozen
figure CSV and site registry needed for the plot and may write only the single
PNG above plus new task-owned display verification records.

Reproduce the accepted plot data, geometry, ordering, colors, axes, facets,
marks, dimensions, resolution, and typography. Change only these baked text
labels:

- title: `Site deviations from the site-average context association`;
- subtitle: `Adjustment factor = full site-specific comparison/reference
  ratio ÷ site-average comparison/reference ratio`;
- footer phrase: `than the site-average contrast` in place of `than the
  equal-site contrast`.

Keep every site label exactly country coded. Do not replace internal column
names or provenance fields in the frozen CSV. Do not alter the SVG counterpart
or the historical alt-text CSV in this order. Their accepted identities must
remain:

- SVG: `b23f9a6838c2ecc476bdb5e68c203e0c7a85d05479a65841f75ee02d21e20b1c`;
- historical alt-text CSV:
  `a8be1b85d4c0c98922b98080148dcd87b43a28a3ee1fe6a1c55b979c1791200f`.

Use R 4.6.1 and the synchronized project library. This is display-only
regeneration from frozen plot data. Do not load a fitted model, recalculate an
estimate, interval, p-value, FDR decision, diagnostic, sensitivity, or source
row, and do not run Quarto or knitr.

## Required verification

Before execution:

- reproduce all identities above;
- prove the dedicated script has no model, prediction, inferential, source-data
  write, Quarto, or broad-builder path;
- verify the frozen CSV has the accepted 90 rows, ten interaction panels, nine
  country-coded sites, and the stored plotting columns, without changing it;
- record a protected inventory covering the two accepted QMDs, main H06,
  config, frozen CSV, registry, SVG, historical alt-text CSV, and relevant
  accepted scientific outputs.

After the one bounded R command:

- return the exact command, R and consequential plotting-package versions,
  runtime, and exit status;
- return PNG pre/post SHA-256, byte count, pixel dimensions, and resolution;
- prove the frozen CSV, site registry, two QMDs, SVG, historical alt-text CSV,
  main H06, config, and protected scientific inventory are byte-identical;
- verify that the dedicated refresh script changed no data mapping, ordering,
  layer, scale, facet, geometry, color, dimension, or theme value relative to
  the accepted plot construction, apart from the three specified text labels;
- inspect the refreshed PNG at original size and at a 170 mm final display
  width. Check every title, subtitle, footer line, facet label, country-coded
  site label, axis label, point, interval, overlap, clipping, wrapping, and
  effective text size;
- confirm there is no visible `equal-site`, uncoded site name, clipped text,
  overlap, or unintended change to plot marks;
- write a new non-circular display-refresh manifest and visual-QA record in
  H06-daily-owned audit paths; and
- run focused static checks and `git diff --check` for the new script and
  records.

Do not render either QMD and do not request profile integration yourself.
Return the repaired PNG and evidence for independent harmonizer acceptance.
Shared-profile integration remains coordinator-owned and the REPORT-017 render
queue remains serial.
