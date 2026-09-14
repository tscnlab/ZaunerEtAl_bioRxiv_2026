# REPORT-014/017 order 33: H02 consolidated reader rewrite

Date: 2026-08-14

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Status: authorized source-only order; every H02 render remains held

## Purpose

Perform one coherent source-only rewrite of the complete H02 result and preparation/provenance pair. Read both documents, the complete current H02 handoff, all directly dependent report tests, and the historical H02 report manifests before editing. Implement the complete approved matrix in one pass, run the source-only verification suite once after all edits are complete, and stop for independent acceptance. Do not render.

This order may overlap H01 order 32 because its entire mutable path set is H02-specific and disjoint. It must not touch any H01 path or any shared build, profile, ledger, hook, catalog, or coordination file.

The controlling package is:

- Full audit: `audit/report_harmonization/report017_h02_consolidated_full_document_audit.md`, SHA-256 `a94562a1ec286d8e86d7cd29e554acd9b349cbac8bd45a691a2832d63240e3be`.
- Complete 27-row matrix: `audit/report_harmonization/report017_h02_consolidated_change_matrix.csv`, SHA-256 `590a4b03b5457ad255ee1cace0f19ba8c567de045417ce0ac1be1f7f2015a0ab`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.
- Coordination matrix at dispatch: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `5120fddcd9eaf1b3bde8999af3e99c2b041e3451a5ac460a374fdaf0fe9d0c45`. This is coordination evidence only and is not an owner execution pin while parallel source work is active.

## Exact owner-scoped preflight pins

- `notebooks/hypotheses/H02.qmd`: `56f6ded2dae5420e36231958d0b1a50f5f938d0d9dd2172301b2340861a0ff20`, 56,571 bytes.
- `audit/hypotheses/H02/H02_analysis_preparation.qmd`: `3d298f2f45165107bc69bbc3b35f1414a5d0cb905d8aa09c839d1e862618e808`, 54,702 bytes.
- `tests/hypotheses/H02/test_h02_reader_report.R`: `c54718734b679139a4d7f0c121c58daf8d5fe5efed49feeef2cc37eac25b185c`, 7,494 bytes.
- `tests/hypotheses/H02/test_h02_preparation_report.R`: `8c42a8a42856e5b9fb190a4e44de716f41ee1c8b7ef4eadd66c12c7663fd823d`, 5,475 bytes.
- `tests/hypotheses/H02/test_h02_paired_placement_display.R`: `17e1706ce8720ac48925e47be1b6ab2c246bbd900c7412b838834e8c39f3404a`, 3,591 bytes.
- `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`: `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7`, 12,457 bytes. Historical render inventory, preserve byte-for-byte.
- `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`: `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331`, 40,049 bytes. Historical worker inventory, preserve byte-for-byte.
- `audit/handoffs/H02_worker_handoff.md`: `0cf26a7038e7c49dc8e9790798b5ed3e1d01a5431cf0e1d8845b02892b96bc94`, 39,985 bytes.

Stable shared read-only context:

- `notebooks/preregistration_deviations.qmd`: `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.
- `config/site_display_registry.csv`: `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.
- `_quarto-nathealth.yml`: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`. Context only; do not edit or render.
- Current result HTML: `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164`.
- Current companion HTML: `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`.

Stop before editing if any owner-scoped preflight pin differs. Shared coordinator files may drift only outside the owner edit set. Report such drift as context and do not repin it.

## Authorized mutable files

The owner may edit only:

1. `notebooks/hypotheses/H02.qmd`
2. `audit/hypotheses/H02/H02_analysis_preparation.qmd`
3. `tests/hypotheses/H02/test_h02_reader_report.R`
4. `tests/hypotheses/H02/test_h02_preparation_report.R`
5. `tests/hypotheses/H02/test_h02_paired_placement_display.R`
6. `audit/handoffs/H02_worker_handoff.md`
7. New H02-owned order-33 audit, source-diff, reverse-proof, protected-inventory, and non-circular manifest evidence under `audit/hypotheses/H02/`.

Do not edit either historical H02 manifest during this source-only order. Do not edit any analysis script, scientific test, data, model, stored table, stored figure, source-data file, build output, profile, central record, harmonizer-owned file, manuscript file, or another hypothesis.

## Complete result-source rewrite

Implement every applicable H02-result row in the matrix while preserving all scientifically necessary detail.

### Target order

Use this coherent reader order:

1. Question and Answer in brief.
2. What was analysed, including the existing glossary.
3. Model and quantities used to compare sites and people.
4. Primary near-eye result, beginning with `fig-h02-near-patterns`, followed by `tbl-h02-near-variation`.
5. Conditional Shapley results and pointwise site windows.
6. Complementary chest result.
7. Direct comparison of near-eye and chest patterns.
8. Model checks and their accepted visible conclusions.
9. Sensitivity analyses.
10. Interpretation and limitations.
11. Detailed analysis record, containing exact fitted samples, the anchored registration record, the topic-organized registration links, source data, and technical provenance.

The main figure and table become the first result figure and first result table endpoints. Move `tbl-h02-near-sample` and `tbl-h02-chest-sample` to the late detailed analysis record. Their rows, values, order, captions, and IDs remain unchanged.

Move the complete `#h02-preregistration-deviations` section and both registration-change tables to the same late record. Add a concise forward source link from the opening scope. Put the link list in a disclosure labelled `Show linked registration entries by topic`. Preserve exactly 22 link occurrences, 18 unique lower-case anchors, every visible stable ID, and every topic-to-ID mapping.

