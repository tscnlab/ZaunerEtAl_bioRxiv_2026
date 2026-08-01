# H02 worker handoff: final authoritative analysis

Prepared: 2026-08-01
Scope: H02 only
Primary placement: near eye
Complementary placement: chest
Status: **analysis accepted; production inference, diagnostics, reader-facing
results and preparation/provenance pages, final display and terminology rules,
and both H02-only renders complete; no unresolved H02 scientific gate**

This document supersedes every earlier H02 worker-handoff draft or addendum.
It describes only the coordinator-approved final input bundle and the outputs
fitted to that bundle.

## Scope and independence

H02 was audited and implemented independently of H01 results. No H01 fitted
estimate, p-value, outcome-selection result, or model object was used.

Changes are confined to the authorized H02 notebook, scripts, tests,
H02-specific artifacts, H02 audit files, and this handoff. Shared preparation,
central ledgers, shared Quarto configuration, H11, submission files,
`renv.lock`, and `manuscript/R0_NatMed/` were not edited. No package was
installed or updated. No push, upload, or manuscript edit was made.

## Registered question and final estimands

The preregistered hypothesis was:

> “Within-participant variance in hourly melanopic EDI, with participants
> nested in sites, exceeds variance between sites.”

The final analysis addresses that ordering with two explicitly defined,
descriptive estimands:

1. **Integrated fitted-curve variation.** Site variation is the variance among
   fitted site curves across a 48-bin local-clock grid, giving every site the
   same weight. Participant variation is the within-site variance among fitted
   participant curves over the same grid, averaged with every site receiving
   the same weight. Participant-day variation applies the same weighting to
   fitted day-intercept contributions. Ratios compare these model-implied
   dispersions in squared
   `log10(melEDI + 0.1 lx)` prediction units. They are not shares of observed
   response variance.
2. **Conditional Shapley/general dominance.** The global time effect is
   retained in every hierarchy-respecting subset model. Site pattern,
   participant pattern, and participant-day shift are allocated their average
   increment in row-weighted in-sample transformed-scale R-squared over every
   admissible entry order. This is fitted-model relevance within this sample,
   not causal importance or cross-validated predictive importance.

## Approved inputs and identities

Coordinator decision `H02-INPUT-001` in
`audit/decisions/h02_shared_input_transition.md` explicitly approved the
following bundle. All six identities were rechecked after the final render and
remain unchanged. The base and temporal verification manifests report `PASS`
and the H02 contract test independently verifies their content.

| Input | SHA-256 |
|---|---|
| `artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds` | `afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5` |
| `artifacts/06_model_data/base/metrics_chest_30_minute_context.rds` | `01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2` |
| `artifacts/12_manifests/base_model_data_artifacts.csv` | `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4` |
| `artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds` | `69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a` |
| `artifacts/06_model_data/temporal_provenance/true_utc_source_bins.rds` | `08d1adfb3e55c93da043b74d07dfade203c34f720c88062fa83eec5ebd1844f9` |
| `artifacts/06_model_data/temporal_provenance/artifact_manifest.csv` | `9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d` |

Additional recovery/sensitivity inputs were:

| Input | SHA-256 |
|---|---|
| `artifacts/06_model_data/scenarios/manuscript_prepared_data/thirty_minute_data.rds` | `813453681cb24ca88cdf5f6b833824649f0e24e9f3bed5af80aad1c4f06fffdc` |
| `data/metrics_separate_glasses.RData` | `f4b8ddfdbd4ee2e577957ed6a89f65a7b44581bba916e786147dcd40c94a234b` |
| `data/metrics_separate_chest.RData` | `f1ab7345966bdaa8705a03745798d99c3d945fe0119f2476a5dd6e9a53f5de2f` |
| `RQ1.qmd` | `ecf2f7f7af569b4d2b3f8404e39690a1924173a02a97aa4db65233950b6f6643` |
| `docs/RQ1.html` | `989a961ebcea5707dc68a9dd3379c7ed914fa0bdf81e7e69100be1d47ce49480` |
| `docs/RQ1_chest.html` | `d7237b3bb89162e3d5554d673c94e2f707b263f729a229c576c660a3c9d38bd6` |

The relevant decision/evidence identities were:

| Record | SHA-256 |
|---|---|
| `audit/decisions/h02_shared_input_transition.md` | `203f1f9e3878393f38fa3681c0dbf647f139557f0b68403387253aaa52079b32` |
| `audit/evidence/preregistration_contract.md` | `117b3d075df5ee8c822fba70b3cc0b7b5240581ab500c14e2880514474ac4225` |
| `audit/hypotheses/H01-H04_migration_map.md` | `6f3735500c672faf236d3e3ec84beb5adef68518b97c38ac90ef925265c07144` |
| `audit/decisions/bootstrap_execution_policy.md` | `8bc2f8d31d23dec94b8735b6b913f6886f89fb07adc9d9d33f345e9c2b81871a` |
| `config/site_display_registry.csv` | `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809` |

## Data construction, support, ordering, and grouping

- Local wall-clock time defines the daily profile; verified true UTC defines
  row order and elapsed-time adjacency.
