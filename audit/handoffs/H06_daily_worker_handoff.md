# H06 daily-metric worker handoff

- Date: 2026-08-13
- Variant: H06 daily-metric preregistration-aligned analysis
- MDER gate: **H06-D-G2-MDER — author approved on 2026-08-11**
- Corrected gap gate: **H06-D-G2-MDER-GAP — author approved on 2026-08-11;
  corrected MDER branch frozen**
- No-nugget gate: **H06-D-G2P-AR-NN — author approved on 2026-08-11;
  bounded diagnostic closed and frozen**
- L10: **H06-D-G2P-L10-METRIC011 accepted exactly as recommended under
  H06-D-002 / CHG-109; all joint slots remain non-estimable**
- Current work boundary: **Stage 3 reader report and Stage 4 preparation/
  provenance companion author accepted; H06-D-G4 closed; task wrapped up**
- Temporal amendment: **production complete under H06-D-G2P-H02 approval;
  pointwise intervals only**
- Shared MDER hold: **released for the controlling mean-of-viable-ratios
  contract**
- Main H06 ownership: **untouched**

## Scientific separation

H06_daily remains a scientifically separate participant-day analysis. Each
metric-specific participant-day contributes at most one row. It neither models
repeated hourly melEDI nor weights days by supported hours, and it is not a
sensitivity analysis of the approved hourly H06 outcome.

The exploratory temporal GAMM is a third estimand: one supported 30-minute
arithmetic-mean melEDI bin per row. Its output is not interchangeable with the
participant-day daily-metric route or the approved hourly H06 analysis.

## Stage 4 preparation and provenance companion

The author accepted the revised Stage 3 reader report and instructed the task
to continue. The bounded companion is complete and was subsequently accepted
with the instruction `approved - wrap up`:

- source: `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`,
  SHA-256
  `fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e`;
- standalone HTML:
  `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`, SHA-256
  `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`;
- 31-entry non-circular output manifest:
  `12f1d210aa03f9cbda72bc7a6f01457c92f637be0c375d59c6eeaaa025300030`;
- 15-entry report manifest:
  `c0d75bc9c4ead50ef48b8b7e7c88fd41a15474340472ea7f65443f5a196db1c2`;
- focused R 4.6.1 test:
  `51c0e2e42865e66d64e8625e7996c0d66022a15b0c0212df3bcf0ec3bdec8680`;
  and
- H06-D-G4 stop-gate record:
  `audit/hypotheses/H06_daily/H06_daily_stage4_preparation_gate.md`, SHA-256
  `96d4e2ea27bad097d7cccbf7e38371e404311073ad5a398e5c6d4f46c4118f1b`.

The no-refit author-acceptance closure adds:

- acceptance record:
  `audit/hypotheses/H06_daily/H06_daily_stage4_preparation_acceptance.md`,
  SHA-256
  `7c284d6b79df9e2d541c6484b38038820b4e1a0b8206997f1cd8a293e108481b`;
- 19-entry non-circular acceptance manifest:
  `artifacts/12_manifests/H06_daily/H06_daily_preparation_acceptance_manifest.csv`,
  SHA-256
  `9b9900a90ec0729e0e2140da31347cde1fc64304267e721d4ac3bdae2330800d`;
- bounded acceptance sealer:
  `scripts/hypotheses/H06_daily/seal_h06_daily_preparation_acceptance.R`,
  SHA-256
  `fe6e7d7f0d8486e6d2c02ecfbee64edd8d9996f08d93692a7bad2d8c28c23785`;
  and
- focused acceptance test:
  `tests/hypotheses/H06_daily/test_h06_daily_preparation_acceptance.R`,
  SHA-256
  `be7132d7129900f1176bf0d9697a23e7ffae72cc540b18996dd1d4ef75df7fd6`.

All 19 pinned inputs passed. The companion documents 15 participant-day
outcomes, three contexts, 522 exact fitted-sample records, 12 complete 15-slot
families, the H01-aligned diagnostic architecture, complementary and
sensitivity branches, the jointly adjusted daily analysis, and the separate
30-minute GAMM. It contains 17 compact tables, one embedded source-paired
figure with alt text, and one analysis-path diagram. The figure and rendered
DOM checks pass. Automated local `file://` browser control remained
unavailable and is disclosed.

