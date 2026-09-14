# REPORT-017 H06 consolidated full-document audit

Date: 2026-08-14

Status: complete read-only source audit; one consolidated source-only owner order is appropriate; all H06 rendering remains held

## Controlling boundary

This audit follows REPORT-014, REPORT-016, REPORT-017, the accepted hourly H06 scientific closure, the current site-display registry, and the consolidated-document-pass protocol. The hourly analysis remains the main H06 result. The accepted H06 daily analysis is complementary and estimates a different participant-day quantity.

The audit covers the complete hourly result report, its preparation and provenance companion, every reader-facing table and figure display, both directly dependent reporting tests, the Stage 2 scientific test as protected context, all three current H06 manifests, dynamic links, the complete owner handoff, the current rendered pages, and provisional main and supplemental output roles.

No data, model, estimate, interval, p-value, model check, sensitivity, FDR decision, sample definition, table, figure, source-data file, or scientific artifact was changed. No Quarto render or scientific analysis was run. Structural inventories, source reading, link checks, checksums, PDF text extraction, and image inspection were non-analytical. H06 remains scientifically closed.

## Reviewed identities

- Result source: `notebooks/hypotheses/H06.qmd`, SHA-256 `692c28ce165eda27e0b85dbb73f2e834a31a188ae8eefe9f1391980bd5641459`, 56,355 bytes.
- Companion source: `audit/hypotheses/H06/H06_analysis_preparation.qmd`, SHA-256 `205eac1ee6d878353a2b23c3741e18ef7480765882d6e0baad0808963b3aa731`, 55,895 bytes.
- Current result HTML: `_build/nathealth/notebooks/hypotheses/H06.html`, SHA-256 `ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`, 6,109,797 bytes.
- Current companion HTML: `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html`, SHA-256 `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`, 771,694 bytes.
- Stage 2 scientific test: `tests/hypotheses/H06/test_h06_stage2.R`, SHA-256 `489115354c11de17b627e4e2cb28cef9f54654a50756a7d4897dda3080b29b89`, 15,916 bytes.
- Stage 3 reporting test: `tests/hypotheses/H06/test_h06_stage3.R`, SHA-256 `a6e3e307b023588b475587876be86eeb9c0f7b9d9d1597df946dd112458940aa`, 35,771 bytes.
- Preparation test: `tests/hypotheses/H06/test_h06_preparation_report.R`, SHA-256 `2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc`, 12,918 bytes.
- Stage 2 manifest: `artifacts/12_manifests/H06/H06_stage2_artifacts.csv`, SHA-256 `2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752`, 227 data rows.
- Stage 3 manifest: `artifacts/12_manifests/H06/H06_stage3_artifacts.csv`, SHA-256 `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21`, 301 data rows.
- Preparation manifest: `artifacts/12_manifests/H06/H06_preparation_report_manifest.csv`, SHA-256 `db976477b9cdbce2a6d4575e382b2f04062e8834c086f1d82cb25d7e8a2176e4`, 315 data rows.
- Owner handoff: `audit/handoffs/H06_worker_handoff.md`, SHA-256 `5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829`, 24,781 bytes.
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Phase 2 output catalog: `audit/report_harmonization/phase2_main_supplement_output_catalog.csv`, SHA-256 `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`.
- Central deviation page: `notebooks/preregistration_deviations.qmd`, SHA-256 `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.
- Site display registry: `config/site_display_registry.csv`, SHA-256 `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.

The result and companion, both focused reporting tests, and the complete handoff were read in full. The result contains 20 labelled R chunks, 11 cross-referenced native table displays, two additional native formula-table displays, and six figure endpoints. The companion contains 34 labelled R chunks, 30 native table endpoints, and three figure endpoints. Every current chunk parses structurally without execution.

The three manifests are accepted historical records. Their exact current mismatch sets are:

- Stage 2, four paths: `audit/handoffs/H06_shared_change_request.md`, `audit/handoffs/H06_worker_handoff.md`, `scripts/hypotheses/H06/h06_contract.R`, and `tests/hypotheses/H06/test_h06_stage2.R`.
- Stage 3, five paths: `scripts/hypotheses/H06/h06_contract.R`, `audit/handoffs/H06_shared_change_request.md`, `audit/handoffs/H06_worker_handoff.md`, `_build/nathealth/notebooks/hypotheses/H06.html`, and `notebooks/hypotheses/H06.qmd`.
- Preparation, four paths: `_quarto-nathealth.yml`, `artifacts/12_manifests/base_model_data_artifacts.csv`, `audit/hypotheses/H06/H06_analysis_preparation.qmd`, and `notebooks/hypotheses/H06.qmd`.

