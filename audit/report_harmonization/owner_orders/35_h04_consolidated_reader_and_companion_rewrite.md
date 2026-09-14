# REPORT-014/017 order 35: H04 consolidated reader and companion rewrite

Date: 2026-08-14

Owner: H04 task `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: authorized source-only order; every H04 render and figure refresh remains held

## Purpose

Perform one coherent source-only rewrite of the complete H04 result and preparation/provenance pair. Read both documents, the complete current H04 handoff, the three reader and participant-random-intercept tests, both current report manifests, the accepted post-closure synchronization check, and the complete matrix before editing.

Implement the complete package in one pass. Run the prescribed source-only verification suite once after all edits are assembled. If an unexpected failure occurs, do not enter a piecemeal patch loop. Seal the complete stopped state and return one combined defect list. Do not render.

This order may overlap H01 order 32 and H02/H03 source-only work because its entire mutable path set is H04-specific and disjoint. It must not touch H01, H02, H03, another hypothesis, or any shared build, profile, ledger, hook, catalog, or coordination file.

The controlling package is:

- Full audit: `audit/report_harmonization/report017_h04_consolidated_full_document_audit.md`, SHA-256 `1464ba303ce047cad1294da1cadb783968f82983ee090300587288eef9cb42d1`.
- Complete 44-row matrix: `audit/report_harmonization/report017_h04_consolidated_change_matrix.csv`, SHA-256 `0e9518e5c2f1aeeabd63759cd3d54eb4372eb491d9cec581eb70ed5d6f579f6a`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.
- Accepted post-closure synchronization check: `audit/report_harmonization/h04_postclosure_random_intercept_harmonization_check.md`, SHA-256 `901f39f506f2770c014a923a788d5370c5ee61a8bcfab368e6592efa47d1c780`.
- Coordination matrix at dispatch preparation: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `bfd269b389d0e13a5d188404479dbd11aabe2fe52fd60a9405890ae1c452fac6`. It is coordination evidence only and is not an owner execution pin while parallel source work is active.

## Exact owner-scoped preflight pins

- `notebooks/hypotheses/H04.qmd`: `cd58c2ff5708fd3c74336656056dc1459f59772e55a31abd6f90bd25ad11e6ac`, 80,555 bytes.
- `audit/hypotheses/H04/H04_analysis_preparation.qmd`: `28e44e527f1048cdd2b56cf2d7d7ed4b6a1faea5b8cd2c6765068fb2bf994d3d`, 89,045 bytes.
- `tests/hypotheses/H04/test_h04_stage3_reader_report.R`: `53a5d68b3f56856c20824c43a4703f208bd0984cd81a443fab7111b07e783e17`, 23,170 bytes.
- `tests/hypotheses/H04/test_h04_preparation_report.R`: `8a862e0acece4d77392647a55df4f659410fbc94e2fc6ae40b642c47c2184935`, 14,036 bytes.
- `tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R`: `247523ec05b484e161e2717a21d33314375370b84413a3bbcfb150582b86ad90`, 9,022 bytes.
- `tests/hypotheses/H04/test_h04_stage1_support.R`: `6f349ed118af7b008a9afe7618ae65abf151b5b704e9b3249d20f4003b2d9d6f`, 8,094 bytes.
- `tests/hypotheses/H04/test_h04_stage2.R`: `36ce39863acd7ab2a11d85ec7dd97a0ba0153e97591aa2d9022866da839d6626`, 21,086 bytes.
- `artifacts/12_manifests/H04/H04_stage3_artifacts.csv`: `6215a9496f5f542ff92c19536b5601aa49c1ca804523eb7f9ff8bfdff852e115`. Preserve byte-for-byte as accepted pre-editorial scientific-closure evidence.
- `artifacts/12_manifests/H04/H04_preparation_report_manifest.csv`: `ba6164aa81a38d79670ddf7d89b7b9b17bfd8e906d45293c568f01c079c5d524`. Preserve byte-for-byte as accepted pre-editorial render evidence.
- `audit/handoffs/H04_worker_handoff.md`: `0c9727b74e54febc80d7cb89b2d5b44d26ea801d9bc17a21b311ed98f9de447a`.

Stable shared read-only context:

- `notebooks/preregistration_deviations.qmd`: `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.
- `config/site_display_registry.csv`: `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.
- `_quarto-nathealth.yml`: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`. Context only; do not edit or render.
- Current result HTML: `cad724ca28c651db62f2bb11a51d0d53adbf133785a6d9477f600900269e3cbe`.
- Current companion HTML: `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`.
- Phase 2 output catalog: `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`. It already contains the accepted H04 random-intercept and Mundlak supplemental roles; do not edit it.

