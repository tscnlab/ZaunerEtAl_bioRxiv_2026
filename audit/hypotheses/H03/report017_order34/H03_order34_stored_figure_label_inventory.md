# H03 deferred stored-figure label inventory

Date: 2026-08-14

Status: inventory only; no figure was rebuilt or edited

## Near-eye category-by-site context

Frozen family:

| File | SHA-256 |
|---|---|
| `artifacts/10_figures/H03/H03_near_eye_site_context_estimates.png` | `382a929e9ca5a9154fff3c509ba9bf116ebce00d61dd60227d559d10009872a8` |
| `artifacts/10_figures/H03/H03_near_eye_site_context_estimates.pdf` | `d13a4daa0ddba02c308e297cd6f9d7b8eca8c6214d73a10a34063d3c064f85b0` |
| `artifacts/10_figures/H03/H03_near_eye_site_context_estimates.svg` | `7b433203d57f2b7b91a0a46b8b187c89cc959a24146e3335e2c6e5d327ae7541` |

Frozen source data:
`artifacts/11_source_data/H03/H03_near_eye_site_context_figure_data.csv`,
SHA-256 `2d4ce68c9ac3fba8b31b5b7f190ee0f923ed1ba5d741045040cfde51e011f172`.

Frozen display function:
`h03_site_context_figure()` in
`scripts/hypotheses/H03/h03_reporting.R`, SHA-256
`1412a89c52a5aa7d65559de5e2b927dcbaad64a990bffb11dc876e6fad6a2342`.

The SVG still contains the baked phrases `BH-adjusted site deviation`,
`site-standardized category mean`, and `53 H03-F4 site-deviation contrasts`.
A later bounded refresh should change labels only to `FDR-labelled site
deviation`, `site-average category mean`, and `53 supported site-deviation
contrasts`. It must preserve every point, interval, line, colour, axis,
facet, dimension, and source-data row.

## Exploratory latitude context

Frozen family:

| File | SHA-256 |
|---|---|
| `artifacts/10_figures/H03/H03_reader_latitude_category_slopes.png` | `e27b7a8d84cabae1ab3e9694302a275da2f7bfd106df02a530a54ed48f5d9a15` |
| `artifacts/10_figures/H03/H03_reader_latitude_category_slopes.pdf` | `d2db711358d6cdfd3f4c54e686449102208de48b2c325a35382f860f4253bfbe` |
| `artifacts/10_figures/H03/H03_reader_latitude_category_slopes.svg` | `b994deeaa3c6335912cdc14ef0d53af932103091479d43d6665680320bfb75ec` |

Frozen source data:
`artifacts/11_source_data/H03/H03_reader_latitude_figure_data.csv`, SHA-256
`30bb81bb176440368a45d8b3fd6e3fdc443a53d10eb440995cb0c904954536b2`.

Frozen builder:
`scripts/hypotheses/H03/build_h03_stage3_revision.R`, SHA-256
`6d1eaacee852865b7b696653d0ee27cfd23d2001085aaf8612e2874521f87379`.

The SVG still says that filled points pass `BH adjustment across seven
category slopes within placement`. A later bounded refresh should use `the
within-placement FDR label across seven category slopes`. It must preserve
every point, interval, colour, axis, facet, dimension, and source-data row.

No later refresh may refit the latitude model or recalculate an adjusted
p-value. It must read the frozen label flag and plotted values.

