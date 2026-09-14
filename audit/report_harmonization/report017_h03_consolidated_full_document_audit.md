# REPORT-017 H03 consolidated full-document audit

Date: 2026-08-14

Status: complete read-only source audit; one consolidated source-only owner order is appropriate; H03 rendering remains held

## Controlling boundary

This audit follows REPORT-014, REPORT-016, REPORT-017, H03-AUX-001 / CHG-139, RH-SYNC-H03-001, and the consolidated-document-pass protocol. It covers the complete H03 result report, its preparation and provenance companion, all reader-facing table and figure endpoints, directly dependent tests and manifests, dynamic links, the current H03 handoff, and the provisional main and supplemental output roles.

No data, model, estimate, interval, p-value, model check, sensitivity, multiplicity decision, sample definition, Shapley allocation, figure, source-data file, or scientific artifact was changed. No Quarto render or scientific analysis was run. Structural inventories and checksum checks were non-analytical. H03 remains scientifically closed.

## Reviewed identities

- Result source: `notebooks/hypotheses/H03.qmd`, SHA-256 `5d329c24afbd321a2be8d87ca7453a8612ab6745d009d4cecef2c82a4c6dd59a`, 67,332 bytes.
- Companion source: `audit/hypotheses/H03/H03_analysis_preparation.qmd`, SHA-256 `b7671d848544228088df9bbe179a172fd7402e7fa18c3029be9b499d0ef2f760`, 64,129 bytes.
- Current result HTML: `_build/nathealth/notebooks/hypotheses/H03.html`, SHA-256 `68aa07eb7470286d0d6da76114ce7bf346ee635974fe7403c1860ad4560c3d25`, 330,938 bytes.
- Current companion HTML: `_build/nathealth/audit/hypotheses/H03/H03_analysis_preparation.html`, SHA-256 `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`, 900,339 bytes.
- Stage 3 reader test: `tests/hypotheses/H03/test_h03_stage3_reader_report.R`, SHA-256 `0af80c8dfede663d724c488f5b7947ca8635a944d789f7a552f6e932999bd3ef`.
- Companion test: `tests/hypotheses/H03/test_h03_preparation_report.R`, SHA-256 `bddaa2393ead9317c5f526a00f75d2fd86e0e7efeaf84dcd2737e61b149a058a`.
- Auxiliary-model test: `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R`, SHA-256 `30fa488114886eb4e9feeccc55f6f752e229585bfc1f2eb5b5a85bfba582bfc8`.
- Stage 2 scientific test: `tests/hypotheses/H03/test_h03_stage2.R`, SHA-256 `a174e3fe2a1a7832a5f6e8e8a98a3da8d88d85bd30e22917e554ae658f7ce596`.
- Current 350-row Stage 3 manifest: `artifacts/12_manifests/H03/H03_stage3_artifacts.csv`, SHA-256 `5f4f10528f1c49d52518a6dde36d6ce0ffd71869cab9bcde382bf9c9edce3170`. Every row currently matches.
- Historical 319-row preparation manifest: `artifacts/12_manifests/H03/H03_preparation_report_manifest.csv`, SHA-256 `5235b02c6c542a010336eca9569b77b269deb673d4659d794393d2427146393a`.
- Owner handoff: `audit/handoffs/H03_worker_handoff.md`, SHA-256 `dae48601f0ba90ee2932556b312ac2e0e94db0bc695ea242c01328c9ea6a0fec`.
- H03-AUX-001 / CHG-139: `audit/decisions/h03_auxiliary_model_assessments_closure.md`, SHA-256 `85be31f6c105ea2c47a5353a32d4081dcdbc50a0738998f2106c0952c4527827`.
- RH-SYNC-H03-001: `audit/report_harmonization/h03_postclosure_synchronization_check.md`, SHA-256 `569767a839a34f1dc3e58ea8c5b554da23a56163a2cf48ad90d7a17cd05b1aea`.
- Auxiliary script: `scripts/hypotheses/H03/run_h03_participant_random_intercept_assessment.R`, SHA-256 `662e7ac81b3b67693023acdb196b2187d7058e863294b7b77e0105b8ca456f4c`.
- Auxiliary six-file manifest: `artifacts/12_manifests/H03/H03_near_eye_participant_random_intercept_manifest.csv`, SHA-256 `81bab5291ca9f9aa24a39cae991857b8f5b39046090da2e4f4c984f4ea7c2306`.
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Phase 2 output catalog: `audit/report_harmonization/phase2_main_supplement_output_catalog.csv`, SHA-256 `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.

The Stage 3 manifest is the exact scientific-closure inventory before this proposed editorial revision. The preparation manifest is older historical render evidence. It currently has seven known mismatches: the result HTML, Nature Health profile, Stage 3 manifest, figure-readability decision, companion authoring QMD, result authoring QMD, and Stage 3 reader test. Neither manifest should be broadly rebuilt during the source-only order.

## Scientific result boundary

The accepted primary analysis is the population-mean fixed-power quasi-Tweedie model with participant-clustered covariance. The additive model supplies the preregistered light-source-category omnibus. The accepted category-by-site interaction model supplies descriptive site-average means, ratios, and supported site-specific context. Near eye is primary and chest is complementary.

The new auxiliary near-eye model is a separate descriptive participant random-intercept assessment:

```text
geo_medi_1h ~ site * light_source + (1 | participant)
```

It has marginal R-squared 0.79585, conditional R-squared 0.87623, and a participant-intercept increment of 0.08037. Its hierarchy-respecting refit-based Shapley allocation is 0.05630 for study site, 0.71045 for light source, and 0.02910 for the interaction. These stored values are model-dependent point summaries, not causal or unique variance shares.

The within-participant and between-participant sensitivity remains a population-mean quasi-Tweedie augmentation with participant-clustered covariance. It is not a mixed model, random-intercept model, random-slope model, or variance-component analysis. Neither auxiliary analysis replaces the primary model, changes its multiplicity families, or supplies evidence to another hypothesis.

The proposed work must preserve every accepted sample, formula, estimate, interval, p-value, FDR decision, model check, influence result, sensitivity classification, figure, source-data row, and primary conclusion.

## Result-report findings

### Information hierarchy

The central finding is accurate, but the opening callout contains seven category lines and six site-deviation lines before the reader reaches the principal figure and table. Two exact-support tables then make supplemental sample context the first result tables.

The coherent target order is:

1. Question and a concise Answer in brief.
2. A short orientation to the primary near-eye and complementary chest roles, outcome, site-average estimate, and observation unit.
3. Model and reported quantities.
4. Principal results, beginning with `fig-h03-primary-estimates` and `tbl-h03-primary-results`.
5. Omnibus and category-by-site interaction context.
6. Site-specific context and descriptive model-performance summaries.
7. The exploratory participant random-intercept assessment, with a dynamic link to its companion record.
8. Model checks and sensitivity analyses.
9. Same-participant, same-hour placement comparison.
10. Exploratory nonlinear time-of-day and linear-latitude context.
11. Interpretation and limitations.
12. A late detailed analysis record containing the exact sample and category-support tables, detailed category and site lines moved from the opening callout, registration links, formulas, source data, and provenance.

This preserves every endpoint and detailed scientific statement while making the proposed main figure and main table the first figure and table endpoints.

### Vocabulary and prose

- Retain `site-average estimate` and its existing first-use explanation that each site receives equal weight on the fitted log-mean scale.
- Use `[light-source category]-by-site interaction` or `category-by-site interaction`, explained as an association allowed to differ by study site. Do not lead with unexplained heterogeneity terminology.
- Use `participant-level variation` for the visible auxiliary-table group now labelled `Participant heterogeneity`.
- Retain `nonlinear GAM analysis`, `AR(1)`, `95% CI`, `FDR`, and `Shapley allocation` only after the approved first-use explanations.
- Use `the same participants and participant-hours at both sensor positions` before the shorter same-hour or common-sample label.
- Replace visible `submitted site palette`, `submitted site registry`, and `submitted-manuscript site` wording with `shared country-coded site registry`, `shared site order and colours`, or `country-coded study sites` as appropriate.
- Display verification states as `Verified` and `Review needed`, without changing stored PASS/FAIL values.
- Do not display internal multiplicity-family IDs. Use plain family descriptions in the multiplicity table while retaining exact IDs only in technical provenance or code.
- Use reader labels with spaces for fields such as `Source model`, `Reference or comparison`, `Inferential role`, `Principal outputs`, `Run on this page`, `Output group`, `Reader use`, and `Calculated on render`.
- Replace prose em dashes with punctuation or separate sentences. Missing-value dash symbols may remain.
- Preserve exact filenames and code-only object names containing `heterogeneity` where required for reproducibility.

### Progressive disclosure

- Move the two exact support tables to the late detailed analysis record.
- Keep concise model-check conclusions visible. Put the full primary model-check table and figure in a disclosure labelled `Show detailed primary model checks`.
- Keep the overall sensitivity conclusion visible. Put the detailed sensitivity table in `Show detailed sensitivity results`.
- Put the full exploratory temporal figures, tables, and checks in a disclosure labelled `Show exploratory nonlinear time-of-day details`, while retaining the purpose, main interpretation, and limitations outside it.
- Put the exploratory latitude table and figure in `Show exploratory latitude details`, while retaining the ecological and non-causal qualification outside it.
- Put exact formulas, registration entries, and detailed source/provenance links in the late detailed analysis record.
- Add `lightbox: true` to both result and companion HTML formats. No figure regeneration is authorized in this source pass.

### Principal and supplemental outputs

- `fig-h03-primary-estimates` remains the provisional main H03 figure. It is 3,840 by 3,060 pixels at 300 dpi and is already highly polished.
- `tbl-h03-primary-results` remains the provisional main H03 table. Preserve its native gt construction, rows, order, values, units, caption, and notes.
- `tbl-h03-participant-random-intercept` is already present in the output catalog as `supplement: detailed result or context`. No catalog edit is needed.
- All other result endpoints retain their accepted supplemental roles.
- The shortlist remains provisional until the author sees the fresh focused render. HTML tables must work reasonably at a typical screen size. If an exported table PNG exists or is later produced, the PNG is the controlling exported-table visual check.

## Participant random-intercept synchronization

The result contains the accepted auxiliary section and four stored source-data links, but the companion does not yet document it. The result also lacks a direct anchor link to the future companion subsection.

The companion must add one display-only subsection immediately after its fixed-effect R-squared subsection, with anchor `#sec-h03-prep-participant-random-intercept`. It must read the six already sealed auxiliary outputs by identity, show the exact stored formula and point summaries, state the convergence, Hessian, singularity, lag-one residual correlation, and zero-mass qualifications, and explain the descriptive boundary.