These manifests and both current HTML files should remain byte-identical in the source-only order. They are historical or stale-render context and must not be represented as final integration evidence for revised sources.

## Scientific result boundary

The primary outcome remains the zero-aware geometric mean melEDI for each retained participant-hour. The near-eye sensor position is primary because it is closer to ocular light exposure. The chest sensor position is complementary and represents non-ocular exposure.

The primary near-eye frame remains 16,596 supported hours from 715 participant-days, 137 participants, and nine sites. The three primary average associations remain:

- free versus work day, ratio 1.45, 95% CI 1.14 to 1.85, FDR-adjusted p = 0.004;
- active versus sedentary status, ratio 2.06, 95% CI 1.54 to 2.76, FDR-adjusted p < 0.001; and
- one additional hour of previous sleep, ratio 0.98, 95% CI 0.85 to 1.12, FDR-adjusted p = 0.745.

The predictor-by-site interaction, alternative working variance, and leave-one-site-out checks continue to qualify the day-type finding. The activity association remains the most stable result. The previous-sleep interval remains compatible with a modest decrease or increase and does not establish absence of an association.

All FDR families remain exact. Site-specific screens remain exploratory and compare each site's ratio with 1, not with another site or the site-average estimate. Pointwise site-to-average intervals remain unadjusted. The gap-timing-unaware comparison, paired-day comparison, complementary chest estimates, covariance checks, working-variance check, calendar-label check, influence checks, and Gaussian log-scale response check retain their accepted roles.

The nonlinear GAM analysis remains exploratory timing context. Its pointwise intervals apply at one displayed hour and are neither simultaneous bands nor multiplicity-controlled whole-curve tests. All formulas, samples, support definitions, estimates, intervals, p-values, FDR decisions, residual summaries, sensitivities, source-data rows, and claims must remain unchanged.

## Result-report findings

### Information hierarchy

The scientific question and Answer in brief are accurate. The central result is delayed, however, because the exact-sample table, two formula displays, and FDR-family table precede the principal figure and table. Detailed site, sensitivity, model-check, diary, clock-time, and figure-QA outputs are always expanded. The page reads as an analysis dossier before it reads as a result report.

The coherent target order is:

1. Scientific question, hourly-main versus daily-complementary orientation, preparation link, and concise Answer in brief.
2. A short reader orientation defining melEDI, participant-hour, participant-day, primary near-eye and complementary chest roles, comparison directions, 95% CI, participant-cluster HC3, FDR, predictor-by-site interaction, site-average estimate, and sensitivity analysis.
3. Principal hourly result, beginning with `fig-h06-core-effects`, followed immediately by `tbl-h06-primary-effects` and its interpretation.
4. The visible conclusion about predictor-by-site interactions and site dependence, with detailed site outputs available on request.
5. The visible conclusion from required dataset, complementary chest, paired-day, working-variance, and influence analyses, with detailed displays available on request.
6. The visible model-check qualification, with the detailed table and residual figure available on request.
7. Clearly labelled exploratory diary and nonlinear clock-time findings, with detailed formula, table, and figure displays available on request.
8. Interpretation and limitations.
9. Preregistration deviations and exact dynamic links.
10. A late Detailed analysis record containing exact samples, formulas, declared FDR families, source-data links, figure reproducibility, and technical provenance.

This makes `fig-h06-core-effects` the first result figure and `tbl-h06-primary-effects` the first result table. Every other current endpoint remains present exactly once.

### Vocabulary and prose

- Keep `melanopic equivalent daylight illuminance (melEDI)` at first use.
- Use `estimated mean hourly melEDI among observed hours that met the support criteria` instead of leading with `expected-hour` or `supported-hour` shorthand.
- Keep near-eye as the primary position and chest as complementary non-ocular evidence. Do not call either a direct retinal measure.
- Explain participant-hour and participant-day before using the short terms alone.
- Explain a participant-cluster-robust 95% CI as allowing observations from the same participant to be related and using the HC3 small-sample correction. `HC3` and `95% CI` may remain thereafter.
- Use false-discovery-rate adjustment at first use and FDR thereafter. The full Benjamini-Hochberg method name may remain only where technical reproducibility requires it. Do not expose the BH abbreviation in reader prose, captions, notes, or alt text.
- Use predictor-by-site interaction model, explained as allowing an association to differ by study site. Code-only heterogeneity object names may remain.
- Use site-average estimate, first explained as an average across sites that gives each site equal weight. Code-only equal-site field names may remain.
- Use model checks as the reader-facing umbrella term. Replace visible PASS/FAIL and bare TRUE/FALSE states with `Verified`, `Meets numerical checks`, or `Review needed`, as appropriate, while keeping fail-closed stored checks in code.
- Keep sensitivity-analysis names only after stating what dataset, sample, covariance correction, site weighting, response model, calendar label, participant, or site is changed.
- Explain the gap-timing-unaware dataset once in plain language. The short term may remain thereafter.
- Keep common-sample and paired-day language exact. The same participants and participant-days are used at both sensor positions, but three hourly keys differ at each position. This is not an observation-level identity comparison, equivalence analysis, or direct placement effect.
- Keep nonlinear GAM analysis and pointwise 95% CI after concise first-use explanations.
- Keep symlog after explaining that it is linear from 0 to 1 lx and logarithmic above 1 lx while labels remain in lux.
- Every literal study-site name must retain its country code.
- Replace the one prose em dash with commas or separate sentences. The missing-value dash symbol may remain.

