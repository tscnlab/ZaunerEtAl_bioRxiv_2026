# REPORT-014/017 order 37: H06 consolidated reader and companion rewrite

Date: 2026-08-14

Owner: main hourly H06 task `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: authorized source-only order; every H06 render remains held

## Purpose

Perform one coherent source-only rewrite of the complete main hourly H06 result
and preparation/provenance pair. Read both documents, the complete current H06
handoff, all three existing H06 tests, all three current H06 report manifests,
the full audit, and the complete matrix before editing.

Implement the complete package in one pass. Run the prescribed source-only
verification suite once after all edits are assembled. If an unexpected failure
occurs, do not enter a piecemeal patch loop. Seal the complete stopped state and
return one combined defect list. Do not render.

This order may overlap other source-only work because its mutable path set is
H06-specific and disjoint. It must not touch H06 daily, another hypothesis, or
any shared build, profile, ledger, hook, catalog, or coordination file.

The controlling package is:

- Full audit: `audit/report_harmonization/report017_h06_consolidated_full_document_audit.md`, SHA-256 `f9802f66bf615f7c8b5cb1b137f3cbc732735aeeee4ff03e84dd6f8a322e2ede`.
- Complete 59-row matrix: `audit/report_harmonization/report017_h06_consolidated_change_matrix.csv`, SHA-256 `8ed288517f41521df21640a19473d287ae183776e6c5c25a5128863511079951`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.
- Coordination matrix at dispatch preparation: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `1744edd196f0daba495a3781836b5964f3148e78f90bd1f4a226526798e9d9be`. It is coordination evidence only and is not an owner execution pin while parallel source work is active.

## Exact owner-scoped preflight pins

- `notebooks/hypotheses/H06.qmd`: `692c28ce165eda27e0b85dbb73f2e834a31a188ae8eefe9f1391980bd5641459`, 56,355 bytes.
- `audit/hypotheses/H06/H06_analysis_preparation.qmd`: `205eac1ee6d878353a2b23c3741e18ef7480765882d6e0baad0808963b3aa731`, 55,895 bytes.
- `tests/hypotheses/H06/test_h06_stage2.R`: `489115354c11de17b627e4e2cb28cef9f54654a50756a7d4897dda3080b29b89`, 15,916 bytes.
- `tests/hypotheses/H06/test_h06_stage3.R`: `a6e3e307b023588b475587876be86eeb9c0f7b9d9d1597df946dd112458940aa`, 35,771 bytes.
- `tests/hypotheses/H06/test_h06_preparation_report.R`: `2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc`, 12,918 bytes.
- `artifacts/12_manifests/H06/H06_stage2_artifacts.csv`: `2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752`, 227 data rows.
- `artifacts/12_manifests/H06/H06_stage3_artifacts.csv`: `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21`, 301 data rows.
- `artifacts/12_manifests/H06/H06_preparation_report_manifest.csv`: `db976477b9cdbce2a6d4575e382b2f04062e8834c086f1d82cb25d7e8a2176e4`, 315 data rows.
- `audit/handoffs/H06_worker_handoff.md`: `5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829`, 24,781 bytes.

Stable shared read-only context:

- `notebooks/preregistration_deviations.qmd`: `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.
- `config/site_display_registry.csv`: `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.
- `_quarto-nathealth.yml`: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`. Context only; do not edit or render.
- Current result HTML: `_build/nathealth/notebooks/hypotheses/H06.html`, `ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`, 6,109,797 bytes.
- Current companion HTML: `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html`, `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`, 771,694 bytes.
- Phase 2 output catalog: `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`. Do not edit it.
- Complementary daily result: `notebooks/hypotheses/H06_daily.qmd`, `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`, 65,344 bytes.
- Complementary daily companion: `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`, 35,409 bytes.
- H06 display CSS: `notebooks/hypotheses/H06.css`, `20eb8615bf40acf6cb36a3ca43a360d9cc943fd2a79299520e9d864406a359af`.

