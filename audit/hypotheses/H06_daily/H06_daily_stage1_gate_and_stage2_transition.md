# H06 daily Stage 1 gate and Stage 2 transition

- Date: 2026-08-11
- Variant: H06 daily-metric preregistration-aligned analysis
- Gate: H06-D-G1
- Status: **author approved; bounded Stage 2 production-code pilot authorized**

## Author approval

The author replied **“approve”** to the 14-item H06-D-G1 gate in
`audit/hypotheses/H06_daily/01_audit_and_plan.qmd`. This approves:

1. work/free day, binary Sedentary/Active status, and previous-night sleep
   duration as three separate primary measures;
2. weekday/weekend as a named registered sensitivity; the remaining registered
   exercise and sleep fields as exploratory unless prospectively promoted;
3. separate one-measure primary models and a jointly adjusted three-core model
   only as exploratory;
4. fixed site with equal-site marginalization as primary, predictor-by-site
   heterogeneity as a separate hierarchy, and the signed random-site/random-
   slope formula as a benchmark with `NON_ESTIMABLE` permitted;
5. the 15 H05-derived family candidates subject to fresh H06-daily diagnostics,
   including the bounded L10 zero-mass pilot;
6. the prespecified timing transforms and failure rules;
7. the actual-date residual-dependence trigger and gap-aware daily AR(1)
   counterpart only when justified;
8. one 15-slot BH association family per activated predictor and separate
   15-slot heterogeneity families;
9. near-eye all available as primary, paired/common near-eye and chest as
   complementary, and all-available chest as context;
10. the declared prepared-data, placement, support, and exact-period
    sensitivities;
11. the H06-local KNUST_S005 provenance interpretation only if sedentary time
    is used;
12. the explicit diagnostic acceptability rules;
13. no numerical transfer of V0 hourly results; and
14. a production-code pilot and runtime gate before a heavy batch or
    resampling.

No conclusion from the separate hourly H06 analysis is imported.

## Author amendment: exploratory 30-minute time-of-day GAMM

The author additionally requested a separately labelled exploratory time-of-
day GAMM, implemented with `mgcv::bam()` and an AR(1) correction, to assess
work/free day, binary daily activity status, and previous-night sleep duration
against the supported **30-minute zero-aware geometric-mean melEDI metric**.
The specification is to use H02/H03 as precedents.

This amendment is a third estimand and is not a sensitivity of either the
daily-metric models or the approved hourly H06 model:

- each supported 30-minute bin is one model row;
- the response is `zero_aware_geometric_mean_medi_lx`, not the H02 arithmetic
  mean and not a daily metric;
- no day is weighted explicitly, although days with more supported bins
  contribute more rows by construction;
- predictor terms are exploratory and are excluded from every H06-daily
  15-slot multiplicity family;
- occurrence/magnitude or Tweedie family choice must be justified on this
  exact frame, not copied from H02/H03;
- true UTC provenance orders observations; `AR.start` resets at every
  participant-day, after each unsupported or elapsed-time gap, and on both
  sides of a non-one-to-one fall-back wall-clock outcome;
- the residual `rho` is estimated from a preliminary no-AR fit and fixed in
  the final `bam()` fit; for non-Gaussian fits this is explicitly a working-
  residual GEE approximation, not an exact likelihood AR(1);
- near eye is the pilot and eventual primary display; chest and paired/common
  placements remain complementary if the model passes the pilot gate.

The exact current near-eye complete-core frame contains 33,057 supported
30-minute bins from 715 participant-days, 137 participants, and nine sites.
It contains 10,225 exact zeros (30.9%). The chest frame contains 36,558 bins
from 789 participant-days, 149 participants, and eight sites, with 11,703
zeros (32.0%). These counts were reconstructed in R 4.6.1 from the immutable
Preparation 06 artifacts before any fit.

## H06-D-G2P pilot gate

Stage 2 now begins only as a bounded production-code pilot. It will:

1. exercise representative Gaussian, Tweedie, identity-Gaussian, and L10
   zero-mass daily metric families;
2. fit the near-eye 30-minute temporal candidate using the H02 sequencing
   contract and H03-style cyclic/global, site, participant, and participant-day
   structure;
3. compare a one-part Tweedie mean candidate with a two-part binomial/Gamma
   candidate because exact zeros are common and the generating mechanisms may
   differ;
4. report convergence, basis capacity, zero calibration, residual dependence,
   support, exact fitted samples, elapsed time, and projected production time;
5. make no production inferential claim and run no bootstrap or simulation;
6. stop for explicit author approval before the full model batch.
