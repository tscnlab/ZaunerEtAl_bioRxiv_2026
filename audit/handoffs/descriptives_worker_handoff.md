# Descriptive tables and figures: final handoff

Date: 2026-08-03

## METRIC-011 bounded addendum (2026-08-12)

The shared L10 numerical-zero normalization has been consumed in the
descriptives through a bounded L10-only refresh. Exactly eight participant-day
L10 mean values are now exact zero; every non-L10 source row and every figure
export is hash-identical. Table 2 retains identical visible three-decimal
values and an identical PNG while its L10 thumbnail source contains the three
corrected near-eye zeros under the registered threshold-1 symlog transform.
The current HTML, exact hashes, preservation evidence, tests, and environment
note are recorded in
`audit/handoffs/descriptives_l10_METRIC-011_handoff.md`.

## Outcome

The submitted descriptive tables and figures have been rebuilt with the
updated verified data, using the old manuscript-generating visual grammar and
the corrections approved during review. The final reader-facing report is:

`_build/nathealth/notebooks/descriptives.html`

Publication tables are native `gt` objects. Four table PNGs and six figure
sets (PNG, JPEG, PDF, and SVG) are available for side-by-side comparison with
the retained submitted files. Exact R-produced CSV sources, source hashes,
export specifications, alt text, and a complete output manifest accompany
them.

No model was fitted or refitted. No bootstrap, simulation, Shapley run, or
hypothesis computation was triggered. No package was installed and
`renv.lock` was not edited by this task.

### REPORT-011-PILOT-001 and REPORT-013 addendum

Figure 1 is the approved export-scale and typography reference. The implementation uses
the literal `ggplot2::ggsave(scale = 1.5)` mechanism with a 10.5-by-10-inch
base canvas, producing 15.75-by-15-inch exports. No font, line, point, key,
annotation, density, or other plot parameter is multiplied. The submitted
source-level text settings were restored separately as a replication repair:
14-pt `theme_cowplot()` bases, 12-pt tick labels, 14-pt axis titles and tags,
11-pt caption text, and 3-unit map labels.

The PNG is exactly 4725 × 4500 pixels at 300 dpi. The approved source settings
are 12-pt tick labels, 14-pt axis titles and panel tags, 11-pt captions, and
3-unit map labels. The 170-mm A4 mock-up is used only as a QA scaffold; final
PNG, JPEG, SVG, and PDF files use tightly bounded figure canvases and are not
saved on A4 pages. The mock-up shows no clipping, overlap, distortion, awkward
wrapping, or panel imbalance. HTML
structure confirms the exact copied asset, non-empty alt text, and 100% width.
Browser-level inspection of the local `file://` page is NOT TESTED because the
browser security policy blocks it. At 170 mm, the 8.5-pt nominal minimum is
3.61 pt effective, below the default REPORT-011 target; the status is therefore
`TYPOGRAPHY_APPROVED_DETAIL_QA_OPEN` because typography approval does not close
the independent review of Figure 1 content details.

