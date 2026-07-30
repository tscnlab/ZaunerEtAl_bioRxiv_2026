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

## REPORT-006: Manuscript-prepared-data sensitivity

Every H01--H11 report applies the same new analysis implementation to two
datasets: the newly prepared data for the main analysis and the data prepared
for the manuscript, with only objectively demonstrable data errors corrected.
The latter is called the **manuscript-prepared-data sensitivity**. Its complete
definition and fidelity rule are in
[`manuscript_prepared_data_sensitivity.md`](manuscript_prepared_data_sensitivity.md).

The exact fitted-model sample and 95% confidence-interval requirements in
REPORT-004 and REPORT-005 apply equally to both datasets. The comparison
therefore isolates changes caused by data preparation and metric calculation;
it does not rerun the manuscript's modelling implementation. Differences
between the full manuscript-generating chain and the main analysis remain part
of the audit discussion rather than this sensitivity.
