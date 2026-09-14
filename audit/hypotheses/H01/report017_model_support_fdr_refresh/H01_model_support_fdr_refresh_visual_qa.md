# H01 model-support FDR display refresh: visual QA

Date: 2026-08-14

Scope: display-only inspection of
`artifacts/10_figures/H01/stage3/H01_stage3_model_support.png` after the
bounded REPORT-017 order 31f refresh.

## Inspected displays

- Original raster: 3,360 by 2,368 pixels at 320 dpi.
- Intended reader display: the H01 result page uses the figure at 100% of the
  available content width.
- Focused region: bottom legend title and the adjacent status keys.

## Result

PASS. The visible title is `FDR-adjusted result`. It is legible at the
original size and at the intended full-width reader display. The title does
not overlap the first legend key or label. The legend remains centred, the
two status keys remain aligned, and there is no clipping, cropping, distorted
text, or altered panel geometry. Metric labels, facet headings, cells,
symbols, colours, and question labels remain visually unchanged.

The pixel audit found 5,697 changed pixels in the bounding box x =
1,564...1,916 and y = 2,276...2,312. This box is wholly inside the authorized
legend-title region x = 1,540...1,920 and y = 2,240...2,340. Every raster
pixel outside that region is identical. The SVG retains 372 lines and differs
only at line 365, the legend-title text node.

No Quarto render or scientific computation was used for this inspection.
