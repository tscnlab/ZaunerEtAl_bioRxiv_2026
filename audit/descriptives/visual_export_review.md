# Visual review of replicated descriptive exports

Date: 2026-08-03

## Verdict

**THE DESCRIPTIVE DISPLAY REBUILD PASSES; FIGURE 1 TYPOGRAPHY IS APPROVED AND
ITS REMAINING DETAIL REVIEW STAYS OPEN.** REPORT-011-PILOT-001 established the
Figure 1 export and typography reference. The submitted
10.5-by-10-inch base canvas is exported with the literal
`ggplot2::ggsave(scale = 1.5)` argument, producing a 15.75-by-15-inch,
4725-by-4500-pixel PNG at 300 dpi. Fonts, lines, points, keys, and other marks
are not multiplied. The complete descriptive display set was subsequently
rebuilt from the same verified stored inputs so that all eligible zero-containing
melEDI panels use `LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`.
No model, bootstrap, simulation, or hypothesis computation was run.

The author-supplied reference attachment and retained `figures/Fig1.png` are
byte-identical (SHA-256
`3933c77a9d9c64f3155f5c460619e586ba7f9a5c3ad20b97d99e7e58409344a1`)
and both are 4725 × 4500 pixels at 300 dpi. They therefore provide one exact
reference rather than two approximate screenshots.

Figure inspection used the A4 portrait mock-up at 100%, with 20-mm left/right
margins and a 170-mm figure region, solely as a QA scaffold. Submission-facing
PNG, JPEG, SVG, and PDF files retain tightly bounded figure canvases and are
not saved on A4 pages. The final HTML was also checked
structurally: it resolves to the exact current PNG, has non-empty alt text, and
sets `width:100.0%`. Browser-level visual inspection of the local `file://` page
is recorded as NOT TESTED because the browser security policy blocks local-file
inspection; it is not silently treated as a pass.

The Figure 1 export is 400.05 mm wide and is reduced to 170 mm only for that
diagnostic check. The approved source-level typography is recorded explicitly:
`theme_cowplot()` uses its 14-pt base, tick labels are 12 pt, axis titles and
tags are 14 pt, the caption is 11 pt, and map labels use `size = 3` (about
8.54 pt). Typography approval does not close the independent review of Figure
1 content details. The machine-readable dimensions, mock-up hash, status, and
notes are in `audit/descriptives/figure_readability_qa.csv` and
`artifacts/12_manifests/descriptives/figure_specifications.csv`.

The focused runtime test resolves the current component themes to 12-pt tick
text, 14-pt axis titles, 11-pt captions, and 14-pt plot tags. It then builds
the complete patchwork grob and verifies that tags A, B, C, D, and E each have
`fontsize = 14`; the map point and label layers both resolve to `size = 3`.
These values match the submitted generator's default `theme_cowplot()` and
`plot_annotation(tag_levels = "A")` settings.

At the 170-mm diagnostic check, no Figure 1 panel, label, caption, axis title, terminal
tick, vertical bracket, uncertainty band, or map callout is clipped. There are
no unresolved text collisions, distorted labels, awkward wraps, squeezed data
regions, or panel imbalance. The review concerns display only; scientific
values remain authoritative in the exported R-produced source CSV files.

## Table review

| Rebuilt output | Final pixels | Assessment |
|---|---:|---|
| `participant_site_characteristics_replica.png` | 2388 × 3022 | PASS. Full-roster participant information, roster-wide non-all-zero days, two-unit participant time, near-eye-only declared non-wear, no-wrap trailing counts, collection span, and civil photoperiod are visible without unwanted breaks. |
| `participant_site_characteristics_manuscript_replica.png` | 2388 × 2368 | PASS. The reduced Table 1 variant used in the submitted manuscript retains its submitted row selection and styling with the updated verified values. |
| `metric_descriptive_summary_replica.png` | 3560 × 3570 | PASS. Site columns are equal width; metric labels wrap to at most two lines; units are complete; grey `N`/`d` lines are legible; thumbnails do not inflate row height. |
| `recommendation_context_replica.png` | 1972 × 1658 | PASS. `Recommended range` wording, one-line `relevant / all` counts, registered site styling, and the stronger white separation below Overall are all visible. |