No model was fit or refit. No prediction, rho, raw p-value, adjusted p-value,
deletion analysis, resampling result, or scientific output was recomputed.
The accepted Stage 3 identities remain unchanged. No website integration is
requested. Shared configuration, central ledgers, manuscript files, main H06,
commit, and push remain untouched. Both focused tests pass under R 4.6.1.
H06-D-G4 is closed, and there is no automatic next analytical or reporting
step in this task.

## Exploratory H02-aligned temporal production

The exact production response is
`log10(30-minute arithmetic mean melEDI + 0.1 lx)` with Gaussian identity-link
errors. The exact formula is:

```r
response ~
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, work_free_day, bs = "sz", k = 12) +
  s(time_hour, activity_status, bs = "sz", k = 12) +
  s(time_hour, by = sleep_between_h, k = 12) +
  s(time_hour, by = sleep_within_h, k = 12) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

Only the global clock smooth is cyclic. Every `sz`, `fs`, and sleep smooth has
`xt = NULL`. Fits use fREML, `discrete = TRUE`, one R thread, 0/24 global
knots, H02's true-time sequence boundaries, and a frame-specific rho estimated
from the rho-zero full-model response residuals.

Six frames were fitted:

- primary near eye: 33,057 bins, 715 days, 137 participants, nine sites,
  rho 0.5787;
- primary chest: 36,558 bins, 789 days, 149 participants, eight sites,
  rho 0.5697;
- paired/common near eye: 25,583 bins, 553 days, 109 participants, eight sites,
  rho 0.5791;
- paired/common chest: the same bins/days/participants/sites, rho 0.5611;
- gap-timing-unaware near eye: 32,969 bins, 710 days, 137 participants, nine
  sites, rho 0.5765; and
- gap-timing-unaware chest: 36,404 bins, 782 days, 149 participants, eight
  sites, rho 0.5635.

Five frames passed the full bounded diagnostic gate. Paired/common chest failed
the residual scale-pattern rule (absolute-residual/fitted Spearman 0.313 above
0.300); no association function or p-value was inspected or extracted from
that frame.

All primary and gap near-eye four-test BH-adjusted whole-function p-values are
displayed as `<0.001`. One mgcv approximate raw p-value was slightly negative
from numerical evaluation; the source retains it and the BH input alone was
clamped to zero. The primary Free/Work shifted-response ratio ranged from 0.20
at 08:45 to 1.84 after midnight, Active/Sedentary reached 1.62 at 15:15, the
within-participant +1 h sleep ratio reached 0.76 at 00:15, and the
between-participant +1 h sleep ratio reached 0.61 at 08:45. These are fitted
transformed-scale associations, not raw arithmetic-mean or causal effects.

Every reported temporal interval is pointwise. No simultaneous interval was
constructed or described. Site-deletion/influence refits remain withheld and
are not claimed as passed.

The production report is
`audit/hypotheses/H06_daily/04_temporal_h02_production.qmd` with self-contained
HTML. Three 170-mm reader figures have PNG/PDF/SVG exports, paired source-data
CSVs, alt text, and passing readability QA.

## Controlling METRIC-010 definition

Daily MDER is the arithmetic mean of viable one-minute melEDI/illuminance
ratios. Both channels must be finite and strictly positive. Shared preparation
uses a complete 1,440-minute local wall-clock grid, averages fall-back duplicate
minutes channel-wise, leaves spring-forward absent minutes missing, and retains
MDER with at least 720 viable minute ratios. There is no profile weighting,
gating, scaling, or ratio of daily integrals.

The controlling identities are:

- decision SHA-256 `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`;
- metric manifest `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`;
- independent MDER audit manifest
  `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb`;
- base-model manifest
  `b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09`;
- base input bundle
  `168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8`;
- gap-preparation manifest
  `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935`;
- independent H01 gap manifest
  `79ee4818d7f3967827a6412f8537196e84ee7a6ccc1b8d2c5e9dd3124ed44b47`;
  and
- repair-evidence manifest
  `81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018`.

All 16 direct input hashes passed. Primary availability is 702 of 816 near-eye
days from 137 participants and 732 of 902 chest days from 152 participants.
Corrected gap-timing-unaware availability is 687 of 811 near-eye days from 137
participants and 723 of 897 chest days from 152 participants. Every retained
gap value is finite and strictly positive. The old THUAS chest zero is now
missing with no viable momentary ratio; no task-local repair was made.

## METRIC-010 production result

The selected primary model is Gaussian identity with site fixed effects, the
context predictor, and a participant random intercept. Student-t identity is
the mandatory heavy-tail sensitivity. Exact primary near-eye estimates are:

| Contrast | Gaussian estimate (95% CI) | Student-t estimate (95% CI) | Exact sample |
|---|---:|---:|---:|
| Free day minus Work day | -0.0013 (-0.0134 to 0.0108) | -0.0006 (-0.0093 to 0.0082) | 679 days / 136 participants / 9 sites |
| Active minus Sedentary | 0.0083 (-0.0070 to 0.0235) | 0.0034 (-0.0076 to 0.0144) | 645 / 133 / 9 |
| +1 h previous-night sleep | 0.0017 (-0.0028 to 0.0063) | 0.0032 (-0.0001 to 0.0065) | 679 / 136 / 9 |

The raw primary common-association p-values are 0.830, 0.275, and 0.483. Raw
site-heterogeneity p-values are 0.005, 0.053, and 0.778. None has an adjusted
decision: each applicable BH family currently contains only the MDER slot of
15 required metric slots, so all adjusted p-values remain missing.

Gaussian Q--Q correlations are 0.870--0.879, while Student-t quantile-residual
Q--Q correlations are 0.997. Student-t shifts are 0.125--0.645 primary
standard errors. The Gaussian results are reportable only with an explicit
heavy-tail limitation and mandatory Student-t sensitivity.

True one-day residual screens triggered actual-date AR(1) counterparts through
site maxima around 0.39. Their rho values were -0.742, -0.706, and -0.757 and
their effect shifts were 0.056, 0.020, and 0.015 primary standard errors. All
carried an automated structured-covariance singularity flag despite finite
variance components, so they are retained as stability sensitivities only.

All 405 participant-deletion and 27 site-deletion refits completed. Maximum
participant shifts were 0.30--0.71 standard errors; maximum site shifts were
1.05--1.22. Work/free reversed under deleting KNUST, MPI, or RISE; sleep
reversed under deleting IZTECH. Their magnitudes/CIs are reportable without a
stable cross-site directional claim. Activity had no direction reversal but
retains a site-generality limitation.

The exact registered random-site/random-slope work/free and activity formulas
were estimable as benchmarks only. The sleep benchmark was singular with a
random-site correlation of 1.000 and is non-estimable; it was not simplified.

The corrected all-available gap near-eye Gaussian estimates are:

| Contrast | Estimate (95% CI) | Exact sample |
|---|---:|---:|
| Free day minus Work day | -0.0016 (-0.0140 to 0.0108) | 664 days / 136 participants / 9 sites |
| Active minus Sedentary | 0.0090 (-0.0066 to 0.0246) | 630 / 133 / 9 |
| +1 h previous-night sleep | 0.0018 (-0.0028 to 0.0065) | 664 / 136 / 9 |

All selected intervals include zero. Student-t shifts are 0.111, 0.543, and
0.651 Gaussian standard errors; the Student-t sleep interval is 0.000003 to
0.006710, only just above zero, and is disclosed as tail-model sensitivity.
Raw gap association p-values are 0.804, 0.245, and 0.470; raw heterogeneity
p-values are 0.005, 0.046, and 0.808. All six affected 15-slot families remain
incomplete at 1/15, so no adjusted p-value or adjusted decision exists.

All selected and Student-t gap fits passed the bounded diagnostics with the
explicit Gaussian heavy-tail limitation. Actual-date AR(1) shifts were
0.019--0.061 standard errors; all AR fits retain the structured-covariance
singularity flag and remain stability sensitivities. The gap sleep registered
random-slope benchmark is singular at correlation 1.000 and non-estimable.

Exactly 24 MDER-dependent frames were refreshed: 18 gap frames and six
primary--gap common-sample frames. Twelve primary all-available or
placement-paired frames and 12 frozen-result domains passed preservation
checks. No primary all-available, placement-paired, or deletion model was
refitted; the six primary--gap common-sample fits were necessarily updated.

The METRIC-010 report is
`audit/hypotheses/H06_daily/05_mder_metric010_amendment.qmd` with self-contained
HTML. Its primary forest plot has PNG/PDF/SVG exports, paired source data, alt
text, and passing final-size QA.

## Bounded non-MDER daily AR-repair pilot

The post-MDER current sources and the two frozen Stage 2 pilot frames were
compared before fitting. The pre-sleep and positive-L10 frames have identical
ordered participant-day keys, values, columns, and factor levels. MDER was not
opened, refitted, or revised.

The non-MDER pilot remains pinned to its fit-time sources and has not been
refitted. Its directly used near-eye participant-day source remains
byte-identical at `fb04a84f...`, and both task-owned frames and all outputs
match their fit-time hashes. The coordinator's later current base/gap delivery
was consumed only by the bounded MDER refresh above; it does not retroactively
rewrite the historical non-MDER pilot manifests or authorize another repair
fit.

The pilot fitted exactly one independent `glmmTMB` Gaussian calibration and one
actual-date, gap-aware AR(1) counterpart for each of two frames. Every missing
calendar date starts a new participant sequence; observed dates are not
compressed across gaps. The AR formula adds
`ar1(day_index_factor + 0 | day_sequence_id)` to the fixed-site predictor model
with participant random intercept.

Both repairs are **NOT_ACCEPTABLE** under the prespecified complete gate:

- Pre-sleep duration × previous-night sleep used 648 days, 139 participants,
  nine sites, and 450 true adjacent-day pairs. Its AR effect retained direction
  and shifted by 0.130 frozen-model standard errors. Temporal, distributional,
  bounds, and structured-covariance screens passed, but the fit returned
  false-convergence code 8, two warnings, and a non-positive-definite Hessian;
  residual SD collapsed to `8.8e-05 h`. No result was promoted.
- Positive L10 magnitude × work/free day used 680 positive-component days, 140
  participants, nine sites, and 484 pairs. Its AR effect retained direction and
  shifted by 0.897 standard errors. The fit returned singular-convergence code
  7, rho at 1.000 to displayed precision, pooled post-AR lag-1 of -0.491,
  maximum absolute site lag of 0.932, and Q--Q correlation of 0.808. Numerical,
  covariance, AR-coefficient, temporal, and Gaussian-distribution domains all
  failed.

The full 784-day representative L10 frame contains 104 exact zeros and three
additional strictly positive values of `4.163336342344337e-17 lx`. Exact-zero
splitting retains those rows in the positive component and maps them to
-16.381 under `log10()`. H06_daily did not threshold, round, delete, or
reclassify them. Their intended scientific status was referred to the shared
metric owner in `audit/handoffs/H06_daily_shared_change_request.md`; that hold
was later resolved by the controlling METRIC-011 delivery described below.

The coordinator subsequently finalized that provenance rule, independently
verified the eight affected cells, rebuilt the shared primary artifacts, and
issued targeted H06_daily repinning instructions. The historical pilot remains
unchanged; the replacement L10 analysis is a separate amendment below.

The gate report is
`audit/hypotheses/H06_daily/06_daily_ar_repair_pilot.qmd` with self-contained
HTML. It contains no association p-value, multiplicity result, bootstrap,
simulation, deletion batch, or remaining-grid fit.

## Bounded pre-sleep no-nugget diagnostic

The author approved exactly one pre-sleep AR diagnostic with the unchanged
648-day frame and `dispformula = ~0`. Static reconstruction remained identical
at 648 participant-days, 139 participants, nine sites, and 450 true adjacent-
day pairs. The one model fit took 0.243 seconds; no L10, MDER, independent,
remaining-grid, bootstrap, simulation, or deletion fit was run.

The model converged with a positive-definite Hessian, no warnings, and no
singularity. Rho was -0.085; the coefficient retained direction and shifted by
0.130 frozen-model standard errors. Pooled residual lag-1 was -0.135 and the
largest absolute site lag was 0.276. Distributional and physical-bounds checks
passed.

The preliminary audit incorrectly counted glmmTMB's fixed mapped dispersion
value as free. A no-refit finalizer verified `dispformula = ~0`, an all-`NA`
dispersion parameter map, no dispersion term in the optimized vector, and the
package-fixed residual SD of 0.000122070 h. Correcting only the two derived
verdict rows yields **ACCEPTABLE**; no fitted or diagnostic quantity changed.
The author approved **H06-D-G2P-AR-NN** on 2026-08-11. The result is closed and
frozen as a temporal-stability sensitivity, not an association claim.

The initial fit process deserialized the sealed historical composite checkpoint
at SHA-256
`024ca6d5f51d8d5e80ed3f597a4faf93c4ce96697cf88496f782a059f9b9fdf4`
and accessed only `$fits$pre_sleep_identity`; it never accessed the historical
L10 member. Before report finalization, that exact pre-sleep member was sealed
as the standalone reference
`artifacts/07_models/H06_daily/H06_daily_pre_sleep_only_historical_reference.rds`
(SHA-256
`2c5534516d398f7eef01e5d43ff151cfc88303b8937f8280f91c871b5fd2b98a`).
Its version-3 serialized bytes are exactly identical to the parent member. The
repaired controlling input manifest pins the standalone pre-sleep frame and
reference; the initial composite deserialization remains explicitly disclosed.
This was a no-refit provenance-container repair and created no analytical L10
dependency.

## METRIC-011 L10 amendment

The shared METRIC-011 decision is final at SHA-256
`23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`,
with independent evidence manifest
`a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`.
Exactly eight primary L10 mean cells changed from machine-precision remnants to
exact zero: three near eye and five chest. Every non-L10 scientific value and
all gap-timing-unaware L10 scientific values are unchanged.

H06_daily completed only the already-prespecified L10 branch: three predictors
across primary near-eye/chest all-available, placement-paired/common near-eye/
chest, and gap-timing-unaware near-eye/chest scenarios. Exact zeros remain in
the binomial zero-occurrence component and are excluded only from the
`log10(L10)` strictly positive magnitude component.

All three primary near-eye occurrence models are non-estimable because of
complete or quasi-complete separation. UCR has no zero L10 day in either
work/free category, either activity category, or across its observed
sleep-duration support. The triggered work/free occurrence AR counterpart also
failed at rho -0.999964. Therefore all six primary and all six gap near-eye
joint association/site-heterogeneity tests are
`NON_ESTIMABLE_COMPONENT_FAILURE`; raw and BH-adjusted p-values are missing.
L10 remains slot 3 in every 15-slot family. No component or regularized result
substitutes for the failed joint slot.

Primary positive-only Gaussian ratios are 0.925 (0.759 to 1.128) for Free
versus Work day, 0.864 (0.674 to 1.107) for Active versus Sedentary, and 0.775
(0.722 to 0.832) per one hour longer previous-night sleep. These condition on
L10 greater than zero and are descriptive only. Work/free reverses direction
under the Student-t sensitivity with a 1.35-SE shift; activity shifts 1.04 SE
after deleting MPI; and the sleep Student-t fit fails its numerical gate, so
its nominal interval is withheld. All displayed intervals are pointwise.

The authorized normal-prior occurrence MAP fits at standard deviations 1.5,
3, and 6 are diagnostic sensitivities only. They carry no ordinary confidence
interval, p-value, BH entry, or significance decision. The exact registered
random-site/random-slope occurrence models remain benchmarks and were not
promoted.

Production completed 18 analyses serially in 156.67 seconds. A 50-refit pilot
preceded the 440-refit positive-only deletion batch, which completed serially
in 38.76 seconds with no failures. No occurrence or joint deletion model was
run. A no-refit finalizer preserved all 194 fitted-model subobjects exactly;
all 294 pre-existing protected H06_daily files, including the closed pre-sleep
branch, passed byte-for-byte preservation.

The separate report is
`audit/hypotheses/H06_daily/08_l10_metric011_amendment.qmd` with self-contained
HTML. The transition is
`audit/hypotheses/H06_daily/H06_daily_l10_metric011_transition.md`. The author
accepted **H06-D-G2P-L10-METRIC011** exactly as recommended on 2026-08-12
under H06-D-002 / CHG-109. The controlling acceptance SHA-256 is
`5c1e7204e9bdd7f76ffbb0f960f2505ac5a4b23a4c94018d0dff3a33fcf4d9ea`;
the independent H06-D-001 verification SHA-256 is
`e6816a31b5253675c93ab7f3cacac7f2d415d4fd7159762475fa65bf2a142c28`.
The gate is closed and frozen; the remaining daily grid is still frozen.

## Compute and reproducibility

The family pilot used three primary near-eye predictor frames. A 50-deletion
production-code pilot had no failures and projected the full 432-refit
influence batch at about 0.19 minutes. The full production script completed in
31.3 seconds. The targeted 24-frame MDER refresh completed in 11.7 seconds. No
bootstrap or heavy resampling was used. The later L10 amendment runtimes are
reported separately above and were serial.

All scientific calculations ran under R 4.6.1 in the synchronized project
library. Focused tests verify the exact input, code, output, report, figure, and
software manifests. No shared preparation, central ledger, Quarto
configuration, manuscript, bibliography, `renv.lock`, main-H06 output, commit,
push, upload, or website integration was changed or requested.

## Current stop gates and next decisions

The original primary H06-D-G2-MDER decisions remain approved. The obsolete
one-zero comparator qualification is superseded by the corrected shared gap
rebuild and is not retained as a current result.

The author approved **H06-D-G2-MDER-GAP** on 2026-08-11 after reviewing:

1. corrected gap availability and exact fitted samples;
2. the three selected estimates and explicit heavy-tail limitation;
3. disclosure of the near-zero Student-t sleep lower bound as sensitivity;
4. raw heterogeneity slots without BH decisions;
5. singular AR and registered-benchmark dispositions; and
6. the frozen-primary preservation boundary.

That approval closes and freezes the corrected MDER branch without authorizing
any further fit. The original non-MDER repair gate authorized one bounded
no-nugget diagnostic and classified the three L10 numerical remnants as zero.
The author approved **H06-D-G2P-AR-NN** as recommended on 2026-08-11. The
accepted disposition is to:

1. accept the no-nugget pre-sleep AR counterpart as an acceptable temporal-
   stability sensitivity without promoting a separate association claim;
2. accept the transparent no-refit parameter-map audit correction;
3. consume the later finalized METRIC-011 artifacts only through a distinct,
   bounded L10 amendment; and
4. keep the remaining daily production grid frozen throughout that amendment.

The bounded no-nugget branch is closed and frozen. The author accepted the
distinct L10 amendment exactly as recommended at
**H06-D-G2P-L10-METRIC011**. All 12 joint L10 slots remain
`NON_ESTIMABLE_COMPONENT_FAILURE` with missing raw and BH-adjusted p-values;
positive-only and MAP results remain descriptive diagnostics, and no hierarchy
substitution is authorized. A one-part `log10(L10 + 0.1 lx)` model could avoid
the separated occurrence component only by changing to an unconditional
shifted-log estimand; it is not promoted by this acceptance and would require
a new explicit author amendment.

No further fit, remaining-grid work, Stage 3/4 output, site integration, main
H06 change, or final H06 version selection is authorized. H06_daily remains
stopped after the bounded no-refit gate closure.

## H06-D-015 Stage 3 reader completion

The later controlling transition is `H06-D-015 / CHG-133`, recorded in
`audit/decisions/h06_daily_stage2_acceptance_stage3_transition.md` at SHA-256
`26e3cf5302db74156a2ad929a80a1352eac6967ccf0e0e1adb5cdcfa71b9954e`.
It accepts the targeted gap clock-hour repair and authorizes only the compact
complementary Stage 3 report. This section supersedes the older stop boundary
immediately above; it does not alter any historical result.

All 12 pre-acceptance H06-D-015 identities and the five central ledger
snapshots passed the bounded R 4.6.1 intake check. The task-owned accepted
transition is now SHA-256
`ac34798ac197ea9207b04c2f0c53dcf1bf62351d7157ce0f3273890e63a1e787`.
The Stage 3 input contract contains 23 verified identities.

The standalone complementary reader report is:

- source: `notebooks/hypotheses/H06_daily.qmd`, SHA-256
  `9dc418b1124c44faf391d47687d69ac225b39b1ddc806010bc11ca56c0f35707`;
- focused HTML: `notebooks/hypotheses/H06_daily.html`, SHA-256
  `c6d61d684d76e1e8bcc9bc66b8d567cd51bcfa1eddee2266d7e2143950917d70`.

It identifies the completed hourly H06 report as the main analysis and the
participant-day analysis as complementary preregistration-oriented evidence.
It contains the required visible **Answer in brief** callout, one row per
metric-specific participant-day estimand, the three approved predictors,
primary/chest/paired/gap roles, exact fitted samples, pointwise 95% confidence
intervals, and all 12 fixed 15-slot FDR families. Dynamic `.qmd` links point to
the main H06 report and the preregistration-deviations page. The report contains
no V0 or construction-history language.

The reader bundle contains 45 complete primary rows, 180 placement rows, 45
gap-timing-unaware rows, 12 family summaries, and the exact three primary/gap
FDR decision changes. L10 mean remains non-estimable with raw and adjusted
p-values missing in every relevant slot; no positive-only, MAP, or shifted-log
result substitutes for it. The accepted MDER estimates remain unchanged and
none of their primary 95% intervals excludes zero.

All 468 non-L10 cells remain usable with limitations, with zero hard or gross
residual failures. The report retains the AR, response-family, deletion-
influence, and participant-cluster HC3 interaction qualifications. It names the
1.23-HC3-SE first-light Work/Free Student-t shift and the 1.26-HC3-SE L10-
midpoint activity AR shift; timing predictor-by-site results remain sensitivity
dependent.

Three reader figures have nonempty alt text and paired source-data CSVs. The
two accepted forest plots and the new FDR overview passed original-resolution
checks for label and interval legibility, panel balance, legends, clipping,
and overlap. The rendered HTML has one reader title, 10 compact `gt` tables,
three embedded image payloads, and the required callout. Automated visual
inspection of the local HTML itself was unavailable because the in-app browser
blocked `file://` access; no workaround was used. This disclosed limitation is
recorded separately from 10 passing rendered-DOM and figure-QA checks.

