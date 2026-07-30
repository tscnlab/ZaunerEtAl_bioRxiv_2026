# Zero-mass threshold-timing relevance map

Finding ID: `FIND-012`  
Decision ID: `METRIC-004`  
Status: canonical Preparation 03 repair independently verified; Preparation
04 result verification pending  
Severity: high  
Date: 2026-07-30

## Finding

The initial support-aware implementation derived support for first, last, and
mean timing above 250 lx from positive excess of the fixed median MEDI profile:
`max(median MEDI - 250 lx, 0)`. The pooled full-day median profile reached only
173.628 lx for glasses and 138.158 lx for chest. Its threshold-timing relevance
mass was therefore zero for both placements.

The pre-repair Preparation 04 reconciliation consequently returned no finite
first, last, or mean threshold-timing value on any of 811 near-eye or 897 chest
participant-days. The comparison artifacts contained finite baseline timings
for 778 near-eye and 867 chest days. This was a support-map construction
failure, not evidence that threshold events or their timings were absent.

Evidence:

- `artifacts/04_reference_profiles/reference_profiles.csv`;
- `artifacts/04_reference_profiles/metric_relevance_maps.csv`;
- `audit/reconciliation/preparation04/metric_distribution_summary.csv`; and
- `audit/scripts/compare_preparation04_baseline.R`.

## Approved repair

Preparation 03 now learns a separate fixed empirical distribution for strict
`MEDI > 250 lx` occurrence. For every participant-day and 30-minute bin, it
calculates the fraction of valid minutes exceeding the threshold. It then
gives equal weight to days within participant and equal weight to participants
within the pooled, site-specific, or leave-one-site-out profile.

The pooled placement-specific distribution is primary. Site-specific and
leave-one-site-out variants are sensitivities. The map is used only to score
temporal observation support: 0.80 is primary and 0.70/0.90 are fixed
one-axis-at-a-time sensitivities. It never scales, weights, or imputes an
observed timing value. A genuinely zero-mass learned distribution remains
non-estimable without a uniform or median-based fallback.

## Verification

`tests/test_reference_profiles.R` verifies strict threshold handling,
participant-day-then-participant balancing, pooled/site/leave-one-site-out
variants, support thresholds, zero-mass behavior, and isolation from all
non-timing maps under R 4.6.1. The focused test passes.

The canonical Preparation 03 rebuild now contains 1,728 distribution rows in
36 pooled/site/leave-one-site-out groups and 1,728 corresponding timing-map
rows. All 36 timing-map groups have positive, estimable relevance mass.

The independent complete verifier passed 394 of 394 checks. It reconstructed
all 288 median-profile groups and all 36 strict-exceedance distribution groups
from the immutable Preparation 02 inputs, reproduced all scientific values
and support fields, verified the exact distribution-to-map linkage, and
matched all 11 bytewise artifact hashes. The verified manifest SHA-256 is:

`c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d`

Preparation 04 values, estimable denominators, models, and claims remain
pending and must pass the major-result gate.

## Reopening condition

Reopen if the threshold, strict endpoint, aggregation hierarchy, 30-minute
learning resolution, profile variants, support cutoff registry, or
support-only interpretation changes, or if the rebuilt distribution has zero
mass or materially changes a result or conclusion.
