# Personal light-exposure metric-validity decision

Decision ID: `METRIC-001`  
Related MDER support decision: `METRIC-003`  
Status: approved advisory specification; implementation and rerun pending  
Decision date: 2026-07-29  
Scope: common metric construct, temporal support, missingness, gap handling,
reference-profile use, and metric-specific admissibility  
Implementation boundary: this record does not change analytical files or
establish that the present metric values are final  
Machine-readable companion:
[`../ledgers/metric_validity.csv`](../ledgers/metric_validity.csv)

## Decision in brief

The retained data define an intentional hybrid 24-hour light-exposure
construct:

- during wake and pre-sleep, the primary measurements are near-eye
  measurements;
- during reported sleep, the logger is beside the bed and therefore measures
  the bedside sleep environment, not ocular exposure; and
- metrics that span wake and sleep describe this explicitly labelled hybrid
  record. They must not be described as continuous 24-hour ocular exposure.

The 50% hourly and 80% daily thresholds are retained. `COVERAGE-001` fixes the
current 1,440-minute whole-cycle denominator (Rule A) as primary and the two
sleep-excluded alternatives (Rules B and C) as sensitivity scenarios. Because
the signed preregistration literally says to exclude sleep from the daily
denominator, primary Rule A is disclosed as `DEV-055`; it is not described as
preregistration-faithful. Eligibility of a participant-day is separate from
admissibility of a metric. Failure of one metric's temporal, state, boundary,
or denominator requirements makes that metric `NA` with a reason code; it does
not remove the otherwise eligible participant-day from other metrics.

The 10-darkest-hour level and timing metrics are retained. No 5-darkest-hour
level metric (`L5`) will be calculated. The current metric concepts remain
eligible after the modifications below; the existing implementations are not
accepted merely because they return a number.

## Scenario and common rules

### Eligibility, timestamps, and state

1. Preserve the original local-clock time axis and an explicit regular grid.
   Missing, invalid, saturated, non-wear, and unsupported observations remain
   missing; they are never converted to darkness or zero.
2. Under primary Rule A, an hour remains eligible only with at least 50% valid
   data, and a participant-day remains eligible only with at least 80% support
   across the fixed 1,440-minute hybrid day, including bedside
   sleep-environment measurements. The numeric thresholds are preregistered;
   the full-day denominator is the approved deviation `DEV-055`.
   State-specific metrics must additionally have observable support in their
   named state.
3. The expected interval, actual interval duration, local time zone, daylight
   saving transition, placement, sleep/wake state, wear state, and gap status
   must remain explicit.
4. Every result table carries both the eligible-data denominator and the
   metric-specific non-missing denominator. Metric-specific missingness uses
   reason codes such as `no_state_window`, `insufficient_bin_support`,
   `no_supported_candidate`, `left_censored`, `right_censored`,
   `no_threshold_event`, `zero_denominator`, and
   `insufficient_repeated_days`.
5. A true absence of a threshold event is zero for a duration metric only
   when the relevant search domain is sufficiently observed. The corresponding
   first, last, or mean timing is `NA` with `no_threshold_event`, not midnight
   or zero.

### Fixed reference profile

A dedicated preparation notebook will learn the reference profile once and
export it as a versioned, hashed R object plus a rectangular CSV. No
participant-day calculation may refit or update the profile.

The primary reference is pooled across sites but **not across placements or
states**. It uses participant-balanced 30-minute local-clock bins within each
placement-by-state domain. MEDI and photopic illuminance (`LIGHT`) receive
separate reference profiles. Participant balancing means that participants,
not their unequal numbers of epochs or days, determine the pooled bin
profile. The export must include the contributing participant and
participant-day counts for every bin.

Site-specific and leave-one-site-out profiles are sensitivity specifications.
They test dependence on the pooled temporal reference; they do not create
participant-day-specific profiles and do not reverse the approved decision
that near-eye data are primary and chest data complementary.

For a target domain with fixed reference weight \(w_b\) and observed support
\(c_b\) in 30-minute bin \(b\), profile-weighted coverage is:

\[
C_w = \frac{\sum_b w_b c_b}{\sum_b w_b}.
\]

Here \(c_b\) is the observed fraction of the expected bin, not an indicator
created after deleting missing rows. The profile used for \(w_b\), the
placement/state domain, and zero-denominator handling must be stored with the
metric.

Profile-weighted coverage is a support diagnostic, not a universal
correction factor. Time-sensitive correction is used only for an additive
estimand that supports it, especially dose. Means, quantiles, threshold
durations, continuous periods, windows, and clock timings must not be divided by coverage
as a generic repair.

