# H09–H11 canonical migration map

Status: read-only code, artifact, and claim map; implementation and clean
reruns pending  
Prepared: 2026-07-30  
Baseline branch commit: `20ba43c27e69fd952ce8023770538f2aa843ef5e`  
Primary placement: near-eye (`glasses`)  
Complementary placement: chest, preferably on paired/common samples  
Pooling decision: rejected

## Purpose and authority

This document maps the current H09–H11 implementations into canonical
hypothesis notebooks. It distinguishes:

1. the signed preregistration contract;
2. the exact behaviour of the current R/Quarto implementation;
3. confirmed implementation defects and unresolved scientific choices;
4. repairs that do not themselves select a new substantive result; and
5. major gates that require author approval before fitting or reporting.

This is not a result approval. Numerical values below describe the frozen
current render or saved baseline only. They must not be copied into the
Nature Health manuscript until the canonical clean rerun, result-difference
audit, metric re-audit, and every applicable major gate are complete.

The governing records are:

- `audit/evidence/preregistration_contract.md`;
- `audit/ledgers/hypothesis_contracts.csv`;
- `audit/ledgers/deviation_register.csv`;
- `audit/ledgers/finding_register.csv`;
- `audit/decisions/metric_validity.md`;
- `audit/decisions/metric_implementation_parameters.md`;
- `audit/decisions/placement_decision.md`;
- `audit/decisions/saturation_boundary.md`;
- `audit/findings/timestamp_dst_fallback.md`;
- `audit/findings/state_precedence_and_channel_mask.md`; and
- `audit/findings/heterogeneous_source_epochs.md`.

If this map conflicts with a later approved decision record, the later record
controls. This map must then be updated before the affected hypothesis
notebook is implemented.

### Static-verification note

Numerical inspection used R 4.6.1 with:

- `lme4` 2.0.1;
- `glmmTMB` 1.1.14;
- `mgcv` 1.9.4;
- `gratia` 0.11.2;
- `emmeans` 2.0.3; and
- `dplyr` 1.2.1.

R loaded these hashed baseline objects:

- `data/metrics_glasses.RData`, SHA-256
  `9595cb7c574672cf2c8ff89ac3d227f3f7ff11eca57776609e19599561b2d441`;
- `data/metrics_chest.RData`, SHA-256
  `4498d677a8fc7d47168ab2f03731f2dc67b419102b7c818305925273d57c818c`;
- `data/metrics_separate_glasses.RData`, SHA-256
  `f4b8ddfdbd4ee2e577957ed6a89f65a7b44581bba916e786147dcd40c94a234b`;
  and
- `data/metrics_separate_chest.RData`, SHA-256
  `f1ab7345966bdaa8705a03745798d99c3d945fe0119f2476a5dd6e9a53f5de2f`.

R was used only to enumerate schemas, metric rows, finite-value support,
participant and participant-day counts, demographic factor support, timestamp
spacing, and the AR-sequence starts implied by the saved data. No H09–H11
model was refit.

The current rendered `docs/RQ3.html` and `docs/RQ3_chest.html` were inspected
as output evidence. Their SHA-256 hashes are respectively
`a4fa3c566d954dfd939d8fba94f0ecf05c675c02411ac4732ea74da1c9d4c368`
and
`de4bf82e03978c9a1b7747107dba3345f6f011e96bca3f77eea2f57e4fc4991e`.
They report the former R 4.5.0 environment and are not independent validation.

The current H09 source retrieves chronotype dynamically with
`melidosData::load_data("chronotype")`; it does not persist the questionnaire
input or exact joined model frames. The rendered source reports an
\(MSF_{sc}\) range from 01:15:43 to 08:07:51, but participant, site, and
missingness counts after the chronotype join are not durable artifacts.
Canonical preparation must pin both MCTQ and MEQ sources and export their
schemas and sample flow.

## Shared migration rules

### Canonical artifacts and scenarios

Each notebook consumes one explicit model-data object:

- `notebooks/hypotheses/H09.qmd` consumes
  `artifacts/06_model_data/H09.rds`;
- `notebooks/hypotheses/H10.qmd` consumes
  `artifacts/06_model_data/H10.rds`; and
- `notebooks/hypotheses/H11.qmd` consumes
  `artifacts/06_model_data/H11.rds` plus a versioned approved H02 temporal
  specification.

Every object must carry:

- placement and scenario;
- producer and input hashes;
- source release and acquisition provenance;
- site, participant, participant-day, and time keys as applicable;
- variable, construct, and unit dictionaries;
- factor levels, reference levels, and contrast definitions;
- inclusion flags and exclusion or non-estimability reasons;
- ordinary and metric-specific support;
- questionnaire construction, scoring, and missing-item rules;
- the exact model frame for every comparison; and
- sample flow at every analytical unit.

The notebooks must not call `load()`, download data, install packages, mutate
shared global objects, or depend on an earlier hypothesis's fitted objects.
They may consume an approved, versioned H02 temporal-model specification, but
not H02 significance, model objects, or predicted values.

The same parameterized implementation is used for:

1. `placement = "glasses", scenario = "primary"`;
2. `placement = "glasses", scenario = "paired_common_sample"`;
3. `placement = "chest", scenario = "paired_common_sample"`; and
4. a separately labelled all-chest contextual scenario if retained.

No H09–H11 model pools placements or treats chest observations as additional
independent ocular observations.

### Common preprocessing inherited by H09–H11

The canonical model data inherit the approved common pipeline:

- one-minute aggregation is source-epoch aware and requires complete expected
  subepoch support in the primary analysis;
- true `datetime_utc` controls keys, ordering, elapsed duration, gaps, and
  adjacency;
- `datetime_wall` is the deliberately reinterpreted common local-clock
  coordinate for timing metrics and within-day curves;
- repeated fall-back wall bins are averaged only for declared clock-aligned
  analyses, while source offsets, fold status, and real elapsed intervals are
  retained;
- the diary interval from `sleepprep` through wake is authoritative;
- wear-log `sleep` is provenance only;
- only wear-log `off` outside the diary sleep window is invalid non-wear;
- invalid non-wear masks analytical MEDI and LIGHT together, while raw
  channels remain immutable;
- one-minute MEDI is valid only below \(10^5\) lx;
- the registered 50%-per-hour and 80%-per-day eligibility rules apply before
  metric-specific support;
- a failed metric becomes reason-coded `NA` without discarding an otherwise
  eligible participant-day; and
- full-day metrics are explicitly hybrid: near-eye during wake/pre-sleep and
  bedside environmental measurement during diary-defined sleep.

No L5 value is produced. The darkest-window level metric is L10, and the
darkest-window timing metric is the midpoint of L10.

### Common inferential and reporting rules

- Every comparison uses identical model-frame rows and fails on a key
  mismatch.
- Questionnaire and demographic joins are asserted as
  many-measurements-to-one-participant joins; duplicate covariate keys fail.
- IDs are asserted unique across sites or represented explicitly as
  `site:participant`.
- Transformations, families, links, and units come from one versioned metric
  registry.
- Gaussian mixed models with different fixed effects are compared under ML;
  REML may be used for final estimation only after structure is fixed.
- GAM/GAMM structure comparisons use identical rows, a common valid
  likelihood criterion, and a common declared autocorrelation strategy.
  fREML AIC values from models with different mean structures and separately
  estimated `rho` values are not treated as comparable evidence.
- Main associations, predictor-by-site interactions, and site-specific
  estimates are distinct estimands and receive declared multiplicity
  treatment.
- Every BH family is assembled as a complete vector before
  `p.adjust(..., method = "BH")`. Planned non-estimable members remain in the
  registry with `NA` and a reason.
- Repeated scalar calls such as
  `p.adjust(p, method = "fdr", n = 5)` are not vector-wide BH. With one
  supplied p-value, BH has no cross-test ranks and the result is
  Bonferroni-like.
