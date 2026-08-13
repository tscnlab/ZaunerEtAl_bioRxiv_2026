# H06_daily timing-repair pilot transition

- Gate: `H06-D-G2P-TIMING-REPAIR`
- Controlling authorization: `H06-D-009 / CHG-119`
- Date: 2026-08-12
- Status: bounded pilot complete; awaiting author decision

## Completed scope

The primary near-eye, all-available timing-repair pilot used the 12 exact
sealed frames authorized in `H06-D-009`: four participant-day timing outcomes
by the three approved day-level predictors. The candidate route was applied
uniformly:

```r
response_value ~ site
response_value ~ site + predictor
response_value ~ site * predictor
```

The models were fitted with `stats::lm()`. Uncertainty used participant-cluster
HC3 covariance from `sandwich::vcovCL(type = "HC3", cadjust = TRUE,
fix = FALSE)`, with cluster-minus-one t/F reference distributions. The pilot
also ran the prespecified fixed-mean Student-t and actual-date, gap-bounded
no-nugget AR(1) diagnostic sensitivities. No p-value from a sensitivity model
was substituted for a candidate p-value.

## Gate evidence

- All 12 source frames match their exact object hashes, participant-day counts,
  participant counts, site counts, encodings, and contrasts.
- All 36 candidate mean models are full rank. All 36 unmodified HC3 covariance
  matrices are finite, symmetric, positive semidefinite, and usable without
  `fix = TRUE`; all 12 candidate cells pass the numerical/design gate.
- All 36 Student-t fits converge. The overall predictor association is stable
  in 11 of 12 Student-t comparisons; first timing above 250 lx melEDI for
  work/free day shifts by 1.23 HC3 SE and is a substantial limitation.
- Of the 12 additive no-nugget AR fits, nine converge. Eight converged
  association comparisons are stable; L10-midpoint activity shifts by 1.26
  HC3 SE and is a substantial limitation. The three nonconverged additive AR
  comparisons are classified as unresolved, not stable.
- Site-heterogeneity coefficients are sensitivity-dependent: 10 of 12
  Student-t interaction comparisons and five of seven converged AR interaction
  comparisons meet the prespecified instability rule. Five AR interaction
  fits are unresolved because they did not converge.
- No no-nugget AR fit meets the descriptive post-AR pooled-and-every-site lag
  rule. This is disclosed but is not an independence failure for the candidate
  route: participant-cluster HC3 permits arbitrary within-participant
  dependence.
- The serial bounded pilot fitted 108 models in 6.46 seconds. The mechanical
  timing-only projection across the 12 declared scenario roles is 77.5
  seconds. No resampling or deletion fit was run in this repair pilot.
- All 571 protected pre-existing H06_daily files remain byte-identical.
- Exactly 24 raw pilot Wald tests were stored. Every adjusted-p field is
  missing and every test is labelled `PILOT_RAW_ONLY_NO_BH_UPDATE`.

## Recommended author disposition

Accept the participant-cluster HC3 route for later production of the four
timing outcomes, with two bounded qualifications:

1. Carry the two 1–<2-SE overall-association sensitivities as major limitations
   (L10-midpoint activity under AR and first timing work/free under Student-t),
   and retain the three nonconverged additive AR checks as unresolved
   diagnostics rather than evidence of stability.
2. Treat timing predictor-by-site heterogeneity as sensitivity-dependent. Run
   its prespecified robust tests and retain their named multiplicity slots if
   production is approved, but do not make an unqualified site-heterogeneity
   claim when the diagnostic sensitivity reverses a site coefficient or does
   not converge.

This recommendation does not accept any pilot association or p-value. It does
not itself authorize production, BH updates, deletion batches, chest,
paired/common, gap-timing-unaware scenarios, Stage 3, Stage 4, main-H06 edits,
or final H06 integration.

## Decision required

The author must either:

- accept the recommended constrained timing route and separately authorize
  the complete remaining non-L10 production grid; or
- keep one or more timing outcomes on hold and specify a new scientific
  amendment.

Until that decision, all downstream work remains stopped at
`H06-D-G2P-TIMING-REPAIR`.
