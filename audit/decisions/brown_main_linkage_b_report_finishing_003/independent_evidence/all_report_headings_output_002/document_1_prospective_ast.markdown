---
title: "Brown recommendation adherence: implementation and reconciliation"
subtitle: "Internal current-main record and complete sensitivity disposition"
date: last-modified
engine: knitr
format:
  html:
    toc: true
    toc-depth: 3
    number-sections: true
    code-fold: true
    code-tools: false
    embed-resources: true
    page-layout: full
    css: ../../stage3_cross_state_association/report.css
execute:
  echo: false
  warning: false
  message: false
  error: false
  freeze: false
---


```{.r}
#| label: setup-current-implementation
#| include: false
options(stringsAsFactors = FALSE, scipen = 999)
source(file.path(Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"), "audit/analyses/brown_adherence/main_linkage_b_amendment/stage3/code/report_data.R"))
source(file.path(br_amendment, "stage3/code/report_sensitivities.R"))
source(file.path(br_amendment, "stage4/code/report_methods.R"))
main <- br_load_tables()
br_load_sensitivities()
br_load_methods()
knitr::opts_knit$set(root.dir = br_analysis)
br_verify_leaves()
```

## Disposition and controlling record {#sec-disposition}

The complete B/B80 main-model pair and bounded finishing calculations are independently verified under BA-018 / CHG-157. The scientific disposition remains qualified: Pre-sleep fails the registered 80% coverage criterion, temporal dependence remains unresolved, and failed sensitivity routes have no inferred results. Numerical completion is not unconditional scientific success or final report acceptance.

Package 011 preserves 95 supervised execution histories, including eight nonzero attempts. This report executes frozen aggregate formatting only. No fitting, prediction, simulation, resampling, contrast, confidence-interval or FDR calculation occurs here. The final BA-LB-REPORTS-REVIEW is not closed by this document.

