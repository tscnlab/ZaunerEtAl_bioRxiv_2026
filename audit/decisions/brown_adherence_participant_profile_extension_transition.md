# Brown recommendation adherence participant-profile extension

Decision ID: `BA-005`  
Change ID: `CHG-143`  
Date: 2026-08-15  
Status: author approved; participant-profile Stages 1 and 2 authorized with continuation through amended Stage 3

## Author direction and decision

The author approved the recommended participant-profile extension and
authorized its Stage 1 design, Stage 2 implementation, and continuation to an
amended Stage 3 report without another owner-permission gate between those
stages.

The extension asks two distinct questions:

1. Do participants differ in their general adherence tendency across all
   states?
2. Do participants also have state-specific adherence profiles, such as being
   relatively high during Wake but relatively low during Pre-sleep or the
   Sleep environment?

The accepted single participant-intercept model addresses only the first
question. It cannot represent cross-state reversals. `BA-005` therefore opens
a separate participant-profile analysis whose primary evidence is continuous
cross-state concordance and whose secondary display is cohort-relative
Wake/Pre-sleep/Sleep tertile movement.

## Preserved accepted analysis

This decision does not alter or overwrite `BA-003`, `BA-004`, their selected
F3/R3/Q2/Q1/D0 models, or the existing Stage 2 and Stage 3 packages. The
following accepted or sealed identities remain historical evidence and must
stay byte-identical:

