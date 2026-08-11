# H04 preparation-figure readability QA

Date: 2026-08-11

Overall outcome: PASS

Inspection basis: each final, tightly bounded PNG was inspected at original
resolution and at its intended 170-mm display width, together with the direct
Quarto HTML render. A four-page A4 portrait proof places each figure at 170 mm
between 20-mm side margins; that PDF is a QA simulation only and is not a
final figure asset.

## Figure checks

- `fig-h04-prep-positive-distribution`: PASS. Near-eye and chest panels are in
  the intended order; original-unit lux labels are legible; the long x-axis
  title, facet labels, and y-axis title are not clipped; the positive-only
  display is visibly separated from the exact-zero table and caption.
- `fig-h04-prep-category-support`: PASS. Both panels retain adequate data
  region, all six category labels follow the reader-facing order, near-eye
  and chest bars are distinguishable, and the legend and axis ticks are
  unclipped.
- `fig-h04-prep-site-category-support`: PASS. Submitted site labels, all six
  categories, sparse-cell circles, and the weighted-hour colour legend are
  legible. The two placement panels remain balanced and no text overlaps.
- `fig-h04-prep-clock-category-support`: PASS. All 24 hourly cells remain
  distinguishable, the selected clock ticks are clear, locally sparse circles
  and no-observation crosses are separable, and the weighted-hour colour
  legend is unclipped.

For every figure, clipping/cropping, overlaps, text distortion, line wrapping,
units, legend balance, mark distinguishability, caption presence, and alt-text
presence were checked. All mandatory items passed.
