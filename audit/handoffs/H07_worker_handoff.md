# H07 worker handoff

Last updated: 2026-08-07
Branch: `rewrite/NH`
Current gate: H07-005 approved; H07 worker closed, coordinator integration pending
Production computation: not run
Stage 3: rendered and verified
Stage 4: approved, rendered, and verified before shared-site integration

## Scope and ownership

All edits are confined to H07-owned notebook, audit, script, test, artifact,
render, and handoff paths. No shared preparation code, central ledger, shared
Quarto configuration, bibliography, manuscript, submission file, `renv.lock`,
or `manuscript/R0_NatMed/` path was modified by the H07 worker.

One H07 shared-change request is open solely for coordinator-owned Quarto
render-list and navigation integration. Proposed central-ledger entries are
listed below for coordinator action only after owner approval.

## Gate history

Decision `H07-001` approved H07-G1 through H07-G16 on 2026-08-06. After
reviewing the Stage 2 pooled-support display, the owner reopened H07-G1,
H07-G9, and H07-G13 and approved decision `H07-002` on 2026-08-07. The
revision asks whether a plateau-like photoperiod association is visible in
the pooled data even with the known site, collection-period, and support
limitations.

Decision `H07-003` approved `H07-S2R-001` through `H07-S2R-008` on
2026-08-07 and authorized the standalone Stage 3 reader report. The accepted
disposition uses the derivative-defined pattern as a descriptive pooled-data
result, retains every stated limitation, requires no production computation,
and does not authorize Stage 4.

Decision `H07-004` approved `H07-S3-001` through `H07-S3-006` on
2026-08-07 and authorized Stage 4. The scientific analysis-preparation and
provenance companion was then created from frozen artifacts only. No fit,
prediction, derivative, sensitivity, simulation, or bootstrap was rerun.

Decision `H07-005` approved `H07-S4-001` through `H07-S4-004` on
2026-08-07. The H07-owned four-stage workflow is closed. Shared-site and
central-ledger integration remain coordinator-owned and pending; they require
no scientific recomputation.

Durable records:

- `audit/hypotheses/H07/H07_stage1_gate_and_stage2_transition.md`;
- `audit/hypotheses/H07/H07_stage2_derivative_gate_revision.md`;
- `audit/hypotheses/H07/H07_stage2_gate_and_stage3_transition.md`; and
- `audit/hypotheses/H07/H07_stage3_author_gate.md`;
- `audit/hypotheses/H07/H07_stage3_gate_and_stage4_transition.md`; and
- `audit/hypotheses/H07/H07_stage4_author_gate.md`; and
- `audit/hypotheses/H07/H07_stage4_closure.md`.

H07-002 is explicitly post-result. It removes the pooled-support,
one-hour-run, and leave-one-site-out criteria as eligibility gates while
retaining them as diagnostics. The complete nine-metric families, near-eye
primary and chest complementary roles, exact samples, diagnostic checks,
sensitivity roles, and claim restrictions remain active.

## Revised derivative-defined plateau rule

For each metric and placement, the revised assessment uses the existing
site- and participant-adjusted photoperiod GAM and evaluates the model-scale
first derivative of `s(photoperiod_hours)` at 100 equally spaced points from
the exact metric-specific minimum to maximum recorded photoperiod. A
pointwise detected increase has a 95% interval wholly above zero. A
**derivative-defined plateau pattern** is present when the immediately next
point contains zero and every later point remains zero-compatible through the
recorded maximum. The transition is the bracket between the last detected
increase and first zero-compatible point.

The primary derivative uses central finite differences, forward/backward
boundary differences, a 0.01 h step, and unconditional covariance where
available. V0's forward-difference, conditional-covariance settings are a
method sensitivity. Pointwise non-detection is not equivalence, an asymptote,
a mechanistic ceiling, or a causal photoperiod effect.

## Stage 2 deliverables

- Audit source:
  `audit/hypotheses/H07/02_implementation_and_v0_comparison.qmd`.
- Rendered audit:
  `audit/hypotheses/H07/02_implementation_and_v0_comparison.html`.