### Progressive disclosure

Keep the Answer in brief, principal figure, principal table, central estimates, site-dependence conclusion, overall sensitivity conclusion, model-check qualification, exploratory timing conclusion, and limitations visible.

Use exactly these disclosures for detailed material:

- `Show site-specific estimates and interaction details`
- `Show complementary placement and sensitivity results`
- `Show detailed model checks and influence analyses`
- `Show exploratory clock-time and diary analyses`
- `Show technical source and figure checks`

Move the exact-sample table, both formula displays, and the FDR-family table to the late Detailed analysis record. Preserve all labels, captions, alt text, source links, formulas, table pipelines, and cross-reference targets.

### Cross-links

The result and companion already use relative dynamic QMD links, and all four deviation anchors resolve. Retain both reciprocal hourly links, Preparation 06 links, and the exact `DEV-015`, `DEV-030`, `DEV-031`, and `DEV-032` targets.

Now that H06 daily Stage 3 and Stage 4 are accepted and registered, add one reciprocal reader link from the hourly result to `H06_daily.qmd`. Describe that page as complementary participant-day evidence and keep the hourly analysis explicitly primary. The companion may link to the same daily result for orientation. Do not merge results, transfer estimates, or imply that the analyses are interchangeable.

### Principal and supplemental outputs

- `fig-h06-core-effects` remains the provisional main H06 figure. Its stored PNG is 2,141 by 1,486 pixels at 320 dpi, SHA-256 `bc553dcb5dce302dc11a837d4a7a56e33cd35020b85bf0fadf8fe42603d331c9`. Preserve all 18 plotted effect rows, estimates, intervals, order, symbols, colours, facets, null lines, dimensions, and DPI.
- `tbl-h06-primary-effects` remains the provisional main H06 table. Preserve its three rows, order, directions, ratios, 95% CIs, FDR-adjusted p-values, decisions, native gt construction, caption, and notes.
- Every other result table and figure remains supporting or supplemental.
- All output roles remain provisional until the author sees the fresh focused render.
- HTML tables must work reasonably at a typical screen size. If an exported table PNG exists or is later produced, that PNG is the controlling exported-table visual check.

## Stored-figure wording inventory

Static original-size inspection and PDF text extraction identified four current reader figures that require a later, separate label-only refresh. This corrects the older coordination note that counted three PNGs.

1. `H06_reader_primary_effects.png`, SHA-256 `bc553dcb5dce302dc11a837d4a7a56e33cd35020b85bf0fadf8fe42603d331c9`, 2,141 by 1,486 pixels at 320 dpi. Replace baked `expected-hour` and `supported-hour` wording with the approved mean-hourly description.
2. `H06_stage3_site_specific_significance_screen.png`, SHA-256 `c1c8c332a0fb75ceea95b125d0696f893db5b27503760fe7ae454715d5920dea`, 2,141 by 1,700 pixels at 320 dpi. Replace baked `expected-hour`, `equal-site`, `BH`, `heterogeneity`, and `frozen` wording with mean-hourly, site-average, FDR, predictor-by-site, and current-model wording. All site names already carry country codes.
3. `H06_reader_temporal_day_type.png`, SHA-256 `df2322474720c7357dd5e45003bca0a85bc8afa1e5cd55d3e692c1b557214e92`, 2,141 by 2,582 pixels at 320 dpi. Simplify baked expected-value and technical footer wording to the approved exploratory nonlinear GAM and pointwise-interval explanation.
4. `H06_reader_temporal_activity.png`, SHA-256 `01354dbbbb6156f8813a76a75762c82010d8c5fb0d70b5846a21725c0ed13e5c`, 2,141 by 2,582 pixels at 320 dpi. Apply the same bounded terminology repair as the day-type figure.

