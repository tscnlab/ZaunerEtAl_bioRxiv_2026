# State intervals on the complete metric grid

Finding ID: `FIND-008`  
Status: repair unit verified; full clean rerun pending  
Severity: high  
Date: 2026-07-30

## Finding

Preparation 04 originally rebuilt a complete true-minute grid but inherited
`State.Brown`, wear, and measurement-context fields only from the
Preparation 02 coverage rows. That is not a sufficient state denominator:
a minute can be absent from the light source while still lying inside a known
sleep-diary or wear-log interval.

The repaired metric builder now treats the canonical Preparation 01 sleep and
wear interval RDS files as explicit inputs. It validates their manifest paths,
sizes, SHA-256 hashes, release provenance, UTC time axes, non-overlap, and
half-open `[start, end)` bounds. It projects those intervals onto every
complete true-UTC minute before joining eligible MEDI/LIGHT values. No
last-observation-carried-forward rule is used.

For each minute at which the light source was present, the newly projected
sleep label, Brown state, wear label, measurement context, context provenance,
and conflict flags must exactly match Preparation 01. Any mismatch aborts the
build.

## Metric-domain consequence

If any minute of a retained calendar day remains outside the supported diary
intervals, the total daily wake, pre-sleep, and sleep domains cannot be
bounded. Each state-duration metric on that day is therefore missing with
`incomplete_state_domain`. This differs from:

- `no_state_window`: the diary-state domain is complete but the target state
  is absent; and
- `insufficient_state_support`: the target state is known but too few of its
  minutes contain valid MEDI under the selected support rule.

The failure is metric-specific. The participant-day and all full-day metrics
remain available.

## Verification

The warning-as-error synthetic Preparation 04 suite covers:

- source-absent minutes inside a known state interval, including their correct
  state denominator and support;
- a source gap spanning a wake-to-pre-sleep boundary;
- a genuinely unresolved diary-state interval;
- wear-log `off` outside versus during diary sleep;
- half-open interval boundaries;
- exact interval artifact and manifest hashes; and
- deliberate source/projection and manifest/hash mismatches that must abort.

The BAUA near-eye coverage smoke object was then projected against the
canonical full-run interval artifacts without calculating final metrics:

- 152,640 complete true-minute rows reconciled;
- all source-present state/context values matched;
- 13,649 minutes remained genuinely unresolved by the diary intervals; and
- the cutoff-neutral gate classified 36 state-metric instances on 12
  participant-days as `incomplete_state_domain`, while retaining those days.

Verification used R 4.6.1 with:

- coverage SHA-256
  `7631444b6e9fb946f63bd1e941a91eedd4bf85814b52ca0bdb12648978ef4cd2`;
- state-interval-manifest SHA-256
  `4667373c35a28b54a6b998988087615d59ea4b5e02ea6e4e012f5522bad3c0bf`;
  and
- the project R 4.6 library and LightLogR 0.10.3.

This smoke result is not a final full-cohort sample count and does not select
the unresolved state-support cutoff.

## Reopening condition

Reopen this finding if the sleep/wear source releases, interval-construction
rules, state precedence, metric day boundary, or state-support estimand
changes.