### Gaps, windows, and boundaries

- Continuous threshold periods end at missing or invalid intervals, disallowed gaps,
  non-wear, device changes, participant-day boundaries, and any state boundary
  that is outside the metric's domain.
- Durations use actual valid interval lengths. Consecutive retained rows do
  not establish continuity.
- M10 and L10 candidates are evaluated on the 30-minute local-clock grid.
  Each 10-hour candidate must comprise 20 consecutive clock bins and carry
  explicit observed and profile-weighted support. Unsupported candidates
  cannot win merely because missing values were removed.
- First/last events and period onsets/offsets carry left- and right-boundary
  censor flags. An event adjacent to an unobserved search-window boundary is
  not reported as the true first or last event without qualification.
- The L10 search wraps across midnight without compressing the time axis.

### MDER, IS, and IV

MDER is the exposure-weighted ratio of integrals over identical paired valid
intervals:

\[
\mathrm{MDER} =
\frac{\sum_i \mathrm{MEDI}_i \Delta t_i}
     {\sum_i \mathrm{LIGHT}_i \Delta t_i}.
\]

It is not the arithmetic mean of epoch-level `MEDI / LIGHT` ratios. Under
`METRIC-003`, ordinary paired coverage, fixed MEDI-profile support, and fixed
`LIGHT`-profile support must each be at least 0.80, and the paired `LIGHT`
integral must be positive. Failure of any requirement produces exactly one
reason-coded MDER `NA` without removing the participant-day. The fixed
profiles diagnose signal-specific temporal support; they do not scale,
weight, or correct the numerator, denominator, or ratio. Support cutoffs 0.70
and 0.90 are fixed MDER-specific sensitivities.

IS and IV are calculated from the fixed one-hour grid defined in
`metric_implementation_parameters.md`. Missing hours remain missing. IV
differences use only truly adjacent real hours with the expected time
separation; neither deleted-row adjacency nor concatenated wake time is valid.
IS collapses a repeated fall-back clock hour for the like-clock comparison,
whereas IV preserves both real hours. Both metrics require at least three
eligible days. IS additionally requires at least 20 of 24 clock hours, each
represented on at least two eligible days; IV requires at least 24 adjacent
hour pairs across at least three eligible days. Both metrics retain the hybrid
24-hour interpretation and must disclose that sleep intervals represent the
bedside environment.

## Per-metric decisions

`Modify` below means that the metric concept is retained but the current
implementation must be replaced or qualified before use. `Exclude` means the
metric must not be produced.

