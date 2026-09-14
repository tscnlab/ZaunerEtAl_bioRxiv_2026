# MDER as the mean of viable momentary ratios

Decision ID: `METRIC-010`  
Date: 2026-08-11  
Status: author approved, implemented, independently verified, repinned, and
gap-timing-unaware reconstruction repaired  
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

Every unavailable primary MDER day had some viable ratios but less than 50%
viable minute support; no otherwise eligible primary day had zero viable
ratios. The complete site-specific counts are stored in
`artifacts/08_diagnostics/mder_METRIC-010/support_by_site.csv`.

## Gap-timing-unaware reconstruction repair

The first `METRIC-010` repin relabelled the gap-timing-unaware MDER as the same
momentary-ratio construct but still copied the frozen daily values. It did not
recalculate them from the pinned one-minute `MEDI` and `LIGHT` inputs. This
became visible as a construct-impossible finite MDER of zero for
`THUAS::THUAS_S002` at chest level on 2025-03-09, a day with 1,440 zero `MEDI`
values and therefore no viable strictly positive minute-level ratio.

The repaired builder now applies the five-step rule above directly to the
pinned one-minute gap-timing-unaware inputs. It changes only MDER; all 25,620
non-MDER participant-day cells are exactly unchanged. The independently
verified gap-timing-unaware outcome is:

| Placement | Eligible participant-days | MDER available | MDER unavailable | Participants represented | Mean | Median | Maximum |
|---|---:|---:|---:|---:|---:|---:|---:|
| Near eye | 811 | 687 | 124 | 137 | 0.724 | 0.724 | 1.857 |
| Chest | 897 | 723 | 174 | 152 | 0.757 | 0.750 | 3.645 |

The unavailable counts comprise 122 near-eye and 171 chest days below the
720-minute support cutoff, plus two near-eye and three chest days with no
viable momentary ratio. Only MDER is missing on those days.

On exact common participant-days, primary and gap-timing-unaware MDER are now
nearly identical because both implement the same one-minute estimand. The
small remaining differences arise from the prepared input streams, not from a
different daily formula:

| Placement | Common days | Mean primary minus gap-timing-unaware | Median difference | Mean absolute difference | Correlation |
|---|---:|---:|---:|---:|---:|
| Near eye | 687 | +0.000039 | 0 | 0.000922 | 0.999775 |
| Chest | 723 | -0.000009 | 0 | 0.001004 | 0.999823 |

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
| Gap-timing-unaware preparation manifest | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` |
| Gap repair evidence manifest | `81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018` |
| Gap participant-day RDS | `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1` |
| Gap MDER-support RDS | `a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5` |
| Site/daylight context manifest | `959e7a1ff1e659ad3eb673c4d4b827da0b02b8a0a779e2647459638c4dac1045` |
| Shared base-model-data manifest | `b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09` |
| H01 primary prepared-input manifest | `5aa19326b2de468efb177af0d8f193253db63aade2d607f9570f5c3337e39c74` |
| H01 gap-timing-unaware prepared-input manifest | `79ee4818d7f3967827a6412f8537196e84ee7a6ccc1b8d2c5e9dd3124ed44b47` |
| Pre-analysis comparison manifest | `f90ea36334b59821101ef36de50d5d84dcfc6e8bee23f1f918be10fb2247724e` |
| Downstream rebuild manifest | `408087d420999322628066caae31efc288a5a5213b8b57d4b9a4ad77c9ec9a77` |
| H06 hourly-frame invariance evidence | `75794d5dc13392a05cd81ac57456bd03ccc5f12713f8f774db72f2bfab44de4f` |

## Downstream disposition

MDER-dependent portions of Preparation reports, Descriptives, H01, H05, the
daily-metric H06 variant, and H10 must use the repaired gap artifact. Each task
must update only its MDER model frame, fitted MDER model, diagnostics,
confidence intervals, multiplicity family containing MDER, tables, figures,
prose, claims, and manifest identities. A task that already completed its
primary `METRIC-010` amendment needs only the now-changed gap-timing-unaware
MDER branch and any family-wide fields derived from it. All non-MDER models
and accepted results remain frozen.

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
