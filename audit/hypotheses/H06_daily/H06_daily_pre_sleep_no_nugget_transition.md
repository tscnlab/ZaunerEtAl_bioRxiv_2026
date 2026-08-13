# H06_daily pre-sleep no-nugget transition

- Date: 2026-08-11
- Gate: **H06-D-G2P-AR-NN**
- Status: **author approved on 2026-08-11; bounded diagnostic closed and frozen**
- Verdict: **ACCEPTABLE as a temporal-stability sensitivity**
- Fits run: **one**
- L10: **shared numerical-zero implementation pending; excluded**
- MDER: **approved and frozen; excluded**
- Remaining daily production grid: **not authorized**

## Authorized question

The diagnostic asks only whether fixing the Gaussian residual dispersion at
glmmTMB's `dispformula = ~0` value resolves the earlier numerical failure while
preserving the same pre-sleep frame, fixed effects, participant random
intercept, and actual-date gap-aware AR(1) structure. It does not test or
promote a new association claim.

The fitted formula was:

```r
response_value ~ site + previous_sleep_duration_centered_h +
  (1 | participant_key) +
  ar1(day_index_factor + 0 | day_sequence_id)
```

The response is duration below 10 lx melEDI before sleep in hours. The
predictor coefficient is the change in that duration per one-hour greater
previous-night sleep duration. The Gaussian identity model used REML and
`dispformula = ~0`.

## Exact execution and sample

All 13 direct inputs passed their pinned identities. The current reconstructed
frame is exactly identical to the authorized frame: 648 participant-days, 139
participants, nine sites, 198 gap-delimited participant sequences, and 450
true adjacent-day pairs. The one fit took 0.243 seconds. No independent refit,
L10 or MDER fit, remaining-grid fit, bootstrap, simulation, or deletion refit
was run.

## Final diagnostic result

The no-nugget model:

- converged with a positive-definite Hessian and zero warnings;
- was not singular;
- estimated participant and AR standard deviations of 0.655 h and 0.798 h;
- estimated AR rho at -0.085;
- retained the frozen-model effect direction with a 0.130-standard-error
  shift;
- reduced the conditional pooled residual lag-1 to -0.135, with maximum
  absolute site lag 0.276;
- passed the Gaussian Q-Q, residual-spread, extreme-residual, and physical-
  prediction checks; and
- passed every prespecified domain.

The engineering coefficient was -0.108 h per one-hour greater previous-night
sleep duration, with model-based 95% interval -0.157 to -0.058 h. This value is
reported only to demonstrate stability against the frozen independent and
failed free-dispersion AR fits. This bounded gate does not promote an
association p-value, multiplicity decision, or scientific claim.

## Parameter-map audit correction

The first post-fit verdict was falsely negative because the audit checked
whether `fixef(model)$disp` was nonempty. In glmmTMB 1.1.14,
`dispformula = ~0` retains the fixed dispersion value for reporting but maps it
out of the optimized parameter vector. The no-refit finalizer verified:

- the stored dispersion formula is `~0`;
- the dispersion parameter map is entirely `NA`, so the parameter is fixed;
- no dispersion parameter occurs in the optimized vector; and
- the fixed residual standard deviation is 0.000122070 h, exactly the package
  control value.

The finalizer changed only the derived specification and overall verdicts from
not acceptable to acceptable. It did not refit or alter the model, effect,
uncertainty, covariance parameters, residuals, or any other diagnostic.

## H06-D-G2P-AR-NN approval record

The author approved **H06-D-G2P-AR-NN** as recommended on 2026-08-11. The
accepted disposition is to:

1. accept the no-nugget pre-sleep AR counterpart as an acceptable, gap-aware
   temporal-stability sensitivity;
2. retain the independently specified fixed-site participant-intercept model
   as the primary route rather than promoting this diagnostic coefficient as a
   separate finding;
3. accept the transparent parameter-map audit correction and immutable
   preliminary provenance; and
4. keep L10 and the remaining daily production grid on hold until the
   coordinator implements the author-approved shared numerical-zero rule and
   supplies downstream impact and repinning instructions.

This approval closes and freezes the bounded diagnostic. No Stage 3/4 output,
site integration, manuscript change, shared preparation change, commit,
upload, or additional fit is authorized by this transition. The separate L10
and remaining-grid hold remains in force.