The full descriptive display set was then rebuilt from the unchanged verified
inputs. Every reader-facing plot of nonnegative, strongly right-skewed melEDI
that contains true zeros now uses
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`. Panel C of the
time-series-to-metrics figure was given a separate tag margin and its caption
was split across three lines to remove overlap and clipping. No model,
bootstrap, simulation, or hypothesis analysis was run.

The supplied original attachment is byte-identical to retained
`figures/Fig1.png`: both have SHA-256
`3933c77a9d9c64f3155f5c460619e586ba7f9a5c3ad20b97d99e7e58409344a1`
and dimensions 4725 × 4500 pixels at 300 dpi. Runtime plot-object inspection
confirms 12-pt facet/axis text, 14-pt titles, 11-pt captions, and 3-unit map
labels/points; the assembled patchwork grob contains tags A–E at exactly 14 pt.

## Final requested changes

### General and tables

- Table and figure captions are left aligned in the Quarto HTML.
- Table 1 covers the full 191-person roster and every available non-all-zero
  day across near-eye and chest data. Participant time uses at most two units
  (`116w 4d` overall), only near-eye declared non-wear is displayed,
  `Screened days` reports the final result only, collection dates and civil
  photoperiod use the full available roster, and every trailing `(n=...)`
  display starts on a consistent no-wrap line.
- A second Table 1 reproduces the exact reduced variant embedded in the
  submitted manuscript and its Quarto source. It omits only MEQ score, Gender,
  Collection dates, Weekday/weekend, Workday/free-day diaries, Social jetlag,
  and Sleep duration while retaining the updated verified values and the
  submitted 1200-pixel/14-pixel display scale.
- Table 2 retains the submitted groups and styling. All ten site columns have
  equal widths; median, interval, mean ± SD, and size lines do not wrap.
  Lowercase `n` was dropped: `N` means participants and `d` means
  participant-days. The 72-pixel distribution thumbnails preserve the old
  aspect without setting the cell height; their curves use black outlines.
  A display bug that formatted duration SDs as minutes rather than hours was
  found during visual QA and corrected.
- The recommendation table says `recommended range`. Every percentage is
  followed by a compact one-line `relevant / all` count. Overall is separated
  from site rows by a thick white rule plus the fine neutral rule.

The `$create-gt-tables` workflow governed semantic `gt` structure, targeting,
footnotes, no-wrap spans, accessible thumbnail treatment, and standalone
table export verification.

### Figures

- Figure 1 uses the submitted 10.5-by-10-inch base canvas and literal
  `ggsave(scale = 1.5)`, yielding a 15.75-by-15-inch export that is displayed
  at 170 mm only in the diagnostic mock-up. The final assets are not A4 pages.
  Figures 2–5 retain their approved geometry but were regenerated from their
  verified source data to apply the exact symlog display rule where eligible.
- Figure 1 retains the submitted five-panel composition. The map uses the
  submitted projection and styling with deterministic, non-overlapping
  two-column leader labels, including white text for Izmir. Collection periods
  are rectangles spanning available dates and split after pauses of at least
  six dates. Panel E uses LightLogR fixed 15-minute pooling, site and Overall
  medians, a pointwise central 67% value ribbon for Overall, average diary
  sleep, average civil night, the submitted vertical sleep/pre-sleep/daytime
  bracket, no declared non-wear state, and a true `LightLogR` symlog y-axis
  with threshold 1.
- The near-eye site profiles use the submitted white-background 3 × 3
  repeated-48-hour design with nested central 50%, 75%, and 95% value ribbons.
  The eight-site chest complement uses a complete 4 × 2 grid, avoiding an
  orphan ninth panel. Both retain pooled 15-minute medians, average sleep and
  civil night, the vertical recommendation bracket, and no declared non-wear.
  Their shared source helper now also specifies true symlog threshold 1, but
  the retained Figure 2/3 files were intentionally not regenerated in this
  Figure 1-only pilot.
- Figure 3 keeps every metric name on one line and uses reduced clock/numeric
  tick sets so labels remain readable at 170 mm without collision.
- Figure 4 uses the exact pinned gap-timing-unaware V0 30-minute samples for
  study days 2–6. Top-to-bottom order by TAT250 calculated from those displayed
  daytime samples is MPI_S226, BAUA_S003, MPI_S227, BAUA_S022, MPI_S205,
  TUM_S009, and BAUA_S009. The submitted A–D layout and reader-facing caption
  are retained without clipping.
- Figure 5 consumes the verified current H1 latitude–photoperiod bounds. Site
  densities have black outlines and are drawn before, hence behind, the black
  impossible-photoperiod curtain. Legend keys are separated and registered
  site styling is retained.
- Figure 6 is the recommendation table described above.

REPORT-011 final-size visual QA is recorded in
`audit/descriptives/figure_readability_qa.csv` and
`audit/descriptives/visual_export_review.md`. Six A4 portrait mock-ups at 100%
are retained under `artifacts/08_diagnostics/descriptives/a4_mockups/`; only
the Figure 1 mock-up was regenerated for the corrected pilot.

## Exact sample contracts

| Construct | Final contract |
|---|---|
| Normalized participant roster | 191 participants |
| Available non-all-zero near-eye data | 143 participants; 1,134 participant-days |
| Available non-all-zero chest data | 157 participants; 1,246 participant-days |
| Available union across placements | 184 participants; 1,478 unique participant-days |
| Available paired data | 116 participants; 902 participant-days |
| Main near-eye data | 141 participants; 816 participant-days; 1,175,160 real minutes |
| Main chest data | 154 participants; 902 participant-days; 1,298,880 real minutes |
| Paired main subset | 112 participants; 643 participant-days |
| Profile source | 1,824 placement/site/profile rows; 96 fixed 15-minute bins per panel, repeated once for display |
| Figure 1 profile uncertainty | Pointwise central 67% value interval across eligible one-minute melEDI values; not a confidence interval |
| Figure 2/3 site-profile uncertainty | Nested pointwise central 50%, 75%, and 95% value intervals across eligible one-minute melEDI values; not confidence intervals |
| Mean-period source | 19 placement/site rows, rounded to 15 minutes |
| Table 2 | 17 metrics × Overall plus nine sites = 170 cells |
| Figure 4 examples | 7 fixed participants; 35 participant-days; 1,680 verified 30-minute bins |
| Recommendation context | Main near-eye sample; each cell carries its exact minute numerator and denominator |

Participant-level characteristics in Table 1 use the whole roster. Metric
values and their finite participant-day samples remain those of the verified
metric artifacts; Table 2 does not recalculate metrics.

## Provenance and shared rules

- All 12 pinned shared manifests passed before analytical inputs were read.
- DISPLAY-001 is consumed from `config/site_display_registry.csv` in the exact
  order Borås, Delft, Dortmund, Tübingen, Munich, Madrid, Izmir, San José,
  Kumasi. Registry SHA-256:
  `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.