Keep the accepted near-eye and chest model-check conclusions visible. Put `fig-h02-near-diagnostics` with `tbl-h02-near-diagnostics` in `Show detailed near-eye model checks`; put the chest pair in `Show detailed chest model checks`. Preserve their captions, alt text, paths, values, and endpoint IDs exactly.

Add `lightbox: true`. Do not regenerate any figure.

### Reader vocabulary

- Preserve all existing approved first-use explanations for nonlinear GAM analysis, transformed and back-transformed quantities, autocorrelation and AR(1), pointwise 95% CI, site-average curves, participant and participant-day variation, Shapley allocation, matched sample, and the gap-timing-unaware dataset.
- Remove the visible identifier `H02-F1-site-pattern`. Describe it as the single confirmatory near-eye omnibus site-pattern test or the single confirmatory family.
- Use FDR in compact reader-facing language. Do not display the BH abbreviation. The full Benjamini-Hochberg false-discovery-rate method may remain once in subordinate technical reproducibility text.
- Replace prose em dashes. Preserve the missing-value dash symbol in table code.
- Preserve all site names with country codes.

## Complete companion-source rewrite

Implement every companion row in the matrix.

- Add `lightbox: true`.
- Rename `Purpose` to `About this analysis record` and `What is calculated when this page opens` to `Render boundary`.
- Define `model frame` at first use as the exact rows and variables used for one fitted model.
- Remove only `response_source_dir`, its `dir.create()` call, and the two `write_csv()` calls that write the accepted response-distribution CSV files during render. Retain the in-memory `response_distribution_positive` and `response_distribution_zeros` objects and all figure code. Do not read, rewrite, or otherwise modify the frozen CSV files.
- Add reader labels for every visible underscore-separated column named in the matrix.
- Map displayed input-verification status to `Verified` and `Review needed`; preserve stored PASS/FAIL values and all hash checks.
- Remove `H02-F1-site-pattern` from visible settings and notes while preserving the single confirmatory-family meaning.
- Keep exact filenames, commands, hashes, package versions, and the full method name in subordinate technical provenance.
- Preserve the reciprocal result link and exact anchored registration link as dynamic relative `.qmd` links.

## Endpoint and scientific preservation contract

Result source:

- exactly 15 `tbl-*` endpoints and five `fig-*` endpoints;
- all current labels present exactly once;
- `fig-h02-near-patterns` is the first figure endpoint;
- `tbl-h02-near-variation` is the first table endpoint.

Companion source:

- exactly 16 `tbl-*` endpoints and four `fig-*` endpoints;
- all current labels present exactly once.

Across both sources preserve every existing:

- R chunk label and top-level prepared-object assignment, except removal of the authorized write-only `response_source_dir` assignment;
- inline-R expression and scientific numeric token;
- exact selected Wilkinson formula;
- sample definition, estimate, interval, p-value, FDR decision, diagnostic result, sensitivity classification, figure path, table data pipeline, caption scientific content, alt-text scientific content, and source-data reference;
- 22 registration-link occurrences and 18 unique anchors;
- relative source and companion links.

The source audit must fail on any additional assignment, inline expression, formula, artifact reference, numeric-token, endpoint, or scientific-text change outside the explicit editorial allow-list. No source may contain a hard-coded internal `.html`, `_build`, `file://`, absolute local, or root-absolute page link.

