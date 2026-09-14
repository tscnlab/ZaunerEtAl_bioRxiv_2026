# H06 hourly analysis source-only handoff

Date: 2026-08-14

Status: the four-stage main hourly H06 scientific workflow remains closed and
unchanged. REPORT-014/017 order 37 stopped at its source-only verifier with 17
sealed assertions. Order 37a restores one accepted visible `p = 0.298`
sentence and corrects those verifier classifications without changing the
analysis. Rendering remains on hold pending the separate four-figure label
repair and serial render authorization.

## Final source identities

- `notebooks/hypotheses/H06.qmd`: SHA-256
  `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`,
  60,677 bytes.
- `audit/hypotheses/H06/H06_analysis_preparation.qmd`: SHA-256
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
  59,613 bytes.

These are source identities only. The existing result and companion HTML
files remain stale render context and do not represent the revised sources.

## Analysis hierarchy and preserved scientific roles

The hourly analysis remains the main H06 result. The separate
`notebooks/hypotheses/H06_daily.qmd` report remains complementary
participant-day evidence. The two estimands are related but not
interchangeable, and no estimate moved between them.

The main hourly outcome remains the zero-aware geometric mean melEDI for each
retained participant-hour. Near-eye measurements remain primary. Chest
measurements remain complementary non-ocular evidence. Neither position is a
direct retinal measure.

The primary frame remains exactly 16,596 supported hours, 715
participant-days, 137 participants, and nine study sites. The primary model
continues to estimate an average over retained participant-hours, so days with
more retained hours receive more weight.

## Preserved models, inference, and findings

The two confirmatory Wilkinson formulas remain exact:

```text
response_value ~ site + work_free_day + activity_status + previous_sleep_duration_centered_h
response_value ~ site * work_free_day + site * activity_status + site * previous_sleep_duration_centered_h
```

The log-mean quasi-Poisson specification, fixed site terms,
participant-cluster HC3 covariance, finite-participant inference,
predictor-by-site interaction tests, site-average contrasts, and one-time
back-transformation remain unchanged. The declared FDR families remain the
three primary common-effect tests, three predictor-by-site interaction tests,
three practical contrasts, and the separate nine-site families used for each
exploratory site screen.

The primary near-eye estimates remain:

- free versus work day: ratio 1.45, 95% CI 1.14 to 1.85, FDR-adjusted
  p = 0.004;
- active versus sedentary day status: ratio 2.06, 95% CI 1.54 to 2.76,
  FDR-adjusted p < 0.001; and
- per one additional hour of previous sleep: ratio 0.98, 95% CI 0.85 to
  1.12, FDR-adjusted p = 0.745.

The work/free predictor-by-site interaction remains FDR-retained at
p = 0.017. Activity and previous sleep retain no FDR-adjusted
predictor-by-site interaction. The interaction-model site-average ratios
remain 1.15 for free/work, 1.93 for active/sedentary, and 0.97 per additional
hour of previous sleep. The interaction model's site-average day-type
association did not meet the adjusted threshold (three-predictor FDR-adjusted
p = 0.298). The site screen still compares each site's ratio with 1, while the
separate pointwise site-to-average intervals compare each site with the
site-average estimate. The free/work associations at Borås (SE) and Dortmund
(DE), and the active/sedentary association at Tübingen (DE), remain retained
in their separate nine-site FDR families.

The required gap-timing-unaware sensitivity remains exact. Its near-eye frame
contains 16,329 hours, 702 participant-days, 137 participants, and nine sites.
The near-eye ratios remain 1.44, 2.08, and 0.96. On the exact common-hour
frame, all 16,329 hour keys remain and 12 response values differ.

The complementary all-available chest ratios remain 1.51, 1.81, and 0.95.
The paired-day comparison remains restricted to the same 109 participants and
553 participant-days at both positions, with 12,842 participant-hours in each
frame. Three hourly keys differ at each position. It is not an
observation-level identity comparison, equivalence analysis, or direct
placement effect.

Changing the working variance to fixed power 1.8 still gives ratios 1.15,
1.91, and 0.95, with FDR-adjusted p-values 0.260, < 0.001, and 0.260. The HC1,
HC2, site-weighting, calendar-label, participant-deletion, site-deletion, and
Gaussian response checks remain unchanged. Day type remains site- and
model-dependent.

All stored fits retain their numerical convergence, rank, and HC3 covariance
checks. The response still has 28.3% exact-zero hours, dispersion 3,618,
fitted-decile observed/fitted ratios from 0.78 to 1.61, and residual
correlations of 0.464 at lag 1, 0.233 at lag 2, and 0.013 at lag 6. These
qualify the working mean and residual structure without changing the reported
participant-cluster-robust intervals.

