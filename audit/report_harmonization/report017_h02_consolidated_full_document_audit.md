# REPORT-017 H02 consolidated full-document audit

Date: 2026-08-14

Status: complete read-only source audit; one consolidated source-only owner order is appropriate; H02 rendering remains held

## Controlling boundary

This audit follows REPORT-014, REPORT-016, REPORT-017, the author-approved vocabulary and structural template, and the consolidated-document-pass protocol. It covers the complete H02 result report, its preparation and provenance companion, all reader-facing table and figure endpoints, directly dependent source and rendered-report tests, H02 manifests, dynamic links, provisional output roles, and the current owner handoff.

No data, model, estimate, interval, p-value, diagnostic, sensitivity, multiplicity decision, sample definition, figure, source-data file, or scientific artifact was changed. No Quarto render or scientific analysis was run. Structural inventories and checksum checks were non-analytical. The existing H02 scientific result remains accepted and frozen.

## Reviewed identities

- Result source: `notebooks/hypotheses/H02.qmd`, SHA-256 `56f6ded2dae5420e36231958d0b1a50f5f938d0d9dd2172301b2340861a0ff20`, 56,571 bytes.
- Companion source: `audit/hypotheses/H02/H02_analysis_preparation.qmd`, SHA-256 `3d298f2f45165107bc69bbc3b35f1414a5d0cb905d8aa09c839d1e862618e808`, 54,702 bytes.
- Current result HTML: `_build/nathealth/notebooks/hypotheses/H02.html`, SHA-256 `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164`, 270,001 bytes.
- Current companion HTML: `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`, SHA-256 `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`, 580,722 bytes.
- Reader-report test: `tests/hypotheses/H02/test_h02_reader_report.R`, SHA-256 `c54718734b679139a4d7f0c121c58daf8d5fe5efed49feeef2cc37eac25b185c`.
- Preparation-report test: `tests/hypotheses/H02/test_h02_preparation_report.R`, SHA-256 `8c42a8a42856e5b9fb190a4e44de716f41ee1c8b7ef4eadd66c12c7663fd823d`.
- Matched-placement display test: `tests/hypotheses/H02/test_h02_paired_placement_display.R`, SHA-256 `17e1706ce8720ac48925e47be1b6ab2c246bbd900c7412b838834e8c39f3404a`.
- Preparation-report manifest: `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`, SHA-256 `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7`.
- Worker inventory: `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`, SHA-256 `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331`.
- Owner handoff: `audit/handoffs/H02_worker_handoff.md`, SHA-256 `0cf26a7038e7c49dc8e9790798b5ed3e1d01a5431cf0e1d8845b02892b96bc94`.
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Phase 2 output catalog: `audit/report_harmonization/phase2_main_supplement_output_catalog.csv`, SHA-256 `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.

The current HTML files and historical report manifests predate the accepted source-only REPORT-014 and REPORT-016 revisions. They are retained as historical render evidence, not treated as current source acceptance.

## Scientific result boundary

The primary near-eye analysis uses 141 participants, 816 participant-days, 37,756 30-minute observations, and nine sites. The complementary chest analysis uses 154 participants, 902 participant-days, 41,842 observations, and eight sites. The accepted result is that the combined participant-pattern plus participant-day ordering exceeds the site-pattern ordering in the primary analysis and remains stable across the reported complementary and sensitivity analyses. The participant-only contrast is less stable outside the complete near-eye sample.

The conditional Shapley analysis already provides additive component-level allocations of in-sample R-squared. These are Shapley-allocated contributions, not independent term R-squared values, causal effects, population variance components, or cross-validated predictive importance. No new Shapley computation is needed.

The proposed work must preserve the selected formula, all fitted samples, all values and intervals, the single confirmatory near-eye omnibus site-pattern test, every FDR decision, every diagnostic qualification, all pointwise-interval qualifications, every sensitivity classification, and the main-versus-complementary placement hierarchy.

## Result-report findings

### Information hierarchy

The result is scientifically clear, but the full registration record and two registration-change tables appear before the model and the primary result. The exact near-eye sample table then appears before the proposed main figure and main table. This delays the principal evidence and makes a supplemental sample table the first result table.

The coherent target order is:

1. Question and answer in brief.
2. What was analysed and the existing concise glossary.
3. Model and reported quantities.
4. Primary near-eye result, beginning with `fig-h02-near-patterns` and `tbl-h02-near-variation`.
5. Conditional Shapley results and pointwise site windows.
6. Complementary chest result.
7. Matched near-eye and chest evidence.
8. Model checks, with the detailed figures and tables in disclosures while the accepted conclusions remain visible.
9. Sensitivity analyses.
10. Interpretation and limitations.
11. Detailed analysis record containing the two exact fitted-sample tables, registration changes, the exact topic-to-ID links, source data, and technical provenance.

This retains every endpoint and cross-reference while making the proposed principal H02 outputs the first figure and first table.

### Vocabulary and prose

- Retain the approved scientific subtitle, `Site, participant, and participant-day variation in personal light exposure`.
- Retain `nonlinear GAM analysis`, `back-transformed`, `AR(1)`, `95% CI`, `Shapley allocation`, and `site-average curve` with their existing first-use explanations.
- Retain `matched sample` for the exact same participants, participant-days, and 30-minute observations at both placements.
- Retain `gap-timing-unaware dataset` because its first use gives the accepted coverage and interpretation boundary.
- Remove the internal multiplicity-family identifier `H02-F1-site-pattern` from reader-facing prose and tables. Use `the single confirmatory near-eye omnibus site-pattern test` or `the single confirmatory family` instead.
- Use FDR in reader-facing compact text. Do not display the abbreviation BH. The full Benjamini-Hochberg false-discovery-rate method may remain once in technical reproducibility text.
- Replace prose em dashes with commas, parentheses, colons, or separate sentences. The dash glyph used only as a missing-value table symbol may remain.
- Do not expose code-only object names containing `heterogeneity`; reader prose already uses participant-level variation and fitted-model relevance.

### Progressive disclosure

- Move the registration section, with anchor `#h02-preregistration-deviations`, to the late detailed analysis record.
- Put the exact 22 registration-link occurrences and 18 unique lower-case anchors in a disclosure labelled `Show linked registration entries by topic`.
- Keep each concise model-check interpretation visible. Put the corresponding diagnostic figure and table in a disclosure labelled `Show detailed near-eye model checks` or `Show detailed chest model checks`.
- Add `lightbox: true` to the result HTML format so the dense four-panel and diagnostic figures remain inspectable at narrow widths without regenerating them.