- A 30-minute outcome is the arithmetic mean melEDI when at least 15 valid
  one-minute values are present. Unsupported, non-wear, out-of-range, and
  otherwise invalid values remain missing rather than being treated as zero.
- Participant and participant-day identifiers are site-prefixed. Every fitted
  frame is unique on site, participant, participant-day, placement, local date,
  and 30-minute wall-clock bin.
- AR(1) sequences reset at every participant-day, after every omitted or
  elapsed-time-discontinuous bin, and on both sides of a non-one-to-one
  fall-back wall-clock outcome. No residual pair crosses those boundaries.
- Near-eye and chest are modelled separately. During sleep they characterize
  the bedside light environment rather than light at the nominal worn
  position.

## Deviations and clarifications

All material deviations are displayed in the reader report. In compact form:

| Aspect | Registered or unspecified | Final analysis |
|---|---|---|
| Placement | Chest primary, near-eye repeat | Near eye primary; chest complementary |
| Outcome epoch | Hourly geometric-mean melEDI | 30-minute arithmetic-mean melEDI |
| Response scale | No zero-handling transform specified | `log10(melEDI + 0.1 lx)` |
| Global time effect | No separate overall smooth | Cyclic global time effect, `k = 12`, centred with every site receiving equal weight |
| Site curve | Site-specific cyclic smooths | Sum-to-zero `sz` deviations, `k = 12`; default noncyclic time marginal |
| Participant hierarchy | Participant-time factor smooth | Participant factor smooth, `k = 10`, plus participant-day random intercept |
| Variance target | Within-participant versus between-site variance | Integrated fitted-curve dispersion plus conditional Shapley allocation |
| Bin support | No 30-minute rule | At least 15 valid minutes per 30-minute bin |
| Whole-day handling | Coverage exclusion; no exact-zero rule | No additional H02 daily-coverage deletion; entirely exact-zero days excluded |
| Clock/DST | Not operationally specified | Wall clock for profiles; true UTC for order; fall-back folds retained |
| Measurement context | Wear/sleep removal described generally | Worn wake values plus bedside sleep environment |
| Operating range | Values above 120,000 lx excluded | melEDI below 100,000 lx after minute aggregation |
| Environment | R 4.5 | R 4.6.1 synchronized project library |

## Selected model and implementation

The exact Wilkinson formula used identically for the current and
manuscript-prepared scenarios is:

