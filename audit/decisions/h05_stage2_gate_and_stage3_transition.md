# H05 Stage 2 gate and transition to the reader-facing result

Decision ID: `H05-001`
Date: 2026-08-01
Status: approved

## Decision

The author approved H05 Stage 2 gate items 1–5 and 7:

1. the zero-of-68 primary result and withdrawal of the two V0 significance
   claims;
2. fixed site as the primary site adjustment and the faithful/corrected V0
   displays;
3. the model-adequacy classifications, including the four materially limited
   sleep-environment models;
4. the two leading F2 estimates as stable but not multiplicity-retained;
5. the complementary chest and registered sensitivity interpretations; and
7. the claim dispositions and strongest defensible conclusion.

The former item 6 is superseded because it incorrectly described production
computation as Stage 3. The deferred expensive analyses remain deferred and no
production bootstrap or simulation is required for the approved H05 primary
inference. H05 nevertheless proceeds to mandatory Stage 3, the standalone
reader-facing result.

## Controlling sequence

1. H05 Stage 1 audit and proposed analysis: complete and approved.
2. H05 Stage 2 implementation and V0 comparison: complete and approved,
   subject only to correcting the workflow wording without scientific
   recomputation.
3. H05 Stage 3 standalone reader-facing result: authorized to begin and must
   stop for author approval.
4. H05 Stage 4 scientific pipeline description and provenance: blocked until
   Stage 3 is approved.

Production computation is an unnumbered gate between Stages 2 and 3 when it
is needed. It is not needed for H05.

## Required Stage 2 wording repair

The H05 task updates and rerenders
`audit/hypotheses/H05/02_implementation_and_v0_comparison.qmd`, its HTML, and
`audit/handoffs/H05_stage2_handoff.md` to remove statements that Stage 3 is
optional or may be skipped. It records the author approvals above and states
that only a production-computation gate is optional. No model, estimate,
interval, diagnostic, sensitivity result, or claim is recomputed for this
repair.

## Stage 3 and stop gate

Stage 3 is authored at `notebooks/hypotheses/H05.qmd` and rendered to
`_build/nathealth/notebooks/hypotheses/H05.html`. It follows the shared
four-stage contract, presents near-eye primary and chest complementary results,
uses stored verified H05 outputs, and includes the H05-specific diagnostic and
sensitivity qualifications. The task stops after the Stage 3 source, HTML,
tests, manifests, and handoff are complete.

Stage 4 may begin only after explicit author approval of Stage 3. Its source is
`audit/hypotheses/H05/H05_analysis_preparation.qmd` under `REPORT-007`.

## Reopening condition

Reopen if the Stage 2 wording repair changes a scientific output, if a
production computation becomes necessary, if Stage 3 omits a material H05
limitation or changes the approved conclusion, or if Stage 4 begins before
Stage 3 approval.
