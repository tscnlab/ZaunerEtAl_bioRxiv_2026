# REPORT-014/017 order 34: H03 consolidated reader rewrite and companion synchronization

Date: 2026-08-14

Owner: H03 task `019fbe52-c067-7521-b2cf-62d9398d173b`

Status: authorized source-only order; every H03 render and figure refresh remains held

## Purpose

Perform one coherent source-only rewrite of the complete H03 result and preparation/provenance pair. This order combines the full reader-harmonization pass with the already authorized RH-SYNC-H03-001 companion synchronization. Read both documents, the complete current H03 handoff, the four current H03 tests, both report manifests, H03-AUX-001 / CHG-139, and the complete matrix before editing.

Implement the complete package in one pass. Run the prescribed source-only verification suite once after all edits are assembled. If an unexpected failure occurs, do not enter a piecemeal patch loop. Seal the complete stopped state and return one combined defect list. Do not render.

This order may overlap H01 order 32 and H02 order 33 because its entire mutable path set is H03-specific and disjoint. It must not touch H01, H02, another hypothesis, or any shared build, profile, ledger, hook, catalog, or coordination file.

The controlling package is:

- Full audit: `audit/report_harmonization/report017_h03_consolidated_full_document_audit.md`, SHA-256 `e43a703aec1d2e70a79b9bac970857fe2928b727ad46849745673770d8e0b176`.
- Complete 38-row matrix: `audit/report_harmonization/report017_h03_consolidated_change_matrix.csv`, SHA-256 `917e29f200fd9e3554e14561307c262203a5ce455eb4614e5006bf878abd313c`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.
- RH-SYNC-H03-001: `audit/report_harmonization/h03_postclosure_synchronization_check.md`, SHA-256 `569767a839a34f1dc3e58ea8c5b554da23a56163a2cf48ad90d7a17cd05b1aea`.
- H03-AUX-001 / CHG-139: `audit/decisions/h03_auxiliary_model_assessments_closure.md`, SHA-256 `85be31f6c105ea2c47a5353a32d4081dcdbc50a0738998f2106c0952c4527827`.
- Coordination matrix at dispatch preparation: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `5120fddcd9eaf1b3bde8999af3e99c2b041e3451a5ac460a374fdaf0fe9d0c45`. This is coordination evidence only and is not an owner execution pin while parallel source work is active.

## Exact owner-scoped preflight pins

- `notebooks/hypotheses/H03.qmd`: `5d329c24afbd321a2be8d87ca7453a8612ab6745d009d4cecef2c82a4c6dd59a`, 67,332 bytes.
- `audit/hypotheses/H03/H03_analysis_preparation.qmd`: `b7671d848544228088df9bbe179a172fd7402e7fa18c3029be9b499d0ef2f760`, 64,129 bytes. This is an accepted pre-existing owner modification in the shared checkout.
- `tests/hypotheses/H03/test_h03_stage3_reader_report.R`: `0af80c8dfede663d724c488f5b7947ca8635a944d789f7a552f6e932999bd3ef`, 18,080 bytes.
- `tests/hypotheses/H03/test_h03_preparation_report.R`: `bddaa2393ead9317c5f526a00f75d2fd86e0e7efeaf84dcd2737e61b149a058a`, 8,412 bytes.
- `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R`: `30fa488114886eb4e9feeccc55f6f752e229585bfc1f2eb5b5a85bfba582bfc8`, 7,568 bytes.
- `tests/hypotheses/H03/test_h03_stage2.R`: `a174e3fe2a1a7832a5f6e8e8a98a3da8d88d85bd30e22917e554ae658f7ce596`, 19,424 bytes.
- `artifacts/12_manifests/H03/H03_stage3_artifacts.csv`: `5f4f10528f1c49d52518a6dde36d6ce0ffd71869cab9bcde382bf9c9edce3170`, 83,962 bytes. Preserve byte-for-byte as the accepted pre-editorial scientific-closure inventory.
- `artifacts/12_manifests/H03/H03_preparation_report_manifest.csv`: `5235b02c6c542a010336eca9569b77b269deb673d4659d794393d2427146393a`, 81,124 bytes. Preserve byte-for-byte as historical render evidence.
- `audit/handoffs/H03_worker_handoff.md`: `dae48601f0ba90ee2932556b312ac2e0e94db0bc695ea242c01328c9ea6a0fec`, 23,752 bytes.
- `scripts/hypotheses/H03/run_h03_participant_random_intercept_assessment.R`: `662e7ac81b3b67693023acdb196b2187d7058e863294b7b77e0105b8ca456f4c`, 16,328 bytes.
- `artifacts/12_manifests/H03/H03_near_eye_participant_random_intercept_manifest.csv`: `81bab5291ca9f9aa24a39cae991857b8f5b39046090da2e4f4c984f4ea7c2306`, 2,190 bytes.