```r
response ~
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

`response` is `log10(melEDI + 0.1 lx)`. The global time effect is cyclic.
The `sz` term estimates site departures that sum to zero, so the global time
effect is centred with every site receiving equal weight. The participant
`fs` term estimates person-specific
departures within sites, and the random-intercept term estimates day-specific
level shifts. The default time marginals inside `sz` and `fs` are not forced
to join at midnight; the fully cyclic formulation is retained only as the
declared model-form sensitivity.

Models were fitted with `mgcv::bam()` using fREML. `mgcv::predict.gam(...,
type = "lpmatrix")` and the fitted conditional covariance provide curve and
pointwise interval extraction. `gratia::appraise()` supplies the reader-facing
residual plots, and `gratia::model_concurvity()` wraps
`mgcv::concurvity(full = TRUE)`. `itsadug` was available but was not used for
the final inference because its generic helpers do not encode the audited
participant-day/discontinuity AR boundaries. The boundary-aware residual and
resampling operations are H02 R functions, not `gratia`, `mgcv`, or `itsadug`
bootstrap functions.

The H11 inheritance contract is saved without requiring reinterpretation at
`artifacts/07_models/H02/selected_temporal_model_specification.csv`
(SHA-256 `c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f`).
H11 itself was not edited.

## Exact fitted samples

### Primary near eye

| Site | Participants | Participant-days | 30-minute observations | Exact zeros | AR sequences |
|---|---:|---:|---:|---:|---:|
| Borås (SE) | 13 | 78 | 3,619 | 1,101 | 123 |
| Delft (NL) | 13 | 78 | 3,596 | 1,214 | 130 |
| Dortmund (DE) | 18 | 107 | 4,959 | 1,516 | 167 |
| Tübingen (DE) | 26 | 150 | 6,900 | 1,944 | 257 |
| Munich (DE) | 10 | 60 | 2,758 | 659 | 115 |
| Madrid (ES) | 23 | 129 | 6,052 | 2,503 | 173 |
| Izmir (TR) | 17 | 101 | 4,702 | 1,292 | 163 |
| San José (CR) | 6 | 32 | 1,469 | 378 | 60 |
| Kumasi (GH) | 15 | 81 | 3,701 | 1,500 | 170 |
| **All 9 sites** | **141** | **816** | **37,756** | **12,107** | **1,358** |

### Complementary chest

| Site | Participants | Participant-days | 30-minute observations | Exact zeros | AR sequences |
|---|---:|---:|---:|---:|---:|
| Borås (SE) | 16 | 96 | 4,472 | 1,440 | 148 |
| Delft (NL) | 15 | 93 | 4,307 | 1,461 | 146 |
| Dortmund (DE) | 20 | 114 | 5,308 | 1,784 | 171 |
| Munich (DE) | 10 | 60 | 2,757 | 799 | 116 |
| Madrid (ES) | 22 | 123 | 5,783 | 2,420 | 165 |
| Izmir (TR) | 17 | 102 | 4,749 | 1,311 | 165 |
| San José (CR) | 39 | 230 | 10,628 | 3,158 | 418 |
| Kumasi (GH) | 15 | 84 | 3,838 | 1,426 | 178 |
| **All 8 sites** | **154** | **902** | **41,842** | **13,799** | **1,507** |

Tübingen is absent from chest because no chest model data are available there.
Reader-facing names, order, and colors follow `DISPLAY-001` exactly.

## Main results and 95% confidence intervals

### Omnibus site-pattern family

The single confirmatory H02 site-pattern comparison gave chi-squared =
474.9313 on 96 degrees of freedom, raw p <0.001 and BH-adjusted p <0.001
(full-precision value for both: 1.606128e-51). Its multiplicity family is
`H02-F1-site-pattern`, contains one test, and uses BH adjustment. Participant
and participant-day reduced-model comparisons are structure diagnostics and
carry no multiplicity claim.

### Integrated fitted-curve variation

| Placement | Quantity | Estimate (95% CI) |
|---|---|---:|
| Near eye | Site-curve variation | 0.1004 (0.0407 to 0.1389) |
| Near eye | Participant-curve variation | 0.1804 (0.1258 to 0.2136) |
| Near eye | Participant-day intercept variation | 0.0195 (0.0098 to 0.0244) |
| Near eye | Participant + day variation | 0.1999 (0.1399 to 0.2300) |
| Near eye | Participant / site | 1.797 (1.157 to 4.332) |
| Near eye | (Participant + day) / site | 1.991 (1.291 to 4.767) |
| Chest | Site-curve variation | 0.1012 (0.0488 to 0.1160) |
| Chest | Participant-curve variation | 0.1484 (0.1000 to 0.1994) |
| Chest | Participant-day intercept variation | 0.0348 (0.0197 to 0.0391) |
| Chest | Participant + day variation | 0.1832 (0.1265 to 0.2276) |
| Chest | Participant / site | 1.465 (0.973 to 3.179) |
| Chest | (Participant + day) / site | 1.809 (1.219 to 3.736) |

Each interval uses 2,000 percentile hierarchical cluster resamples of sites,
participants within sampled sites, and participant-days within sampled
participants. Fitted contributions are held fixed. Seeds are 20302601 for the
main near-eye run and 20296827 for the main chest run. The combined
participant-plus-day ordering is retained at both placements; the
participant-only chest interval includes one.

### Conditional Shapley/general dominance

| Placement | Component | Allocated R-squared (95% CI) | Share of full-model R-squared (95% CI) |
|---|---|---:|---:|
| Near eye | Global time effect | 0.6113 (0.5503 to 0.6566) | 78.9% (73.6% to 82.6%) |
| Near eye | Site pattern | 0.0156 (0.0069 to 0.0264) | 2.0% (0.9% to 3.5%) |
| Near eye | Participant pattern | 0.1001 (0.0793 to 0.1252) | 12.9% (10.1% to 16.4%) |
| Near eye | Participant-day shift | 0.0482 (0.0352 to 0.0643) | 6.2% (4.4% to 8.6%) |
| Chest | Global time effect | 0.5827 (0.5235 to 0.6286) | 79.1% (73.6% to 82.8%) |
| Chest | Site pattern | 0.0154 (0.0082 to 0.0237) | 2.1% (1.1% to 3.3%) |
| Chest | Participant pattern | 0.0875 (0.0710 to 0.1105) | 11.9% (9.5% to 15.3%) |
| Chest | Participant-day shift | 0.0513 (0.0396 to 0.0674) | 7.0% (5.3% to 9.4%) |

The full-model in-sample R-squared was 0.7753 (95% CI 0.7394 to
0.8039) near eye and 0.7369 (0.7034 to 0.7663) at chest. The relative
comparisons were:

| Placement | Comparison | Estimate (95% CI) |
|---|---|---:|
| Near eye | Participant pattern / site pattern | 6.410 (3.846 to 15.136) |
| Near eye | (Participant pattern + day shift) / site pattern | 9.494 (5.767 to 21.810) |
| Near eye | Participant share of site + participant allocation | 86.5% (79.4% to 93.8%) |
| Near eye | Participant + day share beyond global time effect | 90.5% (85.2% to 95.6%) |
| Chest | Participant pattern / site pattern | 5.687 (3.723 to 10.678) |
| Chest | (Participant pattern + day shift) / site pattern | 9.023 (6.006 to 17.027) |
| Chest | Participant share of site + participant allocation | 85.0% (78.8% to 91.4%) |
| Chest | Participant + day share beyond global time effect | 90.0% (85.7% to 94.5%) |

Both placements completed 2,000/2,000 finite hierarchical resamples with zero
failures. Subset models and fitted predictions were held fixed. Seeds were
20302631 near eye and 20296857 chest. The defensible relevance wording is:
**within this sample and selected model, participant-specific daily patterns
received about 6.4 times the in-sample model-fit allocation of site-specific
patterns; participant patterns plus participant-day shifts received about 9.5
times the site allocation.** This must not be described as observed variance
explained or causal importance.

### Time-resolved curves

Figure 1 uses pointwise conditional 95% intervals from the fitted linear
predictor and conditional covariance. Smoothing parameters are held fixed.
Red segments mark individual 30-minute site/global-time-effect intervals that exclude
one; they are not simultaneous or familywise-controlled discoveries and have
no separate multiplicity family. Exact windows and factors are in
`artifacts/09_tables/H02/figure4_pointwise_conditional_windows.csv`.

Both placements use the same A-D builder. Panel A labels the total as
`n = 816 participant-days (d)` or `n = 902 participant-days (d)`. Panel B is
the site-curve panel; each facet labels its fitted site sample at approximately
15:00 and 0.28 lx, as `n = xxx d`. Panel C contains participant curves.
The standalone PNG/PDF figures and the H02 results HTML were regenerated on
2026-08-01 from the stored accepted model objects. This was display-only: no
model was refitted and no bootstrap or Shapley analysis was rerun.

## Diagnostics and influence

| Check | Near eye | Chest | Assessment |
|---|---:|---:|---|
| Convergence/rank | converged; 2,333/2,333 | converged; 2,537/2,537 | full coefficient rank |
| AR parameter | 0.6227 | 0.6065 | estimated from boundary-aware preliminary residuals |
| Overall lag-1 residual correlation, before to after | 0.6227 to 0.0826 | 0.6065 to 0.0698 | major reduction |
| Participant-day median lag-1 | 0.0971 | 0.0880 | some positive dependence remains |
| Participant-day 95th-percentile lag-1 | 0.4576 | 0.4448 | a subset of days remains strongly correlated |
| AR-standardized RMSE | 0.7016 | 0.7746 | transformed response scale |
| Correlation of absolute residual with fitted | 0.2022 | 0.2244 | modest fitted-dependent spread |
| Maximum absolute standardized residual | 5.69 | 5.44 | tail departures remain |
| Common-time k-index (p) | 0.999 (0.435) | 0.982 (0.130) | no evidence available basis was too small |
| Participant k-index (p) | 0.999 (0.455) | 0.982 (0.115) | no evidence available basis was too small |
| Maximum absolute sum of `sz` deviations | 2.57e-15 | 1.17e-15 | sum-to-zero constraint verified |
| Observed concurvity, common/site | 0.999/0.992 | 1.000/0.989 | high overlap; interpret full curves and contrasts |

The QQ plots show an S-shaped departure from Gaussian residuals; observed vs
fitted plots show the exact-zero lower boundary; and residual spread increases
modestly with fitted exposure. The model is adequate for conditional mean
curves and complete contrasts, but is not a perfect generative model for the
zero-heavy response. Isolated smooth coefficients should not be interpreted
as independent effects.

Primary near-eye conditional deletion diagnostics held the fitted model fixed.
Deleting any one participant changed the two dispersion ratios by at most
6.9%; deleting any one site changed them by at most 34.0% (Kumasi was the
largest site deletion), and every deletion retained both ratios above one.
These are influence diagnostics, not refitted sensitivity intervals.

### Diagnostic-only global-time basis comparison

At the author's request, the accepted cyclic global time smooth was compared
with a default thin-plate global smooth. The only formula change was
`s(time_hour, bs = "cc", k = 12)` to
`s(time_hour, bs = "tp", k = 12)`. Both placements retained their exact
accepted samples, `sz` site term, participant factor smooth, participant-day
intercept, transformation, and boundary-aware rho algorithm. This was a
residual-diagnostic sensitivity only: no bootstrap, simulation, variation
summary, Shapley analysis, or inferential claim was run.

| Diagnostic | Near eye: cyclic | Near eye: non-cyclic | Chest: cyclic | Chest: non-cyclic |
|---|---:|---:|---:|---:|
| AIC | 64,819.642 | 64,825.630 | 81,193.894 | 81,198.625 |
| Response-residual RMSE | 0.728658 | 0.728661 | 0.805071 | 0.805069 |
| AR-standardized RMSE | 0.701627 | 0.701636 | 0.774633 | 0.774623 |
| Correlation, absolute residual with fitted | 0.202169 | 0.201842 | 0.224362 | 0.224198 |
| Normal-QQ correlation | 0.961114 | 0.961171 | 0.965973 | 0.966033 |
| Boundary-aware overall lag-1 | 0.082576 | 0.082604 | 0.069829 | 0.069820 |
| Participant-day median lag-1 | 0.097079 | 0.097123 | 0.087999 | 0.088279 |
| Participant-day 95th-percentile lag-1 | 0.457639 | 0.455531 | 0.444761 | 0.446157 |
| Global-curve 24:00/00:00 ratio | 1.000000 | 1.006607 | 1.000000 | 1.058287 |

Residual differences were negligible and inconsistent in direction. The
non-cyclic fit had higher AIC by 5.988 near eye and 4.732 at chest and allowed
a midnight value mismatch, especially at chest. The cyclic global smooth is
therefore retained: it gives the scientifically appropriate 24-hour
continuity without a detectable residual penalty. Preliminary plus final fit
time was 126.6 seconds near eye and 170.3 seconds chest; zero resamples were
run. The accepted primary models and H11 inheritance specification were not
changed.

## Sensitivity classification

| Scenario | Exact sample | Participant/site (95% CI) | (Participant + day)/site (95% CI) | Classification |
|---|---|---:|---:|---|
| Primary near eye | 141 participants; 816 days; 37,756 observations | 1.797 (1.157 to 4.332) | 1.991 (1.291 to 4.767) | reference |
| Gap-timing-unaware dataset, identical `sz` implementation | 141; 809; 37,603 | 1.705 (1.068 to 4.029) | 1.917 (1.201 to 4.489) | stable; all six variation summaries stable |
| Fully cyclic site/participant deviations | same primary sample | 1.730 (1.116 to 3.881) | 1.889 (1.212 to 4.131) | stable model-form sensitivity |
| Placement-matched near eye | 112; 643; 29,786 | 1.329 (0.885 to 2.831) | 1.545 (1.017 to 3.302) | combined ordering retained; participant-only uncertain |
| Complementary chest | 154; 902; 41,842 | 1.465 (0.973 to 3.179) | 1.809 (1.219 to 3.736) | combined ordering retained; participant-only uncertain |
| Placement-matched chest | 112; 643; 29,786 | 1.409 (0.851 to 3.247) | 1.753 (1.092 to 3.908) | combined ordering retained; participant-only uncertain |

The placement-matched sensitivity is the former “common-bin” analysis. It
retains only site, participant, local-date, and 30-minute wall-clock keys for
which both near-eye and chest values are admissible and finite, then fits the
two placements separately on those identical keys. It tests whether the
placement comparison changes merely because the two sensors otherwise have
different available observations; it is not a different binning method.

The strongest stable conclusion is therefore that participant-specific
patterns **together with participant-day shifts** are more dispersed than
site patterns. The participant-pattern-only contrast is less stable outside
the complete near-eye sample.

## Comparison with the submitted implementation and results

The submitted near-eye implementation fitted 37,603 observations from 141
participants, 809 participant-days, and 9 sites; the final analysis has seven
more days and 153 more observations. Submitted chest fitted 41,664 observations
from 154 participants, 894 participant-days, and 8 sites; the final analysis
has eight more days and 178 more observations.

The submitted code started AR sequences only at the first retained row within
each participant; used a midpoint offset `+ 0.25`; added a day/night smooth
described as photoperiod; compared separately fREML-fitted candidates; and
reported variances of isolated term predictions divided by their sum. Those
isolated term shares omit covariance and are not observed variance explained.

The submitted participant-plus-day/site isolated-term ratios were 2.2957 near
eye and 1.8805 chest. The final fitted-curve dispersion ratios are 1.9911 and
1.8090, respectively, but these numbers do not share an estimand and should be
compared only qualitatively. Both retain the combined participant-level > site
ordering. The conditional Shapley ratios (9.494 and 9.023) are a third,
explicitly fitted-model allocation estimand and have no submitted analogue.

The final selected-model AIC values are 64,819.64 near eye and 81,193.89
chest, versus submitted values 64,952.13 and 81,644.58. They are not directly
comparable because the data, AR boundaries, response construction, and model
structure changed.

## Reader-facing preparation page and website placement

The reader-facing preparation/provenance source is
`audit/hypotheses/H02/H02_analysis_preparation.qmd`. It is a companion to the
H02 results report and follows the verified source data through model-frame
construction, model specification, temporal-boundary handling, fitting,
diagnostics, uncertainty, sensitivity analyses, figures, and manifests. A
Mermaid diagram provides the full data-to-result chain. Short `gt` tables and
four descriptive plots expose exact samples, site-specific support, model
settings, stored fit summaries, AR-boundary checks, diagnostic sources, and
the executable-script map.

The final reader revision removes references to internal step numbers,
coordinator tasks, approvals, and worker roles from the page. Its opening
callout is an informational note. The transformed-response figure now reports
the discrete exact-zero mass separately—12,107/37,756 near-eye observations
(32.1%) and 13,799/41,842 chest observations (33.0%)—and scales the histogram
to the positive observations. Exact-zero rows remain in both fitted models;
only the descriptive display changed. The exact positive plot input and zero
summary are stored as paired CSV source data under
`artifacts/11_source_data/H02/`.
The website-output `.qmd` copy is byte-identical to the authoring source, and
the preparation-report test now enforces that identity.

The preparation page has a strict execution boundary. Rendering validates the
pinned input hashes and computes only descriptive summaries of the two
H02-specific primary model frames. It does not fit a GAM, estimate rho,
predict curves, rerun a bootstrap, or recompute Shapley allocations. Every
externally produced scientific output is named and linked to its producing
script and stage manifest.

The results and preparation pages contain reciprocal `.html` links. The verified
website-path render is
`_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`.
Coordinator-owned website integration is complete. Under the `nathealth`
profile, the preparation source follows the H02 result
source immediately in the render list, and the dedicated Nature Health
sidebar lists “H02 results” immediately followed by “H02 preparation and
provenance.” Both pages contain that sidebar, breadcrumbs, reciprocal links,
and previous/next navigation; neither contains the inherited public-site
sidebar. The preparation page uses shared website assets rather than a
single-file embedded resource bundle. The current coordinator-owned
`_quarto-nathealth.yml` SHA-256 consumed by the final H02 provenance refresh is
`516ac36aee8bce6d29fc2c7df91a1e41d0d2bb078256be49b695c7622408c8e7`.
The H02 source is the documented exemplar for analogous preparation pages in
later hypothesis work.

## Runtime, environment, code, and commands

Scientific calculations used R 4.6.1 with the activated project library.
Consequential versions were mgcv 1.9-4, gratia 0.11.2, itsadug 2.5, gt 1.3.0,
and Quarto 1.9.37. The synchronized `renv.lock` SHA-256 is
`3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.
The timeout-controlled environment check passed.

