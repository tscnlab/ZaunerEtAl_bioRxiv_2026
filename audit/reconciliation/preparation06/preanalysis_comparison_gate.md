# Preparation 06 pre-analysis comparison gate

Status: `PASS`

Date: 2026-07-30

## Purpose

This gate compares the dataset prepared for the manuscript with the verified
main-analysis Preparation 06 inputs before any H01-H11 model is fitted. It provides
descriptive reconciliation only. A shared field/key mapping does not establish
computational or estimand equivalence, and variables without a defensible
mapping retain an explicit not-applicable baseline.

## Pinned inputs

- Model-input normalization manifest:
  `e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab`
- Base-model manifest:
  `fd48dc5d1ecd5da125dd2c360c32239f0adfe7009eca881f5838b0e61b81b13d`
- Base-model input bundle:
  `b6262d925937f505514834ea9d5b733a6be76c00b1a8ec6855a9a10947bfb900`
- Metric display registry:
  `6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154`

## Verified scope

- 72 metrics and key prepared variables;
- all 22 registered light-metric rows in the display registry;
- 120 variable-placement comparisons;
- observation, participant, and participant-day support;
- mean, median, spread, quantiles, and empirical distribution distances for
  numerical variables;
- complete levels, counts, proportions, total-variation distance, and maximum
  level-proportion changes for categorical variables;
- key additions/removals and paired changes on common keys;
- exact figure-source CSVs for both diagnostic panels;
- no M10/L10 onset or offset fields;
- no participant identifiers, participant-level rows, raw timestamps, or free
  text in exported comparison artifacts.

## Verification

The R 4.6.1 producer and an independently implemented verifier both passed.
The regression suite verified deterministic byte-stable rebuilding, incorrect
input-hash rejection, output-manifest tamper rejection, artifact tamper
rejection, the model-ready endpoint firewall, explicit diary quarantine, and
aggregate-only exports. A separate read-only review reproduced the checks and
found no blocking or major issue.

The complete comparison was regenerated after the verified darkest-10-hour
roundoff repair and the resulting upstream fingerprint changes. The
independent verifier confirms the exact current values, source mappings,
sample counts and privacy rules:

- 15 manifest entries: 12 CSV, 2 PNG, and 1 Markdown report;
- comparison manifest SHA-256:
  `a6ed6cbb184383fb7b649ae9b67e8d5c44e24fffb3ff3fbb8af52fbb252e768c`;
- numerical diagnostic: 2520 x 3240 pixels;
- categorical diagnostic: 2520 x 3600 pixels.

The diagnostic PNGs are audit-only and are not submission figures. Their
180-dpi export is adequate for zoomable audit review but does not satisfy the
submission-figure resolution gate.

## Reopening condition

Reopen and rerun this gate after any change to a pinned input hash,
manuscript-prepared artifact, main-analysis metric or predictor, analytical metric registry,
transformation, estimand, comparison crosswalk, summary implementation, or
privacy/export rule.
