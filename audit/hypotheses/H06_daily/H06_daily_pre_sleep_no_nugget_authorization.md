# H06_daily pre-sleep no-nugget diagnostic authorization

- Date: 2026-08-11
- Parent gate: **H06-D-G2P-AR**
- Authorized execution: **one bounded pre-sleep AR diagnostic only**
- L10: **shared numerical-zero implementation pending; excluded**
- MDER: **approved and frozen; excluded**
- Remaining daily production grid: **not authorized**

## Author decision

The author approved one diagnostic refit for duration below 10 lx melEDI before
sleep with previous-night sleep duration as predictor. It must use the
unchanged 648-day near-eye frame, the same fixed effects, participant random
intercept, actual-date gap-aware AR(1) sequence structure, Gaussian identity
family, REML estimation, and `dispformula = ~0`.

The execution must fit exactly one model and reapply the complete input,
sequence-support, numerical, covariance-singularity, AR-coefficient,
effect-stability, residual-temporal, Gaussian-distribution, and physical-bounds
gate. It is an engineering diagnostic, not authorization for an association
claim, p-value, multiplicity decision, independent-model refit, alternative
family, deletion analysis, resampling, remaining-grid fit, Stage 3/4 output, or
site integration.

## L10 decision and boundary

The author classified the three L10 values of
`4.163336342344337e-17 lx` as numerical zeros, plausibly introduced by the
10-hour averaging calculation. H06_daily must not change them locally. The
coordinator has been asked to verify and implement a shared provenance-based
rule, audit downstream effects, rebuild affected artifacts, and issue targeted
repinning instructions. L10 remains excluded from this diagnostic and on hold.