The shared reader-display builder and the site-screen builder, all paired PDFs and SVGs, and all frozen source CSVs must remain byte-identical in this source-only order. A later artifact order may change labels only, with exact pre/post identities, normalized SVG or pixel-region preservation, and final-size visual QA. It must not fit a model or recalculate any plotted quantity.

## Companion findings

The companion is scientifically faithful and already separates the hourly common-effect analysis, predictor-by-site interaction analysis, model checks, named sensitivities, and exploratory nonlinear clock-time analysis. It also correctly explains participant-hour weighting, previous-night linkage, true-time sequences, site support, residual correlation, and the paired-day limitation.

The remaining repairs are reader-facing and structural:

- Add `lightbox: true`.
- Retitle the opening callout `About this analysis record` and keep the no-recomputation boundary concise.
- Keep the top-down analysis map and reciprocal hourly result link.
- Add a short orientation link to the complementary daily result without importing any daily estimate.
- Replace visible `Executed` and `Not executed` workflow states with reader descriptions such as `Read from stored records` and `Not repeated here`.
- Display stored verification booleans and PASS/FAIL states as `Verified`, `Meets numerical checks`, or `Review needed`, while preserving the raw values and all fail-closed assertions in code.
- Replace visible internal role IDs, underscore-delimited stability classifications, and raw provenance labels with spaced plain-language labels.
- Replace `Accepted model bundle` and similar historical labels with current scientific-role descriptions. Keep exact paths, hashes, package names, formulas, and commands only in subordinate technical provenance.
- Keep the complete 30-table and three-figure endpoint sets. Use bounded disclosures for exact identities, code maps, output inventories, environment details, and reproduction instructions where this materially improves scanning.
- Preserve all three preparation figures, their alt text, captions, source-data links, dimensions, and source values.

## Source-test and provenance strategy

The current Stage 3 and preparation tests are render-coupled and retain historical HTML, gate, BH, equal-site, and hard-coded HTML-link expectations. Editing them during another source rewrite would create the same avoidable transition loops already encountered elsewhere. The source-only order should therefore:

1. Preserve the Stage 2, Stage 3, and preparation tests byte-for-byte.
2. Preserve all three current H06 manifests byte-for-byte.
3. Add one new H06-owned source-only harmonization test that validates both revised QMDs, every endpoint, first-endpoint order, formulas, scientific tokens, dynamic links and anchors, country-coded sites, approved vocabulary, no scientific calls, exact historical-manifest mismatch sets, and protected scientific identities.
4. Add one bounded non-circular H06 source manifest that pins the final QMDs, new source-only test, unchanged existing tests and manifests, handoff, current HTML as stale context, provisional main and supplemental outputs, four deferred display artifacts, source-data files, profile context, and order evidence. It must not claim that either HTML corresponds to revised source.
5. Run the new source-only test once under R 4.6.1 after the complete rewrite is assembled. Parse every R chunk without executing it. Do not run the scientific Stage 2 test or the render-coupled Stage 3 and preparation tests in this source-only order.

The test should preserve every pre-existing top-level scientific assignment, inline-R expression, formula, prepared-object reference, numeric token, artifact path, table and figure ID, caption, alt-text scientific statement, and source-data target. It may allow only an explicit recorded set of reader-display strings, disclosure wrappers, dynamic daily links, and non-mutating display mappings. It must fail on any added fit, refit, prediction, model loading, p-value calculation, FDR calculation, residual calculation, sensitivity rerun, scientific write, or artifact regeneration.

## Current render disposition

The current result and companion HTML files predate this consolidated hierarchy and terminology pass. They remain stale render context, not final visual evidence.

After independent source acceptance and a separately accepted label-only repair of the four baked figure families, H06 should receive exactly one result render and one companion render in the serial REPORT-017 queue. Review both pages together for semantic tables, links, endpoint numbering, disclosures, lightbox behavior, main-figure and main-table readability, desktop and narrow layout, exported figure quality, and protected scientific identities. Collect every newly exposed display defect before one combined correction order.

## Disposition

No scientific discrepancy blocks H06. One consolidated source-only owner order may proceed after exact owner-scoped preflight. It must not render, edit the shared profile, touch the semantic hook, modify build outputs, change central or harmonizer-wide files, edit H06 daily, regenerate figures, or run scientific computation. The owner should implement the complete matrix once, run the one source-only suite once after all edits, and stop for independent acceptance.
