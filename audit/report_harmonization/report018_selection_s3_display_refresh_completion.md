# REPORT-018 selection-page S3 display refresh completion

Date: 2026-09-01

Status: **PASS**

## Scope

This bounded post-acceptance refresh mirrors the independently accepted
Supplementary Figure S3 presentation in the figure and table selection page.
It changes display geometry only:

- desktop width is 82% with a 44-rem cap;
- the image is centred within its figure; and
- width returns to 100% at 708 px and below.

Supplementary Table S2 already used the accepted 126-rem table and 22-rem
metric-stub geometry and was not changed. The accepted main manuscript,
standalone Supplementary Information, manuscript sources, scientific assets,
captions, values, and all other selection-page content were preserved. The
main manuscript and Supplementary Information were not rerendered.

## Selection identities

| Artifact | Pre-refresh SHA-256 | Final SHA-256 |
|---|---|---|
| Selection QMD | `506363929f27268f765c940c33cbbc2bf089aac8619484576d7027c837677dfa` | `1e29b5f4a83343978bbb4bf8e841072d1b941832991e3fa78139517738044676` |
| Selection HTML | `c259ac5fbf2f5284fe01cccf763c783454036810ae18d3194101dd14c43b2cec` | `82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6` |

The final canonical QMD and HTML were byte-identical to the temporary
candidate copies used for the replacement gate.

## Structural verification

```text
Rscript --vanilla scripts/report_harmonization/replay_manuscript_figure_table_selection_integration.R
MANUSCRIPT_SELECTION_INTEGRATION_REPLAY=PASS fragments=20 repaired=4 substitutions=259 manifest=37 R=4.6.1 gt=1.3.0

Rscript --vanilla scripts/report_harmonization/check_manuscript_table3_gt_candidate_revision.R
TABLE3_REVISION_CHECK=PASS checks=14

Rscript --vanilla scripts/report_harmonization/check_remaining_manuscript_gt_candidates.R
REMAINING_GT_CHECK=PASS checks=15

Rscript --vanilla scripts/report_harmonization/check_supplementary_composite_figures.R
SUPPLEMENTARY_COMPOSITE_CHECK=PASS checks=14 manifest=17 R=4.6.1

quarto render audit/manuscript_nature_health/manuscript_figure_table_selection.qmd --to html --no-execute

Rscript --vanilla scripts/report_harmonization/check_manuscript_figure_table_selection.R
MANUSCRIPT_DISPLAY_SELECTION=PASS checks=41 tables=23 gt=20 images=53 headers=2882 html=82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6 bytes=30925051 R=4.6.1
```

The new 41st structural check pins the S3 figure ID, desktop CSS block, and
708-px responsive CSS block exactly once.

## Browser verification

At 1280 by 720, the canonical page loaded all 53 images and all 23 tables,
with no page-level horizontal overflow. S3 rendered as a centred block at
82% of its figure width with the 44-rem cap active.

At 390 by 844, all 53 images remained loaded and S3 rendered at 100% of its
figure width with `max-width: 100%`. The page retained its existing local
wide-table scrolling behaviour. The viewport was reset after the check. The
browser console contained no warnings or errors.

## Non-circular seal

The companion manifest
`audit/report_harmonization/report018_selection_s3_display_refresh_completion_manifest.csv`
contains 12 exact input and output identities. It deliberately excludes this
completion record and the manifest itself.

