# Daily eligible-hours unit

Finding ID: `FIND-010`  
Status: `repair_verified`  
Date: 2026-07-30

## Finding

The Preparation 02 daily audit field `day_eligible_hours` was intended to
record a count from 0 to 24. The builder summarized `hour_eligible` after
joining the hourly flag onto the 1,440-row minute grid, so each eligible hour
was counted 60 times. Stored values such as 960, 1,440, and 1,320 therefore
represented 16, 24, and 22 eligible hours.

Every pre-repair value was divisible by 60. Summing the corrected values
reconciled exactly to the independently stored placement totals:

| Placement | Eligible hours |
|---|---:|
| Near-eye | 22,480 |
| Chest | 24,838 |

## Scientific effect

None. The field was a mislabeled audit summary. Hour eligibility, the daily
valid-minute numerator, the fixed 1,440-minute denominator, the daily
eligibility flag, eligible signal channels, and participant-day inclusion did
not depend on `day_eligible_hours`.

The corrected rebuild retains:

- 811 eligible near-eye participant-days from 141 participants; and
- 897 eligible chest participant-days from 154 participants.

## Repair and verification

The daily summary now counts distinct eligible clock-hour labels. Regression
tests assert exact 0–24 values at the 50% hourly and 80% daily boundaries.

The independent verifier reconstructs all hourly and daily coverage tables
from the Preparation 01 aligned artifacts without calling the Preparation 02
coverage helper. After the repair it reports:

- 10/10 generated artifacts present with matching bytewise SHA-256 and byte
  counts;
- 1,635,960/1,635,960 near-eye input/output true-UTC rows;
- 1,798,560/1,798,560 chest input/output true-UTC rows;
- 1,136 near-eye and 1,249 chest participant-days; and
- exact agreement for Rule A settings, coverage flags, eligible channels,
  sample flow, the 100,000-lx MEDI boundary, non-wear masking, and retained
  LIGHT values.

Evidence:

- `scripts/pipeline/aggregation_coverage.R`;
- `scripts/pipeline/verify_coverage_artifacts.R`;
- `tests/test_aggregation_coverage.R`;
- `tests/test_verify_coverage_artifacts.R`; and
- `artifacts/12_manifests/coverage_artifacts.csv`.