Stop before editing if any owner-scoped preflight pin differs. A mutable harmonizer or coordinator file may drift outside the owner edit set. Record such drift as context and do not repin it.

The existing untracked `audit/hypotheses/H04/01_audit_and_plan.html` and `audit/hypotheses/H04/02_implementation_and_v0_comparison.html` are outside this order. Preserve them and do not add, delete, stage, or rewrite them.

## Authorized mutable files

The owner may edit only:

1. `notebooks/hypotheses/H04.qmd`
2. `audit/hypotheses/H04/H04_analysis_preparation.qmd`
3. `audit/handoffs/H04_worker_handoff.md`
4. New `tests/hypotheses/H04/test_h04_report017_source_harmonization.R`
5. New order-35 audit, source-diff, reverse-proof, protected-inventory, stored-figure-label inventory, execution record, and non-circular source-manifest evidence under `audit/hypotheses/H04/report017_order35/`

Do not edit the five current H04 tests, either current H04 report manifest, any analysis or figure-building script, any data, model, stored table, stored figure, source-data file, build output, profile, central record, harmonizer-owned file, manuscript file, or another hypothesis.

## Complete result-source rewrite

Implement all H04-result rows in the matrix while preserving every scientific distinction and endpoint.

### Target order

Use this coherent reader order:

1. Question and concise Answer in brief.
2. Short What was analysed orientation covering primary near-eye and complementary chest roles, the one-hour zero-aware geometric melEDI outcome, the `1/k` sharing of multi-select hours, and participant-hour and participant-day definitions.
3. A compact Terms used below glossary.
4. Principal results, starting with `fig-h04-primary-estimates` and then `tbl-h04-primary-results`.
5. Supporting contrasts and omnibus tests.
6. Sample and activity-support details.
7. Model and estimand.
8. Site-specific context and descriptive fixed-effect R-squared.
9. Exploratory participant random-intercept decomposition.
10. Model checks and sensitivity analyses.
11. Same-participant, same-hour sensor-position comparison.
12. Exploratory nonlinear time-of-day context.
13. Interpretation and limitations.
14. Detailed analysis record with registration links, exact formulas, source links, and the exact category lines moved from the opening callout.

Move, rather than delete, the existing five exact inline category lines from the opening callout. Preserve every existing inline-R expression and scientific numeric token.

Move `tbl-h04-overall-samples`, `tbl-h04-sample-flow`, and `tbl-h04-category-support` so they no longer precede the principal result. Their source pipelines, rows, order, values, captions, notes, and IDs remain unchanged.

Make `fig-h04-primary-estimates` and `tbl-h04-primary-results` the first figure and table endpoints. Preserve the exact set of 17 table and seven figure labels, each exactly once.

Keep accepted model-check, sensitivity, random-intercept, same-participant, and temporal interpretations visible. Put detailed endpoints in the exact disclosures named in the matrix. Preserve captions, alt text, paths, source-data links, and cross-reference targets.

Move the existing registration section, with its anchor and all five exact deviation links, to the late detailed record. Move `tbl-h04-formulas` to the same record. Do not alter their content.

Add `lightbox: true`. Do not regenerate any figure.

### Reader vocabulary

- Use `site-average estimate`, explained as an average across the observed sites that gives each site equal weight on the fitted log-mean scale.
- Use `activity-by-site interaction`, explained as an association allowed to differ by study site. Code-only object names and filenames containing `heterogeneity` remain unchanged.
- Replace reader prose that calls Other/unspecified activity heterogeneous with the plain boundary that it is a varied display-only category and not a coherent scientific category.
- Retain approved first-use explanations for 95% CI, FDR, random intercept, nonlinear GAM analysis, AR(1), Shapley allocation, back-transformation, and common sample.
- For the matched placement analysis, first state that it uses the same participants and participant-hours at both sensor positions.
- Replace visible submitted-site wording with shared country-coded study-site wording.
- Use FDR in compact reader displays. The full Benjamini-Hochberg method name may remain in technical reproducibility text. Do not introduce reader-facing BH.
- Replace prose em dashes with punctuation or separate sentences. Missing-value dash symbols may remain.
- Keep all country-coded site names, including captions and alt text.

### Participant random-intercept boundary

Keep the accepted subsection visible and preserve its dynamic link to:

```text
../../audit/hypotheses/H04/H04_analysis_preparation.qmd#sec-h04-prep-participant-random-intercept
```