Principal commands, each run from the repository root with the project
R 4.6.1 library, were:

```text
Rscript --vanilla scripts/hypotheses/H02/audit_submitted_h02.R
Rscript --vanilla scripts/hypotheses/H02/build_h02_model_data.R
Rscript --vanilla scripts/hypotheses/H02/run_h02_analysis.R
Rscript --vanilla scripts/hypotheses/H02/run_h02_formula_sensitivity.R
Rscript --vanilla scripts/hypotheses/H02/run_h02_temporal_diagnostics.R

H02_DOMINANCE_EXECUTION_MODE=production \
H02_DOMINANCE_FULL_APPROVED=COMPUTE-001-approved \
Rscript --vanilla scripts/hypotheses/H02/run_h02_dominance_analysis.R

Rscript --vanilla scripts/hypotheses/H02/build_h02_figure4_replication.R
Rscript --vanilla scripts/hypotheses/H02/build_h02_reader_diagnostics.R
Rscript --vanilla scripts/hypotheses/H02/build_h02_paired_placement_display.R
Rscript --vanilla scripts/hypotheses/H02/run_h02_global_time_diagnostic_sensitivity.R
R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> \
quarto --profile nathealth render notebooks/hypotheses/H02.qmd --to html
R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> \
quarto --profile nathealth render audit/hypotheses/H02/H02_analysis_preparation.qmd --to html
Rscript --vanilla scripts/hypotheses/H02/build_h02_figure_readability_qa.R
Rscript --vanilla scripts/hypotheses/H02/build_h02_preparation_report_manifest.R
Rscript --vanilla scripts/environment/run_renv_status_safe.R <root> 60 true
Rscript --vanilla scripts/hypotheses/H02/build_h02_worker_manifest.R
```

