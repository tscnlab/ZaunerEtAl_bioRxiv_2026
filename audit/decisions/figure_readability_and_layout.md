# Figure readability and layout

Decision ID: `REPORT-011`

Date: 2026-08-01

Updated: 2026-08-03

Status: approved

The descriptive Figure 1 pilot establishes an approved typography reference,
not an approval of every visual detail in that figure. Its source-level values
are retained as recorded below; clipping, panel balance, annotation placement,
line breaks, and other figure-specific details remain subject to the ordinary
visual-QA gate.

## Scope

This rule applies to every reader-facing figure in preparation, descriptive,
placement, hypothesis, sensitivity, supplementary, and manuscript outputs.
It applies to newly created figures and to existing figures at their next
authorized reporting touchpoint.

## Typography at final size

Figure typography is judged at the size at which the reader actually sees the
figure, not from the font-size argument in plotting code or from an enlarged
development window.

Unless a narrower journal placement is already fixed, the reference check is
a 170-mm-wide (6.69-in) full-width figure, including any legend. An A4 portrait
page with 20-mm left and right margins may be used to simulate that display
width during QA. It is an inspection scaffold only: the final figure must not
be exported or delivered on an A4 page. Figures intended for a narrower
placement must be assessed at that narrower width; passing at 170 mm cannot be
used to approve a figure that will later be reduced.

- Panel letters and text carrying the central result are visually prominent;
  approximately 7--9 pt at final display size is usually appropriate.
- Axis titles, tick labels, legends, facet labels, direct labels, and important
  annotations should normally be approximately 5--7 pt at final display size,
  with the upper part of that range preferred for the main axes and result.
  No essential result, category, unit, or scale information may depend on text
  smaller than 5 pt.
- Minor, non-essential annotations may use approximately 3.5--5 pt when a larger
  label would materially reduce the data region. Small text must remain
  readable and cannot carry information required to understand the main
  result.
- A wide figure that is reduced to fit the HTML column or publication width
  must still meet these effective final-size expectations after scaling.
- Text is never stretched, condensed, or otherwise distorted to make it fit.
  Maintain the font's normal aspect ratio.

If readable labels do not fit, first revise the design: shorten or wrap labels,
use an explained abbreviation, move secondary detail to a caption or table,
reposition or directly label a legend, split an overloaded panel, or choose a
more appropriate figure aspect ratio. Shrinking all text is the last resort.

## Design canvas, export scale, and display size

Treat these as three distinct quantities:

1. `base_width_in` and `base_height_in` define the design canvas supplied to
   `ggsave()` before scaling.
2. `export_scale_multiplier` is the literal `ggsave(scale = ...)` argument.
   The exported device is
   `base_width_in * export_scale_multiplier` by
   `base_height_in * export_scale_multiplier`.
3. `display_width` is the width at which Quarto, a journal page, or another
   output displays the exported asset.

The `ggsave()` scale argument enlarges the graphics device. It does **not**
multiply theme font sizes, line widths, point sizes, legend keys, or other
geoms. Do not emulate it by changing those plot specifications.

For a figure generated directly by a knitr cell, the Quarto equivalent is to
multiply `fig-width` and `fig-height` by the intended export-scale multiplier,
leave the plot object unchanged, and set `out-width` separately for the
reader-facing display. For an externally saved asset, call `ggsave()` with the
literal scale argument and include the resulting asset at the intended
`out-width`. In either route, changing `fig-dpi` alone changes raster
resolution, not the plot-to-text ratio.

Record, at minimum, `base_width_in`, `base_height_in`,
`export_scale_multiplier`, `export_width_in`, `export_height_in`, raster DPI,
and intended HTML and print display widths. The display reduction factor is:

`display reduction factor = display width / export width`

The effective final text size is the nominal plot text size multiplied by this
factor. This calculation remains part of print QA, but it must not be confused
with the export-scale control itself.

Every publication-readiness check must inspect both the actual Quarto display
and a print-size simulation at the intended width. An A4 mock-up is one
permitted simulation and must remain a diagnostic artifact. Native-resolution
preview alone is insufficient, and a direct 170-mm export is not required when
a larger design canvas deliberately gives the accepted plot-to-text balance.

Final PNG, JPEG, SVG, and PDF assets use a tightly bounded figure canvas or
page box that matches the figure itself. They contain no A4 page, page margins,
letterhead, or other surrounding paper canvas. A4 mock-ups are excluded from
submission-facing figure directories and manifests except where a manifest is
explicitly a QA manifest.

The supplied submitted figures show that export scale is content-specific,
not a universal typography setting:

| Reference | Base canvas (in) | Export scale | Export canvas (in) | Raster at 300 dpi |
|---|---:|---:|---:|---:|
| Descriptive Figure 1 | 10.5 x 10 | 1.5 | 15.75 x 15 | 4725 x 4500 |
| Descriptive Figure 2 | 12 x 8 | 1.5 | 18 x 12 | 5400 x 3600 |
| Descriptive Figure 3 | 10 x 10 | 2 | 20 x 20 | 6000 x 6000 |
| Time-series-to-metrics figure | 10 x 9 | 1 | 10 x 9 | 3000 x 2700 |
| Submitted H1 Figure 4 | 13 x 17 | 1 | 13 x 17 | vector PDF |