Preserve the plain explanation that the participant random intercept lets participants have different overall exposure levels while retaining the fixed activity-by-site structure. Preserve the exact formula, working power, `1/k` weights, samples, marginal and conditional R-squared, participant increment, Shapley components, convergence and Hessian checks, residual lag-one correlations, exact-zero mismatch, no-random-slope boundary, no-participant-day boundary, and descriptive non-causal interpretation.

Keep the explicit distinction from the population-mean Mundlak-style sensitivity. Neither assessment changes the primary analysis or multiplicity families.

## Complete companion harmonization

### Opening and shared vocabulary

Add `lightbox: true`. Rename `Purpose` to `About this analysis record`. Keep the existing reciprocal result links and random-intercept anchor.

Replace visible references to submitted site registries, submitted category labels, and submitted country-coded names with shared country-coded site registry, reader-facing category, and country-coded study-site names.

Replace reader prose and table strings that call Other/unspecified heterogeneous with the accepted display-only qualification. Do not alter the transformation rule.

Display input verification states as `Verified` and `Verified current identity` while preserving stored PASS/FAIL values and fail-closed code. Display construction and estimability states in sentence case.

### Reader-facing tables

In `tbl-h04-prep-multiplicity`, map the stored scopes and decision roles to plain reader descriptions. Display `FDR`, not `BH`. Preserve every family member, method, family size, alpha, and decision.

Use spaced reader labels in the transformation, primary specification, estimand, script map, output map, and render-boundary tables. This includes `Scientific reason`, `Near eye`, `Source model`, `Reference distribution`, `Inferential role`, `Principal outputs`, `Run on this page`, `Output group`, `Reader use`, and `Calculated on render`.

Replace the reader phrase `registered 10^10 gate` with `predefined 10^10 threshold`. Preserve the exact value and decision.

Use `stored outputs` and `analysis record` in reader narrative where `artifacts`, `manifest`, or execution mechanics are not needed for comprehension. Retain exact technical paths, checksums, commands, and package names in subordinate reproducibility sections.

The companion must retain exactly 37 table and four figure endpoints, each once. No endpoint may be added or removed.

### Computation boundary

The companion must remain display-only. Do not source or run a model builder. Do not fit, refit, predict, simulate, bootstrap, resample, rerun a Shapley allocation, recalculate p-values, regenerate source data, or write any project output. Existing lightweight descriptive summaries from stored data may remain exactly as accepted.

## Handoff refresh

Update `audit/handoffs/H04_worker_handoff.md` to record:

- the final result and companion identities;
- the accepted primary, Mundlak, and participant random-intercept scientific-role distinctions;
- the exact reciprocal dynamic links and auxiliary anchor;
- the source-only verification commands and results;
- the preserved Stage 3 and preparation manifests and stale HTML identities;
- the deferred two-figure baked-label refresh list; and
- the continued REPORT-017 render hold.

Do not propose a new central scientific decision and do not alter H04's closed status.

## New source-only test and non-circular seal

Create `tests/hypotheses/H04/test_h04_report017_source_harmonization.R`. It must require R 4.6.1 and verify, without executing either QMD:

- exact result endpoint set: 17 tables and seven figures, each once, with `fig-h04-primary-estimates` and `tbl-h04-primary-results` first;
- exact companion endpoint set: 37 tables and four figures, each once;
- every result and companion R chunk parses without execution;
- exact formula and scientific numeric-token preservation outside an explicit editorial allow-list;
- existing inline-R, top-level assignment, artifact-reference, and source-data-reference sets, allowing only the minimum non-mutating structure and display assignments;
- the random-intercept anchor and exact result link, general reciprocal links, five preregistration links, central anchors, preparation links, and all source-data targets;
- no hard-coded internal HTML, build, file, absolute-local, or root-absolute page links;
- approved vocabulary, country-coded sites, no visible submitted-site production wording, no unexplained reader heterogeneity, no visible internal family IDs, and no reader-facing BH abbreviation;
- exact primary, Mundlak, and participant random-intercept formulas, roles, stored estimands, limitations, script map, and output map;
- no project-side write, fit, refit, predict, simulate, bootstrap, resample, Shapley, or artifact-regeneration call in either QMD;
- all five existing H04 tests and both existing report manifests retain their exact preflight hashes and byte counts;
- all protected scientific artifacts, stale HTML files, profile, deviation page, site registry, output catalog, and accepted post-closure check remain byte-identical; and
- the two stored figure families still contain the known baked labels and retain their exact preflight identities pending a later authorized refresh.

Create a new non-circular order-35 source manifest under `audit/hypotheses/H04/report017_order35/`. It must pin:

