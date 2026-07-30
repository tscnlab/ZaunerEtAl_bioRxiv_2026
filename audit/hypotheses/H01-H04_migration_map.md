# H01–H04 canonical migration map

Status: read-only code and claim map; implementation and clean reruns pending  
Prepared: 2026-07-30  
Baseline branch commit: `20ba43c27e69fd952ce8023770538f2aa843ef5e`  
Primary placement: near-eye (`glasses`)  
Complementary placement: chest, preferably on paired/common samples  
Pooling decision: rejected

## Purpose and authority

This document maps the current H01–H04 implementations into the canonical
hypothesis notebooks without treating the current implementation as an
authority for the scientific result. It separates:

1. the signed preregistration contract;
2. the behavior of the current code;
3. known and newly confirmed implementation defects; and
4. the proposed repaired specification and the comparisons needed before a
   result or claim can be accepted.

This is not a model-result approval. Numerical values quoted below describe
the current rendered or saved baseline only. They must not be copied into the
Nature Health manuscript until the clean canonical rerun, result-difference
audit, and applicable major-result gates are complete.

The governing records are:

- `audit/evidence/preregistration_contract.md`;
- `audit/ledgers/hypothesis_contracts.csv`;
- `audit/ledgers/deviation_register.csv`;
- `audit/decisions/metric_validity.md`;
- `audit/decisions/metric_implementation_parameters.md`;
- `audit/decisions/placement_decision.md`;
- `audit/findings/timestamp_dst_fallback.md`; and
- `audit/findings/state_precedence_and_channel_mask.md`.

If this map conflicts with a later approved decision record, the later
decision record controls and this map must be updated before implementation.

### Static-verification note

Numerical inspection for this map used R 4.6.1 with the project library and
`emmeans` 2.0.3. It loaded the hashed baseline
`metrics_glasses.RData`, `metrics_separate_glasses.RData`,
`metrics_separate_chest.RData`, and `H1_results.RData` objects to enumerate
metric/model rows, factor levels, and saved bin counts. It also inspected the
registered default adjustments of the `emmeans` contrast generators used by
the current code. No hypothesis model was refit and no baseline result was
adjudicated from a non-R calculation. H03/H04 displayed counts and claims
were traced from the current source and rendered Quarto output.

## Shared migration rules

### Canonical artifacts and scenarios

Each notebook consumes exactly one explicit model-data object:

- `notebooks/hypotheses/H01.qmd` consumes
  `artifacts/06_model_data/H01.rds`;
- `notebooks/hypotheses/H02.qmd` consumes
  `artifacts/06_model_data/H02.rds`;
- `notebooks/hypotheses/H03.qmd` consumes
  `artifacts/06_model_data/H03.rds`; and
- `notebooks/hypotheses/H04.qmd` consumes
  `artifacts/06_model_data/H04.rds`.

Every object must carry the placement, scenario, producer, input hashes,
variable dictionary, factor levels, inclusion flags, exclusion reasons, and
sample-flow data needed to reproduce it. The notebooks must not call
`load()`, download data, install packages, mutate shared global objects, or
read an earlier hypothesis workspace.

The same parameterized implementation is used for:

1. `placement = "glasses", scenario = "primary"`;
2. `placement = "glasses", scenario = "paired_common_sample"`;
3. `placement = "chest", scenario = "paired_common_sample"`; and
4. any separately registered complementary chest scenario.

The all-chest sample may be shown as supplementary contextual evidence, but
it is not a larger ocular-exposure sample. No H01–H04 model pools placement
records or estimates a universal chest-to-glasses conversion.

### Common preprocessing inherited by H01–H04

The canonical model data must inherit, and expose rather than silently
recompute, the following approved rules:

- true `datetime_utc` is used for keys, ordering, durations, gaps, and
  adjacency;
- `datetime_wall` is the common local-clock coordinate for clock-time
  cutoffs, profiles, and time-of-day models;
- repeated fall-back wall-clock bins are averaged only for clock-aligned
  analyses, with the number of source intervals, offsets, and fold status
  retained;
- the sleep diary interval from attempted sleep (`sleepprep`) through wake is
  authoritative;
- wear-log `sleep` is provenance only;
- only wear-log `off` outside the diary sleep interval is invalid non-wear;
- analytical MEDI and LIGHT receive the same invalid-nonwear mask, while raw
  channels are retained;
- one-minute MEDI values are retained only below \(10^5\) lx; values at or
  above \(10^5\) lx are invalid;
- participant-days first satisfy the registered 50%-per-hour and 80%-per-day
  rules; metric-specific support then produces a value or a reason-coded
  missing value without discarding an otherwise useful day; and
- sleep-period observations describe the bedside sleep environment, not
  worn ocular exposure.

H02 uses the approved 30-minute arithmetic-mean outcome with at least 15
valid one-minute observations. H03 and H04 use the distinct one-hour
zero-aware geometric-mean outcome with at least 30 valid one-minute
observations. These outcomes must never be substituted for one another
without an explicit result-difference comparison.

### Common inferential and reporting rules

- Fit comparisons use identical rows. A comparison must fail if model-frame
  keys differ.
- Gaussian mixed models that differ in fixed effects are compared under
  maximum likelihood; REML may be used for the final estimation fit after
  the structure is fixed.
- Every multiplicity family is a complete vector assembled before
  `p.adjust(..., method = "BH")` is called. Raw p-values, family identifiers,
  family sizes, ranks, and adjusted p-values are retained.
- An omnibus test is distinguished from reference contrasts and from
  site-by-context heterogeneity. A test that adds a main effect and all
  interactions simultaneously is not reported as a main-effect test.
- Estimates are reported in practical units with intervals. P-values do not
  replace estimates or intervals.
- Marginal and conditional \(R^2\) may describe a full mixed model.
  Differences between marginal-\(R^2\) values from overlapping models are
  not an additive variance decomposition.
- All participant, participant-day, hour, site, placement, and category
  denominators are reported for the actual model frame.
- Diagnostics, warnings, source-data CSVs, and model summaries are durable
  artifacts. An interactive `check_model()` plot is not sufficient.
- Every current claim listed below is reopened automatically if its estimate,
  interval, adjusted inference, model sample, or interpretation changes.

## Source-to-canonical map

| Unit | Current near-eye implementation | Current chest implementation | Canonical destination |
|---|---|---|---|
| H01 | `RQ1.qmd:74-548`; helpers in `scripts/fitting.R`, `scripts/summaries.R`, and `scripts/H1_specific.R` | `RQ1_chest.qmd:71-547`, near-literal copy with chest inputs and output paths | `notebooks/hypotheses/H01.qmd` |
| H02 | `RQ1.qmd:549-1004` | `RQ1_chest.qmd:548-1003`, near-literal copy; no chest interpretation text | `notebooks/hypotheses/H02.qmd` |
| H03 | `RQ2.qmd:87-825`, including the GLMM and exploratory temporal GAM; helpers in `scripts/RQ2_specific.R` and `scripts/helpers.R` | `RQ2_chest.qmd:84-826`; additionally forces exclusion of outdoor electric light | `notebooks/hypotheses/H03.qmd` |
| H04 | `RQ2.qmd:826-1577`, including the GLMM and exploratory temporal GAM | `RQ2_chest.qmd:827-1578`, near-literal copy with chest inputs and output paths | `notebooks/hypotheses/H04.qmd` |

