# Brown recommendation adherence participant-profile Stage 2 stop

Decision ID: `BA-006`  
Change ID: `CHG-144`  
Date: 2026-08-15  
Status: verified stop; joint participant-profile construct not estimable under the approved Laplace route

## Central disposition

The Brown-adherence participant-profile extension has reached its
prespecified Stage 2 technical stop. `BA-PP-G1-TECH` passed, but
`BA-PP-G2-TECH` did not. The complete construct-preserving ladder `P0`, `P1`,
and `P2` failed the approved maximum-likelihood and Laplace-approximation
gate. The task correctly stopped before fitting the at-least-80% sample,
calculating reliability or tertile summaries, running temporal sensitivity,
or starting Stage 3.

`BA-006` closes the active execution authority opened by `BA-005`. The
automatic Stage 2-to-Stage 3 continuation in `BA-005` was conditional on a
passing `BA-PP-G2-TECH` gate and therefore was not exercised. No further
participant-profile analysis, amended Stage 3 report, or writer notification
is authorized by this decision. The planned `BA-PP-G3-REVIEW` gate was not
reached.

## Sealed Stage 2 identities

| Sealed item | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/09_participant_profile_implementation_and_reconciliation.qmd` | `bd8d036df6e907fd9f77f74fd852edbc2110ee0cc3d57a8d0080dba9724848ee` |
| `audit/analyses/brown_adherence/09_participant_profile_implementation_and_reconciliation.html` | `1bf11c5f95c889d61356beaf415c096ebf159f392ad28cd2ffd9b7b039adc60e` |
| `audit/analyses/brown_adherence/stage2_participant_profile/participant_profile_stage2_gate.csv` | `4d5abf2394ff6ea29b57b691f1bffbf62422de661ffba6d4ba405c1d2e43867d` |
| `audit/analyses/brown_adherence/stage2_participant_profile/participant_profile_stage2_final_manifest.csv` | `a5949b95b6393e746bc51b489b4ca4e19ff2810303e6d2d4d25aee7016a6f43a` |
| `audit/handoffs/brown_adherence_participant_profile_handoff.md` | `d1351dc47796410ac226f965ba15a6f4db45e13b5dccb691dffbb690b1be0482` |

Independent R 4.6.1 verification matched all 58 non-circular manifest
members and their byte counts. It also reproduced the sealed checks: 32 of
32 exact-likelihood checks, 14 of 14 source checks, 12 of 12 stop-audit
checks, and 23 of 23 render checks. The protected Boundary Stage 2 package
remains exact for 378 of 378 identities, the protected Boundary Stage 3
package remains exact for 82 of 82 identities, and the nine `BA-005` frozen
pins remain exact.

## Verified technical finding

All three primary any-valid rungs ended in false convergence, had maximum
absolute Laplace gradients far above the accepted 0.01 threshold, and had
non-positive-definite fixed-parameter Hessians.

| Model | Rung | Maximum absolute Laplace gradient | Fixed Hessian | Minimum conditional random-Hessian eigenvalue | Random-Hessian eigenvalue ratio |
|---|---|---:|---|---:|---:|
| `BA-PP-ANY-P0` | P0, unstructured | 1,415,029.5 | not positive definite | 0.0000115300 | 0.0000006646 |
| `BA-PP-ANY-P1` | P1, common plus state-specific deviations | 2,171,613.6 | not positive definite | 0.0000025583 | 0.0000001499 |
| `BA-PP-ANY-P2` | P2, common plus equal deviations | 15,662.2 | not positive definite | 0.0012684134 | 0.0000746055 |

The participant covariance matrices were interior and the conditional random
modes were stationary, with maximum absolute conditional random gradients
below 0.001. Those facts do not rescue the fitted models. Near-flat
random-Hessian directions made the approved Laplace integration unstable,
and the fixed-parameter uncertainty calculation failed. Every provisional
covariance output is marked `accepted = FALSE` and is not an estimate that may
be interpreted or reported scientifically.

This is a failure to estimate the joint participant-profile construct under
the approved integration strategy. It is not evidence that participants lack
general adherence differences, state-specific variation, or cross-state
concordance.

## Frozen boundary and prohibited interpretation

The following remain stopped and unavailable:

- the at-least-80% participant-profile fit;
- state-specific reliability or repeatability estimates;
- participant-profile tertiles and transition summaries;
- membership-uncertainty summaries;
- temporal-confounding sensitivity for the participant-profile extension;
- an amended participant-profile Stage 3 report; and
- notification of the Nature Health writer about a participant-profile
  result.

No provisional covariance, correlation, standard deviation, conditional
mode, or transformed parameter from `P0`, `P1`, or `P2` may be used as a
scientific result. Non-retained or unestimated terms must not be assigned zero
variance. Existing accepted `BA-003` and `BA-004` Brown-adherence results and
reader outputs remain unchanged.

## No authorized analytical next step

This decision records the failed stop only. It does not authorize another
integration method, a new fit, a reduced scientific construct, separate
state-by-state models, participant deletion, relaxed convergence criteria,
the at-least-80% analysis, Stage 3, shared integration, manuscript editing,
commit, push, or upload.

If the author elects to continue, the work must reopen at a new prospective
Stage 1 decision. That decision must select and justify a non-Laplace
integration strategy before fitting. Candidate routes are deterministic
adaptive quadrature, when technically suitable for the joint likelihood, or
a fully Bayesian joint model with explicit priors and identification checks.
It must preserve the participant-profile construct, endpoint process, frozen
samples, privacy boundary, and complete at-least-80% replication rule unless
the author separately approves a scientific amendment.

The reopened plan must prespecify software and versions, numerical or
posterior diagnostics, identification and boundary rules, interval and
multiplicity handling, and exact stop conditions. It must first run a bounded
runtime and numerical-stability pilot. Any computation-heavy quadrature,
sampling, simulation, or resampling requires the existing `COMPUTE-001` pilot
and explicit compute authorization before production.

## Reopening condition

Reopen only after an explicit author decision selects a prospective Stage 1
route and its bounded pilot contract. Also reopen if any sealed identity or
preservation check fails, or if a proposed method changes the response,
endpoint process, participant-profile construct, samples, privacy boundary,
or an accepted `BA-003` or `BA-004` result.