- Estimates and 95% intervals are reported in practical units. P-values,
  selection flags, and significance colouring do not replace them.
- Model-specific diagnostics are required. Diagnostics inherited from a base
  metric model do not validate a new predictor or interaction.
- Marginal or conditional \(R^2\) belongs to a named fitted model. Variance
  across correlated prediction terms is not an additive variance
  decomposition and is not called variance explained.
- Models report actual participants, participant-days, observations, sites,
  placement, predictor support, and outcome-specific missingness.
- All current claims listed below reopen if their sample, estimate, interval,
  adjusted inference, model, or interpretation changes.

## Source-to-canonical map

| Unit | Current near-eye implementation | Current chest implementation | Canonical destination |
|---|---|---|---|
| H09 | `RQ3.qmd:283-568`; shared registry `RQ3.qmd:120-146`; helpers `scripts/fitting.R:1-54`, `scripts/helpers.R:230-269` | `RQ3_chest.qmd:279-564`, a near-literal copy with chest inputs and paths | `notebooks/hypotheses/H09.qmd` |
| H10 | `RQ3.qmd:570-855`; shared registry `RQ3.qmd:120-146`; helpers `scripts/fitting.R:1-54`, `scripts/helpers.R:230-269` | `RQ3_chest.qmd:566-851`; table path is not placement-specific | `notebooks/hypotheses/H10.qmd` |
| H11 | `RQ3.qmd:857-1308`; 30-minute producer `data_preparation.qmd:437-482` | `RQ3_chest.qmd:853-1304`; same model code with chest input | `notebooks/hypotheses/H11.qmd` |

The manuscript claims are at `index.qmd:365-377`; current supplementary
figure and table inclusions are at `index.qmd:671-675` and
`index.qmd:693-695`. The current website render order is near-eye RQ3,
chest RQ3, then manuscript (`_quarto.yml:10-14`), which makes shared output
paths consequential.

## Current baseline support

The frozen metric registries are not canonical outputs, but they establish
the baseline that result-difference tables must reconcile.

### H09 timing metrics before chronotype joining

| Metric | Near-eye finite participant-days | Near-eye participants | Chest finite participant-days | Chest participants |
|---|---:|---:|---:|---:|
| M10 midpoint | 811 | 141 | 897 | 154 |
| L10 midpoint | 811 | 141 | 897 | 154 |
| Mean timing above 250 lx | 778 | 141 | 867 | 154 |
| First timing above 250 lx | 778 | 141 | 867 | 154 |
| Last timing above 250 lx | 778 | 141 | 867 | 154 |

These counts precede MCTQ/MEQ missingness and the canonical metric-support
rules. The current near-eye stored ranges are 4.98–18.98 h for M10 midpoint,
-11.88–11.98 h for the recentered L10 midpoint, 8.15–19.84 h for mean timing,
0–18.53 h for first timing, and 8.73–23.98 h for last timing. These ranges
show why wrap-boundary validation is required; they do not establish that a
linear outcome model is valid.

### H10 metrics before model-specific complete cases

| Current outcome group | Near-eye finite values | Chest finite values |
|---|---:|---:|
| IS and IV, each | 141 participants | 154 participants |
| Mean, M10 mean, M10 midpoint, L10 mean, L10 midpoint, duration >1,000 lx, longest period >250 lx, and dose, each | 811 participant-days | 897 participant-days |
| Mean, first, and last timing >250 lx, each | 778 participant-days | 867 participant-days |
| MDER | 725 participant-days / 140 participants | 729 participant-days / 154 participants |
| Pre-sleep duration <10 lx | 780 participant-days | 867 participant-days |
| Sleep duration <1 lx | 790 participant-days | 878 participant-days |
| Wake duration >250 lx | 755 participant-days / 140 participants | 839 participant-days / 153 participants |

Age and sex are finite for all 141 near-eye and 154 chest participants in the
saved registries. The observed sex categories are 79 Female and 62 Male for
near-eye, and 86 Female and 68 Male for chest. Every represented site contains
both categories, but the smallest near-eye site cell is UCR with 4 Female and
2 Male participants; the smallest chest cells include TUM with 6 Female and
4 Male participants. Site interactions therefore need sparse-cell and
influence checks even though no cell is empty.

The collected gender categories are 80 Woman and 61 Man for near-eye, and 87
Woman and 67 Man for chest. There is one participant in each placement
registry for whom the binary sex and gender labels do not map to the same
binary grouping. Sex and gender must remain separate constructs rather than
interchangeable labels.

### H11 temporal input before the demographic join

| Baseline item | Near-eye | Chest |
|---|---:|---:|
| Stored 30-minute rows | 38,832 | 42,912 |
| Participants | 141 | 154 |
| Participant-days | 809 | 894 |
| Finite MEDI rows | 37,603 | 41,664 |
| Current participant-only `AR.start` values | 141 | 154 |
| Elapsed-time sequence starts after response missingness | 550 | 576 |
| Participant-day-or-gap sequence starts | 1,167 | 1,276 |

The finite-response streams contain 409 near-eye and 422 chest positive
within-participant discontinuities beyond the expected 30-minute step. A
participant-only start flag necessarily bridges many missing intervals. The
canonical count will differ after the approved preprocessing and support
repairs.

# H09: Chronotype and exposure timing

## Preregistered contract and current estimand

H09 states that five timing-based exposure metrics are associated with
chronotype measured by both MCTQ and MEQ. The registered model is
(`audit/evidence/preregistration_contract.md:172-177`):

```text
Metric ~ Predictor * Site +
  (1 | Site:Participant)
```

The current implementation uses only MCTQ \(MSF_{sc}\), fits five linear
Gaussian mixed models, and reports a chronotype-only slope. MEQ is absent.
The current reported estimand is therefore neither the complete registered
chronotype contract nor site-adjusted.

The current metric set also contains the open `DEV-008` deviation: mean timing
above 250 lx replaces the registered midpoint of the longest continuous
period above 250 lx. This changes one outcome and must be closed explicitly.

## Exact current inputs, metric set, and filters

### Inputs and join

- Near-eye metrics: `data/metrics_glasses.RData`.
- Chest metrics: `data/metrics_chest.RData`.
- Chronotype:
  `melidosData::load_data("chronotype") |> flatten_data()`.
- Current join key: `site`, `Id`.
- Current retained predictor: `msf_sc`, converted from seconds to decimal
  hours (`RQ3.qmd:311-318`; chest `RQ3_chest.qmd:307-314`).

The current code filters the metric registry to `metric_type == "timing"` and
removes every name containing `onset` or `offset`
(`RQ3.qmd:322-339`). After the shared model registry removes response-less
rows, the five outcomes are:

1. M10 midpoint;
2. L10 midpoint;
3. mean timing above 250 lx;
4. first timing above 250 lx; and
5. last timing above 250 lx.

All five use response `metric`, engine `lmer`, and a Gaussian family
(`RQ3.qmd:120-146`). The metric frames are joined separately to chronotype and
rows with missing `msf_sc` are dropped (`RQ3.qmd:343-348`). Join cardinality,
duplicate participant keys, MCTQ scoring, MEQ scoring, and model-specific
sample flow are not checked or persisted.

The source argues that linear modelling is adequate because all observed
\(MSF_{sc}\) values are after midnight (`RQ3.qmd:318`). That establishes a
current predictor range, not the linear validity of every timing outcome.
The recentered L10 midpoint nearly spans the -12/+12 cut, and first/last
timing approach 0/24. Each timing variable needs its own circular or
unwrapping check.

## Exact current formulas, comparisons, and references

For each metric, the current formulas are
(`RQ3.qmd:327-332`; chest `RQ3_chest.qmd:323-328`):