The accepted result-report render completed all 45 report blocks. The revised
preparation-page render completed all 51 blocks. Both read accepted fits and
production bootstrap outputs; neither refits models nor reruns resampling.

All ten H02 tests passed under fresh R 4.6.1 sessions:

- `test_h02_contract.R`;
- `test_h02_dominance.R`;
- `test_h02_dominance_fit.R`;
- `test_h02_dominance_pilot.R`;
- `test_h02_figure4_replication.R`;
- `test_h02_figure_readability.R`;
- `test_h02_outputs.R`;
- `test_h02_paired_placement_display.R`;
- `test_h02_reader_report.R`;
- and `test_h02_preparation_report.R`.

## Output identities and provenance

The authoritative non-circular inventory is
`artifacts/12_manifests/H02/H02_worker_output_hashes.csv`. It contains the
path, SHA-256, byte size, artifact class, producer, and R version for **all 192
H02 worker outputs**, excluding only itself and this handoff to prevent
self-reference. Its own SHA-256 is
`0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331`.
The nested H02 preparation-report manifest records 57 identities, including
the final Nature Health profile, rendered source copy, four page-specific plot
assets, the two response-distribution source-data files, and the matched
near-eye/chest curve source data.

Key publication-facing and inferential identities are:

| Output | SHA-256 |
|---|---|
| `_quarto-nathealth.yml` | `516ac36aee8bce6d29fc2c7df91a1e41d0d2bb078256be49b695c7622408c8e7` |
| `notebooks/hypotheses/H02.qmd` | `d2cc99a30ee9e6c8ece97e55bee05f4ff6d930fd10557a2407ff58f5335aaac1` |
| `_build/nathealth/notebooks/hypotheses/H02.html` | `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164` |
| `audit/hypotheses/H02/H02_analysis_preparation.qmd` | `52a1b3b85c4a375c44c0a2a83f542ea2663c7d233a6de18ed689cb2b7a0be557` |
| `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.qmd` | `52a1b3b85c4a375c44c0a2a83f542ea2663c7d233a6de18ed689cb2b7a0be557` |
| `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html` | `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa` |
| `artifacts/11_source_data/H02/preparation_response_distribution_positive_observations.csv` | `22dff3af0f213b3ceaed0d5ca827da4184b662ff7d0366d592b6598b56e96842` |
| `artifacts/11_source_data/H02/preparation_response_distribution_exact_zero_summary.csv` | `f2cc126a168bf8d6db3c5b13b3c6fea83030b23e7fdebff882bea1eb390f31db` |
| `artifacts/11_source_data/H02/paired_placement_site_curves.csv` | `3bc65cdd98bb8e71c5bc6f586e0aab966a929cc6b47df25b8e6eaf1376f5c5c8` |
| `artifacts/12_manifests/H02/H02_paired_placement_display_manifest.csv` | `fffcffcecc79196a11515ff74c56b8293fbea9ee2368b4b71b6c39cddeb65753` |
| `artifacts/12_manifests/H02/H02_figure_readability_qa.csv` | `f0898eeab659591109954f453f78ef5f5b783415cce015c79c1ce17c72a43814` |
| `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv` | `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7` |
| `artifacts/10_figures/H02/figure4_exact_layout_replication.png` | `2d31f38a169659b37a16c44b9845605186709e4dc7734a8f97342408711f9ac2` |
| `artifacts/10_figures/H02/figure4_exact_layout_replication.pdf` | `daccad7889e79d11980e0543f154421d3d238c0b2c3e34ddae42de3b31106ba4` |
| `artifacts/10_figures/H02/figure4_exact_layout_replication_chest.png` | `a82659874f9246b27e8cc25733b7a8236bbf8327d67f6378f868cc8f9c2f2cb1` |
| `artifacts/10_figures/H02/figure4_exact_layout_replication_chest.pdf` | `80b4553e3751d2b302ca9187bcba480de1c5261a34c492437dd4c69fd28de53d` |
| `artifacts/10_figures/H02/model_diagnostics_near_eye.png` | `63feccccbde19e1804fe1405260e0a2015344837549046015e16374e8d5df05c` |
| `artifacts/10_figures/H02/model_diagnostics_chest.png` | `10e8d1b1fce74474987b5f8b699260c85a4dba28126da2164fb9442e409424e8` |
| `artifacts/09_tables/H02/variation_summary.csv` | `a07296c2e64e15a0217b9efc21b83acd578574f5b456a79eb2401382b0b4d3b0` |
| `artifacts/09_tables/H02/dominance_summary.csv` | `c50589ee53541845cee1a104ae4aabb0bb45296a94e3ab7547fd1142ded4e84f` |
| `artifacts/09_tables/H02/dominance_comparison_summary.csv` | `7240b7ab29818b085375a10c02bf53e49ad71203d6e2feb2385c590ca27e36fe` |
| `artifacts/09_tables/H02/figure4_pointwise_conditional_windows.csv` | `ada1406a99af8edacbc9662c7a4616811bada78cb2a4cc5e61e6d9853e5cfa7b` |
| `artifacts/12_manifests/H02/H02_analysis_manifest.csv` | `cba73edc1d4974dd9a86a03513af7491aa62e8b09dbb3606895aa3af551b3804` |
| `artifacts/12_manifests/H02/H02_dominance_manifest.csv` | `fe63aec3b643aa383e4ae68bc7ba71d6a7545f50278907b116c83816e26bf161` |
| `artifacts/12_manifests/H02/figure4_replication_manifest.csv` | `bc393421b09347bd594928fb4893b538bcf55a11443cf8bdb02d218056a94d73` |
| `artifacts/12_manifests/H02/H02_reader_diagnostics_manifest.csv` | `493762b324d6f7e468ed78f91a30430cee58b9b3762cf7c870ccf7c8faccca0a` |
| `artifacts/07_models/H02/selected_temporal_model_specification.csv` | `c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f` |
| `artifacts/09_tables/H02/global_time_basis_model_comparison.csv` | `a53fdc6fa7fe6e4374d4cb49e6e45a2638964be0739598b8097326d3fba51824` |
| `artifacts/08_diagnostics/H02/global_time_basis_residual_metrics.csv` | `c53e1e78da391240701727a0d56a2694545c3cf52c1bbdb4dc80a055b463ae92` |
| `artifacts/12_manifests/H02/H02_global_time_basis_diagnostic_manifest.csv` | `1987dcfae933a15b6da56c54d09e0da79fc0418ec8fa907d7dc729896ceace23` |

