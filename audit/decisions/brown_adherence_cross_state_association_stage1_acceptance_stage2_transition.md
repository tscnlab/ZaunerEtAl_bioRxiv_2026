# Brown adherence cross-state association Stage 1 acceptance and Stage 2 transition

Decision ID: `BA-007`  
Change ID: `CHG-145`  
Date: 2026-08-20  
Status: author approved; bounded cross-state association Stage 2 authorized

## Author decision and analysis status

The author reviewed the complete `BA-CS-G1-REVIEW` package and replied:

> **approve and continue**

This accepts all 16 prospective Stage 1 gate items without revision. The
accepted `BA-003` and `BA-004` endpoint-inflated Brown recommendation model
remains the main analysis. This cross-state association remains a separate
exploratory extension and does not replace, refit, or reclassify that main
analysis.

The stopped `BA-005` and `BA-006` participant-profile analysis also remains
unchanged. Its failed Laplace covariance outputs must not be used as starting
values, estimates, participant summaries, or evidence in this extension. The
new model answers narrower within-participant and between-participant
association questions and does not reopen the failed three-state random
covariance.

This extension remains outside H01 through H11 and does not alter `BA-M1`
through `BA-M5`. The central hypothesis-stage ledger therefore remains
unchanged. `BA-007` and `CHG-145` are the controlling central records.

## Accepted Stage 1 identities

| Accepted artifact | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/11_cross_state_association_audit_and_plan.qmd` | `f579c79dd4ab39d015fbe724890919f03da04ac7125c543c00747961d39f630b` |
| `audit/analyses/brown_adherence/11_cross_state_association_audit_and_plan.html` | `8adbc5bf73b8048f78aa434ba3a5dc2f5d30cb408a503f01a5658c55d8f395db` |
| `audit/analyses/brown_adherence/stage1_cross_state_association/cross_state_stage1_gate.csv` | `c9cc0cd1b2b5a1bde911f5e82d11473d6ecee5ae5b7bf7bc73f40b38e15b0059` |
| `audit/analyses/brown_adherence/stage1_cross_state_association/cross_state_stage1_final_manifest.csv` | `4beae413c106b02692decfe7661093698b583f272818432c0acd7b2ce9668b69` |
| `audit/handoffs/brown_adherence_cross_state_association_handoff.md` | `dcec35fe1b04a7396c519250ba174f77200f38d8ed7984b12f930725e16b733a` |

Independent R 4.6.1 verification matched all 47 non-circular manifest
members and their byte counts. It also confirmed 19 of 19 required support
checks, 7 of 7 source checks, 22 of 22 render checks, 14 native `gt` tables,
the protected prior Brown packages, and the shared scientific-input pins. No
association model was fitted in Stage 1.

All 47 accepted manifest members are read-only Stage 2 inputs. Stage 2 must
stop before execution if any accepted Stage 1 identity or any frozen identity
listed in the original Stage 1 authorization changes.

## Accepted chronology and cycle mapping

Actual diary dates and UTC timestamps determine chronology. `source_row` is a
provenance identifier only and must never determine the preceding or following
record. Observed source-row deltas ranged from -6 to +7 even though every
retained anchor-to-next diary gap was one calendar day.

The cross-state overlay anchors on Wake and pairs the preceding Sleep period
and following Pre-sleep period by the explicit chronological next record. It
is chronologically equivalent to the historical linkage-B triplet while
leaving the frozen linkage-C rows and behavioral-cycle keys used by the main
analysis unchanged. All 1,376 any-valid overlay target rows reconciled exactly
to the historical linkage-B timestamps and Brown counts.

Day type belongs to the Wake anchor. It must not be inherited from the target
row. Pairwise-complete Wake-Sleep and Wake-Pre-sleep samples remain primary so
that a missing target state does not remove the other valid pair.

## Frozen Stage 2 estimand and model contract

The any-valid sample is primary. Stage 2 must repeat the identical selected
model rung, estimands, contrasts, diagnostics, and reference grid at the
at-least-80-percent coverage gate before a claim can proceed.

The response is the exact target-state Brown-check numerator and valid-minute
denominator. Exact zero and one are valid observations. Sleep and Pre-sleep
are response targets. Wake is a predictor and is not a response row.

The two primary Wake predictors are:

1. the current cycle's Wake adherence minus that participant's equal-cycle
   mean across all valid Wake periods, scaled per 10 percentage points; and
2. the participant's equal-cycle all-Wake mean, centered across participants
   and scaled per 10 percentage points.

The second predictor describes observed short-term propensity and must not be
called a stable participant trait. The mean model also adjusts for the
participant's centered Free-Wake fraction. An equal-day-type participant
construction is a prespecified sensitivity, not a replacement primary
estimand.

The first candidate is the endpoint-inflated beta-binomial
`CS-F3/R0/Q2/Q1/D0` model. Its exact components are:

```r
cbind(target_brown_yes, target_brown_no) ~
  target_state * site * day_type +
  target_state * wake_within_10pp +
  target_state * wake_between_centered_10pp +
  target_state * wake_free_fraction_centered_10pp

