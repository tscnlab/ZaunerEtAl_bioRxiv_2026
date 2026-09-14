# Nature Health manuscript shared-change request

Date: 2026-08-14

Status: **open for coordinator and report-harmonization disposition**

Requested shared correction: reconcile reader-facing statements about whether gender was measured.

## Conflict

The current H10 reader source states that gender identity was neither measured nor inferred. The accepted source audit shows that the normalized demographic artifact contains separate `sex` and `gender` fields. H11 already states the correct analytical boundary: gender is a distinct construct and was not analysed.

The author's manuscript feedback confirms the intended interpretation: gender was available in the data but was not analysed.

## Evidence

- `notebooks/hypotheses/H10.qmd`, current reader paragraph near the start of the scientific question: says gender identity was neither measured nor inferred.
- `audit/hypotheses/H10/01_audit_and_plan.qmd`: carries separate biological-sex and gender variables through the audited sample construction and records both fields.
- `audit/hypotheses/H11/01_audit_and_plan.qmd`, section `The measured construct: biological sex, not gender`: states that the normalized demographics artifact has separate fields and that gender does not enter the model.
- `notebooks/hypotheses/H11.qmd`: states that gender is a distinct construct and was not analysed.

## Requested wording boundary

Shared reader prose should state, in substance:

> Biological sex and gender were recorded as separate variables. The accepted analyses used biological sex, coded Female or Male. Gender was not analysed.

The correction must not imply that gender and biological sex are interchangeable, that gender was inferred from sex, or that the biological-sex results apply to gender identity.

## Manuscript disposition

The task-owned Phase 3 manuscript uses the evidence-supported wording above. No accepted reader report, analysis, central ledger or shared configuration was edited by the manuscript task. The coordinator or report harmonizer should determine whether the H10 reader source and any dependent rendered material require a controlled wording correction.