Duplicate near-eye/chest source must remain until canonical equivalence is
demonstrated. After equivalence, the old RQ and chest hypothesis code can be
retired as duplicated producers; its hashed baseline remains in the audit
record.

# H01: Site differences in personal light-exposure metrics

## Preregistered contract and current estimand

The signed hypothesis is that personal light-exposure metrics differ among
sites after accounting for latitude and, for applicable duration metrics,
photoperiod. The registered participant structure is a participant nested in
site random intercept. The registered placement was chest with a glasses
repeat; the approved ocular estimand reverses that placement order.

Site and latitude cannot be estimated jointly as unrestricted fixed effects
because each site has one latitude. The current analysis therefore estimates
a site model and a latitude model separately. That deviation is retained as
an audit target, not hidden as though it had been preregistered.

## Exact current input and filtering

### Inputs

- Near-eye: `data/metrics_glasses.RData`, object `metrics_glasses`.
- Chest: `data/metrics_chest.RData`, object `metrics_chest`.
- Both are produced in `metric_preparation.qmd` from the multi-object
  `metrics_separate_*.RData` and `preprocessed_*_2.RData` workspaces,
  participant metadata, site coordinates, and mean photoperiod.

The saved metric table has 22 rows: two participant-level dynamics metrics
and 20 participant-day metrics. The H01 code left-joins a hand-written model
specification table and retains the 17 rows with a non-missing response
specification. No explicit, immutable H01 inclusion flag exists. Each model
silently uses the complete cases accepted by its fitting engine.

The five saved rows not modelled in H01 are the M10 onset and offset, L10
onset and offset, and unqualified full-day duration above 250 lx. The
canonical 17-member H01 set is:

1. interdaily stability;
2. intradaily variability;
3. full-day geometric mean MEDI;
4. M10 mean;
5. L10 mean;
6. duration above 1,000 lx;
7. duration above 250 lx during wake;
8. duration below 10 lx during pre-sleep;
9. duration below 1 lx during diary-defined sleep;
10. longest continuous period above 250 lx;
11. M10 midpoint;
12. L10 midpoint;
13. mean timing above 250 lx;
14. first timing above 250 lx;
15. last timing above 250 lx;
16. daily MEDI dose; and
17. MDER.

Current saved metric objects already reflect earlier 50% hourly and 80% daily
filtering, but they do not implement the newly approved metric-specific
support, gap, state-channel, DST, dose, MDER, M10/L10, circular-timing, or
\(10^5\)-lx rules. Canonical H01 therefore consumes newly derived metrics,
not these `.RData` objects.

### Current per-metric response and family map

| Metrics | Current response | Current engine/family |
|---|---|---|
| Interdaily stability | `qlogis(metric)` | `lm`, Gaussian |
| Intradaily variability | `metric` | `lm`, Gaussian |
| Full-day mean, M10 mean, L10 mean, dose, longest period above 250 lx | `log_zero_inflated(metric)` | `lmer`, Gaussian |
| MDER | `metric` | `lmer`, Gaussian |
| Duration above 1,000 lx; above 250 lx during wake; below 10 lx pre-sleep; below 1 lx during sleep | `metric` | `glmmTMB`, Tweedie with log link |
| M10 midpoint, L10 midpoint, mean/first/last timing above 250 lx | decimal clock hour as `metric` | `lmer`, Gaussian |

The current timing treatment centers L10-related times around midnight in
`metric_preparation.qmd`, but other clock times enter as ordinary decimal
hours. It does not verify that the linearization cut is away from the
observed support.

## Exact current model formulas and reference handling

For a participant-level dynamics outcome \(y\):

```text
H1_1:    y ~ site + photoperiod
H1_0:    y ~ photoperiod
H1_lat:  y ~ latitude + photoperiod
H1_phot: y ~ site
```

For a participant-day outcome:

```text
H1_1:    y ~ site + photoperiod + (1 | site:Id)
H1_0:    y ~ photoperiod + (1 | site:Id)
H1_lat:  y ~ latitude + photoperiod + (1 | site:Id)
H1_phot: y ~ site + (1 | site:Id)
H1_rand: y ~ photoperiod + (1 | site/Id)
```

`(1 | site/Id)` expands to a site random intercept plus the participant
within-site intercept already present in the null model. There is no random
site comparison for the participant-level dynamics outcomes.

Current site factor levels begin with `BAUA`, which is therefore the internal
treatment reference unless a fit overrides it. The displayed site effects,
however, are created afterward with `emmeans(~ site) |> contrast()` and are
effect contrasts against the equally weighted site mean. The displayed
intercept is also an equal-site estimated marginal mean. Latitude is shown
per 10-degree increase only by multiplying the table coefficient after model
fitting. Photoperiod is in hours and is not centered.

## Exact current fitting, comparisons, and multiplicity

- `lm`, `lmer`, or `glmmTMB` is selected from the hand-written model table.
- `lmer` is called with its default `REML = TRUE`.
- Nested tests use `anova(model0, model1)`. `anova.merMod` may refit with ML
  for the likelihood-ratio test, but the separately generated `AIC()` table
  uses the stored REML fits.
- Site is tested with `H1_0` versus `H1_1`.
- Latitude is tested with `H1_0` versus `H1_lat`.
- Photoperiod is tested with `H1_phot` versus `H1_1`.
- A site random intercept is tested with `H1_0` versus `H1_rand`.
- AIC values are collected for the null, site, site-without-photoperiod,
  latitude, and random-site formulations even though some stored Gaussian
  fits have different fixed effects under REML.
- Each extracted p-value is passed separately to
  `p.adjust(p, method = "fdr", n = 17)`.

The last operation is not vector-wide Benjamini–Hochberg adjustment. For a
length-one input with `n = 17`, it behaves as if the other 16 p-values were
one and returns the Bonferroni-like value `min(17 * p, 1)`. A correct H01 BH
calculation first assembles the 17 raw p-values for a declared family and
then adjusts that vector once.

## Current outputs and claims

Current durable outputs are:

- `data/H1_results.RData` and `data/H1_results_chest.RData`;
- `tables/H1.png` and `tables/chest/H1.png`;
- `tables/H1_R2_tbl.png` and `tables/chest/H1_R2_tbl.png`; and
- manually copied counterparts under `assets/` used by `index.qmd`.

The current main manuscript claims, among other things, that:

- level- and timing-based metrics differ by site after photoperiod
  adjustment;
- latitude models fit overall and daytime level outcomes better than site
  models;
