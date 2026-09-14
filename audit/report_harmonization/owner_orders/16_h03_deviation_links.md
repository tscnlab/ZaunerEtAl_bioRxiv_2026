# Harmonization follow-up 16 — exact H03 deviation links

Date: 2026-08-12  
Owner task: `019fbe52-c067-7521-b2cf-62d9398d173b`  
Controlling decisions: REPORT-014 / CHG-124, REPORT-016 / CHG-126, and CHG-128  
Dispatch mode: **source-only exact-link integration; no Quarto render or scientific execution**

## Exact owned documents and dispatch identities

| Source | SHA-256 at order preparation |
|---|---|
| `notebooks/hypotheses/H03.qmd` | `e9bfdf643fe96e1feb2a164d59fbba86d2d50c04125a60e1fe881e34503a0974` |
| `audit/hypotheses/H03/H03_analysis_preparation.qmd` | `ec49a51d4b3b91c60220ca67e467319ca0ccb10a680590cd7ece24f2f3f4bb7d` |

Recheck both identities immediately before editing and stop on drift. Keep
all accepted data, formulas, estimates, intervals, tests, diagnostics,
sensitivities, tables, figures, captions, and stored outputs frozen.

## Result-report link integration

Change `## Preregistration deviation` to
`## Preregistration deviations {#h03-preregistration-deviations}`. Replace
only its current two-sentence paragraph with the following concise linked
list, using these exact relative QMD targets and no additional IDs:

- **Study-site structure ([DEV-013](../preregistration_deviations.qmd#dev-013)).**
  The registered random-effects architecture was not retained because site
  support did not justify the registered random-slope formulation and the
  participant-day component collapsed. The accepted analysis uses fixed
  study-site adjustment for the population-average category association and
  a separate category-by-site interaction model.
- **Response model ([DEV-014](../preregistration_deviations.qmd#dev-014)).**
  The registered Gaussian response formulation had inadequate distributional
  diagnostics. The accepted fixed-power quasi-Tweedie log-mean models with
  participant-clustered covariance accommodate the non-negative, right-skewed
  response and exact zeros. They are mean models, not calibrated
  zero-generating distributions.
- **Light-source categories ([DEV-022](../preregistration_deviations.qmd#dev-022)).**
  The analysis retains all seven prespecified categories under one
  placement-independent support rule and labels unsupported site-category
  cells rather than silently deleting categories.
- **Primary and site-interaction questions ([DEV-023](../preregistration_deviations.qmd#dev-023)).**
  The additive model supplies the primary six-restriction category omnibus;
  the separate category-by-site interaction model supplies descriptive means,
  ratios, and site-specific variation.
- **Multiple-testing adjustment ([DEV-024](../preregistration_deviations.qmd#dev-024)).**
  False-discovery-rate adjustment is applied to each explicitly assembled
  complete contrast family; category and site-interaction questions remain
  separate families.

This wording restates the current REPORT-016 dispositions and scientific
content already documented elsewhere in the accepted report. Do not reframe
the primary omnibus as an interaction test, turn the working response family
into a calibrated probability model, change the seven-category construct, or
replace reader-facing FDR with BH.

## Companion link

In the opening paragraph that links to the H03 results report, change only
that link sentence to: `The [H03 results report](../../../notebooks/hypotheses/H03.qmd)
presents the scientific findings and its [preregistration deviations](../../../notebooks/hypotheses/H03.qmd#h03-preregistration-deviations).`
Do not duplicate the five-entry list in the preparation/provenance companion.

## Boundary

Do not fit or refit a GLM/GAM, calculate predictions, re-estimate
autocorrelation, rerun leave-one-site-out checks, bootstrap, simulate,
recalculate an allocation, rebuild an asset, or run Quarto. Do not edit
configuration, ledgers, artifacts, scripts, tests, bibliography, lockfile,
manuscript, or another QMD. Preserve the existing explicit model limitations,
non-estimable cells, country-coded site names, FDR language, and principal
output order.

## Focused evidence to return

- pre/post SHA-256 values for both QMDs and exact changed source lines;
- confirmation that all five relative QMD targets and anchors resolve and
  that the companion link resolves to the unique result-section anchor;
- confirmation that no hard-coded internal `.html`, `file://`, `_build`,
  build-directory, or absolute local page link remains;
- identical chunk-label, assignment, inline-R, artifact-reference, and
  figure/table identifier sets;
- confirmation that formulas, values, table/figure code, captions, alt text,
  and scientific claims outside the replaced paragraph are byte-identical;
- scoped status/diff showing exactly these two owned QMDs; and
- `git diff --check` for the two sources.

Do not render in this follow-up. Focused Phase 4 renders remain separately
released.
