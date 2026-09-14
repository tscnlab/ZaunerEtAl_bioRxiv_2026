# H06 revised Stage 1A gate and Stage 2 transition

Decision ID: `H06-002`  
Date: 2026-08-10  
Status: approved

## Evidence and scope

The author explicitly approved revised gate `H06-G1A`. The coordinator
verified the identities supplied by the H06 worker:

- `audit/hypotheses/H06/01_audit_and_plan.qmd`, SHA-256
  `393fd87c908302c1681925dcc451b27be31e652758592da8a81c775ff09aaf26`;
- `audit/hypotheses/H06/01_audit_and_plan.html`, SHA-256
  `186ab355deb0ba41f276c55c0490e9e0edbe7be1060c40fe2f4c366ed8eee8ae`;
- `audit/handoffs/H06_worker_handoff.md`; and
- `audit/handoffs/H06_shared_change_request.md`.

`H06-002` preserves the author-approved hourly estimand, predictors, site
hierarchy, marginalization, multiplicity families, placement roles, source
pin, and exploratory/confirmatory boundary recorded by `H06-001`. It
supersedes `H06-001` only for the dependence and working-distribution
architecture that failed the first Stage 2 adequacy gate. The earlier decision
and Stage 2 outputs remain historical audit evidence rather than accepted H06
results.

## Approved revised Stage 2 contract

1. The primary outcome remains supported one-hour zero-aware geometric mean
   melEDI.
2. The primary predictors remain work/free day, binary activity
   (`Sedentary` versus `Active`), and previous-night sleep duration.
   Weekday/weekend remains an estimate-and-95%-CI sensitivity; other named
   predictors remain exploratory.
3. The primary additive formula is
   `response_value ~ site + work_free_day + activity_status + previous_sleep_duration_centered_h`.
   H06-F1 uses participant-cluster robust coefficient-block Wald tests.
4. The separate heterogeneity formula is
   `response_value ~ site * work_free_day + site * activity_status + site * previous_sleep_duration_centered_h`.
   H06-F2 tests the corresponding site-interaction blocks. The additive and
   heterogeneity questions are not combined into one omnibus.
5. Both models use a quasi-Poisson log-mean working model and unmodified
   participant-cluster HC3 covariance from `sandwich::vcovCL()` with
   `cadjust = TRUE` and `fix = FALSE`. One-parameter tests use a
   finite-cluster *t* reference and multi-parameter tests use a Wald *F*
   reference with `G - 1` denominator degrees of freedom.
6. Fixed site, sum-to-zero contrasts, and equal-site reader-facing
   marginalization remain in force. The primary marginal model contains no
   participant or participant-day random intercept, latent or working AR
   term, random-site term, or confirmatory local-clock term. True-time
   sequence information remains mandatory for residual-lag diagnostics and
   the separately labelled exploratory temporal analysis.
7. The fixed-power quasi-Tweedie working model with `p = 1.8` and HC1/HC2
   covariance are bounded sensitivities. They do not authorize likelihood,
   AIC, ICC, random-effect, or variance-decomposition claims.
8. The existing H06 multiplicity families, near-eye primary role,
   paired/common-sample and chest complementary roles, gap-timing-unaware
   sensitivity, V0 comparison, and exact-sample reporting contract remain
   unchanged.
9. Stage 2 must complete residual, mean-calibration, participant-influence,
   site-deletion, covariance, data, placement, multiplicity, and V0-comparison
   checks before any result or claim can be accepted. It then stops at the
   Stage 2 author-review gate.
10. The immutable `melidosData` 1.0.6 source pin remains unchanged. Stage 2
    performs only the approved read-only seven-`S001`/zero-`S101` assertion;
    no shared data or preparation rebuild is authorized.

## H06-local contract authorization

The H06 worker may update its H06-owned input-contract pin to the approved
Stage 1 source identity
`393fd87c908302c1681925dcc451b27be31e652758592da8a81c775ff09aaf26`
and, where the contract records the rendered evidence, HTML identity
`186ab355deb0ba41f276c55c0490e9e0edbe7be1060c40fe2f4c366ed8eee8ae`.
This is a gate-identity update only. It does not authorize any change to shared
data, preparation code, shared manifests, or coordinator-owned files.

## Result and reopening conditions

Stage 2 is authorized and in progress under this revised contract. No H06
estimate, interval, diagnostic classification, sensitivity result, or claim
is accepted by this gate. Stage 3 and Stage 4 remain blocked until the revised
Stage 2 report is explicitly approved.

Reopen `H06-G1A` if the outcome, predictors, formulas, quasi-Poisson mean
model, participant-cluster HC3 specification, finite-cluster reference, site
formulation, marginalization, multiplicity families, placement roles, source
pin, sensitivity set, or exploratory/confirmatory boundary changes or cannot
be implemented as specified.
