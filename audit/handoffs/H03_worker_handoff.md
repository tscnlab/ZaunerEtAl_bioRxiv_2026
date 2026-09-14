# H03 worker handoff

- Date: 2026-08-10
- Branch: `rewrite/NH`
- Current gate: **H03-owned Stage 4 complete; shared Quarto integration pending**
- Primary inferential model: approved population-mean quasi-Tweedie GLM
- Exploratory temporal model: approved raw-outcome Tweedie GAMM
- Production resampling or simulation: none
- Stage 4 preparation companion: created, rendered, and H03-verified; integrated
  profile verification awaits the coordinator-owned adjacency entries

## Author decisions now implemented

The author approved progression to Stage 3 and made the following final
architecture and reporting choices:

- retain the accepted population-mean quasi-Tweedie GLM for preregistered
  inference;
- retain the additive model only for the preregistered category omnibus, while
  using the accepted category-by-site heterogeneity model for all descriptive
  means, ratios, intervals, and site summaries;
- use the adjusted raw-outcome time-of-day GAMM, which produces conditional
  arithmetic-mean melEDI curves, for clearly labelled exploratory context;
- show equal-sized, lightly reduced filled and open support markers in the
  temporal figures; and
- add a bounded exploratory replacement of categorical site by
  category-specific linear absolute-latitude slopes.

On 2026-08-10 the author approved Stage 3 after two final display changes:

- Figure 2 now uses one common symlog axis for all seven facets, covering the
  0, 1, 10, 100, and 1,000 lx breaks and the Borås outdoor-daylight maximum;
  significant site points use the same site colour for outline and fill.
- Figure 8 uses each light-source category colour for both outline and fill of
  BH-labelled points; non-labelled points remain open in the same outline
  colour.

The refreshed Stage 3 render and latest 337-file H03 manifest pass the focused
R 4.6.1 reader-report test.

The rejected no-time GAMM, reduced Tweedie GLMM pilot, inherited
log-transformed temporal display, and construction history are not included in
the standalone reader report. The site-heterogeneity companion remains
separate from the primary omnibus.

No shared preparation code, central ledger, shared Quarto configuration,
manuscript file, bibliography, `renv.lock`, or non-H03 file was modified.

## Stage 3 reader report

The standalone reader-facing report is:

- source: `notebooks/hypotheses/H03.qmd`;
- render: `_build/nathealth/notebooks/hypotheses/H03.html`.

It contains an “Answer in brief” callout, the exact fitted samples and category
support, visible model formulas, site-standardized estimates and 95%
confidence intervals, REPORT-008 p-values, the primary and site-heterogeneity
tests, the recognizable overall-plus-site-deviation table architecture,
diagnostic tables and figures, predefined sensitivities, a common-sample
near-eye/chest comparison, the approved exploratory time-of-day context, and
the exploratory latitude replacement. The Answer in brief lists all seven
near-eye category means and ratios and the six largest supported site
deviations. Near eye is primary and chest complementary. The report contains
no V0, workflow-stage, pilot, or construction-history language.

All linked CSVs and figures are copied into the bounded Nature Health render.
Eight figures have non-empty descriptive alt text. Reader-facing melEDI plots
use `LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)` for display only;
their source CSVs retain untransformed melEDI.

## Primary model and reference system

The exact primary formula is:

```r
geo_medi_1h ~ site + light_source
```

