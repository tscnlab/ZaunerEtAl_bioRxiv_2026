# Brown main-analysis linkage B: Stage 1 reopening

Decision ID: `BA-017`  
Change ID: `CHG-156`  
Date: 2026-09-11  
Status: authorized Stage 1 specification; effective on sealed coordinator dispatch  
Owner: Brown task `019fffdf-66d4-7802-9091-09283ad27b7f`  
Next gate: `BA-LB-G1-REVIEW` (coordinator review of the completed amendment)

Release barrier: owner execution starts only after the BA-017 and CHG-156
ledger entries, non-circular release manifest, and independent release checks
are complete and the coordinator sends their exact identities. The controlling
release evidence is `audit/decisions/brown_main_linkage_b_stage1_release/`.
The former draft and pre-append ledgers are preserved in its `baseline/` root.

## Author direction and decision

The author asked the main analysis to use the exploratory analysis's grouping:
a wake anchor tied to the preceding Sleep and following Pre-sleep. The Writer
and Brown owner relayed this direction on 11 September. The author then asked,
"as its gonna take some time - can you dispatch the Brown pre-sleep window
alignment?" This chooses the new primary linkage and authorizes this bounded
continuation; it does not accept replacement estimates that do not yet exist.

Record linkage B as the requested replacement primary contract. Reopen Stage 1
to freeze its exact sample, model-reuse decision, computation plan, and reporting
dependencies. The current release is for that amendment and its checks only.
Stage 2 fitting and new inference require the subsequent coordinator transition
after this concrete plan passes. Do not ask the author to choose linkage B again.

The independently verified finding is partial existing coverage. An accepted
linkage-B any-valid endpoint-inflated fit exists, together with response-scale
cell estimates, covariance, and three site-average day-type contrasts. The
accepted boundary package contains no linkage-B at-least-80-percent fit or
complete replacement primary package. A filename or historical sensitivity
status must not be promoted into acceptance of the new primary analysis.

## Exact chronology

Let `w_r` be the indexed wake instant, `s_r` the existing Brown contract's
sleep-preparation instant preceding it, and `s_next` the corresponding instant
in the actual following diary record. These symbols retain the existing
timestamp fields and must not substitute sleep onset for sleep preparation.

| Recommendation window | Linkage-B interval | Day-type ownership |
|---|---|---|
| Sleep | `[s_r, w_r)` | Work/Free label of the indexed wake date |
| Daytime, stored as Wake | `[w_r, s_next - 3 hours)` | Same indexed wake-date label |
| Following Pre-sleep | `[s_next - 3 hours, s_next)` | Same indexed wake-date label |

Resolve the following record by participant, actual diary dates, and UTC
chronology. Source-row numbers are provenance keys, not arithmetic positions.
Where a window needs the following record, require the accepted forward
next-date support and do not bridge missing diary days. Retain independent
state eligibility rather than requiring complete triads. Midnight does not
transfer the following Pre-sleep window to a different day type.

Both the former linkage C and linkage B already retain the same full Daytime
interval. Linkage C did not split Wake. The change reassigns Pre-sleep from the
period preceding the indexed Sleep to the period following the indexed
Daytime, changing its sample and sometimes its Work/Free ownership.

## Independent evidence

The coordinator inspected the owner's complete temporary audit implementation
and replayed it under R 4.6.1 in a separate temporary directory. Six substantive
replay outputs are byte-identical. The owner evidence manifest verifies 9/9;
the existing linkage-B fit manifest verifies 7/7. An additional independent
inspection of all 21 top-level endpoint model bundles confirms the absence of
the proposed 2,069-row linkage-B coverage fit. The sole FALSE coverage row,
`existing_B_80_endpoint_model`, is an expected absence finding.

| Sample | State rows | Participants | Wake-anchor cycles | Valid minutes | Complete triads |
|---|---:|---:|---:|---:|---:|
| Historical C, any-valid | 2,216 | 140 | 782 | 1,028,958 | 662 |
| Proposed B, any-valid | 2,298 | 140 | 794 | 1,043,192 | 740 |
| Historical C, at least 80% | 2,004 | 140 | 770 | 985,550 | 507 |
| Proposed B, at least 80% | 2,069 | 140 | 762 | 996,868 | 565 |

