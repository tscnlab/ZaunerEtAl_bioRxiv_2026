# H11 Stage 2 inferential-method decision

Date: 2026-08-01  
Gate: Stage 2 method amendment  
Status: **approved**

## Decision received in the H11 task

The author explicitly approved `H11-METHOD-001` through
`H11-METHOD-007` from
`audit/hypotheses/H11/02_inferential_method_amendment.html`.

The author additionally reiterated:

> use pointwise estimates instead of simultaneous for the 95% CI - if that is
> still of relevance

This clarification is relevant and is implemented as the already proposed
`H11-METHOD-005`: all displayed curve intervals are participant-cluster-robust
pointwise 95% confidence intervals. They are not simultaneous bands and may
not be used to claim a familywise-supported clock-time period.

## Approved amended contract

1. Remove the planned `ML`, `discrete = FALSE` comparison fits and the
   delta-AIC support rule.
2. Test the complete 48-bin Female-minus-Male curve from each existing final
   `M_pattern` fREML/discrete fit.
3. Use AR-whitened participant-summed scores, a CR1 sandwich covariance, the
   `mgcv` smoothing-bias component `Vp - Ve`, and the approved finite-cluster
   fractional-rank F reference.
4. Retain one global test per placement and BH adjustment across the two
   level/shape decomposition tests within placement.
5. Use participant-cluster-robust pointwise 95% intervals; do not interpret
   contiguous pointwise exclusions as a simultaneous significant period.
6. Open the H02-like descriptive effect-size branch within a main placement
   only when its one-test global robust raw p-value is below 0.050. Fit an
   fREML/discrete `M0` only after that gate and only for descriptive fitted-
   prediction effect-size estimators.
7. Retain leave-one-site-out sensitivity and explicit fixed-site,
   associational biological-sex limitations for the later sensitivity gate.

Any effect-size resampling in this Stage 2 execution remains limited to the
already approved 50-replicate non-inferential pilot. A production bootstrap
requires a separate computation approval.

## Outcome-awareness and scope

Feasibility values existed before this approval because evaluating numerical
stability and runtime necessarily evaluated the test. The method amendment is
therefore outcome-aware and must be recorded as a registered deviation. The
decision is justified by estimand match, participant-level robustness,
compatibility with the accepted H02 structure, and bounded runtime; it does
not authorize causal or population-of-sites claims.
