# H07 Stage 2 derivative gate revision

Decision ID: `H07-002`
Date: 2026-08-07
Status: approved author revision during Stage 2

## Reason for reopening

After reviewing the Stage 2 support displays, the owner judged that the
pooled local-support rule answered a stronger cross-site overlap question than
the intended H07 question. The intended question is whether a photoperiod
association with a plateau-like derivative pattern is visible in the pooled
observed data, while retaining site, collection-period, support, and influence
limitations in the interpretation.

This is a post-result revision. It must not be presented as preregistered or as
fixed before inspection of the H07 Stage 2 output.

## Revised operational assessment

For each of the nine metrics and each placement separately:

1. use the already fitted site- and participant-adjusted
   `adapted_photoperiod_smooth` GAM;
2. evaluate the first derivative of `s(photoperiod_hours)` on a 100-point grid
   from the exact metric-specific minimum to maximum recorded photoperiod;
3. use central finite differences with forward/backward differences at the
   observed boundaries, a 0.01 h step, and pointwise 95% intervals using
   unconditional covariance where available;
4. call a derivative point a detected increase when its lower interval limit
   exceeds zero, and compatible with zero when its interval contains zero;
5. classify a derivative-defined plateau pattern at the first transition from
   a detected increase to a zero-compatible point when every later grid point
   remains zero-compatible through the maximum recorded photoperiod; and
6. report the transition as the bracket between the final detected-increase
   grid point and the first zero-compatible grid point.

The V0 forward-difference, conditional-covariance settings are retained as a
method sensitivity. The binary classification and boundary are reported
separately.

## Superseded gate components

This decision supersedes the eligibility role of:

- `H07-G1`'s equivalence-margin requirement for the requested descriptive
  plateau classification;
- `H07-G9`'s pooled, leave-one-site-out, and one-hour sustained-support rule;
  these remain support and influence diagnostics only; and
- `H07-G13`'s prohibition on applying a V0-like pointwise derivative
  transition to the revised analysis.

All other H07-001 requirements remain active, including the complete
nine-metric outcome set, near-eye primary and chest complementary roles,
metric-specific response models, exact samples, diagnostics, sensitivities,
V0 reconstruction, and prohibition of causal, clinical, health-outcome,
placement-equivalence, and unsupported mechanistic claims.

## Interpretation boundary

The requested rule identifies a **derivative-defined plateau pattern**. It is
descriptive and post-result because it searches pointwise intervals over a
grid without curve-wide or cross-metric multiplicity control. An interval
containing zero is not evidence that the derivative is practically zero, so
the result is not an equivalence test, proof of an asymptote, or a mechanistic
ceiling. Site, photoperiod, and collection period remain entangled; sparse
upper-tail and leave-one-site-out findings remain visible limitations but do
not suppress the classification.

## Computation authorization

The revision reuses existing fitted model checkpoints and requires no model
refit, bootstrap, or production simulation. Any future full-range simultaneous
band or resampling procedure remains behind the existing pilot and production
approval gate.
