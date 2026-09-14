# REPORT-014/017 order 36: H05 consolidated reader and companion rewrite

Date: 2026-08-14

Owner: H05 task `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Status: authorized source-only order; every H05 render remains held

## Purpose

Perform one coherent source-only rewrite of the complete H05 result and preparation/provenance pair. Read both documents, the complete current H05 handoff, all three existing H05 tests, all three current H05 report manifests, the full audit, and the complete matrix before editing.

Implement the complete package in one pass. Run the prescribed source-only verification suite once after all edits are assembled. If an unexpected failure occurs, do not enter a piecemeal patch loop. Seal the complete stopped state and return one combined defect list. Do not render.

This order may overlap other source-only work because its mutable path set is H05-specific and disjoint. It must not touch another hypothesis or any shared build, profile, ledger, hook, catalog, or coordination file.

The controlling package is:

- Full audit: `audit/report_harmonization/report017_h05_consolidated_full_document_audit.md`, SHA-256 `c27b15a29fc56142419dda2f2d5ecb860ad18775a67096fdffe857eb00e7932d`.
- Complete 44-row matrix: `audit/report_harmonization/report017_h05_consolidated_change_matrix.csv`, SHA-256 `5edf51a846e2d187bb76a534e4fe533b7e551c929f9fbf659fb8362b88f625b7`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.
- Coordination matrix at dispatch preparation: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `87ee3d5ceb4b80107d789a558acff1a43e5f29f6a4afc601678d11102040e0ec`. It is coordination evidence only and is not an owner execution pin while parallel source work is active.

## Exact owner-scoped preflight pins

- `notebooks/hypotheses/H05.qmd`: `b4167419ce0f22b635d41c98d3d7edda2717fc73e6c963371f79035a334d793c`, 70,979 bytes.
- `audit/hypotheses/H05/H05_analysis_preparation.qmd`: `f7d7d3ef4bdf9b29403e85592b7dd2737f7e3c9dcfdc0ff7275eeefa7735c28f`, 74,171 bytes.
- `tests/hypotheses/H05/test_h05_stage2.R`: `76008cadabc573005f4833c21494a61f034ff376ea6ef92612691e2694bbb1b7`, 17,076 bytes.
- `tests/hypotheses/H05/test_h05_stage3_reader_report.R`: `982162ccbd55def924beff3fbb0e98d31a94884aeb8cc683f817189e1171d4f4`, 30,898 bytes.
- `tests/hypotheses/H05/test_h05_preparation_report.R`: `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`, 15,264 bytes.
- `artifacts/12_manifests/H05/H05_stage2_artifacts.csv`: `09363abf0557646870d0752f08b00f42013deec471a1ea97067c2333a1a811cc`, 15,631 bytes.
- `artifacts/12_manifests/H05/H05_stage3_artifacts.csv`: `9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100`, 42,166 bytes.
- `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`: `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36`, 34,048 bytes.
- `audit/handoffs/H05_stage4_handoff.md`: `896205d9b7f0403e7cb70023ebb392526e58a30825c4d2b151488098602018b4`, 14,619 bytes.

Stable shared read-only context:

- `notebooks/preregistration_deviations.qmd`: `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.
- `config/site_display_registry.csv`: `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.
- `_quarto-nathealth.yml`: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`. Context only; do not edit or render.
- Current result HTML: `58be9b4da8bb67a4322af7096472de1bf97c47d17c79f39078692577a2788b96`.
- Current companion HTML: `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`.
- Phase 2 output catalog: `43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`. Do not edit it.

Stop before editing if any owner-scoped pin differs. A mutable coordinator or harmonizer file may drift outside the owner edit set. Record such drift as context and do not repin it.

## Authorized mutable files

The owner may edit only:

1. `notebooks/hypotheses/H05.qmd`
2. `audit/hypotheses/H05/H05_analysis_preparation.qmd`
3. `audit/handoffs/H05_stage4_handoff.md`
4. New `tests/hypotheses/H05/test_h05_report017_source_harmonization.R`
5. New order-36 audit, exact source diff, reverse proof, protected inventory, execution record, stored-figure inventory, and non-circular source-manifest evidence under `audit/hypotheses/H05/report017_order36/`

Do not edit the three existing H05 tests, any current H05 manifest, any analysis or figure-building script, any data, model, stored table, stored figure, source-data file, build output, profile, central record, harmonizer-owned file, manuscript file, or another hypothesis.

## Scientific boundary

Preserve the accepted H05 analysis exactly:

- near-eye measurements are primary and chest measurements are complementary non-ocular evidence;
- four LEBA factors by 17 metrics form each complete 68-test family;
- zero associations retain FDR-supported evidence;
- four sleep-environment cells remain in the family but are unfit for inference;
- fixed site effects define the primary analysis and the registered random-site structure remains a sensitivity;
- common-sample placement comparisons assess concordance, not equivalence or a direct placement effect;
- MDER is the arithmetic mean of viable one-minute ratios under the accepted positivity and support rule;
- the gap-timing-unaware dataset, leave-one-site-out refits, upper-tail checks, exact-period analysis, and descriptive rank correlations retain their accepted roles.

Do not change a sample, formula, transform, model, estimate, interval, p-value, FDR decision, diagnostic, influence result, sensitivity, figure, source-data row, or scientific claim.

## Complete result-source rewrite

### Target order

Use this coherent reader order:

1. Question and concise Answer in brief.
2. Short orientation covering primary near-eye and complementary chest roles, the four LEBA factors, participant-day, participant-level SD, 95% CI, FDR, and the same-participant and same-participant-day common sample.
3. Primary near-eye result, starting with `fig-h05-near-effects`, then `tbl-h05-near-results-a` and `tbl-h05-near-results-b` as one continued main table.
4. The exact two leading F2 estimates and their non-retained interpretation.
5. Complementary chest evidence.
6. Model checks and the unfit sleep-environment boundary.
7. MDER and upper-tail evidence.
8. Common-sample, random-site, leave-one-site-out, gap-timing-unaware, and exact-period sensitivities.
9. Interpretation and limitations.
10. A late Detailed analysis record containing factor construction, exact samples, formulas, response specifications, registration links, source links, and subordinate technical provenance.

Move content rather than deleting it. Preserve every existing inline-R expression and every scientific numeric token. Do not add new scientific quantities.

Move `tbl-h05-factors`, `tbl-h05-formulas`, `tbl-h05-response-specifications`, and `tbl-h05-near-samples` so they no longer precede the main outputs. Preserve their complete source pipelines, rows, order, values, captions, notes, and IDs.

Make `fig-h05-near-effects` the first figure and `tbl-h05-near-results-a` the first table endpoint. Keep `tbl-h05-near-results-b` immediately after part A. Preserve the exact set of 30 table and seven figure labels, each once.

Add `lightbox: true`. Do not regenerate any figure.

### Progressive disclosure

Keep all central conclusions visible. Use exactly these disclosures for detailed endpoints:

- `Show detailed near-eye model checks`
- `Show complementary chest results and model checks`
- `Show MDER details and upper-tail checks`
- `Show detailed sensitivity results`

Keep captions, alt text, source-data links, and cross-reference targets unchanged in scientific content. Do not hide the unfit-for-inference boundary, zero-of-68 result, leading F2 magnitudes, complementary role, MDER qualification, or overall sensitivity interpretation.

### Reader vocabulary

- Use `near-eye measurements` and explain that they measure light close to the eyes. Do not describe them as direct retinal measurements.
- Keep chest measurements explicitly complementary and non-ocular.
- Explain participant-day, participant-level standard deviation, 95% confidence interval, FDR adjustment, random effect, fixed site effect, Tweedie model, back-transformation, likelihood-ratio comparison, and sensitivity analysis at first use.
- First describe the common sample as the same participants and participant-days at both sensor positions. Then use `common sample` as the short form.
- Explain MDER and the gap-timing-unaware dataset before using the abbreviations or short labels alone.
- Use FDR in reader-facing prose and compact displays. Keep the full Benjamini-Hochberg method name only in subordinate reproducibility text. Do not expose the `BH` abbreviation or internal family IDs to readers.
- Replace submitted-site or submitted-manuscript wording with study-site, country-coded study-site order, or shared site display registry wording.
- Use sentence-case reader labels instead of production states. Preserve code-only internal names required for reproducibility.
- Replace prose em dashes with punctuation or separate sentences. Missing-value dash symbols may remain.
- Keep every literal site name country-coded.

## Complete companion harmonization

### Opening and structure

Add `lightbox: true`. Move the existing About this analysis record callout from Technical provenance to the opening, then rename `Purpose` to `About this analysis record`. Preserve the analysis map and explicit statement that the page does not repeat model computation.

Correct the sentence about the linked registration-record summary so that it says the summary `is mapped there once`. Preserve both reciprocal dynamic QMD links and the result anchor.

