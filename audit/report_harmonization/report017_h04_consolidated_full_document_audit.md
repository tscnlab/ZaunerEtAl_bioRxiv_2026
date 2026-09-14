# REPORT-017 H04 consolidated full-document audit

Date: 2026-08-14

Status: complete read-only source audit; one consolidated source-only owner order is appropriate; H04 rendering remains held

## Controlling boundary

This audit follows REPORT-014, REPORT-016, REPORT-017, the accepted H04 scientific closure, the accepted Mundlak-style sensitivity, the accepted exploratory participant random-intercept assessment, and the consolidated-document-pass protocol. It covers the complete H04 result report, its preparation and provenance companion, all reader-facing table and figure endpoints, directly dependent tests and manifests, dynamic links, the current H04 handoff, and the provisional main and supplemental output roles.

No data, model, estimate, interval, p-value, model check, sensitivity, multiplicity decision, sample definition, Shapley allocation, figure, source-data file, or scientific artifact was changed. No Quarto render or scientific analysis was run. Structural inventories, source reading, link checks, and checksum checks were non-analytical. H04 remains scientifically closed.

## Reviewed identities

- Result source: `notebooks/hypotheses/H04.qmd`, SHA-256 `cd58c2ff5708fd3c74336656056dc1459f59772e55a31abd6f90bd25ad11e6ac`, 80,555 bytes.
- Companion source: `audit/hypotheses/H04/H04_analysis_preparation.qmd`, SHA-256 `28e44e527f1048cdd2b56cf2d7d7ed4b6a1faea5b8cd2c6765068fb2bf994d3d`, 89,045 bytes.
- Current result HTML: `_build/nathealth/notebooks/hypotheses/H04.html`, SHA-256 `cad724ca28c651db62f2bb11a51d0d53adbf133785a6d9477f600900269e3cbe`, 380,116 bytes.
- Current companion HTML: `_build/nathealth/audit/hypotheses/H04/H04_analysis_preparation.html`, SHA-256 `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`, 1,207,573 bytes.
- Stage 3 reader test: `tests/hypotheses/H04/test_h04_stage3_reader_report.R`, SHA-256 `53a5d68b3f56856c20824c43a4703f208bd0984cd81a443fab7111b07e783e17`.
- Companion test: `tests/hypotheses/H04/test_h04_preparation_report.R`, SHA-256 `8a862e0acece4d77392647a55df4f659410fbc94e2fc6ae40b642c47c2184935`.
- Participant random-intercept test: `tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R`, SHA-256 `247523ec05b484e161e2717a21d33314375370b84413a3bbcfb150582b86ad90`.
- Current 293-row Stage 3 manifest: `artifacts/12_manifests/H04/H04_stage3_artifacts.csv`, SHA-256 `6215a9496f5f542ff92c19536b5601aa49c1ca804523eb7f9ff8bfdff852e115`.
- Current 252-row preparation manifest: `artifacts/12_manifests/H04/H04_preparation_report_manifest.csv`, SHA-256 `ba6164aa81a38d79670ddf7d89b7b9b17bfd8e906d45293c568f01c079c5d524`.
- Owner handoff: `audit/handoffs/H04_worker_handoff.md`, SHA-256 `0c9727b74e54febc80d7cb89b2d5b44d26ea801d9bc17a21b311ed98f9de447a`.
- Accepted post-closure synchronization check: `audit/report_harmonization/h04_postclosure_random_intercept_harmonization_check.md`, SHA-256 `901f39f506f2770c014a923a788d5370c5ee61a8bcfab368e6592efa47d1c780`.
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Phase 2 output catalog: `audit/report_harmonization/phase2_main_supplement_output_catalog.csv`, SHA-256 `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.

The current H04 handoff was read completely before preparing an owner instruction. The two current H04 manifests are accepted pre-editorial closure and render records. They should remain byte-identical in the source-only order rather than being broadly rebuilt around stale HTML.

## Scientific result boundary

The accepted primary analysis is a population-mean fixed-power quasi-Tweedie model with participant-clustered covariance. The additive site-plus-activity model supplies the primary five-category omnibus. A separate support-qualified activity-by-site interaction model supplies descriptive site-average means, ratios, and site-specific context. Near eye is primary and chest is complementary.

Multi-select activity hours retain one total contribution through exact `1/k` weights. Other/unspecified activity remains an additive-model display-only category and supports no substantive claim. The population-mean within-participant and between-participant sensitivity remains a separate Mundlak-style augmentation. It is not a mixed model or variance-component analysis.

The accepted exploratory mixed model is:

```text
geo_medi_1h ~ site * activity_named + (1 | participant)
```

It preserves the same support-qualified five-category frame and exact `1/k` weights. Marginal and conditional R-squared are 0.766 and 0.858 near eye and 0.768 and 0.859 at chest. The participant-intercept increment is about 0.092 at both sensor positions. These values are descriptive, model-dependent point summaries. They are not causal or unique variance shares and do not replace the primary population-mean inference.

The proposed work must preserve every accepted sample, formula, weight, estimate, interval, p-value, FDR decision, model check, influence result, sensitivity classification, figure, source-data row, and scientific conclusion.

## Result-report findings

### Information hierarchy

The central finding is accurate, but five exact category lines and three supplemental support tables occur before the principal figure and table. The registration-change list also appears before the main display. This delays the answer that matters most to a scientific reader.

The coherent target order is:

1. Question and a concise Answer in brief.
2. A short explanation of the primary near-eye and complementary chest roles, the one-hour outcome, the shared contribution of multi-select hours, and the key terms needed for the main display.
3. Principal results, beginning with `fig-h04-primary-estimates` and `tbl-h04-primary-results`.
4. Supporting contrasts and omnibus tests.
5. Sample and activity-support details.
6. Model and estimand.
7. Site-specific context and descriptive fixed-effect R-squared.
8. The exploratory participant random-intercept assessment.
9. Model checks and sensitivity analyses.
10. Same-participant, same-hour sensor-position comparison.
11. Exploratory nonlinear time-of-day context.
12. Interpretation and limitations.
13. A late detailed analysis record containing registration links, exact formulas, source links, and the exact category lines moved from the opening callout.

This preserves every endpoint and detailed scientific statement while making the proposed main figure and main table the first figure and table endpoints.

### Vocabulary and prose

- Retain `site-average estimate` and explain at first use that it is an average across the observed sites that gives each site equal weight on the fitted log-mean scale.
- Use `activity-by-site interaction`, explained as an association allowed to differ by study site. Do not lead with unexplained heterogeneity terminology.
- Describe Other/unspecified activity as a varied display-only category or as not a coherent scientific category. Do not call it a heterogeneous category in reader prose.
- Retain `nonlinear GAM analysis`, `AR(1)`, `95% CI`, `FDR`, `random intercept`, and `Shapley allocation` only with their approved first-use explanations.
- For the paired placement analysis, first say that it uses the same participants and participant-hours at both sensor positions. `Common sample` may then be used as a shorter label.
- Replace visible `submitted site names`, `submitted site registry`, and `submitted reader-facing category` language with `country-coded study-site names`, `shared country-coded site registry`, and `reader-facing category`.
- Display verification states as `Verified` and `Verified current identity`, not all-capital production states. Preserve the stored values and fail-closed checks in code.
- Replace `registered gate` in reader prose with `predefined threshold`.
- Display plain multiplicity descriptions, including `activity-by-site interaction omnibus`, rather than internal or legacy labels.
- Use reader labels with spaces for columns such as `Scientific reason`, `Near eye`, `Source model`, `Reference distribution`, `Inferential role`, `Principal outputs`, `Run on this page`, `Output group`, `Reader use`, and `Calculated on render`.
- Replace prose em dashes with punctuation or separate sentences. Missing-value dash symbols may remain.
- Preserve exact filenames and code-only object names containing `heterogeneity`, `BH`, or historical identifiers where reproducibility requires them.

### Progressive disclosure

- Keep the main result visible and first.
- Keep concise conclusions for supporting contrasts, site context, model checks, sensitivity analyses, and exploratory temporal analysis visible.
- Put the full supporting contrast and omnibus tables in a disclosure labelled `Show supporting contrasts and interaction tests`.
- Put the detailed site table, site figure, and fixed-effect R-squared table in `Show site-specific context and R² summaries`.
- Put the full primary model-check table and figure in `Show detailed primary model checks`.
- Put the full sensitivity and Mundlak tables in `Show detailed sensitivity results`, while retaining the overall stability conclusion outside.
- Put exploratory temporal tables, figures, allocation, and model checks in `Show exploratory nonlinear time-of-day details`, while retaining the purpose, main interpretation, and limitations outside.
- Put registration entries, formulas, and subordinate provenance links in the late detailed analysis record.

### Principal and supplemental outputs

- `fig-h04-primary-estimates` remains the provisional main H04 figure. It is 3,840 by 3,060 pixels at 300 dpi and is otherwise highly polished.
- `tbl-h04-primary-results` remains the provisional main H04 table. Preserve its native gt construction, rows, order, values, units, caption, and notes.
- `tbl-h04-participant-random-intercept` remains supplemental detailed model context.
- `tbl-h04-mundlak` remains supplemental sensitivity context.
- All other result endpoints retain their accepted supplemental roles.
- The shortlist remains provisional until the author sees the fresh focused render. HTML tables must work reasonably at a typical screen size. If an exported table PNG exists or is later produced, the PNG is the controlling exported-table visual check.

## Companion findings

The companion is scientifically faithful and already explains the primary and complementary roles, participant-hours and participant-days, one-hour response, activity-by-site interaction, site-average estimation, participant-clustered covariance, FDR, nonlinear GAM analysis, AR(1), model checks, sensitivities, and the exploratory random-intercept distinction. The accepted reciprocal link and auxiliary anchor are present.

Remaining repairs are structural and reader-facing:

- Add `lightbox: true`.
- Rename the `Purpose` heading to `About this analysis record`.
- Replace visible submitted-site and submitted-category wording with shared reader terminology.
- Replace visible Other/unspecified heterogeneity wording with its plain display-only qualification.
- Display verification states and model-construction outcomes in sentence case.
- Recode the visible multiplicity table to plain family descriptions and FDR terminology while preserving all members and decisions.
- Apply reader-facing spaced labels to the transformation, model-specification, estimand, script, output, and render-boundary tables.
- Replace the visible `registered 10^10 gate` phrase with `predefined 10^10 threshold`.
- Retain technical filenames, commands, checksums, package names, exact formulas, and the full Benjamini-Hochberg method name only where subordinate reproducibility requires them.
- Keep all model fitting, prediction, simulation, bootstrap, and Shapley computation outside the render. The companion reads accepted outputs only.

The result currently contains 17 table and seven figure endpoints. The companion contains 37 table and four figure endpoints. Every endpoint must remain present exactly once.

## Source-test and provenance strategy

The current Stage 3 and companion tests are render-coupled. Running them unchanged against revised sources would mix current source with stale HTML. The source-only order should therefore:

1. Preserve the current Stage 3, preparation, participant-random-intercept, Stage 1, and Stage 2 tests byte-for-byte.
2. Preserve the current Stage 3 and preparation manifests byte-for-byte as accepted pre-editorial closure and render records.
3. Add one new H04-owned source-only harmonization test. It must validate both QMD sources, every endpoint, first-endpoint order, formulas, dynamic links and anchors, country-coded sites, terminology, artifact references, absence of project-side writes and scientific calls, the distinction among the primary model, Mundlak sensitivity, and random-intercept assessment, and all protected scientific identities.
4. Add one bounded non-circular H04 source manifest. It must pin the final QMDs, new source-only test, unchanged scientific tests and historical manifests, handoff, accepted random-intercept evidence, principal and supplemental figures, source-data files, profile context, stale HTML context, and owner evidence. It must not claim that the existing HTML corresponds to the revised source.
5. Run the unchanged participant random-intercept test and the new source-only harmonization test under R 4.6.1. Parse every R chunk without execution. Do not run the render-coupled Stage 3 or preparation tests until the later serial render gate.

This creates a current source seal without rewriting historical render evidence or creating a source-versus-HTML transition loop.

## Stored-figure label follow-up

Static SVG inspection found reader-visible wording that cannot be repaired in QMD source alone.

The provisional main figure `H04_reader_heterogeneity_category_estimates` contains `Heterogeneity-model` in both panel titles and `site-heterogeneity model` in its footer. Current identities are PNG `b2f883b89fa4e482442651f97f6e97c2aed14b48b83cc77050cbe7a1f51ed940`, PDF `65c2a3cbc125df54e9780f9d255dcd624d5c126593afe2658481c803f22d6103`, and SVG `b8bc9612b27ed876bb28bb9e5755f8c6a0564cf20d08ec16a0d68f0402e821ae`.

The supplemental site figure `H04_site_activity_estimates` contains `equal-site`, `BH-adjusted`, `support-gated`, and `site-heterogeneity model`. Current identities are PNG `a183754e2d79d6c748caf9747b37e3d52277efc89d586844f225ee45c6f80da0`, PDF `f8afe38e949f03351f8ad4b2af28eb15cbd7e7f2e44fb7144bb40c70354e6a0c`, and SVG `4015ec7e9b5756c1e8efba18b1195763e9bb274a019980430cf9a72cc3c14746`.

The paired frozen source data are `H04_reader_heterogeneity_category_figure.csv` SHA-256 `e27bc81e0c6dd2ff50dd0c6ffa4e95d9c7e9c16e5b20ce45fb4df7d1e89f3652` and `H04_site_activity_figure.csv` SHA-256 `f07f54bc288bd660b0e3a107016c7852a64ce72c0f1594df052519062a2c5caf`.

The source-only owner must inventory these exact families and the minimum display builders, but must not regenerate them. Before the H04 serial render, one bounded display-only artifact order should rebuild only these two figure families from frozen display data. It should change only reader labels to `activity-by-site interaction model`, `site-average`, `FDR-adjusted`, and `support-qualified`, preserving every plotted value, interval, point, colour, facet, dimension, and scientific statement.

## Current render disposition

The current result and companion HTML files predate the consolidated hierarchy and terminology pass. They remain stale render context, not final visual evidence.

After independent source acceptance and the separate bounded baked-label refresh, H04 should receive exactly one result render and one companion render in the serial REPORT-017 queue. The two pages should then receive one combined semantic, link, table, figure, desktop, narrow, lightbox, and protected-identity review. All newly exposed display defects should be collected before one combined correction order.

## Disposition

No scientific discrepancy blocks H04. One consolidated source-only owner order may overlap H01, H02, and H03 source-only work because all mutable paths are H04-specific and disjoint. H04 must not render, edit the shared profile, touch the semantic hook, modify build outputs, change central or harmonizer-wide files, regenerate figures, or run scientific computation. The owner should implement the complete matrix once, run the source-only suite once after all edits, and stop for independent acceptance.