```text
H9_full:
metric ~ site * msf_sc + (1 | Id)

H9_site_only:
metric ~ site + (1 | Id)

H9_intercept_only:
metric ~ 1 + (1 | Id)

H9_additive:
metric ~ site + msf_sc + (1 | Id)

H9_chronotype_only:
metric ~ msf_sc + (1 | Id)
```

The stated confirmatory formula is `metric ~ chronotype * site`, and the
source says site is sum-coded (`RQ3.qmd:291-307`). In the actual model fit:

- `fit_model()` passes no contrast argument (`scripts/fitting.R:6-14`);
- no global contrast option is set in RQ3 or its sourced helpers; and
- only a separate exploratory `lm(msf_sc ~ site)` explicitly requests
  `contr.sum` (`RQ3.qmd:551-559`).

The clean-document main models therefore use the factor's default treatment
coding, not the claimed sum coding.

The current comparisons are (`RQ3.qmd:414-427`):

```text
intercept_only vs chronotype_only:
reported confirmatory chronotype test, with no site adjustment

additive vs full:
site-by-chronotype interaction

chronotype_only vs additive:
site main effect
```

A significance-driven decision tree creates an `H9_model` object from the
three comparisons (`RQ3.qmd:429-443`). That selected object is not used for
the reported slope, interval, or \(R^2\). Instead:

- `emtrends()` always uses `H9_chronotype_only`
  (`RQ3.qmd:445-450`); and
- `r2_helper()` always uses `H9_chronotype_only`
  (`RQ3.qmd:454-461`).

The output estimates therefore come from a different model than the stated
site-adjusted or selected model.

## Exact current multiplicity

The prose declares:

- five metric comparisons for the confirmatory analysis; and
- `n = 9` for sites/interactions (`RQ3.qmd:305-307`).

The code sets `H9_fdr_n` to five and sends each scalar p-value from all three
comparison types separately to `model_comp_p(..., n = H9_fdr_n)`
(`RQ3.qmd:337-339`, `RQ3.qmd:417-427`). `model_comp_p()` then calls:

```r
p.adjust(p.value, method = "fdr", n = n)
```

on that one value (`scripts/fitting.R:45-54`). Thus:

- no five-member p-value vector is assembled;
- the output is Bonferroni-like rather than ranked BH;
- the claimed nine-member site family is not implemented; and
- MEQ contributes no tests to any family.

`n` can tell `p.adjust()` the intended family size, but it cannot supply the
missing ranks of the other p-values. Passing one p-value at a time does not
implement within-hypothesis BH.

## Current outputs and claims

Current files are:

- `tables/H9.png`;
- `tables/chest/H9.png`;
- `figures/Fig7.pdf` and `.png`;
- `figures/chest/Fig7.pdf` and `.png`; and
- manually copied `assets/H9.png` and `assets/Fig7.png`.

No chronotype input, model frame, fitted model, diagnostics, sample flow, or
source-data CSV is persisted.

The current near-eye render reports slopes of 0.31, 0.40, 0.32, and 0.44 h
per 1 h later \(MSF_{sc}\) for M10 midpoint, L10 midpoint, mean timing, and
first timing, respectively, all with displayed p-values below 0.001.
Last timing has a displayed p-value of 0.12. Reported marginal \(R^2\) values
are 0.05–0.08. The chest render reports corresponding slopes of 0.31, 0.32,
0.39, and 0.57 h and a last-timing p-value above 0.9.

The manuscript reproduces the near-eye values and concludes that chronotype
shifted exposure timing (`index.qmd:365-367`). Its supplementary figure is a
pooled raw scatterplot with an ordinary `lm` smooth, not a prediction from the
mixed model (`RQ3.qmd:517-545`; `index.qmd:671`). Those values and that claim
are reopened.

## Confirmed defects and risks

1. **Registered predictor omitted.** MEQ is absent from code, outputs, and
   deviation documentation.
2. **Wrong primary comparison (`IMP-009`).** The reported chronotype test
   compares intercept-only with chronotype-only and omits site.
3. **Estimate provenance mismatch (`IMP-009`).** Slopes and \(R^2\) come from
   the chronotype-only model even when another model is selected.
4. **Scalar multiplicity (`IMP-001`, `FIND-005`).** Five p-values are never
   adjusted as one vector.
5. **Interaction-family mismatch.** The prose says `n = 9`; code applies
   scalar `n = 5`.
6. **False contrast-coding claim.** The main models do not explicitly use sum
   coding.
7. **Significance-driven model selection.** Adjusted p-values determine the
   model object, but the selected model is then ignored for reporting.
8. **No durable questionnaire provenance.** MCTQ/MEQ source releases, scoring,
   missingness, and joined counts are absent.
9. **No model-specific diagnostics.** The notebook says diagnostics were
   checked in RQ1 (`RQ3.qmd:409`), which cannot validate chronotype slopes,
   interactions, or influence.
10. **Timing topology not verified.** A predictor lying after midnight does
    not make all clock-time outcomes linear.
11. **Raw pooled display.** The displayed `lm` smooth ignores site,
    participant clustering, and selected-model structure.
12. **Open outcome deviation (`DEV-008`).** Mean timing above 250 lx is not the
    registered midpoint of the longest period above 250 lx.

## Proposed repaired specification

### Chronotype-source and timing contracts

The H09 model-data producer must:

- pin MCTQ and MEQ source revisions and hashes;
- assert one questionnaire row per site-participant;
- document item scoring, units, correction rules, valid ranges, missing-item
  rules, and dates;
- retain MCTQ \(MSF_{sc}\) and the registered MEQ score as distinct constructs;
- report their correlation and missingness descriptively without using one
  to select the other;
- export site-by-instrument participant counts;
- merge them many-to-one onto each metric frame with cardinality checks; and
- retain exact complete-case keys separately for every
  metric-by-instrument model.

For each timing outcome, the producer must store:

- clock representation and cut point;
- observed range and density near the cut;
- circular concentration or an equivalent wrap diagnostic;
- support and reason-coded missingness;
- whether the metric is safely unwrapped for linear modelling; and
- the practical unit of a slope.

If a timing outcome crosses its cut materially, use a declared circular or
harmonic model, or define and validate a fixed unwrapping rule before fitting.
Do not choose the rule from which version produces the smaller p-value.

### H09 major gates

`H09-G1` must decide the roles of MCTQ and MEQ. The registered default is to
restore both. Omitting MEQ requires a documented estimand deviation and a
reason grounded in construct validity or data availability, not its observed
result.

`H09-G2` must close `DEV-008`: either restore the registered midpoint of the
longest period above 250 lx or approve mean timing above 250 lx as the adapted
outcome. If the adaptation remains, the registered metric may be shown as a
named sensitivity when admissible.

`H09-G3` must declare the complete multiplicity partition before models are
examined. A defensible default is separate five-member main-association
families for MCTQ and MEQ, and separate five-member omnibus-interaction
families for each instrument. A combined ten-member main family is also
coherent if both instruments are treated as one inferential family, but this
choice cannot be inferred after seeing results.

### Primary and interaction models

For each approved instrument and metric, create one complete common frame and
fit:

```text
M0:
g(metric) ~ site +
  (1 | site:participant)

M_main:
g(metric) ~ site + chronotype +
  (1 | site:participant)

M_full:
g(metric) ~ site * chronotype +
  (1 | site:participant)
```

Here `g` comes from the timing-metric registry. For safely unwrapped timing
hours it may be the identity transformation; circular outcomes require their
approved alternative.

- Compare `M0` with `M_main` for the site-adjusted average chronotype
  association.
- Compare `M_main` with `M_full` for site heterogeneity.
- Use ML for differing fixed effects and refit the approved final Gaussian
  mixed model with REML.
- Set site contrasts explicitly and store them in the model manifest.
- Use an explicit chronotype reference and scale, such as change per one hour
  \(MSF_{sc}\) or the validated MEQ unit.
- Report site-adjusted practical slopes and intervals from `M_main`; if
  `M_full` is retained, report equal-site marginal trends and site-specific
  departures with their own uncertainty.