Stage 3 sealing identities are:

- input manifest:
  `9b414843cd06a09b029badb4d01392ea7f70ab429c81eb4abfd5762c0cd2eee2`;
- 11-entry source-data manifest:
  `46d4b807a7a2ece77720e372fd47be634b095a0b64233f457f0f2db4a46f50ae`;
- 12-entry software manifest:
  `e477eec236d49e54be05c40082a1e6a76abab3359decfb17b0ca6b6d19575727`;
- figure readability QA:
  `8b2adec6abe8d36e049764a71290893fdbaa170951c8487c6846b82d5db5fb0c`;
- render QA:
  `a2c5751d392cf25bbae67122b90cfb504ff64740abd68be1b9f849f304ff1ec7`;
- 26-entry non-circular output manifest:
  `791dc7975c10d5ee7fcbaf0d4b3df378b92d9155ae5701f425c1ff99330b8709`;
- focused test:
  `b9d70221170ad3826d2b42bd0f02400dffa1a956bb435cbef2be25c38c3b788d`.

The fresh focused test passed under R 4.6.1 and verifies every displayed raw
p-value, FDR q-value, decision, fixed slot, source-data identity, figure pair,
HTML structure, and non-circular manifest identity against the accepted Stage
2 rows. No model was fit or refit, and no raw or adjusted p-value was
reconstructed.

