# Brown recommendation adherence cross-state association Stage 1 authorization

Decision ID: `BA-007`  
Change ID: `CHG-145`  
Date: 2026-08-20  
Status: author direction accepted; Stage 1 audit authorized; no model fitting authorized

## Author direction and central interpretation

The author directs that the accepted Brown recommendation boundary model remain
the main analysis. It must not be refitted, replaced, or reclassified. A new
and separate exploratory extension may assess two narrower cross-state
questions:

1. At the behavioral-cycle level, is higher Wake adherence associated with
   higher adherence during the preceding Sleep environment and the following
   Pre-sleep period?
2. At the participant level, do participants with higher overall Wake
   adherence also tend to have higher overall Sleep-environment and Pre-sleep
   adherence?

Continuous associations are primary. Cohort-relative tertiles are secondary
descriptive displays. This decision opens only a prospective Stage 1 audit and
specification phase. It does not authorize a fit, p-value, confidence interval,
response-scale prediction, cross-state association estimate, tertile outcome
comparison, or reader-result amendment.

## Relationship to the accepted and stopped Brown analyses

`BA-003` and `BA-004` remain the scientific authority for the accepted Brown
boundary model and its reader-facing random-effect display. The original
selected endpoint-inflated beta-binomial model remains the main result.

`BA-005` and `BA-006` remain the complete record of the attempted joint
three-state participant-profile extension. Its `P0` through `P2` Laplace fits
remain unaccepted and must not supply a covariance, correlation, standard
deviation, conditional-mode summary, tertile, or scientific claim. This new
extension is not a rescue or reinterpretation of those fits. It asks a simpler
within-participant and between-participant association question without
reopening the failed three-state random covariance.

All existing Stage 1, Stage 2, Stage 3, participant-profile, and central gate
artifacts under `BA-003` through `BA-006` remain read-only historical evidence.
In particular, the following sealed identities remain mandatory preservation
pins even when their task-owned files are held in the continuing Brown task's
workspace:

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
| `audit/analyses/brown_adherence/09_participant_profile_implementation_and_reconciliation.qmd` | `bd8d036df6e907fd9f77f74fd852edbc2110ee0cc3d57a8d0080dba9724848ee` |
| `audit/analyses/brown_adherence/09_participant_profile_implementation_and_reconciliation.html` | `1bf11c5f95c889d61356beaf415c096ebf159f392ad28cd2ffd9b7b039adc60e` |
| `audit/analyses/brown_adherence/stage2_participant_profile/participant_profile_stage2_gate.csv` | `4d5abf2394ff6ea29b57b691f1bffbf62422de661ffba6d4ba405c1d2e43867d` |
| `audit/analyses/brown_adherence/stage2_participant_profile/participant_profile_stage2_final_manifest.csv` | `a5949b95b6393e746bc51b489b4ca4e19ff2810303e6d2d4d25aee7016a6f43a` |
| `audit/handoffs/brown_adherence_participant_profile_handoff.md` | `d1351dc47796410ac226f965ba15a6f4db45e13b5dccb691dffbb690b1be0482` |

The ten shared scientific inputs pinned by `BA-001`, every accepted
`Brown.check` threshold, and every protected identity inherited through
`BA-002` through `BA-006` also remain preflight requirements.

## Frozen measurement, linkage, and sample rules

Stage 1 must preserve the accepted inclusive minute-level definitions:

- Wake adherence is the proportion of valid Wake minutes at or above 250 lx,
  outside the three hours before sleep;
- Pre-sleep adherence is the proportion of valid Pre-sleep minutes at or below
  10 lx;
- Sleep-environment adherence is the proportion of valid Sleep minutes at or
  below 1 lx; and
- exact state-period values of zero and one remain valid observations.

Use linkage C and its accepted state-validity and day-type rules. Anchor the
new pairing on a Wake interval, then identify the preceding Sleep environment
and following Pre-sleep period within the same behavioral cycle. Stage 1 must
show the exact diary-row and date mapping and must fail closed on an off-by-one
or ambiguous cycle assignment. It may not silently redefine linkage C.

The any-valid sample is primary. The complete analysis specification must be
replicated on the identical at-least-80-percent coverage gate. Pairwise-complete
Wake-Sleep and Wake-Pre-sleep samples are primary. Complete triads may be
proposed only as a clearly labelled sensitivity if Stage 1 demonstrates
adequate support. Missing one target state must not unnecessarily remove the
other target-state pair.

## Authorized Stage 1 support audit

All checks must run in R 4.6.1 from the sealed Brown model frames and accepted
linkage inputs. Stage 1 may calculate only aggregate design and feasibility
evidence needed to freeze the production specification. It must audit:

1. exact pair counts, participants, paired cycles, and unique cycle keys for
   Wake-Sleep and Wake-Pre-sleep in both coverage samples;
2. site, target state, day type, and site-by-day-type support, including
   whether the paired cycle's day type is unambiguous under linkage C;
3. target and Wake valid-minute denominator distributions, boundary mass at
   zero and one, and observations per participant;
4. participants with both Work and Free days, participant-specific Work/Free
   composition, and whether the participant-mean Wake component requires
   equal-day-type standardization or explicit composition adjustment;