Claim provenance is therefore:

- exact samples: `artifacts/06_model_data/H02/sample_counts.csv` and
  `H02_model_data_manifest.csv`;
- omnibus test/model structure: `model_structure_comparisons.csv`;
- fitted dispersion: `variation_summary.csv` and fitted-contribution RDS
  files;
- relative fitted-model relevance: `dominance_summary.csv`,
  `dominance_comparison_summary.csv`, the two production prediction RDS
  files, and `H02_dominance_manifest.csv`;
- time-resolved claims: the two Figure 1 source RDS files and
  `figure4_pointwise_conditional_windows.csv`;
- matched-placement display: `paired_placement_site_curves.csv` and
  `H02_paired_placement_display_manifest.csv`;
- diagnostic claims: the H02 diagnostic CSVs, diagnostic source RDS files,
  and `H02_reader_diagnostics_manifest.csv`;
- final-size visual QA: `H02_figure_readability_qa.csv`;
- global-basis diagnostic sensitivity: `global_time_basis_model_comparison.csv`,
  the `global_time_basis_*` diagnostic CSVs, and
  `H02_global_time_basis_diagnostic_manifest.csv`;
- reader-facing preparation chain:
  `audit/hypotheses/H02/H02_analysis_preparation.qmd`, its website-path HTML,
  and `H02_preparation_report_manifest.csv`;
