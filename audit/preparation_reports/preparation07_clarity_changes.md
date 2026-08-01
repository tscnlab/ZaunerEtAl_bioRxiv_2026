# Preparation 07 reader-facing rewrite and display QA

Date: 2026-08-01

Page: `notebooks/preparation/07_example_days.qmd`

Rendered HTML: `_build/nathealth/notebooks/preparation/07_example_days.html`

## Scientific purpose and execution boundary

- Reframed the page as a display-only inspection of accepted one-minute
  preparation artifacts, before hypothesis modeling.
- Named the three exact scientific inputs and verified their current SHA-256
  identities without loading the coverage or daylight RDS objects.
- Stated explicitly that no Preparation 07 selection, source-data, or figure
  artifact enters H01–H11; hypothesis inputs come from Preparation 06.
- Replaced the live call to `verify_prepared_day_showcase_artifacts()` with
  direct reads of stored CSV outputs plus bounded file-identity, schema, and
  lightweight structural checks.
- Explained that the production verifier reopens the scientific inputs and
  reproduces the fixed-seed selection, but that this result-producing verifier
  is not rerun or represented as a render-time check.

## Reader-facing changes

- Added an opening purpose, exact inputs, chain position, informational render
  note, and Mermaid data-to-display diagram.
- Explained the build driver, producer module, and independent verifier in
  execution order, including what each reads, why it is separate, and what it
  produces.
- Translated the stored selection settings into plain scientific language:
  near-eye placement, 50%-per-hour and 80%-per-day coverage, complete diary
  timing, declared non-wear, civil daylight, local wall-clock display, and
  retained UTC provenance.
- Split the formerly wide participant-day table into separate timing and data
  availability tables.
- Replaced both `knitr::kable()` tables with seven semantic `gt` tables.
- Used submitted site names, order, and registered colour markers throughout
  the site tables.
- Reported nine selected participant-days, 12,960 one-minute rows, 12,480
  valid melEDI minutes, 480 declared non-wear minutes, no other unavailable
  minutes, a valid-share range of 82.2% to 100.0%, and fixed seed 20260730,
  all calculated only from the stored display CSVs.
- Named and linked every stored output, including the paired figure source-data
  CSV and accepted PNG/SVG.

## Figure changes and REPORT-011 QA

The accepted 3 × 3 production figure and its source data were not changed.
For the HTML page, the same accepted source-data CSV is redrawn as three
three-panel figures in submitted site order. This is a display-only operation;
no exposure value, state, selected day, eligibility decision, or analytical
artifact is recalculated or overwritten.

Figure settings use 9 pt axis, tick, and legend text; 9.5 pt facet text and
legend title; and a 10 pt axis title. Each figure is 9.5 inches wide at 150 dpi
and displayed at 100% page width. Final-size QA used 900-pixel-wide copies,
matching the review page's effective content width.

QA result: **PASS**.

- no clipping or cropping of axes, units, facets, participant/date labels,
  time ticks, legends, state bands, or data traces;
- no overlaps, distorted text, awkward wrapping, or orphaned units;
- no long labels that squeeze the data region;
- three balanced panels per row with consistent scales and adequate plot area;
- black traces, dashed contextual steps, civil-night shading, diary-period
  colours, and red non-wear marks remain distinguishable;
- every figure has an informative caption, specific alt text, and the paired
  source-data link.

The in-app browser security policy blocked programmatic navigation between two
local `file://` pages. The HTML contract, local-resource resolution, explicit
table widths, and rendered figure files were therefore checked directly; no
alternate browser-navigation workaround was used.

## Bounded checks and identities

- Static source test: PASS.
- Rendered HTML test: PASS.
- `gt` tables: 7.
- accessible profile figures: 3.
- scoped pre-render baseline:
  `audit/preparation_reports/preparation07_prerender_scoped_readset.csv`;
- scoped baseline SHA-256:
  `d969d3b04d817ab6de822bef34e38c09eb2f606df172e7796a1996858a9b2da7`;
- post-render comparison:
  `audit/preparation_reports/preparation07_postrender_scoped_verification.csv`;
- scoped result: 28 of 28 paths unchanged, zero mismatches;
- source QMD SHA-256:
  `fbb37a1e0d209c58a33d53e121a00921cedf4ccfa03be104d76302ff2023302e`;
- focused test SHA-256:
  `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f`;
- rendered HTML SHA-256:
  `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc`;
- rendered figure SHA-256 values:
  `ad6ee88b1df7a0b2f17d513825d74887cc009b74317ae23d43bb16a14c2d9ad8`,
  `837d65b0f35f490e2c76ac4e170ebd633a349c4aff821fe82eae2be7ebb6b53d`,
  and
  `fd6f1cb73718674fdb6544e89bb684be0723bb33378709c399c4b161e1ec5629`.

No package was installed or updated. No preparation builder, scientific
verifier, metric calculation, model, prediction, bootstrap, simulation,
Shapley calculation, or H01–H11 computation was run.