The exploratory nonlinear timing analysis remains a two-part binomial-logit
occurrence and Gamma-log positive-magnitude GAM, with four cyclic factor-by
clock smooths, parametric site adjustment, participant and participant-day
random-effect smooths, true-sequence `AR.start`, fixed working residual
correlations, `k = 16`, `fREML`, and `discrete = TRUE`. It retains no `sz`
component and no site-specific clock smooth. Its response-scale contrasts,
pointwise intervals, occurrence calibration, basis warning, omitted
cross-component covariance, and lack of simultaneous or multiplicity-controlled
whole-curve inference remain unchanged. The reported local windows remain
07:15 to 19:00 and 23:30 to 05:15 for activity, and 06:45 to 09:15 and 18:45
to 19:15 for day type.

All samples, estimates, intervals, p-values, FDR decisions, diagnostics,
sensitivities, source-data rows, stored figures, and scientific claims remain
unchanged.

## Reader and preparation source changes

The result now begins with the provisional principal figure
`fig-h06-core-effects`, immediately followed by the provisional principal
table `tbl-h06-primary-effects`. Exact samples, formulas, FDR families, and
technical figure checks remain available in the late detailed analysis
record. Site-specific, sensitivity, model-check, exploratory, and technical
details use progressive disclosures without dropping any endpoint.

The result retains exactly 11 cross-referenced tables, two native formula
displays, six figures, and 20 labelled R chunks. The companion retains exactly
30 tables, three figures, 34 labelled R chunks, and the complete `flowchart TD`
map. Both sources add `lightbox: true`. No QMD was executed and no figure was
regenerated.

The companion now presents stored workflow and check states in reader terms,
including `Read from stored records`, `Not repeated here`, `Verified`, `Meets
numerical checks`, `Review needed`, `Yes`, and `No`. Raw values and fail-closed
assertions remain in code.

## Dynamic links

The exact source links remain:

- result to companion:
  `../../audit/hypotheses/H06/H06_analysis_preparation.qmd`;
- companion to result:
  `../../../notebooks/hypotheses/H06.qmd`;
- result to complementary daily evidence: `H06_daily.qmd`;
- companion to complementary daily evidence:
  `../../../notebooks/hypotheses/H06_daily.qmd`;
- result to Preparation 06:
  `../preparation/06_model_ready_datasets.qmd`;
- companion to Preparation 06:
  `../../../notebooks/preparation/06_model_ready_datasets.qmd`; and
- the exact `DEV-015`, `DEV-030`, `DEV-031`, and `DEV-032` targets on
  `notebooks/preregistration_deviations.qmd`.

The result anchor `#h06-preregistration-deviations` remains unique. No internal
HTML, build, file, absolute-local, or root-absolute page link was added.

## Source-only verification and preservation

The one-shot verification command is:

```sh
Rscript tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R
```

Order 37 previously evaluated 171 checks and stopped with 17 defects in
`audit/hypotheses/H06/report017_order37/defect_list.csv`. Sixteen were verifier
classifications. The one source-preservation defect was the missing accepted
`p = 0.298` sentence restored above. The preceding sandboxed startup process
never entered the verifier body; after its authorized environment retry, the
real order-37 verifier sealed in about two seconds.

The controlling order-37a result is `PASS`, as sealed by
`audit/hypotheses/H06/report017_order37a/execution_record.md`. If the one-shot
37a suite does not reach `PASS`, this handoff is invalid and its consolidated
stopped-state defect list controls. The suite requires R 4.6.1, parses every R
chunk without execution, audits endpoints, source structure, dynamic links,
reader vocabulary, the exact restored numeric inventory, protected hashes,
historical manifest mismatch sets, two-step reverse substitution, and the new
non-circular source manifest.

The following remain byte-identical to their order-37 preflight identities:

- `tests/hypotheses/H06/test_h06_stage2.R`;
- `tests/hypotheses/H06/test_h06_stage3.R`;
- `tests/hypotheses/H06/test_h06_preparation_report.R`;
- the Stage 2, Stage 3, and preparation report manifests;
- both stale H06 HTML files;
- `_quarto-nathealth.yml`, the deviation page, site registry, output catalog,
  H06 CSS, and both H06 daily sources;
- all scientific models, tables, diagnostics, sensitivities, reconciliation
  evidence, stored figures, source CSVs, and figure builders pinned by the
  order-37 source manifest.