- H11 inheritance: `selected_temporal_model_specification.csv`.

## Claim implications

1. The omnibus evidence supports site-specific daily melEDI patterns.
2. The preregistered participant-over-site ordering is most robust when
   participant-specific pattern and participant-day shift are considered
   together.
3. Participant-only fitted-curve dispersion is above site dispersion in the
   primary near-eye analysis, but its chest and placement-matched intervals
   include one.
4. Within the selected in-sample model, participant-pattern relevance is much
   larger than site-pattern relevance; use the conditional Shapley wording,
   not “observed variance explained.”
5. Pointwise red segments describe local fitted-curve departures only and are
   not simultaneous discoveries.

## Unresolved gates and proposed coordinator-ledger entries

There is **no unresolved H02 scientific or compute gate**. The selected
pointwise figure does not require a model-refitting simultaneous-band
bootstrap. A future request for such a new computation would be a separate
task under `COMPUTE-001`, not an outstanding requirement of this analysis.

There is **no unresolved H02 publication gate**. Coordinator-owned website
integration and both final website renders are complete. The H02 worker did
not edit shared Quarto configuration; it consumed and recorded the final
coordinator-owned profile identity when rebuilding H02 manifests.

Proposed coordinator entries:

- **Decision:** accept `h02_nh_v2_sz` as the H02 primary model and the fully
  cyclic formulation as model-form sensitivity; authorize H11 to consume the
  frozen specification artifact without reinterpretation.
