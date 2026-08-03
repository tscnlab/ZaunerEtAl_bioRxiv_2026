# REPORT-011 physical-size revalidation

Date: 2026-08-01

Updated: 2026-08-03

Status: approved; reference typography accepted; detail revalidation in progress

## Why prior visual checks are being reopened

The first version of REPORT-011 required inspection at final size but did not
fix a physical reference width. Some workers therefore inspected native
10--20-inch canvases or 900/1024-pixel browser previews and called those final
size. Those checks can miss severe downscaling: for example, an 8-pt label on
an 18-inch canvas becomes about 3 pt when displayed at 170 mm. This does not
make a large export canvas intrinsically wrong. A larger canvas can be the
deliberate mechanism for obtaining an accepted plot-to-text ratio, provided
the actual HTML and print displays are both inspected.

Unless a narrower placement is specified, all reader-facing figures are now
checked at a 170-mm display width. An A4 portrait page with 20-mm side margins
may be used only as a QA simulation of that width; the final figure asset is
tightly cropped to its own bounds and is never saved on an A4 canvas. Essential
axis, label, legend, facet, and annotation text should normally be 5--7 pt
after scaling, while panel letters and central-result text are typically
7--9 pt. Minor non-essential text may be 3.5--5 pt but cannot carry information
needed to understand the main result.
Base design dimensions, literal export scale, exported dimensions, intended
display width, display reduction factor, smallest essential nominal text, and
effective final text are required evidence. `ggsave(scale = ...)` multiplies
the device dimensions; it does not authorize multiplying plot fonts, lines,
points, or keys. A prior PASS without these quantities is treated as NOT TESTED
under the clarified rule.

## Scope status

| Scope | Current status under clarified rule | Required action |
|---|---|---|
| Descriptive figures | Figure 1 typography approved; detail QA remains open | Retain the recorded 14-pt basis, 12-pt ticks, 14-pt titles/tags, 11-pt caption, and 3-unit map labels. Resolve remaining figure-specific details from stored display data. A4 evidence remains QA-only; other figures retain content-specific export scales. |
| Preparation 01, 02, and 05 | Not applicable: no empirical reader-facing figures | Retain table and diagram layout checks; apply the physical-size rule if an empirical figure is later added. |
| Preparation 03, 04, 06, and 07 | NOT TESTED | At the next authorized reporting touchpoint, re-export or redraw from stored display/source data only and verify at 170 mm (or the declared narrower width). Do not run preparation builders or scientific verifiers. |
| H01 | NOT TESTED under the clarified rule | Revalidate the closed result and preparation figures from stored outputs at the next authorized report touchpoint; do not refit or rerun bootstraps. |
| H02 | NOT TESTED under the clarified rule | Revalidate its nine reader-facing figures from stored outputs at the next authorized report touchpoint; do not refit or rerun resampling or Shapley calculations. |
| H05 | NOT TESTED under the clarified rule | Revalidate its ten reader-facing figures from stored outputs at the next authorized report touchpoint; do not refit or recompute diagnostics. |
| H11 | Revalidation required in the active reader-report work | Apply the clarified rule before the current reader-facing report can pass figure QA. |
| H03, H04, H06, H07, H08, H09, and H10 | Required before future Stage 3/4 acceptance | Use the clarified rule for every new reader-facing figure; record physical-size evidence in the hypothesis-specific QA manifest. Existing H06/H08 display work applies it at the next figure-producing step without restarting scientific computation. |

## Execution rule

Figure-only correction consumes stored figure source data, predictions, or
accepted outputs. It does not authorize data preparation, metric calculation,
model fitting, prediction, bootstrap, simulation, Shapley calculation, or a
changed scientific result. Closed reports are not restarted solely to update
typography; their QA is reopened and the correction is integrated at their
next authorized reporting touchpoint.
