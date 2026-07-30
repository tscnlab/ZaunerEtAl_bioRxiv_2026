# Manuscript-prepared-data sensitivity

Date: 2026-07-30  
Status: approved by the author

## Purpose and name

Every H01--H11 analysis will include a
**manuscript-prepared-data sensitivity**. It applies the same newly approved
H01--H11 implementation used for the main analysis to the dataset that had
been prepared for the manuscript. Only objectively demonstrable data errors
are corrected in that dataset.

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

- **main analysis:** new data preparation and new H01--H11 implementation;
- **manuscript-prepared-data sensitivity:** manuscript-prepared data and the
  same new H01--H11 implementation; and
- **reported manuscript value:** the historical number or claim, used only for
  audit comparison.

## Data-fidelity rule

A correction may enter the manuscript-prepared dataset only when all of the
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

The sensitivity does not change the manuscript-prepared dataset's coverage,
gap, support, censoring, weighting, metric definition, placement, pooling, or
inclusion rules. Those differences are precisely what the comparison is
intended to test. If a possible data error has more than one scientifically
reasonable correction, it remains unchanged and is documented.

## Same analysis implementation in both scenarios

The main and sensitivity scenarios use the same:

- H01--H11 estimands, predictors, contrasts, transformations, model families,
  fixed and random effects, correlation structures, and diagnostics;
- multiplicity families and vector-wide adjustment;
- confidence-interval methods;
- placement roles; and
- result and sample-flow code.

Only the prepared dataset differs. If a model cannot be fitted to the
manuscript-prepared dataset, it is reported as non-estimable rather than
simplified only for that scenario.

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
