# Shared `gt` contract for manuscript main and supplementary tables

Status: **approved for the first display-adjustment run; final output appearance remains subject to author review**  
Current validated versions: R 4.6.1, `gt` 1.3.0, `knitr` 1.51, Quarto 1.9.37  
Current Nature Health profile target: HTML; submission-stage DOCX is explicitly deferred

## Scope

Every manuscript main and supplementary table from Descriptives and H01–H11 must end as a native `gt_tbl` printed from its labelled knitr cell. This includes all 195 currently catalogued table candidates, the proposed new compact H10 main table, the proposed combined H11 global-test main table, and any later accepted H06_daily manuscript/supplement table.

The requirement applies equally to principal and supplemental tables. A table must not be implemented as `knitr::kable()`, a data-frame/paged-table print, code/stdout placed under a table caption, raw HTML, LaTeX-only markup, a screenshot, or a separately saved image reinserted into Quarto.

Current evidence shows:

- 190 of 195 current candidate tables already render as native `gt` tables;
- 194 have a rendered semantic table core, and all 195 rendered captions resolve and match their source captions;
- 179 already satisfy the complete proposed native-`gt` publication structure;
- four Descriptives support tables use `knitr::kable()`;
- H08's formula “table” is code/stdout under a Quarto table caption rather than a semantic table;
- all current principal-table components use `gt`, but H10's proposed compact main table does not yet exist;
- 11 H06 tables use native `gt` but need `tbl-` identifiers for valid Quarto cross-references.

Exact evidence is in `phase2_gt_table_audit.csv`, with the five conversions isolated in `phase2_gt_conversion_targets.csv`. The endpoint-specific instructions are in `gt_conversion_specifications.md`, `gt_conversion_specifications.csv`, and `h06_gt_identifier_repairs.csv`.

## Analysis boundary

`gt` is a presentation layer over accepted prepared data. Owners must not use a table pipeline to make or adjudicate a scientific decision.

- Keep joins, filters, exclusions, recoding, denominators, estimates, confidence intervals, p-values, multiplicity adjustments, transformations, back-transformations, sample counts, and reported summaries in the accepted upstream R objects or stored outputs.
- Preserve raw values, missingness, units, row inclusion, and row order.
- A formatter may change display text or precision; it must not conceal or replace an analytical transformation.
- `sub_missing()` may display an approved missing-value label; it must not turn missingness into zero or another measured state.
- A reported summary must come from validated prepared data. `summary_rows()` may express table anatomy but must not become a second scientific implementation.
- No table conversion authorizes fitting, refitting, prediction, simulation, bootstrap, Shapley analysis, or shared-preparation rebuild.

For each table, retain a stable input key, capture the prepared input before table construction, and test that the input and key order remain identical after constructing the `gt_tbl`.

## Canonical Quarto ownership

Each table uses a labelled R cell and lets Quarto own numbering and cross-references:

````markdown
```{r}
#| label: tbl-example
#| tbl-cap: "Concise description of population, comparison, and purpose."

prepared_table_data |>
  gt::gt(rowname_col = "Measure") |>
  gt::cols_label(estimate = "Estimate", interval = "95% CI")
```
````

Requirements:

- label begins with `tbl-` and is unique within the project;
- `tbl-cap` is the single numbered document caption;
- the final cell value inherits from `gt_tbl`;
- do not also use `gt(caption = ...)` or `tab_caption()`;
- use `tab_header()` only when an internal title supplies genuinely different information and does not repeat the Quarto caption;
- preserve dynamic `@tbl-*` references and verify that no literal unresolved reference remains;
- print the native table rather than `as_raw_html()`, `capture.output()`, `gtsave()` plus re-inclusion, or private object fields.

## Semantic table anatomy

Use `gt` grammar rather than visual workarounds:

1. `gt::gt()` with `rowname_col` for true row labels and `groupname_col` for prepared row groups.
2. `cols_label()` for reader labels and `tab_spanner()` for genuine column hierarchy.
3. `fmt_*()` for display formatting, followed by `sub_*()` for approved substitutions, followed by `text_*()` only when necessary. The final applicable formatter controls each cell.
4. `tab_footnote()` targeted to exact labels/cells for abbreviations, symbols, missingness, or exceptions.
5. `tab_source_note()` for concise whole-table provenance or interpretive qualifications.
6. `cols_hide()` for stable helper fields used in targeting; never target by fragile displayed row positions when a key or raw-data condition exists.
7. `tab_options()` and restrained `tab_style()` only after semantic structure and annotations are stable.

