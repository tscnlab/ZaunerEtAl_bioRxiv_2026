# H11 analysis-preparation figure readability QA

Date: 2026-08-06  
Policies: REPORT-011 and REPORT-013  
Overall outcome: PASS

## Physical-size basis

All three reader-facing figures were exported on tightly bounded 8.5-inch
canvases. They are intended for display at 170 mm on an A4 portrait page with
20-mm side margins. The resulting display-reduction factor is 0.787402.
Central 12-pt source text therefore resolves to 9.45 pt, essential 10-pt text
to 7.87 pt, and minor 9-pt text to 7.09 pt. All meet the physical-size
requirements of REPORT-011.

Each exported PNG was placed, without replotting, on a separate A4 portrait
QA page at the intended 170-mm width. The three-page QA-only proof is
`artifacts/12_manifests/H11/H11_preparation_figure_A4_proofs.pdf`. The A4 page
geometry is not part of any final figure asset.

## Page-level inspection

| Proof page | Figure | Result |
|---:|---|---|
| 1 | Site-by-sex support in the primary fitted frames | PASS |
| 2 | Positive melEDI distribution and retained exact zeros | PASS |
| 3 | Activity-context attrition, paired horizontal bars | PASS |

Every page was inspected at its A4-equivalent physical layout for clipping or
cropping, overlaps, distorted or abnormally narrow/wide text, awkward
wrapping, orphaned words, broken units, long labels that compress the data
region, legend-to-data balance, and distinguishability of lines, points, and
bars. All checks passed. The final assets are tightly bounded to the figures.

For the activity-context attrition figure, each placement is now represented
by a conventional horizontal bar beginning at the shared 0% baseline. Near-eye
and chest bars are paired within category and carry direct one-decimal
percentage labels. No free-standing or endpoint-ambiguous connector lines
remain.

The melEDI distribution uses
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)` with original-unit
breaks and labels. The scale is linear through 1 lx and base-10 logarithmic
above 1 lx. Exact zeros are displayed separately and remain present in the
fitted frames. The paired source-data CSV stores untransformed melEDI values.

This QA used frozen frames and stored derived source data only. No model was
fitted, no prediction was recalculated, and no resampling was run for display
or typography.