It is fitted with `stats::glm()` and
`statmod::tweedie(var.power = 1.539919, link.power = 0)`. Indoor electric
light is the category reference. Participant-clustered HC1 covariance and
finite-cluster *t*/*F* reference distributions account for repeated hours and
days without claiming to remove serial correlation.

Cross-site estimates are **site-standardized**: every included site receives
weight `1/S` on the fitted log-mean scale, followed by one back-transformation.
The absolute estimate is therefore the geometric mean of fitted site-specific
expected values, not an observation-frequency-weighted mean or a fictional
average site.

The exact fitted samples are:

| Placement | Participants | Participant-days | Participant-hours | Sites | Exact-zero hours |
|---|---:|---:|---:|---:|---:|
| Near eye, primary | 140 | 801 | 17,935 | 9 | 4,977 |
| Chest, complementary | 151 | 880 | 19,512 | 8 | 5,409 |

The seven-category omnibus results are:

| Placement | F | Numerator df | Denominator df | p-value |
|---|---:|---:|---:|---:|
| Near eye | 97.540 | 6 | 139 | <0.001 |
| Chest | 82.208 | 6 | 150 | <0.001 |

The additive model's site-standardized indoor-electric estimate is 88.9 lx.
Because supported category-by-site heterogeneity makes that common-effect
mean structure descriptively restrictive, it is not used for result
summaries. The accepted interaction model gives the following near-eye
site-standardized means and ratios to indoor electric:

| Category | Expected melEDI, lx (95% CI) | Ratio to indoor electric (95% CI) |
|---|---:|---:|
| Indoor electric | 85.1 (71.6–101.1) | 1.000 (reference) |
| Outdoor electric | 9.4 (6.9–12.8) | 0.110 (0.078–0.156) |
| Indoor daylight | 198.8 (169.2–233.4) | 2.335 (1.877–2.905) |
| Outdoor daylight | 959.6 (786.8–1,170.2) | 11.274 (8.709–14.595) |
| Emissive display | 23.8 (17.4–32.5) | 0.280 (0.197–0.398) |
| Sleep darkness | 2.2 (1.5–3.3) | 0.026 (0.018–0.039) |
| External light during sleep | 11.2 (8.1–15.5) | 0.131 (0.091–0.189) |

The 88.9 versus 85.1 lx difference is not a sample or outcome change. The
additive model pools one common category contrast across all hours and sites;
the interaction model estimates each site-category cell and then gives sites
equal weight on the fitted log-mean scale.

These are observational associations in one-hour melEDI, not causal,
health-outcome, or placement-equivalence estimates.

## Site heterogeneity and fixed-effect R²

The results-blind full heterogeneity gate passed, so the five-category
fallback was not used. Near eye uses:

```r
geo_medi_1h ~ site * light_source
```

Chest has one structurally absent cell and uses the rank-complete equivalent:

```r
geo_medi_1h ~ 0 + site_source_cell
```

Near eye is rank 63/63 with 48 interaction restrictions; chest is rank 55/55
with 41 restrictions. Both participant-robust heterogeneity tests have
p<0.001. Unsupported site-category cells remain explicitly labelled; no
unplanned site-specific p-values were added. The figure identifies the
predeclared BH-significant site deviations around a dashed site-standardized
category mean.

The combined near-eye table now uses the submitted site colours, highlights
the site-standardized row, and separates it from the site-specific deviation
rows with an empty row. The Answer in brief reports the three largest higher
supported deviations—Tübingen outdoor electric (20.421-fold), Munich external
light during sleep (11.647-fold), and Dortmund external light during sleep
(9.217-fold)—and the three largest lower deviations—Kumasi sleep darkness
(0.166-fold), Tübingen emissive display (0.245-fold), and Borås emissive
display (0.306-fold). Each passes the predeclared 53-deviation BH family.

Descriptive fixed-effect R² is calculated from these accepted heterogeneity
models. Near-eye working quasi-deviance R² is 0.522; participant-hour and
participant-balanced squared-error R² values are 0.129 and 0.128. The
interaction partial R² conditional on the additive model is 0.052, 0.018, and
0.019 under these definitions. The hierarchy-respecting near-eye
quasi-deviance allocation assigns 86.3%, 8.7%, and 5.0% of fitted improvement
to category, site, and interaction. These are in-sample point descriptions,
not mixed-model R² values or inferential tests.

## Primary diagnostics, sensitivities, and influence

Both primary GLMs converged without warnings, retained full design rank, and
had finite positive-definite participant-cluster covariances. Residual lag-one
correlations remain 0.478 near eye and 0.615 at chest; clustering protects
coefficient uncertainty but does not whiten residuals. Exact zeros comprise
27.8% of hours, while the working Tweedie relationship implies 85.2% and
94.8%. The working family is therefore used only for its mean and
mean-variance relationship, not as a calibrated zero-probability or
individual-hour prediction model.

No simple zero-inflation term is appropriate because the working Tweedie
already predicts too many zeros; additional structural zeros would move the
fit in the wrong direction. Re-estimating the variance power could change the
working zero fraction but would not guarantee calibration. A direct zero
model would require a substantively different two-part/hurdle analysis, which
was not added during this reporting revision.

The gap-timing-unaware dataset contains 17,616 near-eye and 19,220 chest hours;
all seven category rows are stable at both placements. Paired/common-sample,
boundary-excluded, supported-cell, variance-power, and within/between-
participant checks leave every omnibus decision unchanged. Outdoor electric
remains sparse and can become support-non-estimable in reduced samples.

Twenty-seven deletion refits produce 189 category rows. No category-omnibus
decision changes. The corrected denominator is **146 of 149 estimable
non-reference category ratios** whose full-data ratio lies inside the
deletion-refit interval. The three local chest exceptions concern sleep
darkness after excluding Kumasi, external light during sleep after excluding
Munich, and sleep darkness after excluding one Kumasi participant. Earlier
handoff text stating 173/176 counted the wrong row set and is superseded.

## Approved exploratory time-of-day context

The final reader-facing exploratory formula is:

```r
geo_medi_1h ~
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, light_source, bs = "sz", k = 12) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

The model uses a fixed-power Tweedie response (`p = 1.539919`), log link,
fREML, discrete fitting, and an estimated-then-fixed boundary-aware AR(1)
correction. The global cyclic smooth is the time-of-day reference. Category
and site smooths are sum-to-zero deviations; indoor electric is not the GAMM
reference.

Site, participant, and participant-day terms remain in the fitted model but
are set to zero in displayed global/category curves. Panel A shows conditional
raw-scale arithmetic means, Panel B category-to-global ratios, and Panel C
available participant-hours. Equal-sized 2.0-point filled circles mark
supported observed hours; open circles of the same size mark locally sparse
observed hours (fewer than 20
participant-hours, five participants, or three sites); grey gaps have zero
observations and no curve. The figure uses seven category facets across each
of three one-row panels and includes a 250-lx break.

Final raw-outcome GAMM summaries are:

| Placement | rho | Adjusted R² | Deviance explained | Site-standardized participant-balanced raw-scale R² | Residual lag 1 |
|---|---:|---:|---:|---:|---:|
| Near eye | 0.156 | 0.514 | 0.841 | 0.544 | 0.146 |
| Chest | 0.106 | 0.460 | 0.824 | 0.499 | 0.144 |

Both final fits converge at full rank with positive-definite smoothing-
parameter Hessians and no final warnings. Global smooth edf/k′ values are
9.36/10 and 9.47/10; deterministic k-indices are 0.890 and 0.884. No
permutation k-test was run. Residual spread remains mean-dependent and working
zero fractions (0.465 and 0.508) exceed observed fractions (0.278 and 0.277),
so the analysis remains descriptive.

Natural-log predictor-variance point allocations are 60.4% global time, 24.2%
light-source deviations, 5.2% site deviations, 7.6% participant curves, and
2.5% participant-day shifts near eye. Chest values are 58.3%, 26.4%, 6.5%,
5.7%, and 3.1%. They are descriptive Shapley allocations under
site-standardized participant-balanced weights, without simulation intervals
or causal interpretation.

## Exploratory linear latitude replacement

A separate bounded exploratory analysis replaces categorical site by seven
category-specific linear absolute-latitude slopes:

```r
geo_medi_1h ~ 0 + light_source +
  light_source:absolute_latitude_10deg_centered
```

Latitude is centred at the equal-site mean absolute latitude within placement
(39.2° near eye; 38.1° chest). The model retains the fixed-power quasi-Tweedie
log-mean specification. Because latitude varies only between sites,
coefficient-wise HC1 uncertainty is clustered at site rather than participant;
seven slopes form one BH family within each placement. No joint seven-slope
Wald test is reported because covariance rank is bounded by only nine and
eight site clusters.

Near-eye BH-labelled ratios per 10° farther from the equator are 1.197
(1.081–1.326) for indoor electric, 1.253 (1.131–1.388) for indoor daylight,
1.354 (1.105–1.661) for outdoor daylight, and 1.428 (1.076–1.895) for sleep
darkness. Each remains positive in all nine leave-one-site-out fits. At chest,
only indoor electric retains the BH label, 1.142 (1.061–1.229), and remains
positive in all eight omissions. Both models converge without warnings at
rank 14/14. These are ecological associations across a small number of sites,
not causal latitude effects or evidence that latitude replaces supported
categorical site heterogeneity.

## Stage 3 provenance and QA

New Stage 3 H03-owned files include:

- `scripts/hypotheses/H03/build_h03_stage3_assets.R`;
- `scripts/hypotheses/H03/build_h03_stage3_revision.R`;
- `scripts/hypotheses/H03/build_h03_stage3_manifest.R`;
- `tests/hypotheses/H03/test_h03_stage3_reader_report.R`;
- `artifacts/09_tables/H03/H03_reader_temporal_*.csv`;
- `artifacts/08_diagnostics/H03/H03_reader_temporal_*.csv`;
- `artifacts/10_figures/H03/H03_reader_temporal_*.{png,pdf,svg}`;
- `artifacts/11_source_data/H03/H03_reader_temporal_*.csv`;
- `artifacts/12_manifests/H03/H03_stage3_reader_asset_manifest.csv`;
- `artifacts/12_manifests/H03/H03_stage3_figure_readability_qa.csv`;
- `artifacts/12_manifests/H03/H03_stage3_revision_asset_manifest.csv`;
- `artifacts/12_manifests/H03/H03_stage3_revision_figure_readability_qa.csv`; and
- `artifacts/12_manifests/H03/H03_stage3_artifacts.csv`.

The asset builder reused frozen fitted raw-outcome GAMM objects and did not
refit models, resample observations, or simulate data. It generated 28 temporal
reader assets. The bounded revision builder generated 14 additional
heterogeneity-summary and latitude assets and fitted only the two specified
latitude GLMs plus their finite leave-one-site-out checks; it ran no bootstrap
or simulation. Direct PNG inspection found no clipping, unbounded A4 canvas,
or panel imbalance. The focused R 4.6.1 test verifies scientific values,
formulas, required prose, 13 `gt` tables, eight figures and their alt text, 18
linked source CSVs, copied render dependencies, and every SHA-256 in the Stage
3 inventory. The latest H03-wide Stage 3 manifest contains 337 files after the
Stage 4 companion and its bounded artifacts were added.

The single-document render required Quarto's normal external Sass cache. The
project-wide `renv` startup was bypassed only for rendering by supplying the
existing project library directly; neither shared configuration nor the
library was modified.

## Stage 4 preparation and provenance companion

The H03-owned Stage 4 companion is complete:

- source: `audit/hypotheses/H03/H03_analysis_preparation.qmd`;
- direct bounded render:
  `audit/hypotheses/H03/H03_analysis_preparation.html`;
- temporary website-path copy, pending the coordinator-owned profile render:
  `_build/nathealth/audit/hypotheses/H03/H03_analysis_preparation.html`;
- artifact builder:
  `scripts/hypotheses/H03/build_h03_preparation_artifacts.R`;
- figure-QA builder:
  `scripts/hypotheses/H03/build_h03_preparation_figure_readability_qa.R`;
- manifest builder:
  `scripts/hypotheses/H03/build_h03_preparation_report_manifest.R`; and
- focused test:
  `tests/hypotheses/H03/test_h03_preparation_report.R`.

The page is a bounded provenance reconstruction. Its render reads frozen H03
model frames and precomputed result artifacts but does not fit, predict from,
simulate from, or bootstrap any model. It documents the registered question,
sample construction, outcome, category coding, estimability rules, exact
Wilkinson formulas, reference and site-standardization system, covariance and
multiplicity choices, diagnostics, sensitivities, temporal context, latitude
exploration, and the code-to-output chain. It contains 26 readable `gt` tables
and four empirical descriptive figures with accessible alt text and linked,
untransformed source CSVs. The reader report and preparation companion link to
each other.

The preparation reconstruction independently confirms the frozen primary
frames:

| Placement | Participants | Participant-days | Participant-hours | Sites | Exact-zero hours |
|---|---:|---:|---:|---:|---:|
| Near eye | 140 | 801 | 17,935 | 9 | 4,977 |
| Chest | 151 | 880 | 19,512 | 8 | 5,409 |

There are no duplicated participant-hour keys, missing outcomes or analysis
categories, invalid melEDI values, or hours below the accepted 30-minute
validity threshold. The analysis category is mutually exclusive at the hour
level, while 7,109 near-eye and 8,012 chest hours retain more than one
underlying source flag; the companion explicitly distinguishes those facts.
Across placement-by-site-by-category cells, 101 meet the predeclared support
rule, 17 are observed but sparse, and eight have no observations.

Seven dedicated preparation CSVs contain 2 frame-integrity rows, 2 zero-mass
rows, 80 positive-response-distribution rows, 14 category-support rows, 126
site-category rows, 336 clock-category rows, and 1,681 participant-day rows.
The preparation manifest records 319 files, and the copied website source is
byte-identical to the author source.

The Stage 3 manifest intentionally excludes the Stage 4 preparation manifest,
while the Stage 4 manifest records the Stage 3 manifest. This one-way
dependency prevents the two manifests from recursively invalidating each
other. After rebuilding in that order, both inventories pass full SHA-256
verification.

All four final figures are tightly bounded rather than saved on A4. Original-
resolution inspection found no clipping, overlap, distortion, or panel
imbalance. At a simulated 170-mm display width, essential text remains at
least 7.30 pt and central text at least 8.52 pt. The QA CSV and A4-only proof
are recorded in `artifacts/12_manifests/H03/`, and
`audit/hypotheses/H03/H03_preparation_figure_readability_qa.md` records an
overall PASS.

The focused preparation test completes every H03-owned source, sample,
scientific-content, source-data, HTML, figure, alt-text, caption, manifest, and
readability assertion. It then reaches the shared verifier and stops only at:

```text
The preparation page is not immediately after its result in the render list.
```

This is the expected coordinator-owned profile-adjacency blocker; it is not a
failure of the H03 companion. The H03 worker did not weaken the shared
verification contract or edit `_quarto-nathealth.yml`.

## Proposed central ledger entries

The coordinator owns the central ledgers. Proposed entries only:

| Ledger class | Proposed entry |
|---|---|
| Hypothesis stage gate | H03 Stage 3 standalone report author-approved; H03-owned Stage 4 preparation companion complete and locally verified; final integrated verification awaits the coordinator-owned Quarto render/navigation adjacency entries. |
| Primary inference | Retain the population-mean fixed-power quasi-Tweedie GLM with participant-cluster HC1: near eye F(6,139)=97.540, p<0.001; complementary chest F(6,150)=82.208, p<0.001. |
| Reference decision | Indoor electric is the category reference; cross-site estimates are site-standardized on the fitted log-mean scale and back-transformed once. Retain the additive model only for the preregistered omnibus and use the accepted heterogeneity model for descriptive estimates. |
| Heterogeneity decision | Full seven-category heterogeneity passed; use `site * light_source` near eye and the rank-complete observed-cell equivalent at chest; fallback not invoked. |
| Descriptive reporting | Report interaction-model site-standardized near-eye means and indoor-electric ratios, distinguish the overall row visually, use site colours, and disclose the six largest supported BH-labelled site deviations. |
| Influence correction | Report 146/149 estimable non-reference ratios inside deletion-refit intervals, with three disclosed local chest exceptions; supersede the erroneous 173/176 denominator. |
| Distributional limitation | Primary and temporal working Tweedie zero mass exceeds observed zero mass; interpret both as mean models, not calibrated generative or zero-probability models. |
| Sensitivity | Paired/common-sample, gap-timing-unaware, boundary, support, variance-power, within/between-participant, and deletion checks do not change the omnibus conclusion. |
| Temporal decision | Use the raw-outcome global cyclic plus light-source/site `sz` GAMM as exploratory time-of-day context; display category-to-global ratios, not indoor-electric ratios; keep site/participant/day terms in the fit but exclude them from displayed curves. |
| Temporal diagnostics | Final raw-outcome GAMMs converge at full rank with positive smoothing Hessians; residual lag 1 remains about 0.14 and zero-mass mismatch persists, so no curve-wide inference is made. |
| Fixed-effect R² | Report the defined heterogeneity-model R² summaries and hierarchy-respecting category/site/interaction point allocation; do not call them mixed-model R² or effect tests. |
| Latitude exploration | Report the separate category-specific linear absolute-latitude replacement with site-cluster HC1, seven-slope within-placement BH families, and leave-one-site-out checks; treat results as ecological and non-causal. |
| Reader report | The standalone H03 report has an Answer-in-brief callout, exact samples and intervals, accessible tightly bounded figures with untransformed source CSVs, and no V0/construction-history language. |
| Preparation companion | The bounded H03 preparation/provenance page is complete with frozen-frame sample reconstruction, exact model formulas and specifications, seven source-data CSVs, 26 `gt` tables, four accessible figures, reciprocal result-page links, figure-readability QA, and a 319-file preparation manifest. |
| Compute gate | No production bootstrap, simultaneous-band simulation, allocation simulation, or new heavy computation was run in Stage 3. |

## Shared-change status

The remaining blocker is recorded in
`audit/handoffs/H03_shared_change_request.md`. The coordinator-owned
`_quarto-nathealth.yml` still omits the now-existing H03 preparation source
from both the render list and hypothesis navigation. No shared file was
modified by the H03 worker.

## Required next action

The coordinator must resolve
`audit/handoffs/H03_shared_change_request.md` by placing the H03 preparation
source immediately after H03 results in both the shared render list and
hypothesis navigation. The coordinator should then render the adjacent H03
result/preparation pair with the Nature Health profile and rerun
`tests/hypotheses/H03/test_h03_preparation_report.R`. No further H03-owned
scientific analysis or companion construction is required unless that
integrated render exposes a new issue. Do not modify `_quarto-nathealth.yml`
in this H03 worker task.

## REPORT-014/017 order 34 source synchronization, 2026-08-14

This section supersedes only the earlier handoff's source-navigation,
terminology, endpoint-count, and next-action statements. It does not change
the accepted scientific results. H03 remains scientifically closed under
H03-AUX-001 / CHG-139 and RH-SYNC-H03-001. No stage was reopened.

### Final synchronized sources

| Source | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H03.qmd` | `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41` | 68,198 |
| `audit/hypotheses/H03/H03_analysis_preparation.qmd` | `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131` | 75,638 |

The result keeps 14 tables and eight figures, with
`fig-h03-primary-estimates` and `tbl-h03-primary-results` first. The
companion keeps all previous 26 tables and four figures and adds only
`tbl-h03-prep-participant-random-intercept`, for 27 tables and four figures.
Both QMDs use dynamic source links and `lightbox: true`. No corresponding
HTML was rendered under this order.

The exact result-to-companion link is
`../../audit/hypotheses/H03/H03_analysis_preparation.qmd#sec-h03-prep-participant-random-intercept`.
The companion anchor is
`sec-h03-prep-participant-random-intercept`, and the companion retains its
dynamic links to `../../../notebooks/hypotheses/H03.qmd`.

### Two distinct participant assessments

The predefined within-participant and between-participant sensitivity is a
population-mean quasi-Tweedie augmentation with participant-clustered
covariance. It is not a mixed model, random-intercept model, random-slope
model, or variance-component analysis.

The post-closure auxiliary assessment is a separate descriptive
participant-random-intercept model:
`geo_medi_1h ~ site * light_source + (1 | participant)`. It uses a glmmTMB
Tweedie log-link likelihood with fixed power 1.539919. It contains no
participant-day effect, random light-source slope, or AR(1) term. Its R²,
ICC, and hierarchy-respecting Shapley values are descriptive,
model-dependent, non-causal, uncertainty-unqualified point summaries and do
not replace the population-mean primary model or its multiplicity families.

Controlling auxiliary files:

- decision:
  `audit/decisions/h03_auxiliary_model_assessments_closure.md`, SHA-256
  `85be31f6c105ea2c47a5353a32d4081dcdbc50a0738998f2106c0952c4527827`;
- synchronization record:
  `audit/report_harmonization/h03_postclosure_synchronization_check.md`,
  SHA-256
  `569767a839a34f1dc3e58ea8c5b554da23a56163a2cf48ad90d7a17cd05b1aea`;
- accepted runner:
  `scripts/hypotheses/H03/run_h03_participant_random_intercept_assessment.R`,
  SHA-256
  `662e7ac81b3b67693023acdb196b2187d7058e863294b7b77e0105b8ca456f4c`;
- six-file manifest:
  `artifacts/12_manifests/H03/H03_near_eye_participant_random_intercept_manifest.csv`,
  SHA-256
  `81bab5291ca9f9aa24a39cae991857b8f5b39046090da2e4f4c984f4ea7c2306`.

### Source-only verification and seals

The new source-only test is
`tests/hypotheses/H03/test_h03_report017_source_harmonization.R`. The final
verification record, exact commands, runtimes, and package versions are in
`audit/hypotheses/H03/report017_order34/H03_order34_execution_record.md`.
The non-circular current source seal is
`audit/hypotheses/H03/report017_order34/H03_order34_source_manifest.csv`.

The historical scientific-closure and preparation manifests remain
byte-for-byte unchanged:

- `H03_stage3_artifacts.csv`, SHA-256
  `5f4f10528f1c49d52518a6dde36d6ce0ffd71869cab9bcde382bf9c9edce3170`;
- `H03_preparation_report_manifest.csv`, SHA-256
  `5235b02c6c542a010336eca9569b77b269deb673d4659d794393d2427146393a`.

The latter remains historical render evidence with the same seven known
mismatches. Neither existing HTML file is accepted as a render of the revised
sources.

### Deferred baked-label refresh

No figure was edited or regenerated. A later bounded order may refresh only
the baked FDR and site-average wording in:

- `H03_near_eye_site_context_estimates.{png,pdf,svg}`; and
- `H03_reader_latitude_category_slopes.{png,pdf,svg}`.

Their exact pins, frozen source-data identities, builders, and minimum label
replacements are recorded in
`audit/hypotheses/H03/report017_order34/H03_order34_stored_figure_label_inventory.md`.
No new central scientific decision or ledger entry is proposed by this
source synchronization.

Order-34 acceptance is currently stopped by one source-test contract defect,
not by a scientific or link-resolution discrepancy. The new test imposed an
unsupported minimum of 20 Markdown-linked source-data targets; the preserved
sources contain 16, and all 16 resolved before that assertion. In accordance
with the order, the test was not patched or rerun. The exact stopped state and
required fresh correction are recorded in
`audit/hypotheses/H03/report017_order34/H03_order34_execution_record.md`.

## REPORT-017 order 34a final source-test acceptance, 2026-08-15

This section supersedes only the stopped acceptance status in the preceding
order-34 section. It does not change any H03 scientific result, source QMD,
render, or artifact.

Under the authorized order-34a correction, the source-only test now requires
the exact 16 unique linked source-data targets and exact set equality. Its
existing auxiliary qualification checks use a whitespace-normalized companion
string so source-wrapped required phrases are matched without changing the
QMD. The corrected test parsed under R 4.6.1. The unchanged auxiliary test and
the complete corrected REPORT-017 source-harmonization test each passed on
their single authorized run, and the latter reached its final success
message.

The synchronized QMD sources remain frozen at:

| Source | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H03.qmd` | `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41` | 68,198 |
| `audit/hypotheses/H03/H03_analysis_preparation.qmd` | `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131` | 75,638 |

The original order-34 manifest remains an immutable historical stopped-state
seal. The final execution record, exact reverse diff, target and qualification
proof, and superseding non-circular source seal are in
`audit/hypotheses/H03/report017_order34/`. No H03 render is released. The next
action is independent harmonizer acceptance of this source-only seal.