Both B samples retain all 54 State x Site x Day-type cells. Sleep and Daytime
scientific rows are identical between C and B for both coverage samples.
All changed membership is in Pre-sleep. Among any-valid Pre-sleep periods, 637
physical periods are shared, 129 occur only in B, 47 only in C, and 182 shared
periods change day-type ownership. The corresponding coverage counts are 534,
83, 18, and 148. These are aggregate audit findings, not replacement model
results.

Direct timestamp checks pass for 771 Sleep, 761 Daytime, and 766 Pre-sleep
rows, and for all 2,298 wake-date/day-type assignments. The normalized diary
contains 21 chronological gaps longer than one date, with a maximum of three
days. Retained B Daytime pairs have one-date successors. The previously
accepted exploratory overlay reconciles 758 Sleep and 618 Pre-sleep pairs
exactly with historical B timestamps and counts. Its source-row deltas of
-6 through +7 must not be interpreted as temporal adjacency.

The existing B fit is `F3/R3/Q2/Q1/D0`, with convergence 0, a positive-definite
Hessian, and recorded status `acceptable_with_cautions`. Its accepted
sensitivity outputs include 54 means and a 54 x 54 covariance, six site-average
means, and three day-type contrasts. The stored quadrature checks pass. These
are useful benchmarks; full primary diagnostic and inferential acceptance is
still required.

This feasibility audit is complete. Reuse its sealed findings and preserved
owner/independent evidence. Do not execute either completed audit script again
or reopen the settled linkage choice. New Stage 1 checks are limited to exact
input identity transfer and genuinely unresolved specification dependencies.

## Frozen authorities and inputs

`shared` is
`/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026`.