Stop before editing if any owner-scoped pin differs. A mutable coordinator or
harmonizer file may drift outside the owner edit set. Record such drift as
context and do not repin it.

## Authorized mutable files

The owner may edit only:

1. `notebooks/hypotheses/H06.qmd`
2. `audit/hypotheses/H06/H06_analysis_preparation.qmd`
3. `audit/handoffs/H06_worker_handoff.md`
4. New `tests/hypotheses/H06/test_h06_report017_source_harmonization.R`
5. New order-37 audit, exact source diff, reverse proof, protected inventory,
   execution record, stored-figure inventory, and non-circular source-manifest
   evidence under `audit/hypotheses/H06/report017_order37/`

Do not edit the three existing H06 tests, any current H06 manifest, any
analysis or figure-building script, any data, model, stored table, stored
figure, source-data file, build output, profile, central record,
harmonizer-owned file, manuscript file, H06 daily file, or another hypothesis.

## Scientific boundary

Preserve the accepted hourly H06 analysis exactly:

- the hourly analysis remains the main H06 result and the daily analysis
  remains complementary participant-day evidence;
- the primary outcome remains the zero-aware geometric mean melEDI for each
  retained participant-hour;
- near-eye measurements remain primary and chest measurements remain
  complementary non-ocular evidence;
- the primary frame remains 16,596 supported hours, 715 participant-days,
  137 participants, and nine study sites;
- the accepted average ratios, 95% confidence intervals, FDR-adjusted
  p-values, interaction results, site-specific screens, sensitivities, model
  checks, and exploratory nonlinear timing results remain exact;
- site-specific screens compare each site's ratio with 1, while pointwise
  site-to-average intervals compare a site with the site-average estimate;
- the paired-day comparison uses the same participants and participant-days,
  but three hourly keys differ at each position, and therefore is not an
  observation-level identity comparison, equivalence analysis, or direct
  placement effect; and
- the nonlinear GAM analysis remains exploratory, with pointwise intervals
  that are not simultaneous bands or multiplicity-controlled whole-curve
  tests.

Do not change a sample, formula, transformation, model, estimate, interval,
p-value, FDR decision, diagnostic, residual summary, influence result,
sensitivity, curve, table value, figure value, source-data row, or scientific
claim.

## Complete result-source rewrite

### Target order

Use this coherent reader order:

1. Scientific question, explicit hourly-main versus daily-complementary
   orientation, reciprocal preparation link, and concise Answer in brief.
2. A short first-use orientation for melEDI, participant-hour,
   participant-day, primary near-eye and complementary chest roles, 95% CI,
   participant-cluster HC3, FDR, predictor-by-site interaction, site-average
   estimate, and sensitivity analysis.
3. Principal hourly result, beginning with `fig-h06-core-effects`, followed
   immediately by `tbl-h06-primary-effects` and the accepted interpretation.
4. The visible conclusion about predictor-by-site interactions and model/site
   dependence, followed by optional detailed site evidence.
5. The visible conclusion from required dataset, chest, paired-day,
   working-variance, and influence analyses, followed by optional details.
6. The visible model-check qualification, followed by optional detailed
   checks.
7. Clearly labelled exploratory diary and nonlinear clock-time findings,
   followed by optional detailed outputs.
8. Interpretation and limitations.
9. Preregistration deviations with all four exact dynamic links.
10. A late Detailed analysis record containing exact samples, confirmatory and
    exploratory formulas, declared FDR families, source-data links, figure
    reproducibility, and subordinate technical provenance.

Move content rather than deleting it. Preserve every existing inline-R
expression, formula, prepared-object reference, and scientific numeric token.
Do not add new scientific quantities.

Move `tbl-h06-exact-samples`, both native confirmatory formula displays, and
`tbl-h06-fdr-adjustment` so that they no longer precede the main outputs.
Preserve their source pipelines, rows, order, values, captions, notes, formulas,
and identifiers.

