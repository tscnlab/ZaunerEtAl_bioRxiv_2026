# REPORT-014/017 order 35a: H04 complete test-contract correction and source seal

Date: 2026-08-15

Owner: H04 task `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: prepared for coordinator review and release

## Purpose

Order 35 completed the consolidated reader and preparation/provenance rewrite, then stopped after its only source-only suite exposed two expectation defects in the new test. Independent review replayed the complete corrected test and the separate participant random-intercept assessment. All checks pass. This order applies the complete test-only correction once and seals the already completed H04 source rewrite without rendering.

Controlling independent review:

`audit/report_harmonization/report017_h04_order35_stopped_state_independent_acceptance.md`

## Exact preflight pins

Stop without editing if any of these identities differs:

- `notebooks/hypotheses/H04.qmd`: `63e815683e1e81dadd480aeb230c7913de7726aa9242f5ce89ec4a0e7e90471c`;
- `audit/hypotheses/H04/H04_analysis_preparation.qmd`: `52160297aaaa65f9cc0e36839adb0fcbe86e55631c847476b5006f03d657e9da`;
- `tests/hypotheses/H04/test_h04_report017_source_harmonization.R`: `02e7494ad081f6395fe19ceca2ed3ded1fe8bc3e8dbaf550e3279f3406ac427f`;
- `tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R`: `247523ec05b484e161e2717a21d33314375370b84413a3bbcfb150582b86ad90`;
- stopped audit: `a6e1da19f7e1e97d6aedadcac931534965271fbd7eadcd56607fafa4727f45ad`;
- stopped source audit: `6dfc9d80ebc917f9e88c7d63e7119cc4a86d3c6a3ff1226b2a29aa9cf601c111`;
- exact source patch: `a9c4a58710b09af4d7b89f16fef3c8d9a00607b711443cee316fff3dcacb3d5d`;
- protected inventory: `5580faa3ef816fc3baacd6e91b0ebc9e4e5b27a0cc8431ca532af1a5f83cad41`;
- Stage 3 artifact manifest: `6215a9496f5f542ff92c19536b5601aa49c1ca804523eb7f9ff8bfdff852e115`;
- H04 consolidated package manifest: `ab0cfd8b663c70d78e4d6b2b9adaf507bf547c7ae21190e4ff2aec81ff3bca89`;
- result HTML, retained as stale render evidence: `cad724ca28c651db62f2bb11a51d0d53adbf133785a6d9477f600900269e3cbe`;
- companion HTML, retained as stale render evidence: `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`;
- Nature Health profile, recorded only as shared context: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

The harmonizer coordination-matrix identity is dispatch evidence only. It is not an owner execution pin while disjoint source-only orders run in parallel.

## Only authorized edit

Edit only `tests/hypotheses/H04/test_h04_report017_source_harmonization.R` and make exactly these four corrections:

1. Replace the truncated `tbl-h04-prep-output-map` expected hash with `04088ce197cc7462de74c50b72cb6c5b291c3b8ba4cb0f0b5e5f34a4705c7181`.
2. Replace the expected hash for `audit/hypotheses/H04/01_audit_and_plan.html` with `59afbcd101e77ceadd7a720ef5e7bceebc22650d3e5d4b623a463d25f8bb2a4b`.
3. Replace the expected hash for `audit/hypotheses/H04/02_implementation_and_v0_comparison.html` with `2e8bcaa35974c7aef36b1cfa9b942a4d7e1baca9cfacc2edb57365bf43aab636`.
4. In the existing `scientific_role_separation` phrase check, remove only `ignore.case = TRUE` while retaining `fixed = TRUE`. Do not alter the phrase vector or any other test logic.

The exact post-edit test identity must be SHA-256 `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`, 33,144 bytes. Record an exact four-change reverse proof that reconstructs the pre-edit identity.

## One complete execution and seal

After the edit parses under R 4.6.1, create `audit/hypotheses/H04/report017_order35a/` and run exactly these two tests once, in this order:

```sh
Rscript --vanilla tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R
H04_ORDER35_AUDIT_CSV=audit/hypotheses/H04/report017_order35a/H04_order35a_source_audit.csv Rscript --vanilla tests/hypotheses/H04/test_h04_report017_source_harmonization.R
```

The second test must exit zero with exactly 37 PASS rows and no warning. Record exact commands, R and package versions, runtimes, exit statuses, the four-change diff and reverse proof, protected-identity results, and scoped `git diff --check`.

If either prescribed test fails, stop once and seal the complete state. Do not patch or rerun. If both pass, create only bounded H04-owned order35a execution, audit, and non-circular manifest evidence and return the final test and evidence identities for independent harmonizer acceptance.

## Preservation boundary

Do not edit either QMD, any existing order35 evidence, H04 handoff, current or historical manifest, HTML, figure, table, source data, model, diagnostic, script, shared profile, central ledger, harmonizer record, bibliography, manuscript, package, or lockfile. Do not run Quarto, execute a QMD, fit or refit, predict, simulate, bootstrap, rerun Shapley allocation, regenerate an artifact, render, commit, push, or upload.

H04 REPORT-017 rendering remains held. H01 remains the only active render path.
