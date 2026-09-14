# Harmonization follow-up 14 — exact DEV-056 link in Preparation 06

Date: 2026-08-12  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Controlling decisions: REPORT-014 / CHG-124 and REPORT-016 / CHG-126  
Dispatch mode: **one source-only link edit; no Quarto render or scientific execution**

## Exact owned documents and dispatch identities

| Source | SHA-256 at order preparation |
|---|---|
| `notebooks/preparation/06_model_ready_datasets.qmd` | `cecd5b4f3cd3b4600102d94f6caea7adf6d7506cc8c01105b0de0960e7adc904` |

Recheck this identity immediately before editing and stop on any drift. The
other six preparation QMDs are outside this follow-up and must not change.

## Exact link repairs

In Preparation 06, at the existing identifier-correction paragraph before
`tbl-gap-timing-unaware-correction`, replace the bare `DEV-056` text with
`[DEV-056](../preregistration_deviations.qmd#dev-056)`. Preserve the exact
seven-row TUM exercise-diary correction, both internal participant keys, and
the statement that no scientific light value changed.

Do not add a general deviation index link, change another use of
"deviation" that refers to a fitted statistical departure rather than a
preregistration departure, or create any new mapping. This exact anchor comes
directly from the reconciled crosswalk and REPORT-016 overlay.

## Boundary

This follow-up authorizes only the one Markdown-link edit above. Do not run a
preparation builder, metric derivation, verifier, hypothesis computation,
model, prediction, bootstrap, simulation, Shapley calculation, or full-project
render. Do not edit data, artifacts, manifests, scripts, tests, configuration,
ledgers, decisions, bibliography, lockfile, manuscript, or rendered HTML.
Preserve the visible Preparation 03/04/06 provenance qualifications exactly.

## Focused evidence to return

- pre-edit and post-edit SHA-256 values for the QMD;
- exact changed source lines;
- confirmation that each target QMD and exact anchor resolves;
- confirmation that there is no internal hard-coded `.html`, `file://`,
  `_build`, build-directory, or absolute local page link;
- confirmation that the surrounding scientific paragraph is otherwise
  byte-identical and that no chunk label, R expression, prepared object,
  artifact path, number, or claim changed;
- scoped status/diff proof showing exactly this owned QMD changed; and
- `git diff --check` for the source.

Do not render in this follow-up. A focused render remains a separately
released Phase 4 action.