- The full available-day domain extended beyond the dates in the verified
  shared solar-context artifact. The missing 146 site/date keys were produced
  in R with the project's existing canonical solar-context function and are
  labelled `canonical extension for available non-all-zero day` in
  `available_collection_days.csv`; no shared artifact was changed.
- Figure 5 consumes
  `artifacts/11_source_data/H01/stage3/H01_stage3_photoperiod_latitude_bounds.csv`,
  SHA-256
  `bec885c76b37d24b6c4e9fedfc9822405b6ec6fc85fe99f4e608081e0cd224c5`.
- REPORT-008 was reviewed. No inferential p-value is displayed in the
  descriptive report, so no p-value formatting action was required.
- ENV-001 lock SHA-256:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

## Durable outputs

### Tables

- `artifacts/09_tables/descriptives/participant_site_characteristics_replica.png`
- `artifacts/09_tables/descriptives/participant_site_characteristics_manuscript_replica.png`
- `artifacts/09_tables/descriptives/metric_descriptive_summary_replica.png`
- `artifacts/09_tables/descriptives/recommendation_context_replica.png`
- Matching authoritative CSV files are in the same directory.

### Figures

Each stem below has `.png`, `.jpeg`, `.pdf`, and `.svg` exports in
`artifacts/10_figures/descriptives/`:

- `descriptive_overview`
- `near_eye_site_profiles`
- `chest_site_profiles`
- `near_eye_metric_distributions`
- `time_series_to_metrics`
- `latitude_photoperiod_diagnostic`

### Source and audit artifacts

- `artifacts/11_source_data/descriptives/available_collection_days.csv`
- `artifacts/11_source_data/descriptives/collection_intervals.csv`
- `artifacts/11_source_data/descriptives/profile_summary.csv`
- `artifacts/11_source_data/descriptives/profile_context_bands.csv`
- `artifacts/11_source_data/descriptives/profile_average_periods.csv`
- `artifacts/11_source_data/descriptives/gap_timing_unaware_source_provenance.csv`
- `artifacts/11_source_data/descriptives/photoperiod_latitude_bounds.csv`
- `artifacts/11_source_data/descriptives/figure_alt_text.csv`
- `artifacts/12_manifests/descriptives/figure_source_data_map.csv`
- `artifacts/12_manifests/descriptives/figure_specifications.csv`
- `artifacts/12_manifests/descriptives/table_export_specifications.csv`
- `audit/descriptives/figure_readability_qa.csv`
- `audit/descriptives/visual_export_comparison.csv`
- `audit/descriptives/visual_export_review.md`

## Verification evidence

