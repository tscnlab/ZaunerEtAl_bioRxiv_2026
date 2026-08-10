# H09 Stage 3 gate and Stage 4 transition

Date: 2026-08-10

Decision ID: **H09-003**

Status: **Stage 3 approved with a wording amendment; Stage 4 authorized**

## Author decision

The author accepted the standalone H09 reader report and requested one brief
clarification: the terms `mctq_hour_centered` and `meq_10_centered` must be
explained.

The approved clarification states that:

- `mctq_hour_centered` is MCTQ MSFsc expressed in clock hours minus the
  participant mean of 4.114 h, so one unit is one hour later corrected
  midsleep;
- `meq_10_centered` is the MEQ score minus the participant mean of 52.860 and
  divided by 10, so one unit is 10 MEQ points toward greater morning
  preference; and
- centering changes the model intercept's reference point but not the
  chronotype slopes, their 95% confidence intervals, or their tests.

No scientific result, model specification, sample, multiplicity decision,
diagnostic assessment, sensitivity result, figure, or source-data value is
changed by this wording amendment.

## Transition

H09-003 authorizes the reader-facing analysis-preparation and provenance
companion at
`audit/hypotheses/H09/H09_analysis_preparation.qmd`. The companion may perform
only bounded identity, schema, key, and lightweight descriptive checks from
frozen H09 artifacts. It must not fit, refit, predict, simulate, bootstrap,
resample, or recompute a scientific result.