- photoperiod predicts most metrics;
- conditional \(R^2\) spans roughly 25%–62%;
- participant differences often exceed fixed-effect contributions; and
- chest findings are broadly consistent with the primary results.

These are reopened claims. The current table omits intervals for many
reported practical estimates, and the manuscript receives manually copied
assets rather than an authoritative produced artifact.

## Confirmed defects and risks

1. **Scalar multiplicity error (`IMP-001`).** H01 adjusted p-values are not
   vector-wide BH values.
2. **Conditional-\(R^2\) branch error (`IMP-004`).** The current code selects
   `H1_0_r2$R2_conditional` whether or not the site model is selected.
3. **Invalid REML AIC comparison (`IMP-010`).** Stored REML models with
   different fixed effects enter the same AIC table.
4. **Non-identifiable registered site-plus-latitude formula (`DEV-009`).**
   The current separate-model workaround is necessary, but its latitude
   model omits a site-level grouping term even though latitude varies only at
   site level. Participant-days must not create fictitious independent
   latitude replication.
5. **Overlapping \(R^2\) differences.** Subtracting marginal or conditional
   \(R^2\) values from several overlapping models does not uniquely
   decompose variance into site, photoperiod, latitude, participant, and
   residual shares.
6. **Unverified response families and circular timing.** Current
   transformation/family choices are hand-entered, and ordinary Gaussian
   clock-hour models can be cut-point dependent.
7. **Metric provenance changes.** Approved repairs to the saturation limit,
   dose, MDER, M10/L10, timing, continuity, DST, state masking, and temporal
   support can alter H01 values and model frames.
8. **Photoperiod scope.** The current code includes photoperiod in all 17
   outcomes. The signed contract only explicitly requires it for metrics
   with a day/night-duration component. Retaining all-outcome adjustment
   preserves the current scientific comparison but must remain a declared
   adaptation, with a preregistration-faithful sensitivity.
9. **Non-deterministic provenance.** Multi-object workspaces, frozen results,
   and manual asset copying prevent a clean raw-to-claim path.

## Proposed repaired specification

### Primary site estimand

For each metric \(m\), estimate the adjusted difference among the observed
sites in the near-eye sample. Preserve the current equal-site interpretation:
site marginal means and site deviations are averaged equally across sites,
not weighted by the number of hours or participants recruited at each site.

For participant-day metrics:

```text
g_m(metric) ~ site + photoperiod_c + (1 | site:participant)
```

For participant-level dynamics metrics:

```text
g_m(metric) ~ site + photoperiod_c
```

Here `g_m()` is the metric-specific, predeclared transformation or link.
`photoperiod_c` is centered in hours so the intercept has a defined
interpretation. Site is explicitly sum-coded for coefficient stability, but
all reported site estimates come from equal-site marginal means and do not
depend on an arbitrary reference site.

The all-outcome photoperiod adjustment is retained as the adapted primary
specification because it is the current manuscript estimand. A
preregistration-faithful sensitivity omits photoperiod where the signed
contract did not require it. Any material disagreement is a major-result
gate.

The omnibus site test compares the site model with the identical-row model
without `site`. Gaussian mixed models are fit with ML for this comparison.
After the formula is fixed, a REML fit supplies final Gaussian estimates and
intervals. Tweedie models remain ML fits.

### Latitude analysis

Latitude is a separate ecological, site-level explanatory analysis, not a
component added to the fixed-site model:

```text
g_m(metric) ~ abs_latitude_10deg_c + photoperiod_c +
  (1 | site) + (1 | site:participant)
```

The participant-level version omits the redundant participant random
intercept but retains site clustering where estimable. With only nine sites,
latitude estimates and intervals are reported as limited site-level
evidence. Leave-one-site-out influence is mandatory. The latitude model is
not called proof that latitude explains a fixed site effect, and a
non-nested AIC difference is not converted into a significance claim.

### Metric-specific distribution rules

The current family map is the starting candidate, not an automatic final
choice. For every metric the notebook must record:

- support for zeros and bounds;
- link/transformation and inverse transformation;
- convergence and singularity;
- residual/distributional diagnostics;
- practical-unit marginal means and contrasts; and
- a declared alternative distribution or transformation when one is
  scientifically valid.

Timing metrics must use the approved circular estimates. A linearized
clock-hour mixed model is allowed only after a fixed cut point is declared
and the observed support is shown not to straddle it. Otherwise a
circularly valid model or circular bootstrap contrast is required and
constitutes a major model gate.

### Multiplicity

Predeclare at minimum:

- `H01-F1-site`: the 17 omnibus site p-values, adjusted together by BH;
- `H01-F2-photoperiod`: the 17 photoperiod tests if all are interpreted
  inferentially, adjusted together by BH; and
- `H01-F3-latitude`: the 17 ecological latitude tests, adjusted together by
  BH and labelled secondary.

Random-site-versus-fixed-site AIC comparisons are model-description
exercises, not another set of “significant site” tests. If a narrower
photoperiod family is adopted to follow the signed contract, its complete
member list must be fixed in the H01 model-data dictionary before fitting.

### Required diagnostics

- model-frame equality for every nested comparison;
- observations, participant-days, participants, and sites by metric;
- outcome support, zeros, bounds, and transformations;
- convergence, Hessian, gradients, and singularity;
- Gaussian residual distribution and variance pattern;
- Tweedie dispersion, zero behavior, simulated residuals, and tail fit;
- participant- and site-level influence;
- leave-one-site-out latitude estimates;
- stability of equal-site versus observed-sample marginalization;
- circular cut-point and resultant checks for timing outcomes; and
- common-sample glasses/chest coefficient and inference comparison.

## Required H01 result-difference checks

For every metric, produce one row per comparison stage containing:

1. current saved near-eye result;
2. canonical code under current metric values and current model rules;
3. canonical rebuilt metric under the repaired preprocessing rules;
4. repaired model with true vector-wide BH; and
5. paired/common-sample glasses and complementary chest results.

The row must include all model-frame denominators, estimate, standard error,
interval, raw p-value, adjusted p-value, family/rank, full-model \(R^2\),
convergence state, and claim classification. Explicitly flag:

- BH significance changes;
- the corrected conditional-\(R^2\) branch;
- changes caused by the \(10^5\)-lx rule;
- changes caused by metric-specific support;
- changes caused by valid ML comparisons;
- latitude leave-one-site-out instability; and
- any change in the direction or practical magnitude of a site contrast.

## H01 dependencies and downstream reopening

H01 cannot close until preparation notebooks 01–05, the 17 metric-validity
implementations, and model-specific sample flow pass. H05 currently reads
the H01 workspace and H07 currently selects outcomes based on H01/H02
significance. Those dependencies must be removed: later hypotheses may use
the common metric dictionary, but may not select outcomes based on an H01
p-value. Any upstream metric repair reopens H01.

# H02: Site, participant, and participant-day pattern variation

## Preregistered contract and current estimand

