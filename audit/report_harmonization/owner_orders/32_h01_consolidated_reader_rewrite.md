# REPORT-014/017 order 32: H01 consolidated reader rewrite

Date: 2026-08-14

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: authorized source-only order; H01 rendering remains held

## Purpose

Perform one coherent source-only rewrite of the complete H01 result and preparation/provenance pair. This order replaces piecemeal editorial follow-ups. Read both documents and all directly dependent tests and current manifests before editing, implement the complete approved matrix in one pass, run the source-only checks once after all edits are complete, and stop for independent acceptance. Do not render.

The controlling package is:

- Full audit: `audit/report_harmonization/report017_h01_consolidated_full_document_audit.md`, SHA-256 `7c93a352ebbc310752f589c85e314fe316bc3bd7a6d6c9ec7f9d7266b216d896`.
- Complete 29-row matrix: `audit/report_harmonization/report017_h01_consolidated_change_matrix.csv`, SHA-256 `203b07bde69e0636be899c5747d4453ae1596591aaf022764f2ce3a55a8fbec4`.
- Accepted audit manifest: `audit/report_harmonization/report017_h01_consolidated_audit_manifest.csv`, SHA-256 `23be2bed43364cbb8d0b3cbca7a2d783fd23a708844ee004ebedd7ad562a58de`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.
- Coordination matrix at dispatch: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `9813c8330957efb8534783119ded8f4af98818e42537f3451fad18f8163be438`.

## Preflight pins

- `notebooks/hypotheses/H01.qmd`: `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`, 90,640 bytes.
- `audit/hypotheses/H01/H01_analysis_preparation.qmd`: `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`, 54,405 bytes.
- `tests/hypotheses/H01/test_h01_reporting_inputs.R`: `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`.
- `tests/hypotheses/H01/test_h01_preparation_report.R`: `12b04008e60cab737780947308042634ee06643dddc450502754fade11228bea`.
- `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`: `1aa2e9419fcc25fbfc759ffa0a39aa0556abff5bdc3f2c6e4f1950213bdec2e5`.
- `tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R`: `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`.
- `artifacts/12_manifests/H01_reporting_artifacts.csv`: `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`.
- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`: `16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e`.
- `artifacts/12_manifests/H01_worker_artifacts.csv`: `debce70f59c8e2c401ad36291694604246349633079bcd4d706aba6cf4d548c5`.
- `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`: `bae856c2bb75df317f476e7e993178061628c0fcdbc6795a4b88f78843f8d9d0`.
- `audit/handoffs/H01_worker_handoff.md`: `00ae3a8e9aa6a9203f598d57f21ef462cbc676407f50c162fa0ab14c3457d9b0`.
- `_quarto-nathealth.yml`: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Current result HTML: `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`.
- Current companion HTML: `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

Stop before editing if any pin differs, except expected central-ledger drift outside every file named above.

## Authorized files

The owner may edit only:

1. `notebooks/hypotheses/H01.qmd`
2. `audit/hypotheses/H01/H01_analysis_preparation.qmd`
3. `tests/hypotheses/H01/test_h01_reporting_inputs.R`
4. `tests/hypotheses/H01/test_h01_preparation_report.R`
5. `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`
6. `artifacts/12_manifests/H01_reporting_artifacts.csv`
7. `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`
8. `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`
9. `artifacts/12_manifests/H01_worker_artifacts.csv`
10. `audit/handoffs/H01_worker_handoff.md`
11. New H01-owned bounded order-32 audit, row-diff, reverse-proof, and non-circular manifest evidence.

Do not edit the accepted display-refresh test. If a new failure would require changing it, seal the complete stopped state and return the full failure list.

## Complete source rewrite

Implement every row in the approved change matrix. Preserve all accepted scientific differences and retain the full records even when they move into a disclosure or the late detailed analysis record.

The scientific wording correction is exact. In `tbl-h01-prep-estimands`, replace the Estimand cell for `Variation represented` with:

> Marginal R², conditional R², participant-associated share, and model-specific term part-R² values that may overlap and must not be summed

### Early support orientation

Do not hard-code a new sample number. Prefer an already loaded accepted summary object if it provides the required orientation. Otherwise, exactly one new non-mutating top-level assignment named `h01_support_orientation` is authorized. It may be derived only from the already loaded accepted `exact_samples` object, using grouping, filtering, and summarizing operations. It must not read another file, alter `exact_samples`, join external data, or calculate any model quantity.

New inline-R expressions are allowed only to display named fields from `h01_support_orientation`. Record the exact new assignment and inline-expression allow-list. The source audit must require every pre-existing top-level assignment, inline-R expression, formula, scientific numeric token, and artifact reference to be unchanged and must fail on any addition, removal, or change outside that allow-list.

### Endpoint and disclosure contract

- Result endpoint set: exactly 36 `tbl-*` endpoints and 10 `fig-*` endpoints.
- Companion endpoint set: exactly 20 `tbl-*` endpoints and two `fig-*` endpoints.
- Every existing endpoint label remains present exactly once.
- `fig-h01-model-support` becomes the first result figure endpoint.
- `tbl-h01-primary-publication-summary` becomes the first result table endpoint.
- Moving content into disclosures or the late detailed record must preserve every caption, alt-text scientific statement, source-data link, and cross-reference target.
- Final numbering, lightbox behavior, and disclosure behavior remain later post-render gates. Do not claim them as rendered acceptance now.