- Do not choose the reporting model through adjusted-significance branches.

### Multiplicity

Subject to `H09-G3`, suggested family IDs are:

- `H09-F1-MCTQ-main`: five site-adjusted MCTQ associations;
- `H09-F2-MEQ-main`: five site-adjusted MEQ associations;
- `H09-F3-MCTQ-interaction`: five omnibus MCTQ-by-site interactions;
- `H09-F4-MEQ-interaction`: five omnibus MEQ-by-site interactions; and
- `H09-F5-site-trends`: all requested metric-by-site trend contrasts across
  both instruments, if these contrasts are inferential rather than
  descriptive.

Each family is assembled before BH adjustment. Omnibus interactions count
once per metric; nine site levels are not themselves nine omnibus tests.

### Required diagnostics

- MCTQ and MEQ scoring, ranges, missingness, and site support;
- join key uniqueness and row preservation;
- metric-specific participants, participant-days, sites, and instrument
  support;
- clock-cut and circular/unwrapping diagnostics;
- linearity of chronotype slopes;
- response distribution and transformation checks;
- residual distribution, heteroscedasticity, and participant/date dependence;
- convergence, gradients, Hessian, and singularity;
- fixed-effect rank and site-by-instrument support;
- participant and site influence, including leave-one-site-out estimates;
- equal-site versus observed-sample marginalization;
- exact model-frame identity for each comparison; and
- all-near-eye versus paired/common-sample near-eye and chest estimates.

## Required H09 result-difference checks

Compare current and repaired:

- five current MCTQ outcomes versus the approved MCTQ/MEQ contract;
- registered longest-period midpoint versus mean timing above 250 lx;
- metric and questionnaire rows, participants, days, and sites;
- MCTQ/MEQ missingness and common samples;
- current intercept-only-versus-chronotype-only test versus the repaired
  site-adjusted test;
- scalar-adjusted values versus vector-wide BH values;
- current chronotype-only slopes/\(R^2\) versus approved-model estimates and
  intervals;
- treatment coding versus explicit site coding and marginalization;
- linear versus circular/unwrapped sensitivity;
- site-interaction estimability and leave-one-site-out influence; and
- all-near-eye versus paired/common-sample near-eye and chest conclusions.

Every number at `index.qmd:367` must map to one verified result row. A changed
estimate, interval, adjusted inference, instrument role, sample, timing
representation, or interpretation reopens the claim.

## H09 dependencies and reopening

H09 depends on admissible supported timing metrics, the MCTQ/MEQ provenance
artifact, the dual-time-axis repair, and the placement/common-sample manifest.
Any change to a timing metric, chronotype score, clock representation, family
partition, site adjustment, or influence result reopens H09.

# H10: Age, sex, and personal light-exposure metrics

## Preregistered contract and current estimand

H10 states that personal light-exposure metrics depend on age and sex. The
registered model for each predictor is
(`audit/evidence/preregistration_contract.md:179-186`):

```text
Metric ~ Predictor * Site +
  (1 | Site:Participant)
```

Age and biological sex are distinct registered predictors. Gender was
collected but is not named as an H10 predictor in the preregistration. It
must be reported as a separate construct and not silently substituted for
sex.

The current analysis fits age and sex additive models and both site
interactions, but tests only age-by-site. It combines the two main-effect
counts into a nominal `n = 34` while adjusting each p-value separately.

## Exact current inputs, metric set, and filters

### Inputs

- Near-eye: `data/metrics_glasses.RData`.
- Chest: `data/metrics_chest.RData`.
- Age, sex, and gender are already embedded in each metric frame by
  `metric_preparation.qmd:90-107` and
  `metric_preparation.qmd:115-180`.
- A separately loaded demographics table is used only for preliminary
  site-distribution plots and tests (`RQ3.qmd:597-615`).

The current H10 code joins the shared response registry and retains every row
with a non-missing response (`RQ3.qmd:617-639`). This yields 17 outcomes:

1. interdaily stability;
2. intradaily variability;
3. daily geometric mean MEDI;
4. M10 mean;
5. M10 midpoint;
6. L10 mean;
7. L10 midpoint;
8. duration above 1,000 lx;
9. longest period above 250 lx;
10. mean timing above 250 lx;
11. first timing above 250 lx;
12. last timing above 250 lx;
13. dose;
14. MDER;
15. pre-sleep duration below 10 lx;
16. sleep duration below 1 lx; and
17. wake duration above 250 lx.

The generic full-day duration above 250 lx and the four M10/L10 onset/offset
rows are excluded through the shared response registry. No immutable H10
inclusion manifest exists.

## Exact current response, family, and model map

| Outcomes | Current response | Current engine/family |
|---|---|---|
| Interdaily stability | `qlogis(metric)` | `lm`, Gaussian |
| Intradaily variability | `metric` | `lm`, Gaussian |
| Mean, M10 mean, L10 mean, dose, longest period >250 | `log_zero_inflated(metric)` | `lmer`, Gaussian |
| M10 midpoint, L10 midpoint, mean/first/last timing >250, MDER | `metric` | `lmer`, Gaussian |
| Duration >1,000, wake >250, pre-sleep <10, sleep <1 | `metric` | `glmmTMB`, Tweedie log |

For participant-level dynamics outcomes, the current code removes
`(1 | Id)` from every formula (`RQ3.qmd:630-632`). For participant-day
outcomes, the exact formulas are (`RQ3.qmd:623-629`):

```text
H10_age_additive:
response ~ site + age + (1 | Id)

H10_sex_additive:
response ~ site + sex + (1 | Id)

H10_site_only:
response ~ site + (1 | Id)

H10_age_only:
response ~ age + (1 | Id)

H10_intercept_only:
response ~ 1 + (1 | Id)

H10_age_full:
response ~ site * age + (1 | Id)

H10_sex_full:
response ~ site * sex + (1 | Id)
```

The source says site is sum-coded (`RQ3.qmd:583-585`), but `fit_model()` does
not set contrasts and no global sum-contrast option exists. The fitted H10
models use default treatment coding.

Current global participant IDs happen to be unique across sites in both saved
registries. The canonical implementation must assert that invariant or use
`site:participant` explicitly rather than relying on it silently.

## Exact current comparisons and multiplicity

The implemented comparisons are (`RQ3.qmd:721-737`):

```text
site_only vs sex_additive:
sex main association

site_only vs age_additive:
age main association

age_additive vs age_full:
age-by-site interaction
```

Although `H10_sex_full` is fitted, no sex-by-site comparison, p-value,
estimate, or table column is created. This leaves part of the registered
model untested.

The code calculates `H10_fdr_n = 17 * 2 = 34`
(`RQ3.qmd:635-639`). Each sex, age, and age-interaction p-value is then sent
separately to `model_comp_p(..., n = 34)`
(`RQ3.qmd:724-734`). Consequently:

- the 34 main-effect p-values are not one BH vector;
- age and sex are not adjusted as separate vectors;
- age-interaction p-values are each treated as though they belong to the same
  scalar `n = 34` convention;
- sex-interaction p-values do not exist; and
- the table's statement that all displayed values use FDR with `n = 34` is
  inaccurate.

The reported age slope is taken from `H10_age_additive`
(`RQ3.qmd:736-737`). The reported marginal \(R^2\), however, is computed from
`H10_age_only`, which omits site (`RQ3.qmd:755-763`). It is not the \(R^2\) of
the model described by the table or manuscript.

## Current construct handling and site support

The saved sex factor retains levels Female, Male, Intersex, and Prefer not to
say, but only Female and Male have observations. Gender retains Woman, Man,
Non-binary, Other, and Prefer not to say, but only Woman and Man have
observations. Empty categories must remain visible in the construct audit but
cannot be estimated.