Stable shared read-only context:

- `notebooks/preregistration_deviations.qmd`: `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.
- `config/site_display_registry.csv`: `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.
- `_quarto-nathealth.yml`: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`. Context only; do not edit or render.
- Current result HTML: `68aa07eb7470286d0d6da76114ce7bf346ee635974fe7403c1860ad4560c3d25`.
- Current companion HTML: `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`.
- Phase 2 output catalog: `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`. It already contains `tbl-h03-participant-random-intercept`; do not edit it.

Stop before editing if any owner-scoped preflight pin differs. A mutable harmonizer or coordinator file may drift outside the owner edit set. Record such drift as context and do not repin it.

## Authorized mutable files

The owner may edit only:

1. `notebooks/hypotheses/H03.qmd`
2. `audit/hypotheses/H03/H03_analysis_preparation.qmd`
3. `audit/handoffs/H03_worker_handoff.md`
4. New `tests/hypotheses/H03/test_h03_report017_source_harmonization.R`
5. New order-34 audit, source-diff, reverse-proof, protected-inventory, stored-figure-label inventory, execution record, and non-circular source-manifest evidence under `audit/hypotheses/H03/report017_order34/`

Do not edit the four current H03 tests, either current H03 manifest, any analysis or figure-building script, any data, model, stored table, stored figure, source-data file, build output, profile, central record, harmonizer-owned file, manuscript file, or another hypothesis.

## Complete result-source rewrite

Implement all H03-result rows in the matrix while preserving every scientific distinction and endpoint.

### Target order

Use this coherent reader order:

1. Question and concise Answer in brief.
2. Short orientation to the near-eye primary role, chest complementary role, outcome, site-average estimate, and observation unit.
3. Model and reported quantities.
4. Principal results, starting with `fig-h03-primary-estimates` and then `tbl-h03-primary-results`.
5. Omnibus and category-by-site interaction context.
6. Site-specific context and descriptive model performance.
7. Exploratory participant random-intercept assessment.
8. Model checks and sensitivities.
9. Same-participant, same-hour placement comparison.
10. Exploratory nonlinear time-of-day and linear-latitude context.
11. Interpretation and limitations.
12. Detailed analysis record with exact support tables, the detailed category and site lines moved from the opening callout, registration links, formulas, source data, and provenance.

Move `tbl-h03-overall-samples` and `tbl-h03-category-support` to the late detailed record. Their source pipelines, rows, order, values, captions, and IDs remain unchanged. Move, rather than delete, the existing seven category and six site-deviation inline lines from the opening callout. Preserve every existing inline-R expression and scientific numeric token.

Make `fig-h03-primary-estimates` and `tbl-h03-primary-results` the first figure and table endpoints. Preserve the exact set of 14 table and eight figure labels, each exactly once.

Keep the accepted model-check, sensitivity, temporal, and latitude interpretations visible. Put their detailed endpoints in the exact disclosures named in the matrix. Preserve captions, alt text, paths, source-data links, and cross-reference targets.

Add `lightbox: true`. Do not regenerate any figure.

### Reader vocabulary

- Use `category-by-site interaction` in reader prose, explained as an association allowed to differ by study site. Code-only object names and historical filenames containing `heterogeneity` remain unchanged.
- Replace only the visible auxiliary-table group `Participant heterogeneity` with `Participant-level variation`.
- Replace the visible `submitted site palette` phrase with the shared country-coded site order and colours.
- Retain the approved first-use explanations for site-average estimates, FDR, nonlinear GAM analysis, AR(1), 95% CI, Shapley allocation, transformed quantities, and same-participant comparisons.
- Use FDR in compact reader displays. The full Benjamini-Hochberg method name may remain in technical reproducibility text. Do not introduce reader-facing `BH`.
- Replace prose em dashes with punctuation or separate sentences. Missing-value dash symbols may remain.
- Keep all country-coded site names, including captions and alt text.

### Participant random-intercept link and boundary

Add exactly one dynamic source link from the auxiliary result subsection to:

```text
../../audit/hypotheses/H03/H03_analysis_preparation.qmd#sec-h03-prep-participant-random-intercept
```

Keep all four existing stored-data links. Preserve the explicit boundary that the auxiliary model is descriptive, model-dependent, non-causal, and not a unique allocation. Preserve the absence of random slopes, participant-day effect, and AR(1), and the residual lag-one and zero-mass qualifications.

## Complete companion synchronization and harmonization

### Opening and shared vocabulary

Add `lightbox: true`. Rename `Purpose` to `About this analysis record`. Replace visible references to submitted site registries with the shared country-coded site registry, order, and colours. Display input verification states as `Verified` and `Review needed` while preserving stored PASS/FAIL values and checks.

### Display-only auxiliary reads

In the setup, read the accepted auxiliary files by exact path. Read only. Do not source or execute the auxiliary runner and do not deserialize a model unless needed solely to verify a sealed identity. Prefer the stored summary, Shapley, model-check, environment, and manifest CSVs for display.

The six-file controlling auxiliary manifest must verify exactly. No model fit, refit, prediction, simulation, bootstrap, resampling, Shapley calculation, or artifact write may occur.

### New companion subsection

Immediately after `### Descriptive model performance`, add:

