# REPORT-018 H10 order 32 source-only dispatch

Date: 2026-08-22

Status: `SEALED_FOR_SINGLE_SOURCE_ONLY_DISPATCH`

Owner: `019fdc1b-b77b-7972-aed0-784da328e115`

## Controlling order and serial boundary

The controlling order remains byte-identical:

- `audit/report_harmonization/owner_orders/32_h10_sex_gender_construct_wording.md`
- SHA-256 `c37577debae69e731c22d0d12966e5deff03f2c14419349d1abd4276c58c9317`
- 7,966 bytes

H09 result and companion integration is independently accepted. H10 is therefore at the next serial safe point for a path-bounded source-only correction. No render is released. H10 result HTML, H10 companion HTML, H11, and every later target remain held pending independent H10 source acceptance.

## Exact mutable preflight pins

| Path | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H10.qmd` | `3c8d6891854a298e4fad69d1d7499c4d45a7d7c522f50e920b6b6aa1e4abac3f` | 49,191 |
| `audit/hypotheses/H10/H10_analysis_preparation.qmd` | `c46d6ae965daba94750220e6eeaf95aa01b5cff4bc929117848f72090b7583f1` | 58,413 |
| `tests/hypotheses/H10/test_h10_stage3_reader_report.R` | `9f683babf2fd036bf33acf71ce5ef694d4a78a2893b5c6d4b54df9b9c01a1c3c` | 23,426 |
| `tests/hypotheses/H10/test_h10_preparation_report.R` | `836a6b48250946375c512895d05a50c77e6472ccccf987510675a33235cdcb22` | 14,764 |

The current owner handoff is `70f4b211d329f893ce5f75ac3e494e634546e160f96761509259f7ba6518087f`. The normal profile remains `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

## Refreshed evidence verification

Fresh binary-safe R 4.6.1 hashing reproduced all 12 historical planning-manifest members exactly. The scientific evidence identities remain:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `artifacts/06_model_data/normalized_inputs/demographics.rds` | `a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf` | 2,824 |
| `artifacts/06_model_data/H10/H10_model_frames.rds` | `2d1c9119409c908f6890062c46827698aff19b12c3bcc93ce15cb37b28b8a6e7` | 381,924 |

The independent read-only construct audit also confirmed:

- the current normalized demographics object has 191 records and 17 fields, with separate nonidentical `sex` and `gender` columns;
- recorded `sex` values are Female and Male, while recorded `gender` values are Man, Non-binary, and Woman;
- all 68 current H10 model frames contain `biological_sex`, none contains `gender`, and the biological-sex values are Female and Male;
- the unchanged 612-row model manifest contains 272 biological-sex formulas and zero formulas containing a gender term; and
- the accepted Stage 1 source and model manifest remain byte-identical to their historical pins.

These findings preserve the order's construct disposition. They do not authorize scientific recomputation or a manifest refresh. The owner must preserve both scientific evidence identities exactly and must stop if either differs at execution.

## Released edit boundary

Exactly four false source passages and their directly dependent source assertions may change, as specified in the controlling order:

1. Result opening paragraph.
2. Result Figure `fig-h10-sex-associations` caption.
3. Companion construct paragraph.
4. Companion model-entry sentence.
5. Only the corresponding source assertions in the two named H10 tests.

The corrected boundary is: biological sex and gender were recorded separately; the accepted analysis used biological sex coded Female or Male; gender was not analysed; the gender variable did not enter a model; and the analysis provides no inference about gender identity.

The accepted limitation beginning `Biological sex was the construct actually recorded` must remain exact except for source line wrapping.

## Execution and stop contract

The owner may use R 4.6.1 only for parsing, source-text checks, exact identity checks, diff/reversal checks, and the focused source-only tests allowed by order 32. The owner must not execute QMD chunks or run Quarto, a model, prediction, simulation, bootstrap, builder, artifact regeneration, broad manifest update, commit, push, or upload.

The two QMDs, two tests, and bounded task-owned evidence are the only mutable paths. Every HTML, artifact, model, scientific value, current or historical manifest, profile, lockfile, shared file, central record, H11 path, and later target is immutable.

Return one complete source-only seal for independent acceptance. Stop once on any unexpected test failure, scientific mismatch, identity drift, or path expansion. No render follows automatically.

## Pre-dispatch verification

- Checker: `scripts/report_harmonization/check_report018_h10_order32_dispatch.R`, SHA-256 `23319d7c823bdc22e6d3465b15a42769e3ac72237f4c92c91b084233f694e146`, 10,498 bytes.
- Verification: `audit/report_harmonization/report018_h10_order32_dispatch_preflight.csv`, SHA-256 `61d0e8065316e3e27714b9cc2bfe35a64d1f76b6fb96400295dd2175d0961805`, 4,365 bytes.
- Result: `REPORT018_H10_ORDER32_DISPATCH_PREFLIGHT=PASS checks=28 stable=18 planning=12/12 construct=4 targets=3 R=4.6.1`.
- Pre-dispatch coordination baseline: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `2c8bf7458598aa31894d04cd4094f7a5237790168ccf641c9f68dbf0694bc614`.