### Verification and provenance displays

In `tbl-h05-prep-input-identities`, display `Verified` or `Review needed` instead of PASS or FAIL. Preserve all 17 exact identity comparisons and the fail-closed `stopifnot` logic.

In `tbl-h05-prep-integrity-checks`, change only the stale visible expected value `12 matches` to `17 matches`. The source already requires and observes the exact 17 result-input roles. Map visible status values to sentence-case reader labels while preserving the stored checks.

Replace submitted-manuscript site/order/registry wording with study-site and shared-registry wording. Preserve the exact site set, order, colours, participant counts, and samples.

In the multiplicity table, map internal family IDs to plain family descriptions and display FDR terminology. Preserve all family members, sizes, alpha values, raw and adjusted decisions, and complete-vector checks.

Use spaced reader labels in displayed tables, including `Calculated when rendered`, `Reads or defines`, `Why separate`, `Entry point`, and `Runs when page renders`. Code-only variable names may remain.

Explain random effect, fixed site effect, Tweedie model, back-transformation, likelihood-ratio comparison, and sensitivity analysis at first use. Keep exact formulas and full technical method names in subordinate provenance.

In `tbl-h05-prep-output-identities`, replace only the reader-facing build-directory HTML row with:

- Output: `Reader report source`
- Path: `notebooks/hypotheses/H05.qmd`
- Producer: a plain source-authoring label consistent with the table

Do not expose `_build` paths as reader content. Do not modify any build output.

### Computation boundary

The companion must remain display-only. Do not source or run a model builder. Do not fit, refit, predict, simulate, bootstrap, resample, repeat model checks, rerun leave-one-site-out analyses, recalculate p-values, regenerate source data, or write any project output. Existing lightweight descriptive summaries from stored inputs may remain exactly as accepted.

Retain exactly 22 table and three figure endpoints, each once.

## Handoff refresh

Update `audit/handoffs/H05_stage4_handoff.md` to record:

- final result and companion identities;
- preserved primary and complementary roles and all scientific boundaries;
- exact reciprocal dynamic links and deviation anchor;
- source-only verification command and result;
- preserved existing tests, manifests, stale HTML, profile, and scientific artifacts;
- provisional main and supplemental output roles;
- no stored-figure label refresh required before rendering; and
- continued REPORT-017 render hold.

Do not alter H05's closed scientific status or request a new central scientific decision.

## New source-only test and non-circular seal

Create `tests/hypotheses/H05/test_h05_report017_source_harmonization.R`. It must require R 4.6.1 and verify, without executing either QMD:

- exact result endpoint set: 30 tables and seven figures, each once, with `fig-h05-near-effects` and `tbl-h05-near-results-a` first and `tbl-h05-near-results-b` immediately after part A;
- exact companion endpoint set: 22 tables and three figures, each once;
- every R chunk in both QMDs parses without execution;
- exact formula, inline-R, scientific numeric-token, endpoint-label, artifact-reference, figure-reference, and source-data-reference preservation, allowing only the companion's exact visible `12` to `17` provenance-label transition and an explicit recorded allow-list of non-mutating display assignments;
- all existing top-level scientific assignments are preserved and no fitting, filtering, joining, model, sample, or estimand expression changes outside the approved display-only allow-list;
- reciprocal result and companion QMD links, nine preregistration links and central anchors, Preparation 04 and Preparation 06 links, and all source-data targets;
- no hard-coded internal HTML, build, file, absolute-local, or root-absolute page links;
- approved vocabulary, country-coded sites, no visible submitted-site production wording, no reader-facing internal family IDs, no reader-facing BH abbreviation, and no prose em dash;
- the exact primary and complementary roles, 68-test family, zero retained results, four unfit cells, common-sample interpretation, fixed-site primary role, random-site sensitivity role, MDER definition, and gap-timing-unaware sensitivity boundary;
- no project-side write, fit, refit, predict, simulate, bootstrap, resample, scientific recalculation, or artifact-regeneration call in either QMD;
- the three existing H05 tests and all three existing H05 report manifests retain their exact preflight hashes and byte counts;
- the Stage 2 manifest has zero mismatches;
- the Stage 3 manifest retains exactly its current four-path mismatch set;
- the preparation manifest retains exactly its current four-path mismatch set;
- both current HTML files remain exact stale render context;
- profile, deviation page, site registry, output catalog, principal and supplemental figures, figure builder, source-data files, and protected scientific artifacts remain byte-identical; and
- the three inspected reader figures retain their dimensions and exact identities, with no regeneration.

