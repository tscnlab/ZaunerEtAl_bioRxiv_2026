# H06_daily bounded daily AR-repair pilot stop gate

- Date: 2026-08-11
- Gate: **H06-D-G2P-AR**
- Status: **pre-sleep no-nugget diagnostic approved and frozen under
  H06-D-G2P-AR-NN; L10 upstream implementation pending**
- Scope: **two non-MDER daily-family repairs only**
- MDER: **approved, complete, and frozen**
- Remaining daily production grid: **not authorized**

## Completed bounded work

The author authorized a production-code pilot of two daily AR repairs after
main-H06 confirmed that no competing heavy computation was active. H06_daily
fitted exactly four models:

1. an independent `glmmTMB` Gaussian calibration and an actual-date,
   gap-aware AR(1) counterpart for duration below 10 lx melEDI before sleep,
   with previous-night sleep duration as predictor; and
2. the same two covariance forms for the positive-magnitude component of L10
   mean melEDI, with work/free day as predictor.

Each AR counterpart used:

```r
response_value ~ site + predictor +
  (1 | participant_key) +
  ar1(day_index_factor + 0 | day_sequence_id)
```

The default Gaussian residual dispersion was retained. A missing calendar date
started a new sequence, and the day index restarted within that sequence. No
observed dates were compressed across a gap.

The current post-MDER frames were analytically identical to their frozen
pre-rebuild counterparts, including ordered participant-day keys, values,
columns, and factor levels. The pre-sleep frame contained 648 days, 139
participants, nine sites, and 450 true adjacent-day pairs. The positive-L10
frame contained 680 days, 140 participants, nine sites, and 484 pairs.

After fitting, the broad shared base-model-data manifest changed from the
controlling `6cfbfb18...` identity to `b6fa2283...`. The directly used
near-eye participant-day object remains byte-identical at `fb04a84f...`, and
all task-owned frames and outputs still match their fit-time hashes. The drift
is qualified in `audit/handoffs/H06_daily_shared_change_request.md`; no new fit
or downstream repinning is allowed until the preparation coordinator
reconciles it.

## Prespecified verdicts

Both repairs are **NOT_ACCEPTABLE**.

### Pre-sleep duration

The AR coefficient retained the frozen direction and shifted by 0.130 frozen
standard errors. Its residual distribution, physical bounds, and post-AR
temporal screen passed. The fit nevertheless returned false-convergence code
8, two warnings, and a non-positive-definite Hessian; residual standard
deviation collapsed to `8.8e-05 h`. Numerical fit is a mandatory domain, so no
association result or test was promoted.

### Positive L10 magnitude

The AR coefficient retained the frozen direction and shifted by 0.897 frozen
standard errors. The model returned singular-convergence code 7, estimated rho
at 1.000 to displayed precision, left pooled residual lag-1 at -0.491 and the
maximum absolute site lag at 0.932, and failed the Gaussian distributional
rule. It is not usable for inference.

The underlying exact-zero split also retains three strictly positive L10
values of `4.163336342344337e-17 lx`, which become -16.381 under `log10()`.
H06_daily did not threshold, round, remove, or reclassify them. Their intended
scientific status has been referred to the shared metric owner in
`audit/handoffs/H06_daily_shared_change_request.md`.

## Compute and claim boundary

The four model fits took less than one second of measured fitting time. No
remaining-grid fit, deletion batch, bootstrap, simulation, p-value,
multiplicity decision, or scientific association claim was produced. The
MDER model and all completed MDER-independent outputs were left unchanged.

## Decisions required at H06-D-G2P-AR

The recommended author decision is:

1. authorize one bounded no-nugget pre-sleep diagnostic using the unchanged
   frame and formula structure plus `dispformula = ~0`, with the complete
   acceptance gate reapplied before any result is considered;
2. retain the L10 hold until the shared metric owner classifies the three
   numerical-near-zero positive values;
3. if strict positivity is confirmed, require a separately specified and
   approved robust positive-magnitude family pilot; and
4. keep the remaining daily-metric production grid frozen until these two
   response-family decisions are resolved.

No Stage 3/4 output or website integration is authorized by this gate record.

## Author decision recorded on 2026-08-11

The author approved exactly one bounded no-nugget pre-sleep diagnostic using
the unchanged 648-day frame, fixed and random terms, actual-date gap-aware
sequence structure, Gaussian identity family, and `dispformula = ~0`. The
complete numerical, covariance, effect-stability, temporal, distributional,
and physical-bounds gate must be reapplied. This approval does not authorize an
independent-model refit, an association claim, another response family, a
remaining-grid fit, resampling, or deletion diagnostics.

The author also classified the three L10 values of
`4.163336342344337e-17 lx` as numerical zeros, plausibly created by the
10-hour averaging calculation. H06_daily must not implement that rule locally.
The coordinator has been asked to verify and implement a shared, provenance-
based numerical-zero rule, audit downstream ramifications, rebuild affected
artifacts, and issue targeted repinning instructions. Until those arrive, L10
and its multiplicity slots remain on hold. Once rebuilt, zeros must be retained
in zero-capable analyses and in the occurrence part of a two-part analysis;
they are excluded only from a strictly positive magnitude component by
definition, not discarded as participant-days.

## Bounded no-nugget execution

The authorized diagnostic fitted exactly one model in 0.243 seconds. The
648-day frame remained identical to its frozen/current reconstruction, with
139 participants, nine sites, and 450 true adjacent-day pairs. No independent
model, L10 model, MDER model, remaining-grid model, bootstrap, simulation, or
deletion refit was run.

The no-nugget model converged with a positive-definite Hessian, no warnings,
and no structured-covariance singularity. Its AR coefficient was -0.085. The
effect estimate retained direction and shifted by 0.130 frozen-model standard
errors. Post-AR pooled residual lag-1 was -0.135 and the largest absolute site
lag was 0.276; the Gaussian-distribution and physical-bounds checks passed.

The preliminary post-fit audit incorrectly treated the fixed dispersion value
returned by `fixef()` as freely estimated. A no-refit finalizer verified that
`dispformula = ~0` maps the dispersion parameter out of glmmTMB's optimized
vector while retaining its fixed reporting value. Correcting only that derived
audit field changes the complete verdict to **ACCEPTABLE**; the fitted model and
every model-dependent diagnostic remain unchanged. The author approved
**H06-D-G2P-AR-NN** on 2026-08-11 as a temporal-stability sensitivity only;
the diagnostic is now closed and frozen.
