# REPORT-018 order 46a: H06 hourly reader-figure label refresh retry

Date: 2026-08-21

Owner: H06 hourly owner `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: released for one final consolidated artifact-only continuation. No Quarto render is authorized.

## Controlling records

- Original order 46: `audit/report_harmonization/owner_orders/46_h06_hourly_reader_figure_label_refresh.md`, SHA-256 `5e0823af8dcd5f1d05c7248d42b95f78e101615600b73626fcf7fa5cd38b5478`, 16,269 bytes.
- Original dispatch manifest: `audit/report_harmonization/report018_h06_order46_dispatch_manifest.csv`, SHA-256 `79d965aa26ac70522029df8f0f96c3e8fece12f82fae2d621d96103e1937d6e1`, 7,767 bytes.
- Independent stopped-state and prospective verification: `audit/report_harmonization/report018_h06_order46_stopped_acceptance.md`, identity pinned by the order-46a dispatch manifest.

All scientific, source-data, artifact, source, manifest, render, and profile boundaries from order 46 remain controlling except for the exact retry corrections below. This continuation replaces no historical order or stopped evidence.

## Hard preflight

Before mutation, reproduce every non-matrix row in the order-46a dispatch manifest. In particular require:

- accepted H06 result QMD `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`;
- accepted H06 companion QMD `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`;
- both accepted pre-edit builders `b50bc1396f8d59647d7401849dd1cc23d6a988442fbc03cb2efdfe53d0b83c35` and `9bde77139aff4b38009b8db70c0c152d516d31bf120fd86a9fc362140522378e`;
- stopped refresh implementation `c84fe32ceb269b1df17457adbe4970d14694f9d5a2add9b86a630929333acefe`, 66,644 bytes;
- unchanged focused test `4c30795cb4b24dc26d012d5061045ad2c01dc717a0f75e00a690ac843ac4d97a`, 11,372 bytes;
- all eight frozen source CSVs, the site registry, all 11 pre-edit exports, the 301-row Stage 3 manifest, profile, stale HTMLs, H06 daily sources, package lock, and protected scientific inventory at their order-46 pins;
- retained empty directory `/private/tmp/h06_report018_order46_117d74905a6e7` still present and empty.

Stop before editing if any hard pin differs. The coordination matrix is dispatch evidence only and is not an owner mutation target.

## Preserve the first stopped attempt

Before changing the refresh implementation, create `audit/hypotheses/H06/report018_order46a_stopped_snapshot/`. Copy into it, without reserialization, the stopped refresh implementation, unchanged focused test, four existing order-46 evidence CSVs, and a bounded non-circular snapshot manifest. Require all six source copies to reproduce their stopped hashes and bytes exactly. Preserve `/private/tmp/h06_report018_order46_117d74905a6e7` unchanged and empty.

Do not rewrite or delete the original evidence to conceal the stopped execution. The final order-46 evidence directory may then be refreshed by the authorized continuation.

## Exact refresh-implementation correction

Edit only `scripts/hypotheses/H06/refresh_h06_report018_reader_figure_labels.R`. Apply exactly these seven classifications:

1. In the eight-source row-count guard, replace the single outer `c(` with `list(`.
2. In `expected_png_dimensions()`, add `L` to all six width and height literals.
3. In `normalized_svg_structure()`, normalize only `textLength` attribute values before the existing text and title normalization. Preserve every text position, style, element, path, and non-text attribute.
4. At the start of `normalize_visible_text()`, normalize U+2212, U+2010, and U+2011 to ASCII `-`, then retain the existing whitespace normalization.
5. In the revised temporal footer, add an explicit newline after `display.` and before `The panel-A transformation is display-only.`. Keep every visible word unchanged. The day-type and activity footers must each render in ten lines, matching baseline panel geometry.
6. Replace only the repaired site subtitle with:
   - `Dashed: site-average estimate from this model; filled: retained`
   - `after nine-site FDR adjustments; open:`
   - `not retained`
7. In the directly dependent builder-literal validator, require those two concise site-subtitle fragments and reject both the historical subtitle and the superseded long repaired candidate.

After Air 0.4.1 formatting and R 4.6.1 parsing, the refresh implementation must be exactly SHA-256 `98141fec09cdbd32450ef9b4b4c1ed1e29c01680976dc7c959c1fc37bbefa1b8`, 67,057 bytes. Require an exact diff and reverse proof to the stopped implementation `c84fe32...`.

Do not edit the focused test before candidate generation. Do not add any model, prediction, inference, summarization, adjustment, or scientific-data call.

## One fresh candidate run

Create one fresh candidate directory under `/private/tmp`. Do not reuse or promote from the empty stopped directory or from the harmonizer's prospective directories.

Run the corrected refresh implementation in `prepare` mode exactly once through the normal R 4.6.1 project profile with only the established narrow access to the existing user-owned renv cache. No preliminary project test or dry run is authorized.

Require all existing order-46 checks plus these postconditions:

- 61/61 source, value, geometry, PNG, PDF, and SVG checks pass;
- every old-label PNG and SVG baseline reproduces its sealed target byte-for-byte;
- every old-label PDF reproduces page geometry, extracted visible text, and rendered pixels;
- all four candidate PNG dimensions are exact and all data-region pixels remain unchanged;
- normalized SVG structure passes after text-content and `textLength` normalization only;
- PDF required-label checks pass after the bounded dash normalization;
- both temporal figures retain baseline panel geometry and ten footer lines;
- the concise site subtitle is fully visible on one line at original, 170-mm, 708-pixel, and 200-percent-equivalent views;
- all four candidate families retain at least 7-point essential text, all country-coded sites, and no clipping, overlap, distortion, or harmful wrapping.

If any candidate or visual check fails, seal one complete stopped state without patching or retrying.

## Exact builder display edits

Only after the complete candidate set and manual visual QA pass, edit the two accepted builders with the original order-46 display transitions, amended only as follows:

- the site builder must use the concise subtitle specified above;
- the reader builder must use the two explicit temporal-footer line breaks specified above.

Do not mechanically format either builder. R 4.6.1 parsing, exact diff inspection, and reverse proof are required. Expected post-edit identities are:

- reader builder SHA-256 `5431bcdffc65ac0d217f29e3e821699d3f28da1192ba51ce6ab0b77f9f8ac6da`, 20,839 bytes;
- site builder SHA-256 `e92aedc03a2f5e75e9c6ce884498ebb69fa8ea79af4ce122325fc2dd26ebd7cd`, 27,545 bytes.

No code-only, stored-source, model, transformation, formula, mapping, layer, scale, break, limit, order, colour, shape, line type, text size, dimension, DPI, output-path, or source-path value may change.

## Promotion, direct reseal, and verification

After all four visual rows are marked PASS, run the corrected refresh implementation in `promote` mode exactly once. It may replace the 11 durable exports once, directly reseal the Stage 3 manifest from 301 to exactly 308 unique rows under the original 13-update and seven-append contract, and create the bounded completion evidence.

Do not run a broad manifest builder. Preserve all historical REPORT-017/018 evidence byte-for-byte, including the original order-46 records and the new stopped snapshot.

Run the unchanged focused test exactly once under R 4.6.1 after promotion. Also require:

- all 11 durable exports byte-identical to their accepted candidates;
- all four PNGs and paired PDF/SVG outputs visually and structurally consistent;
- exact builder reverse proofs;
- exact 13-row manifest update set and seven-row append set;
- 308 unique Stage 3 manifest rows;
- complete protected scientific and build inventories unchanged outside the authorized two builders, 11 exports, Stage 3 manifest, refresh implementation, stopped snapshot, and bounded order evidence;
- scoped `git diff --check`, Air check for the two new R files, and the project no-em-dash check for new prose.

Return the fresh temporary directory, all pre/post hashes and bytes, 61-check audit, completed visual QA, focused-test output, builder diffs and reverse proofs, Stage 3 manifest identity, and non-circular owner seal for independent acceptance.

## Prohibitions and hold

No Quarto command, QMD execution, render, model load, fit, refit, prediction, simulation, bootstrap, resampling, p-value or FDR calculation, scientific summarization, source-data write, other artifact regeneration, shared profile edit, ledger edit, package or lock change, commit, push, upload, or deletion is authorized.

H06 result, H06 companion, H06 daily, H07, and every later REPORT-018 render remain held. A separate result-only render order may be released only after independent artifact acceptance.
