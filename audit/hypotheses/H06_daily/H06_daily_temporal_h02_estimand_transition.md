# H06 daily exploratory temporal estimand transition

- Date: 2026-08-11
- Status: **author confirmed; corrected bounded near-eye pilot authorized**
- Scope: exploratory 30-minute temporal analysis only
- MDER: unaffected and still on its separate upstream hold

## Author decision

After a read-only cross-check with the scientifically closed H02 task, the
author confirmed replacement of the earlier H06_daily temporal proposal with
an H02-comparable estimand and model structure.

The superseded temporal pilot modeled the 30-minute zero-aware geometric-mean
melEDI response with one-part Tweedie and two-part occurrence/magnitude
candidates. It also supplied cyclic marginal bases to the `sz` and `fs`
smooths. Those fits remain frozen engineering history but cannot determine the
response family, basis dimension, temporal contrasts, or production model for
the confirmed analysis. The daily-metric portion of that pilot is not changed
by this transition.

## Authoritative H02 evidence

The cross-check used:

- `artifacts/07_models/H02/selected_temporal_model_specification.csv`,
  SHA-256
  `c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f`;
  and
- `artifacts/07_models/H02/main__glasses__all_available__selected_model.rds`,
  SHA-256
  `45fa9d6b28a10a7c09d1bd4541c009977eebb8ccdbcda5f33ba306934b20acc7`.

The stored fit was inspected read-only under R 4.6.1 and mgcv 1.9-4. It is a
Gaussian identity-link `bam()` of
`log10(30-minute arithmetic-mean melEDI + 0.1 lx)`. Its exact structural
formula is:

```r
response ~
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

Only the global clock smooth is cyclic. The primary H02 `sz` and `fs` terms
have no `xt` argument and use their default thin-plate time marginals.

## Confirmed H06_daily estimand

Let `Y` be the admissible 30-minute arithmetic mean melEDI in lx and
`Z = log10(Y + 0.1 lx)`. The exploratory H06_daily temporal analysis targets
the conditional expected transformed profile

```text
E[Z | local clock time, work/free day, daily activity status,
     previous-night sleep duration, site, participant, participant-day].
```

This is an observational association estimand. On the display scale,
`max(0, 10^eta - 0.1)` is the inverse transform of a mean log response. It is
geometric-mean-like for `Y + 0.1` and, under the fitted Gaussian log model, is
also a conditional median. It is not the raw-scale arithmetic expectation
`E[Y]`.

Work/free day and Sedentary/Active status are day-level labels. Their temporal
terms use sum-to-zero factor smooths with default, non-cyclic thin-plate time
marginals. Previous-night sleep duration is decomposed on the exact fitted
participant-day sample into:

1. the participant's equally day-weighted mean, centred on the equally
   participant-weighted grand mean; and
2. the day's deviation from that participant mean.

This separates between-participant from within-participant sleep-duration
associations. Both sleep varying-coefficient functions use default non-cyclic
thin-plate time marginals. The three contexts enter one jointly adjusted
exploratory model.

## Corrected pilot formula and fitting contract

The bounded near-eye pilot will evaluate:

```r
response ~
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, work_free_day, bs = "sz", k = 12) +
  s(time_hour, activity_status, bs = "sz", k = 12) +
  s(time_hour, by = sleep_between_h, k = 12) +
  s(time_hour, by = sleep_within_h, k = 12) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

It inherits H02's fREML, `discrete = TRUE`, one-thread setting, local midpoint
clock coordinate, 0/24 global knots, true-time ordering, and AR-boundary
algorithm. The full corrected formula is first fitted with `rho = 0`; rho is
the boundary-aware lag-1 correlation of response residuals, clamped to
[-0.95, 0.95], and the identical formula is refitted with that fixed rho.
Neither H02's numerical rho nor the superseded H06_daily pilot rho is reused.

The pilot performs no effect inference, bootstrap, simulation, chest fit,
paired/common-sample fit, or gap-timing-unaware fit. It must report exact
support, convergence, basis capacity, residual distribution, remaining
temporal dependence, identifiability, runtime, and an explicit acceptable/not-
acceptable verdict before any temporal association is interpreted.
