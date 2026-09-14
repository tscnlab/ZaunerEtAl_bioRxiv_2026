# Model-result reporting decisions

Date: 2026-07-30  
Status: approved by the author

## REPORT-003: Plain-language audit outputs

Preparation, hypothesis, placement, sensitivity, and manuscript-development
HTML pages must be understandable without knowing the pipeline's internal
object names.

Implementation:

- use familiar metric names and categories from the manuscript;
- use `melEDI` in reader-facing text and reserve `MEDI` for the actual R
  variable;
- explain a necessary technical term at first use;
- keep internal identifiers, file formats, join vocabulary, reason codes, and
  model-engine details in folded R code or a clearly labelled technical note;
- do not call the main analysis “canonical”; identify an alternative only when
  it differs from the main analysis; and
- retain exact numerical values, units, citations, identifiers, and
  cross-references while simplifying prose.

This decision changes how the audit is communicated. It does not authorize a
change to a scientific result or analysis rule.

## REPORT-004: Confidence intervals

Every fitted-model report must give a 95% confidence interval for each
consequential estimate, contrast, model-based average, transformed effect, and
model-performance summary for which an interval is estimable. A standard
error or \(p\)-value does not replace the interval.

The report states the interval method and the scale on which it was
calculated. Effects from a transformed or linked model are also reported in
practical reader-facing units when that transformation is valid. Failure to
obtain a planned interval is reported, with the reason, rather than silently
omitted.

## REPORT-005: Exact fitted-model sample

Every result table must describe the exact observations that entered that
fitted model. Counts from a prepared dataset do not satisfy this requirement.

The required fields are:

- **Participant-day models:** participants, participant-days (model rows), and
  sites, overall and by site, plus the valid measurement hours that
  contributed to the modelled metric where that quantity is defined.
- **Participant-level models:** participants (model rows), sites, and the
  participant-days and valid measurement hours that contributed to
  constructing each participant-level exposure metric.
- **Hourly models:** participants, participant-days, one-hour observations,
  and sites.
- **Thirty-minute models:** participants, participant-days, 30-minute
  observations, and sites.
- **Categorical and interaction models:** the relevant counts for each
  category and category × site combination, in addition to the totals above.
- **Paired placement models:** complete near-eye--chest pairs, paired
  participants, paired participant-days, and sites for each metric, overall
  and by site.
- **Sensitivity comparisons:** the sample for each model and the participants,
  participant-days or participant-level rows, time-resolved observations, and
  sites shared by the main and alternative models.

Metric-specific unavailable values and exclusions are reported by reason when
they are needed to reconcile the prepared sample with the fitted sample. The
result table or a directly linked sample-flow table must contain these counts;
they cannot be recoverable only from an R object.

Measurement hours used to derive a daily or participant-level outcome are
labelled as derivation support, not as independent model observations. A unit
that does not apply to a model is shown as not applicable rather than reported
as zero.

Reopen REPORT-004 or REPORT-005 if a target method does not permit the planned
interval or sample unit to be defined. Such a case is reported as
non-estimable and reviewed rather than bypassed.

## REPORT-008: P-value display

Every raw or multiplicity-adjusted p-value shown in prose, a table, a figure,
or an annotation uses a leading zero and three decimal places. Values strictly
smaller than 0.001 are shown as `<0.001`; 0.001 itself is shown as `0.001`.

The displayed value is bold only when it meets the significance rule explicitly
stated for that value or label. Raw and adjusted p-values are labelled
separately and are emphasized according to their own declared rules; rounding
never determines significance. Full numeric precision remains in the source
data and model artifacts. The complete convention and shared R helper are in
[`p_value_display_conventions.md`](p_value_display_conventions.md).

## REPORT-009: Paired placement comparison display

Every Stage 3 hypothesis report assesses whether the fitted common-sample
results permit a direct near-eye-versus-chest estimate plot. Where valid, use
near-eye on the horizontal axis, chest on the vertical axis, one point per
matched estimand, an identity line, null lines, and equal axis geometry. Report
the exact paired sample and component 95% confidence intervals in the figure or
an adjacent table.

The display uses separately fitted results on an identical paired/common
sample; it does not compare unmatched all-available samples, imply pooling, or
establish equivalence. If the estimands or scales are incompatible, or the
result is an unreduced temporal curve, explain why the scatterplot is not
applicable and use the closest valid placement comparison. The complete rule is
in
[`paired_placement_comparison_display.md`](paired_placement_comparison_display.md).