5. design-matrix rank, separation risk, target-state support, and parameter
   count for the leading within-between model without fitting it;
6. the number of Wake cycles available per participant and state, the
   measurement-error limitation from sparse participant histories, and a
   prespecified within-state reliability or stability estimator with an
   adequacy threshold that must pass before categorization;
7. candidate tertile cut-point ties, aggregate occupancy, and deterministic
   leave-one-cycle-out membership stability as feasibility diagnostics only;
8. actual-date spacing, repeated-cycle patterns, and the planned temporal
   diagnostics needed to distinguish a within-participant association from
   short-term serial persistence; and
9. privacy and disclosure controls proving that no participant identifier,
   participant ranking, or small-cell participant profile can enter a reader
   output.

Stage 1 may report aggregate cut-point, occupancy, and membership-stability
diagnostics solely to decide whether secondary categories are supportable. It
must not compare target adherence across those categories, calculate a
cross-state overlap result, publish a participant classification, or describe
the feasibility diagnostics as scientific findings.

## Required prospective Stage 2 specification

The Stage 1 report must propose one exact, executable specification for later
author review. The leading specification is a stacked Sleep and Pre-sleep
endpoint-inflated beta-binomial target model that:

- uses the exact valid-minute target numerator and denominator;
- decomposes cycle-level Wake adherence into the participant's mean Wake
  adherence and that cycle's deviation from the participant mean;
- interacts target state with both the within-participant and
  between-participant Wake components;
- retains the accepted site and day-type adjustment, with the Stage 1 decision
  on Work/Free composition applied prospectively;
- handles repeated participants without reopening the failed three-state
  participant random covariance;
- preserves the selected endpoint-process structure unless Stage 1 identifies
  a construct-preserving technical requirement that is explicitly presented
  at the gate;
- reports later effects per 10 percentage-point higher Wake adherence and as
  response-scale predictions; and
- carries complete convergence, Hessian, rank, boundary, endpoint-calibration,
  residual, temporal, influence, and at-least-80-percent sensitivity rules.

Stage 1 must freeze the exact formula, contrast coding, reference grid,
interval method, response-scale estimands, diagnostic thresholds, estimability
ladder, and stop rules before any fit. Result-dependent simplification,
participant deletion, predictor-specific selection, and use of the failed
`BA-005` covariance estimates are prohibited.

The proposed new inferential family is `BA-CS-M1`, containing exactly four
association contrasts:

1. within-participant Wake to Sleep;
2. within-participant Wake to Pre-sleep;
3. between-participant Wake to Sleep; and
4. between-participant Wake to Pre-sleep.

The four p-values would receive one BH false-discovery-rate adjustment if the
family is later author approved and estimated. Tertile displays receive no
additional p-values. Stage 1 calculates none of these p-values.

Secondary displays for later stages may include low, middle, and high
within-participant Wake-deviation groups against target-state adherence, and
participant Wake-tertile groups against participant Sleep and Pre-sleep
summaries with aggregate cross-state overlap. They remain cohort-relative,
descriptive, uncertainty-qualified, and conditional on the prespecified
reliability and leave-one-cycle-out stability gates.

## Authorized task-owned paths

The continuing Brown-adherence task may create or modify only:

- `audit/analyses/brown_adherence/11_cross_state_association_audit_and_plan.qmd`;
- its targeted HTML
  `audit/analyses/brown_adherence/11_cross_state_association_audit_and_plan.html`;
- Stage 1 support tables, code, tests, manifests, and gate evidence under
  `audit/analyses/brown_adherence/stage1_cross_state_association/`; and
- `audit/handoffs/brown_adherence_cross_state_association_handoff.md`.

Expected closing records are
`stage1_cross_state_association/cross_state_stage1_gate.csv`,
`stage1_cross_state_association/cross_state_stage1_final_manifest.csv`, and the
new handoff. Every manifest must be non-circular and must prove the frozen
identities above unchanged.

No existing Brown QMD, HTML, model, source data, manifest, handoff, Stage 1,
Stage 2, Stage 3, or participant-profile path may be edited or resealed.

## Mandatory stop and prohibited work

Stage 1 stops at `BA-CS-G1-REVIEW` for explicit author approval of the complete
production specification. The author's approval of the exploratory direction
does not pre-approve a fitted model or allow automatic continuation to Stage 2.

Before that gate, do not fit a model, calculate an association, p-value,
confidence interval, FDR result, response-scale prediction, scientific
reliability estimate, or tertile outcome result. Do not resample, bootstrap,
simulate, rank participants, modify Stage 3, notify the manuscript writer, edit
shared Quarto configuration, commit, push, upload, or start another Brown
analysis. Heavy computation remains subject to `COMPUTE-001` after a bounded
pilot and explicit compute authorization.

## Reopening condition

Reopen `BA-007` if a frozen identity changes, linkage C cannot uniquely
produce the proposed cycle pairs, pair support is inadequate, the two-level
within-between question requires the failed joint covariance construct, the
endpoint process or response must change, the four-contrast family cannot be
retained, participant disclosure risk appears, a support diagnostic requires
prohibited scientific computation, or the extension would modify an accepted
`BA-003` or `BA-004` result rather than add separate exploratory evidence.