The stopped order-37 verifier and every file under
`audit/hypotheses/H06/report017_order37/` also remain byte-identical historical
evidence. The companion QMD remains byte-identical at
`f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`.

The historical manifest mismatch sets remain exactly 4, 5, and 4 paths for
Stage 2, Stage 3, and preparation, respectively. These are historical
identity differences, not new scientific discrepancies.

## Provisional output roles and deferred work

`fig-h06-core-effects` remains the provisional principal H06 figure and
`tbl-h06-primary-effects` remains the provisional principal H06 table. Every
other result endpoint remains supporting or supplemental until the author
reviews a fresh focused render.

Four stored figures still require the separately authorized label-only repair
before rendering:

- `H06_reader_primary_effects.png`, SHA-256
  `bc553dcb5dce302dc11a837d4a7a56e33cd35020b85bf0fadf8fe42603d331c9`;
- `H06_stage3_site_specific_significance_screen.png`, SHA-256
  `c1c8c332a0fb75ceea95b125d0696f893db5b27503760fe7ae454715d5920dea`;
- `H06_reader_temporal_day_type.png`, SHA-256
  `df2322474720c7357dd5e45003bca0a85bc8afa1e5cd55d3e692c1b557214e92`;
- `H06_reader_temporal_activity.png`, SHA-256
  `01354dbbbb6156f8813a76a75762c82010d8c5fb0d70b5846a21725c0ed13e5c`.

That later order may change baked labels only. It must preserve every plotted
quantity, interval, curve, support bar, order, symbol, colour, facet, null
line, dimension, and DPI. REPORT-017 continues to hold the result and
companion renders until that artifact repair and a separate serial release.

No shared file, H06 daily file, scientific artifact, existing test, existing
manifest, build output, package, lockfile, central record, manuscript file, or
other hypothesis was changed by order 37. No commit or push was performed.

## Near-eye employment-eligibility sensitivity

The author requested one additional sensitivity that removes participants who
fall outside the registered employment requirement, limited to the near-eye
sample. The controlling scenario is `H06-S-EMP-NE`. It changes only
employment eligibility and preserves the accepted supported-hour outcome,
predictors, coding, sites, formulas, equal-site standardization,
quasi-Poisson log mean, participant-cluster HC3 covariance, finite-cluster
degrees of freedom, confidence level, and three-member FDR families.

The restriction excludes only participants recorded as `Not employed` or
`Marginally employed (Minijob)`. Students and trainees remain eligible solely
on that status, and age above 65 years is not an exclusion rule. Six
participants were removed: four recorded as marginally employed and two as not
employed. The frozen primary near-eye sample contained 16,596 supported hours,
715 participant-days, 137 participants, and nine sites. The restricted sample
contains 15,871 supported hours, 684 participant-days, 131 participants, and
all nine sites. The smallest retained site-by-day-type and site-by-activity
cells contain 187 and 180 supported hours.

The restricted common-effect estimates are:

- Free day versus work day: ratio 1.46, 95% CI 1.11–1.91, FDR-adjusted
  p = 0.010.
- Active versus sedentary: ratio 1.88, 95% CI 1.42–2.48, FDR-adjusted
  p < 0.001.
- Previous sleep duration per additional hour: ratio 0.95, 95% CI 0.83–1.09,
  FDR-adjusted p = 0.437.

All three comparisons with the frozen primary sample are classified as
`stable within model uncertainty`. Day-type predictor-by-site heterogeneity
remains FDR-supported, changing from F(8, 136) = 2.87, adjusted p = 0.017, to
F(8, 130) = 3.59, adjusted p = 0.003. Activity and previous-sleep
predictor-by-site tests remain unsupported. All nine day-type and all nine
activity site summaries are stable. Eight of nine previous-sleep summaries
are stable. Kumasi is precision-sensitive because its descriptive pointwise
sleep interval changes from 0.73–1.14 to 0.70–0.95; this adds no multiplicity
family and does not change the overall sleep conclusion.

Both restricted models converged, retained full-rank designs, and produced
finite positive-definite HC3 covariance matrices. The numerical gate passed
for both. Residual mean-variance structure and within-person temporal
correlation remain similar to the accepted primary model and continue to
qualify interpretation.

The isolated report pair is:

- `audit/hypotheses/H06/employment_eligibility_sensitivity/H06_employment_eligibility_sensitivity.qmd`,
  SHA-256
  `199808d90b0c282b64fe5fba4706bec4845f8f79a73e4365c471cb05ada4e80f`;