~ (1 | participant_id) + (1 | association_cycle_id)

target_exact_zero ~ target_state + day_type
target_exact_one ~ target_state * day_type
~ target_state
```

The model uses maximum likelihood and Laplace integration with the already
accepted deterministic TMB likelihood route, R 4.6.1, TMB 1.9.21, and C++17.
No package installation or lockfile change is authorized.

## Deterministic estimability ladder

Stage 2 must follow this order:

1. Fit `CS-F3/R0/Q2/Q1/D0` on the any-valid sample.
2. Replace `R0` with `R3`, retaining only `(1 | participant_id)`, solely when
   the association-cycle intercept is singular, on a boundary,
   non-identifiable, or the documented cause of convergence or Hessian
   failure.
3. Never remove the participant intercept. Failure of `R3` stops the
   extension.
4. Move through `F2`, `F1`, and `F0` in order only for documented rank,
   finite-estimate, convergence, or Hessian failure. Preserve interaction
   hierarchy, both Wake association components, and the composition
   adjustment at every rung.
5. Do not simplify `Q2`, `Q1`, or `D0` without a structural failure. A change
   to the endpoint process or response family returns to Stage 1.
6. Do not remove the within-Wake or between-Wake term separately. Failure or
   non-estimability of either scientific association term stops the extension
   before a family change.

No transition may depend on estimate direction, magnitude, p-value, interval,
or narrative convenience. The failed participant-state vector, random state
slopes, endpoint random effects, and conditional-mode correlations are not
candidates.

## Estimands and multiplicity

`BA-CS-M1` is one family of exactly four association tests:

1. within-participant Wake association with Sleep;
2. within-participant Wake association with Pre-sleep;
3. between-participant Wake association with Sleep; and
4. between-participant Wake association with Pre-sleep.

All four raw p-values must exist before one Benjamini-Hochberg FDR adjustment
is applied. A failed or non-estimable member blocks the complete family.
There are no category p-values and no transfer into `BA-M1` through `BA-M5`.

For each contrast, Stage 2 may report the target-specific conditional logit
slope with a 95% Wald interval and the marginal overall-adherence change for a
10-percentage-point Wake difference, in percentage points, with a 95%
delta-method interval. Marginal results use equal weighting of the nine sites,
50:50 weighting of Work and Free days, and integration over the complete
endpoint mixture and retained random effects.

The within-participant comparison is -5 to +5 percentage points around the
participant's usual Wake adherence. The between-participant comparison is -5
to +5 percentage points around the equal-participant mean, with the within
deviation fixed at zero and Free-day composition at its centered reference.
Fifteen-node and 30-node Gauss-Hermite results must agree within 0.05
percentage points before a marginal result is released. No bootstrap interval
is authorized.

## Required diagnostics and sensitivities

Before interpretation, Stage 2 must complete and preserve:

- deterministic likelihood validation before the first Brown-data fit;
- fixed-design identity and rank, finite estimates, optimizer status, maximum
  absolute gradient, positive-definite Hessian and covariance, and
  random-effect boundary checks;
- a maximum absolute gradient no greater than 0.01 for structural retention,
  with no greater than 0.001 required for an unqualified acceptable fit;
- target, site-by-day-type, valid-minute denominator, and endpoint
  calibration;
- 250 conditional predictive draws using seed 20260814 plus a documented
  sample offset;
- observed and predicted all-zero, mixed, and all-one counts by target,
  assessed separately from overall adherence;
- Pearson and randomized-quantile residual diagnostics, residual plots
  against both Wake components and denominators, and prespecified binned
  linearity diagnostics;
- nine leave-one-site-out fits and the bounded five-participant influence
  screen; and
- exact sample, participant, pair, site-cell, and boundary-count
  reconciliation before any p-value or FDR calculation.

Endpoint miscalibration blocks endpoint claims but does not automatically
invalidate the overall adherence association. Overall adherence and endpoint
probabilities require separate acceptable, acceptable-with-limitations, or
not-acceptable dispositions.

Residuals must be ordered by actual Wake-anchor date within participant and
target. A temporal sensitivity is triggered only when the absolute lag-1
Pearson residual correlation is at least 0.20 and its 95% interval excludes
zero. If triggered, fit the registered target-specific participant-centered
date-trend sensitivity and the deterministic at-least-two-day thinned sample.
Withhold the day-level claim if direction, interval-exclusion status, or the
response-scale 10-point effect changes materially. An OU process requires a
new prospective gate.

The identical selected model and complete contract must be repeated at the
at-least-80-percent coverage gate. All four `BA-CS-M1` effects must preserve
direction and interval-exclusion status, and no absolute response-scale shift
may exceed 2 percentage points. Failure restricts interpretation to the
any-valid observed-support estimand and requires author review before reader
reporting.

The complete-target-pair sample and equal-day-type between-person
construction are prespecified sensitivities. Neither may replace the
pairwise primary because its estimate is preferred.

## Category and privacy boundary

Only after a successful continuous model may Stage 2 calculate descriptive
day-level low, middle, and high Wake-deviation display summaries using the
frozen type-1 cutpoints. They receive no p-values and may not replace the
continuous association evidence.

Hard participant-tertile overlap is prohibited because none of the six
prespecified stability checks reached 80%. Stage 2 must not export participant
IDs, ranks, row-level memberships, cross-state participant overlap, or small
participant cells. Relaxing the stability rule, excluding unstable
participants, or introducing probabilistic membership returns to Stage 1.

## Authorized Stage 2 paths

The continuing Brown-adherence task may create or modify only:

- `audit/analyses/brown_adherence/12_cross_state_association_implementation_and_reconciliation.qmd`;
- its targeted HTML
  `audit/analyses/brown_adherence/12_cross_state_association_implementation_and_reconciliation.html`;
- task-owned code, model objects, diagnostics, tables, source data, tests,
  manifests, execution records, and gate evidence under
  `audit/analyses/brown_adherence/stage2_cross_state_association/`; and
- `audit/handoffs/brown_adherence_cross_state_association_handoff.md`.

All Stage 1 files and every prior Brown file remain read-only. The Stage 2
manifest must be non-circular and must prove all accepted and frozen
identities unchanged.

## Mandatory Stage 2 stop

After the authorized implementation, fitting, diagnostics, sensitivities,
multiplicity calculations, and Stage 2 report are complete and verified, stop
at `BA-CS-G2-REVIEW` for explicit author review.

No Stage 2 estimate, p-value, FDR result, diagnostic disposition, or claim is
accepted by this transition. Stage 3, Stage 4, shared Quarto integration,
manuscript or writer notification, shared edits, commit, push, upload, broad
simulation, bootstrap, exhaustive participant deletion, and any unregistered
heavy computation remain unauthorized. A need for heavy production
computation returns to `COMPUTE-001` for a bounded pilot and explicit
approval.

## Reopening condition

Reopen `BA-007` before further fitting if an accepted or frozen identity
changes; the exact date-based pairing or 1,376-row historical reconciliation
fails; the response, endpoint process, sample, day ownership, estimand,
reference grid, four-member family, or privacy boundary changes; either Wake
association component is unavailable; the ladder requires an unregistered
model; the hard participant-tertile stability rule would be relaxed; or the
extension would modify an accepted `BA-003` or `BA-004` result.
