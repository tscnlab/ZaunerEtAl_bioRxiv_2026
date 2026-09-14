# Descriptive-figure export-scale pilot

Decision ID: `REPORT-011-PILOT-001`

Date: 2026-08-01

Updated: 2026-08-11

Status: Figure 1 author accepted

Use the literal ggplot2 export option `scale = 1.5`. This multiplies the export
device width and height while leaving typography, line widths, points, legend
keys, annotations, and all other plot specifications unchanged.

For the Figure 1 showcase, reproduce the submitted export contract:

- `base_width_in = 10.5`;
- `base_height_in = 10`;
- `export_scale_multiplier = 1.5`;
- `export_width_in = 15.75`;
- `export_height_in = 15`;
- `dpi = 300`; and
- expected raster dimensions `4725 x 4500` pixels.

The other accepted submitted descriptive exports demonstrate why this is not
yet a universal `1.5` default: Figure 2 used `12 x 8` inches with scale `1.5`,
Figure 3 used `10 x 10` inches with scale `2`, and the time-series-to-metrics
figure used `10 x 9` inches with scale `1`. The pilot therefore tests the most
directly comparable Figure 1 contract first and stops before changing the
remaining figures.

The rebuilt figure retains the accepted data, panel composition, plot theme,
site order and colours, curves, intervals, annotations, and protocol raster.
Do not redesign the figure merely to accommodate the export scale: the larger
canvas is the requested mechanism for changing the plot-to-text ratio.

The submitted source-level typography is part of that plot specification:
ordinary cowplot panels use the 14-pt base, 12-pt ticks, 14-pt axis titles and
panel tags, an 11-pt caption, and 3-unit map labels. These values are restored
before export; they are not multiplied by 1.5. The repeated profile uses
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`.

In Quarto, display the external image at `out-width: 100%`. For a directly
generated knitr figure, the equivalent is `fig-width = 15.75` and
`fig-height = 15` with the unchanged plot object and a separately declared
`out-width`. `fig-dpi` controls raster resolution only and is not a substitute
for export scaling.

Regenerate Figure 1 only from the already authorized descriptive figure source
data. Produce the updated standalone asset and the descriptive HTML view. An
A4 mock-up may be produced solely to inspect the figure at the intended print
width; it is not a final export and must not enter a submission-facing figure
directory. Do not run preparation, metric, hypothesis, model, prediction,
bootstrap, simulation, or Shapley computation.

The author accepted the final Figure 1 detail layout in the updated
[descriptive showcase](../../_build/nathealth/notebooks/descriptives.html) on
2026-08-11 after the reviewed Panel B label placement and Panel E annotation
routing were incorporated. This closes detail-level QA for Figure 1. It does
not make `scale = 1.5` a universal default. The prior font-and-mark multiplier
implementation remains invalid and must not be promoted to the figure
manifest, QA record, or report.