| Metric | Current validity | Approved action and primary rule | Failure condition on an otherwise retained day |
|---|---|---|---|
| 30-minute arithmetic mean MEDI | `modify` | Preserve the 30-minute local-clock grid for H2/H11; require at least 15 valid one-minute intervals, report bin support, and apply the zero-aware log only at the modelling stage; never remove a whole day because this outcome is static or unsupported. | Unsupported bin becomes metric-specific `NA`; the day stays retained. |
| 1-hour zero-aware geometric mean MEDI | `modify` | Preserve the local-clock hourly grid for H3/H4/H6; require at least 30 valid one-minute intervals and retain context/state boundaries. | Unsupported hour becomes metric-specific `NA`; the day stays retained. |
| Daily geometric mean MEDI | `modify` | Report the zero-aware geometric mean of valid hybrid-day MEDI with ordinary and profile-weighted coverage; do not divide the mean by coverage. | No supported daily value or failed day eligibility. |
| M10 mean | `modify` | Select the brightest supported 20-bin candidate and calculate its geometric mean. | No supported 10-hour candidate. |
| L10 mean | `modify` | Select the darkest supported 20-bin candidate across the midnight boundary and calculate its geometric mean. | No supported 10-hour candidate. |
| L5 mean | `exclude` | Do not calculate or report it. | Not applicable. |
| Time above 1,000 lx | `modify` | Sum actual qualifying interval durations on the hybrid day; do not scale by coverage. | Target domain insufficiently supported; zero is allowed only for an observed no-event day. |
| Time above 250 lx during wake | `modify` | Project canonical diary intervals onto the complete true-minute grid, then sum actual qualifying intervals within valid waking near-eye wear. | `incomplete_state_domain`, `no_state_window`, or `insufficient_state_support`; an adequately observed no-event wake window is zero. |
| Time below 10 lx during pre-sleep | `modify` | Project canonical diary intervals onto the complete true-minute grid, then sum actual qualifying intervals in the declared pre-sleep state. | `incomplete_state_domain`, `no_state_window`, or `insufficient_state_support`. |
| Time below 1 lx during sleep | `modify` | Project canonical diary intervals onto the complete true-minute grid, then sum actual qualifying intervals and label the result as bedside sleep-environment duration. | `incomplete_state_domain`, `no_state_window`, or `insufficient_state_support`. |
| Longest period above 250 lx | `modify` | Use true interval lengths and terminate periods at every disallowed gap or boundary. | Unsupported continuity or a boundary-censored period; an observed no-event day has zero duration. |
| First time above 250 lx | `modify` | Use local clock time with explicit search-window and left-censor status; no coverage scaling. | No event, unobserved left boundary, or insufficient search support. |
| Last time above 250 lx | `modify` | Use local clock time with explicit search-window and right-censor status; no coverage scaling. | No event, unobserved right boundary, or insufficient search support. |
| Mean timing above 250 lx | `modify` | Use a circular, interval-duration-weighted mean of supported qualifying intervals. This remains a documented replacement of the registered midpoint of the longest period, not the same metric under a new name. | No event or insufficient circular/search-window support. |
| M10 midpoint | `modify` | Report the circular local-clock midpoint of the selected supported M10 candidate. | No supported candidate or unresolved boundary. |
| L10 midpoint | `modify` | Report the circular local-clock midpoint of the selected supported midnight-wrapping L10 candidate. | No supported candidate or unresolved boundary. |
| Daily melanopic EDI dose | `modify` | Integrate MEDI using actual durations; use the fixed MEDI profile for the approved time-sensitive missing-coverage correction and retain observed dose and correction factor. | Missing/zero reference mass, unsupported correction, or failed eligibility; never substitute zero. |
| MDER | `modify` | Use the ratio of MEDI and LIGHT integrals on identical paired valid intervals only when ordinary paired, fixed MEDI-profile, and fixed LIGHT-profile support are each at least 0.80; require a positive paired LIGHT integral; do not scale or profile-weight the ratio. | No paired observations, non-positive paired LIGHT integral, or any of the three supports below 0.80; return one reason-coded metric `NA` and retain the day. |
| Interdaily stability | `modify` | Use one-hour common local-clock bins on a regular repeated-day hybrid grid; require at least three eligible days and at least 20 clock hours represented on at least two days. | Fewer than three eligible days, insufficient clock-hour support, or undefined variance. |
| Intradaily variability | `modify` | Use only truly adjacent one-hour pairs on the absolute-time grid, retain missing gaps, and require at least 24 pairs across at least three eligible days. | Fewer than three eligible days, fewer than 24 adjacent pairs across three days, or undefined variance. |

The exact estimands, units, primary rules, sensitivities, failure conditions,
current baseline counts, and reporting qualifications are recorded row by row
in `audit/ledgers/metric_validity.csv`.

## R-verified current baseline

These counts describe the existing July 2026 `.RData` artifacts. They are
**baseline/current**, not accepted final counts. They must be regenerated
after implementation, the approved `MEDI <100000` operating-range rule, and a
clean pipeline rerun.

Verification environment:

- R 4.6.1 (2026-06-24), invoked with `Rscript --vanilla`;
- lubridate 1.9.4 was loaded for current duration-class missingness checks;
- counts used base-R row, unique-key, and `is.na()` operations;
- no analytical file was changed.

Input artifacts:

| File | SHA-256 |
|---|---|
| `data/metrics_separate_glasses.RData` | `f4b8ddfdbd4ee2e577957ed6a89f65a7b44581bba916e786147dcd40c94a234b` |
| `data/metrics_separate_chest.RData` | `f1ab7345966bdaa8705a03745798d99c3d945fe0119f2476a5dd6e9a53f5de2f` |
| `data/preprocessed_glasses_2.RData` | `0d00bac25d955d45447f74cc9c3ad6a5f5dfa1de1282d8d619c9468f72e0c430` |
| `data/preprocessed_chest_2.RData` | `b289c17c64d1bd24166fa3873da9aa8f22a5f57c793a7282ecb201dc77dcd274` |

The existing metric artifacts contain 811 near-eye participant-days from 141
participants and 897 chest participant-days from 154 participants.

Current metric-specific missingness is:

| Current output | Near-eye non-missing / metric `NA` | Chest non-missing / metric `NA` |
|---|---:|---:|
| First, last, and mean timing above 250 lx | 778 / 33 | 867 / 30 |
| MDER | 725 / 86 | 729 / 168 |
| Duration below 10 lx in pre-sleep | 780 / 31 | 867 / 30 |
| Duration below 1 lx in sleep | 790 / 21 | 878 / 19 |
| Duration above 250 lx in wake | 755 / 56 | 839 / 58 |

All other current daily columns mapped in the ledger have 811/0 near-eye and
897/0 chest values, but that numerical completeness is not proof of temporal
or construct validity.

The current 30-minute objects contain 38,832 near-eye rows
(37,603 non-missing arithmetic and geometric MEDI summaries; 1,229 `NA`) and
42,912 chest rows (41,664 non-missing; 1,248 `NA`). They represent only 809
of 811 retained
near-eye days and 894 of 897 retained chest days because the current static-day
filter removes two and three otherwise retained days, respectively. The
approved implementation must retain those days and assign bin/outcome-level
status instead.

The H2/H11 outcome is the zero-aware log of the 30-minute arithmetic mean, as
documented in `_deviations.qmd:20`; it is not a 30-minute geometric mean.
H3/H4/H6 separately use a one-hour zero-aware geometric mean. An earlier
version of this audit conflated those outcomes; the ledger now records them as
separate estimands.

## R-verified MDER support gate

The cutoff-neutral gate used the repaired Preparation 02 Rule A
participant-days and the fixed pooled MEDI and `LIGHT` profiles. It calculated
support and denominator diagnostics only; no MDER ratio, model, p-value, or
downstream result was calculated.

| Placement | Eligible days | 70% retained | 80% retained | 90% retained |
|---|---:|---:|---:|---:|
| Near-eye source | 811 | 790 | 733 | 601 |
| Chest source | 897 | 874 | 825 | 691 |

At 0.80, all 141 near-eye participants across nine sites and all 154 chest
participants across eight sites remain represented. Each placement has two
days with a non-positive paired `LIGHT` integral; these fail independently of
the support cutoff. An independent R 4.6.1 verifier reproduced all 2,650
daily, overall, site, and participant rows exactly and confirmed the manifest
SHA-256
`c4ecfab41892e44b38dd78097277ccef5f94a379b44c7b309de281e9215a7b3c`.

The author approved 0.80 as primary and 0.70/0.90 as fixed sensitivities
before repaired ratios or hypothesis results were inspected. Full details and
reopening conditions are in
[`../findings/mder_support_cutoff_gate.md`](../findings/mder_support_cutoff_gate.md).
Canonical metric values and downstream before/after comparisons remain
pending.

## Locked implementation parameters

The base epoch, threshold endpoints, gap rule, bin and window support,
reference-profile support, metric-specific relevance maps, dose-correction
guard, MDER support rule, deterministic M10/L10 tie rule, DST handling, IS/IV
requirements, and circular-resultant criterion were fixed before inspecting
rebuilt metric values. They are recorded in
[`metric_implementation_parameters.md`](metric_implementation_parameters.md).

Participant-window classification remains `undetermined` only when the
prespecified support, state, boundary, denominator, or repeated-day rule
cannot be met. Parameters must not be tuned after inspecting which value
produces a preferred result.

## Final advisory sets

- Retain after specified modification: 30-minute arithmetic mean MEDI,
  one-hour and daily geometric mean MEDI, M10 mean, L10 mean, all five
  duration metrics, all five retained
  timing metrics including the documented mean-timing replacement, dose,
  MDER, IS, and IV.
- Exclude: L5 mean.
- Undetermined at participant-window level: any retained metric whose support,
  state, boundary, denominator, or repeated-day requirement cannot be
  established. Such a result is metric-specific `NA`, not a reason to discard
  unrelated metrics.

## Implementation and re-audit handoff

The later R implementation must:

1. create and freeze the participant-balanced reference-profile artifact in a
   dedicated preparation notebook;
2. export expected and observed support by 30-minute local-clock bin,
   placement, state, site-profile scenario, and light quantity;
3. emit one metric-value table and one metric-admissibility table keyed by
   site, participant, date, placement, and metric;
4. store ordinary coverage, profile-weighted coverage, correction factor,
   censor flags, gap/boundary status, and one failure reason per missing
   metric;
5. preserve eligible days when individual metrics fail;
6. rerun pooled, site-specific, and leave-one-site-out profile scenarios
   without participant-day refitting;
7. compare current and repaired values and sample counts in R; and
8. return this decision to read-only metric-validity review before any repaired
   result is treated as manuscript evidence.