### Principal and supplemental outputs

- `fig-h02-near-patterns` remains the provisional main H02 figure. Its accepted stored PNG is 3,300 by 4,200 pixels at 300 dpi. It is highly polished and requires no redesign.
- `tbl-h02-near-variation` remains the provisional main H02 table. Preserve its native gt construction, rows, order, values, units, title, and source note.
- `tbl-h02-near-sample`, the two registration-change tables, all Shapley detail, pointwise windows, diagnostics, chest results, matched-placement figure, and sensitivity table retain their accepted supplemental roles.
- The shortlist remains provisional until the author sees the fresh focused outputs. HTML table usability is judged at a typical screen width. If an exported table PNG is later produced, that PNG becomes the controlling exported-table visual check.

## Companion findings

The companion is scientifically faithful and already explains the primary and complementary roles, participant-days, the nonlinear GAM, transformed and back-transformed scales, AR(1), pointwise intervals, Shapley allocation, model checks, and sensitivities. The remaining repairs are structural and reader-facing:

- Add `lightbox: true`.
- Rename `Purpose` to `About this analysis record` and `What is calculated when this page opens` to `Render boundary`.
- Define a model frame at first use as the exact rows and variables used for one fitted model.
- Remove the render-side `dir.create()` and two `write_csv()` calls. The accepted source CSV files remain frozen provenance. Rendering may calculate the already accepted descriptive display in memory but must not write project files.
- Replace visible underscore-separated column labels with spaced reader labels in the render-boundary, diagnostic-map, sensitivity-map, module-map, and script-map tables.
- Display input verification states as `Verified` and `Review needed`, without changing the stored PASS/FAIL values.
- Remove `H02-F1-site-pattern` from the model-settings and structure-comparison display strings while preserving the single-family scientific meaning.
- Keep exact filenames, commands, package names, hashes, and the full Benjamini-Hochberg method name in the subordinate technical provenance section.
- Preserve the reciprocal dynamic `.qmd` link and the anchored link to the result's registration record.

The companion contains 16 table endpoints and four figure endpoints. All must remain present exactly once. The descriptive figures may be recalculated only by the later authorized R 4.6.1 target render from their accepted inputs. No fitted model, prediction, bootstrap, residual, or Shapley object may be recomputed.

## Tests and provenance finding

The current reader and preparation tests still require hard-coded source-side `.html` links, stale BH display wording, current HTML existence, and a byte-identical rendered QMD before a revised source can be accepted. This couples source review to rendering and creates the same avoidable loop encountered in H01.

The consolidated source order should:

1. Add one explicit opt-in source-only mode, `H02_REPORT_SOURCE_ONLY`, to the result and preparation tests. Default behavior must remain the complete rendered-HTML branch.
2. Require dynamic relative `.qmd` source links in both modes. The default rendered branch continues to require resolved `.html` links in HTML.
3. Keep all source, endpoint, formula, sample, value, figure, link, anchor, native-gt, forbidden-call, country-code, and scientific-artifact checks in source-only mode.
4. Update the matched-placement test from stale BH wording to the approved FDR wording without changing any numerical or sample assertion.
5. Preserve the current H02 preparation and worker manifests as historical Aug-1 render inventories during the source-only order. They already contain three known historical-to-live mismatches each. Do not run either broad manifest builder or claim that the stale HTML was accepted.
6. Create a bounded non-circular order-33 source manifest that pins the two current QMDs, changed tests, frozen scientific inputs, historical manifests, handoff, profile context, and order evidence. Later, after the serial result and companion renders, perform one bounded post-render reseal of current build and manifest identities.

This keeps the historical render trail intact and gives the source rewrite a current, non-circular seal without mixing new source identities with stale build rows.

## Current render disposition

The current result and companion HTML files were not used for final visual acceptance because they predate the accepted REPORT-014 vocabulary revision and REPORT-016 dynamic-link integration. A visual finding from those stale pages would not reliably describe the proposed source state.

After independent source acceptance, H02 should receive exactly one result render and one companion render in the serial REPORT-017 queue. The two fresh pages should then receive one combined semantic, link, table, figure, desktop, narrow, lightbox, and protected-identity review. Diagnostic details, wide native tables, the principal figure, the principal table, and the matched-placement figure require explicit final-size checks. Any display defects should be collected across both pages and returned in one correction package.

## Disposition

No scientific discrepancy blocks H02. One consolidated source-only owner order may run while H01 source-only work is active because the H01 and H02 owner paths are disjoint. H02 must not render, edit the shared profile, touch the semantic hook, modify build outputs, change central or harmonizer-wide files, or run scientific computation. The owner should implement the complete matrix once, run the source-only suite once after all edits, and stop for independent acceptance.
