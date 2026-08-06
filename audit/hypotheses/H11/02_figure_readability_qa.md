# H11 Stage 2 figure readability QA

Date: 2026-08-01  
Policy: REPORT-011  
Status: **PASS**

## Scope and method

The four H11 curve/contrast figures, two boundary-aware residual-correlation
figures, and two frozen V0 audit figures were visually inspected at their
intended full report-column display size. The generated figures use a 7.2-inch
canvas and declare at least 7 pt for important text. The inspection covered
clipping, overlaps, distortion, wrapping, data-region balance, legend balance,
line/point distinguishability, and the accessibility contribution of captions
and alt text.

This was display-only QA. No model was fitted or refitted, and no bootstrap,
simulation, or other scientific recomputation was performed for typography.

## Display-only repair

The first chest renders placed an open circle at each of all 48 displayed clock
bins because every pointwise interval excluded one. This obscured the nearly
constant ratio curve. The final chest and chest sensitivity renders omit those
redundant circles and state directly in the subtitle that all 48 displayed
pointwise intervals exclude one and that the intervals are not simultaneous.
The source-data rows are retained unchanged. Ratio-axis breaks were also
adjusted to show 0.75, 1.00, 1.50, and 2.00 clearly at final size.

## Result

All eight inspected figures passed. Generated figures have readable sample
subtitles, axes, ticks, legends, panel titles, annotations, and interval-scope
captions without clipping or crowding. Female and Male use an accessible pink/
blue palette and remain traceable by their labelled curves and ribbons.
Residual diagnostic lines remain distinguishable by colour, position, and
point markers.

The frozen V0 figures are retained only as author-facing audit evidence. Their
embedded text is readable at full width, but the near-eye figure contains the
known incorrect work/free-day caption and red pointwise-to-period overclaim.
The surrounding report caption and alt text identify both limitations. Neither
frozen figure is authorised for the Stage 3 or Stage 4 reader-facing report.

The machine-readable checklist is
`artifacts/12_manifests/H11/H11_stage2_figure_readability_qa.csv`.