These are reference geometries, not automatic defaults. Choose a base canvas
that fits the panel structure, then use export scale only when it reproduces a
reviewed plot-to-text balance. A project-wide default will be considered only
after the descriptive pilot is approved.

For the descriptive Figure 1 pilot, the approved source-level typography is a
14-pt `theme_cowplot()` basis, 12-pt tick labels, 14-pt axis titles and panel
tags, an 11-pt caption, and 3-unit map labels. These values are recorded before
export and are not multiplied by `scale = 1.5`. At a 170-mm display width, the
15.75-inch export is reduced by about 0.425, corresponding to about 6.0 pt for
14-pt text and 5.1 pt for 12-pt text. The 3-unit map labels are about 8.5 pt
before export and 3.6 pt at that display width; they are secondary labels whose
site identities are repeated elsewhere in the figure. This approved reference
anchors both the normal 5--7-pt range and the narrow 3.5--5-pt exception for
non-essential repeated detail. Replacing the base theme with a 10.5- or 11-pt
theme before applying `scale = 1.5` would not reproduce the approved ratio.

## Match content and figure dimensions

Canvas dimensions, panel arrangement, and typography are chosen together.
The data region must remain large enough to interpret the plotted values after
titles, facet strips, axes, annotations, and legends are placed. Avoid both
very wide figures whose downscaling makes all text and marks tiny and very
narrow panels in which labels dominate or leave too little room for the data.

Use deliberate line breaks for long facet, axis, legend, and annotation text.
Avoid undesirable mid-phrase breaks, isolated one-word lines, broken units, or
unwrapped labels that compress the plot. Check text length and wrapping in the
rendered output because device fonts and dimensions can alter line breaks.

## Required post-adjustment visual QA

After any change to font size, label wording, wrapping, figure dimensions,
legend position, or panel layout, inspect the final figure at its intended
HTML and publication dimensions. Record these checks:

1. no cropped or clipped text, points, intervals, lines, legends, panel
   letters, or annotations;
2. no overlapping labels, axes, legends, or panels;
3. no unusually wide, narrow, stretched, or condensed text;
4. no undesirable line breaks, orphaned words, broken units, or excessively
   long unwrapped text;
5. axis, facet, legend, and annotation text is readable without zooming;
6. the data region remains proportionate to the surrounding text and legend;
7. line widths, points, intervals, and other marks remain distinguishable at
   final size; and
8. colour, greyscale, caption, and alt-text requirements still pass.

Visual inspection complements structural tests. A successful render alone is
not evidence that these checks pass. Any mandatory failure blocks the figure
from being classified as publication ready.

The QA record must also state the intended display width in millimetres, the
native export width, the resulting scaling factor, the smallest nominal
essential text, and its effective final size. Missing physical-size evidence
is a `NOT TESTED`, not a pass.

## Export-scale pilot

The descriptive showcase pilots the actual `ggsave(scale = 1.5)` behavior.
The plot object, including its font sizes, line widths, points, legend keys,
annotations, and panel arrangement, remains unchanged unless a separate
visible defect is found during QA.

The first showcase reproduces the accepted submitted Figure 1 geometry:

- `base_width_in = 10.5`;
- `base_height_in = 10`;
- `export_scale_multiplier = 1.5`;
- `export_width_in = 15.75`;
- `export_height_in = 15`; and
- `4725 x 4500` pixels at 300 dpi.

Quarto displays the resulting external asset at `out-width: 100%`. The HTML
column width and the optional A4 print mock-up are display controls and do not
alter the stored plot theme. The A4 mock-up is not a final figure format. The
pilot compares the rebuilt descriptive figure with the supplied references at
the same displayed width and checks clipping, label wrapping, panel balance,
and readability.

This is a Figure 1 descriptive pilot only. The author accepted the final
Figure 1 detail layout on 2026-08-11. Figures 2--5, hypothesis figures, and
preparation figures do not automatically inherit `scale = 1.5`; each keeps a
content-appropriate canvas and export scale. The earlier font-and-mark
multiplier interpretation is superseded and must not be used or retained in an
authoritative manifest.

## Computation boundary

Typography and layout repairs use stored figure source data, predictions, or
accepted model outputs. They do not authorize a data rebuild, model refit,
bootstrap, simulation, Shapley calculation, or changed scientific result.
When a figure cannot be repaired from stored outputs, record the limitation and
request a separate scientific-computation decision rather than rerunning the
analysis implicitly.

## Reopening condition

Reopen if the journal's final-size specification changes, a figure format
cannot preserve readable text at the permitted dimensions, or a layout repair
would require a different scientific display or result.
