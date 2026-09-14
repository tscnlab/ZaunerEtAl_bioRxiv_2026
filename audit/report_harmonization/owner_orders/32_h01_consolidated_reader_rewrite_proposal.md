# Proposed REPORT-014/017 order 32: H01 consolidated reader rewrite

Status: proposed, pending coordinator approval of the test and manifest classification

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

## Purpose

Perform one coherent source-only rewrite of the complete H01 result and preparation/provenance pair. This order replaces piecemeal editorial follow-ups. Read both documents and all directly dependent tests and current manifests before editing, implement the complete approved matrix in one pass, run the full source-only checks once, and stop for independent acceptance. Do not render.

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

Stop before editing if any pin differs, except expected central-ledger drift that is outside every file named above.

## Authorized files

The owner may edit only:

1. `notebooks/hypotheses/H01.qmd`
2. `audit/hypotheses/H01/H01_analysis_preparation.qmd`
3. `tests/hypotheses/H01/test_h01_reporting_inputs.R`
4. `tests/hypotheses/H01/test_h01_preparation_report.R`
5. `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`
6. `artifacts/12_manifests/H01_reporting_artifacts.csv`
7. `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`
8. `artifacts/12_manifests/H01_worker_artifacts.csv`
9. `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`
10. `audit/handoffs/H01_worker_handoff.md`
11. New H01-owned bounded order-32 audit and non-circular manifest evidence.

Do not edit the display-refresh test unless a source-only assertion directly requires the updated FDR reader label. If such a change is necessary, stop and report it rather than expanding scope silently.

## Complete source changes

Implement every row in `audit/report_harmonization/report017_h01_consolidated_change_matrix.csv`. The required structure and wording are recorded in `audit/report_harmonization/report017_h01_consolidated_full_document_audit.md`.

The scientific wording correction is exact. In `tbl-h01-prep-estimands`, replace the Estimand cell for `Variation represented` with:

> Marginal R², conditional R², participant-associated share, and model-specific term part-R² values that may overlap and must not be summed

Preserve the following source contracts:

- Result endpoint set: exactly 36 `tbl-*` endpoints and 10 `fig-*` endpoints.
- Companion endpoint set: exactly 20 `tbl-*` endpoints and two `fig-*` endpoints.
- Every existing endpoint label remains unchanged.
- Every existing formula string, inline-R expression, top-level prepared object, artifact path, source-data path, numeric token representing a scientific value, table row, table order, figure path, caption meaning, and alt-text scientific content remains unchanged except for the approved reader-language substitutions.
- `fig-h01-model-support` and `tbl-h01-primary-publication-summary` remain the provisional principal outputs and become the first figure and table endpoints in the result flow.
- All 40 relative registration links and 36 unique lower-case anchors remain exact.
- The reciprocal result/companion links remain dynamic relative `.qmd` links.
- Every site name remains country-coded.
- The full Benjamini-Hochberg method name may remain in technical reproducibility. Reader displays use FDR, never BH.
- The complete sample, diagnostic, sensitivity, formula, registration, and source-data records remain present, even when moved into disclosures or the late detailed analysis record.

## Test and manifest classification

The purpose of this part is to end hash-only editorial loops without weakening scientific protection.

1. Preserve every file under `audit/hypotheses/H01/report016/` and every order 31f through 31i historical owner record byte-for-byte.
2. Preserve the eight immutable live-exact rows and every protected scientific-artifact check in the REPORT-016 test.
3. Retain the positive 40-target/36-anchor link contract and all deviation-row and local-alias mappings.
4. Treat current QMD content as a semantic reader-source contract. Resolve the live QMD hash and byte count through the exact current reporting and Stage 3 manifest rows after their bounded reseal.
5. Do not require the current result or companion HTML to equal a new hash during the source-only phase. Preserve the accepted pre-render HTML identities as historical execution evidence. The final live HTML contract belongs to the later harmonizer post-render acceptance.
6. In the preparation test, replace the stale `.html` source-link requirement with the exact relative `.qmd` result and anchor links. Add an explicit source-only branch that runs without requiring a fresh HTML. Retain the complete rendered-HTML branch for the later companion render.
7. Update only the result and companion QMD hash and byte fields in the reporting, Stage 3, preparation, and worker manifests, plus directly dependent test and manifest rows. Do not run a broad manifest builder. Preserve every unrelated pre-existing row, field, order, role, producer, and R version.
8. Keep the current result and companion HTML rows unchanged until the later render gate.
9. Provide exact row-level before/after evidence and reverse proof for every current-manifest edit.

## Verification

Use R 4.6.1 for all source checks. Run the source-only test suite once after all edits are complete:

- full H01 reporting source test;
- full H01 preparation source-only test;
- full REPORT-016 test under its revised historical/current classification;
- focused display-refresh test only if it remains valid without changing its accepted transition purpose;
- parse every R chunk without execution;
- compare chunk-label, table-label, figure-label, formula, inline-R, top-level assignment, artifact-reference, source-data-reference, and scientific numeric-token sets before and after;
- verify the 40-link/36-anchor contract and all relative targets;
- verify no `.html`, `_build`, `file://`, absolute local, or root-absolute link appears in reader source;
- verify no project-side write remains in either QMD;
- verify all current-manifest rows and all historical files;
- run scoped `git diff --check`.

Record exact commands, R and consequential package versions, pre/post identities, runtime, and any stopped attempt. Return one self-contained handoff. Do not rerun or patch iteratively after a new unexpected failure. Seal the complete stopped state and return the full list so any necessary correction can be issued once.

## Prohibited work

Do not render Quarto. Do not execute model or reporting-builder chunks. Do not fit, refit, predict, simulate, bootstrap, resample, recompute p-values, regenerate figures, rewrite source data, or change scientific artifacts. Do not edit the profile, semantic hook, package library, lockfile, central ledgers, manuscript, shared files, other hypotheses, or historical manifests. Do not commit or push.

Stop after source-only evidence for independent harmonizer acceptance. The later gate will authorize one result render and one companion render followed by one combined acceptance review.
