# Metric implementation parameters

Decision ID: `METRIC-002`  
Related support decisions: `STATE-005`; `METRIC-003`; `METRIC-004`;
`METRIC-005`; `METRIC-006`  
Status: author approved; canonical Preparation 03 and Preparation 04 artifact
integrity independently verified; Preparation 04 result gate open for M10
timing and MDER upper-tail disposition  
Decision date: 2026-07-30  
Scope: parameters that were deliberately fixed before inspecting repaired
metric values

## Purpose

This record closes the implementation parameters left open by the
metric-validity decision. The parameters preserve the preregistered numeric
thresholds of 50% within an hour and 80% within a day. `COVERAGE-001` applies
the latter to Rule A's fixed 1,440-minute hybrid-day denominator; because the
signed wording instead excludes sleep, that denominator remains the approved
preregistration deviation `DEV-055`. Metric-specific support rules prevent one
unsupported metric from removing an otherwise useful participant-day.

The retained full-day record is an intentional hybrid measurement:
near-eye exposure during wake and pre-sleep, and bedside sleep-environment
light during the diary-defined sleep window. It supports 24-hour
environmental-light summaries, but it is not continuous 24-hour ocular
exposure.

## Fixed grid, thresholds, and gaps

- The base analysis grid is one minute and represents half-open intervals
  `[start, start + 60 seconds)`.
- Values must be finite, non-negative, not invalid non-wear, and, for MEDI,
  below 100,000 lx.
- Threshold endpoints are strict: `>1,000`, `>250`, `<10`, and `<1` lx
  melanopic EDI.
- Missing or invalid minutes are never converted to zero or darkness.
- No missing interval is bridged for durations, continuous periods, first/last timing,
  IS, or IV. Adjacency requires the expected separation on the true UTC
  instant axis.
- A 30-minute outcome bin requires at least 15 valid minutes. An hourly
  outcome bin requires at least 30 valid minutes. Unsupported bins become
  metric-specific missing values; the participant-day remains available to
  other metrics.

## State intervals and state-duration denominators

The canonical Preparation 01 sleep and wear intervals are explicit,
checksummed inputs to metric derivation. They are projected with true-UTC
half-open `[start, end)` semantics onto the complete true-minute grid before
eligible light values are joined. No state is carried forward beyond the
prepared intervals. Every source-present minute must exactly reproduce its
Preparation 01 diary state, wear provenance, measurement context, and conflict
flags.

Wake, pre-sleep, and sleep duration denominators include source-absent minutes
when the diary interval establishes their state. If any calendar-day minute
remains outside the supported diary intervals, the state domains cannot be
bounded and all three state-duration metrics on that day are
`incomplete_state_domain`. A complete day without the target state is
`no_state_window`; a known target state with inadequate valid MEDI is
`insufficient_state_support`. These failures never remove the
participant-day or its full-day metrics.

Under `STATE-005`, the primary state-window support cutoff is 0.80. The fixed
0.70 and 0.90 alternatives are metric-specific sensitivities; they do not
change participant-day eligibility.

## Fixed reference profiles

Reference profiles are learned once, before participant-day metric
calculation, on 30-minute local-clock bins. They are participant-balanced
medians and are separate by placement, state domain, and signal (MEDI or
LIGHT). Every exported bin records participant, participant-day, and
observation support.

Threshold-timing support uses a separate fixed distribution rather than the
median MEDI profile. Within each participant-day and 30-minute bin, it is the
fraction of valid minutes with MEDI strictly greater than 250 lx. Those
fractions are averaged with equal weight across days within each participant
and then with equal weight across participants. The distribution is fitted
once by placement for pooled, site-specific, and leave-one-site-out variants.
The pooled variant is primary; the other variants are fixed sensitivity
profiles.

The primary pooled full-day profile and each leave-one-site-out full-day
profile require at least 20 participants per bin. A pooled state-specific
profile and any site-specific profile require at least five participants per
bin. A bin below its threshold is unsupported rather than interpolated.

The fixed relevance maps are metric-specific:

- dose: the non-negative median MEDI profile;
- M10 support: positive contrast of the zero-aware log MEDI profile from its
  daily minimum;
- L10 support: positive inverse contrast of the zero-aware log MEDI profile
  from its daily maximum;
- first/last/mean timing above 250 lx: the fixed participant-day- then
  participant-balanced strict-exceedance distribution;
- paired MEDI/LIGHT metrics: paired support from their separate signal
  profiles, without using either profile to alter the ratio.

If a relevance map has zero total mass in its intended domain, it is
non-estimable and no unweighted fallback is silently substituted.
Every map other than the dose map is used for support assessment only. In
particular, the threshold-timing distribution never weights, scales, imputes,
or otherwise changes an observed timing value.

## Daily dose

Observed dose is the integral of valid MEDI over actual elapsed interval
duration. Corrected dose divides observed dose by profile-weighted coverage,
where missing low-exposure night periods contribute less missing relevance
than missing high-exposure daytime periods.

Correction is allowed only when profile-weighted coverage is at least 0.80,
equivalent to a maximum correction factor of 1.25. Both observed and
corrected dose, ordinary coverage, profile-weighted coverage, and correction
factor are retained. This correction is not applied to means, quantiles,
threshold durations, continuous periods, window levels, clock timings, or MDER.

## MDER

