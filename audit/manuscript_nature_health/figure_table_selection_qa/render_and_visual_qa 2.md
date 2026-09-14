# Nature Health figure and table selection: render and visual QA

Date: 2026-08-23

## Runtime

- R 4.6.1
- Quarto 1.9.37
- gt 1.3.0
- xml2 1.6.0
- knitr 1.51
- digest 0.6.39

The Quarto document has execution disabled. No hypothesis QMD, scientific input, model, estimate, figure export, or accepted reader HTML was executed or changed.

## Build

The planning assets were generated with:

```text
Rscript --vanilla scripts/report_harmonization/build_manuscript_figure_table_selection.R
```

The final document was rendered with:

```text
quarto render manuscript_figure_table_selection.qmd
```

The final render completed without a Pandoc warning. Two earlier environment checks produced no usable artifact: document-level `--output-dir` was rejected before conversion, and the sandboxed Quarto Sass cache could not open its database. The first successful diagnostic build exposed raw HTML div nesting in the copied table previews. The extractor was corrected to emit explicit raw-HTML blocks before the final build.

## Structural acceptance

- Final HTML: `767b3e5d1693b844ef72979d262e5a7a90dbf469fb7503f83e6d2b8a6f078af4`, 14,601,500 bytes.
- R structural checker: 26 of 26 checks passed.
- Accepted source inventory: 13 hypothesis or descriptive reports.
- Rendered document: 18 tables, including 14 accepted native gt previews; 15 figures; 14 disclosures.
- All 15 images have nonempty alt text, loaded successfully, and are embedded in the standalone HTML.
- Document IDs are unique. All 1,829 explicit table-header tokens resolve exactly once to a `th` element inside their own table.
- The preview semantic step made 256 reversible substitutions limited to gt-internal `id` and `headers` values. Visible text, values, table order, and accepted figure bytes were unchanged.
- All document anchors and the four relative planning-file links resolve.
- No embedded error or warning node was found.

## Visual acceptance

A temporary static server was rooted exactly at `audit/manuscript_nature_health`, bound only to `127.0.0.1:58421`, and used only for the route `manuscript_figure_table_selection.html`.

- Desktop, 1440 by 1000: title, decision cards, six-item sequence, table of contents, figures, and captions were readable with no page overflow.
- Narrow, 708 by 1000: no page-level horizontal overflow; all 15 figures stayed inside the content area; all wide accepted tables remained inside contained horizontal scrollers.
- The compact Brown Table 1 remained readable at narrow width and preserved the distinction between pooled-minute fractions and modelled state-period estimates.
- The H02 daily-architecture figure loaded at 3,300 by 4,200 source pixels and displayed completely at 616 pixels wide in the narrow layout.
- At the 720 by 500 200-percent-equivalent viewport, the page retained its responsive layout without image clipping or horizontal page overflow.
- The browser console contained zero warnings or errors attributable to the page.

The browser viewport was reset, the QA tab was closed, and the server was stopped. A final listener check found no process on `127.0.0.1:58421`. The final HTML hash remained unchanged after QA.