Table and figure captions are left aligned in the final Quarto HTML.

## Figure review at 170 mm

| Rebuilt output | Native size | Minimum essential text | Assessment |
|---|---:|---:|---|
| `descriptive_overview.png` | 4725 × 4500 px; base 10.5 × 10 in; export 15.75 × 15 in; diagnostic display 170 × 161.9 mm | Approved source settings: 12-pt ticks, 14-pt titles/tags, 11-pt caption, 3-unit map labels | TYPOGRAPHY APPROVED; DETAIL QA OPEN. The submitted three-row composition, approved source-level typography, accepted scientific content, 67% ribbon, average sleep/civil-night displays, and registered site styling are retained. The melEDI axis uses the exact `LightLogR` symlog transform. Literal `ggsave(scale = 1.5)` changes only the export device; it does not multiply plot parameters. The A4 file is diagnostic only. |
| `near_eye_site_profiles.png` | 2007 × 1559 px; 170 × 132 mm | 7.5 pt | PASS. The 3 × 3 repeated-48-hour site layout contains nested central 50%, 75%, and 95% value ribbons, pooled 15-minute medians, average sleep/civil night, the vertical recommendation bracket, and a complete legend and caption. |
| `chest_site_profiles.png` | 2007 × 1275 px; 170 × 108 mm | 7.5 pt | PASS. The eight available sites occupy a complete 4 × 2 layout with no orphan panel. Registered order/colours are preserved without recolouring after Tübingen is omitted. Ribbons, bracket, legend, and caption are legible. |
| `near_eye_metric_distributions.png` | 2007 × 2007 px; 170 × 170 mm | 7.5 pt | PASS. All 16 metric names remain on one line. Reduced clock and numeric break sets eliminate collisions while preserving the 4 × 4 ridge-plus-box layout and equal-size site displays. |
| `time_series_to_metrics.png` | 2007 × 1807 px; 170 × 153 mm | 9 pt | PASS. The exact pinned gap-timing-unaware V0 30-minute samples for seven participants and study days 2–6 are used. Rows are ordered by TAT250 recalculated from the displayed daytime samples: MPI_S226, BAUA_S003, MPI_S227, BAUA_S022, MPI_S205, TUM_S009, BAUA_S009. Panel C’s tag is separated from its vertical title, and the caption is split across three unclipped lines. |
| `latitude_photoperiod_diagnostic.png` | 2007 × 2007 px; 170 × 170 mm | 8 pt | PASS. Black-outlined site densities are drawn first and therefore remain behind the black impossible-photoperiod curtain. The internal registered-site legend has separated colour keys; axes and annotation remain legible. |

## Format and accessibility checks

- The Figure 1 PNG is exactly 4725 × 4500 pixels with 300-dpi metadata. The
  JPEG has the same pixel matrix; macOS reports its embedded density metadata
  as 72 dpi, so only the PNG is used as the 300-dpi contract evidence.
- The raster-backed PDFs have the same declared physical canvases within the
  one-PostScript-point MediaBox precision of R's PDF device; their embedded
  images match the verified PNG dimensions.
- Every SVG parses as a valid vector master.
- Six A4 QA mock-ups are retained under
  `artifacts/08_diagnostics/descriptives/a4_mockups/`; their physical page size
  and hashes are tested. They are diagnostic artifacts, never final figure
  exports.
- DISPLAY-001 supplies all reader-facing site labels, order, and colours.
  Labels, outlines, facets, and points provide non-colour identification.
- The final HTML contains four native `gt` tables, six resolving figure paths,
  non-empty figure alt text, and accessible decorative metric thumbnails.

This is an exact-style replication with updated data and approved corrections,
not a claim of pixel identity with the submitted files.
