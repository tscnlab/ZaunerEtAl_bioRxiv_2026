# Ten-second to one-minute aggregation

Decision ID: `PREP-001`  
Status: approved primary implementation; full-source support audit verified;
relaxed sensitivity implementation pending  
Decision date: 2026-07-30

## Primary rule

The pinned site releases contain explicit regular light streams. Most use a
10-second epoch, but the full-source audit found one regular 1-second stream
and one regular 60-second stream
([`../findings/heterogeneous_source_epochs.md`](../findings/heterogeneous_source_epochs.md)).
Each real one-minute interval is calculated separately for MEDI and LIGHT as
the arithmetic mean of all expected, finite subepochs. The primary
calculation requires the complete participant-stream schedule: 60/60, 6/6,
or 1/1 finite subepochs for 1-, 10-, or 60-second data. It retains:

- expected, observed, distinct, finite, and implicit subepoch counts;
- the true UTC minute and shared local wall-clock minute;
- site, participant, placement, UTC offset, DST, and source provenance; and
- separate validity for MEDI and LIGHT.

A minute with fewer than its stream-specific expected number of finite
subepochs is unsupported for that signal, not zero. The 50%-hour and 80%-day
rules are applied later and do not alter this aggregation definition.

This default preserves the effective behavior of the current arithmetic
aggregation when explicit missing rows are present while retaining streams
whose valid source epoch is not 10 seconds. A relaxed within-minute support
rule is available only as a declared sensitivity if partial minutes are
material; it is not selected after examining downstream results.

## Full-source support audit and fixed sensitivity

The R 4.6.1 full-source audit
([`../findings/minute_aggregation_support.md`](../findings/minute_aggregation_support.md))
found that a threshold of at least 50% finite native observations would
recover only 727 chest minutes per signal, 2,314 glasses MEDI minutes, and
2,387 glasses LIGHT minutes. These equal 0.040%, 0.141%, and 0.146% of
represented real-minute rows, respectively. Most recoverable minutes occur at
KNUST.

The complete-native-epoch definition therefore remains primary. A fixed
sensitivity will use at least 50% of the stream-specific expected native
observations, average only the finite observations, and leave the accepted
50%-hour and 80%-day rules unchanged. It will report site-specific support
because the partial-minute pattern is geographically concentrated.

## Ordering of the operating-range rule

The device operating-range rule is applied to the one-minute MEDI value after
aggregation. The aggregation step therefore retains values at or above
100,000 lx temporarily; the state/alignment step preserves the raw
one-minute value, sets the analytical MEDI value to missing at
`MEDI >= 100000`, and records the reason. This matches the analysis unit used
for the range rule and avoids rejecting a minute merely because one
10-second subepoch exceeded the boundary while the one-minute mean did not.

## DST and keys

Aggregation groups by unique true UTC minutes and never merges the repeated
fall-back hour. A separate derived wall-clock table may average repeated
local-clock minutes, with fold counts and offsets, for coverage,
time-of-day profiles, cutoffs, and clock-aligned models. Both real minutes
remain available for elapsed-time and adjacency calculations.
