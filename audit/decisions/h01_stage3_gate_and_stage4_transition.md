# H01 Stage 3 gate and Stage 4 transition

Decision ID: `H01-010`  
Date: 2026-08-01  
Status: approved

## Evidence

The author approved the standalone H01 reader-facing report after the added
site-by-metric outcome table was rendered and reviewed. The accepted table
contains the eight primary near-eye metrics with a supported overall-site
test, all nine DISPLAY-001 sites, the applicable deviation or ratio with its
95% confidence interval, and bolding only when the within-metric adjusted
p-value is below 0.050.

The accepted Stage 3 artifacts are:

- source: `notebooks/hypotheses/H01.qmd`, SHA-256
  `9f9619d48f2e776200379e3274e9c49a69b7369a2951773b33002374877017d5`;
- Nature Health HTML: `_build/nathealth/notebooks/hypotheses/H01.html`,
  SHA-256
  `5d5aaabc819ed375659dc4192c5ef5b933d47eba25a01590e69ebdb81cab8838`.

The focused H01 reporting and HTML-structure test passes under R 4.6.1. The
render contains 36 semantic `gt` tables and implements the required
`Answer in brief` callout. Stage 3 uses the accepted stored H01 analytical
outputs and does not refit a model or rerun a bootstrap.

## Decision

Accept H01 Stage 3 and authorize Stage 4. The continuing H01 task may create
`audit/hypotheses/H01/H01_analysis_preparation.qmd` as the scientific
analysis-preparation and provenance companion required by REPORT-007.

Stage 4 must:

1. describe, in reader-facing language, the exact data-to-result chain behind
   the accepted H01 report;
2. use stored outputs and bounded identity or lightweight descriptive checks
   only;
3. identify the scripts, model frames, fitted models, bootstrap outputs,
   diagnostics, tables, figures, source data, and manifests that produced the
   accepted results;
4. remain reciprocal-linked and adjacent to the H01 result page after the
   coordinator-owned website integration; and
5. preserve the accepted Stage 3 estimates, intervals, p-values, sensitivity
   classifications, diagnostics, displays, and claim scope.

Stage 4 must not refit models, regenerate predictions, rerun bootstraps or
simulations, recalculate scientific results, or modify shared Quarto
configuration. It is documentation of the accepted result-producing pipeline,
not another scientific analysis stage.

## Reopening condition

Reopen Stage 3 if Stage 4 identifies a scientific or provenance discrepancy,
an accepted input or output changes, a focused verifier fails, or the
reader-facing report or manuscript exceeds the accepted inferential scope.
