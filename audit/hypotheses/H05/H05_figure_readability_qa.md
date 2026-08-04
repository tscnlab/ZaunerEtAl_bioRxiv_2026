# H05 figure readability revalidation

Date: 2026-08-03

Rules: REPORT-011; REPORT-013 applicability assessed

Scope: all 10 reader-facing figures in the H05 results report and analysis-preparation companion

Overall outcome: PASS

## Inspection basis

Each final figure was placed at its actual QMD display width within a 170-mm
reference frame on a separate A4 portrait proof page. The resulting ten-page
proof, `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf`, was inspected
together with the rendered Quarto pages. The display widths ranged from
149.6 mm to 170.0 mm, leaving at least 20 mm on each side of the A4 proof.
Calculated effective essential text sizes ranged from 5.76 pt to 6.43 pt; the
central values in the two effect matrices were 7.11 pt. The A4 page is an
inspection scaffold only and is not part of any final reader-facing asset.

REPORT-013 was assessed as not applicable. These figures show model effects,
model-adequacy categories, residual diagnostics, matched placement estimands,
LEBA-score distributions, sample counts, or site ranges. None shows a
non-negative, strongly right-skewed raw metric distribution with meaningful
exact zeros for which a reader-facing symlog scale would be appropriate.

## Initial findings and display-only repairs

The first physical-size proof exposed four layout defects: clipped subtitles
in the near-eye and chest effect matrices, a left-cropped quantile--quantile
title, and a right-clipped subtitle in the paired-placement figure. The
subtitles were wrapped, the diagnostic title was shortened, and the result
figure canvases and text sizing were adjusted. Figures were then redrawn from
the accepted stored result tables or diagnostic points, the H05 report was
rerendered, and the complete physical-size proof was regenerated. No model,
prediction, diagnostic statistic, sensitivity result, bootstrap, or simulation
was recomputed.

## Final inspection

| Figure | Outcome | Final visual assessment |
|---|---|---|
| `fig-h05-near-effects` | PASS | Metric and factor labels, 95% confidence-interval cell values, legend, and grey unfit cells are readable and unclipped. |
| `fig-h05-near-adequacy` | PASS | Labels, adequacy categories, cell marks, and legend are readable and distinct without overlap. |
| `fig-h05-near-residual-fitted` | PASS | Facet titles, axes, points, smooths, and subtitle are proportionate, readable, and fully visible. |
| `fig-h05-near-residual-qq` | PASS | Facet titles, axes, points, reference lines, and the unfit-for-inference qualification are readable and fully visible. |
| `fig-h05-chest-effects` | PASS | Metric and factor labels, 95% confidence-interval cell values, legend, and grey unfit cells are readable and unclipped. |
| `fig-h05-chest-adequacy` | PASS | Labels, adequacy categories, cell marks, and legend are readable and distinct without overlap. |
| `fig-h05-paired-placement` | PASS | Four panels, equal-axis geometry, identity and null lines, and annotations are readable; the caption does not imply equivalence. |
| `fig-h05-prep-leba-distribution` | PASS | Facet titles, axes, ticks, bars, and participant labels remain readable in a balanced four-panel layout. |
| `fig-h05-prep-sample-support` | PASS | Both panels, metric ticks, placement legend, lines, and points are readable and distinguishable. |
| `fig-h05-prep-site-range` | PASS | Site names, placement panels, axes, ticks, ranges, and points are readable and unclipped. |

Across all ten figures, the final inspection found no clipping or cropping,
overlap, distorted text, awkward wrapping, broken units, excessive legend
competition, or indistinguishable marks or lines. Captions and accessible alt
text remain present in the Quarto sources and rendered pages.