Sex and gender are not interchangeable. The frozen registries contain one
participant whose binary sex and gender group labels differ. Replacing sex
with gender would therefore change the model frame or contrast membership,
not merely rename a factor.

All current site-by-sex cells are non-empty, but UCR near-eye has only six
participants and TUM has ten. High-dimensional sex-by-site interactions can
therefore be unstable despite a full-rank nominal table. Age ranges and
leverage must also be checked within site rather than only overall.

## Current outputs and claims

Current files are:

- `tables/H10.png`;
- `figures/Fig8.pdf` and `.png`;
- `figures/chest/Fig8.pdf` and `.png`; and
- manually copied `assets/H10.png` and `assets/Fig8.png`.

Both RQ3 documents write the table to the same path:

- near-eye: `RQ3.qmd:809-812`;
- chest: `RQ3_chest.qmd:805-808`.

Because chest RQ3 renders after near-eye RQ3 (`_quarto.yml:10-13`), the
placement identity of `tables/H10.png` is not stable. The current shared
target has SHA-256
`ff7fc2f792d1a0345a17bab6a15bab6a81bd1ead432dbdcab89fed9a8cecfff7`,
whereas `assets/H10.png` has
`c0e1c0972b614624b636f9be5b93eb21e805550ffcd2552fe490fbfb543b06ee`.
The manuscript asset therefore does not match the current producer target.

The current near-eye render reports one retained association:

- duration above 1,000 lx: adjusted p = 0.017;
- age slope 0.024 h/year with displayed interval 0.011–0.037; and
- marginal \(R^2 = 0.074\).

The manuscript converts this to 1.44 min/year and approximately 3%–4% per
year, while reporting all sex results as non-significant
(`index.qmd:369-373`).

The chest render reports five age associations after its scalar adjustment.
For several log-transformed Gaussian outcomes, the current table leaves the
age estimate blank and exposes unmatched `lower.CL`/`upper.CL` columns because
the formatting code merges only the asymptotic interval-column convention
used by other engines (`RQ3_chest.qmd:764-802`). This is an output-generation
defect, not evidence that the estimate is zero.

The displayed age figure is an unadjusted pooled `lm` smooth
(`RQ3.qmd:819-832`). Its y-axis calls duration above 1,000 lx “Local time of
day” (`RQ3.qmd:830`). Panel B unnests nearly all metric frames and therefore
repeats participant ages by metric before drawing a site distribution
(`RQ3.qmd:834-845`).

## Confirmed defects and risks

1. **Scalar multiplicity (`IMP-001`, `FIND-005`).** Neither the combined
   34-member set nor separate predictor families are adjusted as vectors.
2. **Registered sex interaction omitted from inference.** The model is fitted
   but never compared or reported.
3. **Interaction-family inconsistency.** Age interactions receive the scalar
   `n = 34` rule; sex interactions receive no p-values.
4. **False sum-coding claim.** Main H10 models use default treatment coding.
5. **Wrong \(R^2\) provenance.** \(R^2\) comes from age-only rather than the
   reported site-adjusted age model.
6. **Output collision (`IMP-011`).** Chest and near-eye tables share one path.
7. **Manual/stale manuscript asset.** `assets/H10.png` does not hash-match the
   current producer target.
8. **Mixed-engine table corruption.** Some chest age estimates are blank
   because interval column names are merged inconsistently.
9. **No sex estimates or intervals.** A null claim is made from p-values
   without a practical contrast or precision.
10. **Sparse-cell risk.** Nominally non-empty site-by-sex cells can still
    produce unstable interactions and strong site influence.
11. **Construct ambiguity.** Sex and gender exist as separate variables, but
    the current report does not explain their roles.
12. **No model-specific diagnostics.** The notebook relies on RQ1 diagnostics
    (`RQ3.qmd:716`) rather than checking the age/sex models.
13. **Misleading display.** The y-unit is wrong and the site distribution
    repeats records across metrics.
14. **Selection-only reporting.** Only adjusted-significant age rows receive
    estimates; all other effect sizes and intervals are suppressed.

## Proposed repaired specification

### Construct and metric contracts

The H10 model-data artifact must:

- identify age, sex, and gender as distinct variables with their question
  wording, coding, source release, and missingness;
- use biological sex for the registered H10 analysis;
- describe gender separately in the cohort table;
- make no gender model part of H10 unless separately approved and labelled
  exploratory;
- retain empty registered response categories in the construct dictionary;
- report site-by-sex and site-by-gender counts without exposing participant
  identities;
- fix sex reference coding before fitting, with the reporting contrast
  explicitly named;
- audit age range and leverage within every site;
- retain the full planned metric set independently of observed significance;
  and
- inherit reason-coded metric support, L10, hybrid sleep-environment wording,
  and the \(10^5\)-lx rule.

### H10 major gates

`H10-G1` must declare the family partition. The recommended specification is
four complete 17-member families:

1. age main associations;
2. sex main associations;
3. age-by-site omnibus interactions; and
4. sex-by-site omnibus interactions.

Keeping one 34-member age-plus-sex main family is a coherent recognizability
option if that is judged the intended preregistered family. It must be chosen
before repaired results are examined. Interactions must not be mixed into a
main-effect family merely because the same helper accepts `n = 34`.

`H10-G2` must identify the primary estimand. The recommended interpretation is
the site-adjusted average age or sex association, with predictor-by-site
heterogeneity as a separately reported registered analysis. A joint test that
adds both the predictor and every interaction answers a different question
and requires explicit approval.

The registered sex construct itself is not an open gate: biological sex
remains the H10 predictor. Adding gender as another inferential predictor
would expand the analysis and requires separate approval.

### Primary and interaction models

For each metric, create predictor-specific common frames and fit:

```text
M0:
g(metric) ~ site +
  participant structure

M_age:
g(metric) ~ site + age +
  participant structure

M_age_full:
g(metric) ~ site * age +
  participant structure

M_sex:
g(metric) ~ site + sex +
  participant structure

M_sex_full:
g(metric) ~ site * sex +
  participant structure
```

For participant-day metrics, the participant structure is
`(1 | site:participant)`. Participant-level IS and IV use an ordinary model
with site adjustment and no fictitious repeated-measure term.

- Compare `M0` with `M_age` and `M_sex` for main associations.
- Compare each additive model with its corresponding full model for
  heterogeneity.
- Use identical rows within each comparison and ML for differing fixed
  effects; refit the approved final Gaussian model under REML.
- Use explicit site and sex contrasts and store them in the manifest.
- Report age slopes over a practically readable increment, such as ten years,
  without hiding the per-year estimate.
- Report Female-to-Male or the approved reverse contrast explicitly, with
  intervals.
- For log or log-link models, report multiplicative factors or percent
  changes; for timing/duration, also report minutes or hours where valid.
- Calculate model fit only from the named reported model. Do not describe
  marginal \(R^2\) as the percentage of outcome variance uniquely explained
  by age or sex.
- If a site interaction is rank-deficient, singular, or dominated by a sparse
  site, retain the failed model and classify the interaction as
  non-estimable rather than silently simplifying it.

### Multiplicity

Subject to `H10-G1`, suggested family IDs are:

- `H10-F1-age-main`;
- `H10-F2-sex-main`;
- `H10-F3-age-site-interaction`;
- `H10-F4-sex-site-interaction`; and
- separately declared families for any site-specific slopes or contrasts.

Each vector contains all 17 planned metric members, including
reason-coded `NA` entries when a model is not estimable. Raw p-values, family
size, rank, and BH-adjusted values are retained.

### Required diagnostics

- demographic source, coding, and participant-key uniqueness;
- age, sex, and gender missingness and site support;
- within-site age ranges and leverage;
- site-by-sex cell sizes, design rank, and aliased coefficients;
- metric-specific participants, days, sites, and complete cases;
- transformation/family/link and zero-support checks;
- convergence, Hessian, gradients, and singularity;
- residual distribution, dispersion, heteroscedasticity, and repeated-day
  dependence;