The signed H02 target compares within-site participant-pattern variability
with between-site pattern variability in repeated melanopic EDI. It
registered hourly geometric-mean MEDI, cyclic site-specific time smooths, a
participant-time factor smooth, AIC-based GAMM comparison, and AR(1)
correction when residual autocorrelation remains.

Documented deviations use 30-minute arithmetic-mean MEDI, add an overall
time smooth, and use an `sz` site-deviation basis. These changes are retained
for re-audit because they make the daily-pattern decomposition more
identifiable, but the outcome and variance estimand must be stated exactly.

## Exact current input and filtering

Near-eye H02 loads:

- `data/metrics_separate_glasses.RData`, object
  `metric_glasses_participanthour`; and
- `data/preprocessed_glasses_2.RData`.

Chest H02 substitutes the corresponding chest files and object.

`metric_*_participanthour` was constructed in `data_preparation.qmd` by:

1. starting from the one-minute stage-2 records;
2. aggregating to floor-aligned 30-minute bins;
3. calculating arithmetic mean `MEDI` and zero-aware geometric mean
   `geo.MEDI`;
4. adding a date;
5. marking a participant-day “static” when all arithmetic bin means equal
   the first bin mean; and
6. removing every bin of such a static participant-day.

No current bin-level valid-minute threshold is applied. The saved baseline
contains 38,832 near-eye 30-minute rows from 141 participants and 809
participant-days, and 42,912 chest rows from 154 participants and 894
participant-days. These are baseline artifact counts, not accepted final
counts.

H02 uses arithmetic `MEDI`, not `geo.MEDI`, and derives:

- `Time = clock time in hours + 0.25`, the bin midpoint;
- `lzMEDI = log_zero_inflated(MEDI)`;
- factor `site`, `Id`, `Date`, state fields, and
  `Id_date = interaction(Id, Date)`;
- numeric photoperiod, which is not used in the fitted formula; and
- `AR.start = TRUE` only for the first retained row of each participant.

The current shared-UTC-looking time axis came from forced site-local clock
labels. It does not distinguish a true UTC instant from the wall-clock
coordinate and can duplicate fall-back keys.

## Exact current formulas, fitting, and reference handling

```text
H2_1:
lzMEDI ~ s(Time, k = 12) +
  s(Time, site, bs = "sz", k = 12) +
  s(Time, Id, bs = "fs") +
  s(Id_date, bs = "re")

H2_0:
lzMEDI ~ s(Time, k = 12) +
  s(Time, Id, bs = "fs") +
  s(Id_date, bs = "re")

H2_phot:
lzMEDI ~ s(Time, k = 12) +
  s(Time, site, bs = "sz", k = 12) +
  s(Time, photoperiod.state, bs = "sz", k = 12) +
  s(Time, Id, bs = "fs") +
  s(Id_date, bs = "re")
```

The `sz` terms are sum-to-zero deviation smooths; there is no ordinary
reference site. The overall `s(Time)` is the average pattern under the
factor-smooth constraints. There is no parametric fixed `site` term. The
“photoperiod” model uses the categorical day/night state at each bin, not the
numeric photoperiod duration calculated in preparation.

Each model is fit twice with `mgcv::bam()`:

1. `discrete = TRUE`, `method = "fREML"` without AR correction;
2. estimate a single `rho` with `itsadug::start_value_rho()`; and
3. refit under fREML with that `rho` and `AR.start`.

AIC is then compared across the three stored fREML fits. The current code
selects `H2_phot` because it has the lowest AIC. Pointwise fitted curves and
smooth intervals are back-transformed to lx.

Finally, it calculates the variance across observations of each prediction
term, divides each term variance by the sum of term variances, labels the
values “partial R2” or “variance explained”, and uses that calculation to
motivate the participant-versus-site claim.

## Current outputs and claims

Current durable outputs are:

- `figures/Fig4.pdf` and `figures/Fig4.png`;
- `figures/chest/Fig4.pdf` and `figures/chest/Fig4.png`; and
- manually copied `assets/Fig4.png`.

The fitted models, exact model frames, AIC table, `rho`, diagnostics, and
figure source data are not durable standalone artifacts.

The current manuscript describes a decomposition into time, photoperiod,
site, participant, and participant-day contributions and claims site-specific
morning/evening departures, including approximately two- to five-fold
patterns for selected sites. H02 is also used as the temporal-model template
for the exploratory H03/H04 context figures.

## Confirmed defects and risks

1. **The registered variance target is not estimated (`IMP-005`).** Variance
   across fitted prediction terms is not a variance-component decomposition.
2. **Correlated terms are divided by the sum of their separate variances.**
   Covariance among terms is shown by the code itself but omitted from the
   “variance explained” calculation.
3. **Outcome deviation (`DEV-012`).** The current arithmetic 30-minute
   outcome differs from the registered hourly geometric mean. It is also
   described inconsistently as a geometric mean in some text.
4. **Unsupported 30-minute bins (`IMP-015`).** A bin can currently be based
   on very few valid minutes.
5. **Static-day deletion is blunt.** It removes a whole participant-day from
   H02 instead of distinguishing true constant exposure, missing support, and
   device artifact.
6. **Non-cyclic bases (`DEV-010`).** Neither the default overall smooth nor
   the `sz` site deviations enforce midnight continuity.
7. **Model-structure deviation (`DEV-011`).** The added overall smooth is
   defensible but changes the registered parameterization.
8. **Photoperiod mismatch.** `H2_phot` models a time-by-day/night-state
   deviation, not a smooth effect of daily photoperiod duration.
9. **AR sequence boundaries.** `AR.start` is true only once per participant,
   so missing bins and other discontinuities can be treated as adjacent.
10. **fREML model selection.** AIC comparisons across models with different
    smooth/fixed structures need an ML-based comparison fit; fREML is
    retained for final smooth estimation after structure selection.
11. **Pointwise significance traces.** Red curve segments use pointwise
    intervals and are not simultaneous curve-level inference.
12. **Time-axis ambiguity.** Fall-back duplicates and forced clock labels can
    alter bin keys, pattern weights, and AR ordering.

## Proposed repaired specification

### Outcome and model frame

Retain the approved adapted outcome:

- arithmetic mean MEDI in a 30-minute local-clock bin;
- at least 15 valid one-minute observations;
- values below \(10^5\) lx only;
- an unsupported bin is missing with a reason code rather than causing
  participant-day deletion;
- fall-back duplicates are averaged on the wall-clock grid with fold
  provenance; and
- sleep bins are explicitly identified as bedside-environment intervals.

Model the zero-aware log of this outcome. The model frame retains
`datetime_wall`, the corresponding true-instant support, participant,
participant-day, site, state, valid-minute count, and fold flags.

### Temporal model

The primary model is a cyclic, identifiable decomposition into an overall
daily curve, sum-to-zero site deviations, participant deviations, and a
participant-day intercept:

```text
lzMEDI ~ site +
  cyclic_overall(Time_wall, k = 12) +
  cyclic_sum_to_zero_site_deviation(Time_wall, site, k = 12) +
  cyclic_participant_deviation(Time_wall, participant, k = 12) +
  random_intercept(participant_day)
```