Make `fig-h06-core-effects` the first result figure and
`tbl-h06-primary-effects` the first result table. Retain exactly the current 11
cross-referenced result table labels, two native formula-table displays, six
figure endpoints, and 20 labelled R chunks. Each endpoint and chunk label must
remain present exactly once.

Add `lightbox: true`. Do not regenerate any figure.

### Progressive disclosure

Keep the Answer in brief, principal figure, principal table, central
estimates, site-dependence conclusion, overall sensitivity conclusion,
model-check qualification, exploratory timing conclusion, interpretation, and
limitations visible.

Use exactly these disclosures for detailed material:

- `Show site-specific estimates and interaction details`
- `Show complementary placement and sensitivity results`
- `Show detailed model checks and influence analyses`
- `Show exploratory clock-time and diary analyses`
- `Show technical source and figure checks`

Preserve every endpoint label, caption, alt-text scientific statement,
source-data link, and cross-reference target. Do not hide or weaken the
previous-sleep uncertainty, day-type site/model dependence, paired-day
non-equivalence, residual/calibration qualification, exploratory status, or
pointwise-interval limitation.

### Reader vocabulary

- Keep `melanopic equivalent daylight illuminance (melEDI)` at first use.
- Describe the displayed mean as the `estimated mean hourly melEDI among
  observed hours that met the support criteria`. Do not lead with
  `expected-hour` or `supported-hour` shorthand.
- Keep near-eye measurements primary and chest measurements complementary and
  non-ocular. Do not describe either as a direct retinal measure.
- Explain participant-hour and participant-day before using the short forms.
- Explain a participant-cluster-robust 95% CI as allowing observations from
  the same participant to be related and using the HC3 small-sample
  correction. `HC3` and `95% CI` may remain thereafter.
- Use `false-discovery-rate adjustment` at first use and `FDR` thereafter.
  The full Benjamini-Hochberg method name may remain only where technical
  reproducibility requires it. Do not expose the `BH` abbreviation in reader
  prose, captions, notes, alt text, or display cells.
- Use `predictor-by-site interaction model`, explained as allowing an
  association to differ by study site. Code-only heterogeneity names may
  remain.
- Use `site-average estimate`, first explained as an average across sites that
  gives each site equal weight. Code-only equal-site names may remain.
- Use `model checks` as the reader-facing umbrella term. Display `Meets
  numerical checks`, `Verified`, or `Review needed` from the same stored raw
  states. Preserve every fail-closed calculation and assertion.
- Name what changes in each sensitivity analysis before using a short label.
- Explain the gap-timing-unaware dataset once in plain language.
- Keep the common-sample and paired-day wording exact.
- Keep `nonlinear GAM analysis` and `pointwise 95% CI` after concise first-use
  explanations.
- Keep `symlog` only after explaining that it is linear from 0 to 1 lx and
  logarithmic above 1 lx while labels remain in lux.
- Display every literal study-site name with its country code.
- Use sentence-case reader labels instead of underscore-delimited status or
  production labels. Code-only identifiers may remain.
- Replace the one reader-facing em dash with punctuation or separate
  sentences. The missing-value dash symbol may remain.

### Site, sensitivity, model-check, and exploratory displays

Retain the accepted site-dependence conclusion visibly. Place the detailed
site figure and wide table in `Show site-specific estimates and interaction
details`. Preserve all sites, estimates, intervals, p-values, FDR decisions,
source links, and the distinction between FDR site screens and unadjusted
pointwise site-to-average intervals.

Retain the required dataset-sensitivity conclusion, complementary chest role,
paired-day non-equivalence statement, and overall sensitivity conclusion
visibly. Place the detailed placement, working-variance, influence, calendar,
site-weighting, leave-one-out, Gaussian, and related outputs in `Show
complementary placement and sensitivity results`.

