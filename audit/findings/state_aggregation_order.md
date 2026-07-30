# State alignment relative to minute aggregation

Status: verified equivalent for the pinned source releases  
Date: 2026-07-30  
Runtime: R 4.6.1, clean `Rscript --vanilla` session

## Audit question

The established workflow attached diary and wear states at the native light
epoch and then used the modal categorical value while aggregating to one
minute. The canonical importer first calculates a complete native-epoch
arithmetic minute and then attaches the same half-open intervals at the
minute start. These operations are equivalent only when every interval
boundary is minute-aligned or, for a non-aligned boundary, the state at the
minute start is also the native-epoch modal state.

Signals are not masked before aggregation in either implementation. The
operating-range and approved non-wear rules are applied to the one-minute
value after its state has been assigned.

## Boundary audit

The pinned sleep-diary and wear-log files contain 6,737 finite interval
boundary timestamps. All wear boundaries, wake times, and all but three
attempted-sleep times fall exactly on a minute boundary.

The three non-aligned timestamps are:

| Participant | Attempted sleep | Seconds within minute |
|---|---|---:|
| RISE_S011 | 2025-06-10 22:20:36 | 36.00000 |
| RISE_S011 | 2025-06-12 22:34:36 | 36.00000 |
| RISE_S012 | 2025-06-10 21:47:34.28571 | 34.28571 |

At each of these boundaries, more than half of the containing minute precedes
the transition. The minute-start state is therefore also the modal
native-epoch state.

## Direct R verification

The affected RISE participants were nevertheless checked directly in both
placement streams. Native epochs were assigned the prepared half-open sleep
and wear intervals, reduced with the categorical modal rule used by
LightLogR, and compared minute by minute with state assignment at the minute
start.

| Placement | Participants | Compared participant-minutes | Sleep mismatches | Brown-state mismatches | Wear mismatches |
|---|---:|---:|---:|---:|---:|
| Near-eye | 2 | 15,840 | 0 | 0 | 0 |
| Chest | 2 | 24,480 | 0 | 0 | 0 |

The reproducible check is
`audit/scripts/verify_state_aggregation_order.R`. It reads only the pinned
cache and source manifest produced by Preparation 01.

## Decision and reopening condition

For the recorded releases, state assignment after complete native-epoch
minute aggregation is retained because it is exactly equivalent to the
native-epoch modal state and is substantially leaner. This is not a change to
the sleep or wear precedence rules. The audit must be rerun whenever a pinned
sleep, wear, or light source changes; any state mismatch reopens Preparation
01 and prohibits downstream use.
