# H06 daily MDER upstream hold

- Date opened: 2026-08-11
- Status: **released on 2026-08-11 for the replacement METRIC-010 contract**
- Scope: MDER only; MDER-independent H06_daily work may continue through its
  existing approval gates

## Prohibited use of current artifacts

The author reopened the upstream MDER definition. H06_daily must not fit,
summarize, interpret, report, or finalize an MDER outcome from the current
`mder_ratio_of_integrals` artifacts. Earlier Stage 1 MDER registry entries,
candidate-sample counts, family suggestions, and the dormant metric mapping
are historical planning material only and are not an approved analysis
contract.

The completed Stage 2 bounded pilot is independent of MDER: its four daily
pilot metrics and its exploratory 30-minute time-of-day models contain no MDER
fit or estimate. Those frozen pilot artifacts remain valid for their stated
engineering purposes.

## Replacement definition communicated by the coordinator

The replacement day-level MDER is to be computed upstream as the arithmetic
mean of viable one-minute melEDI/illuminance ratios, with all of the following
conditions:

1. melEDI and illuminance must both be positive and finite for a one-minute
   pair to yield a viable ratio;
2. pairs with either channel equal to zero or non-finite are excluded; and
3. at least 50% of the expected day minutes must yield viable ratios for the
   participant-day metric to be admissible.

H06_daily will not implement, reconstruct, or independently validate this
replacement in local code. Shared preparation and normalization remain under
coordinator ownership.

## Conditions for releasing the hold

MDER-specific work may resume only after both are supplied:

1. a new shared metric/model-data manifest identifying the replacement field,
   units, exact one-minute viability and day-support rules, source artifact
   identities/hashes, placement support, and admissible participant-days; and
2. targeted coordinator instructions identifying which H06_daily input,
   metric-registry, and model-data pins must be replaced.

After repinning, H06_daily must re-audit MDER naming, units, bounds, missingness,
placement samples, family/link choice, diagnostics, and its metric-specific
Benjamini–Hochberg slot before any MDER fit. No count, family, estimate, or
conclusion may be transferred from the ratio-of-integrals version.

## Release record

The coordinator subsequently supplied the controlling replacement decision,
the current metric and base-model manifests, the independent MDER audit
manifest, the base input-bundle identity, and targeted H06_daily repinning
instructions. The task-local transition is recorded in
`audit/hypotheses/H06_daily/H06_daily_mder_metric010_transition.md`.

This file remains as the historical stop record. It no longer blocks the
replacement MDER-specific analysis, but it continues to prohibit use of any
superseded ratio-of-integrals estimate or conclusion.

The coordinator later supplied the fully corrected gap branch under the same
momentary-ratio rule. H06_daily verified and consumed those current pins only
in the bounded MDER refresh. The former THUAS chest zero is missing under the
no-viable-ratio rule, all retained corrected gap values are strictly positive,
and the revised comparator stopped at H06-D-G2-MDER-GAP for author review. The
author approved that corrected gap gate on 2026-08-11; the replacement MDER
branch is now closed and frozen.
