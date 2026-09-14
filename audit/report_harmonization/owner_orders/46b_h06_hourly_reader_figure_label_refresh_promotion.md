# REPORT-018 order 46b: H06 hourly reader-figure promotion

Date: 2026-08-21

Owner: H06 hourly owner `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: released for one artifact-promotion continuation. No candidate regeneration, scientific execution, or Quarto render is authorized.

## Authority and disposition

- Original order 46: `audit/report_harmonization/owner_orders/46_h06_hourly_reader_figure_label_refresh.md`, SHA-256 `5e0823af8dcd5f1d05c7248d42b95f78e101615600b73626fcf7fa5cd38b5478`, 16,269 bytes.
- Retry order 46a: `audit/report_harmonization/owner_orders/46a_h06_hourly_reader_figure_label_refresh_retry.md`, SHA-256 `e552c2440654d53b04287f85e99991258348d2dc46768300317344bd08e30411`, 9,100 bytes.
- Independent 46a stopped-state acceptance: `audit/report_harmonization/report018_h06_order46a_stopped_acceptance.md`, SHA-256 `88156a0c502b69c3ed8d2cbe6c344ae09ee1e22d53ca174ff914c4966a3d4a60`, 7,673 bytes.
- The prepared candidate package has passed 61/61 structural/export checks and all 16 visual-QA views. The sole stop is a vector-name representation mismatch in retained-file verification.
- A full disposable end-to-end rehearsal has already passed with the exact implementation and output identities required below.

This order does not reopen candidate construction or display review. It corrects only six vector-name comparisons, promotes the already accepted candidates once, reseals the current Stage 3 manifest directly, and runs the focused test once.

## Hard preflight

Before mutation, reproduce every dispatch-manifest path, hash, and byte count except the coordination matrix, which is dispatch-time evidence only. In particular require:

- result QMD `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2` and companion QMD `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`;
- refresh implementation `98141fec09cdbd32450ef9b4b4c1ed1e29c01680976dc7c959c1fc37bbefa1b8`, 67,057 bytes;
- focused test `4c30795cb4b24dc26d012d5061045ad2c01dc717a0f75e00a690ac843ac4d97a`, 11,372 bytes;
- accepted builders `5431bcdffc65ac0d217f29e3e821699d3f28da1192ba51ce6ab0b77f9f8ac6da`, 20,839 bytes, and `e92aedc03a2f5e75e9c6ce884498ebb69fa8ea79af4ce122325fc2dd26ebd7cd`, 27,545 bytes;
- Stage 3 manifest preimage `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21`, 73,277 bytes;
- all 11 durable exports at their order-46 pre-edit identities;
- controlling temporary inventory `4e6fea5faf24e8fb662ea64f37d6a79736b282237b456edad924cca236c1d554`, 8,183 bytes;
- completed source/value/geometry checks `7db9671c852c44b9ad73797e7cd03cfe150239109260a4dbbe4e0bb74e448419`, 5,720 bytes;
- completed visual QA `0f970cf1402f99b0569a0b5b9e55ec86074a795780f687f72832118c63124fd1`, 1,023 bytes;
- the retained directory `/private/tmp/h06_report018_order46_12a64399139a0` with all 53 inventory paths exact by SHA-256 and byte count;
- its five bounded promotion scratch files at the exact hashes and bytes recorded in the independent stopped-state acceptance;
- both stale H06 HTML files, profile, source CSVs, site registry, H06 daily sources, package lock, and all 1,135 protected paths unchanged.

Stop without patching if any hard pin or any of the 53 retained inventory entries differs.

## Exact six-wrapper correction

Edit only these two files.

### Refresh implementation

In `scripts/hypotheses/H06/refresh_h06_report018_reader_figure_labels.R`, within `verify_temporary_inventory()`, wrap only the two `vapply()` results used for retained-file SHA-256 and byte comparison with `unname()`.

No other byte or logic may change. After Air 0.4.1 formatting and R 4.6.1 parsing, require:

- SHA-256 `cea9e7d1d395df0ad45459cc7bdd9fa493320fdc8ab737e6b957d7c475a47ba1`;
- 67,073 bytes;
- exact two-change diff and reverse proof to `98141fec09cdbd32450ef9b4b4c1ed1e29c01680976dc7c959c1fc37bbefa1b8`.

### Focused test

In `tests/hypotheses/H06/test_h06_report018_figure_label_refresh.R`, wrap only these four `vapply()` results with `unname()`:

1. protected-path SHA-256 vector;
2. protected-path byte vector;
3. owner-manifest SHA-256 vector;
4. owner-manifest byte vector.

No assertion, path, expected value, protected set, or other byte may change. After Air 0.4.1 formatting and R 4.6.1 parsing, require:

- SHA-256 `ead333294b952239ba97fb6562179593847b60da137b670a2ba1954e53c30cdd`;
- 11,422 bytes;
- exact four-change diff and reverse proof to `4c30795cb4b24dc26d012d5061045ad2c01dc717a0f75e00a690ac843ac4d97a`.

Do not execute either project script before both exact postimages, parse checks, Air checks, and reverse proofs pass.

## One promotion from the retained candidates

Do not run `prepare`. Do not create a new candidate directory. Do not regenerate, re-export, or visually revise any figure.

Run the corrected refresh implementation in `promote` mode exactly once through normal R 4.6.1 project-profile startup, using only the established narrow access to the existing user-owned renv cache:

```sh
H06_REPORT018_MODE=promote NATHEALTH_PROJECT_ROOT=<exact-project-root> Rscript scripts/hypotheses/H06/refresh_h06_report018_reader_figure_labels.R
```

The implementation must read the retained directory path already sealed in `temporary_directory.txt`, verify the 53-entry inventory, promote the 11 candidates once, directly reseal the Stage 3 manifest, and write the bounded completion evidence.

Require these exact durable export postimages:

| Durable export | SHA-256 | Bytes |
|---|---:|---:|
| `artifacts/10_figures/H06/H06_reader_primary_effects.png` | `23a1e55b6088db2f7e5d217ee221a026247a4341cb218417c1611d6889e54902` | 158,760 |
| `artifacts/10_figures/H06/H06_reader_primary_effects.pdf` | `a0e86d86462af1c6cc1070404ad9bde8233a0cc36a752f82c18cb56738911d33` | 6,915 |
| `artifacts/10_figures/H06/H06_reader_primary_effects.svg` | `11f323f3b91bea4f0a142b83f0004705754a65c13cf870e9a44cec13987e2a4d` | 22,661 |
| `artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.png` | `88aeef89cda1208a80ead843ca9551011350ed5f78734c57ceee380bf994f02e` | 191,658 |
| `artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.pdf` | `fc5d39926af682d629bca21966dd68dbc9bda89e51a511003004d033d6185694` | 32,383 |
| `artifacts/10_figures/H06/H06_reader_temporal_day_type.png` | `7f8de8989621ccd7b51cd7940bc513dc3883d09c098052335efea172bab28c30` | 366,367 |
| `artifacts/10_figures/H06/H06_reader_temporal_day_type.pdf` | `47c2c24fe5bce1605773f2d89e87e9d837055876e7923ec0d0e083d8a38cc64e` | 16,574 |
| `artifacts/10_figures/H06/H06_reader_temporal_day_type.svg` | `3005cbcd8c8b7a40339542fbe776853567d0ff56ae4d98fa6d2ebee6118110d3` | 57,982 |
| `artifacts/10_figures/H06/H06_reader_temporal_activity.png` | `718c0917cb0aa58e2308cf8cdf9f2af144f80d55769044cc1cc294a84095c3d0` | 366,674 |
| `artifacts/10_figures/H06/H06_reader_temporal_activity.pdf` | `e2afdfaf893081922e9dcefc2d26dbcab689a358084c09a2576c507140cc2f2d` | 16,658 |
| `artifacts/10_figures/H06/H06_reader_temporal_activity.svg` | `07b54b298f8c159432f08fc81b0ca2025915c1eb2128d6b02783f14987c58fb0` | 58,495 |

Require the directly resealed `artifacts/12_manifests/H06/H06_stage3_artifacts.csv` to be exactly SHA-256 `a68785b76ac713aa56b0c66be12b4874f975b036c0c697fbe76250cd1e42cc63`, 75,394 bytes, with 308 unique rows, exactly 13 existing-row updates, and exactly seven appended rows. Do not run a broad manifest builder.

## One focused verification and completion seal

After successful promotion, run the corrected focused test exactly once under normal R 4.6.1 project-profile startup:

```sh
Rscript tests/hypotheses/H06/test_h06_report018_figure_label_refresh.R
```

Require the complete PASS message for 308 unique manifest rows, 13 updates, seven appends, 11 paired exports, four visual-QA families, and all protected identities.

If startup, promotion, or the focused test fails, stop once. Do not patch, regenerate, retry, rerun, or render. Seal the complete state and return the exact failure.

On PASS, return:

- exact refresh and test diffs plus reverse proofs;
- exact promotion and focused-test commands, R/package versions, timings, and exits;
- 53/53 retained-file verification;
- all 11 durable export identities;
- exact 308-row Stage 3 manifest identity and row-level change evidence;
- complete source/value/geometry and visual-QA evidence;
- protected-identity reconciliation;
- scoped `git diff --check` and no-em-dash checks;
- one non-circular owner completion manifest.

## Prohibitions and hold

No `prepare` run, candidate generation, display redesign, builder edit, QMD edit or execution, Quarto command, render, model load, fit, refit, prediction, simulation, bootstrap, resampling, scientific summary, p-value or FDR calculation, source-data write, other artifact regeneration, full manifest builder, profile or ledger edit, package or lock change, deletion, commit, push, upload, or publication is authorized.

H06 result, H06 companion, H06 daily, H07, and every later REPORT-018 render remain held. A separate H06 result-only render order may be released only after independent acceptance of this promoted artifact package.
