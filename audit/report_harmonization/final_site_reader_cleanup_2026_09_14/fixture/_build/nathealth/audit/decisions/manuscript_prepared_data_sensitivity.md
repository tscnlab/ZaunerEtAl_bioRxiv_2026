# Gap-timing-unaware dataset sensitivity

Date: 2026-07-30  
Status: approved by the author

## Purpose and reader-facing name

Every H01--H11 analysis will include a
**gap-timing-unaware dataset sensitivity**. It applies the same newly approved
H01--H11 implementation used for the main analysis to the dataset that had
been prepared for the manuscript. Only objectively demonstrable data errors
are corrected in that dataset.

The approved reader-facing term is **gap-timing-unaware dataset**. At first
use, reports explain that this dataset still passed the general 50%-per-hour
and 80%-per-day coverage rules, but the timing of the remaining missing
observations is not used for an additional metric-specific adjustment. For
contrast at that first use only, the primary dataset may be described as
something that could be interpreted as a time-sensitive primary metric
dataset. It is called simply **the primary dataset** thereafter. The complete
terminology rule is in
[`gap_timing_unaware_dataset_terminology.md`](gap_timing_unaware_dataset_terminology.md).

This sensitivity isolates the effect of the new data-preparation and metric
rules. It does not rerun the manuscript's modelling implementation and does
not preserve its code errors, model choices, or reporting limitations.
Comparison with the full manuscript-generating analysis chain remains part of
the audit discussion only.

In other words, this is a **data sensitivity**, not a sensitivity analysis of
the complete analysis chain. The two formal scenarios differ in prepared
data, while their H01--H11 model code is identical.

These names avoid calling an analysis legacy, previous, current, source, or
canonical:

- **primary dataset:** new data preparation and new H01--H11 implementation;
- **gap-timing-unaware dataset:** the predefined comparison data and the
  same new H01--H11 implementation; and
- **reported manuscript value:** the historical number or claim, used only for
  audit comparison.

## Data-fidelity rule

A correction may enter the gap-timing-unaware dataset only when all of the
following are true:

- authoritative evidence identifies one intended data value or record;
- no scientifically reasonable alternative remains;
- the decision does not depend on inspecting a hypothesis result;
- the smallest local correction is used; and
- the correction has an identifier and evidence locator.

Allowed corrections include:

- the verified upstream TUM exercise-diary participant correction;
- an unmistakable identifier, unit, label, or serialization error that can be
  corrected without changing the intended data-preparation method; and
- a compatibility repair needed to read the frozen dataset without changing
  its scientific contents.

The sensitivity does not change the gap-timing-unaware dataset's general
50%-per-hour and 80%-per-day preparation, remaining-gap timing, placement,
pooling, or general inclusion rules. Those differences are precisely what the
comparison is intended to test. The approved H01--H11 metric estimand is,
however, shared across scenarios. Consequently, `METRIC-010` MDER is
recalculated from each scenario's pinned one-minute inputs as the arithmetic
mean of viable positive finite momentary ratios with the same inclusive
720-of-1,440-minute requirement. Copying a frozen daily MDER while relabelling
it as that construct is not an admissible sensitivity difference. If a
possible data error has more than one scientifically reasonable correction,
it remains unchanged and is documented.

## Same analysis implementation in both scenarios

The main and sensitivity scenarios use the same:

- H01--H11 estimands, predictors, contrasts, transformations, model families,
  fixed and random effects, correlation structures, and diagnostics;
- multiplicity families and vector-wide adjustment;
- confidence-interval methods;
- placement roles; and
- result and sample-flow code.

Only the prepared dataset differs. If a model cannot be fitted to the
gap-timing-unaware dataset, it is reported as non-estimable rather than
simplified only for that scenario.

The current verified gap-timing-unaware MDER contains 687 estimable near-eye
participant-days and 723 estimable chest participant-days. Exact derivation,
support, non-MDER invariance, and input/output hashes are recorded under
`audit/reconciliation/mder_METRIC-010_gap_repair/`.

## Required comparison

For every result, the sensitivity report includes:

- the exact participants, participant-days, participant-level rows,
  30-minute observations, other observations, and sites used by each model;
- exact derivation-support hours when retained by the prepared artifacts, or
  an explicit unavailable value when they cannot be reconstructed;
- relevant category, category-by-site, and paired counts;
- exact common-sample counts;
- estimates and 95% confidence intervals;
- raw and adjusted \(p\)-values, adjustment method, family identifier, family
  size, and family rank;
- direction, statistical conclusion, fit, and diagnostic status;
- main-minus-sensitivity differences and a stability classification; and
- the data producer, input fingerprints, correction identifiers, and model
  implementation identifier.

The analysis is classified as stable, quantitatively sensitive,
qualitatively sensitive, inconclusive, invalid, or non-estimable using the
same rules as the other predefined sensitivities.
