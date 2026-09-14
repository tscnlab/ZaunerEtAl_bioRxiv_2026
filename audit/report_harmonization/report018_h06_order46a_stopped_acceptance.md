# REPORT-018 H06 order 46a stopped-state acceptance

Date: 2026-08-21

Disposition: ACCEPTED as a bounded verification-harness stop. The prepared display candidates, visual review, and accepted builder changes are complete. No scientific discrepancy, source-data drift, figure-content drift, or reader-source defect is present. Durable figure promotion and the Stage 3 manifest reseal have not occurred.

## Accepted stopped state

- The order-46a preflight and stopped-snapshot checks passed.
- The corrected refresh implementation is `scripts/hypotheses/H06/refresh_h06_report018_reader_figure_labels.R`, SHA-256 `98141fec09cdbd32450ef9b4b4c1ed1e29c01680976dc7c959c1fc37bbefa1b8`, 67,057 bytes.
- The unchanged focused test is `tests/hypotheses/H06/test_h06_report018_figure_label_refresh.R`, SHA-256 `4c30795cb4b24dc26d012d5061045ad2c01dc717a0f75e00a690ac843ac4d97a`, 11,372 bytes.
- The accepted reader and site builders are already at their exact intended display-only postimages: `5431bcdffc65ac0d217f29e3e821699d3f28da1192ba51ce6ab0b77f9f8ac6da`, 20,839 bytes, and `e92aedc03a2f5e75e9c6ce884498ebb69fa8ea79af4ce122325fc2dd26ebd7cd`, 27,545 bytes.
- The prepared candidate directory is `/private/tmp/h06_report018_order46_12a64399139a0`.
- Its controlling inventory is `audit/hypotheses/H06/report018_order46_figure_label_refresh/temporary_inventory.csv`, SHA-256 `4e6fea5faf24e8fb662ea64f37d6a79736b282237b456edad924cca236c1d554`, 8,183 bytes.
- R 4.6.1 independently reverified all 53 inventory rows: every path exists, all paths are unique, and all SHA-256 identities and byte counts match.
- The directory also contains five bounded promotion scratch files created before the fail-closed comparison. They are the two exact builder patch files, the two exact pre-edit builder reconstructions, and the exact pre-edit Stage 3 manifest reconstruction. Their hashes and sizes are recorded below. They are not candidate exports and are not a scientific mutation.
- The source/value/geometry audit is `7db9671c852c44b9ad73797e7cd03cfe150239109260a4dbbe4e0bb74e448419`, 5,720 bytes.
- The completed visual-QA table is `0f970cf1402f99b0569a0b5b9e55ec86074a795780f687f72832118c63124fd1`, 1,023 bytes.
- All 61 structural and export checks passed. All 16 original-size, 170-mm, 708-pixel, and 200-percent-equivalent visual views passed.
- The order-46a stopped snapshot manifest is `1cb3d10f40e1737eb07dbdb7e7bd0a30d2d4ec9a8935ef11939ad53499f83170`, 1,449 bytes.
- The stopped defect record is `8d1c1fe7677078e59d2dba9d323f0c8863b8a770edb77e63c071eecb8775ab5f`, 107 bytes. Its sole row reports that a retained temporary file changed.

## Exact stop classification

The sole stop is caused by names attached by `vapply()` during `verify_temporary_inventory()`. The CSV columns are unnamed vectors with the same values. `identical()` therefore returns false despite all 53 SHA-256 values and all 53 byte counts matching. The same representation-only issue occurs in two focused-test inventory comparisons. Removing vector names before `identical()` is the smallest fail-closed correction. It changes no candidate, display, builder, artifact, manifest content, or scientific value.

The five extra scratch files in the retained directory are:

| Path basename | SHA-256 | Bytes |
|---|---:|---:|
| `build_h06_stage3_reader_displays.R.patch` | `6c34b718787f6ab885eaf465f0fdfb48b96b4935e4d3bb8398ff075bd8c191c1` | 3,662 |
| `build_h06_stage3_site_specific_screening.R.patch` | `dbffb4e3f7fd5d079f192587a9691c9ba462a5295e04a41359c6aadd2876f0d1` | 1,913 |
| `reverse_build_h06_stage3_reader_displays.R` | `b50bc1396f8d59647d7401849dd1cc23d6a988442fbc03cb2efdfe53d0b83c35` | 20,870 |
| `reverse_build_h06_stage3_site_specific_screening.R` | `9bde77139aff4b38009b8db70c0c152d516d31bf120fd86a9fc362140522378e` | 27,541 |
| `reverse_H06_stage3_artifacts.csv` | `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21` | 73,277 |

## Independent end-to-end rehearsal

A disposable shadow project at `/private/tmp/H06-order46b-shadow.156016482b569` reproduced the complete continuation without altering the project. It applied only the six vector-name removals described below, promoted the retained candidate set, directly resealed the Stage 3 manifest, and ran the focused test.

The rehearsal produced these deterministic implementation identities:

- refresh implementation `cea9e7d1d395df0ad45459cc7bdd9fa493320fdc8ab737e6b957d7c475a47ba1`, 67,073 bytes;
- focused test `ead333294b952239ba97fb6562179593847b60da137b670a2ba1954e53c30cdd`, 11,422 bytes;
- Stage 3 manifest `a68785b76ac713aa56b0c66be12b4874f975b036c0c697fbe76250cd1e42cc63`, 75,394 bytes, with 308 unique rows, exactly 13 updates, and exactly seven appends.

The final direct R 4.6.1 focused-test invocation passed and reported 308 unique manifest rows, 13 updates, seven appends, 11 paired exports, four visual-QA families, and complete protected-identity preservation. One earlier disposable invocation emitted a transient R runtime `VECTOR_ELT` error. The same shadow state then passed both an isolated source invocation and the exact direct invocation. The continuation therefore retains the strict one-run stop rule and does not classify a future runtime failure as pre-approved.

The deterministic promoted export identities are:

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

## Preservation and next gate

At this acceptance point, all 11 durable exports remain at their pre-edit identities and the Stage 3 manifest remains `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21`, 73,277 bytes. Both H06 QMDs, both stale H06 HTML files, profile, frozen source CSVs, H06 daily files, scientific artifacts, package lock, and 1,135 protected paths remain unchanged.

The next gate may only remove the six vector names, reuse the retained candidates, promote once, reseal directly, and run the focused test once. Candidate regeneration, visual rework, Quarto, and scientific computation remain prohibited. H06 result and companion rendering remain held pending independent artifact acceptance.
