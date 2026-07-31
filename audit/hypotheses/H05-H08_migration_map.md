# H05–H08 canonical migration map

Status: read-only code, artifact, and claim map; implementation and clean
reruns pending  
Prepared: 2026-07-30  
Baseline branch commit: `20ba43c27e69fd952ce8023770538f2aa843ef5e`  
Primary placement: near-eye (`glasses`)  
Complementary placement: chest, preferably on paired/common samples  
Pooling decision: rejected

## Purpose and authority

This document maps the current H05–H08 implementations into canonical
hypothesis notebooks. It distinguishes:

1. the signed preregistration and its supporting analysis plan;
2. the exact behaviour of the current R/Quarto implementation;
3. confirmed defects and unresolved scientific choices;
4. the repaired specification that can be implemented without changing an
   estimand; and
5. explicit major gates where the agreed repair policy requires author
   approval.

This is not a result approval. Every numerical value below is a provisional
description of the frozen current render or saved baseline. No value or claim
may enter the Nature Health manuscript until the canonical clean rerun,
result-difference audit, metric re-audit, and applicable major gates are
complete.

The governing records are:

- `audit/evidence/preregistration_contract.md`;
- `audit/ledgers/hypothesis_contracts.csv`;
- `audit/ledgers/deviation_register.csv`;
- `audit/decisions/metric_validity.md`;
- `audit/decisions/metric_implementation_parameters.md`;
- `audit/decisions/placement_decision.md`;
- `audit/decisions/saturation_boundary.md`;
- `audit/findings/timestamp_dst_fallback.md`;
- `audit/findings/state_precedence_and_channel_mask.md`; and
- `audit/findings/heterogeneous_source_epochs.md`.

If this map conflicts with a later approved decision record, the later record
controls. This map must then be updated before a hypothesis notebook is
implemented.

### Static-verification note

Numerical inspection used R 4.6.1 and the project library. It loaded the
hashed baseline objects:

- `data/metrics_glasses.RData`, SHA-256
  `9595cb7c574672cf2c8ff89ac3d227f3f7ff11eca57776609e19599561b2d441`;
- `data/metrics_chest.RData`, SHA-256
  `4498d677a8fc7d47168ab2f03731f2dc67b419102b7c818305925273d57c818c`;
- `data/H1_results.RData`, SHA-256
  `d274865818cc4a0364dae9a444b9be44be02424daa8ad74b9452840f3115b3dc`;
  and
- `data/H1_results_chest.RData`, SHA-256
  `01f91db675d1aa6ae96b6aa7bbc45b2f86445e851a37020d1fe5335d802de9b5`.

R was used only to enumerate object schemas, metric rows, current upstream
selection flags, factor storage, preliminary metric support, and participant
key uniqueness. No H05–H08 correlation or model was recomputed or refit.

The current rendered `docs/RQ2.html`, `docs/RQ2_chest.html`,
`docs/RQ3.html`, and `docs/RQ3_chest.html` were converted to plain text with
the bundled Pandoc to recover displayed tables and render-time values. Those
documents report R 4.5.0 and are evidence of current output only. They are not
independent validation.

The current H05 and H08 source loads LEBA and VLSQ-8 data dynamically through
`melidosData::load_data()`. Those questionnaire inputs are not persisted in a
model-data artifact, and their current join counts cannot be reconstructed
from the saved tables. The canonical preparation stage must therefore pin
their source releases and export their schemas and sample flow before either
hypothesis is run.

## Shared migration rules

### Canonical artifacts and scenarios

Each hypothesis notebook consumes one explicit model-data object:

- `notebooks/hypotheses/H05.qmd` consumes
  `artifacts/06_model_data/H05.rds`;
- `notebooks/hypotheses/H06.qmd` consumes
  `artifacts/06_model_data/H06.rds`;
- `notebooks/hypotheses/H07.qmd` consumes
  `artifacts/06_model_data/H07.rds`; and
- `notebooks/hypotheses/H08.qmd` consumes
  `artifacts/06_model_data/H08.rds`.

Every object must carry:

- placement and scenario;
- producer and input hashes;
- source release and acquisition provenance;
- site, participant, participant-day, and time keys as applicable;
- variable and unit dictionaries;
- factor levels and contrast definitions;
- inclusion flags and exclusion or non-estimability reasons;
- ordinary and metric-specific support;
- questionnaire construction and missing-item rules where applicable; and
- sample flow at every unit used by a model or correlation.

The notebooks must not call `load()`, download data, install packages, mutate
shared global objects, or depend on a fitted H01–H04 result.

The same parameterized implementation is used for:

1. `placement = "glasses", scenario = "primary"`;
2. `placement = "glasses", scenario = "paired_common_sample"`;
3. `placement = "chest", scenario = "paired_common_sample"`; and
4. a separately labelled all-chest contextual scenario if retained.

No H05–H08 model pools placement records or treats chest measurements as
additional independent ocular observations. During diary-defined sleep, both
placements describe the bedside sleep environment rather than their nominal
worn positions.

### Common preprocessing inherited by H05–H08

The canonical model data inherit the approved common pipeline:

- one-minute aggregation is source-epoch aware and requires complete expected
  subepoch support in the primary analysis;
- true `datetime_utc` controls keys, ordering, elapsed duration, gaps, and
  adjacency;
- `datetime_wall` is the shared local-clock coordinate for clock-time
  interpretation;
- repeated fall-back wall-clock bins are averaged only for clock-aligned
  analyses, with fold provenance retained;
- the sleep diary interval from `sleepprep` through wake is authoritative;
- wear-log `sleep` is provenance only;
- only wear-log `off` outside the diary sleep window is invalid non-wear;
- invalid non-wear masks analytical MEDI and LIGHT together while raw channels
  remain immutable;
- one-minute MEDI is valid only below \(10^5\) lx;
- the registered 50%-per-hour and 80%-per-day eligibility rules are applied
  before metric-specific support;
- a failed metric becomes reason-coded `NA` without discarding an otherwise
  eligible participant-day; and
- full-day metrics are explicitly hybrid: near-eye during wake/pre-sleep and
  bedside environmental measurement during diary sleep.

No L5 value is produced. The retained darkest-window level metric is L10.

### Common inferential and reporting rules

- Every comparison uses identical model-frame rows and fails on a key
  mismatch.
- Questionnaire and diary joins are checked as many-measurements-to-one
  covariate joins; duplicates or overlapping intervals fail rather than
  multiply records.
- IDs are asserted unique across sites or are represented explicitly as
  `site:participant`.
- Metric transformations, families, links, and units are registered once and
  reused across hypotheses unless a named sensitivity is run.
- Gaussian mixed models with different fixed effects are compared under ML;
  REML may be used only for the final estimation fit after structure is fixed.
- GAM/GAMM structure comparisons use a valid common likelihood and identical
  rows. fREML AIC is not used to compare different mean structures.
- A main association, a predictor-by-site interaction, and site-specific
  contrasts are separate estimands and separate multiplicity families.
- Every BH family is assembled as a vector before adjustment. Planned but
  non-estimable members remain represented with `NA` and the declared family
  size.
- Estimates and 95% intervals are reported in practical units. Significance
  colouring or p-values do not replace them.
- A squared Spearman coefficient is not called variance explained.
- Differences between marginal \(R^2\) values from overlapping models are not
  called unique or additive contributions.
- Models report actual participants, participant-days, observations, sites,
  placement, predictor support, and metric-specific missingness.
- Diagnostics, model summaries, source data, warnings, and comparison results
  are durable artifacts rather than transient render output.
- All current claims listed below reopen if their sample, estimate, interval,
  adjusted inference, or interpretation changes.

### Metric sets currently implicated

The current H05 code selects the 17 rows in the current metric registry with a
non-missing response specification:

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
15. duration below 10 lx during pre-sleep;
16. duration below 1 lx during sleep; and
17. duration above 250 lx during wake.

H07 and H08 concern the following nine registered level-, duration-, and
exposure-history outcomes:

1. daily geometric mean MEDI;
2. M10 mean;
3. L10 mean;
4. duration above 1,000 lx;
5. duration above 250 lx during wake;
6. duration below 10 lx during pre-sleep;
7. duration below 1 lx during sleep;
8. longest period above 250 lx; and
9. dose.

These are planned sets, not a guarantee that every rebuilt participant-day
has an admissible value. The metric-validity ledger controls the final
definition and reason-coded missingness.

## Source-to-canonical map

| Unit | Current near-eye implementation | Current chest implementation | Canonical destination |
|---|---|---|---|
| H05 | `RQ2.qmd:1578-1721`; `scripts/fitting.R`; H01 result workspace used as a metric registry | `RQ2_chest.qmd:1579-1722`, near-literal copy with chest H01 results | `notebooks/hypotheses/H05.qmd` |
| H06 | `RQ2.qmd:1722-2758`, including the primary GLMM, weekday/weekend check, temporal GAM, and activity-context check | `RQ2_chest.qmd:1723-2759`, near-literal copy | `notebooks/hypotheses/H06.qmd` |
| H07 | `RQ2.qmd:2759-2905`; derivative helper in `scripts/RQ2_specific.R:31-68` | `RQ2_chest.qmd:2760-2888`; reduced hard-coded display and no interpretation section | `notebooks/hypotheses/H07.qmd` |
| H08 | `RQ3.qmd:85-282`; model dispatch and scalar adjustment in `scripts/fitting.R` | `RQ3_chest.qmd:80-278`, near-literal copy with chest inputs | `notebooks/hypotheses/H08.qmd` |

Duplicate near-eye/chest sources remain until equivalence with the canonical
parameterized implementation is demonstrated. Their frozen hashes remain
part of the audit record after retirement.

## Reviewer-feedback and claim-disposition map

The Nature Medicine feedback is advisory rather than a replacement for the
registered contract, but several adopted points directly constrain this
migration:

| Feedback | H05–H08 consequence |
|---|---|
| `NM-R1-01`, results hierarchy | H05–H08 remain fully traceable, but null, adapted, and unstable results need not receive equal main-text prominence. |
| `NM-R1-02`, metric accessibility | Every H05/H07/H08 metric must carry a name, construct, input, unit, support rule, and plain-language interpretation. |
| `NM-R1-03`, evidence levels | Observational exposure associations are not physiological effects or health outcomes; H06/H08 wording must preserve that distinction. |
| `NM-R1-04`, novelty | Expected or weak behaviour/questionnaire associations are not presented as the main novelty; methodological exposure characterization remains separable from replication. |
| `NM-R1-05` and `NM-R2-01`, placement/sample flow | Every unit reports placement-specific participants, days, observations, missingness, paired samples, and sparse-site influence. |
| `NM-R1-07` and `NM-R1-08`, broader exposome factors | Unmeasured social, occupational, built-environment, and climatic pathways are discussed as limitations; unsupported predictors are not added. |
| `NM-R2-02`, season and site heterogeneity | H07 must expose collection period, site/photoperiod confounding, and leave-one-site-out influence; temperature is not introduced. |
| `NM-R2-03`, power and multiplicity | Sparse interactions, complete BH families, intervals, diagnostics, and non-estimability are reported rather than hidden. |
| `NM-R2-04`, no health outcome | None of H05–H08 is framed as clinical, causal, or health-outcome evidence. |

Current manuscript claim locations that must be replaced by verified
producers are:

| Unit | Current claim locations |
|---|---|
| H05 | `index.qmd:341-343`, `index.qmd:391`, and `index.qmd:665` |
| H06 | `index.qmd:345-353`, `index.qmd:423`, `index.qmd:667`, and `index.qmd:689` |
| H07 | `index.qmd:355-357`, `index.qmd:425`, and `index.qmd:669` |
| H08 | `index.qmd:361-363`, `index.qmd:393`, `index.qmd:429`, and `index.qmd:691` |
| Cross-placement | `index.qmd:379-381`, especially the claim that all 11 hypotheses were remarkably stable |

# H05: LEBA factors and personal light-exposure metrics

## Preregistered contract and current estimand

H05 asks whether four LEBA factors are associated with selected
personal-light-exposure metrics. The signed contract records both a
correlation matrix and a site-adjusted model:

```text
Metric ~ LEBA + (1 | Site)
```

The supporting analysis plan lists the correlation matrix and then ambiguously
states `Correlation ~ (1|Site)`. Neither source enumerates the metric set in
the model section, although the current implementation uses 17 metrics and
the analysis plan names the four factors.

The current inferential estimand is an unadjusted, participant-level bivariate
correlation after averaging repeated daily metrics within participant. It does
not fit the registered site-adjusted metric model.

## Exact current inputs, filters, and participant summaries

### Inputs

- Near-eye metric source: `data/H1_results.RData`.
- Chest metric source: `data/H1_results_chest.RData`.
- Questionnaire source:
  `melidosData::load_data("leba") |> flatten_data()`.
- Current join key: `site`, `Id`.

Loading an H01 result workspace makes H05 depend on upstream fitted results
even though it needs metric values only. The current code then keeps metric
rows whose H01 model registry has a non-missing `response`. It does not select
on H01 significance, but the dependency is still unnecessary and obscures
provenance.

The four questionnaire columns and analysis-plan labels are:

| Current column | Factor |
|---|---|
| `leba_f2` | Spending time outdoors |
| `leba_f3` | Using phones and smart devices in bed before sleep |
| `leba_f4` | Controlling and using ambient light before bedtime |
| `leba_f5` | Using light in the morning and during daytime |

For every metric, the current code:

1. groups by `site`, `Id`;
2. computes `mean(metric, na.rm = TRUE)` across participant-days;
3. left-joins the four LEBA scores;
4. pivots factors to long form; and
5. drops missing metric/factor pairs separately within each of the 68
   metric-by-factor cells.

The current numeric metric columns have no stored unit attributes. Timing
metrics are averaged linearly rather than circularly. No minimum number of
participant-days is required for a participant summary, and the number of
days contributing to each summary is not retained.

The saved near-eye registry has 141 participants and 811 participant-days
before the LEBA join. The chest registry has 154 participants and 897
participant-days. Actual H05 pairwise participant counts are not stored in
the current figure or a table and remain provisional/unreconciled.

## Exact current analyses, reference handling, and multiplicity

### Site screen

The current preliminary screen fits four separate ordinary linear models:

```text
LEBA factor ~ site
```

It obtains site marginal means and effect contrasts. Each omnibus p-value is
passed alone to:

```r
p.adjust(p.value, method = "fdr", n = 4)
```

The current render retains F2 and F5 after this screen and reports one site
effect contrast for each. It then concludes that LEBA factors can be analysed
without site. This screen is not the registered outcome model and does not
establish absence of site confounding.

### Correlation matrix

For each of the 68 cells, the current code computes:

```r
correlation = cor(metric, value, method = "spearman")
p_value = cor.test(metric, value)$p.value |>
  p.adjust(method = "fdr", n = 68)
```

Therefore:

- the displayed coefficient is Spearman's rho;
- `cor.test()` defaults to a Pearson correlation test;
- the Pearson p-value is adjusted separately as a scalar; and
- scalar BH with `n = 68` is equivalent here to multiplying that one p-value
  by 68 and truncating at one, not vector-wide Benjamini–Hochberg.

There is no factor reference level in a bivariate correlation. The direction
of each LEBA score is inherited from the loaded questionnaire without an
audited scale-construction table.

No `Metric ~ LEBA + (1|Site)` model is fitted.

## Current outputs and claims

Current durable presentation files are:

- `figures/Fig6.pdf` and `figures/Fig6.png`;
- `figures/chest/Fig6.pdf` and `figures/chest/Fig6.png`; and
- manually copied `assets/Fig6.png`.

No H05 model object, participant-summary table, exact pair-count table,
correlation CSV, scale audit, or figure source-data CSV is persisted.

