# REPORT-017 H04 order 35 stopped-state independent acceptance

Date: 2026-08-15

## Disposition

The order 35 stopped state is accepted as a test-contract stop, not a reader-source or scientific defect. The two revised QMDs remain the complete consolidated H04 source rewrite. No result, formula, sample, estimate, interval, p-value, false-discovery-rate decision, diagnostic, sensitivity, stored artifact, or scientific role was changed by this review.

The stopped-state authority is:

- stopped audit: `audit/hypotheses/H04/report017_order35/H04_order35_stopped_audit.md`, SHA-256 `a6e1da19f7e1e97d6aedadcac931534965271fbd7eadcd56607fafa4727f45ad`;
- source audit: `audit/hypotheses/H04/report017_order35/H04_order35_source_audit.csv`, SHA-256 `6dfc9d80ebc917f9e88c7d63e7119cc4a86d3c6a3ff1226b2a29aa9cf601c111`;
- exact source patch: `audit/hypotheses/H04/report017_order35/H04_order35_exact_source_diff.patch`, SHA-256 `a9c4a58710b09af4d7b89f16fef3c8d9a00607b711443cee316fff3dcacb3d5d`;
- result QMD: SHA-256 `63e815683e1e81dadd480aeb230c7913de7726aa9242f5ce89ec4a0e7e90471c`;
- companion QMD: SHA-256 `52160297aaaa65f9cc0e36839adb0fcbe86e55631c847476b5006f03d657e9da`;
- stopped source test: SHA-256 `02e7494ad081f6395fe19ceca2ed3ded1fe8bc3e8dbaf550e3279f3406ac427f`.

## Complete temporary-copy replay

The stopped source test was copied to `/private/tmp` and changed only for the following four test-contract corrections:

1. The truncated `tbl-h04-prep-output-map` expected digest was completed as `04088ce197cc7462de74c50b72cb6c5b291c3b8ba4cb0f0b5e5f34a4705c7181`.
2. The first excluded historical audit HTML was pinned to its current and Stage 3 identity `59afbcd101e77ceadd7a720ef5e7bceebc22650d3e5d4b623a463d25f8bb2a4b`.
3. The second excluded historical audit HTML was pinned to its current and Stage 3 identity `2e8bcaa35974c7aef36b1cfa9b942a4d7e1baca9cfacc2edb57365bf43aab636`.
4. The role-phrase check removed the ineffective combination `fixed = TRUE, ignore.case = TRUE`. The accepted phrases already match exactly, so retaining only `fixed = TRUE` is stricter and removes seven deterministic R warnings.

The complete corrected source test passed all 37 checks under R 4.6.1 with `digest` 0.6.39 and no warning. Its prospective identity is SHA-256 `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`, 33,144 bytes. The generated temporary audit CSV contains 37 PASS rows and has SHA-256 `09a9d857ef2dce9d46902678e9c5630bdcb4ace93cbc00f4a5d72aa4267f621d`.

The unchanged focused participant random-intercept assessment also passed under R 4.6.1. It read only accepted stored artifacts and did not fit or regenerate a model.

## Full-contract result

The replay confirms all endpoint, chunk, formula, inline-R, numeric-token, artifact-reference, link, anchor, vocabulary, site-name, role-separation, no-scientific-call, protected-package, stored-result, and stored-figure hold checks. No further masked failure remains in either prescribed order 35 test.

This independent review did not edit an H04 owner file, render Quarto, execute a QMD chunk, change a scientific artifact, or alter shared configuration. H04 rendering remains held.
