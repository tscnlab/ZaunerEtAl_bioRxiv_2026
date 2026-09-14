# Proposed `gt` conversion and H06 identifier specifications

Status: **approved for the first display-adjustment run; final visual review pending**  
Scope: five non-`gt` endpoints and 11 native-`gt` H06 identifier repairs  
Scientific effect: none; presentation and Quarto structure only

## Verified current state

The current targeted Nature Health HTML contains 195 candidate manuscript main or supplementary tables.

- 190 render as native `gt` tables.
- 194 render with a semantic table core (`thead`, `tbody`, and column headers).
- All 195 have exactly one resolved Quarto caption whose text matches the source caption after normalizing HTML whitespace.
- 179 already satisfy the complete proposed native-`gt` publication structure.
- Five need conversion to native `gt`: four Descriptives `knitr::kable()` tables and one H08 code/stdout pseudo-table.
- Eleven H06 tables are native `gt`, but their cell labels do not begin with `tbl-`; Quarto therefore does not create a conforming table anchor and accessible caption relationship.

The row-level machine-readable instructions are in [`gt_conversion_specifications.csv`](gt_conversion_specifications.csv) and [`h06_gt_identifier_repairs.csv`](h06_gt_identifier_repairs.csv). The universal scientific, semantic, accessibility, caption, and verification rules are in [`gt_table_contract.md`](gt_table_contract.md).

## Invariants for every change

Owners must keep the accepted prepared object or stored source, row inclusion, row order, stable key, missingness, units, values, precision, caption, and inferential meaning unchanged. The final cell value must inherit from `gt_tbl`; Quarto alone owns the `tbl-*` label and `tbl-cap`.

The conversion may add semantic stubs, prepared row groups, genuine spanners, readable wrapping, alignment, and notes. It may not filter, join, recode, summarize, calculate, reorder, or replace a value to improve appearance. A discrepancy exposed by conversion stops that document and returns to its scientific owner.

## Five exact conversions

### Descriptives sample flow

- **Source:** `notebooks/descriptives.qmd`, cell `tbl-descriptive-sample-flow`, line 142.
- **Accepted input:** `sample_contract`, loaded from `audit/descriptives/sample_count_contract.csv`.
- **Stable ordered key:** `stage + placement`; eight rows.
- **Preserve:** the existing `mutate(across())` display strings, five renamed columns, and caption.
- **Native-`gt` structure:** `Stage` is the stub and `Placement` is the prepared row-group field. The three count columns remain right-aligned; “Not applicable” remains explicit missing-display text.
- **Evidence:** input identity, ordered-key identity, eight-by-five cell comparison, `gt_tbl` inheritance, one caption/anchor, targeted render, and visual checks.

### Descriptives comparison summary

- **Source:** `notebooks/descriptives.qmd`, cell `tbl-descriptive-comparison-summary`, line 407.
- **Accepted input:** `comparison_summary` built from the three named comparison CSVs.
- **Stable ordered key:** `table + comparison_status`; six rows.
- **Preserve:** the current `bind_rows()`, `count()`, labels, integer cell counts, order, and caption.
- **Native-`gt` structure:** `Comparison status` is the stub and `Table` is the prepared row-group field; `Cells` is an integer body column.
- **Evidence:** object/key identity and exact six-row count comparison to the accepted comparison files.

### Descriptives visual-export comparison

- **Source:** `notebooks/descriptives.qmd`, cell `tbl-descriptive-visual-export-comparison`, line 464.
- **Accepted input:** `visual_export_comparison`, loaded from `audit/descriptives/visual_export_comparison.csv`.
- **Stable ordered key:** `output_id`; ten rows.
- **Preserve:** all paths, dimensions, output/type labels, current order, six visible columns, and caption.
- **Native-`gt` structure:** `Output` is the stub; `Type` remains visible; long paths wrap without truncation; pixel dimensions use consistent alignment. No column is hidden to solve width.
- **Evidence:** object/key identity and exact path/dimension-string comparison for all ten rows.

### Descriptives figure contract

- **Source:** `notebooks/descriptives.qmd`, cell `tbl-descriptive-figure-contract`, line 516.
- **Accepted input:** the existing selection from `artifacts/12_manifests/descriptives/figure_specifications.csv`.
- **Stable ordered key:** `figure_id`; six rows.
- **Preserve:** the current selection, labels, values, units, precision, order, twelve visible columns, and caption.
- **Native-`gt` structure:** `Figure` is the stub. Contiguous spanners may group base geometry, export geometry, display geometry, text size, and physical-size checks. Wrapping—not tiny text—is the first width remedy.
- **Evidence:** selected-input/key identity and exact six-row, eleven-body-value comparison to the accepted manifest.

### H08 evaluated formulas

- **Source:** `notebooks/hypotheses/H08.qmd`, cell `tbl-h08-formulas`, line 373.
- **Accepted input:** the nine evaluated formula objects created from the existing `stats::as.formula()` literals.
- **Stable ordered key:** `site_only`, `additive`, `interaction`, `photoperiod_site_only`, `photoperiod_additive`, `photoperiod_interaction`, `participant_site_only`, `participant_additive`, `participant_interaction`.
- **Preserve:** every formula literal, evaluated formula object, assignment order, cell echo setting, code-fold setting, and caption.
- **Native-`gt` structure:** construct one ordered two-column display tibble from the existing object names and exact deparsed evaluated strings; use `Model` as the stub and `Evaluated Wilkinson formula` as the sole body column; print the one table instead of nine separate stdout formula prints.
- **Evidence:** `identical()` checks for all nine formula objects, exact deparse-string comparison, ordered-key identity, `gt_tbl` inheritance, and targeted render/DOM/visual checks.

## Eleven H06 identifier repairs

No H06 table needs conversion or restyling merely to satisfy the `gt` requirement. Each currently has a native `gt_tbl` with a semantic table core. After approval, the H06 owner changes only the cell label according to [`h06_gt_identifier_repairs.csv`](h06_gt_identifier_repairs.csv), retains the caption and table pipeline, updates any dynamic references, and rerenders H06.

The proposed anchor names use reader-facing terms where the shared vocabulary applies, including `tbl-h06-primary-site-interactions` and `tbl-h06-model-checks`. These names are contingent on approval of the vocabulary package; no label is changed before then.

## Acceptance checks

For each revised endpoint:

1. verify R 4.6.1, `gt`, `knitr`, and Quarto versions;
2. assert accepted prepared input and ordered stable key are unchanged;
3. assert the final value inherits from `gt_tbl`;
4. compare every displayed value, unit, missing label, order, and caption with accepted evidence;
5. render only the owned document under the Nature Health profile;
6. verify one `tbl-*` anchor, one resolved Quarto caption, one descendant `table.gt_table`, semantic `thead`/`tbody`/headers, and a valid caption relationship;
7. inspect normal width, a narrow viewport, and 200% zoom for wrapping, clipping, reading order, notes, contrast, and colour-independent meaning;
8. return source/render hashes and confirm frozen scientific inputs and outputs did not change.

The author authorized these conversions and identifier repairs for the first display-adjustment run. Their appearance and principal/supplement role remain provisional until the resulting focused renders are presented for final visual review.
