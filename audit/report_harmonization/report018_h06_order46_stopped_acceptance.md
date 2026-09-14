# REPORT-018 H06 order 46 stopped-state acceptance and prospective retry verification

Date: 2026-08-21

Disposition: the first order-46 execution stopped before candidate export because the row-count guard combined eight data frames with `c()` rather than `list()`. The stop is accepted as a verification-harness defect. No scientific, source-data, figure, builder, manifest, QMD, HTML, profile, package, or lockfile drift occurred.

## Accepted stopped state

- Refresh implementation: `scripts/hypotheses/H06/refresh_h06_report018_reader_figure_labels.R`, SHA-256 `c84fe32ceb269b1df17457adbe4970d14694f9d5a2add9b86a630929333acefe`, 66,644 bytes.
- Focused test: `tests/hypotheses/H06/test_h06_report018_figure_label_refresh.R`, SHA-256 `4c30795cb4b24dc26d012d5061045ad2c01dc717a0f75e00a690ac843ac4d97a`, 11,372 bytes.
- Authorized-label record: SHA-256 `006c2e3dc5fb1742547df490d04e9a7a04cf4352cdb8755dd136e130cf00b187`, 1,403 bytes.
- Defect record: SHA-256 `0c160304ef40110d378ebc79f4e8c33ae11a8209edd453e3992cb52350a1aad9`, 136 bytes.
- Package record: SHA-256 `4f4581f8833476117ce5174ae9afe3d8d087186b53f02b994b497b2d4a6d5864`, 260 bytes.
- Protected inventory: SHA-256 `56db8715e4b8d4f491e98d8476fa598fbaf676626e70578840b71851917627c7`, 169,631 bytes.
- Retained empty candidate directory: `/private/tmp/h06_report018_order46_117d74905a6e7`.

The exact defect was:

`values must be length 1, but FUN(X[[1]]) result is length 0`

Independent R 4.6.1 replay verified all 48 live dispatch pins exactly. Both accepted builders, all 11 figure exports, the 301-row Stage 3 manifest, both hourly QMDs, both stale hourly HTML files, H06 daily sources, the profile, and every protected scientific path remained at their order-46 preflight identities.

## Independent prospective verification

A temporary copy of the stopped refresh implementation was corrected outside the project and exercised through the normal R 4.6.1 project profile with narrowly elevated access only to the existing user-owned renv cache. No durable project target was written.

- Final prospective refresh: `/private/tmp/refresh_h06_order46_prospective.R`, SHA-256 `98141fec09cdbd32450ef9b4b4c1ed1e29c01680976dc7c959c1fc37bbefa1b8`, 67,057 bytes.
- Prospective driver: `/private/tmp/run_h06_order46_prospective_prepare.R`, SHA-256 `e721a0812a77736e21e958c118af08087a48e35617671f7e54a5ef0e592a92c2`, 686 bytes.
- Passing evidence directory: `/private/tmp/h06_order46_prospective_evidence_120b772556063`.
- Passing candidate directory: `/private/tmp/h06_report018_order46_120b7432b3e39`.
- Source, value, geometry, PNG, PDF, and SVG audit: SHA-256 `7db9671c852c44b9ad73797e7cd03cfe150239109260a4dbbe4e0bb74e448419`, 5,720 bytes, 61/61 checks passed.

The prospective run reproduced every old-label PNG and SVG baseline byte-for-byte and every old-label PDF in page geometry, extracted text, and rendered pixels. It preserved all source rows, mapped layers, coordinate systems, panel counts, dimensions, and permitted data regions. All required replacement labels were present and all retired visible terms were absent.

Manual inspection covered original resolution, 170-mm A4 placement, 708-pixel width, and 200-percent-equivalent views for all four PNGs. The first prospective candidate exposed one additional pre-existing export defect: the long site-screen subtitle clipped at the right edge. The final prospective candidate uses the concise one-line subtitle `Dashed: site-average estimate from this model; filled: retained after nine-site FDR adjustments; open: not retained`. It retains the accepted meaning, fits at final size, and leaves the plot panel geometry unchanged.

The two exploratory temporal footers are explicitly broken into ten rendered lines, matching the accepted baseline line count. This prevents the revised wording from shifting or resizing any data panel. All four final prospective PNGs have legible labels, no clipping or overlap, balanced data regions, and a 7.5-point smallest nominal text size at intended final output size.

## Exact retry classifications

The bounded retry must make only these refresh-harness and display-layout corrections:

1. Use `list()` rather than `c()` for the eight-data-frame row-count `vapply()`.
2. Express expected PNG dimensions as integer literals so `identical()` compares like types.
3. Normalize only SVG `textLength` values before the existing normalized text comparison.
4. Normalize Unicode minus and hyphen characters emitted by PDF extraction to ASCII hyphen for required-label checks.
5. Insert explicit line breaks in the revised temporal footer so it retains ten rendered lines and baseline panel geometry.
6. Use the concise, non-clipping site subtitle above.
7. Update only the directly dependent site-builder literal assertions to require the concise subtitle and reject the superseded long candidate.

The prospectively patched builders parse under R 4.6.1 and have these exact expected post-edit identities:

- `scripts/hypotheses/H06/build_h06_stage3_reader_displays.R`: SHA-256 `5431bcdffc65ac0d217f29e3e821699d3f28da1192ba51ce6ab0b77f9f8ac6da`, 20,839 bytes.
- `scripts/hypotheses/H06/build_h06_stage3_site_specific_screening.R`: SHA-256 `e92aedc03a2f5e75e9c6ce884498ebb69fa8ea79af4ce122325fc2dd26ebd7cd`, 27,545 bytes.

No Quarto render is released by this acceptance. H06 result, H06 companion, H06 daily, and every later REPORT-018 target remain held until the artifact package receives independent acceptance.
