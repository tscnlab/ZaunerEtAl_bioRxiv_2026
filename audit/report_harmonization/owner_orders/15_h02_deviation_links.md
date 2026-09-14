# Harmonization follow-up 15 — exact H02 deviation links

Date: 2026-08-12  
Owner task: `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`  
Controlling decisions: REPORT-014 / CHG-124 and REPORT-016 / CHG-126  
Dispatch mode: **source-only exact-link integration; no Quarto render or scientific execution**

## Exact owned documents and dispatch identities

| Source | SHA-256 at order preparation |
|---|---|
| `notebooks/hypotheses/H02.qmd` | `a871e89f3582c0b9391ea54281d2c2eb47a07660f83d0442618b3fcca4644931` |
| `audit/hypotheses/H02/H02_analysis_preparation.qmd` | `ce85c288ebee45eb1fe2d93d44020cc78dd5c17667fb8167f7aac03a3e23dc29` |

Recheck both identities immediately before editing and stop on drift. The
accepted scientific table text, selected formula, code chunks, prepared
objects, figures, and outputs remain frozen.

## Result-report link integration

At `### Deviations from preregistration`, add the explicit Quarto anchor
`{#h02-preregistration-deviations}`. Keep both existing deviation tables and
their prepared rows byte-identical.

Immediately after the two tables, before `## Model`, add one concise visible
**Related preregistration entries** list. Use literal Markdown links so
Quarto, rather than `gt`, owns and resolves each relative QMD target. Map the
existing row labels exactly as follows:

### Model/estimand table

- Primary placement: [DEV-001](../preregistration_deviations.qmd#dev-001),
  [REP-001](../preregistration_deviations.qmd#rep-001), and
  [REP-002](../preregistration_deviations.qmd#rep-002).
- Outcome and epoch: [DEV-012](../preregistration_deviations.qmd#dev-012).
- Response scale: [DEV-012](../preregistration_deviations.qmd#dev-012).
- Global time effect: [DEV-011](../preregistration_deviations.qmd#dev-011).
- Site smooth: [DEV-010](../preregistration_deviations.qmd#dev-010).
- Participant hierarchy: [DEV-011](../preregistration_deviations.qmd#dev-011)
  and [DEV-021](../preregistration_deviations.qmd#dev-021).
- Variance target: [IMP-005](../preregistration_deviations.qmd#imp-005).

### Data/implementation table

- 30-minute support: [DEV-012](../preregistration_deviations.qmd#dev-012)
  and [IMP-015](../preregistration_deviations.qmd#imp-015).
- Whole-day handling: [DEV-019](../preregistration_deviations.qmd#dev-019)
  and [DEV-057](../preregistration_deviations.qmd#dev-057).
- Clock and DST: [IMP-017](../preregistration_deviations.qmd#imp-017)
  and [DEV-021](../preregistration_deviations.qmd#dev-021).
- Measurement context: [DEV-005](../preregistration_deviations.qmd#dev-005),
  [IMP-012](../preregistration_deviations.qmd#imp-012), and
  [REP-003](../preregistration_deviations.qmd#rep-003).
- Operating range: [IMP-002](../preregistration_deviations.qmd#imp-002).
- Software environment: [DEV-049](../preregistration_deviations.qmd#dev-049)
  and [DEV-050](../preregistration_deviations.qmd#dev-050).

Use the visible stable ID as link text. Do not expose overlay status codes,
change a row's scientific wording, add a different crosswalk record, or move
resolved history into the main interpretation.

## Companion link

In the opening `How to use this provenance page` note, immediately after the
paragraph explaining what rendering does and does not calculate, add one
sentence: `The result report lists the [H02 preregistration
deviations](../../../notebooks/hypotheses/H02.qmd#h02-preregistration-deviations).`
Do not duplicate the full mapping in the companion unless it already makes a
specific deviation statement; if a specific central ID is displayed there,
link it directly to
`../../../notebooks/preregistration_deviations.qmd#<lower-case-id>`.

## Boundary

This is link-only. Do not change data, outcome construction, samples, fitted
models, formulas, AR boundaries, estimates, uncertainty, Shapley allocation,
model checks, sensitivities, figures, tables, captions, or scientific claims.
Do not execute a chunk or run Quarto. Do not edit configuration, ledgers,
stored artifacts, scripts, tests, bibliography, lockfile, manuscript, H11, or
another QMD.

## Focused evidence to return

- pre/post source SHA-256 values;
- exact changed line map;
- confirmation that the two prepared deviation blocks and the selected
  Wilkinson formula are byte-identical;
- all new relative QMD targets/anchors resolved, including the reciprocal
  companion link;
- no hard-coded internal `.html`, `file://`, `_build`, build-directory, or
  absolute local page link;
- identical chunk-label, assignment, inline-R, artifact-reference, and
  figure/table identifier sets;
- scoped status/diff showing exactly the two owned QMDs; and
- `git diff --check`.

Do not render in this follow-up. Focused Phase 4 renders remain separately
released.