Implementation may use an `sz`/factor-smooth parameterization only after a
unit test demonstrates midnight continuity and the intended sum-to-zero
constraint. The registered `cc` formulation is retained as a named
sensitivity. The parametric site term captures whole-curve level
differences; the site deviation smooth captures shape differences.

The primary site-pattern comparison removes both the parametric site term
and site-deviation smooth on an identical model frame. It is one omnibus H02
test. A daily photoperiod-duration adjustment or a day/night-state smooth is
a separately labelled secondary specification; it must not be selected and
renamed “photoperiod” solely because it has the lowest current AIC.

Use ML for structure comparison and fREML for the final selected smooth
estimation. Estimate residual autocorrelation on true-order sequences.
`AR.start` must be true at each participant/placement sequence start and
after every unsupported bin or other break in expected true-time adjacency.
If the implementation uses participant-day AR sequences, this boundary
choice must be explicit and tested against a continuous-across-midnight
sequence sensitivity.

### Valid H02 variability estimand

Do not call term-prediction variance “variance explained.” Predeclare a
common 48-bin clock grid and calculate model-implied integrated deviation
energy on the modelling scale:

\[
V_{\mathrm{site}} =
\frac{1}{48}\sum_b \operatorname{Var}_{s}
  \{\hat f_s(t_b)\},
\qquad
V_{\mathrm{participant}} =
\frac{1}{48}\sum_b \operatorname{Var}_{i}
  \{\hat g_i(t_b)\}.
\]

Report \(V_{\mathrm{participant}}/V_{\mathrm{site}}\), both components, and
clustered bootstrap uncertainty. This is explicitly “model-implied
between-curve variability on the common clock grid,” not unique variance
explained and not a causal decomposition. If a stable variance-component
parameterization can estimate comparable site- and participant-smooth
variance components directly, report it as a corroborating specification,
not as an undocumented replacement.

### Multiplicity and curve inference

- `H02-F1-site-pattern` contains the single omnibus site-pattern test.
- Any time-resolved site-deviation claims use simultaneous smooth intervals
  or a declared curve-level test, not a sequence of unadjusted pointwise
  intervals.
- Site-pair differences, if reported, form one complete declared family and
  receive vector-wide adjustment.

### Required diagnostics

- exact 30-minute support and missing-bin map;
- basis dimension and `k` checks;
- midnight value and derivative continuity;
- factor-smooth constraint/identifiability checks;
- concurvity;
- residual distribution and fitted-value pattern;
- ACF by participant and participant-day before and after correction;
- explicit sequence-break audit against true UTC adjacency;
- sensitivity to ML/fREML stage, basis choice, and registered hourly
  geometric outcome;
- influence of each site and sparse Costa Rica near-eye data; and
- bootstrap stability of the integrated deviation-energy ratio.

## Required H02 result-difference checks

Compare:

1. current saved 30-minute data/current formula;
2. canonical migration under current bin rules;
3. support-aware 30-minute bins;
4. repaired cyclic/time-axis/AR model;
5. registered one-hour geometric-mean sensitivity;
6. all-near-eye versus paired/common-sample near-eye; and
7. paired/common-sample chest.

Record row counts, participants, days, supported clock bins, `rho`, EDF,
smooth penalties, convergence, AIC under the valid comparison method,
whole-curve test, simultaneous difference intervals, predicted curves in lx,
and the new variability estimand. Compare current and repaired curves on the
same 48-bin grid with absolute and fold differences. Every current
site/time-window claim is rechecked from the exact source-data CSV.

## H02 dependencies and downstream reopening

H02 depends on the prepared 30-minute outcome, dual time axes, and
participant-day keys. H11 may consume only the approved H02 temporal
specification artifact. H03/H04 secondary temporal models may reuse that
specification, but not H02 fitted values, significance-based outcome
selection, or the invalid term-variance calculation. Any H02 temporal-model
change reopens those secondary H03/H04 displays.

# H03: Self-reported light source and measured exposure

## Preregistered contract and current estimand

H03 asks whether all prespecified hourly primary-light-source categories
predict hourly geometric-mean MEDI. The registered structure was:

```text
melEDI ~ light_source + (light_source | site) +
  (1 | site:participant)
```

The current analysis replaces the random site slopes with fixed
site-by-light-source interactions and replaces the unspecified Gaussian LMM
with a Tweedie GLMM. Those documented deviations remain candidates because
the random-slope model was unstable, but both require renewed diagnostics.

## Exact current input, aggregation, join, and filters

### Inputs

- Near-eye: `data/metrics_glasses.RData` and
  `data/preprocessed_glasses_2.RData`, with
  `hourly_data <- light_glasses_processed2`.
- Chest: corresponding chest files and `light_chest_processed2`.
- Hourly diary: `melidosData::load_data("lightexposurediary") |>
  flatten_data()`.

The current code:

1. floor-aggregates one-minute light data to one-hour bins;
2. calculates arithmetic mean `MEDI` and zero-aware geometric mean
   `geo.MEDI`;
3. removes a participant-day when all hourly arithmetic MEDI values equal
   the first value;
4. joins the hourly diary with `add_states()` within site, participant, and
   date; and
5. uses `geo.MEDI` as the primary GLMM outcome.

There is no explicit requirement for 30 valid minutes in the hour and no
persisted join-cardinality report.

The complete questionnaire dictionary contains:

1. electric light source indoors;
2. electric light source outdoors;
3. daylight indoors;
4. daylight outdoors, including shade;
5. emissive display light;
6. darkness during sleep; and
7. light entering from outside during sleep.

The current near-eye filter first sets a site-by-category cell to missing if
it has fewer than 20 hourly rows, then sets the remaining category to missing
if it has fewer than 200 hourly rows overall. It also manually excludes
“Light entering from outside during sleep.” In the rendered baseline this
leaves five modelled levels: indoor electric light, indoor daylight, outdoor
daylight, emissive display light, and darkness during sleep. Outdoor electric
light falls out through the sparse-cell sequence. The chest notebook also
manually excludes outdoor electric light “for consistency” rather than
applying one placement-independent estimability rule.

The baseline table reports 16,774 near-eye and 18,391 chest participant-hour
rows, but these values must be regenerated because the current filter counts
hours rather than independent participants and because canonical hourly
support can change the frame.

## Exact current formulas, fitting, comparisons, and references

```text
H3_full:
geo.MEDI ~ site * lightsource_primary + (1 | Id)

H3_site_only:
geo.MEDI ~ site + (1 | Id)

H3_additive:
geo.MEDI ~ site + lightsource_primary + (1 | Id)

H3_context_only:
geo.MEDI ~ lightsource_primary + (1 | Id)
```

All are `glmmTMB` Tweedie log-link models with `REML = FALSE`; site is
sum-coded except in the context-only model. IDs are currently globally
site-prefixed, so `(1 | Id)` behaves as a participant intercept, but this
uniqueness is not asserted in the notebook.

