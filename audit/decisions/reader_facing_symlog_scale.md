# Reader-facing symlog scale

Decision ID: `REPORT-013`

Date: 2026-08-03

Status: approved

## Rule

Reader-facing visualizations of non-negative, strongly right-skewed values
that include meaningful exact zeros use the following LightLogR transformation:

```r
LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)
```

This is the default display scale for melEDI values when the plotted data
include zero. It also applies to another variable only when its observed scale
has the same combination of a genuine zero mass and an approximately
log-normal-like positive part.

The transformation is applied through the relevant ggplot scale, for example:

```r
ggplot2::scale_y_continuous(
  trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)
)
```

Source-data CSV files retain the untransformed scientific values. A plot may
store transformed drawing coordinates in an additional column when required
by a specialised geom, but the original value column remains present and the
transformation is documented.

## Interpretation and labelling

The threshold fixes a linear region around zero and a base-10 logarithmic-like
region above it. This preserves exact zero and avoids adding an arbitrary
constant before taking a logarithm. Reader-facing axes retain labels in the
original unit, such as `melEDI (lx)`.

Breaks are selected from interpretable original-scale values and include zero
and 1 whenever they fall within the displayed range. For melEDI, useful
candidates include 0, 1, 10, 250, 1,000, 10,000, and 100,000 lx; use only the
subset that supports the plotted range and does not overcrowd the axis. A
caption or nearby method statement identifies the scale at first use when a
reader could otherwise interpret equal visual distances as equal linear
differences.

## Boundaries

This is a visualization rule, not an automatic model-response transformation
or a change to a scientific estimand. Do not apply it mechanically to:

- clock time, duration, dose, timing, signed contrast, ratio, probability, or
  another quantity that remains interpretable on a linear or purpose-specific
  scale;
- a variable without meaningful exact zeros;
- a display whose scientific question requires a different scale; or
- model fitting, inference, or diagnostics unless that transformation is
  separately specified and approved in the hypothesis analysis.

For distributions with a large discrete zero mass, a report may additionally
show or state the zero proportion separately so the positive distribution
remains visible. That separate display does not mean zero observations were
excluded from the model.

## Adoption and verification

New figures apply this rule immediately. Existing preparation, descriptive,
hypothesis, sensitivity, and manuscript figures adopt it at their next
authorized figure-producing or reporting touchpoint from stored source data or
stored model outputs. Adoption does not authorize a data rebuild, model refit,
prediction run, bootstrap, simulation, Shapley calculation, or other scientific
recomputation.

Verification checks the exact `base = 10`, `thr = 1`, and `scale = 1`
arguments, original-unit labels and breaks, paired untransformed source data,
caption/alt-text accuracy, and the ordinary `REPORT-011` final-size visual QA.

## Adoption audit at approval

The current descriptive helpers, descriptive table thumbnails, prepared-day
showcase, and Preparation 07 example-day source now use the explicit approved
arguments. The source scan identified remaining hypothesis-owned display calls
in H02, H06, and H11. They are migration targets rather than evidence of a
scientific error:

- H02 is closed and adopts the explicit arguments at its next authorized
  figure touchpoint without refitting or recomputing stored results.
- H06 is paused after Stage 2 and integrates the rule with the next approved
  display execution rather than being restarted solely for a scale change.
- H11 is active and was notified to integrate the rule with its next planned
  display execution without rerunning scientific computation solely for this
  change.

Future H03--H10 tasks consume this central rule from the shared workflow. Idle,
closed, or not-yet-loaded tasks are not awakened solely to change a display
scale.

## Reopening condition

Reopen if LightLogR changes the transformation contract, a variable requires a
scientifically different threshold, or the journal requires a scale that
cannot preserve both meaningful zeros and the positive distribution.
