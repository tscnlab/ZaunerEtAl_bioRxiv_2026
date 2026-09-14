# Final figure and table selection refresh

Date: 2026-09-01

Status: **ACCEPTED SELECTION PAGE REFRESH PASSED**

## Scope

This bounded refresh updates only the figure and table selection document and
its deterministic replay and verification scripts. It does not modify or
rerender the accepted main manuscript or Supplementary Information.

The refresh:

1. preserves the approved Table 3 order from the descriptive table:
   Duration, Dynamics, Exposure history, Level, Spectrum, Timing;
2. preserves the exact 17-metric sequence within those groups;
3. replaces the two former Quarto composites for Supplementary Figures S6 and
   S14 with their accepted single-file SVG composites; and
4. extends the selection-page contract and pinned asset manifest to those
   accepted composites.

## Current artifacts

| Artifact | SHA-256 |
|---|---|
| Selection QMD | `506363929f27268f765c940c33cbbc2bf089aac8619484576d7027c837677dfa` |
| Selection HTML | `c259ac5fbf2f5284fe01cccf763c783454036810ae18d3194101dd14c43b2cec` |
| Selection asset manifest | `2bc35a8dd68ed492db10ef34495db01aef30e03163328ee50cfc268e921d0923` |
| Supplementary composite manifest | `cd455868e66efdb5cbe2510393e7fa59f4ff32bb319164b588c389ee6bd18f07` |
| Supplementary Figure S6 SVG | `2dde6fd681f21feecf2acb6d693679bc56f68f809691172bb755e7aac47fa032` |
| Supplementary Figure S14 SVG | `e4b1fe228897a7135bd017c7c01f80a796a43819d5c1078008f2a927093508b5` |

The canonical QMD and HTML are byte-identical to the temporary integration
check copies used for the replacement-render gate.

## Verification

```text
Rscript --vanilla scripts/report_harmonization/replay_manuscript_figure_table_selection_integration.R
MANUSCRIPT_SELECTION_INTEGRATION_REPLAY=PASS fragments=20 repaired=4 substitutions=259 manifest=37 R=4.6.1 gt=1.3.0

Rscript --vanilla scripts/report_harmonization/check_manuscript_table3_gt_candidate_revision.R
TABLE3_GT_CANDIDATE_REVISION=PASS checks=14

Rscript --vanilla scripts/report_harmonization/check_remaining_manuscript_gt_candidates.R
REMAINING_GT_CHECK=PASS checks=15

Rscript --vanilla scripts/report_harmonization/check_supplementary_composite_figures.R
SUPPLEMENTARY_COMPOSITES=PASS checks=14 manifest=17 R=4.6.1

quarto render audit/manuscript_nature_health/manuscript_figure_table_selection.qmd --to html --no-execute

Rscript --vanilla scripts/report_harmonization/check_manuscript_figure_table_selection.R
MANUSCRIPT_DISPLAY_SELECTION=PASS checks=40 tables=23 gt=20 images=53 headers=2882 html=c259ac5fbf2f5284fe01cccf763c783454036810ae18d3194101dd14c43b2cec bytes=30924880 R=4.6.1
```

## Browser inspection

The canonical HTML completed loading in the in-app browser at a 1280 by 720
viewport. All 53 images loaded, all 23 tables were present, document width
matched viewport width, and the browser console contained no warnings or
errors. Supplementary Figures S6 and S14 each resolved to one loaded composite
image. A temporary 390 by 844 viewport check confirmed all images still
loaded; the very wide table remains available through its local horizontal
scroller.

