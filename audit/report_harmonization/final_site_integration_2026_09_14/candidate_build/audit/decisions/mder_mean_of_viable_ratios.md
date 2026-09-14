# MDER as the mean of viable momentary ratios

Decision ID: `METRIC-010`  
Date: 2026-08-11  
Status: author approved, implemented, independently verified, and repinned  
Supersedes: `METRIC-003` and the implementation approved in `DEV-051`  
Reopens: the transfer of the `METRIC-008` upper-tail disposition to the new
estimand  
Scope: primary and gap-timing-unaware MDER preparation, shared model inputs,
MDER-dependent hypothesis results, displays, and claims

## Decision

The melanopic daylight efficacy ratio (MDER) is the arithmetic mean of viable
momentary ratios. For each retained participant-day:

1. place the eligible technical `MEDI` and photopic `LIGHT` channels on the
   complete 1,440-minute local wall-clock grid;
2. when daylight-saving fall-back creates more than one real observation for
   the same local minute, average each channel within that local minute before
   forming a ratio;
3. retain a minute only when both channels are finite and strictly positive;
4. calculate `MEDI / LIGHT` for every retained minute; and
5. report the arithmetic mean of those minute-level ratios only when at least
   720 of the 1,440 wall-clock minutes are viable.

The 50% cutoff is inclusive: 720 viable minutes pass and 719 fail. A spring
daylight-saving clock gap remains absent from the 1,440-minute wall-clock grid;
an autumn repeated minute contributes once after the channel-wise mean. The
fixed denominator makes sites and dates comparable on the intended local
24-hour cycle.

Pairs with a zero or non-finite value in either channel are discarded because
their ratio is undefined or not scientifically meaningful. A day with no
viable pair receives `no_viable_momentary_ratio`; a day with some viable pairs
but less than 50% support receives `below_viable_ratio_fraction`. In both
cases, only MDER is missing. The participant-day remains available for every
other admissible metric.

The general 50%-within-hour and 80%-within-day Rule A preparation still occurs
upstream. The MDER rule is an additional metric-specific support requirement,
not a replacement for general day eligibility. Reference profiles, ordinary
paired coverage, and signal-specific time-of-day support maps no longer
weight, scale, or gate MDER. The former 0.70/0.80/0.90 conjunctive profile gate
belongs to the superseded ratio-of-integrals estimand and is not carried over
as though it tested the same quantity.

## Why the decision changed

The ratio-of-integrals implementation answered a different question: it
weighted each moment by photopic illuminance. The author intended each viable
momentary spectral ratio to contribute equally before the daily average was
taken. The ratio-of-integrals version therefore produced a pronounced upward
shift that did not resemble the submitted implementation, even though most
other repaired metrics changed little.

The former implementation is retained as historical audit evidence under
`artifacts/08_diagnostics/mder_METRIC-010/superseded_METRIC-003/`; it is not an
alternative primary analysis.

## Verified outcome

The independent R 4.6.1 reconstruction checked every eligible participant-day
directly from the one-minute coverage artifacts and reconciled the daily RDS,
CSV, long-format, support, settings, and manifest outputs.

| Placement | Eligible participant-days | MDER available | MDER unavailable | Participants represented | Mean | Median | Maximum |
|---|---:|---:|---:|---:|---:|---:|---:|
| Near eye | 816 | 702 | 114 | 137 | 0.724 | 0.724 | 1.857 |
| Chest | 902 | 732 | 170 | 152 | 0.757 | 0.749 | 3.574 |

Every unavailable MDER day had some viable ratios but less than 50% viable
minute support; no otherwise eligible day had zero viable ratios. The complete
site-specific counts are stored in
`artifacts/08_diagnostics/mder_METRIC-010/support_by_site.csv`.

On exact common participant-days, the new MDER is close to the
gap-timing-unaware/V0 mean-of-ratios preparation:

