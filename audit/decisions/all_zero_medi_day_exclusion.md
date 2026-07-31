# All-zero melEDI participant-day exclusion

Decision ID: `COVERAGE-002`
Related finding: `FIND-037`
Related deviation: `DEV-057`
Status: approved
Decision date: 2026-07-31
Scope: participant-day plausibility screen applied after the coverage cutoff

## Decision

Exclude an otherwise eligible participant-day from the primary analysis when
every finite one-minute melEDI value is exactly 0 lx.

This is a narrow day-level plausibility screen. Individual zero values remain
valid, and neither a dark sleep period nor a partly missing day is sufficient
for exclusion. The rule is applied only after the day has passed its declared
coverage cutoff.

Preserve the original rows and values, record
`day_all_finite_medi_zero`, `day_eligible_without_all_zero_screen`, and
`day_all_zero_medi_excluded`, and set the analysis-ready light channels to
missing with reason `all_zero_medi_day`. Retain
`all_zero_medi_inclusive_sensitivity_period_eligible` so the same analyses can
be rerun with these days included.

## Rationale

The five identified days contained 1,440 finite melEDI minutes and 1,440 exact
zeros. Four placement-days also had zero illuminance throughout; the fifth had
only very small illuminance values. Neighboring eligible days contained
positive exposure. Interpreting these records as valid 24-hour personal
exposure would give an inactive or failed signal the same status as a
plausible observed day.

The exact-zero rule is reproducible and outcome-independent. It avoids a
subjective near-zero cutoff and does not remove ordinary zero observations
that are required for low-light metrics and zero-aware response models.

## Consequences

The primary sample changes from 818 to 816 near-eye participant-days and from
905 to 902 chest participant-days. The paired set changes from 646 to 643
days. Eligible participant counts remain 141 near-eye, 154 chest, and 112 in
the paired set.

The same screen is applied to every fixed coverage-cutoff and sleep-denominator
scenario. The all-zero-inclusive version is retained as an explicit data
sensitivity, not as an alternative primary definition selected from results.

## Reopening contract

Reopen if:

- a complete flat-zero series is shown to be a valid active recording;
- the rule changes from exact zero to a near-zero threshold;
- a scenario applies the screen differently from the primary analysis; or
- inclusion of the five days materially changes a hypothesis estimate,
  uncertainty interval, or conclusion.