Retain the residual and calibration qualification visibly. Place the detailed
diagnostic table, influence results, and residual figure in `Show detailed
model checks and influence analyses`.

Retain the descriptive role of the diary summaries and the exploratory role
and pointwise limitation of the nonlinear GAM analysis visibly. Place the
detailed diary table, formula display, timing tables, and timing figures in
`Show exploratory clock-time and diary analyses`.

Place detailed figure QA and source/provenance material in `Show technical
source and figure checks`. Map `REPORT_011 PASS` and similar stored fields to
plain reader labels while preserving the underlying status and dimensions.

### Dynamic links

Preserve all existing relative dynamic QMD links, including:

- result to `../../audit/hypotheses/H06/H06_analysis_preparation.qmd`;
- both Preparation 06 links;
- the unique result anchor `#h06-preregistration-deviations`; and
- exact `DEV-015`, `DEV-030`, `DEV-031`, and `DEV-032` links to the central
  deviation page.

Add exactly one result-page link to `H06_daily.qmd`. Describe that report as
complementary participant-day evidence and explicitly retain the hourly report
as the main H06 analysis. Do not transfer a daily estimate or imply that the
hourly and daily estimands are interchangeable.

## Complete companion harmonization

Add `lightbox: true` and preserve the current top-down `flowchart TD` analysis
map, including every scientific node and edge.

Retitle the opening callout `About this analysis record`. State plainly that
the page reads accepted stored outputs for display and does not repeat model
fitting or scientific computation. Keep the reciprocal dynamic link to
`../../../notebooks/hypotheses/H06.qmd`.

Add one orientation link to
`../../../notebooks/hypotheses/H06_daily.qmd`. State that it is complementary
participant-day evidence and keep the hourly analysis primary. Do not add a
daily estimate or daily analytical detail.

Replace reader-visible workflow states `Executed` and `Not executed` with
`Read from stored records` and `Not repeated here`, or exact equivalent plain
labels. Replace displayed raw PASS/FAIL and TRUE/FALSE values with `Verified`,
`Meets numerical checks`, `Review needed`, `Yes`, or `No`, as scientifically
appropriate, while preserving raw values and fail-closed assertions in code.

Explain quasi-Poisson model, log mean, fixed site effect, participant-cluster
HC3, predictor-by-site interaction, site-average estimate,
back-transformation, nonlinear GAM, pointwise interval, and AR(1) at first
use. Keep exact formulas and full technical names in subordinate provenance.

Give every stored comparison a plain name and say what dataset, sample,
covariance correction, working variance, site weighting, calendar label,
participant, site, or response model changes. Replace raw internal role IDs,
underscore-delimited classifications, accepted/frozen production labels, and
similar machine wording in displayed cells with spaced scientific-role labels.
Keep exact paths, hashes, commands, package versions, formulas, and producer
relationships in subordinate technical provenance.

Retain exactly 30 table and three figure endpoints in the companion, each once.
Preserve every caption, alt-text scientific statement, source-data link, row,
value, and code pipeline. Do not execute the companion or introduce any new
project-side write.

## Principal and supplemental outputs

- `fig-h06-core-effects` remains the provisional main H06 figure.
- `tbl-h06-primary-effects` remains the provisional main H06 table.
- Every other result endpoint remains supporting or supplemental.
- Every output role and any small styling change remain provisional until the
  author sees the fresh focused render.
- HTML tables must work reasonably at a typical screen size. If an exported
  table PNG exists or is later produced, that PNG is the controlling exported
  table visual check.

Do not edit the phase-2 catalog in this owner order.

## Handoff refresh

Update `audit/handoffs/H06_worker_handoff.md` to record:

- final result and companion identities;
- accepted hourly-main and daily-complementary roles;
- preserved primary near-eye and complementary chest roles;
- all preserved samples, formulas, estimates, intervals, p-values, FDR
  decisions, diagnostics, sensitivities, figures, and claims;
