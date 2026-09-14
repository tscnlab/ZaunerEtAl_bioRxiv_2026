# Phase 4 native `gt` source and render verification

Date: 2026-08-13

## Scope

This verification covers the current Nature Health manuscript-table universe in Descriptives and H01 through H11. It checks table construction and rendered HTML structure only. It does not calculate or adjudicate scientific values, execute Quarto chunks, regenerate artifacts, or change any owner source.

H06_daily remains outside this corpus until its reader-facing Stage 3 and Stage 4 sources are accepted.

## Current source contract

The authoritative current source universe contains 195 table endpoints:

- 13 main-table components;
- 182 supplementary tables;
- 195 uniquely labelled Quarto table chunks;
- 195 single Quarto-owned captions; and
- 195 statically proven native `gt_tbl` return paths.

No endpoint uses a prohibited terminal renderer or an unproven native-`gt` path. The five Phase 2 conversion targets and all H06 identifier repairs are present in the current sources. H10's compact main table and H11's combined main table are included. H05's approved continued main table remains two native `gt` components.

The source checker parses chunk code without execution. It also parses the external Descriptives table-helper definitions used by four endpoints. It does not read research data or compare scientific values.

## Current rendered integration

The current HTML audit distinguishes an existing page from an accepted serial Phase 4 integration:

- 181 of 195 current labels already contain one native `gt` table in the existing HTML;
- 118 of 195 existing endpoints also match the current caption and semantic HTML contract;
- 8 of 195 endpoints, all on the accepted Descriptives target render, have accepted source, render, structural, and visual integration; and
- 187 endpoints in H01 through H11 remain pending their serial targeted renders and visual QA.

The lower current-HTML counts do not identify source defects. They reflect pre-harmonization or otherwise stale HTML for pages that have not yet received an accepted Phase 4 target render. In particular, the existing H06 HTML predates its repaired table identifiers, and the existing H08, H10, and H11 pages predate one current table endpoint each.

The non-strict render test passes the present state. The strict completion mode intentionally remains nonzero until all 195 tables have accepted rendered integration.

## Portability boundary

The configured and currently authorized output is HTML. A small number of native `gt` pipelines contain backend-specific HTML markup. The source audit records that condition separately and does not misclassify those endpoints as non-`gt`. DOCX portability remains deferred and must be verified before any later Word delivery.

## Commands and results

All checks used R 4.6.1 and the project library.

```text
/usr/local/bin/Rscript --vanilla scripts/report_harmonization/audit_gt_source_contract.R
Current source table endpoints: 195
Native gt statically proven: 195
Complete source contracts: 195

/usr/local/bin/Rscript --vanilla tests/report_harmonization/test_phase4_gt_source_contract.R
PASS: all 195 current manuscript main/supplementary table sources use native gt.

/usr/local/bin/Rscript --vanilla scripts/report_harmonization/audit_gt_render_contract.R
Current native gt HTML endpoints at current labels: 181
Current complete HTML table structures: 118
Accepted source/render/visual integrations: 8

/usr/local/bin/Rscript --vanilla tests/report_harmonization/test_phase4_gt_render_contract.R
PASS: accepted integrations 8/195; H01 through H11 pending.
```

A scoped trailing-whitespace check found no violations in the scripts, tests, or generated audit records.

## Disposition

No additional source-owner correction is required for native `gt` construction. The remaining work is the already authorized serial Phase 4 render and visual-verification sequence. That sequence remains held at Preparation 01 visual QA before Preparation 02 can be released. No hypothesis page should be rendered out of order merely to advance this table contract.
