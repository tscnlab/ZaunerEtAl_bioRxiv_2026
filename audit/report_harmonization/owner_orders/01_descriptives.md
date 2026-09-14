# Harmonization order 01 — Descriptives

Date: 2026-08-12  
Owner task: `019fb87f-41b5-75c1-bc11-aa7fa233ef89`  
Controlling decisions: `REPORT-014` / `CHG-124`  
Current source at dispatch: `notebooks/descriptives.qmd`, SHA-256 `c755492977778030d06d2d28931edc865876c7c24b6bafda408acf7aa4634285`  
Dispatch mode: **source-only first; focused render held until the coordinator clears the H06_daily Stage 2 compute window**

## Exact owned document

- `notebooks/descriptives.qmd`

Associated Descriptives-owned focused tests and manifests may be updated only where necessary to verify these display-only source changes. Do not edit shared Quarto configuration, central ledgers, bibliography, preparation pages, hypothesis pages, or manuscript files.

## Reader structure

Use the approved Descriptives information order:

1. study sample and country-coded sites;
2. data coverage and near-eye-primary/chest-complementary placement roles;
3. main descriptive figure and table;
4. light distributions and temporal context;
5. important data-quality or denominator qualifications; and
6. dynamic links to Preparation 01 and 02 plus material source data.

Move replication history, export pilots, source hashes, manifest comparisons, and submitted-analysis construction history out of the main reader flow. They may remain in a restrained final technical/provenance section or an existing audit link when scientifically necessary. Do not remove a qualification merely because it is technical.

## Approved language

- Use the current scientific meaning, not “submitted”, “old”, “reproduced”, “pilot”, internal `REPORT-*` identifiers, pinned-manifest language, or production mechanics in reader prose.
- Keep `symlog` after one concise first-use explanation: identify its linear and logarithmic ranges and state that tick labels remain in the original unit.
- Use “model checks” if any diagnostic umbrella term appears.
- Use “near eye” as primary and “chest” as complementary; do not imply placement equivalence.
- Every reader-facing site name must include its country code in prose, tables, figures, legends, captions, and alt text. At minimum repair the uncoded occurrences around current source lines 199, 298, and 305 (`Tübingen (DE)`, `Munich (DE)`). Preserve the approved registry names, order, and colours.
- Use `false-discovery-rate (FDR) adjustment` at first use and `FDR` thereafter if multiplicity is mentioned; never use the reader-facing abbreviation `BH`.

No introductory glossary box is requested for this document. Prefer concise first-use prose.

## Dynamic links

Add only the approved material links, using relative `.qmd` targets:

- `[Preparation 01](preparation/01_import_state_alignment.qmd)` for aligned records and state handling;
- `[Preparation 02](preparation/02_coverage_sample_flow.qmd)` for shared coverage and denominator flow.

Do not introduce `.html`, `file://`, `_build`, or absolute-path page links. There is currently no deviation mention in this source, so no deviation link is requested at this pass. If editing exposes one, stop that passage and return its stable central ID rather than inventing a link.

## Main and supplemental outputs — provisional first adjustment

- Main figure: `fig-descriptive-overview`. Retain all five panels and full-width placement. Standardize only panel-label/caption hierarchy, preserve the country-coded site names/order/colours, and confirm concise alt text and target-size legibility. Do not recompute or redesign the figure.
- Main table: `tbl-participant-site`. Keep one clear title, restrained group headers, concise unit-bearing column labels, and only interpretively necessary footnotes. Preserve all stored values and denominators.
- Other current figures/tables remain supplemental or report-support outputs. Apply only the approved shared typography, caption, footnote, spacing, country-code, and accessibility conventions.

The author’s approval of these roles and adjustments is provisional. Return the focused main figure/table render for final visual approval after the render window opens.

## Four mandatory native-`gt` conversions

Convert only the final display endpoint; keep every prepared value, key, order, and existing formatting transformation unchanged:

1. `tbl-descriptive-sample-flow`: native `gt_tbl` with `Stage` as the stub and `Placement` as the row group; verify all 8 rows and 5 displayed values.
2. `tbl-descriptive-comparison-summary`: native `gt_tbl` with `Comparison status` as the stub and `Table` as the row group; verify all 6 counts.
3. `tbl-descriptive-visual-export-comparison`: native `gt_tbl` with `Output` as the stub; retain `Type`, paths, dimensions, order, and wrapping; verify all 10 rows and 6 displayed values.
4. `tbl-descriptive-figure-contract`: native `gt_tbl` with `Figure` as the stub; add only genuine contiguous spanners, preserve all precision/order/values, and allow wrapping rather than tiny type; verify all 6 rows and 11 non-stub values.

Each labelled table cell must print a native `gt_tbl` as its final value. Keep the current Quarto `tbl-cap`/cross-reference relationship. Do not use `knitr::kable()`, raw HTML, screenshots, or a saved-table image. Follow `audit/report_harmonization/gt_table_contract.md` and the exact endpoint specifications in `audit/report_harmonization/gt_conversion_specifications.csv`.

## Scientific and computation boundary

This is display-only. Do not change or independently recalculate data, sample flow, denominators, metric values, estimates, intervals, p-values, diagnostics, sensitivity results, placement roles, or claims. Do not rebuild Descriptives inputs/figures, run a scientific preparation script, fit a model, predict, simulate, bootstrap, update packages/lockfiles, or trigger a full-project render. If a wording or `gt` conversion exposes a scientific discrepancy, stop the affected passage/table and return it for scientific review.

## Evidence to return

### Source-only return now

- exact changed source lines and a concise mapping to this order;
- post-edit SHA-256 of `notebooks/descriptives.qmd`;
- confirmation that the four prepared table objects and their ordered keys/values are unchanged before versus after the `gt` endpoint;
- a static check showing no hard-coded internal `.html` links, uncoded study-site names, reader-facing `BH`, or prohibited production-history terms remain in the main reader flow;
- confirmation that no non-owned file or scientific artifact changed.

### Focused render return after explicit compute-window release

- bounded command and exit status for `quarto render notebooks/descriptives.qmd --profile nathealth` under R 4.6.1;
- `tests/descriptives/run_tests.R` result and any narrowly relevant table-contract check;
- source and targeted HTML SHA-256 identities plus updated Descriptives manifest evidence;
- rendered proof that all four converted endpoints contain semantic native-`gt` tables with captions, headers, table bodies, and accessible source notes;
- focused screenshots/previews of `fig-descriptive-overview` and `tbl-participant-site`, plus the four converted tables, with no clipping or unreadable text;
- frozen-output comparison confirming no scientific artifact/value changed.
