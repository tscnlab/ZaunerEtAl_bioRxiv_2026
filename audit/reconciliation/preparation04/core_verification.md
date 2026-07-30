# Preparation 04 core artifact verification

Status: PASS for artifact integrity and approved M10 timing repair  
Verification date: 2026-07-30  
R version: 4.6.1

The independent verifier does not source the metric builder,
`metric_derivation.R`, `time_support.R`, or their scientific helpers.

It passed:

- the exact 29-artifact manifest, byte counts, and SHA-256 values;
- all four RDS/CSV pairs per placement;
- expected dimensions for 897 chest and 811 glasses participant-days;
- whole-cohort daily, long, admissibility, support, and censoring invariants;
- all 36 fixed strict-`MEDI > 250` timing-map groups and normalization;
- exact state-interval projection, longest observed/possible/exact bout
  reconstruction, and threshold-timing value/support/reason reconstruction
  for all 1,708 eligible participant-days.
- the approved all-841-candidate M10 rule: M10 level remains estimable, while
  onset, midpoint and offset are reason-coded missing for exactly two
  near-eye and three chest participant-days.

Verified metric manifest SHA-256:

`ac0325716421f2d90bb83b445ffb6ad965b131e382373e45f4ad6157eac5937d`

The verifier establishes that the artifacts faithfully implement the current
contract. `FIND-017` is closed at the primary-artifact level: timing is no
longer assigned to the five unidentified all-candidate ties. The approved
MDER primary values are unchanged; their registered 90% support, exact
two-day exclusion and waking-only scenarios remain downstream sensitivity
obligations rather than an open author gate.