- exact reciprocal hourly, complementary daily, Preparation 06, and deviation
  links;
- source-only verification command and result;
- preserved existing tests, manifests, stale HTML, profile, H06 daily sources,
  and scientific artifacts;
- provisional main and supplemental output roles;
- the separate four-figure label-only repair still required before rendering;
  and
- continued REPORT-017 render hold.

Do not alter H06's closed scientific status or request a new central scientific
decision.

## New source-only test and non-circular seal

Create `tests/hypotheses/H06/test_h06_report017_source_harmonization.R`. It
must require R 4.6.1 and verify, without executing either QMD:

- exact result endpoint set: 11 cross-referenced tables, two native formula
  table displays, and six figures, each once, with `fig-h06-core-effects` and
  `tbl-h06-primary-effects` first;
- exact companion endpoint set: 30 tables and three figures, each once;
- exact 20 result and 34 companion labelled chunk sets, plus preserved
  unlabeled-chunk bodies where applicable;
- every R chunk in both QMDs parses without execution;
- exact formula, inline-R, scientific numeric-token, top-level assignment,
  prepared-object reference, artifact-reference, figure-reference, and
  source-data-reference preservation, allowing only an explicit recorded
  allow-list of non-mutating display assignments and strings;
- every pre-existing formula, fitted-object reference, filter, join, ordering,
  sample, estimand, and scientific expression remains unchanged;
- exact first-endpoint order and once-only presence of every endpoint;
- reciprocal hourly QMD links, exactly one approved daily result link in each
  hourly page, Preparation 06 links, four deviation links, and all central
  anchors and source-data targets;
- no hard-coded internal HTML, build, file, absolute-local, or root-absolute
  page links;
- approved vocabulary, country-coded sites, no visible BH abbreviation,
  equal-site shorthand, unexplained heterogeneity, internal status code,
  production wording, or prose em dash;
- exact hourly-main, daily-complementary, near-eye-primary, chest-complementary,
  participant-hour, participant-day, HC3, FDR, predictor-by-site,
  site-average, paired-day, sensitivity, nonlinear GAM, pointwise interval,
  and symlog explanations;
- no fit, refit, prediction, model deserialization, bootstrap, simulation,
  resampling, p-value calculation, FDR calculation, diagnostic calculation,
  sensitivity rerun, scientific write, source-data rewrite, figure
  regeneration, or other project-side analytical call;
- the three existing H06 tests and all three current H06 report manifests
  retain their exact preflight hashes and byte counts;
- the Stage 2 manifest retains exactly its current four-path mismatch set;
- the Stage 3 manifest retains exactly its current five-path mismatch set;
- the preparation manifest retains exactly its current four-path mismatch set;
- both current HTML files remain exact stale render context and are not
  represented as revised-source acceptance;
- profile, deviation page, site registry, output catalog, H06 daily sources,
  H06 CSS, four deferred reader figures, their source CSVs and builders, and
  all protected scientific artifacts remain byte-identical; and
- no authorized path outside the two QMDs, handoff, new test, and order-37
  evidence changed.

Create a new non-circular order-37 source manifest under
`audit/hypotheses/H06/report017_order37/`. It must pin:

- final result and companion QMDs;
- final handoff and new source-only test;
- unchanged three existing H06 tests;
- unchanged three existing H06 manifests;
- unchanged current HTML files as stale render context;
- the provisional main figure and table sources, supporting figures, source
  CSVs, figure builders, and display CSS;
- consequential model, table, diagnostic, sensitivity, and reconciliation
  artifacts;
- complementary H06 daily sources as read-only hierarchy context;
- deviation page, site registry, profile, output catalog, and consolidated
  order package as read-only context; and
- bounded audit, exact diff, reverse proof, protected inventory, stored-figure
  inventory, execution record, and package versions.

Exclude the new manifest itself and every circular dependency. Do not claim
that either current HTML corresponds to the revised source.