The current “confirmatory” comparison is site-only versus full. It therefore
adds the light-source main effect and every site-by-light-source interaction
at once. The additive-versus-full comparison tests interaction. The
context-only-versus-additive comparison tests site without interaction.

Reported marginal means are equally averaged over site. Indoor electric
light is intended as the context reference. The table reports:

- an equal-site mean response for indoor electric light;
- category-to-indoor-electric ratios; and
- each site’s effect contrast from the equal-site mean within category.

The indoor-electric reference is used explicitly in the display code, but
the canonical factor level must be set explicitly before model fitting
rather than relying on source factor order.

### Current multiplicity behavior

- The site-only versus full omnibus test is unadjusted as a nominal
  one-comparison test.
- `emmeans(... ) |> contrast(method = "trt.vs.ctrl")` uses the emmeans
  Dunnett-X default for the four retained category-versus-reference
  contrasts, not BH.
- `contrast()` for site effect contrasts uses effect contrasts with its FDR
  default within each light-source `by` group.
- The table footnote nevertheless states FDR for `n = 4` light-source and
  `n = 9` site comparisons.

Thus the displayed category multiplicity description does not match the
code, and site adjustment is partitioned by category rather than declared
as a complete cross-category heterogeneity family.

## Current secondary temporal analysis

The exploratory H03 GAM:

- uses hourly arithmetic `MEDI`, not the primary hourly `geo.MEDI`;
- zero-aware-log transforms that arithmetic mean;
- includes overall time, light-source, site, and day/night-state deviation
  smooths, participant factor smooths, and participant-day intercepts;
- inherits `AR.start = TRUE` only once per participant;
- compares its fREML AIC against a context-free H02-like model;
- repeats the invalid prediction-term variance calculation; and
- draws pointwise red “significant” segments.

It produces `figures/Fig9.*` and its chest counterpart. This is the producer
behind the manuscript’s time-of-day light-source pattern claims.

## Current outputs and claims

Current durable outputs are:

- `tables/H3.png`, `tables/H3.docx`;
- `tables/chest/H3.png`, `tables/chest/H3.docx`;
- `figures/Fig5.*` and `figures/chest/Fig5.*` jointly with H04;
- `figures/Fig9.*` and `figures/chest/Fig9.*`; and
- manually copied `assets/H3.png`, `assets/Fig5.png`, and
  `assets/Fig9.png`.

The current main manuscript claims a strong light-source association, an
indoor-electric reference near 75 lx, large increases for daylight,
decreases for display and darkness categories, small site and interaction
contributions, and roughly 69% incremental \(R^2\) attributed to light
source. These claims are reopened.

## Confirmed defects and risks

1. **The confirmatory LRT is not a category main-effect test.** It adds the
   category and interaction blocks jointly.
2. **Multiplicity labeling is false.** Context contrasts use Dunnett-X while
   the table says BH; site BH families are split by context without being
   declared that way.
3. **Sparse-category handling is data- and placement-dependent.** Two
   prespecified categories disappear, and chest manually mirrors a near-eye
   exclusion.
4. **Repeated observations are incompletely represented.** A participant
   intercept does not represent participant-day clustering or remaining
   within-day hourly dependence.
5. **No hourly support rule.** A geometric mean can be based on fewer than 30
   valid minutes.
6. **Join and category provenance are not asserted.** A diary interval may
   join incorrectly or create unexpected multiplicity without a hard
   failure.
7. **Intervals are discarded from the final table.** Significance is shown
   by bold type around point estimates.
8. **Overlapping \(R^2\) differences are called variance explained.** The
   current “light source” increment includes interaction, and increments for
   site, context, and interaction overlap.
9. **Sleep-category construct.** “Darkness during sleep” is a bedside
   environment measurement and cannot be interpreted as worn ocular
   exposure.
10. **Temporal secondary outcome mismatch.** The GAM uses hourly arithmetic
    rather than the primary hourly geometric outcome.
11. **Temporal-model defects inherited from H02.** Non-cyclic bases,
    discontinuity-insensitive AR starts, fREML model selection, term-variance
    interpretation, and pointwise red segments recur.
12. **No authoritative model/source-data artifact.** Current files are
    presentation outputs and manual manuscript copies.

## Proposed repaired specification

### Category dictionary and support

All seven questionnaire categories remain in the H03 data dictionary and
sample-flow table. No category is silently deleted. Before outcomes are
examined:

- report hours, participant-days, participants, and sites for every category
  and category-by-site cell;
- retain the current 20-hour cell and 200-hour overall thresholds as
  descriptive continuity checks, not as proof of independent support;
- add participant-level support and design-rank checks before permitting a
  site-specific contrast; and
- mark an unsupported contrast `non-estimable` with a reason rather than
  deleting the category from all reporting.

The pooled category effect should include every globally estimable category.
If the full seven-category interaction is rank deficient, retain all
categories in the pooled additive model and limit only the secondary
site-specific interaction analysis to a predeclared supported set. Changing
or combining a category after seeing exposure estimates is a major gate.

### Primary outcome and model

Use the canonical one-hour zero-aware geometric mean of valid MEDI, requiring
at least 30 valid one-minute intervals. Preserve the diary category assigned
to that hour, state, valid-minute count, participant-day, true-time support,
and wall-clock bin. State/context joins must be many-light-to-one-context and
must fail on overlapping context intervals.

Fit:

```text
M0:
geo_medi_1h ~ site +
  (1 | site:participant) + (1 | participant_day)

M_context:
geo_medi_1h ~ site + light_source +
  (1 | site:participant) + (1 | participant_day)

M_full:
geo_medi_1h ~ site * light_source +
  (1 | site:participant) + (1 | participant_day)
```

The candidate primary distribution remains Tweedie with log link because it
supports zero and positive outcomes and preserves the documented
specification. A zero-aware Gaussian log-scale model is the named
common-sample distributional sensitivity. Whichever model is used must
retain the same response estimand and pass zero, dispersion, tail, and
residual checks.

If residual hourly dependence remains, add a predeclared within-
participant-day AR(1) term using the regular hourly clock index, or use the
approved correlation-capable equivalent. This must be compared on identical
rows. Unsupported hours break the sequence.

The primary context omnibus test is `M0` versus `M_context`. The heterogeneity
test is `M_context` versus `M_full`. `M_full` supplies equal-site marginal
means and site-specific contrasts when stable; otherwise the additive
estimates remain primary and the failed interaction is reported.

Set factor levels explicitly:

- placement reference: near-eye;
- light-source reference: indoor electric light;
- site coding: sum-to-zero; and
- marginalization: equal site weights for the primary cross-site estimand.

Report each category’s predicted MEDI in lx and ratio versus indoor electric
light, with 95% intervals. Report sleeping categories as bedside-environment
comparisons.

### Multiplicity

- `H03-F1-omnibus`: one primary context omnibus test.
- `H03-F2-context-contrasts`: every globally estimable
  category-versus-indoor-electric contrast, adjusted together by BH.
