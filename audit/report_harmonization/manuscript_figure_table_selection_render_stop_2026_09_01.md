# Nature Health selection preview render stop

Date: 2026-09-01

Status: `FAIL_CLOSED_POST_RENDER_STRUCTURAL_CHECK`

## Boundary

The source-only H04 revision 3 integration was independently accepted before this target render. The selection source SHA-256 was `0f267a8721b404918f092e3405ba428182105286aee977ad46c4c892e6d11826`. The selected H04 PNG and SVG were exact at `22d402974fc0df26c77536e5db8af166e87637f2192ea4cc4f01da2d98ebb122` and `012453debcd7994ab8b8437bd1b829a4935b26d97803963c6621ee2093bd72dd`.

The first sandboxed invocation of `quarto render manuscript_figure_table_selection.qmd` stopped before document generation because Quarto could not open its user-owned Sass cache. The identical command then ran once with the established narrow cache access and exited 0. The rendered HTML was not accepted or promoted beyond its canonical standalone planning location.

## Stopped post-render identities

- `audit/manuscript_nature_health/manuscript_figure_table_selection.html`
  - SHA-256: `ab635effc0cf11f99da2fc690944f25eaf6d996755ed741bc912f1b45c3fcc0d`
  - bytes: `30512389`
- `audit/manuscript_nature_health/figure_table_selection_qa/structural_checks.csv`
  - SHA-256: `42cf79420183e11188bd07031f9177af55cd96112c28201eb327ed0c6452c947`
  - bytes: `2685`

## Consolidated findings

The existing structural checker stopped with 21 of 30 gates passing. The failed gates were:

- selection asset manifest live identity, 34 of 36;
- accepted output inventory live identity, 0 of 13;
- current native `gt` and manual planning-table count expectations;
- the former manual-table scroller expectation;
- document ID uniqueness;
- scoped table-header resolution, 1,143 of 1,191;
- the exact occurrence-count form of the author-decision check; and
- the stale H01 synthesis endpoint/label selector.

The two stale selection-manifest members are the accepted H06_daily and H07 table fragments. The duplicate document IDs are confined to the two newly embedded H02 Shapley table fragments and consist of their shared unscoped `gt` header, group, and stub identifiers. These are integration and verifier contracts, not scientific discrepancies.

No manuscript render, visual QA, hypothesis render, model execution, scientific calculation, or scientific artifact change occurred. The main manuscript and Supplementary Information outputs remain held.

One complete no-render Harmonizer repair and downstream replay was requested before any replacement selection render.
