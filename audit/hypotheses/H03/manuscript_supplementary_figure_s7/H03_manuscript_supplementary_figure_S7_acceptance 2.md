# H03 manuscript Supplementary Figure S7 acceptance

Date: 2026-08-31
Status: **PASS, SEALED FOR INDEPENDENT ACCEPTANCE**

## Scope

The bounded production task created one durable four-panel H03 manuscript
figure from frozen stored outputs. Panels a-c preserve the accepted near-eye
time-of-day display. Panel d presents the accepted site-average estimates and
site-specific deviation ratios from the light-source-by-site interaction
model.

No model or inferential RDS was loaded. No model, prediction, simulation,
bootstrap, scientific summary, source-data artifact, existing figure, QMD,
HTML, Quarto target, manuscript-selection source, package, lockfile, ledger,
commit, push, or upload was changed or executed.

## Candidate-first QA

The isolated candidate root was:

`/private/tmp/h03_manuscript_s7_candidate.AiLu2p`

The candidate was inspected at its original 4,725 by 7,375 pixel resolution
and at the intended 170 mm manuscript width. The complete figure, panel-d
header and overall row, all nine site rows, long confidence intervals,
non-estimable cells, footer, and panel joins were inspected. No clipping,
collision, truncation, missing cell, or material imbalance was found.

The 170 mm preview has SHA-256
`6afaf9a3d1af03ac5057074720dffc4742cd7d00d31d4ff514c9253f34da6550`.
The panel-d 170 mm preview has SHA-256
`92cda129cff5b7ec4ac3f46a42a5451b04bdabc0fed64ae20a42ee48bd695163`.

The canonical PNG and SVG are byte-identical to the inspected candidate. The
accepted temporal raster differs only in 4,096 pixels inside the three
authorized uppercase-to-lowercase panel-tag boxes. No temporal pixel outside
those boxes changed.

## Preservation results

- All seven site-average estimates, intervals, and indoor-reference ratios
  reproduce the accepted factorization table.
- All 63 site-category records reproduce their accepted ratios, intervals,
  FDR emphasis decisions, support values, and reporting states.
- All ten unsupported site-category cells remain `Not estimable`.
- Adjusted p-values are displayed to the accepted three-decimal grammar, with
  values below 0.001 printed as `<0.001`.
- Category support retains participant-hours, participants, participant-days,
  and sites for every category.
- The accepted overall statement is unchanged: 17,935 participant-hours, 140
  participants, 801 participant-days, and nine sites.
- Each accepted H03 participant-hour has one mutually exclusive primary
  light-source category. The figure explicitly records that 1/k multi-label
  weighting does not apply.
- The temporal source-model flag remains `site_effects_excluded = TRUE`.
- Panel d remains tied to stored `full_literal` interaction-model estimands.
- The seven light-source and nine site palette values have no shared hex
  colour. Country-coded labels, fixed row order, borders, and alternating row
  fills provide non-colour cues.
- Visible text uses “site-average estimate” and “light-source-by-site
  interaction model”. It does not use “heterogeneity model”.
- Bold lowercase panel tags a, b, c, and d are present exactly once.

## Output identities

| Output | SHA-256 |
|---|---|
| `artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.png` | `4287a9268a7ab4a462cfe39293cf3f675a7dce6264d3cc65c4124de581561f44` |
| `artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.pdf` | `f92e7d8ea583fc32e92e477645c5df3453b262b0192bab7cc2051981790d30fa` |
| `artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.svg` | `c683d814fa8006298767b4d0db50af9b628b59e52258d52cabb262519610fb8b` |
| `artifacts/12_manifests/H03/H03_manuscript_supplementary_figure_S7_manifest.csv` | `cb7a6a723880c4b6bf88354a3bf3fbb9979f09f0b1cec2ad6eb8a018b0939fb8` |
| `artifacts/08_diagnostics/H03/H03_manuscript_supplementary_figure_S7_display_qa.csv` | `30602a03f687f3286ca6a56f1cba91646e5d35ab21592dedddb097a4aa884be4` |
| `scripts/hypotheses/H03/build_h03_manuscript_supplementary_figure_s7.R` | `73a92dc8494d5475489766199df7f43e750bce3b5aad355188e376b5546e2308` |

The PNG is 4,725 by 7,375 pixels at 300 dpi. The SVG is 1,134 by 1,770
points. The PDF contains one 1,134 by 1,770 point page and rasterizes to the
same pixel dimensions at 300 dpi.

## Author-facing caption

**Near-eye light exposure by reported light source across time of day and
study site.** **a-c**, Exploratory time-of-day analysis. Panel a shows
expected one-hour melanopic EDI and pointwise 95% confidence intervals; the
dashed line is the site-average local-clock smooth. Panel b shows each
light-source curve relative to that smooth, with 1 as the reference. Panel c
shows available participant-hours; open circles indicate locally sparse
support and grey gaps indicate no observations. **d**, Site-average category
estimates and site-specific deviation ratios from the light-source-by-site
interaction model, with participant-cluster-robust 95% confidence intervals,
FDR-adjusted values, and exact support. The analysis includes 17,935
participant-hours from 140 participants, covering 801 participant-days and
nine sites. Panels a-c and panel d answer different questions and are not
numerically interchangeable. Estimates are observational. During reported
sleep, measurements describe the bedside sleep environment.
