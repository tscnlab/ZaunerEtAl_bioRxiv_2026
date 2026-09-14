# Darkest 10-hour mean numerical roundoff

Finding ID: `FIND-033`  
Status: repaired and independently verified  
Date: 2026-07-30  
Severity: low numerical error; high importance for model-domain checks

> **2026-08-12 extension.** `METRIC-011` and `FIND-050` extend this
> negative-domain repair to positive machine-roundoff residuals only when all
> finite source values are exactly zero. The manifest identities below remain
> historical identities for this original repair; current identities are
> recorded in `audit/decisions/l10_numerical_zero_normalization.md`.

## Finding

The zero-aware geometric mean is calculated on
`log10(melEDI + 0.1)` and transformed back by subtracting 0.1 lx. Floating
point roundoff produced four values just below zero: three near-eye
participant-days and one chest participant-day, with a minimum of
approximately \(-5.55 \times 10^{-17}\) lx.

Negative light exposure is impossible. These values represented numerical
zero, not observed negative exposure. Leaving them unchanged would also cause
otherwise appropriate non-negative response-family checks to reject the data.

## Repair

`restore_nonnegative_geometric_mean()` now:

- calculates the back-transformed value;
- defines a tolerance from machine precision and the transformed scale;
- converts a negative value within that tolerance to exact zero; and
- stops if a materially negative value is produced.

The repair is applied at the shared rolling-window producer, before M10/L10
artifacts are written. It does not recode stored output downstream.

## Verification

R 4.6.1 tests verify an exact zero, a negative value within floating-point
tolerance, and rejection of a materially negative result. The complete metric
derivation was regenerated for both placements. Independent verification then
confirmed:

- 811/811 finite near-eye L10 means, minimum 0, no negative values and
  111 exact zeros;
- 897/897 finite chest L10 means, minimum 0, no negative values and
  126 exact zeros;
- all 29 metric artifacts and 96 independently reconstructed
  participant-days passed;
- the independent MDER and full support-aware metric tests passed; and
- the final H01 input contains no negative metric value.

Current relevant manifest fingerprints are:

- metric artifacts:
  `944f395e00735e6f8200798d4cde387454441d39b9defda68f583bd8778cd34b`;
- base model data:
  `fd48dc5d1ecd5da125dd2c360c32239f0adfe7009eca881f5838b0e61b81b13d`;
- H01 model data:
  `b06f2f3614a4db7b7d5822de8985413a9b0927ff319260b311c4a22150a15f53`.

## Result effect

Four numerical representations changed from a machine-roundoff negative to
exact zero. Participant, participant-day, metric-admissibility and model
sample counts did not change. No H01 model had been fitted before the repair.

## Reopening condition

Reopen if the zero offset, logarithm base, rolling-window calculation,
floating-point tolerance or non-negative outcome contract changes, or if a
materially negative exposure value is observed.