### Scientific and vocabulary preservation

- Preserve every existing formula string, model engine, p-value, interval, estimate, decision, sample definition, sensitivity classification, diagnostic classification, table row and order, figure path, source-data path, and scientific claim.
- `fig-h01-model-support` and `tbl-h01-primary-publication-summary` remain the provisional principal outputs.
- All 40 relative registration links and 36 unique lower-case anchors remain exact.
- Reciprocal result and companion links remain dynamic relative `.qmd` links.
- Every study-site name remains country-coded.
- The full Benjamini-Hochberg method name may remain in technical reproducibility. Reader displays use FDR, never BH.
- The complete sample, diagnostic, sensitivity, formula, registration, and source-data records remain present.
- No source QMD may contain a hard-coded internal `.html`, `_build`, `file://`, absolute local, or root-absolute page link.

## Historical and live test contracts

The purpose of this classification is to end hash-only editorial loops without weakening scientific protection.

1. Preserve every file under `audit/hypotheses/H01/report016/` and every order 31f through 31i historical owner record byte-for-byte. Their historical QMD and HTML identities remain evidence and must not be rewritten.
2. Preserve every immutable scientific and stored-output equality check, including the eight live-exact REPORT-016 rows.
3. Retain the complete positive 40-target/36-anchor link contract, deviation-row contract, local-alias mappings, protected scientific-artifact checks, and exact frozen historical-manifest identity.
4. Resolve each live authoring QMD through exactly one matching path row in each declared current reporting and Stage 3 manifest. Require path uniqueness plus exact live hash and byte equality. Fail on a missing or duplicate path.
5. Remove current HTML only from live scientific equality. Do not remove or alter its historical evidence. The source-only order must not claim a live HTML acceptance. Final live HTML belongs to the separately authorized post-render harmonizer record.

## Explicit preparation-test mode

Add an opt-in source-only mode named `H01_PREPARATION_SOURCE_ONLY`. The default, unset or false behavior must remain the complete rendered-HTML branch.

Source-only mode may skip only:

- build or HTML existence checks that require a fresh render;
- rendered DOM, rendered figure, rendered table, rendered download-copy, and rendered-manifest assertions that cannot be satisfied before rendering.

Source-only mode must retain every source, endpoint, formula, dynamic link, anchor, artifact path, scientific value, forbidden-call, native-gt construction, country-coded site, and historical provenance gate. Replace the stale source-side `.html` link assertion with the exact dynamic `.qmd` result and anchor contract in both modes.

## Direct manifest reseal

Do not run any broad manifest builder. Keep every `_build` QMD, HTML, page-asset, search, and sitemap row unchanged during order 32.

Reseal current dependencies from leaves upward:

1. Finalize and hash the two authoring QMDs and three changed source tests.
2. In the reporting and Stage 3 manifests, update only the exact authoring result and companion QMD rows and any directly dependent current test rows that already exist. Preserve every other row, field, role, producer, R version, and order.
3. In the preparation-report manifest, update only the exact authoring result and companion QMD rows and the exact directly dependent current reporting, Stage 3, and test rows that already exist. Do not touch its build or HTML rows.
4. In the worker manifest, update only the exact authoring QMD, changed test, reporting-manifest, Stage 3 manifest, preparation-manifest, and handoff rows that already exist, plus bounded new order-32 evidence rows permitted by the existing convention.

Require exactly one path row for each resealed dependency. Introduce no self-hash or circular row. Record exact row-level before and after values and prove that reversing only the authorized field changes reproduces each pre-edit manifest byte-for-byte.

## Verification

Use R 4.6.1. After all source and direct-manifest edits are complete, run the complete source-only suite once:

- full H01 reporting source test;
- H01 preparation test with `H01_PREPARATION_SOURCE_ONLY=true`;
- complete REPORT-016 test under the approved historical/live classification;
- the accepted display-refresh test, unchanged;
- parse every R chunk without execution;
- compare chunk-label, table-label, figure-label, formula, pre-existing inline-R, pre-existing top-level assignment, artifact-reference, source-data-reference, and scientific numeric-token sets before and after, applying only the recorded `h01_support_orientation` allow-list if that object was needed;
- verify first-endpoint order and exact once-only presence of all other endpoints;
- verify all 40 registration links, 36 unique anchors, reciprocal QMD links, source-data links, and relative targets;
- verify no project-side write remains in either QMD;
- audit every current-manifest row and every frozen historical file;
- run scoped `git diff --check`.

Record exact commands, R and consequential package versions, pre/post identities, runtime, and any stopped attempt. Return one self-contained handoff.

If a new unexpected failure occurs, do not patch and rerun incrementally. Seal the complete stopped state and return the full failure list so any necessary correction can be issued once.

## Prohibited work

Do not render Quarto. Do not execute model or reporting-builder chunks. Do not fit, refit, predict, simulate, bootstrap, resample, recompute p-values, regenerate figures, rewrite source data, or change scientific artifacts. Do not edit the profile, semantic hook, package library, lockfile, central ledgers, manuscript, shared files, other hypotheses, build outputs, or historical manifests. Do not commit or push.

Stop after source-only evidence for independent harmonizer acceptance. The later gate will authorize one result render and one companion render followed by one combined semantic and visual acceptance review.