- final result and companion QMDs;
- final handoff and new source-only test;
- unchanged current H04 tests;
- unchanged Stage 3 and preparation manifests;
- unchanged current HTML files as stale render context;
- accepted random-intercept model, summary, allocation, diagnostics, environment, manifest, and post-closure synchronization evidence;
- principal and supplemental figures, their source data, and consequential scientific artifacts;
- deviation page, site registry, profile, output catalog, and consolidated order package as read-only context; and
- bounded audit, exact diff, reverse-proof, protected-inventory, baked-label inventory, and execution records.

Exclude the new manifest itself and any circular dependency. Do not claim that either current HTML corresponds to the revised source.

## Stored-figure label inventory only

Do not regenerate figures. Record exact pins and the minimum accepted display construction for these two later refresh targets:

1. `H04_reader_heterogeneity_category_estimates.{png,pdf,svg}`. Current SHA-256 values are PNG `b2f883b89fa4e482442651f97f6e97c2aed14b48b83cc77050cbe7a1f51ed940`, PDF `65c2a3cbc125df54e9780f9d255dcd624d5c126593afe2658481c803f22d6103`, and SVG `b8bc9612b27ed876bb28bb9e5755f8c6a0564cf20d08ec16a0d68f0402e821ae`.
2. `H04_site_activity_estimates.{png,pdf,svg}`. Current SHA-256 values are PNG `a183754e2d79d6c748caf9747b37e3d52277efc89d586844f225ee45c6f80da0`, PDF `f8afe38e949f03351f8ad4b2af28eb15cbd7e7f2e44fb7144bb40c70354e6a0c`, and SVG `4015ec7e9b5756c1e8efba18b1195763e9bb274a019980430cf9a72cc3c14746`.

The corresponding frozen source data are `H04_reader_heterogeneity_category_figure.csv` SHA-256 `e27bc81e0c6dd2ff50dd0c6ffa4e95d9c7e9c16e5b20ce45fb4df7d1e89f3652` and `H04_site_activity_figure.csv` SHA-256 `f07f54bc288bd660b0e3a107016c7852a64ce72c0f1594df052519062a2c5caf`.

Record the relevant display builders `build_h04_stage3_reader_figures.R` SHA-256 `2ae1ae770d4b0cf3725b04cd337d883659d429ff9a8f7c482d38f0af516c158a`, `h04_reporting.R` SHA-256 `44945d43958f5b7c0c0d484b670d435e0db0a5400b133d5b72cc05a2609e53e3`, and `build_h04_stage3_reader_assets.R` SHA-256 `9fef4f87941e28c0db784d5e9ef2971cd96e1d5f8ffd55847b51ccbcc2a24c60`. Do not edit or execute them.

## Verification

After the complete source revision is assembled, use R 4.6.1 and run this suite once:

1. `tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R` unchanged.
2. New `tests/hypotheses/H04/test_h04_report017_source_harmonization.R`.
3. Parse every R chunk in both QMDs without executing it.
4. Compare pre/post chunk-label, endpoint-label, formula, inline-R, top-level assignment, artifact-reference, source-data-reference, and scientific numeric-token sets using only the explicit editorial allow-list.
5. Verify the exact first-endpoint order and once-only presence of every endpoint.
6. Verify all reciprocal QMD links, the auxiliary anchor, five registration links, central anchors, preparation links, and source-data targets.
7. Verify all protected scientific and display artifacts byte-for-byte.
8. Verify the five existing H04 tests, both current manifests, both stale HTML files, profile, site registry, deviation page, output catalog, and post-closure check are byte-identical.
9. Audit every row in the new non-circular source manifest.
10. Run scoped `git diff --check`.

Record exact commands, R and consequential package versions, runtimes, pre/post identities, stopped attempts, and preservation results. Return one self-contained handoff.

Do not run the render-coupled Stage 3 or preparation tests in this source-only order. They retain pre-editorial HTML and manifest contracts for the later render gate.

## Prohibited work

Do not run Quarto or execute either QMD. Do not fit, refit, predict, simulate, bootstrap, resample, rerun Shapley allocation, recalculate p-values, regenerate figures, rewrite source data, or modify scientific artifacts. Do not edit `_quarto-nathealth.yml`, the semantic hook, `phase4_corpus_manifest.csv`, the output catalog, the coordination matrix, search or sitemap files, any `_build` path, central ledgers or decisions, manuscript files, packages, `renv.lock`, H01, H02, H03, or another hypothesis. Do not commit or push.

Stop after source-only evidence for independent harmonizer acceptance. A later bounded order will repair the two baked figure labels, and a later serial gate will separately authorize one H04 result render and one H04 companion render followed by one combined semantic and visual review.