The [reader results](../../13_cross_state_association_results_amendment.html#sec-brown-main-results) and [preparation companion](../../14_cross_state_association_preparation_and_provenance.html#sec-purpose) use the complete main package with exact reuse of the separate exploratory extension. Writer and shared-page propagation remain separate.

## Construction and exact samples {#sec-construction}

Grouping B links preceding Sleep, the full Daytime period and following three-hour Pre-sleep. The wake-start date owns Work/Free classification. Actual dates and UTC boundaries establish chronology; source-row proximity does not imply adjacent dates. Grouping C remains a stored sensitivity.

Expected duration defines coverage. Brown yes plus Brown no defines the likelihood denominator. Each window qualifies independently and exact zero/one proportions remain. No sample is rebuilt during reporting.

```{.r}
#| label: tbl-implementation-contract
#| tbl-cap: "Outcome, timing, coverage and valid-minute contract."
br_show("measurement")
```

`r br_source_links("measurement", "../../")`


```{.r}
#| label: tbl-implementation-samples
#| tbl-cap: "Exact primary sample totals."
br_show("samples")
```

`r br_source_links("samples", "../../")`


```{.r}
#| label: tbl-implementation-support
#| tbl-cap: "Complete window by site by day-type support."
br_show("support")
```

`r br_source_links("support", "../../")`

## Likelihood and repeated-measures structure {#sec-model}

Both main samples retain F3/R3/Q2/Q1/D0: the full fixed interaction, one mean participant intercept, additive window/day-type extra-zero weights, supported-window by day-type extra-one weights and window-specific beta-binomial precision. Extra Daytime all-one mass is fixed to zero.

```{.r}
#| label: exact-current-formulas
#| echo: true
mean_formula <- cbind(brown_yes, brown_no) ~ analysis_state * site * day_type + (1 | participant)
zero_formula <- ~ analysis_state + day_type
one_formula <- ~ boundary_one_state * day_type
dispersion_formula <- ~ analysis_state
list(mean = mean_formula, extra_zero = zero_formula,
     extra_one = one_formula, dispersion = dispersion_formula)
```

These formula objects describe the retained structure, not fitting calls. The implementation uses a site-unique participant key, logit mean, log precision and multinomial mixture weights. TMB calculations used Laplace integration. Structural simplification did not depend on preferred p-values. Inactive slope, cycle and endpoint-process components are not estimates of zero variance.

```{.r}
#| label: tbl-implementation-components
#| tbl-cap: "Selected main and exploratory components."
br_show("model_components")
```

`r br_source_links("model_components", "../../")`


```{.r}
#| label: tbl-implementation-routes
#| tbl-cap: "All saved model dispositions, including failed routes."
br_show("routes")
```

`r br_source_links("routes", "../../")`

## Means, contrasts and multiplicity {#sec-estimands}

Every main value comes from the complete current joint model, including windows with unchanged underlying observations. Population-average adherence integrates the participant distribution; nine sites each receive equal weight. The reference is not a pooled-minute fraction.

The first five main BH families are retained separately within each sample. The sixth main family is one primary 27-test adjustment with an identical unadjusted coverage repetition. The exploratory four-member family is separate. CI exclusion and FDR thresholds are not interchangeable.

```{.r}
#| label: tbl-implementation-levels
#| tbl-cap: "All equal-site adherence levels and 95% CIs."
br_show("levels")
```

`r br_source_links("levels", "../../")`


```{.r}
#| label: tbl-implementation-primary
#| tbl-cap: "Window-specific Free-minus-Work differences."
br_show("primary")
```

`r br_source_links("primary", "../../")`


```{.r}
#| label: tbl-implementation-interactions
#| tbl-cap: "Window-specific and global site interaction tests."
br_show("interactions")
```

`r br_source_links("interactions", "../../")`


```{.r}
#| label: tbl-implementation-compact
#| tbl-cap: "Primary compact site and day-type table."
br_show("compact")
```

`r br_source_links("compact", "../../")`


```{.r}
#| label: tbl-implementation-families
#| tbl-cap: "Testing families and coverage roles."
br_show("multiplicity")
```

`r br_source_links("multiplicity", "../../")`


```{.r}
#| label: tbl-implementation-localizations
#| tbl-cap: "All site-effect-minus-average comparisons and coverage checks."
br_show("localizations")
```

`r br_source_links("localizations", "../../")`

## Calibration and coverage {#sec-calibration}

Main endpoint calibration passes all five applicable predictive envelopes in both samples. Overall adherence remains acceptable with limitations, and actual-date temporal triggers remain present. These are separate assessments.

The primary Pre-sleep CI excludes zero, but its at-least-80% CI includes zero. Direction is retained; the registered coverage gate is false. This is neither evidence of no association nor a test comparing the two estimates.

```{.r}
#| label: tbl-implementation-endpoints
#| tbl-cap: "Observed endpoint counts and stored predictive envelopes."
br_show("endpoints")
```

`r br_source_links("endpoints", "../../")`


```{.r}
#| label: tbl-implementation-coverage
#| tbl-cap: "Exact any-valid versus at-least-80% claim gate."
br_show("coverage")
```

`r br_source_links("coverage", "../../")`


```{.r}
#| label: tbl-implementation-diagnostics
#| tbl-cap: "Main, chest and temporal diagnostic dispositions."
br_show("diagnostics")
```

`r br_source_links("diagnostics", "../../")`

## Sensitivity battery and preserved failures {#sec-sensitivity}

The complete comparison table contains every eligible stored simple, family, calendar, chest, temporal and deletion contrast. DIAG-BINOMIAL and INFLUENCE-4 failed and have no derived inference. All nine site deletions and the other four participant deletions have eligible stored contrasts. No exhaustive deletion battery or bootstrap is performed.

The zero-exclusion endpoint route failed separation; its conditional route is separate. Coverage 70%, coverage 90% and the both-day-type restriction do not retain Pre-sleep's interval decision. Coverage 90% and both-day-type restrictions also exceed the two-percentage-point shift criterion.

```{.r}
#| label: tbl-implementation-sensitivities
#| tbl-cap: "Every eligible recorded sensitivity contrast."
br_show("sensitivities")
```

`r br_source_links("sensitivities", "../../")`


```{.r}
#| label: tbl-implementation-family-status
#| tbl-cap: "Response-family disposition including the failed binomial route."
br_show("family_status")
```

`r br_source_links("family_status", "../../")`


```{.r}
#| label: tbl-implementation-weighting
#| tbl-cap: "Observed-site versus equal-site weighting."
br_show("weighting")
```

`r br_source_links("weighting", "../../")`


```{.r}
#| label: tbl-implementation-grouping
#| tbl-cap: "Preserved C grouping comparison, without a new between-model test."
br_show("grouping")
```

`r br_source_links("grouping", "../../")`

### Actual-date temporal models

Both ENDPOINT-R3 candidates failed structural checks. B80 covariance was finite but indefinite, not nonfinite. BB-R0 was the first eligible route in each sample; BB-R3 was not run. The fallback changes both family and random structure and retains near-boundary cautions.

The stored fixed-covariance delta convention holds fitted variance parameters fixed while integrating random components. Corresponding primary directions and interval decisions persist, but endpoint calibration fails all five applicable checks in both fallback samples. Any-valid Daytime retains its Pearson residual trigger. Absence of a registered B80 trigger does not prove independence. Neither fallback replaces the primary model.

```{.r}
#| label: tbl-implementation-temporal-routes
#| tbl-cap: "Recorded temporal candidates and structural gates."
br_show("temporal_routes")
```

`r br_source_links("temporal_routes", "../../")`


```{.r}
#| label: tbl-implementation-temporal-residuals
#| tbl-cap: "Stored actual-date residual checks."
br_show("temporal_residuals")
```

`r br_source_links("temporal_residuals", "../../")`

### Calendar and complementary chest

The calendar-day comparator retains a random-variance boundary caution. Chest uses a separate eight-site, two-window sample with 153 participants, not a paired sensor-position experiment within the 140-participant primary sample. Sleep is a bedside measurement, not a chest or ocular result.

```{.r}
#| label: tbl-implementation-chest
#| tbl-cap: "Complementary chest summaries."
br_show("chest")
```

`r br_source_links("chest", "../../")`

## Point-only variance decomposition {#sec-r2}

Fifteen-node versus thirty-node numerical agreement passes. This does not provide sampling uncertainty. The participant increment is conditional minus marginal R² in percentage points of explained response variance, not adherence. Relative Shapley weights divide by fixed-effect variance; absolute contributions divide by total response variance. Global and within-window balanced references contain 54 and 18 cells, respectively.

```{.r}
#| label: tbl-implementation-random
#| tbl-cap: "Only retained participant-intercept standard deviations."
br_show("random")
```

`r br_source_links("random", "../../")`


```{.r}
#| label: tbl-implementation-r2
#| tbl-cap: "Fixed, participant and observation/distribution variance shares."
br_show("r2")
```

`r br_source_links("r2", "../../")`


```{.r}
#| label: tbl-implementation-shapley-global
#| tbl-cap: "Global full-model Shapley allocation."
br_show("shapley_global")
```

`r br_source_links("shapley_global", "../../")`


```{.r}
#| label: tbl-implementation-shapley-within
#| tbl-cap: "Within-window Shapley allocation."
br_show("shapley_within")
```

`r br_source_links("shapley_within", "../../")`

## Exact exploratory reuse {#sec-reuse}

The physical dates and counts reconcile with the frozen exploratory pair subset, without expanding it to every potential main-model pair. Its eligible rows remain 1,376 and 1,199. Within/between and composition predictors, all four contrasts and diagnostics remain unchanged.

The 139-profile/417-point raincloud, including its anonymous mapping, jitter and density, is exact reuse. It is not a ranking or stable-trait classification. The exploratory day-level claim remains withheld; inverse between-participant associations retain the temporal, influence and non-causal qualifications.

```{.r}
#| label: tbl-implementation-reuse
#| tbl-cap: "Exact exploratory subset versus potential main pairs."
br_show("pair_eligibility")
```

`r br_source_links("pair_eligibility", "../../")`

## Current four-figure display chain {#sec-displays}

All four figures below read current main aggregate outputs. Their paired sources preserve estimates, intervals, references and stored significance criteria. These are display operations, not scientific recalculation.

![Current equal-site adherence levels. Daytime, Pre-sleep and Sleep identify the Brown recommendation windows.](../stage3/figures/main_adherence_levels.png){#fig-implementation-levels fig-alt="Six Work-day and Free-day levels with 95% CIs." width="100%"}

[Paired source](../stage3/source_data/main_adherence_levels_source.csv)

![Current Work-day site adherence levels, with distinct site-minus-average tests.](../stage3/figures/main_site_workday.png){#fig-implementation-workday fig-alt="All 27 Work-day levels, CIs and nine country-coded sites per window; diamonds indicate the separate FDR site-minus-average comparison." width="100%"}

[Paired source](../stage3/source_data/main_site_workday_source.csv)

![Current site Free-minus-Work differences: diamonds compare with zero; asterisks compare with the equal-site effect.](../stage3/figures/main_site_free_work.png){#fig-implementation-free-work fig-alt="All 27 site effects and CIs with distinct against-zero and departure-from-average markers." width="100%"}

[Paired source](../stage3/source_data/main_site_free_work_source.csv)

![Current coverage comparison. The Pre-sleep 80% interval crosses zero.](../stage3/figures/main_coverage.png){#fig-implementation-coverage fig-alt="Six any-valid and coverage-restricted contrasts with visible vertical guides and a zero line." width="100%"}

[Paired source](../stage3/source_data/main_coverage_source.csv)

## Preservation and reproducibility {#sec-provenance}

All 145 complete frozen aggregate exports retain their original identities. Canonical reader preimages are preserved through exact identity-specific historical maps. Older versions continue to use their existing sealed baselines; no old manifest is repinned. The report code never loads restricted participant frames or model RDS files.

```{.r}
#| label: tbl-implementation-artifacts
#| tbl-cap: "Frozen output collections and exact identities."
br_show("artifacts")
```

`r br_source_links("artifacts", "../../")`


```{.r}
#| label: tbl-implementation-environment
#| tbl-cap: "Consequential software versions."
br_show("environment")
```

`r br_source_links("environment", "../../")`

The technical execution and draw accounting remain in `completion_v2/continued_final_package_011/`. Every failed attempt and qualified diagnostic route is preserved. Reporting evidence separately records source-to-claim mapping, candidate promotion, one render, semantic repair, visual coverage and protected identities.

## Review state {#sec-review}

Scientific calculations are complete with the qualifications above. This internal report and the prepared reader sources require independent reporting acceptance. Stage 3 and Stage 4 renders are released separately, serially. Final author acceptance is not presumed and no downstream manuscript or website update is implied.
