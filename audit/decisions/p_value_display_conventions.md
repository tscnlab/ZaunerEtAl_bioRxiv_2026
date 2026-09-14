# P-value display conventions

Decision ID: `REPORT-008`
Date: 2026-08-01
Status: approved

## Decision

Every displayed p-value in a report, table, figure, caption, annotation, or
reader-facing sentence follows one convention, whether the value is raw or
adjusted for multiple testing:

- show a leading zero and exactly three decimal places;
- show values strictly smaller than 0.001 as `<0.001`;
- show 0.001 itself as `0.001`; and
- use bold type when the displayed value meets the significance rule stated
  for that value, column, panel, or annotation.

Examples are `0.247`, **`0.032`**, and **`<0.001`** when the latter two meet
their explicitly stated significance criterion.

## Raw and adjusted values

The label must identify what is displayed. Use `Raw p` for an unadjusted
value and a specific label such as `BH-adjusted p`, `FDR-adjusted p`, or
`Within-metric adjusted p` for an adjusted value. The caption, column
spanner, footnote, or nearby prose states the applicable alpha level and the
multiple-testing family where relevant.

Bold emphasis follows the rule attached to the displayed value:

- a raw p-value is bold only when the explicitly stated raw-p rule is met;
- an adjusted p-value is bold only when its explicitly stated adjusted-p rule
  is met; and
- a p-value with no inferential decision rule attached is not bold merely
  because it is numerically below 0.05.

Do not bold a raw p-value because its adjusted counterpart is significant, or
an adjusted p-value because the raw value is significant. When the scientific
decision is based on FDR adjustment, the adjusted value is the primary
emphasized result; a raw value may remain unbolded unless the display also
declares a separate raw-p rule.

## Implementation

Formatting changes only the displayed string and typeface. Source-data CSVs,
model objects, result ledgers, and calculation artifacts retain the full
numeric precision.

The shared R helper is `scripts/pipeline/p_value_display.R`. It returns the
three-decimal display label and keeps the supplied significance decision in a
separate logical field. Tables use that field for bold cell styling; figure
annotations use it for font weight. This separation prevents rounded display
values from being used to decide significance.

`NA` or non-estimable values use the report's declared missing-value label and
are never bold. Invalid values outside the closed interval from 0 to 1 fail
validation rather than being formatted.

## Reopening condition

Reopen if the number of displayed decimals, the strict `<0.001` boundary, the
leading-zero convention, or the link between bold emphasis and the explicitly
labelled significance rule changes.