- Revised Stage 1 source and render:
  `audit/hypotheses/H07/01_audit_and_plan.qmd` and
  `audit/hypotheses/H07/01_audit_and_plan.html`.
- Core implementation:
  `scripts/hypotheses/H07/h07_stage2_core.R`.
- Revised derivative extraction:
  `scripts/hypotheses/H07/build_h07_stage2_revised_derivative_assessment.R`.
- Paired fitted-smooth/derivative figure builder:
  `scripts/hypotheses/H07/build_h07_stage2_paired_smooth_derivative_figures.R`.
- Main, sensitivity, leave-one-site-out, V0 reconstruction, diagnostic, and
  summary runners are under `scripts/hypotheses/H07/`.
- Model checkpoints and exact frames are under `artifacts/07_models/H07/`.
- Readable figures and figure source rows are under
  `artifacts/08_figures/H07/`.
- Persisted tables, diagnostics, formula and run registries, sample counts,
  support grids, sensitivity classifications, and session information are
  under `artifacts/09_tables/H07/`.

The revised derivative artifacts include:

- `H07_revised_derivative_points.csv`;
- `H07_revised_plateau_summary.csv`;
- `H07_revised_derivative_method_comparison.csv`;
- `H07_revised_sensitivity_plateau_summary.csv` and comparison;
- `H07_revised_model_form_plateau_comparison.csv`;
- `H07_revised_loso_plateau_comparison.csv` and influence summary; and
- `H07_revised_v0_plateau_summary.csv`.

The primary near-eye and complementary chest result figures now pair every
response-scale fitted metric-value smooth with its model-scale first derivative
in the adjacent panel over the same civil-photoperiod range. Their settings are
recorded in `H07_revised_paired_figure_settings.csv`; the PNGs are
`H07_revised_smooth_derivative_pairs_near_eye.png` and
`H07_revised_smooth_derivative_pairs_chest.png`.

The Stage 1 and Stage 2 renders use Quarto 1.9.37. All scientific calculations
used R 4.6.1 and the existing project library. Current SHA-256 values are:

| Artifact | SHA-256 |
|---|---|
| `01_audit_and_plan.qmd` | `cc23223d751901a2dd06ece56a0457988f1e7d572f123bd3a0450f775f056b86` |
| `01_audit_and_plan.html` | `94b3cb1678e898b9b6652ce378a477a42a18a41258780fb57f0719f053c66f83` |
| `02_implementation_and_v0_comparison.qmd` | `b6489eb8ffd78b6f96493d296d88da73ae18ddfb2bb36d56540d044a6b319680` |
| `02_implementation_and_v0_comparison.html` | `e5e7b22e94253783c26224b82200778533d6f39caf3d4bf036888834161d4002` |
| `H07_stage2_derivative_gate_revision.md` | `f1749102406563932f3f9b981c99f4197c9c8a6790a57a1d47c3556f67ce1ed7` |
| `build_h07_stage2_revised_derivative_assessment.R` | `1d423755c9155f4776b27df8fb37a0a0eb7511d416f94b664746bf8e55e3a53b` |
| `build_h07_stage2_paired_smooth_derivative_figures.R` | `cd0606469932e28ff6acd0f0d1f833ae8a92daeae9934f595cb447228ffbe770` |

Visual QA covered the revised Stage 2 opening, primary table, both paired
fitted-value/derivative figures at native and rendered screen-inset size,
sensitivity summary, final approval gate, and the reopened Stage 1 rule. No
horizontal clipping, panel-title collision, or unreadable final-size figure
text remains.

## Stage 3 reader deliverable

The standalone reader-facing result is complete at:

- source: `notebooks/hypotheses/H07.qmd`;
- Nature Health HTML:
  `_build/nathealth/notebooks/hypotheses/H07.html`;
- focused R verification:
  `tests/hypotheses/H07/test_h07_stage3_reader_report.R`; and
- author gate: `audit/hypotheses/H07/H07_stage3_author_gate.md`.