MDER is the ratio of MEDI and photopic `LIGHT` integrals over identical paired
valid one-minute intervals. It is calculated only when:

- at least one paired valid observation exists;
- the paired `LIGHT` integral is positive;
- ordinary paired-minute coverage is at least 0.80;
- support under the fixed pooled MEDI profile is at least 0.80; and
- support under the fixed pooled `LIGHT` profile is at least 0.80.

The three support requirements are conjunctive: passing one does not
compensate for failing another. The fixed signal-specific profiles diagnose
whether paired missingness occurs at consequential times of day. They do not
scale, weight, or correct either integral or the resulting ratio.

Failure produces exactly one metric-specific reason code, using the
prespecified precedence `no_paired_observation`,
`nonpositive_paired_light_integral`,
`below_ordinary_paired_support`, `below_medi_profile_support`, then
`below_light_profile_support`. MDER becomes `NA`, while the participant-day
and all unrelated metrics remain retained.

Cutoffs 0.70 and 0.90 are fixed MDER-specific sensitivity scenarios. The
primary 0.80 rule retains 733 of 811 near-eye and 825 of 897 chest
participant-days in the verified support gate, with every participant and
site represented. These are support classifications, not final repaired
MDER values; the canonical Preparation 04 rerun and downstream result
comparisons remain pending.

## M10 and L10

- Each candidate contains exactly 600 consecutive one-minute wall-clock
  intervals, and a candidate starts at every wall-clock minute.
- M10 evaluates the 841 non-wrapping starts from minute 0 through minute 840.
  L10 evaluates all 1,440 starts with midnight wrapping.
- The fixed 30-minute relevance maps are expanded deterministically to their
  constituent minutes. Candidate resolution does not relearn or interpolate
  the profiles.
- A candidate requires both ordinary minute support and its metric-specific
  profile-weighted support to be at least 0.80.
- Its level is the minute-duration-weighted zero-aware geometric mean over
  observed values; missing minutes are not compressed.
- The midpoint is `start + 5 hours`. The onset and `start + 10 hours` offset
  remain internal boundary diagnostics only; the analytical metric registry
  retains the window level and midpoint and excludes onset and offset.
- Tied candidate midpoints are summarized circularly. The candidate nearest
  that circular centre is selected, with the earliest absolute start as the
  final deterministic tie-break. A circular resultant below 0.10 makes the
  timing undefined.
- Fall-back duplicate wall minutes are averaged, with provenance, for this
  clock-aligned calculation. Elapsed-time metrics retain both real hours.
- L10 is retained. No L5 value or producer is permitted.

## Threshold timing and censoring

Mean timing above 250 lx is an interval-duration-weighted circular mean. A
circular resultant below 0.10 is undefined. Temporal support is scored with
the fixed strict-exceedance distribution described above. Mean timing uses
whole-day relevance support; first and last timing use the respective leading
or trailing search region. The primary cutoff is 0.80, and 0.70 and 0.90 are
fixed one-axis-at-a-time sensitivity cutoffs. This avoids discarding a day
merely because an unimportant half-hour is missing, while not claiming an
uncensored boundary when a time of day with appreciable event probability was
unobserved. The same learned distribution is reused at every cutoff. A
strict-any-boundary-gap rule is retained only as a separate sensitivity
scenario.

## Longest period above 250 lx

The primary value is the longest observed uninterrupted period with MEDI
strictly greater than 250 lx. Missing or invalid minutes, elapsed-time gaps,
measurement-context changes, and the participant-day boundary break observed
runs. The reported primary value is therefore an observed lower bound; it is
not changed to missing merely because an unobserved interval could conceal a
longer qualifying period.

The longest possible duration, calculated under the bounding assumption that
every missing or invalid minute qualified, is retained as an upper bound. A
censoring flag records when this upper bound exceeds the observed lower bound.
An exact-identifiable-only sensitivity reports the period only when the two
bounds agree. A lower bound of zero on a day with no observed qualifying
minute is distinguishable from an observed no-event day through the upper
bound and censoring fields. No participant-day is deleted because the exact period
duration is not identifiable.

If several observed periods share the maximum duration, the reported
onset/offset pair deterministically selects the earliest onset (then the
earliest offset). The selected-winner boundary-contact flag refers to that
same period. A separate any-winning-run flag records whether another tied
maximum touches either participant-day boundary.

## IS and IV

Hourly values require at least 30 of 60 valid minutes and preserve the
regular grid. Both metrics require at least three eligible days.

- IS additionally requires at least 20 of 24 clock hours, with each retained
  clock hour represented on at least two eligible days.
- IV additionally requires at least 24 truly adjacent hourly pairs spread
  across at least three eligible days.

Undefined total variance, insufficient clock support, or insufficient
adjacent pairs produces a reason-coded missing metric rather than a
participant exclusion.

## Major-result gate

These rules were fixed before the clean rebuilt outputs were inspected.
The strict-exceedance distribution, every-minute M10/L10 search, and
lower-bound longest-period contract pass their focused R 4.6.1 synthetic tests.
The M10/L10 implementation also agrees with an independent literal
enumeration on synthetic and sampled project inputs. The current canonical
Preparation 03/04 artifacts predate these three repairs, so their final sample
flows, values, model effects, and result differences remain unverified.
Those results and any downstream claim changes remain subject to the agreed
major-result approval gate.
