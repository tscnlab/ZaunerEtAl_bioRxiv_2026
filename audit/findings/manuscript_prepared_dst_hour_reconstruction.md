# Repeated fall-back hours in the manuscript-prepared-data sensitivity

Finding ID: `FIND-034`  
Status: repair verified  
Date: 2026-07-30

## Finding

The first reconstruction of the one-hour manuscript-prepared dataset kept the
two occurrences of a repeated daylight-saving fall-back hour as separate
rows. That is the correct representation for elapsed-time calculations in the
main preparation, but it did not reproduce how the manuscript dataset was
prepared.

The manuscript preparation first put all sites on the shared local-clock
scale and then averaged records with the same site, participant and local
hour. It therefore averaged the two fall-back occurrences into one local-hour
value. An independent R 4.6.1 reconstruction found:

| Placement | Manuscript preparation | First sensitivity reconstruction | Difference |
|---|---:|---:|---:|
| Near-eye | 19,176 hours | 19,180 hours | +4 |
| Chest | 21,288 hours | 21,290 hours | +2 |

The 30-minute sensitivity data already averaged the repeated clock labels, so
the first reconstruction also applied different daylight-saving rules at the
two time resolutions. Participant-level and participant-day H01 metrics were
not affected.

## Required repair

The one-hour sensitivity data must reproduce the manuscript preparation:

- group on the shared local-hour key without an occurrence number;
- average both fall-back occurrences within that key;
- retain source-occurrence counts only as documentation;
- verify unique analytical local-hour keys; and
- verify 19,176 near-eye and 21,288 chest rows.

This is not an additional scientific correction to the manuscript-prepared
data. It removes an unintended difference introduced by the reconstruction.

## Verification

R 4.6.1 production, isolated-build and independent-verifier checks pass.
The analytical local-hour key is unique, `local_occurrence` is one throughout,
and the final row counts are 19,176 near-eye, 21,288 chest and 40,464
combined. The manuscript-prepared-data manifest has SHA-256
`af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267`.

## Reopening condition

Reopen if the sensitivity one-hour key retains more than one row per site,
participant, placement and shared local hour, if its expected row counts
change, or if any later adapter treats source-occurrence provenance as
additional model rows.
