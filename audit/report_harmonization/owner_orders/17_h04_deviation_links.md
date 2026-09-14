# Harmonization follow-up 17 — exact H04 deviation links

Date: 2026-08-12  
Owner task: `019febf4-4868-72f3-bd97-31a85e86f8f0`  
Controlling decisions: REPORT-014 / CHG-124, REPORT-016 / CHG-126, and CHG-128  
Dispatch mode: **source-only exact-link integration; no Quarto render or scientific execution**

## Exact owned documents and dispatch identities

| Source | SHA-256 at order preparation |
|---|---|
| `notebooks/hypotheses/H04.qmd` | `f98dad1241092ec4ee34513f8a7bd1ddda9d356b29432edbe4a86f0e6b1dfca1` |
| `audit/hypotheses/H04/H04_analysis_preparation.qmd` | `1389dcf9ccb3eb3a93f2d6a52f1793f3aaabbb09ac9ce294c2709c1c4ce656a8` |

Recheck both identities immediately before editing and stop on drift. Keep
all accepted data, formulas, estimates, intervals, tests, diagnostics,
sensitivities, tables, figures, captions, and stored outputs frozen.

## Result-report link integration

At the end of `## Model and estimand`, immediately before
`## Principal activity-category estimates`, add
`### Preregistration changes {#h04-preregistration-deviations}` followed by
this concise linked list. Use these exact relative QMD targets and no other
IDs:

- **Study-site structure ([DEV-013](../preregistration_deviations.qmd#dev-013)).**
  The accepted population-average category model uses fixed study-site
  adjustment, while a separate activity-by-site interaction model evaluates
  variation among sites. The site interaction does not redefine the primary
  omnibus test.
- **Response model ([DEV-014](../preregistration_deviations.qmd#dev-014)).**
  Fixed-power quasi-Tweedie log-mean models with participant-clustered
  covariance replace the registered Gaussian mixed model. They describe
  multiplicative mean comparisons and are not treated as calibrated
  zero-generating distributions.
- **Multi-label activity representation ([DEV-025](../preregistration_deviations.qmd#dev-025)).**
  The analysis collapses the three outdoor flags before pivoting, removes
  duplicate labels within an hour, gives each of $k$ concurrent retained
  categories weight $1/k$, and retains Other only when it is the sole
  selected category for descriptive display.
- **Primary and site-interaction questions ([DEV-026](../preregistration_deviations.qmd#dev-026)).**
  The additive site-plus-activity model supplies the primary activity
  omnibus; the separate activity-by-site interaction model supplies
  descriptive category means, ratios, and site-specific variation.
- **Multiple-testing adjustment ([DEV-027](../preregistration_deviations.qmd#dev-027)).**
  False-discovery-rate adjustment is applied to each explicitly assembled
  complete activity or site-interaction contrast family.

Do not add `IMP-021`: neither accepted reader source mentions the corrected
historical screen, and REPORT-016 requires that resolved implementation
history remain separate from the current scientific narrative. Do not turn
statistical uses of “site deviation” into preregistration links, expose BH in
reader-facing text, change Other's display-only role, or alter the $1/k$
estimand.

## Companion link

Inside the opening `About this analysis record` callout, extend the existing
results-report sentence to: `The [H04 results report](../../../notebooks/hypotheses/H04.qmd)
presents the findings and its [preregistration changes](../../../notebooks/hypotheses/H04.qmd#h04-preregistration-deviations).`
Do not duplicate the five-entry list in the preparation/provenance companion.

## Boundary

Do not fit or refit a GLM/GAM, calculate predictions, re-estimate
autocorrelation, rerun influence checks, bootstrap, simulate, recalculate an
allocation, rebuild an asset, or run Quarto. Do not edit configuration,
ledgers, artifacts, scripts, tests, bibliography, lockfile, manuscript, or
another QMD. Preserve non-estimable cells, limitations, country-coded site
names, FDR language, category order, and principal output order.

## Focused evidence to return

- pre/post SHA-256 values for both QMDs and exact changed source lines;
- confirmation that all five relative QMD targets and anchors resolve and
  that the companion link resolves to the unique result-section anchor;
- confirmation that `IMP-021` was not added and that statistical
  site-deviation language was not linked;
- confirmation that no hard-coded internal `.html`, `file://`, `_build`,
  build-directory, or absolute local page link remains;
- identical chunk-label, assignment, inline-R, artifact-reference, and
  figure/table identifier sets;
- confirmation that formulas, values, table/figure code, captions, alt text,
  and scientific claims outside the inserted list are byte-identical;
- scoped status/diff showing exactly these two owned QMDs; and
- `git diff --check` for the two sources.

Do not render in this follow-up. Focused Phase 4 renders remain separately
released.