The subsection must explicitly distinguish the auxiliary mixed model from the population-mean within-participant and between-participant sensitivity. It must add the accepted run script, model, summary, Shapley, model-check, environment, and manifest paths to the companion code and output maps. The result must add exactly one relative `.qmd` link to the new anchor. The reciprocal companion-to-result link remains dynamic.

## Companion findings

The companion is scientifically faithful and already explains the primary and complementary roles, participant-days, outcome, interaction, site-average estimation, participant-clustered covariance, FDR, nonlinear GAM analysis, AR(1), model checks, sensitivities, and exploratory latitude context. Remaining repairs are structural and reader-facing:

- Add `lightbox: true`.
- Rename `Purpose` to `About this analysis record`.
- Replace the visible analysis-map and input-table references to a submitted site registry with shared country-coded site wording.
- Add the participant random-intercept synchronization described above.
- Replace visible internal multiplicity-family IDs with plain family descriptions.
- Apply reader-facing spaced labels to the estimand, script, output, and render-boundary tables.
- Keep all model fitting, prediction, simulation, bootstrap, and Shapley computation outside the render. The new subsection reads sealed outputs only.
- Retain technical filenames, commands, hashes, package names, exact formulas, and the full Benjamini-Hochberg method name in subordinate reproducibility text.