## H06-D-G3 author decisions requested

Please decide whether to:

1. accept the standalone complementary framing and **Answer in brief**;
2. accept the complete primary, placement, and gap display with the unchanged
   12 fixed 15-slot families, non-estimable L10 slot, and unchanged MDER result;
3. accept the exact three primary/gap FDR decision changes as sensitivity
   evidence rather than replacement estimates;
4. accept the retained residual, AR, response-family, influence, and HC3
   interaction limitations and the disclosed local-browser QA boundary; and
5. close H06-D-G3 or provide bounded reader-report revisions.

Stage 4 remains a separate, lean preparation/provenance companion and is not
authorized by completion of Stage 3. Website integration, shared configuration,
main-H06 changes, manuscript edits, scientific recomputation, commit, and push
remain blocked.

## H06-D-G3 revised Stage 3 reader handoff

The author requested a bounded revision before accepting Stage 3. The revised
standalone report now:

1. uses a simple note callout with no icon for **Answer in brief**;
2. reports all ten primary FDR-supported site-interaction blocks and identifies
   the pointwise-clear site contrasts;
3. replaces the repeated primary tables with one three-context primary matrix
   and keeps complementary placement, gap sensitivity, joint exploratory, and
   temporal exploratory results in separate sections;
4. adds a common-sample mutually adjusted participant-day analysis containing
   day type, activity, and previous-night sleep;
