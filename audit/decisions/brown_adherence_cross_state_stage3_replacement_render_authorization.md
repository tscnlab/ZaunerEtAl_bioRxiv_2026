# Brown cross-state association Stage 3 replacement-render authorization

Decision ID: `BA-009`  
Change ID: `CHG-148`  
Date: 2026-08-20  
Status: coordinator authorized; one bounded replacement Stage 3 render

## Decision

The first targeted render authorized by `BA-008` was completed before the
Stage 3 contract audit found that the reader report did not yet display three
required stored-output elements:

1. the exact any-valid and at-least-80-percent selected-sample rows;
2. the endpoint and overall calibration disposition; and
3. the approved point-only descriptive Wake-cycle groups.

The Brown cross-state task corrected only its authorized Stage 3 reader source
and display references using frozen Stage 2 outputs. The corrected source
passes all 19 R 4.6.1 source checks. The anonymous raincloud figure remains
exactly 139 profiles and 417 participant-state points, and its PNG and SVG
identities are unchanged.

`BA-009` and `CHG-148` authorize one replacement targeted render of the
corrected reader report, followed by replacement render checks and secure
loopback visual QA. This is a render-completion amendment to `BA-008`. It does
not reopen Stage 2 or change any scientific contract, estimand, selected model,
multiplicity family, estimate, interval, p-value, diagnostic disposition,
claim, figure, or frozen Stage 2 output.

## Controlling Stage 3 identities

| Artifact | Status | SHA-256 | Bytes |
|---|---|---|---:|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | corrected source authorized for replacement render | `3771dfb0da51e4eb63ae26711bbaccc1d11d0459675674ca06f0a40d6c2a2ae1` | 21,736 |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | first unsealed render, now stale | `be628abc02138bada1de9819a3379dec519667414da18dbfa7ed4a8a3c13afbe` | 3,679,869 |
| `stage3_cross_state_association/stage3_source_verification.csv` | 19 of 19 checks passed | `2c401c2052f2c709bb4a43afb61c8490f4418a735d8f7911b16f2da932601da2` | 1,350 |
| `stage3_cross_state_association/stage3_display_manifest.csv` | 16 display members | `f935243c1a2d000eea142115abd33c9073554ddf62815ae5835482cce4503b75` | 4,322 |
| `stage3_cross_state_association/figures/participant_state_raincloud.png` | unchanged | `f3a61b69e89b0933302694ccca4ea5ed5c4d1bb2e67d169f3e1542a644843228` | 1,832,424 |
| `stage3_cross_state_association/figures/participant_state_raincloud.svg` | unchanged | `48bf8f999bd3422ed1c6aef9209259cc4a4e96d1999d0a9563800f89682766fc` | 108,573 |

Paths beginning with `stage3_cross_state_association/` are relative to
`audit/analyses/brown_adherence/`. The task must reproduce every identity
above immediately before the replacement render. The stale HTML identity is
historical execution evidence and is expected to change exactly once.

The following frozen Stage 2 source-data identities used by the three added
reader elements must remain exact:

| Frozen stored output | SHA-256 |
|---|---|
| `source_data/table_selected_sample.csv` | `503e010a7e5ef3a214987e753acf2d05e69dabc4c57fb61eed0cc37292827338` |
| `source_data/table_diagnostic_assessment.csv` | `8854c439ed3982984d07c4242c99198e607f1e3de477b8cb862423baad8250b8` |
| `source_data/table_descriptive_wake_cycle_groups.csv` | `7ae87552993cf3a6d514229d395edea41b80b2d8b0871c46e762f894f4db5ca1` |

These paths are relative to the Stage 3 directory. Their values were copied
from the accepted Stage 2 package and may not be recalculated or rewritten.

## Authorized replacement render

The continuing Brown cross-state task may execute exactly one replacement of
its prior targeted command:

```text
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Use the same R 4.6.1 and Quarto 1.9.37 environment recorded for the first
targeted render. No full-project render, shared Quarto integration, package or
lockfile change, model load for estimation, fit, refit, prediction, new
p-value or confidence interval, simulation, resampling, or scientific
artifact regeneration is authorized.

The replacement render may update only the targeted Stage 3 HTML and its
task-owned render, verification, manifest, handoff, and visual-QA evidence
under `audit/analyses/brown_adherence/stage3_cross_state_association/`.
Accepted Stage 1 and Stage 2 files, figure files, paired figure source data,
the four-member `BA-CS-M1` family, the main Brown analysis, shared files, and
central ledgers must remain byte-identical from the task's pre-render state.

## Required replacement verification

After the one render, the task must:

1. rerun the complete focused R 4.6.1 source and HTML checks, including the
   exact selected-sample rows, both calibration dispositions, all 12
   point-only Wake-cycle-group rows, and the 139-profile/417-point figure;
2. verify every frozen Stage 1 and Stage 2 identity and every protected
   scientific and display input;
3. confirm native table structure, paired source links, privacy protections,
   no internal gate history in reader prose, no new inferential output, and
   no broken or missing figure;
4. seal one replacement non-circular final manifest and a new Stage 3
   handoff that supersede only the unsealed first-render integration evidence;
5. inspect the replacement HTML at desktop and mobile viewports through a
   server bound only to `127.0.0.1`, including the added sample, calibration,
   and Wake-cycle displays and the unchanged raincloud figure; and
6. stop the server, prove that no listener remains, and verify post-QA file
   stability.

The task must stop and return a sealed failed state on any unexplained
identity change, scientific recomputation, missing required display, privacy
violation, render error, broken link, material visual defect, or incomplete
server teardown. No second replacement render is authorized.

## Mandatory stop

The mandatory author gate remains `BA-CS-G3-REVIEW`. The replacement HTML is
not accepted as a scientific result until the complete Stage 3 package passes
the replacement checks and the author explicitly approves that gate.

Do not notify the Nature Health manuscript writer, begin Stage 4, modify the
main Brown result, or perform shared integration before that author approval.

## Reopening condition

Return to the coordinator before further work if any controlling identity
other than the stale HTML changes, the three required elements cannot be
rendered from the frozen stored outputs, the raincloud identities or
139-profile flow change, a new inferential calculation is required, or the
task would exceed the paths and single-render boundary above.