| Check | Result |
|---|---|
| Fresh R 4.6.1 full descriptive builder using the activated project library | PASS; tables and six figure sets regenerated from unchanged verified inputs; no model or resampling computation |
| `quarto render notebooks/descriptives.qmd --profile nathealth` using the activated project library | PASS; final HTML created |
| Full focused R test `tests/descriptives/run_tests.R` | PASS |
| Focused R test `tests/descriptives/run_figure1_export_scale_pilot_tests.R` | PASS; parse, exact geometry, symlog threshold 1, source/manifest hashes, HTML embedding, and Figure 2–5 isolation |
| Runtime typography comparison with the submitted generator | PASS; 12-pt ticks, 14-pt titles, 11-pt captions, 3-unit map labels/points, and assembled A–E tags all at 14 pt |
| Intended-size review using a 170-mm A4 scaffold | INSPECTED; no clipping, overlap, wrapping, distortion, or panel imbalance; A4 is diagnostic only |
| Figure 1 REPORT-011-PILOT-001 export contract | PASS; base 10.5 × 10 in, literal scale 1.5, export 15.75 × 15 in, PNG 4725 × 4500 at 300 dpi |
| Full-build manifest | PASS; all descriptive figure and table files match the current manifest |
| Rendered-HTML structural inspection | PASS; Figure 1 resolves to the exact current PNG, has non-empty alt text, and uses `width:100.0%`; browser visual inspection of `file://` is NOT TESTED |
| Full descriptive rebuild/full test suite | NOT RUN for the corrected pilot; prohibited by the Figure 1-only scope |

Current artifact fingerprints:

| Artifact | SHA-256 |
|---|---|
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |
| Figure 1 PNG | `3088cd0be1fc7c4e97ea75fabac15cd41c21a46d598afd84f0c9629f38c78b6c` |
| Figure 1 JPEG | `79297afe9621ccd1a605ea0a531f1eb8e394c8efdccae14abafa987106620d2d` |
| Figure 1 PDF | `b062a205493151147319463a51affa87515463bd90805cc91f616b6770fb11e6` |
| Figure 1 SVG | `a8818db7ba65900d40f17637ccdcb4a83eae82b378aa60eb457aeb2f85a2a470` |
| Figure 1 A4 mock-up | `143ec23d5eb10dbd460586125bca482f3fd16c8c98e4c4d9b08920d567a0bb4e` |
| `figure_specifications.csv` | `221b316661268482def2ccad6e2c1e492813e4eb100664649dd1da73104a3d2a` |
| `descriptive_artifacts.csv` | `170fb176df205f31a7c8b4c2e0408bb09ef72c9dacef49d3877e5e697a495089` |
| `figure_readability_qa.csv` | `f86c07772b02fa6aff9a2f525585f7b0b06687be3190280ebfaf73c4158ee1f1` |
| `visual_export_comparison.csv` | `3d86b3cf2596d3cb870dbf7cbb2e433aa8d1aea70b6381fe3a63abc867640983` |
| rendered `descriptives.html` | `8cdda3bde8cc6290b06e1eb75839f3e67053ee731c2c3107d08bb2d7496a79cf` |

Unchanged Figure 2–5 PNG and A4 evidence:

| Retained figure | PNG SHA-256 | A4 mock-up SHA-256 |
|---|---|---|
| `near_eye_site_profiles` | `cc7dc0c4cada66c32b312d68feab27598f280e3d8c73a804e5d5154a7aecfb84` | `fd049c645f4c767467cb3de328478ef432938744247ec857ef2dedefcb4ea9ed` |
| `chest_site_profiles` | `bb2457d93b80b598415f8e71eb02ab5f05c1ec323fac65ff2fe2f6338ac923c2` | `48b6b7723177f1002c3846183e59cd46f508ea0bf10a22fde3ab8b7af5689835` |
| `near_eye_metric_distributions` | `da934a2a75ac4e6fea912006f441e9429dad373bcdfe80120d822b45420d54e3` | `ec7a87a45fb227e4d5637f280df22c6c6ce1c428ed12e3dbb032b25c0d77ebe0` |
| `time_series_to_metrics` | `4394565089ba25c417e5058fa14449c6014e997bec0689f138053656dcf04b9d` | `68394c41c00f99edbbd288c7992c8143d9cc94c6347c4d86767a5f79f71a988d` |
| `latitude_photoperiod_diagnostic` | `72cd033dcaaab0276e610fcae768ee1bd986ae81e1855ef16f0565f46e8aeeca` | `f2b38489009ab7b630bd3f3c4b71e758db0d33e52d4ee95b9a1a9d2deb657c01` |

## Working-tree boundaries

This task did not switch branches, reset, clean, stage, commit, push, upload,
or edit shared configuration or `renv.lock`. Existing unrelated working-tree
changes were preserved. Descriptive changes are confined to
`scripts/descriptives/`, `tests/descriptives/`, `notebooks/descriptives.qmd`,
the descriptive artifact/audit directories, and the rendered descriptive
HTML; the coordinator-owned bounded environment script updated its standard
status evidence files when invoked.
