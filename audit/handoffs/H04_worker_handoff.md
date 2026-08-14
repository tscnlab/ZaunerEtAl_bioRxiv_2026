# H04 worker handoff

Date: 2026-08-14

Branch observed: `rewrite/NH`

Current gate: **Stages 1–4 and the two owner-requested post-approval sensitivity assessments are complete in H04-owned scope**

## Scope and authorization

The owner explicitly authorized `$measurement-methods-audit`,
`$quarto-authoring`, and `$develop-r-code` in this H04 task. All three were
invoked. Only H04-owned scripts, tests, reports, handoffs, and artifacts were
changed. No shared preparation code, central ledger, Quarto configuration,
index, Supplementary Information, bibliography, manuscript file, `renv.lock`,
or `manuscript/R0_NatMed/` path was modified. No push or upload was performed;
the owner requested a final H04-scoped commit after approving this companion.

## Gate history

1. H04-G1 through H04-G8 were approved on 2026-08-10, including the revised
   thin-plate `sz` temporal specification.
2. Stage 2 progression was explicitly approved in this task.
3. On 2026-08-11 the owner amended the temporal uncertainty contract: use the
   same implementation as H03 rather than participant-bootstrap intervals.
   This supersedes only the bootstrap clause and pilot/production gate in
   H04-G6; it does not change the approved temporal formula, weights, runs,
   estimand, or retention criteria.
4. The owner then explicitly approved the complete Stage 2 result and
   authorized progression to Stage 3, requesting that H03's main reader
   figures and tables be recreated where appropriate for H04.
5. During Stage 3 review, the owner requested H03's convention of using the
   supported site-heterogeneity model for descriptive category summaries,
   dashed equal-site averages in Figure 2, and temporal activity colours that
   are distinct from H03's light-source category colours. All three amendments
   are implemented; the additive-model primary omnibus remains unchanged.
6. The owner then fixed the reader-facing category order as At home,
   Office/home working, Outdoors, Vehicle/public transport, Sleeping, with
   Other/unspecified last where displayed. The owner also requested taller
   Figures 5 and 6, single-line abbreviated facet strips, and separation of
   panel tags from axis labels. These display-only amendments are implemented;
   model reference coding, fitted objects, estimates, and inference did not
   change.
7. The owner requested category-comparison p-values in Table 9, clarified that
   raw site-deviation p-values were unnecessary, and requested fuller
   ratio-axis coverage in Panels B of Figures 5 and 6. The blue-grey row now
   gives BH-adjusted p-values for the four heterogeneity-model category ratios
   versus At home; every estimable site cell gives only its complete-family
   BH-adjusted deviation p-value. Both temporal ratio panels use one common
   0.01–50 range with standard 1–2–5 logarithmic breaks, which contains the
   complete displayed pointwise interval range of 0.013–29.1. Internal audit
   identifiers and cross-hypothesis implementation language were removed from
   the standalone reader report. These reporting changes do not alter the
   primary omnibus or any fitted model.
8. The owner explicitly approved the standalone H04 reader report on
   2026-08-11 and authorized continuation. The analysis-preparation and
   provenance companion was then authored, rendered, visually inspected, and
   verified in H04-owned scope.
9. The owner explicitly approved the preparation companion on 2026-08-11 and
   requested that the H04 task be wrapped up and committed. This closed the
   four-stage H04 scientific workflow.
10. On 2026-08-14 the owner requested a Mundlak sensitivity analysis. It was
    fitted against the accepted frozen H04 primary-frame archive and added to
    the Stage 3 report without replacing the primary population-mean model.
11. The owner then requested an H03-aligned marginal and conditional R²
    decomposition through a participant random-intercept model. The weighted
    mixed-model assessment, report sections, artifacts, and focused test were
    completed on 2026-08-14. The Writer received the verified results, and the
    Coordinator and Harmonizer were consulted before the final H04 commit.

## Stage 2 deliverables