## Deferred stored-figure repair

Do not regenerate a figure in this order. Record these four exact current PNG
identities and later label-only needs:

1. `artifacts/10_figures/H06/H06_reader_primary_effects.png`,
   `bc553dcb5dce302dc11a837d4a7a56e33cd35020b85bf0fadf8fe42603d331c9`,
   2,141 by 1,486 pixels at 320 dpi. Later replace baked `expected-hour` and
   `supported-hour` wording only.
2. `artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.png`,
   `c1c8c332a0fb75ceea95b125d0696f893db5b27503760fe7ae454715d5920dea`,
   2,141 by 1,700 pixels at 320 dpi. Later replace baked `expected-hour`,
   `equal-site`, `BH`, `heterogeneity`, and `frozen` wording only. Country-coded
   site labels are already correct.
3. `artifacts/10_figures/H06/H06_reader_temporal_day_type.png`,
   `df2322474720c7357dd5e45003bca0a85bc8afa1e5cd55d3e692c1b557214e92`,
   2,141 by 2,582 pixels at 320 dpi. Later simplify baked expected-value and
   technical footer wording only.
4. `artifacts/10_figures/H06/H06_reader_temporal_activity.png`,
   `01354dbbbb6156f8813a76a75762c82010d8c5fb0d70b5846a21725c0ed13e5c`,
   2,141 by 2,582 pixels at 320 dpi. Apply the same later label-only boundary.

The later artifact order must use the frozen source CSVs and preserve every
plotted quantity, point, interval, curve, support bar, order, symbol, colour,
facet, null line, dimension, and DPI. It will require exact pre/post identities,
normalized SVG or pixel-region comparison, and final-size visual QA. It must
not fit a model or calculate any scientific quantity.

## Verification

After the complete source revision is assembled, run this suite once under R
4.6.1:

1. New `tests/hypotheses/H06/test_h06_report017_source_harmonization.R`.
2. Parse every R chunk in both QMDs without executing it.
3. Compare pre/post endpoint labels, formulas, inline R, top-level assignments,
   prepared-object references, artifact references, figure references,
   source-data references, and scientific numeric tokens using only the
   explicit editorial allow-list.
4. Verify exact first-endpoint order and once-only presence of every endpoint.
5. Verify all reciprocal hourly links, two complementary-daily orientation
   links, Preparation 06 links, four registration links and central anchors,
   and source-data targets.
6. Verify all protected scientific and display artifacts byte-for-byte.
7. Verify the three existing tests, three existing manifests, two stale HTML
   files, profile, site registry, deviation page, output catalog, H06 daily
   sources, display CSS, and all builders are byte-identical.
8. Audit every row in the new non-circular source manifest.
9. Run scoped `git diff --check`.

Do not run preliminary project tests. The new test should report all failures
together where feasible. If it fails, stop without patching or rerunning and
return one consolidated defect list.

Record exact commands, R and consequential package versions, runtimes,
pre/post identities, stopped attempts, and preservation results. Return one
self-contained handoff.

Do not run the Stage 2 scientific test or the render-coupled Stage 3 and
preparation tests in this source-only order. They remain accepted historical
and later-render contracts.

## Prohibited work

Do not run Quarto or execute either QMD. Do not fit, refit, predict, simulate,
bootstrap, resample, rerun model checks, recalculate p-values, regenerate
figures, rewrite source data, or modify scientific artifacts. Do not edit
`_quarto-nathealth.yml`, the semantic hook, `phase4_corpus_manifest.csv`, output
catalog, coordination matrix, search or sitemap files, any `_build` path,
central ledgers or decisions, manuscript files, packages, `renv.lock`, H06
daily, another hypothesis, or a shared file. Do not commit or push.

Stop after source-only evidence for independent harmonizer acceptance. A later
serial gate will separately authorize the four-figure label-only repair, then
one H06 result render and one H06 companion render followed by one combined
semantic and visual review.
