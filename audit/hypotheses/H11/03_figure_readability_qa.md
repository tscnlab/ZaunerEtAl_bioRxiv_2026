# H11 Stage 3 figure readability QA

Date: 2026-08-03  
Policies: REPORT-011 and REPORT-013  
Overall outcome: PASS

## Physical-size basis

All eight reader-facing figures use the approved source typography reference:
a 14-pt cowplot basis, 12-pt ticks and legends, 14-pt titles, axis titles,
facet strips, and tags, and 11-pt captions or minor annotations. The tightly
bounded base and exported canvas is 10.5 inches (266.7 mm) wide. The intended
reader width is 170 mm, so the display-reduction factor is 0.637420. The
resulting calculated effective sizes are 7.65 pt for 12-pt source text and
7.01 pt for 11-pt source text. Both meet the clarified REPORT-011 threshold at
the intended final width.

Each actual exported PNG, rather than a native-canvas replot, was rasterized on
a separate A4 portrait page at 170 mm with 20-mm side margins. The eight-page
QA-only proof is
`artifacts/12_manifests/H11/H11_stage3_figure_A4_proofs.pdf`. A4 page geometry
is not embedded in any final figure asset.

## Page-level inspection

| Proof page | Figure | Result |
|---:|---|---|
| 1 | Primary near-eye curves | PASS |
| 2 | Complementary chest curves | PASS |
| 3 | Gap-timing-unaware near-eye curves | PASS |
| 4 | Gap-timing-unaware chest curves | PASS |
| 5 | Same-sample activity-context comparison | PASS |
| 6 | Primary near-eye residual dependence | PASS |
| 7 | Complementary chest residual dependence | PASS |
| 8 | Primary residual distribution and fitted-value dependence | PASS |

Every page was inspected individually at its A4-equivalent physical layout for
clipping or cropping, overlaps, abnormally narrow or wide text, distorted text,
awkward wrapping, orphaned words, broken units, long labels that compress the
data region, legend-to-data balance, and distinguishability of lines, points,
ribbons, and null lines. All checks passed. Figure captions and non-empty alt
text are retained in the reader Quarto source.

The inspection prompted two display-only repairs before PASS was recorded.
The activity-context subtitle now breaks between placements rather than
leaving an orphaned denominator, and the residual-summary facets use wider
spacing and fewer x-axis ticks so their inner labels do not touch. The final
proof shown above contains those repairs.

The four reader-facing melEDI panels use
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`: the axis is linear
from 0 to 1 lx and base-10 logarithmic above 1 lx, with breaks and labels in
untransformed units. Their paired source-data CSV remains untransformed. Ratio
panels remain on a log-ratio scale because their null is 1 rather than 0.

This QA used stored reader source data and predictions only. No model was
refitted, no prediction was recalculated, and no resampling was rerun for
typography or layout.