The current main manuscript says that only two of 68 comparisons were
significant and reports provisional positive associations of LEBA F2 with
dose (`rho = 0.27`, displayed `p = 0.013`) and duration above 1,000 lx
(`rho = 0.29`, displayed `p = 0.032`). The RQ2 interpretation mistakenly calls
the second outcome duration above 250 lx. It also squares rho and describes
the result as explained variance. The Discussion infers that broad habitual
behaviour is less informative than immediate context.

All of these claims are reopened. In particular, the displayed p-values are
not Spearman test p-values and are not vector-wide BH values.

## Confirmed defects and risks

1. **Coefficient/test mismatch (`IMP-006`).** Spearman coefficients are paired
   with Pearson p-values.
2. **Scalar multiplicity error (`IMP-001`).** Sixty-eight p-values are never
   assembled into one BH vector.
3. **Registered site model absent.** No site-adjusted metric model is fitted.
4. **Invalid site-screen logic.** Failure to reject some site differences in
   the predictor does not establish that site can be omitted from an
   exposure association.
5. **Upstream result dependency.** H05 loads fitted H01 results merely to
   recover metric data and model-registry fields.
6. **Linear averaging of clock times.** Participant summaries can be wrong
   near midnight.
7. **Unreported participant support.** One valid day and seven valid days are
   treated alike, and pairwise sample sizes are absent.
8. **Metric-specific missingness hidden.** Pairwise deletion varies across 68
   cells without a sample-flow table.
9. **No questionnaire scale audit.** Score construction, item direction,
   missing-item handling, possible range, observed range, and site support are
   not persisted.
10. **No uncertainty interval.** The figure reports rho and p only.
11. **Squared-rank-correlation overinterpretation.** `rho^2` is not an
    ordinary proportion of outcome variance explained.
12. **Outcome-name inconsistency.** RQ2 text says above 250 lx where the
    figure and manuscript say above 1,000 lx.
13. **No influence or clustering assessment.** Site and participant leverage
    can dominate a modest pooled correlation.
14. **No authoritative source-data artifact.** The manually copied figure is
    the manuscript input.

## Proposed repaired specification

### Fixed factor and metric contracts

Retain all four documented LEBA factors and all 17 planned metric members.
The canonical data dictionary records:

- questionnaire items used in every factor;
- any reverse coding;
- score direction, range, and units;
- missing-item rule;
- one-row-per-site-participant uniqueness;
- observed range and contributing participants by site; and
- the metric definition, unit, temporal domain, and admissibility reason.

No metric is selected using H01 significance or availability of a favourable
correlation. A planned but non-estimable metric remains in the 68-member
manifest with a reason.

Participant-level summaries must be metric appropriate:

- participant-level IS and IV are used directly;
- circular timing metrics use a duration-weighted circular participant
  summary and retain resultant/support;
- other daily metrics use a predeclared participant summary and report days
  and coverage contributing to it; and
- sleep metrics retain their bedside-environment interpretation.

Changing the current arithmetic participant summary for a non-circular metric
requires a before/after comparison but is a low-risk implementation repair if
the estimand remains the participant's typical exposure. A change between
mean and median as the scientific estimand is a major gate.

### Correlation analysis

The repaired correlation matrix uses one method for both coefficient and
test. The continuity specification is a two-sided Spearman rank correlation
with pairwise complete participant summaries:

```text
rho(metric_summary, LEBA_factor)
```

Each cell reports rho, a 95% interval, raw p-value, adjusted p-value, exact
participant count, site count, and days contributing to participant
summaries. Ties and interval method are recorded. Site-stratified and
leave-one-site-out estimates are diagnostics/sensitivities rather than new
confirmatory families.

### Site-adjusted registered analysis and H05 major gate

The signed contract also requires a site-adjusted model. The current code does
not define whether that model or the correlation matrix is primary, and the
supporting analysis plan is ambiguous. Before fitted H05 results are
generated, `H05-G1` must choose and log one of these estimands:

1. **Registered site-adjusted primary:** a metric-appropriate
   `Metric ~ LEBA + (1|Site)` model (adding a participant intercept when daily
   rows are used), with the participant-level Spearman matrix descriptive; or
2. **Participant-correlation primary:** the 68 Spearman correlations remain
   the inferential estimand for continuity, while site adjustment is a named
   sensitivity/deviation.

The recommended contract-preserving option is the first. For daily metrics:

```text
g(metric_day) ~ z_LEBA +
  (1 | site) + (1 | site:participant)
```

For participant-level IS/IV:

```text
g(metric_participant) ~ z_LEBA + (1 | site)
```

The transformation/family `g` comes from the common metric model registry.
With only nine sites, the site random-effect estimate and a fixed-site
sensitivity must both be reported. LEBA slopes are expressed per raw scale
unit and per one participant-level SD. No causal language is permitted.

### Multiplicity

The family structure depends on `H05-G1`:

- `H05-F1-primary`: all 68 planned primary LEBA-by-metric association tests,
  adjusted together by BH;
- `H05-F2-secondary`: all 68 tests from the non-primary analysis only if
  inferential p-values are reported; otherwise report estimates and intervals
  without a second significance screen; and
- questionnaire site-distribution checks are diagnostics, not a mechanism
  for selecting covariates or H05 outcomes.

Raw p-values, family size, rank, adjusted p-values, and non-estimability
reasons are retained.

### Required diagnostics

- questionnaire row/key uniqueness and scale construction;
- factor distributions, ties, ceiling/floor behaviour, and site support;
- metric-specific participants, days, and missingness for all 68 cells;
- circular-summary resultant and boundary handling for timing metrics;
- bivariate scatter/rank diagnostics and influential participants;
- site-stratified and leave-one-site-out rho;
- residual and family checks for any site-adjusted model;
- site random-effect stability with only nine clusters;
- participant random-effect singularity where daily rows are used; and
- common-sample near-eye/chest estimate differences.

## Required H05 result-difference checks

Compare current and repaired:

- the four factor scores, ranges, missingness, and site support;
- the 17 planned metrics and every metric-specific participant count;
- current arithmetic versus repaired circular participant timing summaries;
- current Spearman coefficient versus repaired Spearman coefficient;
- current Pearson/scalar-adjusted p versus raw Spearman and vector-BH p;
- current pooled versus site-adjusted estimates;
- near-eye all-sample versus paired/common-sample near-eye and chest
  estimates;
- influential-site classifications; and
- the two named manuscript associations and every statement that other
  associations were absent.

Every displayed H05 cell must map to one result row and one exact pair-count
row. If either currently named association changes significance or material
magnitude, the manuscript claim gate opens.

## H05 dependencies and reopening

H05 depends on the repaired metric table, LEBA scale artifact, metric-validity
re-audit, and placement/common-sample manifest. It does not depend on any H01
model or significance result. A change to a metric definition, participant
summary, LEBA factor score, multiplicity family, or `H05-G1` reopens H05.

# H06: Day type, exercise, prior sleep, and hourly exposure

## Preregistered contract and current estimand

H06 registered day type, daily exercise, and sleep variables as predictors of
daily light-exposure metrics:

```text
Metric ~ Measure + (Measure | Site) +
  (1 | Site:Participant)
```

The supporting analysis plan lists both weekday/weekend and free/work day;
sleep onset, wake time, and duration; and several exercise fields. The current
documented deviation (`DEV-015`) changes the outcome to hourly geometric mean
MEDI and fits work/free day, exercise intensity, and previous-night sleep
duration jointly. This changes the outcome, unit, weighting of days, temporal
dependence, and hypothesis wording.

The current estimand is the association of three day-level predictors with
the conditional mean of repeated hourly hybrid exposure, including all site
interactions. It is not a daily metric analysis.

## Exact current input, aggregation, joins, and filters

### Light outcome

The current H06 code reuses `hourly_data2`, an object constructed earlier in
H03 from `data/preprocessed_glasses_2.RData` or its chest counterpart. Before
H06:

1. one-minute rows are floor-aggregated to one-hour bins;
2. `geo.MEDI` is the zero-aware geometric mean;
3. no explicit 30-valid-minute support requirement is applied;
4. a participant-day is removed if all its hourly arithmetic MEDI values
   equal the first value;
5. hourly light-source diary states are joined; and
6. sparse light-source labels are changed to missing, although H06 does not
   use that label.

Thus H06 inherits an unnecessary H03 dependency and the current static-day
deletion.

### Day-level predictors

Current questionnaire/diary imports are:

```r
sleep <- load_data("sleepdiaries") |> flatten_data()
exercise <- load_data("exercisediary") |> flatten_data()
```

The current definitions are:

- `Date = date(wake)`, attaching the preceding sleep interval to its wake
  date;
- `daytype = daytype2`, with `"a work day"` as the reference and
  `"a free day"` as the comparison;
- `sleep_duration = as.numeric(sleep_duration)`, interpreted in the render as
  hours;
- exercise intensity reduced to the first word and treated as the nominal
  levels `None`, `Light`, `Moderate`, and `Vigorous`;
- sleep and exercise combined by full join on `site`, `Id`, `Date`; and
- these day-level values left-joined onto every eligible hourly row.

No join-cardinality assertion is persisted. The full model uses complete
cases jointly for `geo.MEDI`, day type, exercise, and sleep duration.

Calendar weekday is added from hourly datetime with Monday as the first day
of the week; Saturday/Sunday are coded as weekend. Weekend is used only in a
post-hoc AIC comparison.

The current near-eye table reports 16,406 participant-hours and the chest
table 18,124 participant-hours. Participants, participant-days, hours by day,
predictor-specific missingness, and site-by-level support are not included in
the table and must be regenerated.

## Exact current formulas, fitting, and references

All five current primary models are Tweedie-log `glmmTMB` models with
`REML = FALSE`:

```text
H6_full:
geo.MEDI ~ site * daytype +
  site * exercise +
  site * sleep_duration +
  (1 | Id)

H6_no_daytype:
geo.MEDI ~ site * exercise +
  site * sleep_duration +
  (1 | Id)

H6_no_exercise:
geo.MEDI ~ site * daytype +
  site * sleep_duration +
  (1 | Id)

H6_no_sleep:
geo.MEDI ~ site * daytype +
  site * exercise +
  (1 | Id)

H6_no_site:
geo.MEDI ~ daytype + exercise + sleep_duration +
  (1 | Id)
```

Site is explicitly sum-coded. Day type and exercise use treatment coding with
work day and no exercise as references. Sleep duration is continuous and not
centered in the fitted formula. The displayed reference is an equal-site
estimated mean at the observed mean sleep duration, reported as 7.9 h.

Because the three primary likelihood-ratio comparisons drop a predictor main
effect and all of its site interactions together, they are joint
association-plus-heterogeneity tests, not main-effect tests.

The current random structure has a participant intercept only. It omits
participant-day clustering and residual within-day correlation. Day-level
predictors are repeated across hours, so a participant-day contributes in
proportion to the number and clock distribution of retained hours.

### Current multiplicity and contrasts

The three likelihood-ratio p-values are not adjusted. Yet the table footnote
claims FDR adjustment for three overall effects.

Current marginal contrasts use:

- `trt.vs.ctrl` for free versus work day;
- `trt.vs.ctrl` for three exercise levels versus none;
- a response-scale trend for sleep duration;
- effect contrasts among sites within each day type or exercise category; and
- site effect contrasts of sleep-duration slopes.

The `trt.vs.ctrl` results use the emmeans shared-control default rather than
the stated BH procedure. Site contrast adjustment is split across hidden
`by` groups. Intervals are removed before the final table.

The site p-value in the H06 table is not produced by H06. No H06
`comp_site` object is created; the global object last assigned in H04 is
silently reused (`IMP-007`).

### Current \(R^2\) decomposition

The current table subtracts marginal \(R^2\) values from overlapping full and
reduced models and labels the differences as unique contributions of day
type, exercise, sleep, and site. These values are not additive variance
components. The helper also constructs a null model from the broader input
data rather than asserting the exact fitted model frame.

## Current secondary and exploratory analyses

### Weekday/weekend

The current alternative replaces work/free day with weekday/weekend in the
same Tweedie model and compares AIC. The render reports the weekend model at
approximately 33 AIC points worse. It is labelled a quick test rather than a
registered day-type analysis.

### Temporal GAM

The temporal model uses the hourly arithmetic MEDI, not the main hourly
geometric outcome. It zero-aware-log transforms that value and fits:

```text
lzMEDI ~
  s(Time, k = 12) +
  s(Time, daytype, bs = "sz", k = 12) +
  s(Time, exercise, bs = "sz", k = 12) +
  s(Time, site, bs = "sz", k = 12) +
  s(Time, photoperiod.state, bs = "sz", k = 12) +
  s(Time, Id, bs = "fs") +
  s(Id_date, bs = "re")
```

It estimates an AR parameter, but `AR.start` is true only once per
participant rather than at every participant-day or gap boundary. Smooths are
not cyclic at midnight. It calculates the variance of prediction terms and
draws pointwise red significance segments. These are not valid unique
variance contributions or simultaneous curve inference.

### Activity-context adjustment

The final exploratory block adds the H04 activity category and repeats the
three joint predictor-block comparisons. It overwrites several H06 object
names, persists no result table, and underlies the manuscript claim that all
three associations remain after controlling for activity. This observational
adjustment does not establish mechanisms or effects beyond activity.

## Current outputs and claims

Current files are:

- `tables/H6.png` and `tables/H6.docx`;
- `tables/chest/H6.png` and `tables/chest/H6.docx`;
- `figures/Fig_H6.*`, `figures/Fig11.*`, and `figures/Fig12.*`;
- corresponding `figures/chest/` files; and
- manually copied `assets/H6.png` and `assets/Fig12.png`.

No authoritative model-frame, model object, diagnostics table, test vector,
or source-data CSV is persisted.

The current manuscript reports provisional associations for:

- work/free day, including five named site deviations;
- four exercise levels and several site deviations;
- an 8% lower hourly exposure per additional hour of prior sleep;
- marginal-\(R^2\) differences of 0.01, 0.05, and 0.02;
- time-of-day differences between work and free days;
- weaker weekday/weekend support; and
- persistence after activity-context adjustment.

It repeatedly calls the outcome average or daily exposure even though the
fitted response is an hourly geometric mean. Every number and the claim that
the associations are small but robust are reopened.

## Confirmed defects and risks

1. **Major estimand deviation (`DEV-015`).** Daily metrics became repeated
   hourly MEDI without an approved final reconciliation.
2. **Registered predictor scope narrowed.** Work/free day, exercise
   intensity, and sleep duration are used; other named day-type, exercise, and
   sleep variables are absent or relegated to an informal check.
3. **Unnecessary H03 dependency.** H06 inherits a light-source join and
   static-day deletion.
4. **No hourly support rule.** An hour can be based on fewer than 30 valid
   minutes.
5. **No join-cardinality contract.** Duplicate daily records could multiply
   hourly rows.
6. **Joint tests labelled main effects.** Each likelihood-ratio test removes
   the predictor and all site interactions together.
7. **Multiplicity description is false.** The three omnibus p-values are raw,
   exercise contrasts use a shared-control adjustment, and site families are
   partitioned implicitly.
8. **Stale site p-value (`IMP-007`).** H04's `comp_site` is displayed in H06.
9. **Incomplete repeated structure.** Participant-day clustering and hourly
   autocorrelation are absent.
10. **Unequal day weighting.** A day with more supported hours contributes
    more rows to a day-level predictor association.
11. **Overlapping \(R^2\) differences.** They are called unique contributions.
12. **Intervals discarded.** The main table relies on bold point estimates.
13. **Temporal outcome mismatch.** The GAM uses arithmetic rather than
    geometric hourly MEDI.
