# Paired near-eye and chest comparison in Stage 3 reports

Decision ID: `REPORT-009`
Date: 2026-08-01
Status: approved

## Decision

Every Stage 3 hypothesis report assesses whether its fitted results support a
direct paired/common-sample comparison of near-eye and chest estimates. When
the comparison is scientifically and statistically valid, include a display
modelled on the accepted H05 plot:

- near-eye estimate on the horizontal axis;
- chest estimate on the vertical axis;
- one point for each exactly matched estimand;
- a 45-degree identity line and clearly visible null reference lines;
- equal geometric scaling of the two axes when the scale permits it; and
- facets, colours, shapes, or direct labels that identify the corresponding
  predictor, contrast, metric group, or other scientifically relevant unit.

The figure uses estimates fitted separately to the same paired/common sample.
It is a placement-comparison display, not a pooling analysis and not evidence
of equivalence by itself.

## Conditions for a valid point comparison

A point enters the plot only when near-eye and chest results share:

- the same participants and participant-days or observations, as applicable;
- the same outcome definition and metric support rule;
- the same predictor, contrast, reference level, and model structure;
- the same response transformation, link, and estimate scale; and
- the same interpretation of the null value.

The report states the exact paired sample and comparison scale. It does not
mix all-available near-eye estimates with all-available chest estimates when
their samples differ, and it does not place heterogeneous outcome units in one
unqualified panel.

Component 95% confidence intervals are shown in the figure when they remain
legible. Otherwise they are reported in an adjacent paired table and the
figure subtitle or caption says so. Closeness to the identity line is described
as concordance or similarity, not equivalence, unless an equivalence margin and
test were fixed independently.

## When the H05-style scatterplot is not appropriate

Do not fit a new model solely to manufacture the display. If the approved
analysis did not produce common-sample estimates, the two placements estimate
different quantities, or the result is an entire temporal curve that cannot
be reduced to a justified scalar estimand, mark the scatterplot as not
applicable and explain why.

Use the closest valid placement comparison when it materially helps:

- paired overlay or difference curves with uncertainty for temporal models;
- matched marginal means or contrasts for categorical models;
- paired coefficient or effect plots when only a small number of estimands is
  available; or
- a concise paired table when a figure would be misleading or unreadable.

The alternative retains near-eye as primary and chest as complementary and
does not imply pooling.

## Accessibility and provenance

The figure has an informative caption and alt text that explain the axes,
identity line, null lines, paired sample, and principal pattern. It uses the
submitted-manuscript display conventions where relevant and remains legible in
greyscale through labels, shapes, or line types. Exact plotted values and
identifiers are retained in a paired source-data CSV.

## Reopening condition

Reopen if placement roles change, unmatched samples are permitted in the
identity plot, incomparable scales are combined, the display is interpreted as
equivalence without a declared margin, or a new fitted analysis is required
solely to create the figure.