It contains the exact preregistered hypothesis, an “Answer in brief” callout,
the full nine-metric near-eye primary and chest complementary families, exact
samples, an evaluated exact model formula, the approved derivative rule,
response specifications, endpoint derivative estimates with pointwise 95%
confidence intervals, both paired smooth/derivative figures, interpreted
convergence/distributional/residual/temporal/identifiability checks, all
approved data and model sensitivities, and metric-specific leave-one-site-out
influence tables.

The report uses no V0, gate, stage, or construction-history language. It links
the paired figures to `H07_main_curve_points.csv`,
`H07_revised_derivative_points.csv`, and
`H07_revised_paired_figure_settings.csv`. Both figures have descriptive
alternative text. The 11 rendered `gt` tables, Answer-in-brief callout, both
figures, final interpretation, and local source links were inspected at the
rendered size. Stage 4 additionally re-exported the same two result figures at
unchanged pixel dimensions using a 9 × 18-inch, 270-dpi canvas and shorter
subtitle wrapping. This display-only repair changed no curve, derivative,
interval, marker, transition, panel, or classification. No clipping, title
collision, unreadable text, broken local link, or panel imbalance remains.

The bounded single-document render completed all 33 blocks under the Nature
Health profile using R 4.6.1 and the existing project library. The focused R
verification passes all scientific and structural checks. Current SHA-256
values are:

| Artifact | SHA-256 |
|---|---|
| `notebooks/hypotheses/H07.qmd` | `dab8e92873d0a128c8b0fe423cc28375aade3f3a926167be8c113c224fbe1cb0` |
| `_build/nathealth/notebooks/hypotheses/H07.html` | `c45058b98da10a0e86d8fc6ed6183cabe7997fdb33414942874102faf953068d` |
| `tests/hypotheses/H07/test_h07_stage3_reader_report.R` | `84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17` |
| `H07_revised_smooth_derivative_pairs_near_eye.png` | `f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113` |
| `H07_revised_smooth_derivative_pairs_chest.png` | `2a714e192bd5c266d03c6f74bdabae9424f5a3663940f0bc3ae5a9ae4e066cd5` |

## Stage 4 preparation and provenance deliverable

The H07-owned Stage 4 companion is complete at:

- source: `audit/hypotheses/H07/H07_analysis_preparation.qmd`;
- bounded standalone HTML:
  `audit/hypotheses/H07/H07_analysis_preparation.html`;
- expected website source and render copies:
  `_build/nathealth/audit/hypotheses/H07/`;
- preparation artifact builder:
  `scripts/hypotheses/H07/build_h07_preparation_artifacts.R`;
- preparation manifest builder:
  `scripts/hypotheses/H07/build_h07_preparation_report_manifest.R`;
- focused verifier:
  `tests/hypotheses/H07/test_h07_preparation_report.R`;
- figure-QA record:
  `audit/hypotheses/H07/H07_figure_readability_qa.md`; and
- closure gate: `audit/hypotheses/H07/H07_stage4_author_gate.md`.

The companion starts with the revised derivative-defined plateau assessment,
quotes the preregistered hypothesis, and documents the exact nine-metric data-
to-result chain. It contains exact input identities, model-frame checks,
metric-specific samples, site/latitude/photoperiod and collection-period
support, response contracts, all nine evaluated Wilkinson formulas, repeated-
participant structure, derivative settings, diagnostics, sensitivity and
leave-one-site-out evidence, execution order, environment identity, and claim
boundaries. It explicitly records that H07 used `mgcv::gam(method = "REML")`,
not `bam()`, so H11's `discrete = FALSE` alternative does not apply.

Nine downloadable preparation CSVs and two preparation figures were built
from frozen H07 frames and tables. All four consequential input hashes and all
18 serialized primary-frame hashes pass. Frame schemas, unique keys, response
reconstructions, stored sample counts, and latitude constancy within site also
pass. The render contains 20 semantic `gt` tables, two figures with captions
and non-empty alternative text, and one Mermaid analysis map.