14. **Temporal discontinuities mishandled.** Smooths are non-cyclic and AR
    sequences cross participant-day/gap boundaries.
15. **Prediction-term variance misinterpreted.** Correlated smooth terms are
    not an additive variance decomposition.
16. **Pointwise curve claims.** Red time segments do not provide simultaneous
    whole-curve inference.
17. **Activity-adjusted claim lacks a durable producer.** Models overwrite
    names and no exact result is staged.
18. **Hybrid construct underlabelled.** Sleep hours are bedside-environment
    measurements, not worn ocular exposure.

## Repaired specification that does not pre-empt the H06 estimand gate

### Construct and join audit

Before modelling, H06 must export:

- a one-row-per-participant-day predictor table;
- exact definitions and source fields for free/work, weekday/weekend,
  exercise, sleep onset, wake, and sleep duration;
- current and available category levels by site;
- missingness and duplicates by predictor;
- the previous-night/date linkage audit;
- participants and participant-days contributing to every level/site cell;
  and
- the exact hourly or daily metric support after joining.

Day type and exercise are observational context variables. Sleep duration is
the preceding diary-defined sleep interval. None is described as causing
exposure.

### H06 major estimand gate

`H06-G1` is mandatory before H06 fitting because the two defensible paths
target different estimands:

1. **Restore the registered daily-metric analysis.** Fit the declared daily
   metrics against the approved day-type, exercise, and sleep measures, with
   participant and site structure and a prespecified multiplicity registry.
2. **Retain the documented hourly adaptation.** Treat H06 as an adapted
   hypothesis about hourly geometric MEDI, explicitly model within-day time
   and dependence, and document that it is not the registered daily-metric
   estimand.

The second path best preserves the recognizable current result, but it cannot
be silently approved by code migration. The first path is closer to the
signed contract but substantially expands the outcome family. The gate must
also fix whether both registered day-type definitions are primary or
work/free is primary with weekday/weekend as a declared sensitivity.

### If the hourly adaptation is approved

Use the canonical one-hour zero-aware geometric mean MEDI with at least 30
valid minutes. Preserve true-time support, wall-clock hour, hybrid state,
participant-day, and gap boundaries. Fit on one common complete-case frame:

```text
M_base:
geo_medi_1h ~ site + clock_time +
  (1 | site:participant) +
  (1 | participant_day)

M_additive:
geo_medi_1h ~ site + clock_time +
  daytype + exercise + sleep_duration +
  (1 | site:participant) +
  (1 | participant_day)

M_full:
geo_medi_1h ~ site + clock_time +
  daytype + exercise + sleep_duration +
  site:(daytype + exercise + sleep_duration) +
  (1 | site:participant) +
  (1 | participant_day)
```

`clock_time` must be cyclic or represented by an equivalent fixed hourly
effect. Residual dependence is checked within participant-day on a regular
hour index; unsupported hours break sequences. A correlation-capable
Tweedie-log model is the continuity candidate. A zero-aware Gaussian
log-scale common-sample model is the named distributional sensitivity.

Primary main-association tests are performed in the additive model. The
interaction model separately tests site heterogeneity. Predictor-specific
tests must preserve hierarchy and identical rows. Set work day and no exercise
as explicit references, centre sleep duration at a declared meaningful value
or the participant-level sample mean, and use equal-site marginalization for
cross-site estimates.

Report response-scale predicted MEDI and ratios with intervals. An
unadjusted total association and an activity-context-adjusted association may
both be shown, but the latter is explanatory/sensitivity evidence and not a
causal mediation result.

### If the daily-metric contract is restored

Use each admissible daily metric as its own response with one observation per
participant-day:

```text
M0:
g(metric_day) ~ site +
  (1 | site:participant)

M_measure:
g(metric_day) ~ site + measure +
  (1 | site:participant)

M_full:
g(metric_day) ~ site * measure +
  (1 | site:participant)
```

Models must address repeated-day temporal dependence where present. The
metric and measure registry, transformations, family partition, and
multiplicity must be fixed before results are inspected.

### Multiplicity

For the hourly adaptation:

- `H06-F1-main`: the three approved predictor main-association omnibus tests,
  one BH vector;
- `H06-F2-heterogeneity`: the three predictor-by-site omnibus tests, one BH
  vector;
- `H06-F3-practical-contrasts`: all prespecified work/free, exercise, and
  sleep-slope contrasts, one declared vector; and
- `H06-F4-site-contrasts`: every requested estimable site deviation across
  all three predictors, one declared vector.

If weekday/weekend is co-primary, the relevant family sizes increase before
adjustment. If the daily-metric path is selected, the registry must declare
the complete measure-by-metric family rather than adjusting within each
model.

### Required diagnostics

- predictor key uniqueness, joins, and date linkage;
- hours, days, participants, and sites by predictor level;
- supported-hour distribution per participant-day;
- model-frame equality for every comparison;
- category sparsity, design rank, and interaction estimability;
- convergence, Hessian, gradients, singularity, zero mass, dispersion,
  tails, and simulated residuals;
- participant-day and within-day residual dependence;
- collinearity among day type, exercise, sleep, site, and clock time;
- participant and site influence;
- equal-site versus observed-sample marginalization;
- cyclic boundary, basis dimension, concurvity, and simultaneous intervals
  for any temporal smooth;
- total versus activity-context-adjusted association; and
- common-sample near-eye/chest estimates, especially for sleep hours where
  nominal wearing position is not the construct.

## Required H06 result-difference checks

Compare current and repaired:

- outcome and unit of analysis selected at `H06-G1`;
- participants, days, hours, sites, predictor missingness, and category
  support;
- current unsupported hourly outcome versus the 30-minute-supported outcome;
- current joint predictor-plus-interaction tests versus separated main and
  heterogeneity tests;
- raw versus vector-BH p-values;
- every global and site-specific response-scale estimate and interval;
- stale H04 site p-value versus the H06-specific site result;
- current overlapping marginal-\(R^2\) differences versus valid full-model
  fit summaries;
- participant-day and autocorrelation repairs;
- work/free versus weekday/weekend evidence;
- current activity-context claim versus its durable repaired producer; and
- all-sample near-eye versus paired/common-sample near-eye and chest results.

Every manuscript number in the current H06 section receives a
claim-provenance row. Any change in the selected estimand or any qualitative
change to a named association is a major result gate.

## H06 dependencies and reopening

H06 depends on the canonical hourly or daily metric producer, pinned daily
diaries, validated join keys, metric support, and the placement manifest. It
does not depend on H03/H04 fitted objects. A changed H06 estimand, predictor
definition, temporal specification, common model frame, or metric repair
reopens H06.

# H07: Latitude, photoperiod, and possible exposure plateaus

## Preregistered contract and current estimand

H07 registered a nonlinear absolute-latitude-by-photoperiod association for
all nine level-, duration-, and exposure-history outcomes:

```text
Metric ~ te(abs_latitude, photoperiod) +
  s(Site, bs = "re") +
  s(Participant, bs = "re")
```

The current documented deviation (`DEV-016`) removes latitude, uses only
photoperiod, and selects outcomes that were significant for photoperiod in
H01. It then retains only H07 models with an AIC improvement greater than two.

The current procedure estimates a flexible photoperiod association. It does
not define or test a ceiling/plateau estimand.

## Exact current input, selection, formulas, and fitting

H07 reuses the global `metrics` object loaded from the H01 result workspace.
It selects:

```r
H1_phot_sig &
metric_type %in% c("level", "duration", "exposure history")
```

Because H01's current photoperiod p-values use the scalar-adjustment defect,
H07 outcome selection inherits both upstream result dependence and broken
multiplicity.

The frozen near-eye selection contains eight candidates:

- daily mean;
- M10 mean;
- L10 mean;
- duration above 1,000 lx;
- longest period above 250 lx;
- dose;
- duration below 10 lx during pre-sleep; and
- duration above 250 lx during wake.

The frozen chest selection contains six candidates:

