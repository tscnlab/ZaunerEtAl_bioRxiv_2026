# H11 Stage 1 author decision

Date: 2026-08-01  
Gate: Stage 1 to Stage 2  
Status: **approved with two author amendments**

## Decision received in the H11 task

The author approved the recommendations in
`audit/hypotheses/H11/01_audit_and_plan.html`, with these changes:

1. Use pointwise 95% confidence intervals instead of simultaneous confidence
   bands, to remain consistent with H02.
2. Compute H02-like estimators of biological-sex effect size only if the sex
   contribution is supported.

All other Stage 1 recommendations, formulas, estimands, samples, placement
roles, model-comparison families, diagnostics, and deferred-analysis gates are
approved as proposed.

## Locked interpretation of the amendments

### Pointwise intervals

The H11 Female-minus-Male curve will use the H02 display convention: 95%
pointwise conditional intervals from the fitted coefficient covariance at the
48 observed 30-minute clock-bin midpoints. These intervals describe local
uncertainty at each displayed clock time. They do not provide simultaneous
95% coverage over the day and will not be used to claim a familywise-supported
"significant period." The global model comparison remains the inferential
test of the H11 sex contribution.

### Conditional effect-size gate

The primary effect-size branch opens only when the primary near-eye comparison
meets both predeclared support criteria:

- the BH-adjusted global `M0` versus `M_pattern` ML comparison has
  `p < 0.05`; and
- `AIC(M0) - AIC(M_pattern) >= 2`.

If these criteria disagree, the primary result is inconclusive and the
primary effect-size branch remains closed. The complementary chest branch is
assessed by the same two criteria within its own `H11-C1-global` family; it may
produce a chest effect-size description, but it cannot open, rescue, or
overturn the primary near-eye branch. As in H02, effect-size estimation is
restricted to the main all-available near-eye and chest analyses and is not
repeated for the manuscript-prepared-data sensitivity.

When the branch opens, Stage 2 will report H02-comparable descriptive fitted-
model relevance estimators on the transformed response scale:

- the fixed-prediction in-sample row-weighted R-squared increment from the
  H02 temporal baseline `M0` to the full sex model `M_pattern` (with one sex
  block this is its exact conditional Shapley/general-dominance allocation);
- that increment as a share of full-model in-sample R-squared; and
- equal-clock fitted-curve variation across the two equally weighted
  biological-sex curves, in squared `log10(melEDI + 0.1 lx)` prediction units.

The relevance estimators are descriptive, conditional on the fitted models,
and are not causal, cross-validated predictive performance, or unique
observed variance explained. If hierarchical cluster resampling is used for
an interval, only the approved 50-replicate pilot may run in Stage 2. Pilot
intervals will be labelled preliminary and will not be used for inference or
reader-facing claims until a production run is separately approved.

## Scope and provenance note

No H11 model had been fitted when this decision was recorded. The original
Stage 1 source, render, and machine-readable artifacts remain unchanged as the
historical proposal that the author reviewed.