- participant and leave-one-site-out influence;
- equal-site versus observed-sample marginalization;
- stable practical-scale back-transformation for every engine;
- exact comparison-frame identity; and
- all-near-eye versus paired/common-sample near-eye and chest estimates.

## Required H10 result-difference checks

Compare current and repaired:

- all 17 planned metric rows and admissibility outcomes;
- metric-specific observations, participants, days, and sites;
- demographic membership and site-by-sex support;
- combined scalar `n = 34` values versus the approved vector-wide families;
- the missing current sex-interaction family versus repaired results;
- treatment coding versus explicit coding and marginalization;
- current age-only \(R^2\) versus fit indices from the reported model;
- age slopes and sex contrasts in practical units with intervals;
- full-sample and leave-one-site-out interaction estimates;
- current blank/misaligned chest table cells versus machine-readable estimates;
- current shared output target versus deterministic placement paths; and
- all-near-eye versus paired/common-sample near-eye and chest conclusions.

Every value and percentage at `index.qmd:371-373` is reopened. The
1.44-min/year conversion must be regenerated from the canonical source row,
not retained because the arithmetic conversion itself is correct.

## H10 dependencies and reopening

H10 depends on admissible daily/participant metrics, the demographic
construct artifact, the metric-family registry, and the
placement/common-sample manifest. Any change to metric admissibility,
construct coding, family partition, interaction status, model family, or
site-influence result reopens H10.

# H11: Sex-specific temporal exposure patterns

## Preregistered contract and current estimand

H11 asks whether diurnal exposure patterns differ by sex. The registered
outcome is hourly geometric-mean melanopic EDI, and the registered GAMM is
(`audit/evidence/preregistration_contract.md:188-194`):

```text
melEDI ~ Sex +
  s(Time, by = Sex, bs = "cc", k = 12) +
  s(Time, by = Site, bs = "fs", k = 12) +
  s(Site, bs = "re") +
  s(Participant, bs = "re")
```

The current analysis inherits the H02 adaptation to 30-minute arithmetic
mean MEDI, adds photoperiod state and participant-specific time curves, uses
sum-to-zero factor smooths instead of the registered bases, and omits the
registered parametric sex main effect. It therefore changes the outcome,
epoch, mean structure, and participant/site structure.

## Exact current input, aggregation, and model frame

The current input is:

- near-eye `metric_glasses_participanthour` from
  `data/metrics_separate_glasses.RData`; or
- chest `metric_chest_participanthour` from
  `data/metrics_separate_chest.RData`.

Despite the object name, the producer aggregates to 30-minute bins using:

```text
MEDI = arithmetic mean of available one-minute MEDI
geo.MEDI = geometric mean after the zero-aware log transform
```

(`data_preparation.qmd:437-469`). H11 models `MEDI`, not `geo.MEDI`
(`RQ3.qmd:888-898`). This is the documented H02 `DEV-012` adaptation, but
H11 has no corresponding entry in `_deviations.qmd`, which currently ends
after H07 (`DOC-001`).

H11 then:

- adds a decimal wall-clock `Time` and shifts it by 0.25 h;
- factors site, participant, sleep, Brown state, wear, and photoperiod state;
- constructs `Id_date`;
- transforms MEDI with
  `LightLogR::log_zero_inflated()` using its default +0.1 and base-10 log;
- computes photoperiod duration;
- sets `AR.start` only for the first row of each participant; and
- joins demographics by `site`, `Id`
  (`RQ3.qmd:883-904`).

The source does not explicitly sort by true UTC before `row_number()`, assert
the 30-minute interval, or recompute sequence starts after the model's
missing-value removal. The fitted frame is not saved.

## Exact current formulas and fitting

The current full and null formulas are
(`RQ3.qmd:929-933`):

```text
H11_full:
lzMEDI ~
  s(Time, k = 12) +
  s(Time, photoperiod.state, bs = "sz", k = 12) +
  s(Time, sex, bs = "sz", k = 12) +
  s(Time, site, bs = "sz", k = 12) +
  s(Time, Id, bs = "fs") +
  s(Id_date, bs = "re")

H11_null:
lzMEDI ~
  s(Time, k = 12) +
  s(Time, photoperiod.state, bs = "sz", k = 12) +
  s(Time, site, bs = "sz", k = 12) +
  s(Time, Id, bs = "fs") +
  s(Id_date, bs = "re")
```

Consequential differences from the contract are:

- neither model includes parametric `sex`;
- the sex difference is represented only by an `sz` time-deviation smooth;
- the overall `s(Time)` is not explicitly cyclic;
- site uses an `sz` time deviation rather than the registered site factor
  smooth plus site random effect;
- the registered `s(Site, bs = "re")` is absent;
- participant-specific time curves replace the registered participant random
  effect;
- participant-day random effects are added;
- photoperiod-state temporal deviations are added; and
- the dependent variable is 30-minute arithmetic rather than hourly
  geometric MEDI.

The omission of parametric sex constrains away or fails to estimate a
time-constant sex difference. A time-deviation smooth alone does not implement
the registered `Sex + sex-specific time smooth` estimand.

For each full/null formula, the code:

1. fits `bam(..., method = "fREML", discrete = TRUE)` without AR(1);
2. estimates a starting `rho` separately from that model;
3. refits the same formula with its separately estimated `rho` and the
   participant-only `AR.start`; and
4. compares the two final models with `AIC()`
   (`RQ3.qmd:939-1019`).

This comparison changes the smooth mean structure, uses fREML criteria, and
allows `rho` to differ between models. It does not provide a controlled AIC
comparison on a common likelihood/correlation specification.

## Current autocorrelation handling

The source flags only the first row per participant
(`RQ3.qmd:900-902`). In the frozen inputs this produces 141 near-eye and 154
chest starts.

After retaining finite response rows and sorting within participant by stored
datetime, the saved data contain:

- 550 near-eye and 576 chest elapsed-time sequences when every non-30-minute
  discontinuity starts a new sequence; and
- 1,167 near-eye and 1,276 chest starts when every participant-day and
  within-day gap starts a new sequence.

The current AR(1) therefore bridges missing response intervals and gaps
between non-contiguous recording days. Because `AR.start` is defined before
model-frame deletion, any missing predictor can create additional unmarked
adjacency. A residual ACF plot after such a fit does not repair the sequence
definition.

## Current comparison, variance claim, and curve inference

The source describes H11 as one comparison but incorrectly says it tests the
effect of site (`RQ3.qmd:873-877`). The actual AIC comparison removes the sex
smooth.

The near-eye render reports:

- `H11_full` AIC 64,944.31;
- `H11_null` AIC 64,952.13; and
- a lower full-model AIC by approximately 7.82.

The chest render reports:

- `H11_full` AIC 81,647.71;
- `H11_null` AIC 81,644.58; and
- a lower null-model AIC by approximately 3.13.

Despite the opposite chest result, the chest source repeats the near-eye prose
that sex will be included because delta AIC exceeds two
(`RQ3_chest.qmd:1011-1018`). This is an internal result-interpretation
contradiction.

The current “variance explained” block:

```r
Xp <- predict(H11_model_1, type = "terms")
variance <- apply(Xp, 2, var)
H11_R2 <- variance / sum(variance)
```

(`RQ3.qmd:971-977`). The code itself displays correlations among the term
predictions. Normalizing marginal variances of correlated terms does not
partition outcome variance or identify a unique share explained by sex. The
claim that sex explains less than 1% is unsupported (`IMP-005`).

The sex-difference curve uses `difference_sz(..., unconditional = FALSE,
level = 0.95)` and marks every clock bin whose pointwise interval excludes
zero (`RQ3.qmd:1113-1150`). It does not construct a simultaneous band over the
curve. A contiguous red segment cannot therefore be reported as a
family-wise-significant two-hour period.

## Current activity-context analysis