| Frozen item | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/stage2/model_frames.rds` | `13ef1ed1e07d055e369b1e7d479285aee38a0587b61c5b87747067c3bc3a6821` |
| `audit/analyses/brown_adherence/stage2/model_frame_membership.csv` | `723fcb2f58d8726b1afc0dff2a9d93a4816766db252c10302a20a4f74e98887d` |
| `audit/analyses/brown_adherence/stage2_boundary/boundary_stage2_final_manifest.csv` | `24e0adf52dbc516213cc40f34e27c41dc7fe531553520aae7a22397a6d5bdf97` |
| `audit/analyses/brown_adherence/07_results.qmd` | `a1c9b4662038c584d6338d0b38378ae572f27fc4ef84fa558557ff9137640cef` |
| `audit/analyses/brown_adherence/07_results.html` | `06edb255a521cc285832dc31846de39878648856bde7ee9cbb6959f83db629c8` |
| `audit/analyses/brown_adherence/stage3/boundary_stage3_final_manifest.csv` | `da25895a3e9938992d7b1f0633d6e274e691c3eb87310be565b28d465130271d` |
| `audit/analyses/brown_adherence/stage3/boundary_stage3_author_gate.csv` | `c34d02ce46311846838ab10d9b8834d2c08082010e3b93c1a8e4fecd6e7a0b53` |
| `audit/analyses/brown_adherence/stage3/boundary_stage3_handoff.md` | `795cd633661296893f1d3afba515abe28654f297fcf3de3f42f9d265f047812d` |
| `audit/handoffs/brown_adherence_strategy_handoff.md` | `8a873a113fa798153af59c034a667e317cba727484da4119c88b25275e789b95` |

The existing `BA-BS3-REVIEW` package was sealed before this extension but was
not author accepted as the final reader report. It remains a frozen
pre-extension record. Writer notification from that package is deferred and
will be superseded by the amended Stage 3 package.

## Verified support at reopening

R 4.6.1 read-only verification of the sealed model frames found:

| Sample | Rows | Participants | At least one observation in every state | At least two observations in every state | At least three observations in every state |
|---|---:|---:|---:|---:|---:|
| Any-valid primary | 2,216 | 140 | 140 | 139 | 136 |
| At least 80% coverage | 2,004 | 140 | 139 | 132 | 122 |

Both frames contain the three accepted analysis states and both day types.
These counts establish feasibility only. Stage 1 must still verify exact
state by site by day-type support, repeated-cycle support, participant-key
nesting, and missing-state patterns before specifying the production model.

## Authorized Stage 1 contract

Stage 1 is prospective design and read-only support assessment. It must not fit
the production model. It must:

1. Define the general participant adherence propensity separately from
   participant-specific state deviations.
2. Preserve the accepted any-valid primary sample and repeat the complete
   analysis on the identical at-least-80% coverage gate.
3. Preserve the accepted State by Site by Day type fixed-effect structure and
   the selected endpoint-process structure unless a clearly labelled
   technical reparameterization is required. Endpoint-process random effects
   are not reopened.
4. Verify whether the participant identifier is globally unique or must be
   represented by a deterministic site-participant key.
5. Prespecify an estimability ladder for a joint participant state profile.
   The leading candidate is an unstructured three-state participant random
   vector, expressed as `(0 + state | participant)` or an algebraically
   equivalent common-propensity plus centered-state-contrast parameterization.
   Any fallback must preserve the scientific construct and may be triggered
   only by support, convergence, Hessian, rank, or singularity evidence.
6. Define continuous primary summaries from the estimated participant
   state-profile covariance structure, including state-specific variation,
   pairwise cross-state covariance or correlation, and contrasts that separate
   the common propensity from state-profile deviations. Correlations of
   conditional modes must not substitute for the fitted covariance parameters.
7. Define state-specific repeatability or reliability, on an explicitly named
   scale, and a prospective adequacy rule. Secondary categorization is not
   allowed for a state whose reliability or support fails that rule.
8. Define cohort-relative tertiles as descriptive displays, not clinical or
   absolute adherence thresholds. Specify the Wake-referenced and reciprocal
   transition summaries, same-tertile and extreme-transition proportions, and
   how uncertainty near cut points will be shown.
9. Define aggregate membership-uncertainty summaries without exposing
   participant identifiers or publishing participant rankings. If uncertainty
   cannot be estimated without bootstrap or heavy simulation, report the
   classification as unavailable rather than bypassing `COMPUTE-001`.
10. Prespecify diagnostics for endpoint calibration, convergence, Hessian,
    rank, singularity, variance-covariance boundaries, within-state residual
    behavior, actual-date temporal dependence, and separation of stable
    participant propensity from short-term temporal persistence.
11. Prespecify the response-scale summaries, interval method, multiplicity
    treatment for any new inferential family, privacy rules, and exact stop
    conditions before any Stage 2 fit.

Stage 1 closes at technical gate `BA-PP-G1-TECH`. Because the author has
already approved the outlined extension, a passing gate may proceed directly
to Stage 2 without another owner response. A scientific change outside this
contract must stop for a new amendment.

## Authorized Stage 2 contract

After `BA-PP-G1-TECH` passes, Stage 2 may:

- read only the two sealed model-frame members `primary_any_valid` and
  `support_80`;
- fit the prospectively specified state-profile model and only its registered
  construct-preserving fallbacks under R 4.6.1;
- retain the accepted fixed State by Site by Day type adjustment and endpoint
  structure;
- estimate continuous state-specific participant heterogeneity and cross-state
  concordance before constructing any tertile display;
- calculate the prespecified within-state reliability summaries and suppress
  categorical displays that fail their adequacy rule;
- produce only aggregate tertile transition tables, membership-uncertainty
  summaries, and de-identified diagnostic outputs;
- diagnose temporal confounding and clearly distinguish stable participant
  profiles from serial persistence;
- repeat the full contract on the at-least-80% sample; and
- retain observational, exploratory, non-causal interpretation throughout.

The new extension must use its own multiplicity family, if any. It must not
alter BA-M1 through BA-M5 or insert its tests into the accepted Brown-adherence
families. A random-effect variance estimate that reaches a boundary, an
unestimable covariance structure, inadequate reliability, or unresolved
temporal confounding must be reported as a limitation or failure according to
the prospective rule. Terms absent from a selected fallback may not be
reported as zero variance.

Standard bounded model fitting is authorized. Bootstrap, resampling, or a
computation-heavy simulation remains subject to `COMPUTE-001`, including its
production-code pilot and explicit author approval of projected cost. No
result-dependent model simplification or participant-level ranking is
authorized.

Stage 2 closes at technical gate `BA-PP-G2-TECH`. If every prospective
contract and preservation check passes, the task may proceed directly to the
amended Stage 3 report without another owner response. Otherwise it must stop
and report the exact failure.

## Authorized Stage 3 contract and next author stop

Stage 3 must be a separate amendment that links to, but does not overwrite,
the frozen `07_results` package. It must lead with the continuous
participant-profile evidence. Tertiles are secondary reader aids and must be
described as cohort-relative and classification-uncertain. All reader outputs
must be aggregate and must contain no participant identifier, participant
ranking, or causal claim.

The mandatory next author stop is `BA-PP-G3-REVIEW`. No Stage 4, shared Quarto
configuration, manuscript edit, writer claim integration, commit, push, or
upload is authorized before that review. Once the amended Stage 3 package is
sealed, notify the Nature Health writer task `019ffb39-372e-7262-bfac-192751fd0e63`
that results are pending author review. Send final claim authority only after
explicit author acceptance of `BA-PP-G3-REVIEW`.

## Authorized task-owned paths

The continuing Brown-adherence task may create or modify only:

- `audit/analyses/brown_adherence/08_participant_profile_audit_and_plan.qmd`;
- `audit/analyses/brown_adherence/08_participant_profile_audit_and_plan.html`;
- `audit/analyses/brown_adherence/stage1_participant_profile/`;
- `audit/analyses/brown_adherence/09_participant_profile_implementation_and_reconciliation.qmd`;
- `audit/analyses/brown_adherence/09_participant_profile_implementation_and_reconciliation.html`;
- `audit/analyses/brown_adherence/stage2_participant_profile/`;
- `audit/analyses/brown_adherence/10_participant_profile_results_amendment.qmd`;
- `audit/analyses/brown_adherence/10_participant_profile_results_amendment.html`;
- `audit/analyses/brown_adherence/stage3_participant_profile/`; and
- `audit/handoffs/brown_adherence_participant_profile_handoff.md`.

The task must maintain non-circular manifests and exact preservation checks
against the frozen identities above. Existing Brown-adherence reports,
handoffs, manifests, models, source data, and Stage 2 or Stage 3 directories
are read-only inputs.

## Reopening condition

Stop and reopen this decision if a frozen identity changes, exact support does
not reconcile, the scientific construct cannot be represented by the
prespecified estimability ladder, a new response or endpoint process is
required, a participant-level disclosure risk appears, a heavy computation is
needed without `COMPUTE-001`, or the amended Stage 3 report would change an
accepted BA-003 or BA-004 result rather than add separate exploratory evidence.