The companion currently contains 26 table endpoints and four figure endpoints. The new auxiliary display adds one table endpoint, for 27 tables and four figures. Every existing endpoint must remain present exactly once.

## Source-test and provenance strategy

The current Stage 3 and preparation tests are render-coupled. The preparation test also contains a stale source-side hard-coded `.html` link assertion. Running those tests unchanged against revised sources would recreate the avoidable stop-and-patch loop seen earlier.

For this source-only order:

1. Preserve the current Stage 3, preparation, participant-random-intercept, and Stage 2 tests byte-for-byte.
2. Preserve both existing H03 manifests byte-for-byte. Treat the Stage 3 manifest as the accepted pre-editorial scientific-closure inventory and the preparation manifest as older historical render evidence.
3. Add one new H03-owned source-only harmonization test. It must validate both QMD sources, all endpoints, first-endpoint order, formulas, dynamic links and anchors, country-coded sites, terminology, artifact references, absence of project-side writes and scientific calls, the auxiliary-model distinction, code/output maps, and all protected scientific identities.
4. Add one bounded non-circular H03 source manifest. It must pin the final QMDs, new source-only test, unchanged scientific tests and historical manifests, handoff, controlling decisions, frozen auxiliary outputs, principal and supplemental figures, source-data files, profile context, stale HTML context, and owner evidence. It must not claim that the existing HTML corresponds to the revised source.
5. Run the unchanged participant random-intercept test and the new source-only harmonization test under R 4.6.1. Parse every R chunk without execution. Do not run the render-coupled Stage 3 or preparation tests until the later serial render gate.