## Explicit source-only test mode

Add an opt-in mode named `H02_REPORT_SOURCE_ONLY` to both `test_h02_reader_report.R` and `test_h02_preparation_report.R`. The default, unset or false behavior must remain the complete rendered-HTML test.

Source-only mode may skip only:

- fresh HTML and copied-QMD existence checks;
- rendered DOM, rendered caption, rendered image, rendered navigation, and rendered-link assertions;
- current-file equality for historical render-manifest rows that cannot describe an unrendered source revision.

Source-only mode must retain every source, formula, endpoint, exact sample, accepted value, dynamic link, anchor, source-data target, figure path, native-gt construction, country-code, no-scientific-call, and historical-manifest identity gate. It must assert that both historical H02 manifests retain their exact preflight hashes and that their known historical-to-live mismatch sets do not expand unexpectedly.

Update source-side reciprocal link assertions to relative `.qmd` targets. In the default branch, continue to require Quarto-resolved `.html` links and reject stale `.qmd` hrefs in HTML.

Update reader-display assertions from BH to FDR and reject visible `H02-F1-site-pattern`. Add exact endpoint-order assertions. In `test_h02_paired_placement_display.R`, change only the stale BH source wording assertion to the approved FDR contract and preserve every 112/643/29,786/eight-site and interval assertion.

## Historical manifests and new source seal

Do not run `build_h02_preparation_report_manifest.R` or `build_h02_worker_manifest.R`. Do not edit either existing manifest. They remain historical Aug-1 render inventories, with their current exact hashes and byte counts.

Create a new non-circular order-33 source manifest under `audit/hypotheses/H02/`. It must pin:

- the final two authoring QMDs;
- the final three changed tests;
- the unchanged historical preparation and worker manifests;
- the unchanged current HTML files as stale render context;
- the unchanged stored main and complementary figures, paired-placement source, variation and dominance tables, relevant scientific manifests, deviation page, site registry, and profile context;
- the updated handoff;
- bounded order-33 audit, diff, reverse, and protected-inventory evidence.

The manifest must exclude itself and any circular dependency. Record exact rows, hashes, byte counts, and roles. Do not claim that the current HTML corresponds to the revised source.

## Verification

Use R 4.6.1. After the complete source and test rewrite is assembled, run the source-only suite once:

1. `test_h02_reader_report.R` with `H02_REPORT_SOURCE_ONLY=true`.
2. `test_h02_preparation_report.R` with `H02_REPORT_SOURCE_ONLY=true`.
3. `test_h02_paired_placement_display.R`.
4. Parse every R chunk in both QMDs without executing it.
5. Compare pre/post chunk-label, endpoint-label, formula, inline-R, top-level assignment, artifact-reference, source-data-reference, and scientific numeric-token sets, applying only the explicit write-removal allow-list.
6. Verify the exact first-endpoint order and once-only presence of every other endpoint.
7. Verify all reciprocal QMD links, 22 registration links, 18 unique central anchors, and every source-data target.
8. Verify no project-side write remains in either QMD.
9. Verify all protected scientific and display artifacts byte-for-byte.
10. Verify the two historical H02 manifests and both stale HTML files are byte-identical.
11. Audit every row in the new non-circular source manifest.
12. Run scoped `git diff --check`.

Record exact commands, R and consequential package versions, runtimes, pre/post identities, the current known historical-manifest mismatch sets, and any stopped attempt. Return one self-contained handoff.

If an unexpected failure occurs, do not patch and rerun incrementally. Seal the complete stopped state and return the full failure list so any correction can be issued once.

## Prohibited work

Do not run Quarto. Do not execute either QMD. Do not fit, refit, predict, simulate, bootstrap, resample, rerun Shapley allocation, recalculate p-values, regenerate figures, rewrite source data, or modify scientific artifacts. Do not edit `_quarto-nathealth.yml`, the semantic hook, `phase4_corpus_manifest.csv`, search or sitemap files, any `_build` path, central ledgers or decisions, harmonizer-wide catalogs or matrices, manuscript files, packages, `renv.lock`, H01, or another hypothesis. Do not commit or push.

Stop after source-only evidence for independent harmonizer acceptance. A later serial gate will separately authorize one H02 result render and one H02 companion render, followed by one combined semantic and visual review.