- `H03-F3-site-heterogeneity`: one omnibus interaction test.
- `H03-F4-site-context-contrasts`: all requested estimable site deviations
  across all categories, adjusted as one declared BH vector, not a hidden
  family per category.

Raw and adjusted values are retained. Dunnett-X may be shown as a named
sensitivity for the shared-control contrast problem, but it cannot be
labelled BH.

### Secondary temporal model

If the H03 time-of-day figure is retained, it:

- uses the same supported hourly geometric outcome as the primary H03 model;
- reuses the approved H02 cyclic temporal specification, not H02 fitted
  results;
- adds a light-source temporal deviation smooth;
- uses valid sequence boundaries and a correlation correction;
- uses ML for structure comparison and fREML for final estimation;
- reports simultaneous curve intervals; and
- makes no prediction-term “variance explained” claim.

This is exploratory context-by-time description. It does not replace the
primary H03 GLMM.

### Required diagnostics

- hourly valid-minute and state/context support;
- diary join cardinality and duplicate keys;
- category and category-by-site hours, days, and participants;
- fixed-effect design rank and aliased cells;
- convergence, Hessian, gradients, and random-effect singularity;
- Tweedie zero, dispersion, tail, and simulated-residual checks;
- participant-day and within-day residual dependence;
- participant and site influence;
- equal-site versus observed-sample marginalization;
- temporal smooth basis, concurvity, ACF, and simultaneous intervals; and
- common-sample near-eye/chest comparison by category and site.

## Required H03 result-difference checks

Compare current and repaired:

- model rows, participants, days, sites, and category support;
- retained/non-estimable category sets;
- current joint context-plus-interaction LRT versus the repaired context-only
  omnibus;
- raw, current Dunnett-X/FDR, and repaired BH p-values;
- equal-site EMMs in lx, ratios, and intervals;
- full-model marginal/conditional \(R^2\), without additive decomposition;
- category and site influence;
- primary geometric and secondary temporal-model outcomes; and
- all-near-eye versus paired/common-sample near-eye/chest estimates.

Every daylight, electric-light, display, darkness, and site-specific
manuscript number must map to one row in the result-difference and
claim-provenance tables.

## H03 dependencies and downstream reopening

H03 depends on model-ready hourly light-source joins, the one-hour metric,
and the approved H02 temporal specification for its optional secondary GAM.
It does not depend on H02 significance or predicted values. Any category
recoding, H02 temporal-specification change, or common hourly outcome repair
reopens H03.

# H04: Activity and measured exposure

## Preregistered contract and current estimand

H04 asks whether all prespecified hourly activity categories predict hourly
geometric-mean MEDI. Its registered mixed-model structure is the same as H03,
with activity replacing light source. The current code makes the same
fixed-site-interaction and Tweedie deviations as H03.

## Exact current input, aggregation, join, and filters

H04 inherits `hourly_data2` from H03 after one-hour light aggregation and
diary joining. It pivots every `act_*` Boolean column to long form, retains
rows with `value == TRUE` and non-missing `geo.MEDI`, and deduplicates by
site, participant, hour, and activity. It then:

- combines free time outdoors, working outdoors, and travel by bike/on foot
  into `outdoor`;
- removes `other`;
- puts `home` first; and
- drops missing activity.

The retained displayed levels are:

1. awake at home (`home`, reference);
2. sleeping in bed (`sleep`);
3. road travel by public transport/car (`road_vehicle`);
4. working indoors/in an office/from home (`working_indoor`); and
5. outdoor free time, outdoor work, or bike/on-foot travel (`outdoor`).

The source questionnaire describes a primary hourly activity, but the
current long transformation does not assert that exactly one activity is
true per participant-hour. If multiple flags are true, it duplicates the
same hourly outcome into multiple activity rows.

The rendered current near-eye activity counts sum to 16,801 non-missing
activity rows, whereas the H04 table footnote reports the H03 light-source
model’s 16,774 rows. The chest H04 footnote likewise reports the H03 count of
18,391. Canonical counts must be regenerated from unique participant-hour
keys.

## Exact current formulas, fitting, comparisons, and references

```text
H4_full:
geo.MEDI ~ site * activity + (1 | Id)

H4_site_only:
geo.MEDI ~ site + (1 | Id)

H4_additive:
geo.MEDI ~ site + activity + (1 | Id)

H4_activity_only:
geo.MEDI ~ activity + (1 | Id)
```

The fitting engine, Tweedie family, ML setting, sum-coded site, LRT sequence,
equal-site marginalization, \(R^2\) differences, and contrast code mirror
H03. `home` is the intended activity reference.

The current preliminary test of activity distribution by site contains a
separate coding defect:

```r
activity_data2 <- activity_data |>
  mutate(activity = fct_drop(lightsource_primary))
```

This overwrites `activity` with the light-source factor before the multinomial
and chi-squared site tests. Consequently, that block does not test the
activity variable it claims to test.

Context contrasts use emmeans’ Dunnett-X default, while the table claims FDR
for four activity contrasts. Site effect contrasts use FDR separately within
activity. The current full-versus-site-only “confirmatory” comparison again
adds activity and interaction together.

## Current secondary temporal analysis

The exploratory H04 GAM recreates the long activity data from hourly
arithmetic `MEDI`, not the primary `geo.MEDI`. It uses the same overall,
activity, site, day/night-state, participant, participant-day, fREML, AR, AIC,
term-variance, and pointwise-interval machinery as H03. It produces
`figures/Fig10.*` and the chest counterpart.

## Current outputs and claims

Current durable outputs are:

- `tables/H4.png`, `tables/H4.docx`;
- `tables/chest/H4.png`, `tables/chest/H4.docx`;
- the joint `figures/Fig5.*` and chest counterpart; and
- `figures/Fig10.*` and chest counterpart.

The manuscript currently uses `assets/H4.png`, `assets/Fig5.png`, and
`assets/Fig10.png` and claims a strong activity association, an awake-at-home
reference near 59 lx, higher exposure for work/travel/outdoor activity, low
bedside sleep values, modest site heterogeneity, and roughly 58% incremental
\(R^2\) attributed to activity. These claims are reopened.

## Confirmed defects and risks

H04 inherits all applicable H03 issues: joint main-plus-interaction omnibus,
contrast-adjustment mismatch, incomplete repeated-observation structure,
missing hourly support, omitted intervals, overlapping \(R^2\) increments,
sleep-environment interpretation, temporal outcome mismatch, H02 temporal
defects, and non-deterministic output provenance.

Additional H04-specific defects are:

1. **Wrong variable in the activity-by-site test.** The code overwrites
   activity with light source.
2. **Wrong displayed model denominator.** The H04 table counts non-missing
   H03 light-source rows rather than H04 activity rows.
3. **Potential duplicate outcome rows.** Multi-flag hours are not identified
   or resolved.
