# M10 timing when all candidate starts tie

Finding ID: `FIND-017`  
Related decisions: `METRIC-005`; `METRIC-007`  
Status: approved repair verified in canonical artifacts  
Date: 2026-07-30  
Severity: high for M10 timing; M10 level remains valid

## Finding

M10 evaluates all 841 non-wrapping 600-minute windows starting at wall-clock
minutes 0 through 840. When every candidate has the same optimum, the M10
level is identifiable but its clock timing is not.

The current general tie rule summarizes winning midpoints circularly. Unlike
L10, the M10 start domain covers only part of the 24-hour clock. All 841 tied
M10 midpoints therefore have a circular resultant of approximately 0.526,
which exceeds the general 0.10 cutoff and produces an artificial selected
window:

- onset: minute 420 (07:00);
- midpoint: minute 720 (12:00); and
- offset: minute 1,020 (17:00).

This time is determined by the geometry of the allowed start domain, not by
the observed exposure.

## Affected participant-days

All five rows have M10 = 0 lx, ordinary support = 1, profile-weighted support
= 1, and all 841 candidate starts tied:

| Site/participant | Date | Placement |
|---|---|---|
| IZTECH_S009 | 2025-03-18 | glasses |
| IZTECH_S009 | 2025-03-19 | glasses |
| IZTECH_S009 | 2025-03-18 | chest |
| IZTECH_S009 | 2025-03-19 | chest |
| THUAS_S002 | 2025-03-09 | chest |

The analogous all-1,440-candidate L10 cases are already timing-non-estimable
because their full-clock tie resultant is below the cutoff.

## Approved repair

Retain the valid zero M10 level and the participant-day. When all 841 possible
candidate starts tie:

- set onset, midpoint, and offset to missing;
- set `timing_estimable = FALSE`; and
- use reason code `all_candidates_tied`.

No broader change to partial-support ties or the circular tie rule is
made. The author approved this disposition on 2026-07-30. The production
helper, independent literal verifier, direct unit suite, independent-verifier
suite, and synthetic Preparation 04 integration suite implement and verify the
rule. The integration test also confirms that the M10 level remains estimable
while the three timing records become missing with
`failure_reason = "all_candidates_tied"`. A synthetic partial M10 tie remains
timing-estimable, and the all-candidate L10 rule remains unchanged.

The regenerated canonical artifacts retain M10 level on all 811 near-eye and
897 chest participant-days and make timing reason-coded missing on exactly the
five affected records. The verified M10-timing samples are therefore 809
near-eye and 894 chest days. The independent core verifier reconstructed all
1,708 participant-days and passed the current 29-artifact manifest
`ac0325716421f2d90bb83b445ffb6ad965b131e382373e45f4ad6157eac5937d`.
H01, H09 and H10—and any H05 selection using M10 timing—must use these
regenerated artifacts before claims are reviewed.