| Placement | Common days | Mean primary minus gap-timing-unaware | Median difference | Mean absolute difference | Correlation |
|---|---:|---:|---:|---:|---:|
| Near eye | 631 | +0.0100 | +0.0050 | 0.0104 | 0.991 |
| Chest | 598 | +0.0150 | +0.0085 | 0.0152 | 0.991 |

By contrast, the new primary values are lower than the superseded
ratio-of-integrals values on their common days:

| Placement | Common days | Mean primary minus superseded | Median difference | Mean absolute difference | Correlation |
|---|---:|---:|---:|---:|---:|
| Near eye | 659 | -0.123 | -0.119 | 0.130 | 0.629 |
| Chest | 705 | -0.138 | -0.138 | 0.150 | 0.731 |

An exact comparison of the participant-day artifacts found zero changed cells
across all 43 shared non-MDER fields at either placement. The downstream
Preparation 06 rebuild also retained all 618 site/daylight context rows and
all 47 context fields exactly; only their input provenance identities changed.
All six H06 hourly analysis frames reconstructed from the repinned inputs were
identical to their accepted frozen frames with tolerance zero and attributes
included.

## Provenance identities

| Artifact | SHA-256 |
|---|---|
| Primary metric manifest | `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43` |
| Independent MDER audit manifest | `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb` |
| Superseded-value snapshot manifest | `21d9aebfc483660694c71fb29733fa6da984243c6c7d5a8c07d053a7489be74c` |
| Gap-timing-unaware preparation manifest | `97c8315afab1c50350754eecb00f69d4fe6923a6c005ecbc0d29a40b7b855a4e` |
| Site/daylight context manifest | `fdc4b78730a27c65d4eb9e4589a5fedbe046798842de0b96c71e5e65101854d3` |
| Shared base-model-data manifest | `6cfbfb18a2f6b1e31613e3fba803c3fbf64eb63e37155ae4fffd437a213b3ad0` |
| H01 primary prepared-input manifest | `9908f695a90c117e0787ab450e9a2531c9db6e9d7ee750797c6a1291c5f1b07b` |
| H01 gap-timing-unaware prepared-input manifest | `b5b368619f073bd9b31bd44f7f76bbf5d41856b4a90889d7da1aa4a0ea4ec56e` |
| Pre-analysis comparison manifest | `a1f12dd054fd3488af859884479240339fab4249fd6cefa58195ab97ea36c833` |
| Downstream rebuild manifest | `4ed6f748e21a59eb0d64810de4804956f0763ff026ae65706c331209ddbecf0a` |
| H06 hourly-frame invariance evidence | `75794d5dc13392a05cd81ac57456bd03ccc5f12713f8f774db72f2bfab44de4f` |

## Downstream disposition

MDER-dependent portions of Preparation reports, Descriptives, H01, H05, the
daily-metric H06 variant, and H10 must be reopened. Each task must update only
its MDER model frame, fitted MDER model, diagnostics, confidence intervals,
multiplicity family containing MDER, tables, figures, prose, claims, and
manifest identities. All non-MDER models and accepted results remain frozen.

H02, H03, H04, the hourly H06 analysis, H07, H08, H09, and H11 do not fit MDER
and require no scientific rerun. They may need a provenance-only hash or
wording refresh if they cite the superseded shared manifest.

Because an arithmetic mean of momentary ratios can be influenced by small but
positive photopic denominators, the old upper-tail/device-day disposition is
not transferred automatically. MDER-dependent tasks must inspect the new
upper tail and influence diagnostics under the new estimand; they must not
silently reuse the two device-days identified for the ratio-of-integrals
version.

## Reopening condition

Reopen if the paired-channel eligibility mask, one-minute wall-clock grid,
strict-positive rule, 50% viable-minute cutoff, daylight-saving flattening, or
arithmetic averaging rule changes; if independent verification no longer
passes; or if a downstream MDER audit identifies a coding or measurement
problem that changes the estimand or admissible sample.
