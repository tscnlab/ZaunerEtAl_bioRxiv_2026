# Brown adherence cross-state association Stage 2 acceptance and Stage 3 transition

Decision ID: `BA-008`  
Change ID: `CHG-147`  
Date: 2026-08-20  
Status: author approved; bounded cross-state association Stage 3 authorized

## Author decision and controlling status

The author explicitly approved `BA-CS-G2-REVIEW`, directed the continuing
Brown cross-state association task to proceed to Stage 3, and assigned the
new connected raincloud display to Stage 3 rather than reopening Stage 2.

This decision accepts the sealed Stage 2 implementation and its split
scientific disposition. The accepted `BA-003` and `BA-004` endpoint-inflated
Brown recommendation analysis in `07_results.qmd` remains the main analysis.
The cross-state association remains a separate exploratory extension. It does
not replace the main analysis, reopen the stopped `BA-005` and `BA-006`
participant-profile model, or become an H01 through H11 hypothesis.

`BA-008` and `CHG-147` close `BA-CS-G2-REVIEW` and authorize only the bounded
Stage 3 reader-report work below. The next mandatory author stop is
`BA-CS-G3-REVIEW`.

## Accepted Stage 2 identities

| Accepted artifact | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/12_cross_state_association_implementation_and_reconciliation.qmd` | `6ecf97d45846b9df09822fc52d1b30eeff14a6be77f3cf348bc7760eaeedc7e4` |
| `audit/analyses/brown_adherence/12_cross_state_association_implementation_and_reconciliation.html` | `914e730b151103b23d28362a1aa0c2f8b08b2855d87c966bdaa0b1cda6bb9412` |
| `audit/analyses/brown_adherence/stage2_cross_state_association/cross_state_stage2_author_gate.csv` | `8af713db5f8eb25653898d35a97416d61b4bc0652ae8bc3cec9894a5770a55c7` |
| `audit/analyses/brown_adherence/stage2_cross_state_association/stage2_handoff.md` | `78770b0cb5415608acd6bf24bdfd9a499cd5598df3b20c28cfe0b0a66d06e382` |
| `audit/analyses/brown_adherence/stage2_cross_state_association/cross_state_stage2_finalization_checks.csv` | `841a9cf33a767f6d6afeeb143045659316db7bd74ddb6ea6027e28b308672979` |
| `audit/analyses/brown_adherence/stage2_cross_state_association/cross_state_stage2_final_manifest.csv` | `ec4549c2aaa07145efbc620ede805f735d3c95e7f047a09707d3eac0ba1fb38b` |

Independent R 4.6.1 verification matched all 162 non-circular manifest
members by path, byte count, and SHA-256; all 15 finalization checks; all four
primary `BA-CS-M1` effects; and all four at-least-80% claim-gate rows. It also
matched the 47 protected Stage 1 members, 518 protected historical members,
and 11 protected shared inputs recorded in the sealed package. The desktop
and 390-pixel served visual checks passed and no listener remained.

## Frozen scientific and reporting sources

The following Stage 2 identities are direct Stage 3 inputs and remain
read-only:

| Frozen input | SHA-256 |
|---|---|
| `stage2_cross_state_association/cross_state_model_frames.rds` | `f206722e544e3b9c860da0e7b2ba5d1ddeded59247a6ba4993f235cc6770d5f7` |
| `stage2_cross_state_association/model_CS-ANY-F3-R3-Q2-Q1-D0.rds` | `6a175cafa8153cb82b3ca4904682c34dd187a1d49dbffa573983f88328c526b2` |
| `stage2_cross_state_association/model_CS-80-F3-R3-Q2-Q1-D0.rds` | `d735428c337969c4411e28268d31e34c3d244ba058776e4eb56264f39411aae1` |
| `stage2_cross_state_association/association_effects.csv` | `17039f2887b5b212b3a8639a3675904c9eb606a82a628e347f2795692678b923` |
| `stage2_cross_state_association/multiplicity_BA_CS_M1.csv` | `c86a119f0bd272c54088024a8e7fdf660f865bc697316f41521c6e0aad19e47f` |
| `stage2_cross_state_association/claim_gate_80.csv` | `762efe853d3b764939c9fadcecf7682c3c5df44490ac1f259ee7fff88f787f84` |
| `stage2_cross_state_association/selected_model_summary.csv` | `503e010a7e5ef3a214987e753acf2d05e69dabc4c57fb61eed0cc37292827338` |
| `stage2_cross_state_association/stage2_technical_assessment.csv` | `996c2581a0518e1436cd48ac52f78ecec9ddeed7075640673290269eadb655c5` |
| `stage2_cross_state_association/descriptive_wake_cycle_groups.csv` | `7ae87552993cf3a6d514229d395edea41b80b2d8b0871c46e762f894f4db5ca1` |

Paths in this table are relative to
`audit/analyses/brown_adherence/`. Every other member of the accepted
162-member Stage 2 manifest is equally protected.

Before Stage 3 work begins, the continuing task must match this decision, the
unique `BA-008` and `CHG-147` ledger rows, every identity above, and all 162
manifest members. It must also verify that `BA-007` and `CHG-145` remain
unique and that the 47 Stage 1, 518 historical, and 11 shared protected
identities remain exact. Stop on any unexplained mismatch. Stage 3 must not
repair, reseal, or regenerate an accepted Stage 1 or Stage 2 artifact.

## Accepted scientific disposition

The selected exploratory model is the endpoint-inflated beta-binomial
`F3/R3/Q2/Q1/D0` model in both the any-valid primary sample and the identical
at-least-80% gate. The participant intercept remains. The non-identifiable
association-cycle intercept was removed at the prespecified R3 rung.

The complete `BA-CS-M1` family contains exactly four effects per 10 percentage
points higher Wake adherence:

| Level | Target | Effect, percentage points | 95% CI | FDR-adjusted result |
|---|---|---:|---:|---:|
| Within participant | Sleep | -0.26 | -0.95 to 0.43 | 0.453 |
| Within participant | Pre-sleep | -1.09 | -2.75 to 0.56 | 0.258 |
| Between participants | Sleep | -2.52 | -3.55 to -1.48 | <0.001 |
| Between participants | Pre-sleep | -3.59 | -5.94 to -1.25 | 0.005 |

The Stage 3 report must preserve these distinctions:

- the within-participant day-level claim is withheld because temporal
  dependence remains unresolved;
- the between-participant result may be reported as acceptable with
  limitations;
- all four at-least-80% checks preserve direction and interval-exclusion
  status, with a maximum response-scale shift of 0.60 percentage points;
- bounded leave-one-site-out and participant-deletion checks are limited and
  must retain their exact qualifications;
- the existing low, middle, and high Wake-cycle groups are descriptive only;
- hard participant tertiles and participant-ranking claims remain prohibited;
  and
- every interpretation is observational, cohort-specific, non-causal, and
  avoids stable-trait language.

## Authorized Stage 3 paths

The continuing Brown cross-state association task may create or update only:

- `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
- its targeted standalone render
  `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html`;
  and