4. **Activity recoding changes the construct.** Bike/on-foot travel is grouped
   with outdoor free/work time, vehicle travel remains separate, and `other`
   is discarded. This is documented in prose but not represented as a
   versioned category dictionary or sensitivity.
5. **Current result language is causal.** “Activity affected exposure” is
   stronger than the observational, self-reported context association
   identified by the model.

## Proposed repaired specification

### Activity dictionary and unique hourly exposure

The H04 model-data producer must first assert the questionnaire encoding:

- if exactly one primary activity is expected, fail and report every
  participant-hour with zero or multiple true flags before model fitting;
- if multiple activities were legitimately allowed, do not duplicate the
  outcome into a nominal one-factor model. Define a multi-label predictor
  strategy as a major estimand gate.

Retain the current five-level recoding as the adapted primary dictionary
because it underlies the recognizable manuscript result, but expose all
eight original choices and the mapping in the sample-flow table. Report the
excluded `other` rows and each component of `outdoor`. A sensitivity keeps
the outdoor components separate when estimable; no component is selected
based on its observed MEDI.

### Primary outcome and model

Use the same supported one-hour zero-aware geometric MEDI outcome as H03.
Fit:

```text
M0:
geo_medi_1h ~ site +
  (1 | site:participant) + (1 | participant_day)

M_activity:
geo_medi_1h ~ site + activity +
  (1 | site:participant) + (1 | participant_day)

M_full:
geo_medi_1h ~ site * activity +
  (1 | site:participant) + (1 | participant_day)
```

Use a Tweedie log-link primary model subject to diagnostics, with the same
zero-aware Gaussian common-sample sensitivity and the same rule for adding
within-participant-day AR(1) dependence as H03.

The primary activity omnibus is `M0` versus `M_activity`; interaction is
`M_activity` versus `M_full`. Use the full model for equal-site marginal
means when stable, otherwise report the additive model and the failed
heterogeneity fit.

Set explicitly:

- `home` as the activity reference;
- sum-coded site;
- equal-site weights for primary marginal estimates; and
- near-eye as primary placement.

Report predicted MEDI in lx and ratios versus awake at home, with intervals.
Describe sleep as the bedside sleep environment. Use “associated with,” not
“affected,” unless a separate causal design justifies the latter.

### Multiplicity

- `H04-F1-omnibus`: one primary activity omnibus test.
- `H04-F2-activity-contrasts`: all four adapted activity-versus-home
  contrasts, adjusted together by BH.
- `H04-F3-site-heterogeneity`: one omnibus interaction test.
- `H04-F4-site-activity-contrasts`: all requested estimable site deviations
  across activities, adjusted as one declared BH vector.

The original-category sensitivity gets its own declared family. Current
Dunnett-X values may be retained for result-difference auditing but are not
called BH.

### Secondary temporal model

If retained, the time-of-day activity model uses the same supported hourly
geometric outcome, the approved cyclic H02 temporal structure, valid AR
sequence breaks, ML-to-fREML fitting stages, and simultaneous intervals. It
does not reuse H03/H02 global objects named `GAM_data` or `H2_model_gam`, and
it does not report prediction-term variance as variance explained.

### Required diagnostics

In addition to H03 diagnostics:

- one/zero/multiple activity flags per participant-hour;
- activity recoding flow from eight source choices to five adapted levels;
- unique participant-hour counts before and after long conversion;
- participant/day/site support for each activity and interaction cell;
- correct activity-by-site descriptive model with participant clustering or
  descriptive proportions only;
- vehicle-versus-active-travel and disaggregated-outdoor sensitivity; and
- correct H04-specific model-frame denominator in every table and claim.

## Required H04 result-difference checks

Compare current and repaired:

- unique participant-hours versus long activity rows;
- original and adapted category counts;
- corrected activity-by-site description;
- current joint activity-plus-interaction LRT versus repaired activity
  omnibus;
- raw, current Dunnett-X/FDR, and repaired BH values;
- EMMs in lx, ratios, and intervals;
- corrected H04 denominator;
- full-model marginal/conditional \(R^2\), without additive decomposition;
- primary and temporal outcome consistency;
- current five-level versus original-category sensitivity; and
- all-near-eye versus paired/common-sample near-eye/chest estimates.

Every activity, site, and time-window claim in the manuscript must map to one
verified source-data row or curve interval.

## H04 dependencies and downstream reopening

H04 depends on the model-ready hourly activity join, unique activity encoding,
one-hour geometric outcome, and the approved H02 temporal specification for
its optional secondary GAM. H06 may use the same activity dictionary as a
covariate but must not import H04 fitted values or p-values. Any activity
recoding, hourly outcome repair, or H02 temporal-specification change reopens
H04.

# Canonical output contract for all four notebooks

Each H01–H04 placement/scenario run must produce:

1. a model-frame RDS containing only the exact fitted rows and keys;
2. a model object RDS per declared fit;
3. a CSV model manifest with formula, family, link, fitting method, package
   versions, input hashes, convergence, warnings, and row counts;
4. raw and adjusted test CSVs with multiplicity-family metadata;
5. practical-scale estimate and contrast CSVs with intervals;
6. a sample-flow CSV at site, participant, participant-day, hour/metric, and
   category levels as applicable;
7. durable diagnostic plots and machine-readable diagnostic summaries;
8. a result-difference CSV against the frozen baseline;
9. publication table/figure files; and
10. exact source-data CSVs for every figure and durable table.

Suggested deterministic paths use the existing artifact roots:

```text
artifacts/07_models/H0x/<placement>/<scenario>/
artifacts/08_diagnostics/H0x/<placement>/<scenario>/
artifacts/09_tables/H0x_<placement>_<scenario>.*
artifacts/10_figures/H0x_<placement>_<scenario>.*
artifacts/11_source_data/H0x_<display_id>_<placement>_<scenario>.csv
artifacts/12_manifests/H0x_<placement>_<scenario>_manifest.csv
```

The assembly notebook, not a hypothesis notebook or a manual copy, selects
the approved near-eye primary and complementary outputs for the manuscript
and Supplementary Information.

# Migration acceptance criteria

H01–H04 migration is complete only when:

- a clean-session run from explicit upstream artifacts succeeds for both
  primary and complementary scenarios;
- canonical-current-rule runs reproduce the current implementation wherever
  no defect is intentionally repaired, or explain every discrepancy;
- all repaired-result differences are classified and approved at the
  appropriate gate;
- model frames and sample flow reconcile across analyses, displays, prose,
  and reporting checklists;
- every p-value belongs to an explicit vector-wide family;
- every estimate has a practical-scale interval;
- all diagnostic failures remain visible;
- near-eye and chest results are never pooled or described as independent
  additions to sample size;
- sleep categories are consistently labelled bedside-environment exposure;
- H02 makes no “variance explained” claim from prediction-term variance;
- H03/H04 make no causal “effect” claim from observational context
  associations; and
- no current H01–H04 number remains in the Nature Health manuscript unless
  its canonical producer and claim-provenance entry verify it.