The exploratory activity block:

- joins light-exposure diary states onto the H11 30-minute data;
- removes sparse light-source levels even though the final model uses
  activity;
- pivots activity flags to long form;
- retains true activity flags and finite `lzMEDI`;
- collapses outdoor activity categories;
- sets `AR.start` only at participant start again; and
- fits activity-only and activity-plus-sex-smooth GAMs
  (`RQ3.qmd:1177-1308`).

The formulas still omit parametric sex:

```text
activity model:
common + activity time smooth + site/participant/day terms

activity-plus-sex model:
common + sex time smooth + activity time smooth +
  site/participant/day terms
```

Both use separately estimated `rho`, participant-only starts, and fREML. Their
AIC comparison is not tabulated or persisted. The activity join changes the
sample, and no exact common-sample comparison links the primary and
activity-context results.

Attenuation after adding self-reported activity would not by itself establish
mediation or that the sex pattern was “behaviourally driven.” Activity and
exposure are contemporaneous observational measurements and may share site,
schedule, measurement, and reporting structure.

## Current outputs and claims

Current files are:

- `figures/Fig13.pdf` and `.png`;
- `figures/chest/Fig13.pdf` and `.png`; and
- manually copied `assets/Fig13.png`.

No H11 model, exact model frame, `rho` record, sequence audit, diagnostics,
curve table, simultaneous interval, or source-data CSV is persisted.

The current source claims:

- sex explains less than 1% of variance;
- females have lower exposure for about two morning hours;
- the peak difference is approximately a factor of two; and
- adding activity removes the sex contribution
  (`RQ3.qmd:1022`, `RQ3.qmd:1171-1174`).

The combined figure caption incorrectly calls the H11 red segment
“deviations of work from free days” (`RQ3.qmd:1158-1162`). The manuscript
strengthens the result to significantly lower exposure from 08:00 to 10:00
and calls it behaviourally driven (`index.qmd:375-377`).

All these claims are reopened.

## Confirmed defects and risks

1. **Registered outcome changed (`DEV-012`).** H11 uses a 30-minute arithmetic
   outcome rather than hourly geometric MEDI.
2. **Parametric sex effect omitted.** The current full model does not implement
   the registered `Sex + sex-specific smooth` structure.
3. **Non-cyclic current time basis.** Neither the overall nor deviation
   smooth explicitly enforces midnight continuity.
4. **Site/participant structure changed.** Registered site and participant
   random effects are replaced or augmented without H11 deviation
   documentation.
5. **Undocumented photoperiod adjustment.** Photoperiod-state smooths enter
   both models without a recorded H11 rationale.
6. **Invalid sequence starts.** Participant-only `AR.start` bridges
   participant-days and hundreds of missing-response gaps.
7. **Ordering not asserted.** `row_number()` is used without an explicit
   true-UTC sort and epoch check.
8. **fREML AIC comparison (`IMP-010`).** Different smooth structures and
   separately derived `rho` values are compared by AIC.
9. **Invalid term “variance explained” (`IMP-005`).** Correlated prediction
   term variances are normalized as if additive.
10. **Pointwise-to-period overclaim.** Pointwise intervals are used to assert
    a significant time interval without simultaneous curve control.
11. **Chest interpretation contradiction.** The chest null has the lower AIC,
    but the source says sex is retained.
12. **Context sample mismatch.** The activity analysis changes the frame and
    does not compare sex estimates on an exact common sample.
13. **Causal/mediation overstatement.** “Behaviourally driven” is not
    identified by covariate attenuation.
14. **No durable diagnostics or source data.** ACF and appraisal plots exist
    only during render.
15. **Caption copy error.** H11 refers to work/free-day deviations.
16. **Deviation-document gap (`DOC-001`).** None of the H11 changes is
    documented in `_deviations.qmd`.

## Proposed repaired specification

### Outcome and temporal-support gate

`H11-G1` must choose between:

1. restoring the registered supported one-hour zero-aware geometric MEDI
   outcome; or
2. approving the supported 30-minute arithmetic MEDI adaptation as the H11
   primary outcome.

The first preserves the signed outcome. The second preserves the recognizable
current H02/H11 curve but is a major change in epoch, scale, denominator, and
dependence. It must inherit the approved H02 decision and be labelled as an
adaptation. If the 30-minute outcome is approved, the registered hourly
geometric outcome should be a named common-sample sensitivity when admissible.

Whichever outcome is chosen must:

- use the approved bin-level support rule;
- retain exact zeros;
- preserve gaps rather than compressing them;
- use true UTC for sequence construction;
- use `datetime_wall` for the common clock axis;
- average repeated fall-back wall bins only on that axis with provenance;
- distinguish waking near-eye from bedside sleep-environment observations;
  and
- store the exact model frame before fitting.

### Sex and model-structure gates

`H11-G2` must define the sex estimand. A transparent model sequence is:

```text
M0:
common temporal, site, participant, and day structure

M_level:
M0 + sex

M_pattern:
M_level + sex-specific cyclic time deviation
```

The registered full model contains both the parametric sex term and
sex-specific time smooth. The author must decide whether the primary H11
test is:

- `M0` versus `M_pattern`, a joint sex-level-plus-pattern test; or
- `M_level` versus `M_pattern`, a shape-specific pattern test with the
  constant sex difference controlled.

Both may be reported if their roles are declared before fitting, but they are
not the same estimand.

`H11-G3` must approve the temporal and hierarchical structure. The registered
starting point is an explicitly cyclic sex smooth, a site temporal factor
smooth, and site/participant random effects. The current additions of
participant-specific curves, participant-day effects, `sz` site deviations,
and photoperiod-state deviations may be retained only when identifiability,
concurvity, and diagnostics support them and their deviation status is
documented.

### Canonical fitting and autocorrelation

After the gates close:

- build all competing models on one exact frame;
- sort by site-participant and true UTC;
- define `AR.start` after every model-frame exclusion;
- start a new sequence at every participant-day boundary and any unexpected
  elapsed-time gap in the primary analysis;
- retain a named sensitivity that allows AR continuation across a contiguous
  midnight boundary if that better represents the approved dependence
  estimand;
- use the same declared `rho` strategy for compared models;
- compare differing smooth mean structures with a valid common
  ML-based criterion that preserves the preregistered delta-AIC rule;
- use fREML only for the final approved estimation fit;
- require explicit cyclic boundary checks at midnight;
- store basis dimensions, smoothing parameters, `rho`, sequence counts, and
  warnings; and
- fail comparisons when frames or sequence starts differ.

The exact mgcv implementation must be verified against the installed version.
Do not assume that changing a basis label alone preserves the intended
penalty, null space, or factor reference.

### Curve inference and practical reporting

`H11-G4` must approve global/simultaneous curve inference in place of the
current pointwise red-segment rule. The recommended reporting set is:

1. one declared global H11 model comparison;
2. the parametric sex contrast with interval;
3. sex-specific predicted curves on the practical MEDI scale;
4. a Female-to-Male difference or ratio curve with a simultaneous 95%
   interval;
5. any supported interval where the simultaneous band excludes the null;
6. the peak practical difference and its uncertainty; and
7. explicit acknowledgement when the data do not localize a stable interval.

No normalized prediction-term variance is reported as variance explained.
Model-level fit summaries may be reported with their exact definition, while
the practical curve and uncertainty carry the substantive interpretation.

### Activity-context analysis

`H11-G5` must classify the activity model as a contextual sensitivity, not a
mediation analysis, unless a separate causal estimand and design are approved.
The recommended sensitivity:

- uses the audited H04 activity dictionary;
- asserts one valid activity representation per modeled interval;
- fits primary and activity-adjusted sex models on the identical
  activity-complete common sample;
- uses identical sequence starts and `rho` strategy;
- reports how sample restriction alone changes the sex curve before activity
  is added;