- new task-owned display code, source data, figures, tables, focused tests,
  manifests, visual-QA records, and a new Stage 3 handoff under
  `audit/analyses/brown_adherence/stage3_cross_state_association/`.

The frozen Stage 1 handoff
`audit/handoffs/brown_adherence_cross_state_association_handoff.md` and the
frozen Stage 2 handoff
`audit/analyses/brown_adherence/stage2_cross_state_association/stage2_handoff.md`
must remain byte-identical. Stage 3 must create its own handoff inside the
authorized Stage 3 directory.

No `07_results.qmd` edit, Stage 4 path, shared Quarto integration, manuscript
edit, central-ledger edit, commit, push, upload, package installation, or
full-project render is authorized.

## Stage 3 reader-report contract

Stage 3 is a stored-output reader report with one newly authorized descriptive
figure construction. It may read the frozen Stage 2 CSV and RDS inputs, copy
accepted estimates into reader tables, and derive only the descriptive
participant-state averages and sample-flow counts required for the figure.
It may not fit or refit a model, rerun prediction or diagnostics, change the
BH family, calculate a new p-value or confidence interval, resample, simulate,
or regenerate a Stage 2 scientific artifact.

The reader report must include:

1. a clear statement that the accepted Brown boundary analysis remains the
   main analysis and this report is a separate exploratory association
   extension;
2. an answer-in-brief that withholds the day-level claim and reports the
   modest inverse between-participant associations with their exact
   limitations;
