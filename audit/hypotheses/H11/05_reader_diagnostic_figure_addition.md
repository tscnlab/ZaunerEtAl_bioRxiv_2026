# H11 reader diagnostic-figure addition

Date: 2026-08-06  
Branch: `rewrite/NH`  
Status: **implemented and verified**

## Author request

The author requested that the reader-facing Diagnostics section show figures
for the main diagnostic outcomes. The report already contained separate
boundary-aware residual-autocorrelation figures for the primary near-eye and
complementary chest fits. This revision retains those figures and adds the
missing visual summary of residual location, tails, and fitted-value-dependent
spread.

## Display-only derivation

No model was fitted or refitted, and no prediction, bootstrap, simulation, or
diagnostic estimator was rerun. The new six-row reader source file is selected
and relabelled in R from the frozen Stage 2 diagnostic output
`artifacts/08_diagnostics/H11/stage2/residual_summary.csv`. It contains Overall,
Female, and Male summaries for the accepted primary near-eye and chest fits.

The resulting figure has two panels:

1. stored final standardized-residual 1st-99th, 5th-95th, and 25th-75th
   percentile ranges with the median; and
2. the stored correlation between absolute residual magnitude and the fitted
   value.

Residual medians are within 0.030 of zero. The 1st-99th percentile ranges are
approximately -1.96 to 2.11 near eye and -2.15 to 2.31 at chest overall, while
the absolute-residual/fitted-value correlations range from 0.197 to 0.240
across the overall and sex-stratified summaries. The display therefore makes
the accepted diagnostic interpretation visible: residuals remain centered
near zero, but heavy tails and heteroscedasticity remain. The pass/fail checks
for convergence, cyclic closure, site constraints, and basis-dimension flags
remain in the table.

## Files

- reader source data:
  `artifacts/08_diagnostics/H11/stage3/H11_reader_primary_residual_summary.csv`;
- reader figure:
  `artifacts/10_figures/H11/stage3/H11_reader_primary_residual_summary.png`
  and `.pdf`;
- report source: `notebooks/hypotheses/H11.qmd`;
- rendered report: `_build/nathealth/notebooks/hypotheses/H11.html`.

## Physical-size QA

This already-planned figure touchpoint also brought all reader figures into
the clarified REPORT-011 final-size geometry. The tightly bounded 10.5-inch
(266.7-mm) export is intended for 170-mm display, giving a reduction factor of
0.637420. Twelve-point essential source text resolves to 7.65 pt and 11-point
minor source text to 7.01 pt.

All eight exported figures were inspected on separate A4 portrait proof pages
at 170 mm with 20-mm side margins. A touching pair of inner facet-axis labels
in the new residual figure and an orphaned denominator in the activity figure
were corrected before PASS was recorded. The final eight-page proof has no
clipping, overlap, distorted text, awkward wrapping, compressed data regions,
or indistinguishable marks. The detailed record is
`audit/hypotheses/H11/03_figure_readability_qa.md`.

## Verification

The H11-only reader render completed with eight non-empty-alt-text figures and
the focused Stage 3 test passed. The scientific conclusions and every stored
inferential estimate are unchanged.