Create a new non-circular order-36 source manifest under `audit/hypotheses/H05/report017_order36/`. It must pin:

- final result and companion QMDs;
- final handoff and new source-only test;
- unchanged three existing H05 tests;
- unchanged three existing H05 report manifests;
- unchanged current HTML files as stale render context;
- principal and supplemental figures, figure builder, and source-data files;
- consequential model, table, diagnostic, sensitivity, and reconciliation artifacts;
- deviation page, site registry, profile, output catalog, and consolidated order package as read-only context; and
- bounded audit, exact diff, reverse proof, protected inventory, stored-figure inventory, execution record, and package versions.

Exclude the new manifest itself and every circular dependency. Do not claim that either current HTML corresponds to the revised source.

## Stored-figure inventory only

Do not regenerate figures. Record at least these exact current identities:

- `H05_reader_near_eye_effects.png`: `70c1013d51f7619fafe0d38664db7dcf55692990993098948ed443e83c35e1a5`, 2,700 by 2,700 pixels, 300 dpi.
- `H05_reader_near_eye_adequacy.png`: `a457fda5dfb9025f21b72daab52c3e5338ba1657f7183ad4726ddd9b57561edf`, 2,700 by 2,550 pixels, 300 dpi.
- `H05_reader_paired_placement_effects.png`: `b30291d1c1f483202b6b3303045a760e03ef43b1fdf18a36a525543b1a387774`, 2,700 by 2,400 pixels, 300 dpi.
- Main figure source: `H05_reader_near_eye_effect_figure_data.csv`, `e563514cfac059a284d0c38ad733bef708f92ba13fec6686e0aa07804e835ec1`.
- Main result source: `H05_reader_near_eye_results.csv`, `501e3d15df42902063a411f2bf7f823c96ff46ca130d09768024ba5cd60210da`.
- Near-eye sample source: `H05_reader_near_eye_samples.csv`, `5cd4b570980d6a48deb18ae777abadf7aa092c739db84532e2840aa8f583837d`.
- Paired source: `H05_paired_effect_comparison_data.csv`, `fd1a9c8ed252a795d88a68990bd023137b48a1d0956768a850fde65f572afa01`.
- Reader builder: `scripts/hypotheses/H05/build_h05_reader_artifacts.R`, `7cecc2ec14b23085c50da300f04a1506f161df755e21ff636ed92ac1a84a6177`.

The static audit found no baked-label repair to perform before rendering.

## Verification

After the complete source revision is assembled, run this suite once under R 4.6.1:

1. New `tests/hypotheses/H05/test_h05_report017_source_harmonization.R`.
2. Parse every R chunk in both QMDs without executing it.
3. Compare pre/post endpoint labels, formulas, inline R, top-level assignments, artifact references, figure references, source-data references, and scientific numeric tokens using only the explicit editorial allow-list.
4. Verify exact first-endpoint order and once-only presence of every endpoint.
5. Verify all reciprocal QMD links, nine registration links and central anchors, preparation links, and source-data targets.
6. Verify all protected scientific and display artifacts byte-for-byte.
7. Verify the three existing tests, three existing manifests, two stale HTML files, profile, site registry, deviation page, output catalog, and figure builder are byte-identical.
8. Audit every row in the new non-circular source manifest.
9. Run scoped `git diff --check`.

Do not run preliminary project tests. The new test should report all failures together where feasible. If it fails, stop without patching or rerunning and return one consolidated defect list.

Record exact commands, R and consequential package versions, runtimes, pre/post identities, stopped attempts, and preservation results. Return one self-contained handoff.

Do not run the Stage 2 scientific test or the render-coupled Stage 3 and preparation tests in this source-only order. They remain accepted historical and later-render contracts.

## Prohibited work

Do not run Quarto or execute either QMD. Do not fit, refit, predict, simulate, bootstrap, resample, rerun model checks, rerun leave-one-site-out analyses, recalculate p-values, regenerate figures, rewrite source data, or modify scientific artifacts. Do not edit `_quarto-nathealth.yml`, the semantic hook, `phase4_corpus_manifest.csv`, output catalog, coordination matrix, search or sitemap files, any `_build` path, central ledgers or decisions, manuscript files, packages, `renv.lock`, another hypothesis, or a shared file. Do not commit or push.

Stop after source-only evidence for independent harmonizer acceptance. A later serial gate will separately authorize one H05 result render and one H05 companion render followed by one combined semantic and visual review.
