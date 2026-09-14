---
title: "Recommendation adherence: preparation and provenance"
subtitle: "Measurement, modelling and interpretation of the Brown recommendation windows"
date: last-modified
engine: knitr
format:
  html:
    toc: true
    toc-depth: 3
    number-sections: true
    code-fold: true
    code-summary: "Show stored-output R code"
    code-tools: false
    embed-resources: true
    page-layout: full
    css: stage3_cross_state_association/report.css
execute:
  echo: false
  warning: false
  message: false
  error: false
  freeze: false
tbl-cap-location: top
---

```{.r}
#| label: setup-stage4-provenance
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

## Purpose and scope {#sec-purpose}

This companion explains how the [integrated recommendation-adherence results](13_cross_state_association_results_amendment.html#sec-brown-main-results) were constructed and checked. The main analysis compares Work and Free days across recommendation windows and sites. A separate exploratory extension asks whether Daytime adherence aligns with Sleep or Pre-sleep adherence within cycles and between participants.

This page presents stored methods, samples and model checks. It does not repeat model estimation or calculate new inferential results.

## Analysis path {#sec-map}

```{.mermaid}
flowchart TD
  A["Valid minute-level melEDI measurements"] --> B["Inclusive Brown recommendation checks"]
  B --> C["Preceding Sleep, Daytime, following Pre-sleep"]
  C --> D["Work or Free day of the wake-start date"]
  D --> E["Independent window eligibility"]
  E --> F["Any-valid primary sample"]
  E --> G["At least 80% coverage sensitivity"]
  F --> H["Endpoint-inflated beta-binomial model"]
  G --> H
  H --> I["Equal-site main results and model checks"]
  E --> J["Eligible paired Daytime-Sleep and Daytime-Pre-sleep observations"]
  J --> K["Within- and between-participant associations"]
  K --> L["Limited participant-level result; day-level claim withheld"]
  I --> M["Integrated reader report"]
  L --> M
```

The diagram describes the data and analysis dependencies, not new computation in this document.

## Measurement and outcome construction {#sec-measurement}

### Recommendation windows and valid comparisons

Daytime, Pre-sleep and Sleep identify the Brown et al. recommendation windows. Daytime excludes the three-hour Pre-sleep window. Melanopic equivalent daylight illuminance (melEDI) is expressed in lux. Each valid minute is classified using the inclusive threshold for its window.

```{.r}
#| label: tbl-stage4-measurement-contract
#| tbl-cap: "Measurement, denominator and coverage definitions."
br_show("measurement")
```

`r br_source_links("measurement")`

The primary Daytime and Pre-sleep stream is near-eye. Sleep is a device-recorded bedside measurement near the sleeper, neither ocular exposure nor a whole-bedroom measure. The complementary chest stream remains a separate two-window analysis.

### Temporal alignment and day ownership

A wake-start date anchors the preceding Sleep, full Daytime and following three-hour Pre-sleep windows. The Work or Free classification belongs to that date. This keeps the daytime interval together even when the adjoining windows cross midnight. Validity is assessed separately for each window.

Actual diary dates and UTC interval bounds establish chronology. Diary row numbers provide provenance only: adjacent stored rows are not assumed to be adjacent dates, and gaps are not bridged. The exploratory pairs use their own frozen eligibility rules within this same temporal alignment.

```{.r}
#| label: tbl-stage4-chronology
#| tbl-cap: "Actual-date and UTC-boundary reconciliation for the exploratory pairs."
br_show("chronology")
```

`r br_source_links("chronology")`

## Exact samples and privacy {#sec-samples}

### Main samples

The primary sample includes every window period with at least one valid comparison. The coverage sensitivity keeps the same outcome construction and model structure while requiring at least 80% valid minutes relative to expected duration. A cycle need not contain all three eligible windows.

```{.r}
#| label: tbl-stage4-main-sample
#| tbl-cap: "Main-analysis periods, participants, cycles and valid-minute denominators."
br_show("samples")
```

`r br_source_links("samples")`

### Exploratory eligibility

Daytime-Sleep and Daytime-Pre-sleep observations are pairwise complete, not a mandatory complete-triad sample. The eligible exploratory samples contain 1,376 and 1,199 target rows. They do not exhaust every potential pair in the main analysis. In particular, some main-model Pre-sleep windows fall outside the exploratory eligibility set; they are not silently added to the extension.

```{.r}
#| label: tbl-stage4-association-sample
#| tbl-cap: "Frozen pairwise samples and target-specific denominators."
br_show("association_sample")
```

`r br_source_links("association_sample")`


```{.r}
#| label: tbl-stage4-pair-eligibility
#| tbl-cap: "Exploratory eligibility compared with potential main-model pairs."
br_show("pair_eligibility")
```

`r br_source_links("pair_eligibility")`

### Anonymous participant display

The connected raincloud uses equal-cycle participant means after deduplicating Daytime within participant and cycle. The complete three-window display contains 139 anonymous profiles and 417 points. Its source, profile mapping, density, jitter and figure are unchanged. Connections join the same profile across windows, not observations over time or participant ranks.

```{.r}
#| label: tbl-stage4-profile-flow
#| tbl-cap: "Sample flow for the descriptive participant-profile display."
br_show("profile_flow")
```

`r br_source_links("profile_flow")`


```{.r}
#| label: tbl-stage4-privacy
#| tbl-cap: "Privacy boundary of the anonymous display source."
br_show("privacy")
```

`r br_source_links("privacy")`

No raw participant identifiers, site-linked profile keys, rankings or hard participant-tertile assignments appear in the reader reports.

## Model implementation {#sec-models}

### Main likelihood and repeated observations

For a window with $n$ valid minutes, the response comprises adherent and non-adherent counts. The endpoint-inflated likelihood combines extra all-no mass, extra all-yes mass where supported, and a beta-binomial count component. It therefore retains exact zero and one adherence and allows dependence among minutes to produce more variation than an ordinary binomial model.

The mean uses a logit link. Window, site and day type use sum-to-zero contrasts. The full fixed interaction is retained. The selected random structure contains one mean participant intercept. Window and day-type slopes, a cycle intercept and endpoint-process intercepts were not retained after their structural checks; they are not estimated zero-variance components.

```{.r}
#| label: tbl-stage4-model-components
#| tbl-cap: "Selected mean, endpoint and dispersion components."
br_show("model_components")
```

`r br_source_links("model_components")`

The following formula objects describe the retained main model. Here `participant` denotes the site-unique participant key; `analysis_state` is the stored recommendation-window factor. The supported all-yes factor includes Pre-sleep and Sleep only.

```{.r}
#| label: retained-main-formulas
#| echo: true
main_mean <- cbind(brown_yes, brown_no) ~ analysis_state * site * day_type + (1 | participant)
extra_all_no <- ~ analysis_state + day_type
extra_all_yes <- ~ boundary_one_state * day_type
dispersion <- ~ analysis_state
list(main_mean = main_mean, extra_all_no = extra_all_no,
     extra_all_yes = extra_all_yes, dispersion = dispersion)
