# Timestamp and DST fall-back finding

Finding ID: `FIND-001`  
Deviation ID: `IMP-017`  
Status: repair approved; analytical rerun pending  
Date: 2026-07-30

## Confirmed mechanism

`melidosData::flatten_data()` applies `lubridate::force_tz(..., "UTC")` to
every POSIXct column before binding sites. `force_tz()` preserves the displayed
clock label and changes the represented instant. It is therefore not a
conversion of each site-local instant to UTC.

On daylight-saving fall-back days, the two distinct occurrences of the
repeated local hour consequently receive identical participant/timestamp
keys. The current analytical artifacts retain those duplicate keys.

## R-verified scope in the saved artifacts

| Artifact | Placement | Duplicate excess | Duplicate keys | Keys with conflicting MEDI or LIGHT |
|---|---:|---:|---:|---:|
| `preprocessed_glasses_1.RData` | near-eye | 240 | 240 | 177 |
| `preprocessed_chest_1.RData` | chest | 120 | 120 | 56 |
| `preprocessed_glasses_2.RData` | near-eye | 240 | 240 | 177 |
| `preprocessed_chest_2.RData` | chest | 120 | 120 | 56 |

Affected near-eye streams are FUSPCEU_S007 and FUSPCEU_S008 on
2024-10-27, and MPI_S221 and MPI_S222 on 2023-10-29. The affected chest
streams are FUSPCEU_S007 and FUSPCEU_S008 on 2024-10-27. Each stream has 60
duplicated local minute keys.

The finding was reproduced in R 4.6.1 from the saved stage-1 and stage-2
objects. It is not inferred from printed time-zone labels alone.

## Approved repair

1. Keep each site's original POSIXct timestamps until the site-specific time
   zone is verified.
2. Create `datetime_utc` with `lubridate::with_tz()`, which preserves the
   instant.
3. Create `datetime_wall` with `lubridate::force_tz(..., "UTC")` solely as a
   common cross-site local-clock coordinate. It must never be described or
   used as true UTC.
4. Preserve separate `timezone`, `utc_offset`, `local_date`,
   `clock_minute`, and DST-transition fields.
5. Key observation streams by site, participant, placement, and
   `datetime_utc`; repeated local-clock labels remain legitimate distinct
   observations.
6. For cross-site clock cutoffs, fixed profiles, and clock-aligned models,
   average repeated fall-back observations into one `datetime_wall` minute and
   record the number of source intervals, distinct instants, offsets, and a
   DST-fold flag.
7. Never collapse repeated real intervals for dose, threshold duration,
   bouts, adjacency, or other elapsed-time and sequential metrics. Those use
   `datetime_utc` and actual interval durations.
8. Rerun and compare every metric, model, table, figure, and claim that
   contains an affected participant-day.

The author approved this dual-axis repair on 2026-07-30. The approval preserves
the intended common local-clock representation while preventing it from
corrupting elapsed-time calculations.

## Reference-profile state-boundary case

The rebuilt near-eye coverage artifact contains one concrete fall-back case
that crosses a diary-state boundary: MPI_S222 on 2023-10-29. Its 60 repeated
wall-clock keys run from 02:00 through 02:59. For 33 keys (02:27–02:59), the
first true occurrence is labelled `pre-sleep` and the second is labelled
`sleep`. Across the repeated hour, the first occurrence has no eligible MEDI
or LIGHT value and the second occurrence has 60 finite zero-valued minutes.

Preparation 03 therefore uses two explicit planes:

- the full-day clock plane collapses each repeated wall key once, averaging
  the finite values while recording its source-row and finite-row counts; and
- each state-specific plane filters the true-UTC rows to its diary state
  before collapsing wall keys, so both true occurrences remain in their
  correct state domains.

The implementation asserts unique true-UTC keys, unique collapsed wall keys,
and exact total-row and finite-row reconciliation separately for the full-day,
wake, pre-sleep, and sleep domains. Synthetic warning-as-error tests cover
finite-plus-finite, finite-plus-missing, and mixed-state repeated folds. The
expensive full profile rerun remains pending.
