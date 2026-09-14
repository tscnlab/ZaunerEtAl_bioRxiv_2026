# H03–H11 gated analysis workflow

Decision ID: `AUDIT-002`
Date: 2026-07-31
Status: approved

## Decision

H03 through H11 use a four-stage workflow:

1. audit V0 against the preregistration, stated deviations, actual
   implementation, and developed analysis plan, then propose the main
   analysis;
2. implement the approved analysis, calculate results or an approved pilot,
   compare them with V0, and recreate the figures and tables;
3. produce a standalone reader-facing hypothesis report; and
4. document the result-producing pipeline in a scientific analysis-preparation
   and provenance companion.

When final inference requires a computation-heavy bootstrap or simulation,
the production run is an additional author gate between Stages 2 and 3. It is
not a numbered stage.

Every stage has its own Quarto HTML document and ends at an author gate. The
complete document content, file names, diagnostic requirements, and reopening
rules are specified in
`audit/hypotheses/H03-H11_gated_workflow.qmd`.

One hypothesis task owns all four stages for its assigned hypothesis. It
remains the same task across the audit, implementation, optional production
computation, reader-facing result, and pipeline-description stages, but must
pause for explicit author approval at every scientific gate. Task continuity
does not carry approval forward and does not transfer ownership of shared
preparation, central ledgers, Quarto configuration, or manuscript files.

After the Stage 3 reader-facing report and its artifacts are accepted, the
same task completes Stage 4 by creating
`audit/hypotheses/Hxx/Hxx_analysis_preparation.qmd`. This is a scientific
preparation-and-provenance companion, not a new inferential analysis or gate.
It follows `REPORT-007` and the revised H02 exemplar. The reader-facing page
never labels itself “Stage 4” or “Step 4” and contains no coordinator/worker
roles, gates, approvals, task mechanics, migration history, or irrelevant
construction variants. It explains exact inputs, samples, support,
transformations, temporal ordering, model construction, inference,
diagnostics, influence, sensitivity, scripts, outputs, and checks in plain
scientific language. Rendering is limited to bounded identity checks and
lightweight descriptions; it cannot refit, predict, re-estimate
autocorrelation, bootstrap, simulate, or recompute Shapley results. Figures
require captions, alt text, and paired source data; tables use compact `gt`
layouts. Reciprocal website links, byte-identical authoring and website QMD
sources, non-circular manifests, and focused structural tests are mandatory.
The coordinator owns website integration; the hypothesis task then refreshes
its tests, worker inventory, and handoff around the final website identities.
The complete requirements are in
`audit/decisions/hypothesis_preparation_provenance_companions.md`.

Under `REPORT-012`, every Stage 3 report places a compact **Answer in brief**
note immediately after its hypothesis-and-analytical-question section. The
callout summarizes only verified results and preserves uncertainty,
multiplicity, complementary-placement, and sensitivity qualifications.

This workflow does not retroactively change H01, H02, or the descriptive
output task except where an explicitly approved reporting rule, including
`REPORT-012`, names an existing report for a display-only update.

## Terminology

`V0 analysis` means the analysis that produced the submitted manuscript. The
term is used only in audit and comparison materials. The final reader-facing
document does not mention V0 or discarded analysis variants.

Stage 3 and Stage 4 call the predefined prepared-data sensitivity the
**gap-timing-unaware dataset** under `REPORT-010`. Its first mention explains
that the 50%-per-hour and 80%-per-day coverage rules still apply and that only
the timing of the remaining gaps is not used for an additional metric-specific
adjustment. For contrast at that first mention only, the primary dataset may
be described as something that could be interpreted as a time-sensitive
primary metric dataset; it is called simply **the primary dataset**
thereafter. Historical scenario labels remain confined to audit and internal
provenance identifiers.

## Diagnostic gate

Every post-fit stage shows the relevant model diagnostics, explains what they
indicate, and states whether each model is acceptable, acceptable with a
specified limitation, or not acceptable. A diagnostic plot or test result
without interpretation cannot pass a gate.

## Reopening condition

Reopen if the number or order of stages changes, if production computation is
mistaken for a numbered stage, if V0 is given a different meaning, or if a
stage is permitted to proceed without its required author approval or
diagnostic assessment. Also reopen if separate replacement tasks are used for
successive stages without an explicit handoff decision, or if a preparation
companion performs scientific computation rather than documenting and
verifying accepted artifacts.
