# H06_daily timing-repair route acceptance addendum

- Date: 2026-08-12
- Verified pilot gate: **H06-D-010 / CHG-120**
- Author acceptance: **H06-D-011 / CHG-121**
- Gate: **H06-D-G2P-TIMING-REPAIR**
- Status: **author approved; production not authorized**
- Scientific computation in this closure: **none**

## Controlling acceptance

The author accepted the participant-cluster HC3 route exactly as recommended
at the timing-repair pilot gate. The controlling acceptance is
`audit/decisions/h06_daily_timing_repair_acceptance.md`, SHA-256
`739c654b9920f08b7da44fe3ecd667cfd30eb56fece91a3efae137c256623869`.
The independently verified pilot gate is
`audit/decisions/h06_daily_timing_repair_pilot_gate.md`, SHA-256
`f398f748369351e084f19caba05a11636e8aead3df9ccd3586c8338100083461`.

This acceptance selects a prospective method for the four held timing
outcomes. It does not accept a pilot estimate, confidence interval, p-value,
or scientific claim, and it does not authorize the remaining non-L10
production grid.

## Accepted prospective route

For M10 midpoint, L10 midpoint, first timing above 250 lx melEDI, and last
timing above 250 lx melEDI, the accepted candidate route retains the sealed
participant-day outcomes and encodings, fixed-site adjustment, and the three
approved predictors. The reduced, additive, and predictor-by-site structures
remain:

```r
response_value ~ site
response_value ~ site + predictor
response_value ~ site * predictor
```

The mean structures use `stats::lm()`. Uncertainty uses participant-cluster
HC3 covariance from
`sandwich::vcovCL(type = "HC3", cadjust = TRUE, fix = FALSE)`, with
cluster-minus-one t/F reference distributions and pointwise 95% confidence
intervals. If production is separately authorized, this route must be applied
uniformly across all three predictors and retain the declared 15-slot
multiplicity families and the complete diagnostic record.

## Frozen pilot evidence and retained qualifications

All 12 candidate cells remain numerically acceptable under the candidate
route. The 24 stored Wald tests remain labelled
`PILOT_RAW_ONLY_NO_BH_UPDATE`; their adjusted-p fields remain missing, and no
Benjamini--Hochberg update or decision was made.

The author accepted the route with every pilot qualification retained:

1. The Student-t association sensitivity for first timing above 250 lx
   melEDI, Work day versus Free day, shifts by 1.23 HC3 standard errors. This
   is a major limitation.
2. The no-nugget AR association sensitivity for L10-midpoint activity shifts
   by 1.26 HC3 standard errors. This is a major limitation.
3. Three additive no-nugget AR diagnostics remain unresolved because they did
   not converge: M10 midpoint with previous-night sleep, first timing above
   250 lx melEDI with Work/Free day, and last timing above 250 lx melEDI with
   Work/Free day.
4. No no-nugget AR structure met the descriptive pooled-and-every-site
   residual-lag rule.
5. Timing predictor-by-site interactions remain sensitivity-dependent. They
   cannot support an unqualified interaction or site-specific claim, including
   when a diagnostic sensitivity reverses a coefficient or does not converge.

These qualifications are part of the accepted route and may not be removed
because a later test is statistically significant or another sensitivity is
more favorable.

## Preservation and no-refit closure

The pilot QMD and HTML, transition, model bundle, diagnostics, tables,
figures, source data, input/code/output/software/pipeline/figure/report
manifests, and focused pilot test retain their verified identities. The final
preservation evidence contains 571 protected pre-existing H06_daily files;
the focused acceptance test live-rehashes all of them against the sealed
record.

The new non-circular acceptance manifest is
`artifacts/12_manifests/H06_daily/H06_daily_timing_repair_acceptance_manifest.csv`.
It pins this addendum, the focused acceptance test, and the controlling frozen
evidence, but deliberately excludes itself. The focused verifier is
`tests/hypotheses/H06_daily/test_h06_daily_timing_repair_acceptance.R`.

This closure did not fit or refit a model, recompute a diagnostic or p-value,
update a multiplicity field, run a deletion analysis or resampling procedure,
or render a document.

## Stop boundary

The participant-cluster HC3 route is accepted, with the limitations above,
but production remains unauthorized. No remaining-grid analysis, BH update,
chest or paired/common analysis, gap-timing-unaware analysis, Stage 2 merge,
Stage 3, Stage 4, website integration, shared edit, L10 or MDER change,
temporal-GAMM or pre-sleep change, main-H06 change, commit, or push is
authorized.

There is no authorized analytical next step after this no-refit closure. A
separate explicit author decision is required before production.