- daily mean;
- M10 mean;
- duration above 1,000 lx;
- longest period above 250 lx;
- dose; and
- duration above 250 lx during wake.

For every selected metric, the current code fits:

```text
H7_full:
log_zero_inflated(metric) ~
  s(photoperiod) +
  s(site, bs = "re") +
  s(Id, bs = "re")

H7_null:
log_zero_inflated(metric) ~
  s(site, bs = "re") +
  s(Id, bs = "re")
```

Both are `bam(..., discrete = TRUE, method = "fREML")`. It compares their AIC
and calls the photoperiod model significant when:

```text
AIC(full) - AIC(null) < -2
```

All metric types receive the same zero-aware log-Gaussian response
specification. Date-level residual dependence is not represented.

The current near-eye render retains six models after this second screen:
daily mean, M10, L10, duration above 1,000 lx, longest period above 250 lx,
and dose. The chest render retains four: daily mean, M10, longest period above
250 lx, and dose. These are provisional render-time classifications.

## Exact current plateau rule and display

`gam_deriv_plot()`:

1. obtains pointwise derivatives of `s(photoperiod)`;
2. finds the last grid point whose derivative lower confidence limit exceeds
   zero;
3. labels that point “Significant rise ends”; and
4. treats later failure to reject a positive derivative as a ceiling.

It does not:

- define an outcome-specific practically negligible slope;
- test equivalence to a flat slope;
- require a sustained flat region;
- require an asymptote or monotone approach;
- use simultaneous derivative intervals;
- distinguish an edge-support loss from flattening; or
- show that a decrease, reversal, or imprecise increase is a plateau.

The near-eye `Fig14` assembly plots daily mean twice and omits M10. The chest
assembly likewise plots daily mean twice and omits M10. The main caption
nevertheless describes six distinct metric pairs.

## Current outputs and claims

Current files are:

- `figures/Fig14.pdf` and `figures/Fig14.png`;
- `figures/chest/Fig14.pdf` and `figures/chest/Fig14.png`; and
- manually copied `assets/Fig14.png`.

No H07 model, support-surface table, derivative CSV, model-comparison table,
diagnostic artifact, or exact figure source data is persisted.

The current near-eye text and manuscript claim provisional ceilings for level
metrics at approximately 14.7–16.4 h photoperiod and for duration above
1,000 lx at approximately 16.6 h. It claims no ceiling for longest period
above 250 lx or dose. The broad chest-consistency paragraph implies stability
across all hypotheses despite a different chest candidate/result set.

All ceiling, plateau, threshold-hour, and cross-placement-stability claims are
reopened.

## Confirmed defects and risks

1. **Outcome double selection (`DEV-016`).** H07 is conditional on H01
   significance and then on H07 AIC.
2. **Inherited scalar multiplicity.** The H01 screen used invalid scalar
   adjustment.
3. **Registered latitude omitted.** The current model is photoperiod-only.
4. **No ceiling estimand (`IMP-008`).** Derivative non-significance is not
   evidence of equivalence to zero or an asymptote.
5. **fREML AIC comparison.** Mean structures that differ by a smooth are
   compared using fREML rather than an appropriate common likelihood.
6. **Sparse joint support unresolved.** Latitude is constant within site and
   the sampled latitude-by-photoperiod surface is sparse.
7. **No outcome-specific practical margin.** A biologically or practically
   material remaining slope is not defined.
8. **Pointwise derivative inference.** Multiple grid points and edge
   uncertainty are ignored.
9. **One response transform for all metrics.** Zero mass, units, and
   distributional differences are not re-diagnosed.
10. **Repeated participant-days.** Within-participant date dependence is not
    checked.
11. **Display duplication/omission (`IMP-008`).** Mean is duplicated and M10
    omitted in both placement displays.
12. **Hard-coded positional indexing.** Figure identity depends on filtered
    row order rather than metric IDs.
13. **No multiplicity registry.** Neither the nine planned outcomes nor
    derivative/plateau decisions form an explicit family.
14. **No durable evidence chain.** The manuscript consumes a manual figure
    copy.

## Proposed repaired specification

### Outcome and support contract

All nine planned H07 metrics enter the model-data manifest independently of
H01 or H02 results. Metric-specific non-estimability is reason coded. L10 is
used; L5 is absent. Dose uses the approved time-sensitive correction only
when its support guard passes, and observed/corrected dose are both retained.
Sleep duration is labelled bedside-environment exposure.

The H07 artifact must provide:

- absolute latitude by site;
- participant-day photoperiod in hours with dawn/dusk provenance;
- collection dates and collection-period ranges by site;
- participant and participant-day support over the joint predictor surface;
- metric-specific missingness; and
- site and participant identifiers with explicit nesting.

No temperature or unsupported environmental predictor is introduced.

### Registered model attempt

The registered tensor model is attempted on identical metric-specific rows:

```text
M0:
g(metric) ~
  s(site, bs = "re") +
  s(participant, bs = "re")

M_tensor:
g(metric) ~
  te(abs_latitude, photoperiod) +
  s(site, bs = "re") +
  s(participant, bs = "re")
```

The transformation/family `g` comes from the common metric registry. Model
comparison uses a valid ML-based criterion on identical rows; final smooth
estimation may use fREML after the structure is fixed.

Before interpretation, the tensor requires:

- adequate occupied cells and ranges in the joint surface;
- acceptable design rank and concurvity;
- enough independent sites for latitude information;
- stable basis dimension and smoothing;
- residual and influence diagnostics; and
- stability to leaving out each site.

Failure is reported as `non-identifiable` or `non-estimable`; it does not
license a photoperiod-only ceiling claim.

### Plateau estimand and H07 major gate

A ceiling cannot be inferred from a slope p-value crossing 0.05. `H07-G1`
must fix an outcome-specific plateau definition before repaired values are
examined. A defensible definition requires all of:

1. an increasing association over an earlier supported range;
2. a predeclared practically negligible slope margin in the outcome's
   practical unit per hour photoperiod;
3. a sustained upper-range interval over which a simultaneous derivative
   interval lies within that margin;
4. adequate observations and independent sites throughout that interval; and
5. leave-one-site-out stability of the plateau classification and boundary.

If no external or scientific basis supports the slope margin, equivalence and
a ceiling are not claimed. The strongest permissible result is then a
nonlinear or attenuating association, or that a plateau is not identified.

`H07-G2` is required if the registered tensor is non-identifiable and a
photoperiod-only adapted model is proposed. That model must be labelled
adapted/exploratory, retain site adjustment where identifiable, and cannot be
described as the registered latitude-photoperiod hypothesis.

### Multiplicity

- `H07-F1-association`: all nine planned global nonlinear-association tests,
  one vector-wide BH family if p-values are used.
- `H07-F2-plateau`: all nine planned plateau/equivalence decisions, one
  declared family if inferential tests are used.
- Simultaneous derivative intervals control inference over each fitted curve;
  they do not replace cross-metric multiplicity.

If model selection remains AIC-based to preserve the registered rule, AIC
support is reported as model evidence rather than called a corrected
significance test. Outcome selection still includes all nine metrics.

### Required diagnostics

- joint latitude-photoperiod support and convex-hull/extrapolation map;
- site-specific collection periods and photoperiod ranges;
- metric-specific participants, days, sites, and missingness;
- design rank, concurvity, basis dimension, k-index, and smoothing stability;
- convergence, residual distribution, heteroscedasticity, and date-lag ACF;
- site, participant, and boundary influence;
- ML comparison and final-fit method provenance;
- simultaneous derivative and practical-equivalence intervals;
- leave-one-site-out plateau classification and boundary;
- pooled versus site-specific/LOSO reference-profile metrics where relevant;
  and
- paired/common-sample near-eye/chest comparison.

## Required H07 result-difference checks

Compare current and repaired:

- current H01-selected candidates versus all nine planned outcomes;
- metric support, participants, days, and sites;
- current H01 scalar-adjusted screen versus no upstream result screen;
- photoperiod-only versus registered tensor estimability;
- fREML AIC versus valid common-likelihood comparison;
- current pointwise “last positive” boundary versus the approved plateau
  estimand;