```

The extra all-no and all-yes linear predictors enter the mixture weights; they are not additional independent adherence outcomes. Daytime extra all-yes mass is fixed at zero. Likelihood estimation used TMB and Laplace integration. Simplification was driven by support and numerical structure, not preferred p-values.

### Reporting averages and uncertainty

The model supplies population-average adherence on the response scale, integrating the retained participant distribution. Nine sites each receive weight 1/9. A site-average Work or Free estimate is therefore not an observed pooled-minute proportion. Free-minus-Work differences are percentage points. Site-level averages and their contrasts use the joint stored covariance, rather than treating the site reference as an independent estimate.

The exact minute denominators remain part of the count likelihood. Missing minutes are not imputed. Variance decomposition uses a balanced 54-cell reference globally and 18 cells within a window. It reports fixed, participant and observation/distribution shares. Shapley weights allocate fixed-effect variation across window, site and day type globally, or site and day type within window. Relative weights divide by fixed-effect variance; absolute R² contributions divide by total variance. All decomposition outputs are point-only and non-causal.

### Exploratory within- and between-participant questions

The extension includes both a participant's deviation from their observed average Daytime adherence and that observed average itself, with a centered Free-Daytime fraction to adjust day-type composition. Target-specific Sleep and Pre-sleep responses are fitted together. Response effects describe 10 percentage points higher Daytime adherence with equal-site and 50:50 Work/Free weighting. Conditional logit slopes and response-scale effects describe different scales.

The participant intercept is retained; the association-cycle intercept could not be retained. Correlations of fitted participant modes are not substituted for covariance parameters. No failed extended-covariance model is interpreted.

::: {.callout-note collapse="true" title="Recorded structural routes"}


```{.r}
#| label: tbl-stage4-main-transitions
#| tbl-cap: "Main model and sensitivity dispositions, including every failed route."
br_show("routes")
```

`r br_source_links("routes")`


```{.r}
#| label: tbl-stage4-cross-transitions
#| tbl-cap: "Separate exploratory structural and sensitivity path."
br_show("cross_transitions")
```

`r br_source_links("cross_transitions")`

:::

## Model checks and sensitivity interpretation {#sec-diagnostics}

Main endpoint calibration passed all five applicable predictive envelopes in both samples. Overall adherence calibration was acceptable with limitations, and actual-date residual dependence remained triggered. The 80% analysis preserves Daytime and Sleep direction and CI exclusion, but Pre-sleep's interval crosses zero. This qualification is not evidence of no association and not a test that the two estimates differ.

Both attempted endpoint-inflated temporal routes failed. The coverage-restricted candidate had a finite but indefinite covariance matrix. The first eligible beta-binomial temporal fallback in each sample retained a near-boundary caution; later fallback rungs were not run. These models change both family and random structure. They preserve corresponding Free-minus-Work directions and interval conclusions, but their endpoint calibration fails all five applicable envelopes. Any-valid Daytime residual correlation remains triggered; no trigger in the coverage fallback does not prove independence. Neither fallback replaces the primary model.

The diary-indexed grouping remains a sensitivity. The calendar-day comparator retains a variance-boundary caution. Coverage thresholds, tiny denominators, complete cycles, both-day-type support, strict thresholds, zero-period handling, dispersion, alternative families and site weighting are separately recorded. All nine leave-one-site-out results and four eligible participant-deletion results remain available; the fifth deletion and ordinary-binomial diagnostic have no derived inference after failure.

The chest analysis uses a separate eight-site, two-window sample. Its sample, calibration and temporal qualifications are not evidence of equivalence between sensor positions.

```{.r}
#| label: tbl-stage4-main-diagnostics
#| tbl-cap: "Separate main and sensitivity calibration assessments."
br_show("diagnostics")
```

`r br_source_links("diagnostics")`


```{.r}
#| label: tbl-stage4-temporal-routes
#| tbl-cap: "Recorded temporal candidates and structural dispositions."
br_show("temporal_routes")
```

`r br_source_links("temporal_routes")`

For the exploratory extension, endpoint calibration was acceptable, but residual temporal dependence and incomplete sensitivity fits prevent a day-level scientific claim. The inverse between-participant associations remain exploratory and non-causal; they do not identify stable traits or ranked participant groups.

```{.r}
#| label: tbl-stage4-cross-diagnostics
#| tbl-cap: "Exploratory model-check assessments."
br_show("cross_diagnostics")
```

`r br_source_links("cross_diagnostics")`

## Multiple testing and site-reference contrasts {#sec-multiplicity}

### Separate testing families

Different scientific questions use distinct Benjamini-Hochberg FDR families. The first five main families are calculated separately within the any-valid and 80% samples. The additional site-effect-minus-reference family has one primary adjustment only; its coverage repetition checks stability without another FDR family. The exploratory within/between analysis has its own four-effect family.

```{.r}
#| label: tbl-stage4-multiplicity
#| tbl-cap: "Testing-family definitions and coverage roles."
br_show("multiplicity")
```

`r br_source_links("multiplicity")`

### Departure from the equal-site Free-minus-Work effect {#departure-from-the-equal-site-work-free-effect}

A site's Free-minus-Work effect is compared with the equal-site effect in the same window. Each reference includes the indexed site with weight 1/9. The stored contrast is reconciled both as site Free-minus-Work effect minus equal-site Free-minus-Work effect, and as Free-day site deviation minus Work-day site deviation. Its uncertainty uses the joint 54-cell covariance. Within each window, the nine signed deviations sum to zero to numerical tolerance.

These are distinct from tests of each site's Free-minus-Work effect against zero. The results figure uses separate symbols for the two questions.

```{.r}
#| label: tbl-stage4-ba-m6-derivation
#| tbl-cap: "Stored component reconciliation for all site-effect-minus-reference contrasts."
br_show("derivation")
```

`r br_source_links("derivation")`


```{.r}
#| label: tbl-stage4-ba-m6-localizations
#| tbl-cap: "All site departures and their coverage-sensitivity results."
br_show("localizations")
```

`r br_source_links("localizations")`

## Reproducibility and provenance {#sec-provenance}

### From calculation to display

The [implementation and reconciliation report](main_linkage_b_amendment/stage2/implementation_and_reconciliation.html) retains exact numerical routes, failed attempts, runtime accounting and full stored comparisons. This companion explains their scientific role without repeating computation.

```{.r}
#| label: tbl-stage4-execution-map
#| tbl-cap: "Measurement, analysis and display dependencies."
br_show("execution")
```

`r br_source_links("execution")`


```{.r}
#| label: tbl-stage4-artifact-map
#| tbl-cap: "Principal frozen output collections and their identities."
br_show("artifacts")
```

`r br_source_links("artifacts")`


```{.r}
#| label: tbl-stage4-environment
#| tbl-cap: "Consequential software versions."
br_show("environment")
```

`r br_source_links("environment")`

The result-producing implementation used R 4.6.1, TMB 1.9.21 and C++17. Reports use Quarto 1.9.37 and the accepted project library. The display code reads aggregate CSVs; it does not load participant model frames, fit models, predict, calculate intervals or adjust p-values. The four main figures use the current complete model outputs, while the exploratory raincloud is exact reuse.

## Interpretation limits {#sec-limits}

- Results concern valid observed minutes and cannot recover missing exposure.
- Sleep describes the bedside measurement, not eye-level or whole-bedroom exposure.
- Site estimates belong to one pooled observational model and are not independent replications.
- Pre-sleep's coverage sensitivity and unresolved temporal dependence qualify the main analysis.
- Failed or near-boundary sensitivities remain visible and cannot be treated as successful checks.
- Exploratory participant means are monitoring-period summaries, not stable traits. Day-level association claims remain withheld.
- Neither the profiles nor the models support causal, ranking or participant-tertile claims.

Return to the [integrated results report](13_cross_state_association_results_amendment.html#sec-brown-main-results) for the findings.
