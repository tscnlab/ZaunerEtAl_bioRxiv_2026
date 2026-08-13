# H06_daily exploratory joint-context amendment

- Date: 2026-08-13
- Task-local gate: H06-D-G3-JOINT-CONTEXT
- Status: author requested; bounded implementation authorized

## Author request

The author asked whether day type, daily activity status, and previous-night
sleep duration had been entered together, then explicitly requested that the
recommended exploratory analysis be added. The author also requested that the
accepted exploratory 30-minute GAMM results be included in the Stage 3 report.

## Bounded scientific scope

1. The accepted predictor-specific participant-day analysis remains unchanged.
2. The new analysis is a primary near-eye, all-available exploratory
   covariate-stability analysis. Every metric uses one common complete-case
   frame containing the response and all three day-level contexts.
3. For each metric, predictor-specific models are first refitted on that same
   common frame. Their estimates are the sample-controlled comparators.
4. The mutually adjusted association model contains fixed site, Work/Free day,
   Sedentary/Active status, previous-night sleep duration centered at 8 h, and
   the established participant dependence structure.
5. Site heterogeneity is added one context at a time while the other two
   contexts remain additive. A fully simultaneous three-block site interaction
   model is not used because it would estimate 24 interaction coefficients and
   make each block conditional on two other high-dimensional blocks.
6. The established response family and transformation are retained for slots
   1, 2, and 4--15. Slot 3, L10 mean, remains the named non-estimable accepted
   slot and is not silently replaced by the stopped shifted-log candidate.
   MDER retains the accepted momentary-ratio estimand and identity-Gaussian
   route.
7. The four repaired clock outcomes retain fixed-site linear models with
   participant-cluster HC3 covariance. Other outcomes retain their accepted
   mixed-model route with a participant random intercept.
8. Six separate exploratory 15-slot Benjamini--Hochberg families are formed:
   three conditional association families and three one-block-at-a-time site
   heterogeneity families. Slot 3 remains named with missing p and q values.
   These exploratory families do not alter any accepted primary raw p-value,
   adjusted p-value, rank, estimate, interval, model object, or claim.
9. Convergence, Hessian, singularity, rank, covariance, observed-response
   support, residual displays, and descriptive actual-date lag are checked.
   No AR refit, deletion batch, bootstrap, or simulation is added. Temporal
   dependence remains a reported nonblocking limitation under H06-D-014.
10. Accepted 30-minute GAMM results are displayed from their sealed artifacts.
    They are not recomputed and remain a separate transformed time-profile
    estimand.

## Reporting interpretation

The joint-context estimates answer whether each recorded context association
is stable after conditioning on the other two recorded contexts on an
identical metric-specific sample. They remain observational associations. A
change can arise from covariance among the recorded contexts, but it does not
identify confounding, mediation, or causation. Site-specific intervals are
pointwise. No simultaneous interval is introduced.