REPORT-011 verification covers the two results figures and two preparation
figures. Six A4-equivalent raster proofs show every figure at a 170-mm display
width; the two tall results figures are covered by contiguous top and bottom
segments without additional reduction. All four figures pass clipping,
overlap, distortion, wrapping, balance, distinguishability, caption, and alt-
text checks. Effective essential text is 7.81–7.87 pt.

The focused preparation verifier passes under R 4.6.1 before shared-site
integration. It confirms a byte-identical expected website QMD copy, two
figures, 20 `gt` tables, all source-data row contracts, formula identities,
four PASS figure-QA rows, six proof pages, reciprocal links, and the complete
preparation manifest. Executable preparation cells contain no model-fit,
prediction, derivative, simulation, or bootstrap calls.

The coordinator-owned `_quarto-nathealth.yml` does not yet include the H07
preparation page. The exact render-list and navigation request is recorded in
`audit/handoffs/H07_shared_change_request.md`. Until that integration, the
bounded standalone HTML and resources are copied into the expected website
tree for local structural and link verification only.

Current non-circular SHA-256 values are:

| Artifact | SHA-256 |
|---|---|
| `H07_analysis_preparation.qmd` | `db57a52eedbfc7cdba78f6cf49e7ed287e8aab2ebd75babcfc7ad2e65339c028` |
| `H07_analysis_preparation.html` | `81c6134635bbfb25915049c3fee16ecfd007e37eb01e878b07c01685ae901302` |
| expected website `H07_analysis_preparation.qmd` | `db57a52eedbfc7cdba78f6cf49e7ed287e8aab2ebd75babcfc7ad2e65339c028` |
| expected website `H07_analysis_preparation.html` | `81c6134635bbfb25915049c3fee16ecfd007e37eb01e878b07c01685ae901302` |
| `build_h07_preparation_artifacts.R` | `c8bcb22f49d1c1f73e5973663a6ac369377ca880c3066d22803f1e4dfa795ed3` |
| `H07_preparation_metric_sample_support.png` | `603afa8def8ff640003daaef806ee390d513df9bb6f6307fa300dba4ad5ba8a7` |
| `H07_preparation_site_photoperiod_ranges.png` | `00d687082780c65d07467fdf730ac8bcf0bd97af11a03af156dc38020b815eb4` |
| `H07_figure_readability_qa.csv` | `463308c6d01d501815fbcf481b81f0b1cc772f034b9f402403e7dda4cbb2185a` |
| `H07_figure_readability_qa.md` | `08bc05bda754b06bf7d34ce22dc7f02b0fbe28a23c09c2a02a053484f462f561` |

## Exact computation completed

- 162 main fits: nine formulas × nine metrics × two placements.
- 234 sensitivity fits across 14 run IDs and 78 metric frames.
- 153 leave-one-site-out fits: nine site omissions per near-eye metric and
  eight per chest metric.
- 28 V0 reconstruction fits: full/null pairs for 14 historical
  outcome-placement candidates.
- One 100-draw derivative simultaneous-band validation pilot per main metric.
- One 100-simulation distribution pilot per Tweedie outcome-placement fit.
- No production bootstrap, simulation, or coefficient-draw run.

All main fits use exact `mgcv::gam(method = "REML")`. The provisional `bam()`
fallback was not needed. No H07 branch uses ML or `discrete = FALSE`.
H07-002 extracted derivatives from existing checkpoints; it did not refit a
model or run a new simulation.

## Approved Stage 2 findings carried into Stage 3

1. **Primary near-eye result: six of nine patterns.** The rule is met for
   mean melEDI (16.10–16.20 h), brightest 10 h mean (15.17–15.27 h), darkest
   10 h mean (14.86–14.96 h), time above 1,000 lx melEDI (14.86–14.96 h),
   time above 250 lx melEDI during wake (14.35–14.45 h), and melEDI dose
   (14.24–14.35 h). Time below 10 lx melEDI before sleep and time below 1 lx
   melEDI during sleep have no prior pointwise detected increase. The longest
   continuous period above 250 lx melEDI remains pointwise increasing at the
   recorded upper boundary.