```markdown
### Exploratory participant random-intercept assessment {#sec-h03-prep-participant-random-intercept}
```

Explain in plain language that a participant random intercept lets each participant have a stable overall exposure level while the site, light-source, and category-by-site terms remain fixed effects. Then state the exact stored formula, Tweedie log-link family, maximum-likelihood fit, fixed power 1.539919, and accepted sample.

Add one native gt endpoint with a new stable `tbl-h03-prep-*` label. It should display the exact stored marginal R-squared, conditional R-squared, participant increment, adjusted and unadjusted ICC, Shapley components and percentages, and fit checks. Use `participant-level variation`, not participant heterogeneity, in reader labels.

State explicitly:

- the five hierarchy-valid nested fits converged without warnings, had positive-definite Hessians, and were non-singular;
- the assessment has no random slopes, participant-day effect, or AR(1);
- lag-one Pearson residual correlation 0.288 and the zero-mass mismatch remain;
- the point summaries are descriptive, model-dependent, non-causal, not uncertainty-qualified, and not a unique allocation;
- this model does not replace the primary population-mean model or change its omnibus or multiplicity families; and
- the separate within-participant and between-participant sensitivity is a population-mean quasi-Tweedie augmentation with participant-clustered covariance. It is not a mixed model, random-intercept model, random-slope model, or variance-component analysis.

### Code and output maps

Add `run_h03_participant_random_intercept_assessment.R` in its analytical position and mark it `No` for run on this page. Add the accepted model, summary, Shapley, nested-model checks, diagnostics, environment, and six-file manifest to the output map.

Apply reader-facing spaced labels to the estimand, script, output, and render-boundary tables. Replace internal family IDs in the visible multiplicity table with plain descriptions while preserving every family member, adjustment, and alpha.

Preserve the dynamic companion-to-result links. Do not introduce internal `.html`, `_build`, `file://`, absolute-local, or root-absolute page links.

The companion must retain every existing 26 table and four figure endpoints exactly once and add only one new auxiliary table, for 27 tables and four figures.

## Handoff refresh

Update `audit/handoffs/H03_worker_handoff.md` to record:

- the final result and companion identities;
- H03-AUX-001 / CHG-139 and RH-SYNC-H03-001;
- the scientific distinction between the population-mean within/between sensitivity and the descriptive participant random-intercept assessment;
- the exact reciprocal dynamic link and new companion anchor;
- the accepted auxiliary script and six-file manifest;
- the source-only verification commands and results;
- the preserved historical Stage 3 and preparation manifests; and
- the deferred two-figure baked-label refresh list.

Do not propose a new central scientific decision and do not alter H03's closed status.

## New source-only test and non-circular seal

Create `tests/hypotheses/H03/test_h03_report017_source_harmonization.R`. It must require R 4.6.1 and verify, without executing either QMD:

- exact result endpoint set: 14 tables and eight figures, each once, with `fig-h03-primary-estimates` and `tbl-h03-primary-results` first;
- exact companion endpoint set: all 26 previous tables plus exactly one new auxiliary table, and all four existing figures;
- every result and companion R chunk parses without execution;
- exact formula and scientific numeric-token preservation outside an explicit editorial allow-list;
- existing inline-R, top-level assignment, artifact-reference, and source-data-reference sets, allowing only the minimum new non-mutating companion display assignments and auxiliary reads;
- the new anchor, exact dynamic result link, existing reciprocal links, five preregistration links, and all source-data targets;
- no hard-coded internal HTML, build, file, absolute-local, or root-absolute page links;
- approved vocabulary, country-coded sites, no visible submitted-site production wording, no visible internal multiplicity IDs, and no reader-facing BH abbreviation;
- exact auxiliary formula, model distinction, stored estimands, limitations, script map, output map, and six-file manifest identity;
- no project-side write, fit, refit, predict, simulate, bootstrap, resample, Shapley, or artifact-regeneration call in either QMD;
- both existing H03 manifests retain their exact preflight hashes and byte counts;
- the historical preparation-manifest mismatch set is exactly the seven paths recorded in the full audit before this order, with no silent normalization;
- all protected scientific artifacts, current HTML files, profile, deviation page, site registry, output catalog, and H03-AUX-001 decision remain byte-identical; and
- the two stored figure families still contain the known baked BH labels and retain their exact preflight identities pending a later authorized refresh.

