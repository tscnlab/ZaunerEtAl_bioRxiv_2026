# Rendered HTML publication-output repair proposal

## Finding

Final DOM inspection of the Nature Health descriptive HTML found two
presentation-layer defects. The six externally generated descriptive figures
were emitted from absolute filesystem paths, which Quarto converted to invalid
`../Users/...` URLs. The 17 miniature metric distributions were present, but
Quarto's HTML image processing removed the `alt` attributes embedded by the
native `gt` table.

## Proposed repair

- Emit each external figure with a path relative to the source QMD, allowing
  Quarto to copy the referenced PNG into the profile output directory and
  retain a portable relative URL.
- Keep each miniature distribution as a redundant visual summary, add a
  visually hidden metric-specific description in its `gt` cell, and mark the
  image itself as hidden from assistive technology. The adjacent numerical
  cells remain the authoritative accessible values.
- Extend verification to the rendered HTML DOM, not only the pre-Quarto
  `gt::as_raw_html()` representation.

## Scientific impact assessment

This repair changes no input, sample, inclusion rule, denominator, metric,
summary, table value, plotted geometry, colour, or inference. It changes only
resource addressing and accessibility markup in the HTML publication layer.

## Decision

Approved for implementation in the descriptive-only Quarto and publication
table modules, followed by a clean render and renewed structural and visual
inspection.