## REPORT-011: Figure readability and layout

Every reader-facing figure is designed and inspected at its actual rendered or
publication size. Unless a narrower placement is specified, use a 170-mm
full-width figure as the reference frame. An A4 page may simulate this width
for QA but is never the final figure canvas. Axis titles, tick labels, legends,
facet labels, direct labels, and important annotations are normally
approximately 5--7 pt at final size; panel letters and central-result text are
typically 7--9 pt. Minor
non-essential annotations may be approximately 3.5--5 pt when necessary.
Small text cannot carry information required to understand the central result.

The QA record states the base design width and height, literal export-scale
multiplier, exported width and height, intended display width, display
reduction factor, smallest essential nominal text, and effective final text
size. The `ggsave()` scale argument enlarges the graphics device; it must not
be emulated by multiplying theme fonts or graphical marks. A native-resolution
or browser-pixel inspection without final-display evidence is `NOT TESTED`,
not a pass. A direct 170-mm export is not required when a larger design canvas
deliberately produces the accepted plot-to-text balance.

Canvas dimensions, aspect ratio, panel layout, text size, and line wrapping
are adjusted together so labels do not consume the data region. Text is never
stretched or condensed. After every size or layout adjustment, visually check
for clipping, overlap, distorted text, undesirable line breaks, excessively
long unwrapped labels, disproportionate plot areas, and marks that become
indistinguishable after scaling. The complete mandatory QA checklist and
no-recomputation boundary are in
[`figure_readability_and_layout.md`](figure_readability_and_layout.md).

## REPORT-013: Symlog display for zero-containing right-skewed values

Reader-facing plots of non-negative, strongly right-skewed values that include
meaningful exact zeros use
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`. This is the default
for melEDI visualizations containing zero. Axis labels and breaks remain in the
original unit, and paired figure-source data retain the untransformed values.

This display rule does not change a model response, scientific estimand, or
analysis transformation. It does not apply mechanically to clock time,
duration, dose, timing, signed contrasts, ratios, probabilities, or variables
whose distribution remains suitable for a linear or other purpose-specific
scale. The complete scope, labelling, and no-recomputation rules are in
[`reader_facing_symlog_scale.md`](reader_facing_symlog_scale.md).

## REPORT-012: Answer in brief

Every standalone reader-facing hypothesis report places a compact Quarto note
callout titled **Answer in brief** directly after the hypothesis and
analytical-question section. In two to four sentences, it states the verified
primary near-eye conclusion, a consequential magnitude and 95% confidence
interval where one compact estimate is scientifically valid, whether
complementary chest evidence agrees materially, and whether a central
sensitivity changes the conclusion.

The callout uses only results already sourced in the detailed report. It
retains multiplicity and uncertainty qualifications, does not translate an
inconclusive result into evidence of no effect, and does not mention V0,
workflow stages, internal artifacts, or construction history. The complete
content and no-recomputation rule are in
[`answer_in_brief_callout.md`](answer_in_brief_callout.md).

## REPORT-006 and REPORT-010: Gap-timing-unaware dataset sensitivity

Every H01--H11 report applies the same new analysis implementation to two
datasets: the newly prepared data for the main analysis and the data prepared
for the manuscript, with only objectively demonstrable data errors corrected.
The latter is called the **gap-timing-unaware dataset** in every reader-facing
Stage 3 and Stage 4 output. Its complete definition and fidelity rule are in
[`manuscript_prepared_data_sensitivity.md`](manuscript_prepared_data_sensitivity.md).

At first use, explain that the gap-timing-unaware dataset still passed the
general 50%-per-hour and 80%-per-day coverage rules, but the timing of the
remaining missing observations is not used for an additional metric-specific
adjustment. For contrast at that first explanation only, the primary dataset
may be described as something that could be interpreted as a time-sensitive
primary metric dataset. Call it simply **the primary dataset** thereafter. The
full naming rule is in
[`gap_timing_unaware_dataset_terminology.md`](gap_timing_unaware_dataset_terminology.md).

The exact fitted-model sample and 95% confidence-interval requirements in
REPORT-004 and REPORT-005 apply equally to both datasets. The comparison
therefore isolates changes caused by data preparation and metric calculation;
it does not rerun the manuscript's modelling implementation. Differences
between the full manuscript-generating chain and the main analysis remain part
of the audit discussion rather than this sensitivity.
