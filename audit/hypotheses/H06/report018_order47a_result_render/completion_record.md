# REPORT-018 H06 order 47a stopped completion record

Date: 2026-08-21

Disposition: provenance repin complete; single result render attempted; render stopped on a new reader-source execution defect; no patch or rerender performed.

## Authorized contract transition

The only source mutation was the approved replacement of three SHA-256 literals in `scripts/hypotheses/H06/h06_contract.R`.

- Preimage: `9de4d56e462de9188bf1123984f3b06b3e01b01706a9618026e98f53444de2bb`, 13,468 bytes.
- Postimage: `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`, 13,468 bytes.
- Reverse substitution reproduced the preimage exactly.
- R 4.6.1 parsed the postimage and verified 21 unique, existing, regular, non-symlink paths.
- All 21 current SHA-256 identities matched.
- Exactly the roles `primary_near_eye_hourly`, `complementary_chest_hourly`, and `current_base_model_manifest` changed.

The first ad hoc R verification used a named `vapply()` result against an unnamed contract column and stopped on a representation-only `identical()` mismatch. A corrected read-only expression using `unname()` passed. Neither command modified project state.

## Sole render retry

The one authorized command was:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order47a_semantic.LTK1Qz quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Quarto 1.9.37 used R 4.6.1 and the normal project profile. The command exited 1 after approximately 84 seconds. It completed setup and reached cell 40 of 41, `tbl-h06-figure-readability-checks`, then stopped in `dplyr::select()` because `dplyr::if_else()` referred to `.data$report_011_status` in the tidy-selection context, where `.data` was unavailable.

No second render was attempted. The result QMD was not edited.

## Stopped-state reconciliation

- Result QMD: `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`, 60,677 bytes.
- Held companion QMD: `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`, 59,613 bytes.
- Stale result HTML: `ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`, 6,109,797 bytes.
- Held companion HTML: `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`, 771,694 bytes.
- Pre-render and post-failure build inventories are identical at `46c2e4dbbfa4700e37966af8d7847042e37509369c62535579ef1aed55471353`, with 836 files, no content change, no mtime change, no addition, no removal, and no symlink.
- All 60 protected dispatch paths remained byte-identical.
- The semantic-audit directory `/private/tmp/h06_order47a_semantic.LTK1Qz` is preserved and empty.
- No Quarto, Pandoc, R, H06 render, or loopback-server process remained active after reconciliation.

The render did not produce fresh HTML and the semantic hook did not run. Therefore the 11-table, six-figure, link, DEV-anchor, secure-loopback, and visual QA gates were not reachable and were not performed against the stale page.

No model, prediction, inference, resampling, artifact regeneration, Stage 3 manifest change, QMD change, test run, companion render, H06 daily render, profile change, package change, lockfile change, ledger change, commit, push, upload, or publication occurred.