Existing document-specific `gt` helpers can remain when they return a `gt_tbl` and satisfy this contract. A new shared table theme is not required. The project has no `_brand.yml`; the Nature Health profile currently relies on its HTML theme plus local H06 font normalization. Owners should preserve the accepted visual system instead of introducing a new font, icon, or colour scheme.

## Main-table hierarchy

Principal tables should make the central comparison visible without requiring readers to decode implementation fields.

- Use one concise Quarto caption.
- Put row groups or stubs in scientific, not construction-history, order.
- Use unit-bearing labels and the approved p-value convention. Use `FDR`, not the abbreviation `BH`, in reader-facing displays after defining false-discovery-rate adjustment; retain the full Benjamini–Hochberg method name only where reproducibility requires it.
- Display every site name with its ISO alpha-2 country code, for example `Tübingen (DE)`, in stubs, groups, columns, notes, and captions.
- Put interval type, multiplicity family, abbreviations, missing-value meaning, and necessary sample qualifications in targeted footnotes/source notes.
- Avoid an internal `tab_header()` that repeats the caption.
- Do not use colour as the only indicator of retained support, model suitability, or placement. Pair it with explicit text, a symbol, or typographic emphasis.

Supplementary tables may retain more model, sample, diagnostic, and sensitivity detail, but use the same caption, semantic, accessibility, and analysis-boundary rules.

## Wide and long tables

Do not solve width by making text unreadably small. In order:

1. remove only genuinely redundant display columns, never scientific content;
2. shorten labels without changing meaning;
3. move repeated definitions to a targeted note;
4. use concise spanners and semantic row groups;
5. retain approved numerical precision;
6. split genuinely distinct questions into separately cross-referenced `gt` tables;
7. use a backend-specific long-table or landscape option only after a targeted render proves it necessary.

H05's two near-eye result blocks remain one logical continued table with a shared caption/note hierarchy. H10's compact main table and H11's combined global-test table are display-only selections from stored accepted rows and must be implemented as `gt_tbl` objects.

## Accessibility

- Use true headers, stubs, groups, and spanners.
- Define abbreviations and non-obvious symbols.
- Use explicit approved missing-value text.
- Preserve meaning without colour and maintain readable contrast.
- Avoid essential hover-only content, raw HTML, tiny fonts, and excessive precision.
- Verify reading order and horizontal overflow at normal width, a narrow viewport, and 200% zoom.
- Keep caption, notes, labels, and body understandable when copied as plain text.

## Current and deferred format targets

The configured Nature Health review profile is HTML-only. Therefore current owner evidence must include a focused HTML render and browser inspection for each revised document; no full-project render is authorized.

The profile explicitly defers a submission-stage DOCX until the manuscript is stable. When that DOCX or a supplementary Word/PDF deliverable is configured and approved, the same semantic `gt` pipelines must be rendered and inspected in that target. No owner should add HTML, LaTeX PDF, Typst PDF, Word formats, filters, extensions, or packages solely for this harmonization task.

Raw `html()` and HTML interactivity are prohibited in a common manuscript table unless the author separately approves a documented format-specific fallback. If a future backend drops meaning, simplify the common semantic table or branch only the unsupported presentation feature while retaining identical prepared data, order, labels, caption, and notes.

## Required owner evidence

For every changed table or table helper, return:

1. exact QMD, labelled chunk, prepared object/file, and stable row key;
2. R, `gt`, `knitr`, and Quarto versions;
3. an assertion that the result inherits from `gt_tbl`;
4. assertions that the prepared input and stable key order are unchanged;
5. checks of visible row/column order, units, precision, signs, missing text, labels, footnotes, source notes, and conditional cues against the accepted stored input;
6. a targeted HTML render log;
7. DOM evidence of one `tbl-*` anchor, one resolved Quarto caption, and one descendant `table.gt_table`, with no duplicate caption or literal `@tbl-*` reference;
8. visual inspection at normal width, narrow width, and 200% zoom, including clipping, wrapping, spanners, stubs, notes, and colour-independent meaning;
9. source and render hashes plus confirmation that frozen scientific inputs/outputs outside the display layer did not change;
10. any format-specific difference or check that could not be completed.

For the later submission target, add programmatic artifact checks and visual inspection appropriate to DOCX or PDF. A successful render command alone is not sufficient evidence of fidelity.

## Final compliance condition

The `gt` requirement is complete only when every accepted manuscript main and supplementary table—including future accepted H06_daily outputs—has:

- a native `gt_tbl` source pipeline;
- a conforming `tbl-*` identifier and single Quarto caption;
- unchanged accepted prepared data and row order;
- semantic, accessible table anatomy;
- a targeted accepted render with programmatic and visual verification in every configured delivery format.