3. the any-valid and at-least-80% sample flow, selected model structure, and
   four-member `BA-CS-M1` result table in practical percentage-point units;
4. the endpoint-calibration, temporal, at-least-80%, equal-day-type,
   leave-one-site-out, and bounded influence dispositions without implying
   stronger stability than the accepted evidence supports;
5. the existing descriptive Wake-cycle groups without category-level
   inference; and
6. a restrained limitations section covering unresolved temporal dependence,
   observational interpretation, short-term participant means, incomplete
   influence retention, endpoint-model cautions, cohort specificity, and the
   prohibition on hard participant tertiles.

Use native `gt` tables, accessible figures with paired source data, practical
units, visible 95% confidence intervals, and plain reader language. Internal
gate IDs, model-rung history, and production terminology belong only in a
separate reproducibility note.

## Required connected raincloud figure

Stage 3 must add one reader-facing descriptive figure with adherence on the
y-axis and Brown state on the x-axis. Its exact construction is:

1. use only the frozen any-valid `primary_any_valid` member of
   `cross_state_model_frames.rds`;
2. deduplicate Wake at participant by association-cycle before aggregation so
   a cycle with both target states contributes only once to Wake;
3. calculate the unweighted mean of observed state adherence across valid
   association cycles separately for Wake, Sleep, and Pre-sleep for each
   participant;
4. retain only participants with at least one observed value in all three
   states, so every connection is complete;
5. show one anonymous point per participant-state and connect the three points
   for the same participant with thin low-alpha lines;
6. add a distribution layer and a compact descriptive central-summary layer;
7. use the state order `Sleep`, `Wake`, `Pre-sleep` to reflect the accepted
   preceding-Sleep, Wake-anchor, following-Pre-sleep construction;
8. state in the caption that connecting lines identify the same anonymous
   participant across state summaries and are not time trajectories or
   participant ranks; and
9. omit an at-least-80% overlay from the primary figure. Any later sensitivity
   figure would require separate authorization.

The R 4.6.1 feasibility check against the frozen frame yields exactly 139
complete participants and 417 participant-state points. Stage 3 must reproduce
and record that flow before drawing the figure.

The paired figure source data may contain only a non-identifying sequential
profile key, state, adherence, and the minimum counts needed to document the
aggregation. It must not expose source participant identifiers, site-linked
participant keys, ranks, tertiles, or any reversible participant crosswalk.
The sequential profile key must be assigned deterministically after an
internal stable ordering and must carry no scientific ordering meaning.

The figure must use accessible colour and shape choices, legible final-size
text, a useful alt description, and both a lossless raster export and a vector
export if the established task workflow supports both without a package
change. The final manifest must bind the figure, paired source data, builder,
caption, alt text, dimensions, and visual-QA evidence. The report and figure
must make no causal, ranking, typological, or stable-trait claim.

## Verification and mandatory stop

The task may run one targeted render of
`13_cross_state_association_results_amendment.qmd`, focused R 4.6.1 source and
HTML checks, a non-circular final manifest, protected-identity verification,
and bounded loopback visual QA at a typical desktop viewport and a narrow
mobile viewport. Exported figures must also be inspected at their intended
final size. The loopback server must bind only to `127.0.0.1`, serve only the
smallest required directory, and be fully stopped with no listener remaining.

Stop at `BA-CS-G3-REVIEW` after the source, targeted HTML, native tables,
figure, paired source data, tests, final manifest, handoff, and visual-QA
evidence are complete. No Stage 3 result is accepted before the author
explicitly approves that gate.

Do not notify the Nature Health manuscript writer before author approval. On
author acceptance, return the complete Stage 3 package to the coordinator for
a central closure record and notification of writer task
`019ffb39-372e-7262-bfac-192751fd0e63` with the accepted identities and a
concise scientific summary.

## Reopening condition

Reopen `BA-008` before further work if a protected identity changes, the
139-participant figure flow cannot be reproduced, participant privacy cannot
be preserved, the figure or report requires a new inferential calculation,
the author changes the accepted split disposition, hard participant tertiles
or rankings are proposed, a new model or response family is needed, heavy
computation is requested without `COMPUTE-001`, or the extension would alter
an accepted `BA-003` or `BA-004` result.
