# Descriptive table and figure style-replication repair proposal

Date: 2026-07-31

## Finding

The rebuilt descriptive tables and several rebuilt figures use the verified
updated data and corrected denominators, but their presentation does not
faithfully reproduce the manuscript-generating outputs retained in `tables/`
and `figures/`. The table implementation introduced a new publication theme,
header rules, source notes, and widths. The figure implementation retained the
intended constructs but changed themes, titles, dimensions, and some visual
encodings. Side-by-side inspection therefore fails the requested exact visual
replication criterion even where the scientific content is correct.

## Proposed repair

1. Treat the table-building and figure-building code in `Descriptives.qmd` and
   its read-only helpers as the visual specification.
2. Replace only the old data layer with the already verified rebuilt table and
   figure source data.
3. Preserve correctness repairs that materially affect interpretation,
   including explicit denominators, circular clock summaries, separate
   placements, contextual rather than adherence wording, opaque diary/non-wear
   bands, and the verified main-day sample.
4. Apply DISPLAY-001 from `config/site_display_registry.csv` for every visible
   site label, order, and colour; do not edit the shared registry.
5. Export the three publication tables as PNG files using the original
   `gtsave()` viewport settings. Export all durable figures as SVG, PNG, JPEG,
   and PDF at the original physical dimensions, with 300-dpi raster exports.
6. Compare every new export with its retained original counterpart and record
   intended similarities, unavoidable content-driven differences, dimensions,
   and visual-QA status.

## Scientific impact

Presentation only. The repair must not change imported data, exclusions,
participant or participant-day samples, metric calculations, point estimates,
uncertainty, denominators, model coding, formulas, or inference. Any numerical
change observed after the repair is a failure and must be investigated in R.

## Acceptance criteria

- Table typography, grouping, alignment, site tinting, footnote placement,
  spanners, separator rows, and column proportions match the submitted design.
- Figure panel arrangement, themes, scales, bands, labels, and export dimensions
  match the submitted design except where a documented correctness repair
  requires a visible change.
- Table CSVs and figure source-data CSVs remain scientifically identical before
  and after the presentation repair.
- Clean-session tests, deterministic rebuild checks, and the Quarto render pass.
- A durable side-by-side comparison record covers every exported table and
  figure.