`brown` is
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`.

Paths beginning with `stage2/`, `stage2_boundary/`, or
`stage2_cross_state_association/` below are relative to
`brown/audit/analyses/brown_adherence/`.

| Authority/input | SHA-256 |
|---|---|
| shared normalized `artifacts/06_model_data/normalized_inputs/sleepdiaries.rds` | `110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15` |
| `stage2/model_frames.rds` | `13ef1ed1e07d055e369b1e7d479285aee38a0587b61c5b87747067c3bc3a6821` |
| `stage2/frame_manifest.csv` | `47b94e517c3d5b0781dfebdd225a4a4f4dde178c9eb0ed66dc24fbad39ed837f` |
| `stage2_boundary/model_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.rds` | `592d03879523a485f54c8837378ff29c782be20538987e879ec8012ef72c0f75` |
| `stage2_boundary/manifest_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.csv` | `b723c26e76cf3943cc1729e7d11b82265ce480699e0f4721bdb68a4580ea3bf2` |
| `stage2_boundary/boundary_sensitivity_estimands.rds` | `f4b8d1c61e124096bf2b3d63555a33602d2d0c5bc2c0be68f69da7445ffd1b90` |
| `stage2_boundary/boundary_stage2_final_manifest.csv` | `24e0adf52dbc516213cc40f34e27c41dc7fe531553520aae7a22397a6d5bdf97` |
| `stage2_boundary/site_free_work_vs_equal_site_amendment/stage2_ba_m6_final_manifest.csv` | `86cbf5d807a2727715b269208bca5177aa38223f1e79163419a2a905f0eb76ea` |
| `stage2_cross_state_association/cross_state_stage2_final_manifest.csv` | `ec4549c2aaa07145efbc620ede805f735d3c95e7f047a09707d3eac0ba1fb38b` |
| `stage2_cross_state_association/stage2_date_mapping_reconciliation.csv` | `e27a37c657eda5359fb468756027c51d3bb4c296c1a12854be0d297bdf7b1222` |
| `stage2_cross_state_association/stage2_historical_linkage_b_reconciliation.csv` | `6c307a08960c15968500612a1b489370289da482083e831f8cfa687e202d9c1f` |
| shared `audit/decisions/brown_adherence_boundary_stage2_acceptance_stage3_transition.md` (BA-003) | `9fd1c581fcde89a8845c2fabfc47b946e2368da49ca78f2f29c1212bc80de7f7` |
| shared `audit/decisions/brown_adherence_site_daytype_vs_equal_site_stage2_stage3_reopening.md` (BA-015) | `59877990f607cf7d74dcd8e46674b926ed7a6d6ddf8ac030991e1389b02a789a` |
| shared `audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md` (BA-016) | `985c865228d392b8721810d33c5fe89cfc73163393b52ce3074752fda2192ebe` |

The release manifest also records current Brown source/HTML identities as
preservation pins. They are not a new assertion that every current source and
historical HTML represents the same reporting revision. All existing accepted
science, reports, figures, manifests, and stop evidence remain historical
records and are outside this Stage 1 write boundary.

## Exact Stage 1 write boundary

The Brown owner may create new files only under:

`brown/audit/analyses/brown_adherence/main_linkage_b_amendment/stage1/`

Use `plan.md` as the readable amendment and
`stage1_handoff.md` as the return. Include the completed audit's aggregate
support and reassignment tables, input pins, an existing-output coverage
matrix, a model/compute plan, a downstream dependency matrix, verification
evidence, session/command records, and a non-circular final manifest in that
root. Copy completed evidence from this release's `completed_owner_audit/`
and `completed_central_replay/` directories; retain their historical path
fields and provide an explicit original-to-copy inventory.
Internal participant keys may be used for checking but must not enter
reader-facing summaries. Preserve the temporary audit evidence in a clearly
identified historical-evidence subdirectory if incorporated.

Use R 4.6.1 for every scientific check. The near-eye primary frame authority is
the sealed frame object, including deterministic filtering of `linkage_b` by
finite `support_fraction >= 0.80`. Carry forward the completed actual-date/UTC,
ownership, and Brown numerator/denominator reconciliations without rebuilding
minutes or repeating feasibility. Hash existing inputs before and after.
Capture the pre-existing Brown analysis file membership and identities before
creating Stage 1 outputs, then require no changes outside the new root at seal.
New planning checks or evidence corrections inside the new root may be
completed together before the final Stage 1 seal.

This authority permits no fit, optimization, objective reconstruction, TMB
compilation, new predictions, new contrasts, p-values, FDR calculations,
diagnostic simulation, R2/Shapley computation, or scientific figure generation.
It permits no changes to current QMD/HTML, earlier analysis files, manuscripts,
shared configuration, packages, lockfiles, or existing manifests. The amendment
is directly readable Markdown, so no Quarto render is released at this stage.

## Required Stage 1 plan

Freeze the following before requesting Stage 2:

1. The exact chronology, independent validity, inclusive Brown thresholds,
   observed-valid-minute denominator, exact 0/1 handling, equal weighting of
   nine sites, sensor provenance, and separate chest comparison.
2. Exact B any-valid and B coverage-frame membership, support by state/site/day
   type, missingness, boundary mass, participant nesting, and the C-to-B
   reconciliation. Reject an unexplained discrepancy from the counts above.
3. One explicit primary-fit strategy: clean reproduction of the existing B fit
   under a new primary identity, or justified reuse after an exact replay of
   its fit/input gates. Specify the numerical tolerances and the required
   B coverage fit. Start from the accepted `F3/R3/Q2/Q1/D0` structure; any
   structural fallback must follow the established failure-driven hierarchy.
   Never select a rung from desired effects or p-values.
4. Complete, separately versioned BA-M1 through BA-M6 output coverage for
   both B samples, preserving the exact accepted sample-specific definitions,
   weighting, contrast directions, endpoint structure, and multiplicity
   hierarchy. In particular, BA-M6 has one 27-test primary BH family. Its
   identical 27 support-80 contrasts are an unadjusted stability/estimability
   gate, not a second FDR family; preserve the BA-015 direction and
   interval-exclusion rules and do not substitute support-sample significance.
   Recompute each whole relevant primary family, including Daytime and Sleep
   results, because joint-model dependence and FDR adjustment preclude
   splicing in C estimates. These are future Stage 2 specifications, not
   permission to calculate new outputs during Stage 1.
5. The B-to-B coverage claim gate: directions, interval-exclusion decisions,
   and the accepted maximum 2-percentage-point shift rule. A historical
   C-to-B linkage comparison is not this coverage gate. The 2-percentage-point
   rule applies only where the existing main contract prescribes it, not as a
   new BA-M6 magnitude threshold.
6. The required primary fit/endpoint/calibration/residual diagnostics, the
   established 250-draw conditional predictive diagnostic, true-date temporal
   checks and exact trigger for any OU sensitivity, nine LOSO fits, and the
   bounded five-participant influence screen. Enumerate all other previously
   accepted sample/measurement sensitivities and explicitly classify which
   require B reruns, which can be reused, and why.
7. Separate B chest construction and comparison, retaining the accepted
   measurement-position qualifications. The sealed frame's chest rows are
   linkage C only. Identify and pin the original accepted chest coverage
   artifact needed for following Pre-sleep periods; do not assume that
   reassigning available C rows gives complete B coverage, particularly at
   record ends. Specify that future construction and its exact sample checks
   without generating a new chest frame at Stage 1. Do not pool positions or
   change measurement interpretation through the linkage amendment.
8. Point-only response-scale marginal/conditional R2, retained random-effect
   increment, global and within-state Shapley allocations, both coverage
   samples, and the established quadrature checks after model acceptance.
9. Exact prospective model counts, runtime evidence from existing execution
   records, resource/concurrency limits, execution order, restart policy,
   and paths for every proposed Stage 2 output. COMPUTE-001 continues to
   govern any computation-heavy bootstrap or simulation beyond the separately
   bounded diagnostic draws. No such additional production is released here.
10. A complete dependency map for main tables, compact displays, BA-M4/BA-M6
    markers, figures, coverage comparison, calibration, random effects,
    R2/Shapley, chest sections, Supplementary S5, provenance, and Writer
    inputs. Treat the exploratory cross-state model as a frozen candidate for
    reuse only after exact pair/sample/input reconciliation. Verify the
    139-profile/417-point raincloud before reuse; do not assume identity from
    similar terminology. Preserve its limitations and withheld day-level claim.

The earlier tag-size finding is separate: the current accepted S5 outer A/B
tags already equal about 6.5 pt at 170 mm. Preserve that convention in the
future display plan. No tag or current figure edit is released by BA-017.

## Gates and coordination

Return the completed Stage 1 package at `BA-LB-G1-REVIEW`. The coordinator will
review the support/identity reconciliation, complete dependency coverage,
model strategy, and bounded compute plan and then issue the separate Stage 2
release. The current author direction is sufficient for the linkage choice.

Replacement Stage 2 estimates and diagnostics must reach a new author-review
gate, `BA-LB-G2-REVIEW`, before a Stage 3 replacement is accepted. Stage 3 and
Stage 4 reporting and any targeted renders will have explicit later boundaries.
Do not revise the accepted exploratory model or release updated manuscript
claims merely because this Stage 1 gate has passed.

The Writer may continue its independent headings, citation, title/abstract
options, and unaffected editable-table work. Final Brown-dependent prose,
numbers, table releases, and website/download synchronization remain pending
the replacement accepted evidence. Do not wake the Harmonizer or Navigation
owner for integration before that evidence exists.

The coordinator appends only BA-017 and CHG-156. All previous register rows and
central acceptance files remain byte-identical. Brown is outside the 15-row
hypothesis coordination matrix, which is not changed by this release.

Order 72d native-SVG Word review and Order 72h selection-preview recovery are
independent. This release does not change their candidates, sources, manifests,
render allowances, or holds, and does not modify the production website.