- **Finding:** the combined participant-pattern plus participant-day ordering
  is stable across preparation, model form, placement, and placement-matched
  checks; participant-only ordering is less stable.
- **Finding:** AR correction substantially reduces average temporal
  dependence, while zero-bound residual structure, some day-level dependence,
  and high common/site concurvity remain.
- **Finding:** changing only the global time basis from cyclic cubic to a
  default thin-plate smooth does not materially improve residual diagnostics,
  raises AIC, and weakens midnight continuity; retain the cyclic global term.
- **Result:** record the exact primary and chest samples, omnibus result,
  fitted-dispersion estimates, and production conditional Shapley estimates
  above.
- **Deviation/change log:** record the 30-minute arithmetic-mean outcome,
  zero-aware transform, near-eye priority, `sz` site deviations,
  participant-day intercept, audited AR boundaries, pointwise conditional
  Figure 1 intervals, approximately 15:00 `n = xxx d` facet labels, and the B/C panel
  tag correction; use “global time effect” for the intercept plus global
  cyclic time smooth in reader-facing text.
- **Reader documentation:** record that the H02
  preparation/provenance page is published beside the H02 results report,
  and reuse its bounded, non-refitting structure as the template for later
  hypothesis-specific preparation pages.
- **Result comparison:** retain only qualitative comparison with submitted
  isolated-term ratios; the estimands are not numerically interchangeable.
- **Claim provenance:** apply the artifact mappings and complete 192-file hash
  inventory above.

## Applied display and terminology rules

This authorized report touchpoint applies `REPORT-008` through `REPORT-011`
without changing any fitted model or inferential artifact.

- **REPORT-008:** the results report and preparation table use the shared
  `p_value_display.R` formatter. Displayed p-values have a leading zero and
  three decimal places, or `<0.001` only for full-precision values below that
  threshold. The BH-adjusted omnibus result is bold under the explicitly
  labelled 0.05 rule; diagnostic p-values are not bold. Full precision remains
  in scientific CSV artifacts.
- **REPORT-009:** a direct placement section now overlays the separately
  fitted near-eye and chest site curves for the exactly matched 112
  participants, 643 participant-days, 29,786 observations, and eight sites.
  A scalar identity scatterplot was rejected because it would discard H02's
  temporal estimand. The component pointwise intervals are not a confidence
  interval for the between-placement difference, and visual concordance is
  not described as equivalence. The 768 plotted rows and six-file provenance
  manifest are recorded under `artifacts/11_source_data/H02/` and
  `artifacts/12_manifests/H02/`.
- **REPORT-010:** both reader-facing pages define and consistently use
  **gap-timing-unaware dataset**. The first definition states the 50%-per-hour
  and 80%-per-day coverage rules and explains that only the timing of remaining
  gaps is omitted from additional metric-specific adjustment.
- **REPORT-011:** all nine reader-facing figures were inspected as
  1024-pixel-wide final-scale previews and cross-checked against their HTML
  widths and intrinsic raster dimensions. The preparation heatmap's colour-bar
  title was moved above a widened bar so its six percentage labels no longer
  overlap. No other figure required repair. All nine passed checks for
  clipping, overlap, text distortion, wrapping, readable important text,
  proportionate data regions, distinguishable marks, captions, and alt text.
  The audit is `H02_figure_readability_qa.csv`; the repair and review used
  rendered artifacts only and reran no model, bootstrap, simulation, or
  Shapley computation.