5. adds the accepted 30-minute temporal GAMM results and paired-source figure;
   and
6. compares daily mean melEDI with the selected main hourly H06 analysis while
   preserving their distinct estimands and weighting.

The exploratory joint-context implementation evaluates one site-by-context
block at a time while retaining the other two contexts additively. It contains
six separate 15-slot BH families, 14 estimable metrics per family, and the
unchanged named L10 slot. The common-sample stability audit classified 34
estimates as stable, seven as substantial limitations, one as unstable or
direction-reversing, and three named L10 entries as not estimable. No accepted
primary or gap p-value, q-value, decision, L10 result, or MDER result changed.

The revised primary site display decomposes each of ten globally supported
interaction blocks into the equal-site comparison/reference ratio and nine
site adjustment factors. Every adjustment factor is the full site-specific
ratio divided by the equal-site ratio, so the full ratio is recovered by
multiplication. Across 90 factors, 13 pointwise intervals were below 1, 11 were
above 1, and 66 included 1. All intervals remain unadjusted and descriptive
within a globally FDR-supported interaction block. Every site mention begins
with a filled dot in the submitted site colour.

For mean melEDI, the equal-site Free/Work ratio is 0.70 (95% CI 0.63 to 0.78).
Delft is pointwise above that average, adjustment 1.36 (1.01 to 1.83), while
Madrid, 0.71 (0.56 to 0.90), and Kumasi, 0.57 (0.43 to 0.76), are pointwise
below it. The remaining six intervals include 1. A new ten-panel forest plot
shows all 90 site adjustments on a common log scale with pointwise 95% CIs,
submitted site colours, paired source data, and alt text.