- reports attenuation with intervals; and
- uses “attenuated after adjustment for recorded activity context,” not
  “behaviourally driven.”

### Multiplicity

- `H11-F1-primary`: the one declared global sex test.
- `H11-F2-level-shape`: parametric-level and shape-specific tests if both are
  treated as confirmatory; declare whether adjustment is required across the
  pair.
- Simultaneous curve intervals control within-curve inference and are not
  replaced by pointwise p-values.
- Activity-context analyses receive separate sensitivity labels and are not
  folded into the primary family post hoc.

### Required diagnostics

- selected outcome support and registered-outcome sensitivity;
- participant, participant-day, row, site, and site-by-sex counts;
- wall-clock fold provenance and midnight continuity;
- sorted true-UTC epoch and sequence-start audit;
- response missingness before and after all joins;
- sex reference, site-by-sex support, and design rank;
- basis dimension, k-index, smoothing parameters, and concurvity;
- ML comparison and final fREML provenance;
- fixed/common `rho` strategy and residual ACF by participant-day;
- residual distribution, heteroscedasticity, tails, and exact-zero behaviour;
- participant, site, day, and leave-one-site-out influence;
- simultaneous difference-band coverage and grid sensitivity;
- primary-versus-activity common-sample decomposition;
- all-near-eye versus paired/common-sample near-eye and chest curves; and
- prediction/source-data reconciliation at every displayed clock time.

## Required H11 result-difference checks

Compare current and repaired:

- registered hourly geometric versus current/adapted supported 30-minute
  arithmetic outcome;
- rows, participants, participant-days, sites, and site-by-sex support;
- current 141/154 participant-only starts versus elapsed-gap and
  participant-day-or-gap starts;
- model rows before and after response/covariate missingness;
- non-cyclic current basis versus approved cyclic structure;
- omission versus inclusion of parametric sex;
- current and approved site/participant/day/photoperiod structures;
- separately estimated-rho fREML AIC versus a valid common comparison;
- current near-eye and contradictory chest model preference;
- normalized prediction-term variances versus valid model-level reporting;
- pointwise red segments versus simultaneous difference intervals;
- current 08:00–10:00/factor-two claim versus repaired interval and peak
  uncertainty;
- unrestricted primary sample versus activity-complete common sample;
- sample restriction alone versus added activity adjustment;
- full-sample and leave-one-site-out sex curves; and
- all-near-eye versus paired/common-sample near-eye and chest conclusions.

Every statement at `index.qmd:375-377` must map to a verified model,
comparison, curve-source row, and simultaneous interval. Any change in
outcome, sex estimand, model structure, sequence rule, model preference,
localized interval, activity attenuation, or placement stability reopens the
claim.

## H11 dependencies and reopening

H11 depends on the approved H02 outcome/temporal specification, supported
temporal bins, dual time axes, demographic construct artifact, activity
dictionary for the sensitivity only, and the placement/common-sample
manifest. Any change to H02's approved outcome, support, basis,
autocorrelation rule, sex estimand, site structure, or activity sample
reopens H11.

# Canonical output contract for all three notebooks

Each completed audit HTML must also contain a visible, evaluated R code cell
that prints the exact Wilkinson formulas passed to every selected and
comparison model. The cell must obtain them from the actual formula builder or
fitted objects; one generic response formula is allowed only for genuinely
identical model structures.

Every H09–H11 placement/scenario run must produce:

1. an exact model-frame RDS containing only fitted keys and inclusion reasons;
2. fitted model RDS files for every declared model;
3. a model manifest with formula, family, link, method, contrasts, software
   versions, input hashes, convergence, warnings, row counts, and model-frame
   hash;
4. raw and adjusted test CSVs with family IDs, planned size, rank, and
   non-estimability;
5. practical-scale estimates, contrasts, trends, curves, and 95% intervals;
6. sample-flow CSVs at site, participant, participant-day, metric,
   questionnaire, sex, and time-bin levels as applicable;
7. durable diagnostic plots and machine-readable diagnostic summaries;
8. an H11 sequence manifest containing sort keys, expected step, gap breaks,
   day breaks, `rho`, and residual ACF summaries;
9. a result-difference CSV against the frozen baseline;
10. publication table/figure files; and
11. exact source-data CSVs for every figure and durable table.

Suggested deterministic paths are:

```text
artifacts/07_models/H0x/<placement>/<scenario>/
artifacts/08_diagnostics/H0x/<placement>/<scenario>/
artifacts/09_tables/H0x_<placement>_<scenario>.*
artifacts/10_figures/H0x_<placement>_<scenario>.*
artifacts/11_source_data/H0x_<display_id>_<placement>_<scenario>.csv
artifacts/12_manifests/H0x_<placement>_<scenario>_manifest.csv
```

The deterministic assembly notebook selects approved near-eye primary and
complementary outputs. Hypothesis notebooks never write a placement-ambiguous
path and never copy files manually into `assets/`.

# Major gates identified by this map

| Gate | Decision required before fitting or reporting |
|---|---|
| `H09-G1` | Restore both registered chronotype instruments, or approve and document omission/reclassification of MEQ. |
| `H09-G2` | Restore the registered longest-period midpoint or approve mean timing above 250 lx as the adapted H09 outcome. |
| `H09-G3` | Declare MCTQ/MEQ main and interaction multiplicity families before viewing repaired results. |
| `H10-G1` | Choose four separate 17-member age/sex main/interaction families or a justified combined main-effect family. |
| `H10-G2` | Confirm site-adjusted average associations as primary and site interactions as separate heterogeneity estimands, or approve a different joint estimand. |
| `H11-G1` | Restore hourly geometric MEDI or approve the supported 30-minute arithmetic H02/H11 adaptation. |
| `H11-G2` | Define whether the primary sex test is joint level-plus-pattern or shape-specific conditional on a sex main effect. |
| `H11-G3` | Approve the registered or adapted cyclic, site, participant, participant-day, and photoperiod structure. |
| `H11-G4` | Replace pointwise time-bin inference with a global test and simultaneous difference band. |
| `H11-G5` | Classify activity adjustment as a common-sample contextual sensitivity unless a separate causal estimand is approved. |
| Result gates | Reopen the relevant unit if corrected metric support, vector BH, model structure, autocorrelation, placement/common-sample analysis, or influence checks change a substantive result or claim. |

# Migration acceptance criteria

H09–H11 migration is complete only when:

- every major gate above has a documented disposition;
- each notebook runs in a clean R 4.6.1 session from explicit inputs;
- canonical-current-rule runs reproduce every unaffected current operation or
  explain the discrepancy;
- repaired metrics pass the metric-validity re-audit;
- MCTQ, MEQ, demographic, metric, and diary joins assert cardinality;
- sample flow reconciles across models, figures, tables, prose, and reporting
  forms;
- every p-value belongs to a declared vector-wide family;
- H09 includes both approved chronotype instruments and reports estimates from
  the stated site-adjusted model;
- H10 tests and reports both age and sex interactions or records
  non-estimability, while keeping sex and gender distinct;
- H10 near-eye and chest outputs have separate deterministic paths;
- H11 includes the registered parametric sex effect in the approved full
  model;
- H11 uses valid sequence starts, a common comparison frame, and an approved
  common autocorrelation strategy;
- H11 does not compare different fREML mean structures as decisive AIC
  evidence;
- H11 makes no prediction-term “variance explained” claim;
- time-localized H11 claims use simultaneous rather than pointwise intervals;
- activity attenuation is not described as causal mediation;
- every estimate has a practical-scale interval;
- all diagnostic failures and non-estimable results remain visible;
- near-eye and chest results are not pooled or described as independent
  additions to ocular sample size;
- sleep-period values are consistently identified as bedside-environment
  exposure;
- every display has exact source data and correct placement/metric identity;
  and
- no current H09–H11 number remains in the Nature Health manuscript without a
  verified canonical producer and claim-provenance entry.