- `audit/hypotheses/H04/02_implementation_and_v0_comparison.qmd`
- `audit/hypotheses/H04/02_implementation_and_v0_comparison.html`
- `scripts/hypotheses/H04/h04_data.R`
- `scripts/hypotheses/H04/h04_modeling.R`
- `scripts/hypotheses/H04/h04_reporting.R`
- `scripts/hypotheses/H04/h04_temporal.R`
- `scripts/hypotheses/H04/run_h04_stage2.R`
- `scripts/hypotheses/H04/run_h04_temporal.R`
- `scripts/hypotheses/H04/refresh_h04_temporal_uncertainty.R`
- `scripts/hypotheses/H04/build_h04_stage2_figures.R`
- `scripts/hypotheses/H04/build_h04_stage2_support.R`
- `scripts/hypotheses/H04/build_h04_temporal_figures.R`
- `tests/hypotheses/H04/test_h04_stage2.R`
- H04 model, diagnostic, table, figure, source-data, and manifest artifacts

The Stage 2 report contains implementation history and the V0 comparison. It
ends at the explicit Stage 2 stop.

## Stage 3 deliverables

- `notebooks/hypotheses/H04.qmd`
- `_build/nathealth/notebooks/hypotheses/H04.html`
- `audit/hypotheses/H04/H03_reader_style_content_crosswalk.md`
- `scripts/hypotheses/H04/build_h04_stage3_reader_assets.R`
- `scripts/hypotheses/H04/build_h04_stage3_reader_figures.R`
- `scripts/hypotheses/H04/build_h04_stage3_assets.R`
- `scripts/hypotheses/H04/build_h04_stage3_manifest.R`
- `tests/hypotheses/H04/test_h04_stage3_reader_report.R`
- `artifacts/12_manifests/H04/H04_stage3_reader_asset_manifest.csv`
- `artifacts/12_manifests/H04/H04_stage3_figure_readability_qa.csv`
- `artifacts/12_manifests/H04/H04_stage3_artifacts.csv`

The standalone reader report opens with an **Answer in brief** callout and
contains no V0, implementation-repair, approval-gate, or construction-history
language. It recreates the H03 reader sequence where it is scientifically
appropriate for H04:

1. exact fitted samples, explicit excluded-hour flow, category support, and
   exact Wilkinson formulas;
2. heterogeneity-model standardized means, ratios, differences, and intervals
   for the five named categories, separately labelled additive-model named
   contrasts and omnibus tests, and the two-panel category-estimate figure;
   Other remains an additive-model display-only exception;
3. separate support-gated site heterogeneity with complete multiplicity
   accounting, the site-context figure, and H03's descriptive
   hierarchy-respecting R-squared decomposition;
4. numerical/plain-language diagnostics and H03's three-panel primary
   diagnostic figure;
5. the complete sensitivity battery and paired/common placement figure; and
6. near-eye and chest exploratory three-row temporal figures, fit and
   diagnostic tables, participant-balanced R-squared, H03's point
   linear-predictor allocation, a three-panel temporal diagnostic figure,
   H03-aligned pointwise uncertainty, and explicit inferential limits.

H03's latitude replacement was not transferred: H04 did not preregister or
approve a latitude analysis, and adding it would introduce a different
scientific question. The exact H03 reader elements and H04 adaptations are
recorded in the crosswalk. The seven H04 figures were rebuilt to use H03's
`cowplot` typography, panel structure, caption treatment, and point/interval
geometry while retaining H04's accepted estimands, support rules, and durable
source-data CSVs. Figure 2 has a dashed equal-site geometric mean in every
placement-by-activity facet. The temporal figures use an H04 palette with no
hexadecimal colour reused from H03's light-source palette. Categorical tables
and panels follow the owner-fixed reference-first reader order. Figures 5 and
6 are exported at 15.75 by 12.5 inches, use six single-line short facet labels,
and place A/B/C at the upper right clear of vertical axis titles.

## Primary representation and samples

The approved transformation is implemented exactly: collapse the three
outdoor flags before pivoting; deduplicate collapsed labels within hour;
suppress co-selected Other while retaining Other-only hours; pivot distinct
labels; and assign each generated row weight `1/k`.

| Placement | Participants | Participant-days | Unique hours | Long rows | Effective weighted hours |
|---|---:|---:|---:|---:|---:|
| Near-eye | 126 | 724 | 16,526 | 17,266 | 16,526 |
| Chest | 150 | 875 | 20,128 | 21,071 | 20,128 |