This creates a current source seal without rewriting historical render evidence or mixing revised source identities with stale build rows.

## Stored-figure label follow-up

Static SVG inspection found two reader-visible abbreviation repairs that cannot be made in QMD source alone:

- `H03_near_eye_site_context_estimates` contains `BH-adjusted` and an internal family label in its baked subtitle/footer.
- `H03_reader_latitude_category_slopes` contains `BH adjustment` in its baked footer.

The main H03 figure is unaffected. The source-only owner must return the exact affected PNG/PDF/SVG identities and the minimal display builders, but must not regenerate them in this order. Before the H03 serial render, one bounded display-only artifact order should rebuild only those two figure families from their frozen source data, changing labels to FDR and removing the internal family label while preserving every plotted value, interval, point, colour, facet, dimension, and scientific statement.

## Current render disposition

The current result HTML contains the accepted auxiliary scientific addition, but it predates the consolidated hierarchy and terminology pass. The companion HTML predates the auxiliary synchronization. Neither should be used for final visual acceptance.

After independent source acceptance and the separate bounded baked-label refresh, H03 should receive exactly one result render and one companion render in the serial REPORT-017 queue. The two pages should then receive one combined semantic, link, table, figure, desktop, narrow, lightbox, and protected-identity review. All newly exposed display defects should be collected before any single combined correction order.

## Disposition

No scientific discrepancy blocks H03. One consolidated source-only owner order may overlap H01 and H02 source-only work because all mutable paths are H03-specific and disjoint. H03 must not render, edit the shared profile, touch the semantic hook, modify build outputs, change central or harmonizer-wide files, regenerate figures, or run scientific computation. The owner should implement the complete matrix once, run the source-only suite once after all edits, and stop for independent acceptance.
