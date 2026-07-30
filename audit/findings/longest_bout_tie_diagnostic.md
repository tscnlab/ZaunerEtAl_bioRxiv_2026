# Longest-bout tied-winner boundary diagnostic

Finding ID: `FIND-016`  
Decision ID: `METRIC-006`  
Status: repaired, unit verified, and canonical values reconciled  
Date: 2026-07-30  
Severity: low diagnostic ambiguity; no scientific-value effect

## Finding

The longest observed bout selected its reported onset and offset
deterministically from the earliest tied maximum run. The existing
`winner_day_boundary_contact` field, however, was true when *any* tied
maximum run touched the participant-day boundary. The label could therefore
describe a different tied run from the one represented by the reported
timestamps.

## Repair

- Tied maximum observed bouts select the earliest onset and then the earliest
  offset.
- `winner_day_boundary_contact` now describes that selected run.
- `any_winning_observed_run_day_boundary_contact` separately reports whether
  any tied maximum run touches a day boundary.
- The selection rule and diagnostic scope are stored in the daily,
  censoring, settings, and per-artifact metadata.
- The possible upper-bound definition and metric-specific failure scope are
  now present in every placement artifact manifest row.

## Verification

A focused synthetic test contains two equal longest bouts: the earlier,
selected run is internal, and a later tied run touches the day boundary. The
selected-winner flag is false, the any-winning-run flag is true, and the
reported onset/offset identify the internal run.

`tests/test_build_metric_derivation.R` passes under R 4.6.1 with warnings as
errors. A frozen pre-repair versus post-repair R comparison found identical
values in every shared column of all 32 metric/state-gate tables. The
canonical data happened to contain no row on which the prior and clarified
shared boundary flag differed; the repair added explanatory columns and
metadata only.

Reopen if winner selection, bout adjacency, boundary definitions, or the
lower/upper-bound contract changes.
