# Daily 80% coverage-denominator decision

Decision ID: `COVERAGE-001`  
Related deviation: `DEV-055`  
Status: approved  
Decision date: 2026-07-30  
Scope: primary participant-day eligibility and registered sensitivity rules  
Implementation boundary: the canonical Rule A analysis remains unchanged;
Rules B and C enter the sensitivity battery

## Decision

Retain Rule A as the primary daily eligibility rule: an eligible participant-
day has finite MEDI in eligible hours for at least 80% of a fixed
1,440-wall-minute day after the inclusive 50% hourly gate.

This denominator answers the intended coverage question: is more than 80% of
the complete 24-hour cycle observed? The study's full-cycle measurement
construct intentionally combines worn near-eye measurements during wake with
bedside measurements during diary-defined sleep. Bedside values characterize
the sleep environment rather than ocular exposure, and all whole-day metrics
and claims must say so.

Use the following two fixed alternatives as sensitivity scenarios:

1. Rule B, the literal daily sleep-excluded alternative: retain Rule A's
   all-minute hourly gate, but divide finite non-sleep MEDI in eligible hours
   by expected non-sleep minutes.
2. Rule C, the wake-aware alternative: divide finite non-sleep MEDI by expected
   non-sleep minutes at both the hourly and daily gates.

All 0.50 and 0.80 thresholds remain inclusive. Only explicit diary state
`sleep` is excluded in Rules B and C; missing or unknown state remains expected
support. No threshold, state rule, or denominator may be retuned after
hypothesis results are inspected.

## Preregistration interpretation

The signed preregistration says that sleep is excluded from the daily
valid-wear denominator. Rule A therefore is not literal adherence to that
wording. It is an approved, explicit preregistration deviation reflecting the
intended hybrid 24-hour coverage construct. This record does not imply that
sleep should have been excluded from the primary construct or that Rule B is
scientifically preferable; Rules B and C quantify how the literal
sleep-excluded interpretations affect results.

The decision was taken after the rule-comparison inclusion counts were known
but before rebuilt hypothesis results were inspected. Its basis is the
measurement construct and fixed support definitions, not inferential
preference.

## Verified inclusion consequences

| Placement | Rule A | Rule B | Rule C |
|---|---:|---:|---:|
| Near-eye participant-days | 811 | 758 | 757 |
| Chest participant-days | 897 | 838 | 837 |
| Near-eye participants | 141 | 141 | 141 |
| Chest participants | 154 | 154 | 154 |

Relative to Rule A, Rule B changes the net eligible-day count by -53 near-eye
and -59 chest; Rule C changes it by -54 and -60. No scenario removes an
eligible participant entirely. Full transition and site-level counts are
recorded in
[`../findings/daily_coverage_denominator.md`](../findings/daily_coverage_denominator.md).

## Sensitivity and reopening contract

The sensitivity battery must:

- report participant, participant-day, and analysis-observation flow for every
  rule by site and placement;
- compare Rule A with Rules B and C on both scenario-specific and exact common
  samples;
- preserve the same downstream metric and model specifications within each
  comparison; and
- classify estimate and conclusion stability without selecting a rule from
  its p-values.

Reopen the affected hypothesis if either sensitivity produces a qualitative
conclusion change, a materially different estimate or uncertainty interval,
or an unexpected site- or placement-specific inclusion pattern. Reopen
`COVERAGE-001` itself only if the intended hybrid-day construct, diary-sleep
authority, hourly gate, or daily support definition changes.
