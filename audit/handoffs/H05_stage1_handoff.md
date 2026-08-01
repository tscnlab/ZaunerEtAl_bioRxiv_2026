# H05 Stage 1 handoff

Status: **complete at the author gate; Stage 2 blocked**

## Scope completed

This worker performed only H05 Stage 1 for the Nature Health analysis audit.
It reconstructed the analysis that produced the submitted manuscript result
(V0), audited the LEBA scores and the exact 17 × 4 association family,
verified participant/day/site support by placement, reconciled the V0 site
screen and correlation calculations, and specified author-facing H05-G1
options. No proposed H05 model, bootstrap, or sensitivity analysis was run.

## Primary deliverables

- `audit/hypotheses/H05/01_audit_and_plan.qmd`
- `audit/hypotheses/H05/01_audit_and_plan.html`
- this handoff
- `audit/handoffs/H05_shared_change_request.md`

Machine-readable audit evidence in `audit/hypotheses/H05/`:

| File | Data rows |
|---|---:|
| `h05_stage1_findings.csv` | 11 |
| `h05_stage1_leba_factor_audit.csv` | 20 |
| `h05_stage1_leba_site_support.csv` | 36 |
| `h05_stage1_v0_associations.csv` | 136 |
| `h05_stage1_v0_metric_support.csv` | 34 |
| `h05_stage1_v0_pair_counts_by_site.csv` | 1,156 |
| `h05_stage1_v0_paired_support.csv` | 17 |
| `h05_stage1_v0_site_contrasts.csv` | 2 |
| `h05_stage1_v0_site_screen.csv` | 4 |

## Controlling preregistration evidence

The exact signed H05 statement is:

> H5: LEBA questionnaire factors correlate with selected personal light exposure metrics.

The signed method is `Correlation matrices + linear models: Metric ~ LEBA +
(1|Site)`. The supporting DOCX is ambiguous about the model outcome and does
not override the signed PDF. H05-G1 must therefore choose whether the
registered site-adjusted metric model is primary or whether the pooled
participant correlation remains primary as an explicit deviation.

## Reproduced V0 facts

- LEBA contains 184 unique `site × Id` rows across nine sites. All 20 item
  responses and all four factor scores are complete.
- F2 is items 04–09 with only item 04 reversed; F3 is items 10–14, F4 items
  15–18, and F5 items 19–23. All stored scores reproduce exactly. Possible
  ranges are 6–30, 5–25, 4–20, and 5–25; observed ranges are 6–26, 6–23,
  4–20, and 5–22.
- V0 selects exactly 17 metric rows with non-missing H01 `response`, then
  crosses them with four factors for 68 cells per placement. It averages all
  daily metrics arithmetically within participant, applies no minimum-day
  rule, and drops pairs cell by cell.
- Near-eye source support is 141 participants/811 days/nine sites. Chest is
  154 participants/897 days/eight sites. Exact metric and cell denominators
  are in the CSVs.
- V0 common placement support is 112 participants/eight sites. Most daily
  metrics have 640 common participant-days; timing metrics 603; MDER 476 days
  and 111 participants; pre-sleep 615; sleep 621; and wake-state time above
  250 lx melEDI 592 days and 111 participants.
- The four questionnaire site-screen p-values are adjusted as one vector after
  unnesting. F2 and F5 pass; effect contrasts identify UCR/F2 (−2.703,
  adjusted p = 0.0002) and BAUA/F5 (−2.239, adjusted p = 0.0250). The shared
  migration map’s contrary scalar description is addressed in the scoped
  shared-change request. The screen still cannot justify omitting site.
- In each association cell, V0 combines a Spearman coefficient with a Pearson
  test and scalar `p.adjust(..., n = 68)`. No registered site-adjusted outcome
  model is fitted.
- On frozen V0 near-eye summaries, a consistent Spearman test and one
  68-value BH vector retain F2 with melEDI dose (rho = 0.272; raw p = 0.00111;
  adjusted p = 0.0377) and time above 1,000 lx melEDI (rho = 0.290; raw
  p = 0.000478; adjusted p = 0.0325). These are diagnostics, not final H05
  results.
- Chest V0 highlights F2 with dose (rho = 0.202; displayed p = 0.042), but its
  consistent Spearman/vector-BH value is 0.204 and no chest cell remains
  flagged.
- The RQ2 prose incorrectly renames the highlighted 1,000-lx outcome as
  duration above 250 lx. It also treats squared rank correlation as explained
  variance. The chest prose duplicates the near-eye interpretation.

## Recommended H05-G1 disposition

Approve the registered site-adjusted analysis as primary:

- 15 participant-day metrics:
  `response_value ~ leba_centered + (1 | site) + (1 | site:participant)`;
- participant-level IS/IV:
  `response_value ~ leba_centered + (1 | site)`;
- compare each full model with a reduced model that removes only LEBA on an
  identical model frame;
- inherit the approved metric-specific H01 response-family/transform package;
- use one complete 68-test near-eye BH family;
- retain participant-level Spearman output as descriptive estimates,
  intervals, and exact support without a second significance screen; and
- use fixed-site, leave-one-site-out, and paired-placement outputs as
  predeclared stability analyses.

Near-eye remains the main placement. Chest is complementary on the exact
paired/common sample, and near-eye is rerun on that sample to separate
placement from sample composition. The audit document specifies the clock
rules, response families, multiplicity alternatives, diagnostics,
sensitivities, and failure gates in full.

## Author gate

The author must approve and log: H05-G1; the factor and metric manifests; the
participant-day/participant model hierarchy; response families; LEBA scaling;
site handling; multiplicity across main, manuscript-prepared-data, and chest
scenarios; clock rules; placement/common-sample roles; interval methods; the
diagnostic/sensitivity menu; failure rules; and withdrawal/replacement of V0
claims. The exact 13-decision checklist is in the audit document.

Until then, do not fit proposed models, inspect candidate H05 results, run a
bootstrap or sensitivity battery, modify `notebooks/hypotheses/H05.qmd`, edit
the manuscript, or update shared decision/deviation ledgers.

## Verification performed

- R 4.6.1 with the project library; consequential package versions are
  printed in the rendered audit.
- Frozen SHA-256 checks passed for both V0 metric workspaces and the normalized
  LEBA input.
- Render-time assertions passed for key uniqueness, score reconstruction,
  17/4/68/136 dimensions, V0 and consistent-method flag counts, site-screen
  results, pair-count persistence, and 17-row paired support.
- Quarto 1.9.37 rendered the standalone embedded-resource HTML successfully.
- The HTML is derived directly from the delivered QMD; no project or Quarto
  configuration file was changed.

## Scope guard

No production notebook, script, manuscript, configuration, shared ledger,
decision record, `renv.lock`, figure, or source-data file was modified. No
commit, push, upload, or external message was made.