Create a new non-circular order-34 source manifest under `audit/hypotheses/H03/report017_order34/`. It must pin:

- final result and companion QMDs;
- final handoff and new source-only test;
- unchanged current H03 tests;
- unchanged Stage 3 and preparation manifests;
- unchanged current HTML files as stale render context;
- H03-AUX-001, RH-SYNC-H03-001, the auxiliary runner and its six-file manifest;
- principal and supplemental figures, their source data, and consequential scientific artifacts;
- deviation page, site registry, profile, output catalog, and consolidated order package as read-only context; and
- bounded audit, exact diff, reverse-proof, protected-inventory, baked-label inventory, and execution records.

Exclude the new manifest itself and any circular dependency. Do not claim that either existing HTML corresponds to the revised source.

## Stored-figure label inventory only

Do not regenerate figures. Record exact pins and the minimum accepted display construction for these two later refresh targets:

1. `H03_near_eye_site_context_estimates.{png,pdf,svg}`. Current SHA-256 values are PNG `382a929e9ca5a9154fff3c509ba9bf116ebce00d61dd60227d559d10009872a8`, PDF `d13a4daa0ddba02c308e297cd6f9d7b8eca8c6214d73a10a34063d3c064f85b0`, and SVG `7b433203d57f2b7b91a0a46b8b187c89cc959a24146e3335e2c6e5d327ae7541`.
2. `H03_reader_latitude_category_slopes.{png,pdf,svg}`. Current SHA-256 values are PNG `e27b7a8d84cabae1ab3e9694302a275da2f7bfd106df02a530a54ed48f5d9a15`, PDF `d2db711358d6cdfd3f4c54e686449102208de48b2c325a35382f860f4253bfbe`, and SVG `b994deeaa3c6335912cdc14ef0d53af932103091479d43d6665680320bfb75ec`.

The corresponding frozen source data are `H03_near_eye_site_context_figure_data.csv` SHA-256 `2d4ce68c9ac3fba8b31b5b7f190ee0f923ed1ba5d741045040cfde51e011f172` and `H03_reader_latitude_figure_data.csv` SHA-256 `30bb81bb176440368a45d8b3fd6e3fdc443a53d10eb440995cb0c904954536b2`.

Record the relevant display functions in `h03_reporting.R` SHA-256 `1412a89c52a5aa7d65559de5e2b927dcbaad64a990bffb11dc876e6fad6a2342` and `build_h03_stage3_revision.R` SHA-256 `6d1eaacee852865b7b696653d0ee27cfd23d2001085aaf8612e2874521f87379`. Do not edit or execute them.

## Verification

After the complete source revision is assembled, use R 4.6.1 and run this suite once:

1. `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R` unchanged.
2. New `tests/hypotheses/H03/test_h03_report017_source_harmonization.R`.
3. Parse every R chunk in both QMDs without executing it.
4. Compare pre/post chunk-label, endpoint-label, formula, inline-R, top-level assignment, artifact-reference, source-data-reference, and scientific numeric-token sets using only the explicit editorial/new-display allow-list.
5. Verify the exact first-endpoint order and once-only presence of every endpoint.
6. Verify all reciprocal QMD links, the new auxiliary anchor, five registration links, central anchors, and source-data targets.
7. Verify all protected scientific and display artifacts byte-for-byte.
8. Verify the existing H03 tests, both historical/current manifests, both stale HTML files, profile, site registry, deviation page, and output catalog are byte-identical.
9. Audit every row in the new non-circular source manifest.
10. Run scoped `git diff --check`.

Record exact commands, R and consequential package versions, runtimes, pre/post identities, stopped attempts, and preservation results. Return one self-contained handoff.

Do not run the render-coupled Stage 3 or preparation tests in this source-only order. They retain historical HTML and manifest contracts for the later render gate.

## Prohibited work

Do not run Quarto or execute either QMD. Do not fit, refit, predict, simulate, bootstrap, resample, rerun Shapley allocation, recalculate p-values, regenerate figures, rewrite source data, or modify scientific artifacts. Do not edit `_quarto-nathealth.yml`, the semantic hook, `phase4_corpus_manifest.csv`, the output catalog, the coordination matrix, search or sitemap files, any `_build` path, central ledgers or decisions, manuscript files, packages, `renv.lock`, H01, H02, or another hypothesis. Do not commit or push.

Stop after source-only evidence for independent harmonizer acceptance. A later bounded order will repair the two baked figure labels, and a later serial gate will separately authorize one H03 result render and one H03 companion render followed by one combined semantic and visual review.