- `audit/hypotheses/H06/employment_eligibility_sensitivity/H06_employment_eligibility_sensitivity.html`,
  SHA-256
  `4abe8a146f716a170b3fc9ea1a54aefe246b438a2a784c43cd855ce0570bdb98`.

The scientific implementation ran once under the normal R 4.6.1 project
profile after an initial package-path startup stop that read no data, fit no
model, and wrote no output. The focused scientific verifier passed. The one
authorized Quarto render succeeded but correctly routed the unregistered
audit target beside its QMD rather than into the Nature Health build tree. Its
raw HTML identity was
`1f2f3cf75fff0200c5653763676cd92d9a6139d05e8095979764f9bfdafc394c`.
No rerender was performed.

The accepted gt semantic engine repaired only generated table IDs and header
references in a candidate made from the raw evidence copy. It preserved nine
native tables, changed 51 ID values and 276 `headers` values, and exactly
reversed to the raw HTML identity. Visible text, links, cells, element order,
and all non-`id`/non-`headers` DOM remained unchanged. The report verifier
passed 31 of 31 checks. Desktop, 170-mm-equivalent narrow, and
200%-equivalent QA passed for all nine tables. The smallest essential table
text is 10 CSS px, equivalent to 7.5 pt. The two widest tables use contained
horizontal scrolling at narrow widths, with no page-level overflow. The
isolated loopback server exposed only the immutable HTML, was stopped, and no
listener remained.

The 46-member non-circular return manifest is
`artifacts/12_manifests/H06/employment_eligibility_sensitivity/H06_employment_eligibility_report_manifest.csv`,
SHA-256
`aa820c8d2df6bf19db9141141220c722ca5b88862d172c1d0b947c9835fc1ed9`.
The complete Nature Health build inventory, accepted main H06 result and
preparation pages, H06 daily files, source data, shared configuration,
ledgers, package state, and lockfile remain unchanged.

This work stops at `H06-S-EMP-NE-REVIEW`. The sensitivity is not integrated
into the accepted main H06 result or preparation report until independent
scientific and author approval.

## Employment-eligibility acceptance and reader-source integration

The author explicitly accepted the near-eye employment-eligibility sensitivity
on 2026-09-02 and requested integration into the reader-facing H06 Quarto
documents. The accepted result package and its scientific classifications are
unchanged. The Writer task, `019ffb39-372e-7262-bfac-192751fd0e63`, received
the exact sample, effects, heterogeneity result, scope, qualifications, and
manuscript-safe wording. The Writer integrated the accepted sensitivity into
its owned Nature Health manuscript source.

The main hourly result source now gives the sensitivity a short visible
qualification and a detailed near-eye-only subsection with the exact sample,
three primary ratios and 95% CIs, adjusted p-values, stability classification,
day-type heterogeneity result, diagnostic qualification, and links to the
stored CSVs. The preparation/provenance source now
records the eligibility rule, sample flow, unchanged model and inference
contract, stored comparison, diagnostic qualification, and reproducibility
links. It states explicitly that the sensitivity was not repeated for chest.
No H06 daily source is referenced or changed by this integration.

Protected source identities changed only as follows:

- `notebooks/hypotheses/H06.qmd`: pre-edit SHA-256
  `013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a`;
  post-edit SHA-256
  `5f8ec988d680e1a3e3dbf2410f0d4e6a49ded80a9990b3a09661aebdc98cbd4e`.
- `audit/hypotheses/H06/H06_analysis_preparation.qmd`: pre-edit SHA-256
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`;
  post-edit SHA-256
  `5b128499a1f1a9312089ec47dfd1ba30cebb2a31059608659c0aa464753abfa0`.

The new source-only verifier is
`tests/hypotheses/H06/employment_eligibility_sensitivity/test_h06_employment_eligibility_reader_integration.R`,
SHA-256
`aa3031f939f0d4ac5f0621e60e18c32fbe5e9716a8fa577a94d2582a620892b0`.
Under R 4.6.1 it passed the exact source tokens, dynamic links, QMD R-chunk
parsing, stored sample counts, all three effect estimates and stability
classifications, and day-type heterogeneity values. `git diff --check` passes
for the tracked result source, and an explicit trailing-whitespace scan passes
for both QMDs and the new verifier.

No model was fit or refit, no scientific quantity was recomputed, and no
artifact, figure, shared configuration, ledger, manuscript, H06 daily file,
package, or lockfile was changed by the H06 reader-source integration. The
current result and preparation HTML files remain unchanged. A serial render
and page-level visual inspection remain held pending an explicit REPORT-018
render release.