2. **Complementary chest result: seven of nine patterns.** The rule is met for
   mean melEDI (15.58–15.68 h), darkest 10 h mean (14.14–14.24 h), time above
   1,000 lx melEDI (13.42–13.52 h), time above 250 lx melEDI during wake
   (13.01–13.11 h), time below 1 lx melEDI during sleep (18.36–18.47 h),
   longest continuous period above 250 lx melEDI (13.73–13.83 h), and melEDI
   dose (13.11–13.21 h). Brightest 10 h mean remains pointwise increasing at
   the recorded upper boundary; pre-sleep low light has no prior detected
   increase.
3. **Method settings do not change the main yes/no result.** Exact V0
   derivative settings agree for all 18 main metric-placement combinations,
   although transition boundaries differ by as much as approximately 1.96 h.
4. **Several data and model sensitivities change classifications.** The
   gap-timing-unaware dataset agrees for all near-eye metrics and eight of nine
   chest metrics. Paired/common samples agree for four of nine near-eye and
   six of nine chest metrics. The exactly identified longest-period branch
   changes the near-eye classification. Expanded-basis fits agree for 16 of
   17 evaluable combinations, and fixed-site fits agree for 16 of 18.
5. **Site omission exposes influence but is not an exclusion gate.** Several
   near-eye classifications change when Munich is omitted; the near-eye
   longest-period classification becomes positive under four of nine site
   omissions. The complementary chest sleep-environment pattern is retained
   under only three of eight omissions. These results limit site-general
   interpretation.
6. **Registered and adapted inferential limitations remain.** Absolute
   latitude is determined by site, so the registered tensor is structurally
   non-identifiable. The adapted photoperiod smooths have target-smooth
   estimated concurvity of approximately 0.9987–0.9989; association and shape
   p-values remain withheld. These limitations no longer suppress the
   requested descriptive pattern.
7. **The sleep-environment Tweedie family fails the pilot zero-mass check.**
   Each placement has four observed zero participant-days, analytic expected
   zeros below 0.0001, and no zero in any of 100 simulations. Its H07 result
   remains descriptive and non-inferential.
8. **The revised V0 comparison is more selective than V0's boundary rule.**
   The AIC retention decisions reproduce. Eight of 14 V0 candidates and six
   of ten historically retained combinations meet H07-002's added
   zero-compatible-through-the-end requirement.
9. **H11's alternative implementation is not needed.** H07's exact daily
   `gam(REML)` fits completed successfully. H11's large half-hourly
   Gaussian/AR(1) motivation for `bam(discrete = FALSE)` and participant CR1
   does not address H07's site, latitude, photoperiod, or collection-period
   structure and was not transferred.

## Exact samples

- Primary near eye: 139–141 participants, 655–816 participant-days and
  observations, nine sites.
- Complementary chest: 153–154 participants, 743–902 participant-days and
  observations, eight sites.
- Paired/common placement sensitivity: 110–112 participants, 505–643
  participant-days, eight sites.
- Exactly identified longest-period sensitivity: 132 participants and 500
  participant-days near eye; 150 participants and 564 participant-days at the
  chest.
- Observed/corrected dose common rows: 141 participants and 761
  participant-days near eye; 154 participants and 851 participant-days at the
  chest.

Metric-exact rows and frame hashes are in `H07_main_samples.csv` and
`H07_sensitivity_samples.csv`.

## H07-local diagnostic correction

`build_h07_stage2_main_diagnostics.R` originally passed Tweedie
`fitted.gam()` values through the inverse log link a second time when creating
only the fitted-range diagnostic. `fitted.gam()` already returns response-scale
values. The H07-local helper now leaves those values on the response scale.
The correction changes no model, coefficient, p-value status, AIC, support
grid, curve, residual, sensitivity, V0 reconstruction, or pilot. Corrected
adapted-fit duration fitted ranges are 0.15–9.62 h rather than impossible
exponentiated values.

## Proposed central-ledger entries

The coordinator owns the ledgers. After owner approval, add or map the
following entries using central conventions:

| Proposed ID | Ledger role | Proposed disposition |
|---|---|---|
| `H07-STAGE2-REV-001` | stage gate | H07-002 revised Stage 2 implemented and rendered; H07-S2R-001 through H07-S2R-008 approved in H07-003 |
| `H07-METHOD-002` | post-result method decision | Assess a 100-point derivative-defined plateau pattern from the existing adapted GAM; pooled support and site omission are diagnostics, not eligibility gates |
| `H07-FIND-001` | finding | Registered latitude–photoperiod tensor non-identifiable because absolute latitude is determined by site |
| `H07-FIND-002` | finding | Adapted photoperiod whole-term and shape p-values withheld for extreme concurvity; conditional AIC descriptive only |
| `H07-FIND-003` | descriptive finding | H07-002 pattern present for six of nine primary near-eye and seven of nine complementary chest metrics; no equivalence, asymptote, mechanistic ceiling, or causal interpretation |
| `H07-FIND-004` | finding/model adequacy | Sleep-environment Tweedie family fails the 100-simulation zero-mass pilot; H07 disposition descriptive/non-inferential |
| `H07-FIND-005` | comparison | V0 AIC retention reproduces; eight of 14 candidates and six of ten retained combinations meet H07-002's added through-end rule |
| `H07-FIND-006` | sensitivity/influence | Paired/common samples, exact-period data, model form, and site omission change several derivative classifications; retain as interpretation limitations |
| `H07-METHOD-001` | method decision | Exact `gam(REML)` retained; no `bam(discrete = FALSE)` or H11 CR1 transfer |
| `H07-SAMPLE-001` | sample flow | Near-eye metric-specific samples 139–141 participants and 655–816 participant-days across nine sites |
| `H07-SAMPLE-002` | sample flow | Chest metric-specific samples 153–154 participants and 743–902 participant-days across eight sites |
| `H07-DEVIATION-001` | registered deviation | Registered tensor retained as non-identifiable result; adapted site-adjusted photoperiod curve separately labelled and non-inferential |
| `H07-DEVIATION-002` | registered deviation | V0 significance/AIC-dependent outcome selection replaced by complete nine-metric families independent of H01 results |
| `H07-DEVIATION-003` | post-result deviation | H07-002 replaces the pre-fit equivalence/support eligibility rule with a descriptive pointwise positive-to-zero-compatible-through-end rule |
| `H07-REPORT-001` | reporting decision | Use “derivative-defined plateau pattern”; state post-result and pointwise limitations; prohibit unsupported ceiling terminology |
| `H07-STAGE3-001` | stage gate | Standalone reader report rendered and verified; H07-S3-001 through H07-S3-006 approved in H07-004 |
| `H07-STAGE3-NOPROD` | computation decision | No production simulation or bootstrap required for the accepted descriptive estimand |
| `H07-STAGE4-001` | stage gate | H07-S4-001 through H07-S4-004 approved in H07-005; H07-owned workflow closed, shared-site integration pending |
| `H07-REPORT-002` | figure QA | Four H07 reader-facing figures pass REPORT-011 at 170-mm display width; result-figure re-export was display-only and preserved scientific content |
| `H07-INTEGRATION-001` | shared change request | Add the H07 preparation source immediately after the result in the shared render list and navigation, then rerun the bounded verifier |

Do not enter an inferential p-value, significant/non-significant association
label, causal site effect, placement-equivalence claim, temperature-adjusted
result, or mechanistic ceiling claim.

## Owner decisions resolved

The complete approved gate and closure records are in
`audit/hypotheses/H07/H07_stage4_author_gate.md` and
`audit/hypotheses/H07/H07_stage4_closure.md`. The author approved:

- `H07-S4-001`: accept the preparation companion as an accurate provenance
  account of the accepted result;
- `H07-S4-002`: accept the bounded execution boundary, exact formula/sample
  records, and no-refit verification;
- `H07-S4-003`: accept the final-size figure QA and display-only result-figure
  repair; and
- `H07-S4-004`: authorize coordinator-owned shared-site integration and final
  ledger closure without scientific recomputation.

Decision `H07-005` records approval of all four items. The H07 worker has
stopped before modifying shared configuration or central ledgers.