The selected main-H06 comparison now uses interaction-model effects wherever
the relevant global interaction is supported. The four selected interaction
cells are main-hourly work/free day, predictor-specific daily work/free day,
predictor-specific daily activity, and mutually adjusted daily work/free day.
Their displayed estimates are equal-site full contrasts, with the range of
the nine full site-specific ratios. The additive-family association q-value
remains the prespecified association test; the interaction q-value determines
which effect model is displayed.

The temporal display contains four whole-function summaries from the accepted
primary near-eye GAMM and the existing context-function figure. It uses
pointwise intervals only. No GAMM was refit.

Current standalone reader identities are:

- QMD: `0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc`;
- HTML: `5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3`;
- 20-entry revision input manifest:
  `68bae924880443265dcf6f5ec7e2d109a7c80bae9edd45e93aaf39ef517f977d`;
- primary site summary:
  `fcf06bc9247f318d6db5fa7e82c6a4cf4524a7a75dd24193fe6aa1391bcd8a0a`;
- 90-row site-deviation figure source:
  `12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc`;
- site-deviation PNG:
  `69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c`;
- conditional joint site summary:
  `4db3fe18bf25e2db21c535bc08858058be757ad8d6970d94f76577c188aec130`;
- main hourly comparison:
  `933840342a8bbc97a579eeb27efcbdc5c26f608b280c2b3aae124b9c8d9246d3`;
- temporal GAMM summary:
  `e65b6ddafaaf200ae90890a7cecc211527cfc00fab96812951828809718b7829`.

Both focused R 4.6.1 tests pass. The revised reader test covers 14 tables,
90 site-to-equal-site adjustments, 144 submitted-colour site markers, and five
embedded figures with nonempty alt text and paired source data. Five of five
original-resolution figure inspections pass. Rendered-DOM QA passes 17 checks
and records one disclosed
limitation because the in-app browser blocked
automated local `file://` access. No workaround was used.

The bounded gate record is
`audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md`. H06_daily is
stopped at **H06-D-G3** for explicit author review. Stage 4, website or shared
configuration changes, manuscript edits, further scientific computation,
commit, and push remain unauthorized.
