# Participant-days with only zero melEDI values

Finding ID: `FIND-037`
Decision ID: `COVERAGE-002`
Related deviation: `DEV-057`
Status: approved and verified in Preparation 02
Decision date: 2026-07-31

## What was found

Five participant-days passed the 80% coverage rule even though every finite
one-minute melEDI value was exactly 0 lx:

| Site | Participant | Date | Placement | Finite melEDI minutes | Zero melEDI minutes |
|---|---|---|---|---:|---:|
| IZTECH | IZTECH_S009 | 2025-03-18 | Near-eye | 1,440 | 1,440 |
| IZTECH | IZTECH_S009 | 2025-03-19 | Near-eye | 1,440 | 1,440 |
| IZTECH | IZTECH_S009 | 2025-03-18 | Chest | 1,440 | 1,440 |
| IZTECH | IZTECH_S009 | 2025-03-19 | Chest | 1,440 | 1,440 |
| THUAS | THUAS_S002 | 2025-03-09 | Chest | 1,440 | 1,440 |

The two IZTECH days also contained only zero illuminance values. On the THUAS
chest day, melEDI was zero throughout while illuminance contained 51 small
positive values with a maximum of 0.19 lx. Neighboring eligible days for the
same participants and placements contained positive light values. A complete
flat-zero day is therefore treated as an implausible or inactive light record,
not as evidence of a genuinely dark personal environment for 24 hours.

## Approved rule

The primary analysis excludes a participant-day when both conditions hold:

1. the day would otherwise pass the primary 80% full-cycle coverage rule; and
2. every finite one-minute melEDI value is exactly 0 lx.

Individual zero readings remain valid. The rule does not discard a day merely
because it contains many zeros, a dark sleep period, or a missing interval.
It applies only to an otherwise eligible day-long flat-zero melEDI signal.

The original rows, raw values, coverage fractions, and classification flags
remain in the Preparation 02 RDS files. The analysis channels are set to
missing for excluded days with reason `all_zero_medi_day`. A separate
all-zero-inclusive eligibility flag retains the former treatment as a fixed
data sensitivity.

## Verified sample effect

| Placement | Eligible before this screen | Eligible after this screen | Excluded | Eligible participants after |
|---|---:|---:|---:|---:|
| Near-eye | 818 | 816 | 2 | 141 |
| Chest | 905 | 902 | 3 | 154 |

The paired eligible set changes from 646 to 643 participant-days and retains
112 participants. No participant is removed entirely from either placement.

These figures describe only the Preparation 02 inclusion effect. Changes to
metric values, metric-specific availability, model samples, estimates, and
claims must be established by the downstream rebuild and hypothesis-specific
result comparisons.

## Implementation and verification

- Rule implementation:
  `scripts/pipeline/aggregation_coverage.R`
- Reason-coded analysis channels and sample flow:
  `scripts/pipeline/build_coverage_sample_flow.R`
- Independent reconstruction:
  `scripts/pipeline/verify_coverage_artifacts.R`
- Fixed Rule A/B/C comparison:
  `scripts/pipeline/daily_coverage_rule_diagnostic.R`
- Synthetic regression tests:
  `tests/test_aggregation_coverage.R`,
  `tests/test_build_coverage_sample_flow.R`, and
  `tests/test_daily_coverage_rule_diagnostic.R`

Under R 4.6.1, the independent Preparation 02 verifier returned `PASS`,
reconstructed 816 near-eye and 902 chest eligible participant-days, identified
exactly two and three all-zero exclusions, and reconciled all input and output
rows. The all-zero screen is also applied consistently to the fixed 70% and
90% daily-coverage sensitivities and to the two sleep-excluded rules; it is not
a scenario-specific choice.

## Reopening conditions

Reopen the decision if device or source documentation establishes that a
complete day-long zero melEDI series can be a valid active recording, if the
definition is broadened beyond exact zeros, if the screen is applied after
model inspection, or if the fixed all-zero-inclusive sensitivity materially
changes an estimate or conclusion.