- raw, adjusted, and simultaneous inference;
- full-sample and leave-one-site-out curves/classifications;
- near-eye versus paired/common-sample chest curves;
- current six/four retained models versus all planned outcomes; and
- figure identity/order and exact source data.

Every reported hour boundary requires a producer row containing its margin,
support interval, simultaneous uncertainty, and influence classification.
If no plateau is identified, every “ceiling” claim and title is removed or
rewritten at the major gate.

## H07 dependencies and reopening

H07 depends on admissible daily metrics, latitude/photoperiod provenance,
collection-period audit, and the placement/common-sample manifest. It does
not depend on H01/H02 significance. Any change to a metric, plateau margin,
joint-support classification, predictor model, or site-influence result
reopens H07.

# H08: VLSQ-8 light sensitivity and exposure metrics

## Preregistered contract and current estimand

H08 asks whether all nine level-, duration-, and exposure-history metrics are
associated with VLSQ-8 score, with site-specific heterogeneity:

```text
Metric ~ VLSQ8 * Site +
  (1 | Site:Participant)
```

The current code fits the same fixed-effect structure for each metric but its
reported “confirmatory” comparison adds VLSQ-8 and every VLSQ-8-by-site
interaction simultaneously. It therefore estimates a joint
association-plus-heterogeneity test, not the cross-site average VLSQ-8
association claimed in the manuscript.

## Exact current inputs, metric set, and filters

### Inputs

- Near-eye: `data/metrics_glasses.RData`.
- Chest: `data/metrics_chest.RData`.
- Questionnaire:
  `melidosData::load_data("vlsq8") |> flatten_data()`.
- Join key: `site`, `Id`.

The current code filters the metric registry to:

```r
metric_type %in% c("duration", "exposure history", "level")
name != "duration_above_250"
```

and then retains rows with a non-missing response specification. This yields
the nine planned outcomes listed in the shared metric section.

Before the VLSQ join, the frozen near-eye registry contains 811
participant-days from 141 participants for each H08 row. Current non-missing
metric values are:

| Current outcome | Non-missing near-eye | Metric `NA` near-eye |
|---|---:|---:|
| Mean, M10, L10, duration >1,000, longest >250, dose | 811 | 0 |
| Pre-sleep duration <10 | 780 | 31 |
| Sleep duration <1 | 790 | 21 |
| Wake duration >250 | 755 | 56 |

The chest registry contains 897 participant-days from 154 participants:

| Current outcome | Non-missing chest | Metric `NA` chest |
|---|---:|---:|
| Mean, M10, L10, duration >1,000, longest >250, dose | 897 | 0 |
| Pre-sleep duration <10 | 867 | 30 |
| Sleep duration <1 | 878 | 19 |
| Wake duration >250 | 839 | 58 |

These are pre-questionnaire baseline counts, not H08 model counts and not
final metric-validity counts.

The current join does not assert one questionnaire row per
site-participant, audit VLSQ-8 item scoring, report score range by site, or
persist complete-case sample flow.

## Exact current response, family, and model map

| Outcome | Current response | Current engine/family |
|---|---|---|
| Mean, M10, L10 | `log_zero_inflated(metric)` | `lmer`, Gaussian |
| Dose | `log_zero_inflated(metric)` | `lmer`, Gaussian |
| Duration above 1,000 lx | `metric` | `glmmTMB`, Tweedie log |
| Duration above 250 lx during wake | `metric` | `glmmTMB`, Tweedie log |
| Duration below 10 lx during pre-sleep | `metric` | `glmmTMB`, Tweedie log |
| Duration below 1 lx during sleep | `metric` | `glmmTMB`, Tweedie log |
| Longest period above 250 lx | `log_zero_inflated(metric)` | `lmer`, Gaussian |

For each metric:

```text
H8_full:
response ~ site * VLSQ8 + (1 | Id)

H8_site_only:
response ~ site + (1 | Id)

H8_additive:
response ~ site + VLSQ8 + (1 | Id)

H8_vlsq_only:
response ~ VLSQ8 + (1 | Id)
```

The code claims site is sum-coded, but `fit_model()` passes no contrasts and
the saved site factors have no contrast attribute. Under the default R
options, treatment coding is used. The current global IDs are unique across
sites, so `(1|Id)` is numerically a participant intercept, but this property
is not asserted.

LMM fits use their default REML setting; `anova()` ordinarily refits differing
fixed-effect `lmer` models under ML. `glmmTMB` fits use their defaults. The
model frame is not explicitly compared before `anova()`.

## Exact current tests and multiplicity

The current comparisons are:

```text
site_only vs full:
joint VLSQ8 main effect + site interaction

additive vs full:
site-by-VLSQ8 interaction

VLSQ8_only vs additive:
site main effect
```

For every comparison and every metric, `model_comp_p()` receives one scalar
p-value and calls:

```r
p.adjust(p, method = "fdr", n = 9)
```

Thus each of the three nominal families is Bonferroni-like at the individual
p-value level, not vector-wide BH. Only the joint site-only-versus-full
comparison is displayed.

No VLSQ-8 coefficient, site-specific slope, predicted contrast, interval,
effect scale, model sample, or diagnostic is reported. The notebook explicitly
omits diagnostics on the rationale that base metric models were checked in
H01; predictor and interaction diagnostics are therefore never assessed.

## Current outputs and claims

Current files are:

- `tables/H8.png` and `tables/H8.docx`;
- `tables/chest/H8.png` and `tables/chest/H8.docx`; and
- manually copied `assets/H8.png`.

No H08 model, score audit, coefficient table, sample flow, diagnostics, or
source-data CSV is persisted.

The near-eye render reports every scalar-adjusted joint p-value as greater
than 0.9. The chest render reports no significant result, with displayed
values from 0.3 to greater than 0.9. The current manuscript concludes that
visual light sensitivity was not associated with exposure and states “all
p > 0.9.” The Discussion groups VLSQ-8 with sex and age as showing limited
associations.

These are absence-of-evidence statements from a joint test with mislabelled
multiplicity and no estimates or intervals. They are reopened.

## Confirmed defects and risks

1. **Scalar multiplicity error (`IMP-001`).** Nine p-values are never adjusted
   as a vector.
2. **Wrong primary test interpretation.** Site-only versus full jointly adds
   the predictor and interaction.
3. **Coding claim is false.** Site is not explicitly sum-coded in the current
   fit.
4. **No effect estimates or intervals.** A null claim cannot be calibrated for
   practical magnitude.
5. **No VLSQ-8 scale audit.** Item scoring, direction, missing rule, range,
   duplicates, and site support are absent.
6. **No model-specific sample flow.** The questionnaire join and
   metric-specific missingness are hidden.
7. **No interaction support check.** Sparse near-eye sites can make
   site-specific slopes unstable.
8. **Diagnostics incorrectly inherited.** H01 diagnostics cannot validate a
   new predictor, interaction, or model frame.
9. **Distribution choice not rechecked.** Zero mass, tail behaviour, and
   transformed residuals can differ after questionnaire complete-case
   filtering.
10. **Daily dependence incomplete.** Repeated participant-days have a
    participant intercept but no check of serial date dependence.
11. **Sleep construct underlabelled.** The below-1-lx outcome is bedside sleep
    environment.
12. **No equivalence framework.** Non-significance is not evidence of no
    practically relevant association.
13. **Deviation-document gap (`DOC-001`).** The current deviation document
    ends after H07, so H08 implementation discrepancies are not disclosed.
14. **No durable producer.** The manuscript consumes a manually copied p-only
    table.

## Proposed repaired specification

### VLSQ-8 scale and metric contract

Before modelling, export a one-row-per-site-participant VLSQ-8 artifact with:

- item names and response ranges;
- reverse-coding and score formula;
- missing-item rule;
- score direction and possible range;
- observed range, centre, and SD overall and by site;
- duplicates and resolution;
- contributing participants by site and placement scenario; and
- translation/version provenance.

