# Input source selection

Decision ID: `INPUT-001`  
Status: approved implementation decision; full-site verification pending  
Decision date: 2026-07-29

## Decision

The canonical pipeline will import the public native-epoch light datasets
from immutable repository commits and will not substitute the separately
published `*_1minute` objects. Complete 1-, 10-, or 60-second streams are
aggregated to one minute before the prepared sleep and wear intervals are
attached at the minute start.

This ordering is permitted only because the pinned-source audit established
exact equivalence with attaching states at native epochs and retaining the
modal categorical state during aggregation. Of 6,737 finite sleep/wear
boundaries, only three are not minute-aligned, and all three retain the same
minute-start and native-epoch modal state. The direct affected-stream check
found zero sleep, Brown-state, or wear mismatches across 15,840 near-eye and
24,480 chest participant-minutes. See
`audit/findings/state_aggregation_order.md`.

The site repositories and revisions are recorded in
`config/site_sources.csv`. Downloaded files and derived artifacts will record
their SHA-256 hashes. The pipeline must fail when a pinned object is missing,
has an unexpected name or schema, or does not retain its documented site time
zone.

## Evidence

An R 4.6.1 comparison used the pinned BAUA commit
`a69ff3835c2ddef1379903ca6089eeb1a57c67c2`.

- Aggregating the 10-second near-eye object yielded 208,800 participant-minute
  keys.
- The published one-minute near-eye object contained 155,520 keys.
- 25,479 participant-minute keys with finite 10-second-derived melanopic EDI
  had no finite value in the one-minute object.
- Among jointly finite values, 99,378 melanopic EDI values differed by more
  than `1e-10`; the maximum absolute difference was approximately 46,846 lx.

The two public objects therefore do not encode interchangeable computational
inputs. Switching to the one-minute object would change observations and
values rather than merely reduce computation. The rebuilt analysis retains
the 10-second source used by the study workflow and treats one-minute
aggregation as an explicit, auditable transformation.

The source-boundary and affected-stream verification is reproducible with
`audit/scripts/verify_state_aggregation_order.R`. Any pinned source change
reopens the ordering decision and requires this check to pass before minute
state alignment is accepted.