The paired/common sample contains 110 participants, 625 participant-days,
14,308 unique participant-hours, 15,001 long rows, and 14,308 effective
weighted hours at each separately fitted placement. The gap-timing-unaware
frames contain 16,242 near-eye and 19,827 chest unique hours.

## Primary and complementary results

The fitted population-mean model is
`geo_medi_1h ~ site + activity`, with quasi-Tweedie working power 1.539919,
log link, exact `1/k` prior weights, participant-clustered HC1 covariance, and
finite-cluster *t*/*F* inference.

Because both site-heterogeneity tests are supported, the reader-facing
descriptive means for the five named categories come from the accepted
site-heterogeneity models, as in H03. Other is excluded from those models and
is retained only as its additive-model display estimate:

| Category | Near-eye | Chest |
|---|---:|---:|
| Sleeping | 4.28 | 4.66 |
| At home | 76.36 | 78.04 |
| On the road with public transport/car | 331.22 | 512.91 |
| Working in the office/from home | 198.87 | 202.87 |
| Outdoors | 714.22 | 998.85 |
| Other/unspecified activity | 221.83 | 315.69 |

The primary five-named-category tests are:

- near-eye: `F(4, 125) = 83.59`, raw `p < 0.001`;
- chest: `F(4, 149) = 93.31`, raw `p < 0.001`.

Other remains fitted but unrestricted and supports no scientific claim. The
full six-category omnibus is secondary. All four named-versus-home contrasts
remain directionally stable in every prespecified sensitivity. Site
heterogeneity is reported separately with support gating and excludes Other.
The inferential named-versus-home table remains tied to the additive model;
no p-value is attached to a descriptive heterogeneity-model estimate.
Primary diagnostics are **ACCEPTABLE WITH LIMITATION** for both placements;
the report retains the zero-structure, variance, serial-dependence, sparse-cell,
and influence qualifications.

## Post-approval participant-level sensitivities

The owner-requested Mundlak sensitivity separates within-participant activity
associations from between-participant activity composition while preserving
the accepted primary participant-hours and exact `1/k` weights. Every primary
named-versus-home ratio lay inside the corresponding Mundlak sensitivity
interval, and the largest point-estimate change was below 17%. The joint
between-participant activity-composition test was $F(4,125)=3.81$, raw
$p=0.006$ near eye and $F(4,149)=2.34$, raw $p=0.058$ at chest. A 10
percentage-point greater outdoors share was associated with ratios of 1.42
near eye and 1.30 at chest, with FDR-adjusted $p=0.039$ and $p=0.054$,
respectively. These exploratory composition contrasts are not causal effects.

The subsequent participant random-intercept assessment uses the supported
five-named-category activity-by-site frame and exact `1/k` weights:

```r
geo_medi_1h ~ site * activity_named + (1 | participant)
```

The `glmmTMB` Tweedie/log model uses maximum likelihood and the fixed working
power 1.539919. The H04 marginal R² calculation weights the fixed linear
predictor variance by the exact fractional memberships. Marginal and
conditional R² were 0.766 and 0.858 near eye, and 0.768 and 0.859 at chest.
The participant-intercept increment was 0.092 at both placements. Activity
accounted for 80.7% of near-eye and 86.1% of chest marginal R², study site for
12.5% and 5.9%, and the interaction for 6.9% and 8.0%. All ten hierarchy-valid
nested fits converged without warnings, had positive-definite Hessians, and
were non-singular.

This mixed model is an exploratory point decomposition. It has no random
activity slopes or bootstrap intervals, and it does not replace the accepted
population-mean quasi-Tweedie inference. Complete implementation and evidence
are in:

- `scripts/hypotheses/H04/run_h04_mundlak_sensitivity.R`;
- `scripts/hypotheses/H04/run_h04_participant_random_intercept_assessment.R`;
- `tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R`;
- `artifacts/09_tables/H04/H04_mundlak_between_participant_omnibus.csv`;
- `artifacts/09_tables/H04/H04_participant_random_intercept_summary.csv`;
- `artifacts/09_tables/H04/H04_participant_random_intercept_marginal_r2_shapley.csv`;
- `artifacts/08_diagnostics/H04/H04_participant_random_intercept_diagnostics.csv`.

## Exploratory temporal implementation

The accepted formula is:

```r
geo_medi_1h ~
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, activity, bs = "sz", k = 12) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

The activity and site `sz` terms resolve to the approved thin-plate marginal
basis. Only the global time smooth is cyclic. Activity-specific AR runs prevent
concurrent long rows from becoming lag neighbours. The exact `1/k` weights are
retained. The H04 temporal palette is deliberately disjoint from H03's
light-source palette to prevent a visual category mapping across hypotheses.

Both activity models are retained **ACCEPTABLE WITH LIMITATION**:

| Placement | Minimum k-index | Activity minus comparator AIC | Deviance explained | Comparator deviance explained | Residual lag 1 |
|---|---:|---:|---:|---:|---:|
| Near-eye | 0.872 | -3,214.95 | 0.848 | 0.818 | 0.176 |
| Chest | 0.863 | -4,983.60 | 0.832 | 0.795 | 0.167 |

There are 41 near-eye and 40 chest locally sparse clock/activity cells. The
accepted non-cyclic deviations can separate across midnight. The retained
activity fits completed both passes without warnings. The chest no-activity
comparator's preliminary zero-rho pass warned `algorithm did not converge`,
but its final fixed-rho comparator fit converged without warning.

## H03-aligned temporal uncertainty

For each time/activity curve, H04 now:

1. obtains `stats::vcov(fit, unconditional = TRUE)`, with `fit$Vp` only as an
   error fallback;
2. sets participant and participant-day smooth contributions to zero;
3. averages the fitted design rows equally across observed sites on the
   log-mean scale;
4. calculates the link-scale standard error from the fitted coefficient
   covariance;
5. applies `estimate ± 1.96 * SE`; and
6. back-transforms once with `exp()`.

The ribbons are model-based pointwise 95% intervals. They are not simultaneous
bands and support no time-specific or curve-wide inference. Resampling
replicates used by the accepted uncertainty implementation: **0**.

The incomplete bootstrap pilot is preserved but superseded:

| Placement | Completed checkpoints | Successful checkpoints | Unsuccessful checkpoints |
|---|---:|---:|---:|
| Near-eye | 16 | 13 | 3 |
| Chest | 19 | 11 | 8 |

These 35 checkpoint files are excluded from estimates, intervals, figures,
tests, and scientific claims. No production bootstrap is required or
authorized. The historical bootstrap driver now aborts before loading data or
fitting a model.

## Verification

Scientific computation used R 4.6.1 and the synchronized project library.

Successful narrow temporal refresh:

```text
NATHEALTH_PROJECT_ROOT=<project-root> \
Rscript --vanilla scripts/hypotheses/H04/refresh_h04_temporal_uncertainty.R
```

Successful H04-only render:

```text
RENV_CONFIG_SANDBOX_ENABLED=FALSE \
H04_PROJECT_ROOT=<project-root> \
quarto render audit/hypotheses/H04/02_implementation_and_v0_comparison.qmd --to html
```

Successful H04-only test:

```text
NATHEALTH_PROJECT_ROOT=<project-root> \
Rscript --vanilla tests/hypotheses/H04/test_h04_stage2.R
```

The test reports:
`H04 Stage 2 fitted-artifact, report, and pointwise-uncertainty contracts passed`.
It directly recomputes one cached near-eye time slice and reconciles its point
estimate and both pointwise limits to the durable source CSV.

Rendered visual QA confirmed that the covariance equation is correctly
typeset, the uncertainty table has no clipped or letter-stacked columns, the
pointwise ribbons and weighted-support panels are legible at publication scale,
and the final gate contains no production-bootstrap decision.

Successful H04-only reader-asset verification:

```text
NATHEALTH_PROJECT_ROOT=<project-root> \
Rscript --vanilla scripts/hypotheses/H04/build_h04_stage3_assets.R
```

Successful standalone reader render:

```text
RENV_CONFIG_SANDBOX_ENABLED=FALSE \
QUARTO_PROFILE=nathealth \
quarto render notebooks/hypotheses/H04.qmd --to html
```

Successful reader-report manifest and test:

```text
NATHEALTH_PROJECT_ROOT=<project-root> \
Rscript --vanilla scripts/hypotheses/H04/build_h04_stage3_manifest.R

NATHEALTH_PROJECT_ROOT=<project-root> \
Rscript --vanilla tests/hypotheses/H04/test_h04_stage3_reader_report.R
```

The reader test reports:
`H04 standalone reader-report contracts passed`. It verifies exact samples,
estimates, omnibus tests, site-deviation counts, sensitivity classifications,
paired/common denominators, temporal formula and uncertainty boundaries, all
seven figures and 19 durable source-data files, seven long-form alt texts, at
least 14 rendered `gt` tables, forbidden workflow-history language, and every
manifest hash. It additionally reconciles all ten named reader averages to the
accepted heterogeneity-model site averages, checks every Figure 2 dashed-line
stratum, verifies the disjoint H03/H04 temporal palettes, and reconciles all 46
derivation-manifest hashes.
The reader contract also checks the exact category sequence in the rendered
support, estimate, contrast, and near-eye site-factorization tables, plus the
12.5-inch base height of both temporal figures. It now checks the four
category-level and 44 site-level BH-adjusted p-value displays in Table 9,
confirms that no raw site p-values or internal reader-facing identifiers
remain, and verifies that the common temporal ratio scale contains every
displayed pointwise confidence bound.

The final rendered HTML contains seven figures, seven non-empty long-form alt
texts, and 17 `gt` tables.

Original-size inspection covered all seven PNGs. The resulting readability
registry records clipping, wrapping, panel balance, tight bounds, and an
effective minimum essential type size of at least 5 pt at 170 mm display
width. Figure 2's dashed references and three-line caption were checked at
original size with no clipping. Figures 5 and 6 were inspected at original
size: all six facet strips remain one row high, A/B/C are separated from the
axis titles, the expanded ratio ticks remain distinct, and captions and axes
are unclipped. The rendered Table 9 was also inspected after revising its
p-value lines; category-level and site-level BH p-values remain readable
without within-cell overlap.
Static rendered-HTML checks confirmed the
heterogeneity-model values, figure order, table count, alt attributes,
formula/result text, temporal-palette statement, and p-value display. Automated
in-app inspection of the new local `file://` render was not available because
that browser surface blocks agent navigation to local files; no alternate
browser route was used.

## Stage 4 deliverables

- `audit/hypotheses/H04/H04_analysis_preparation.qmd`
- `_build/nathealth/audit/hypotheses/H04/H04_analysis_preparation.qmd`
- `_build/nathealth/audit/hypotheses/H04/H04_analysis_preparation.html`
- `audit/hypotheses/H04/H04_preparation_figure_readability_qa.md`
- `scripts/hypotheses/H04/build_h04_preparation_artifacts.R`
- `scripts/hypotheses/H04/verify_h04_metric010_frame_invariance.R`
- `scripts/hypotheses/H04/build_h04_preparation_figure_readability_qa.R`
- `scripts/hypotheses/H04/build_h04_preparation_report_manifest.R`
- `tests/hypotheses/H04/test_h04_preparation_report.R`
- seven preparation source-data CSVs under
  `artifacts/11_source_data/H04/`
- `artifacts/12_manifests/H04/H04_preparation_figure_readability_qa.csv`
- `artifacts/12_manifests/H04/H04_preparation_figure_A4_proofs.pdf`
- `artifacts/12_manifests/H04/H04_preparation_report_manifest.csv`

The standalone preparation companion follows the accepted H02/H03 structure
without reader-facing workflow history. It contains an execution-boundary
note, a Mermaid analysis map, 37 readable `gt` tables, and four alt-texted
figures. It traces the frozen one-hour frames, exact outdoor collapse and
Other-specificity rule, fractional `1/k` weights, sample flow, support and
positivity, formulas and estimands, robust restrictions, equal-site
standardization, support-gated heterogeneity, diagnostics, sensitivities,
thin-plate `sz` temporal construction, pointwise covariance intervals, code
order, output chain, and environment identity. Rendering the page does not fit
or refit a model, predict from a model, resample, simulate, or recompute a
variance allocation.

Four source-data figures were inspected at original size and in a 170-mm A4
proof. Clipping, overlap, wrapping, typography, legend balance, sparse-cell
symbols, and final-size legibility all passed. The preparation manifest records
252 file identities. The result-report manifest now records 299 identities and
excludes the preparation manifest specifically to prevent a reciprocal hash
cycle; the preparation manifest includes the result-report manifest.

### METRIC-010 provenance repin

The current shared near-eye and chest one-hour objects differ bytewise from
the inputs recorded when H04 was fitted because METRIC-010 extended their
embedded metric-setting provenance. The H04 worker did not modify either
shared object. Under R 4.6.1, all 14 H04 analysis frames were rebuilt from the
current objects and compared with the accepted frozen frames at tolerance
zero. Every frame value, row count, column count, and row order was identical;
12 frames differed only in embedded attributes and the two
gap-timing-unaware frames were fully attribute-identical. The H04-local
contract now pins the current shared objects. No model was refit and all
accepted model objects and reported results remain controlling. Durable
evidence is in:

- `artifacts/08_diagnostics/H04/H04_metric010_frame_invariance.csv`;
- `artifacts/08_diagnostics/H04/H04_metric010_input_reconciliation.csv`.

### Stage 4 verification

The registered Nature Health profile render is the canonical preparation
output. The H04-local manifest builder inventories its existing HTML and page
assets read-only. It refreshes only
`_build/nathealth/audit/hypotheses/H04/H04_analysis_preparation.qmd` from the
authoring QMD and proves byte identity; this file is a provenance source copy,
not a second rendering route. No source-side HTML or parallel asset tree is
created. The H04 Stage 1 support, Stage 2, standalone Stage 3 reader,
participant-random-intercept, and preparation tests pass after the additions.

The sealed post-closure harmonization review is
`audit/report_harmonization/h04_postclosure_random_intercept_harmonization_check.md`
(SHA-256
`901f39f506f2770c014a923a788d5370c5ee61a8bcfab368e6592efa47d1c780`).
The two reader sources now use **participant-level variation**, explain the
participant random intercept in plain language, identify `glmmTMB` as the R
software used for the generalized linear mixed model, and provide one anchored
dynamic source link from the result report to the companion details. This was
a source-only synchronization. It did not render or alter the canonical
website HTML, page assets, search index, sitemap, or shared profile.

## Proposed central-ledger entries

The coordinating task owns the central ledgers. Proposed entries or status
updates, not applied here:

1. Mark H04 Stages 1–4 complete and approved in hypothesis-owned scope, with
   only shared Nature Health profile registration pending.
2. Record the primary five-named-category robust test with Other unrestricted,
   the secondary six-category omnibus, and separate supported heterogeneity;
   use the heterogeneity model for named descriptive summaries while retaining
   Other only as an additive-model display estimate.
3. Record the exact primary and complementary sample counts above and the
   paired/common and gap-timing-unaware sensitivity counts.
4. Record `H04-S2-AMEND-001`: the H03-aligned fitted-coefficient covariance
   supplies pointwise temporal intervals; no simultaneous band, curve-wide
   inference, bootstrap, simulation, or production-computation gate remains.
5. Classify the 35 temporal-bootstrap checkpoint files and bootstrap prototype
   scripts as superseded provenance that must not enter Stage 3 or scientific
   claims.
6. Record the Stage 3 standalone report path, its seven figures and 19 durable
   source-data files, the descriptive H03-aligned heterogeneity and temporal
   allocations, and the explicit omission of the unapproved H03-only latitude
   analysis.
7. Record the reader-facing reference-first display order and the taller,
   single-line-facet temporal layout as presentation decisions only, with no
   change to reference coding or fitted results.
8. Record the Table 9 category-level and site-level BH p-value display, the
   omission of raw site p-values, and the common 0.01–50 temporal ratio axis as
   reporting amendments only.
9. Record the METRIC-010 provenance-only repin: all 14 rebuilt H04 frame values
   were identical at tolerance zero, the H04-local current hashes were repinned,
   and no model, estimate, interval, diagnostic, sensitivity, or claim changed.
10. Record that `audit/hypotheses/H04/H04_analysis_preparation.qmd` is
    registered immediately after H04 results in the Nature Health render list
    and navigation, with the profile output as the canonical render.
11. Record the post-approval Mundlak sensitivity and participant
    random-intercept decomposition as exploratory analyses that leave the
    accepted primary population-mean inference unchanged.

## Stop condition

H04-owned work is complete. No further H04 scientific computation, model
fitting, or shared-profile change is required.