This is a scoring audit, not a new psychometric validation study. Any score
reconstruction that changes participant values or inclusion is a major gate.

All nine planned metrics remain in the H08 registry. Metric-specific
non-estimability remains explicit. Sleep duration below 1 lx is labelled
bedside-environment exposure, and dose retains observed/corrected provenance.

### Primary and interaction models

For each metric, use one exact model frame and fit:

```text
M0:
g(metric) ~ site +
  (1 | site:participant)

M_vlsq:
g(metric) ~ site + VLSQ8_c +
  (1 | site:participant)

M_full:
g(metric) ~ site * VLSQ8_c +
  (1 | site:participant)
```

`VLSQ8_c` is the raw score centred at a declared participant-level reference.
Report the slope per raw score unit and per one participant-level SD. Site is
sum-to-zero coded so the additive VLSQ-8 slope is the equal-site average
association. The interaction model supplies site-specific slopes only when
the design is supported.

The primary association test is `M0` versus `M_vlsq`. The heterogeneity test
is `M_vlsq` versus `M_full`. If the interaction is unstable or unsupported,
the additive estimate remains the primary result and the interaction is
reported as non-estimable rather than silently simplified.

The current response/family map is a continuity candidate, not an automatic
approval. Every response uses the shared metric-specific distribution
registry and a common-sample zero-supporting alternative where justified.
Models check date-lag residual dependence; a supported correlation structure
is added as a named sensitivity if needed.

Report practical-scale predicted exposure at meaningful VLSQ-8 values or
quantiles, the slope/ratio with 95% interval, and the observed score support.
The primary conclusion is calibrated as association present, imprecise,
compatible with only small associations, or non-estimable. “No association”
requires a separately justified equivalence margin and is not inferred from
`p > 0.05`.

### Multiplicity

- `H08-F1-main`: all nine planned `M0` versus `M_vlsq` tests, adjusted
  together by BH.
- `H08-F2-heterogeneity`: all nine planned `M_vlsq` versus `M_full` tests,
  adjusted together by BH.
- `H08-F3-site-slopes`: if inferential site-specific contrasts are reported,
  all requested estimable site-by-metric slope deviations form one declared
  vector. Otherwise report estimates and intervals without a significance
  screen.

Raw p-values, family sizes, ranks, adjusted values, and non-estimability
reasons are durable outputs.

### Required diagnostics

- VLSQ-8 key uniqueness, construction, distribution, range, and site support;
- metric-specific participants, days, sites, and questionnaire complete cases;
- within-site score range and site-by-score design rank;
- convergence, Hessian, gradients, singularity, and random-effect stability;
- zero mass, dispersion, tails, and transformed/simulated residuals;
- participant date-lag residual dependence;
- influential participants and leave-one-site-out estimates;
- equal-site versus observed-sample marginalization;
- raw-unit versus SD-scaled effect interpretation;
- model-family common-sample sensitivity; and
- paired/common-sample near-eye/chest slopes and placement heterogeneity.

## Required H08 result-difference checks

Compare current and repaired:

- VLSQ-8 scores, missingness, duplicates, range, and site support;
- current pre-join versus exact model-specific participants and days;
- current metric values versus support-aware repaired values;
- current treatment coding versus explicit sum coding;
- current joint association-plus-interaction test versus separate primary and
  heterogeneity tests;
- current scalar-adjusted versus vector-BH p-values;
- newly reported slopes/ratios and intervals in practical units;
- current all-`p > 0.9` statement versus calibrated effect-size evidence;
- site and participant influence;
- all-near-eye versus paired/common-sample near-eye and chest estimates; and
- sleep-environment wording for the below-1-lx outcome.

Any newly significant result, loss of a planned metric, materially wide
interval, or change from “no association” to “inconclusive” opens the major
claim gate.

## H08 dependencies and reopening

H08 depends on the VLSQ-8 scale artifact, repaired daily metrics,
metric-validity re-audit, model-family registry, and placement/common-sample
manifest. It does not inherit H01 diagnostics or results. Any change to score
construction, metric admissibility, model family, main/interaction family, or
site-support classification reopens H08.

# Canonical output contract for all four notebooks

Each completed audit HTML must also contain a visible, evaluated R code cell
that prints the exact Wilkinson formulas passed to every selected and
comparison model. The cell must obtain them from the actual formula builder or
fitted objects; one generic response formula is allowed only for genuinely
identical model structures.

Every H05–H08 placement/scenario run must produce:

1. an exact model/correlation frame RDS with keys and inclusion reasons;
2. fitted model RDS files for every declared model, where applicable;
3. a model manifest with formula, family, link, method, contrast coding,
   package versions, hashes, convergence, warnings, and row counts;
4. raw and adjusted test CSVs with family IDs, planned size, rank, and
   non-estimability;
5. practical-scale estimates, contrasts, and 95% intervals;
6. sample-flow CSVs at site, participant, participant-day, hour, metric,
   questionnaire, and category levels as applicable;
7. durable diagnostic plots and machine-readable summaries;
8. a result-difference CSV against the frozen baseline;
9. publication table/figure files; and
10. exact source-data CSVs for every figure and durable table.

Suggested deterministic paths are:

```text
artifacts/07_models/H0x/<placement>/<scenario>/
artifacts/08_diagnostics/H0x/<placement>/<scenario>/
artifacts/09_tables/H0x_<placement>_<scenario>.*
artifacts/10_figures/H0x_<placement>_<scenario>.*
artifacts/11_source_data/H0x_<display_id>_<placement>_<scenario>.csv
artifacts/12_manifests/H0x_<placement>_<scenario>_manifest.csv
```

The assembly notebook selects approved near-eye primary and complementary
outputs. Hypothesis notebooks never copy files manually into `assets/`.

# Major gates identified by this map

| Gate | Decision required before fitting or reporting |
|---|---|
| `H05-G1` | Decide whether the registered site-adjusted metric model is primary and the correlation matrix descriptive, or whether the participant-level correlation remains primary as an explicit deviation. |
| `H06-G1` | Choose the registered daily-metric estimand or the documented hourly-geometric-MEDI adaptation; also fix the primary day-type and predictor set. |
| `H07-G1` | Define an externally/scientifically justified metric-specific plateau margin and sustained-support rule, or prohibit a ceiling claim. |
| `H07-G2` | If the registered latitude-photoperiod tensor is non-identifiable, approve or reject a photoperiod-only adapted analysis. |
| Result gates | Reopen the relevant unit if corrected metric support, vector BH, model structure, placement/common-sample analysis, or influence checks change a substantive result or manuscript claim. |

# Migration acceptance criteria

H05–H08 migration is complete only when:

- every major gate above has a documented disposition;
- each notebook runs in a clean R 4.6.1 session from explicit inputs;
- canonical-current-rule runs reproduce every unaffected current operation or
  explain the discrepancy;
- repaired metrics have passed the metric-validity re-audit;
- all questionnaire, diary, metric, and model joins have asserted
  cardinality;
- sample flow reconciles across models, figures, tables, prose, and reporting
  forms;
- every p-value belongs to a declared vector-wide family;
- main associations and site heterogeneity are not conflated;
- every estimate has a practical-scale interval;
- all diagnostic failures and non-estimable results remain visible;
- H05 uses one correlation method for coefficient and p-value and does not
  call `rho^2` variance explained;
- H06 reports the approved unit of analysis, represents temporal dependence,
  and never displays a stale result;
- H07 selects no outcome from H01 significance and makes no ceiling claim
  from derivative non-significance;
- H08 reports effect sizes and does not infer absence from a large p-value;
- near-eye and chest results are not pooled or described as independent
  additions to ocular sample size;
- sleep-period metrics are consistently identified as bedside-environment
  exposure;
- every display has exact source data and correct metric identity; and
- no current H05–H08 number remains in the Nature Health manuscript without a
  verified canonical producer and claim-provenance entry.
