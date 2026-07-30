# M10/L10 candidate-grid coupling

Finding ID: `FIND-013`  
Decision ID: `METRIC-005`  
Status: repair unit verified; canonical Preparation 04 rebuild pending  
Severity: high  
Date: 2026-07-30

## Finding

The first support-aware M10/L10 implementation evaluated one candidate for
each 30-minute relevance-profile bin. That coupled the search resolution to
the resolution of a fixed support map, although the exposure input and target
window were both defined on a one-minute grid. It could miss the true
brightest or darkest 600-minute interval whenever its start was not on a
half-hour boundary.

The intermediate baseline reconciliation combined this candidate restriction
with other approved metric repairs and therefore cannot isolate its numerical
effect. It nevertheless showed non-identical M10/L10 levels and approximately
0.30–0.52-hour mean absolute timing differences, confirming that candidate
resolution required an explicit, independently verified contract rather than
being inherited from profile resolution.

Evidence:

- `audit/reconciliation/preparation04/metric_paired_difference_summary.csv`;
- `audit/scripts/compare_preparation04_baseline.R`; and
- `scripts/pipeline/time_support.R`.

## Approved repair

Every candidate contains exactly 600 consecutive one-minute wall-clock
intervals. M10 evaluates all 841 non-wrapping starts from minute 0 through
minute 840. L10 evaluates all 1,440 starts with midnight wrapping. The learned
30-minute M10/L10 relevance profiles remain fixed and are expanded
deterministically to their constituent minutes; they are not relearned or
interpolated. L10 remains the darkest-window metric, and L5 is not calculated.

## Verification boundary

`scripts/pipeline/verify_rolling_windows.R` independently enumerates literal
candidate windows. `tests/test_verify_rolling_windows.R` verifies the exact
841/1,440 candidate domains, ordinary and profile-weighted support, profile
expansion, ties, fall-back duplication, deterministic missingness, ten
synthetic comparisons, and sixteen fixed project-data comparisons. Under
R 4.6.1, all comparisons pass; the largest candidate-level difference is
`3.93e-14` and the largest summary difference is `3.69e-13`.

This establishes unit equivalence of the optimized implementation, not a
canonical result. The staged Preparation 04 artifacts still predate the
every-minute search and must be rebuilt before reporting M10/L10
distributions, models, or claims.

## Reopening condition

Reopen if the one-minute grid, 600-minute window, wrapping rule, support-map
expansion, tie rule, zero offset, or candidate-support definition changes, or
if the canonical rebuild materially changes a result or conclusion.
