# REPORT-018 order 46: H06 hourly reader-figure label refresh

Date: 2026-08-20

Owner: H06 hourly owner `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: released for one consolidated artifact-only implementation and verification package. No Quarto render is authorized by this order.

## Purpose and controlling boundary

The hourly H06 result and preparation/provenance sources are independently accepted after REPORT-017 order 37a. Four stored reader-figure families retain baked terminology that predates the accepted reader wording. This order repairs those labels once across every paired PNG, PDF, and SVG export before H06 enters the REPORT-018 serial render queue.

This is a display-only artifact refresh from frozen figure-source CSVs. It must not fit or refit a model, load a model object, calculate an estimate, interval, p-value, FDR decision, diagnostic, residual, sensitivity result, or other scientific quantity. It must not regenerate or rewrite any source CSV, table, model, diagnostic, sample registry, QMD, HTML, profile, shared file, ledger, manuscript file, H06 daily file, package, or lockfile.

The four figure families and all 11 paired exports are handled together in this order. Do not split the repair by figure or format.

## Exact accepted preflight pins

The owner must reproduce all pins before editing. Stop without mutation on drift.

### Accepted sources and integration context

- `notebooks/hypotheses/H06.qmd`: SHA-256 `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`, 60,677 bytes.
- `audit/hypotheses/H06/H06_analysis_preparation.qmd`: SHA-256 `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`, 59,613 bytes.
- `audit/handoffs/H06_worker_handoff.md`: SHA-256 `21b37d161f07ec27a2802239a3999621f484b9d697c7cddaf3a73f6c09fe4e90`, 11,453 bytes.
- `tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R`: SHA-256 `fd8b4b5243d9942075a4845ea3fe21ace64fd5cc62300d8cd42b4b86c3eadb61`, 52,962 bytes.
- `_quarto-nathealth.yml`: SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, 7,480 bytes.
- stale result HTML `_build/nathealth/notebooks/hypotheses/H06.html`: SHA-256 `ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`, 6,109,797 bytes.
- stale companion HTML `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html`: SHA-256 `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`, 771,694 bytes.
- current Stage 3 artifact manifest `artifacts/12_manifests/H06/H06_stage3_artifacts.csv`: SHA-256 `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21`, 73,277 bytes, 301 data rows.

The coordination matrix identity at dispatch is evidence only and is not a mutable owner hard pin: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `482e30f8b778dd04ad44b339fbefb33adaf1296d23cdf8162526d77e37f4e2e7`, 26,505 bytes.

### Builders permitted to receive display-literal edits

- `scripts/hypotheses/H06/build_h06_stage3_reader_displays.R`: SHA-256 `b50bc1396f8d59647d7401849dd1cc23d6a988442fbc03cb2efdfe53d0b83c35`, 20,870 bytes.
- `scripts/hypotheses/H06/build_h06_stage3_site_specific_screening.R`: SHA-256 `9bde77139aff4b38009b8db70c0c152d516d31bf120fd86a9fc362140522378e`, 27,541 bytes.

Do not execute either full builder. Do not change any non-display literal, data transformation, object, expression, formula, branch, validation, plot geometry, aesthetic mapping, scale, break, limit, layer, order, colour, shape, line type, size, dimension, DPI, output path, or source-data path in either builder.

### Frozen figure-source CSVs

The dedicated refresh implementation may read only these eight scientific figure-source CSVs, plus `config/site_display_registry.csv` and the minimum literal display constants copied from the accepted builders:

1. `artifacts/11_source_data/H06/H06_reader_primary_effects_figure.csv`, SHA-256 `8a5482eb687a707ec193e2021233d954ca0ca21c322e75a9cd136042d0b51bfe`, 4,668 bytes.
2. `artifacts/11_source_data/H06/H06_stage3_site_specific_significance_screen_figure.csv`, SHA-256 `8d15804a66a6589b6c6f408db147e65c0fa2a42f71cd32fb1dcd2acd6657d642`, 49,970 bytes.
3. `artifacts/11_source_data/H06/H06_reader_temporal_day_type_curves.csv`, SHA-256 `838dc1485dd1c20caaa1693ec8d9969dc60619601a5fb11f9c1f1b350f7bfdab`, 132,409 bytes.
4. `artifacts/11_source_data/H06/H06_reader_temporal_day_type_ratios.csv`, SHA-256 `789c3375b8e7d9db16862c0d084a9484d88123523a7524b1280bee5f13bfce03`, 89,294 bytes.
5. `artifacts/11_source_data/H06/H06_reader_temporal_day_type_support.csv`, SHA-256 `597b72279bf499cecf63c95b11004b29dd388e1858f687ec6a21c0a1e95dfc60`, 2,918 bytes.
6. `artifacts/11_source_data/H06/H06_reader_temporal_activity_curves.csv`, SHA-256 `c947918e14c3d83fc51e8b4c9216d3ad9e5a18002d3b5f3f877b3d30b18cfa6d`, 130,390 bytes.
7. `artifacts/11_source_data/H06/H06_reader_temporal_activity_ratios.csv`, SHA-256 `1a12833bf7fa7aabdc91c23c1c28be26e685d3db4c7ddcea546720efafeb2b14`, 95,026 bytes.
8. `artifacts/11_source_data/H06/H06_reader_temporal_activity_support.csv`, SHA-256 `cac58f8236192d20fbf52ad2c8bd9a2f2809293a841d686969d47275e665fd08`, 2,870 bytes.

`config/site_display_registry.csv` must remain SHA-256 `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`, 295 bytes.

### Exact pre-repair exports

The 11 current files are the only existing display artifacts that may change:

- Primary: PNG `bc553dcb5dce302dc11a837d4a7a56e33cd35020b85bf0fadf8fe42603d331c9` / 159,608 bytes; PDF `efdf03a92d36645aceb842b4ef83bd4af95b724cd787e6ad589122ddd18984fa` / 6,921 bytes; SVG `4b4c4734024ab9b9bb31ba7986cd5fbedbc0bf2be9b5bedc7ff7092de9b9724c` / 22,665 bytes.
- Site screen: PNG `c1c8c332a0fb75ceea95b125d0696f893db5b27503760fe7ae454715d5920dea` / 192,301 bytes; PDF `3d8255dee326b9a38c327d39be3535b526179b47773402675473b0c82041620b` / 32,639 bytes.
- Day type: PNG `df2322474720c7357dd5e45003bca0a85bc8afa1e5cd55d3e692c1b557214e92` / 367,048 bytes; PDF `f66da1d75b59244c84cbd0e571e54d85657daccc52dcf6d70d0a93fc4209422a` / 16,572 bytes; SVG `5e14c8f45006cb15459720c4058bf184a4bacfc52dabfe07cf1eecbdc9664059` / 58,033 bytes.
- Activity: PNG `01354dbbbb6156f8813a76a75762c82010d8c5fb0d70b5846a21725c0ed13e5c` / 368,603 bytes; PDF `9e61383178a1f4e85aa8b4ed007891590c4513e6ccbc1780094e1900a7c50ceb` / 16,661 bytes; SVG `f09c9fd1fca5fb5670355da6f9189d791cbe27bb5299d17c91ff348ad8220c60` / 58,545 bytes.

Preserve dimensions and export settings exactly:

- Primary: 170 by 118 mm, PNG 2,141 by 1,486 pixels at 320 dpi.
- Site screen: 170 by 135 mm, PNG 2,141 by 1,700 pixels at 320 dpi.
- Day type: 170 by 205 mm, PNG 2,141 by 2,582 pixels at 320 dpi.
- Activity: 170 by 205 mm, PNG 2,141 by 2,582 pixels at 320 dpi.

## Authorized exact label transitions

Apply only the following reader-visible transitions in the two accepted builders and in the dedicated refresh implementation.

### Primary figure

- `Primary and contextual expected-hour melEDI ratios` to `Primary and contextual mean hourly melEDI ratios`.
- `Ratio of expected supported-hour melEDI (log scale)` to `Ratio of estimated mean hourly melEDI (log scale)`.

### Site-specific figure

- Title to `Site-specific mean hourly near-eye melEDI ratios`.
- Subtitle to the exact three-part text:
  - `Dashed line: site-average estimate from this model; filled points:`
  - `retained after separate nine-site FDR adjustments; open points:`
  - `not retained`
- Caption to the exact five-line text:
  - `Bars are participant-cluster HC3 pointwise 95% confidence intervals from the current`
  - `predictor-by-site interaction model. The grey line at 1 is the site-specific association null.`
  - `The dashed line is the site-average geometric mean of the nine ratios in this same model.`
  - `Filled points pass a separate nine-site FDR adjustment within that predictor; this does`
  - `not test deviation from the site-average estimate or the overall predictor-by-site interaction.`

Do not change code-only or stored-source terminology such as column names, object names, distribution fields, test-scope fields, screen-result values, or historical producer messages. The repaired figure is a display mapping over the frozen source CSV.

### Exploratory temporal figures

Apply the same shared display-label changes to both temporal figures:

- Day-type panel-A title: `Estimated near-eye melEDI by day type and local time`.
- Activity panel-A title: `Estimated near-eye melEDI by activity status and local time`.
- Panel-A y axis: `Estimated melEDI (lx)`.
- Panel-B y axis: `Estimated melEDI ratio`.
- Replace the technical footer with this exact structure, substituting the existing unchanged `standardization_text` for each figure:

  `Exploratory nonlinear two-part generalized additive model (GAM) display. {standardization_text}`

  `Displayed curves omit participant and participant-day random effects. Bands and ratio intervals are approximate pointwise 95% intervals with fixed smoothing parameters; uncertainty does not include covariance between the occurrence and positive-magnitude components.`

  `Filled and hollow points distinguish intervals that exclude and include 1. These intervals apply to individual displayed hours, not a simultaneous or multiplicity-controlled whole-curve test. The panel-A transformation is display-only.`

Preserve the existing ratio-panel titles, legends, support-panel labels, group names, standardization sentences, support counts, and every scientific qualification not explicitly replaced above.

## Dedicated refresh implementation

Create `scripts/hypotheses/H06/refresh_h06_report018_reader_figure_labels.R` and `tests/hypotheses/H06/test_h06_report018_figure_label_refresh.R`.

The refresh script must:

1. Assert R 4.6.1 and record exact package versions, including `ggplot2`, `cowplot`, `patchwork`, `readr`, `dplyr`, `scales`, `svglite`, `LightLogR`, `digest`, and any image or PDF inspection package used.
2. Pin the eight frozen source CSVs, site registry, two pre-edit builders, and 11 pre-edit exports by SHA-256 and byte count before doing work.
3. Contain no call that loads a model or performs fitting, prediction, simulation, bootstrap, resampling, p-value adjustment, scientific summarization, or source-data write.
4. Reconstruct only the accepted display layers from the eight source CSVs. Preserve row counts, keys, ordering, factor levels, mapped aesthetics, plot layers, coordinate systems, scales, breaks, limits, null and reference lines, colours, shapes, line types, sizes, facets, and output geometry.
5. Build source-derived old-label baselines and repaired candidates in one fresh temporary directory outside durable targets. Do not write a durable target until all four families and all paired formats pass validation.
6. Require the old-label PNG and SVG baselines to reproduce the sealed exports exactly. For PDF, require identical page geometry, extracted visible content except metadata, plot-object structure, and rendered pixels before accepting any metadata-only difference.
7. Validate repaired candidates as one set. Require exact source-row and mapped-aesthetic equality, exact layer and label counts, exact dimensions and 320 dpi, and normalized SVG structure equal apart from the authorized text transitions. For PNGs, require every changed pixel to be explained by the authorized title, axis-label, subtitle, or caption regions and require data-region pixels to remain identical. For PDFs, require the same visible-text and rendered-page boundary.
8. Replace the 11 durable exports once, only after the full candidate set passes. Require all 11 durable files to be byte-identical to their accepted candidate counterparts.
9. Leave every retained temporary baseline and candidate file in a fresh `/private/tmp` directory until independent harmonizer acceptance. Record the exact path and complete inventory. Do not delete prior evidence.

Air-format only the two new R files. Do not mechanically reformat either accepted builder. Parse all four R files under R 4.6.1 and require exact diff and reverse-substitution proof for the two builder edits.

## Visual and content acceptance

Inspect all four repaired PNGs at original resolution and at the intended 170-mm final display size. Also inspect a 708-pixel-wide equivalent and a 200-percent-equivalent view. Record screenshots or rendered inspection images in the order-owned evidence directory.

Require:

- all source rows and every plotted point, interval, curve, support bar, symbol, colour, facet, order, null line, and reference line preserved;
- all new visible labels present exactly, with no visible retired `expected-hour`, `supported-hour`, `equal-site`, `BH`, `heterogeneity`, or `frozen` wording in the four repaired exports;
- all country-coded study-site labels preserved;
- no clipping, overlap, harmful wrapping, distortion, excessive footer growth, or imbalanced data region;
- all essential text at least 7 pt at intended final size;
- PNGs control the exported-raster visual decision, while PDF and SVG remain consistent paired exports;
- no scientific result or interpretation change.

## Direct current-manifest reseal

Do not run `scripts/hypotheses/H06/build_h06_stage3_manifest.R` or any broad manifest builder.

After all artifact checks pass, directly update only the 13 existing rows in `artifacts/12_manifests/H06/H06_stage3_artifacts.csv` for the two builders and 11 paired exports. Preserve every other existing row and field byte-for-byte and in its existing order.

Append only these seven non-circular current rows, using the manifest's existing columns and conventions:

1. `scripts/hypotheses/H06/refresh_h06_report018_reader_figure_labels.R`.
2. `tests/hypotheses/H06/test_h06_report018_figure_label_refresh.R`.
3. `audit/hypotheses/H06/report018_order46_figure_label_refresh/authorized_label_transitions.csv`.
4. `audit/hypotheses/H06/report018_order46_figure_label_refresh/source_value_and_geometry_checks.csv`.
5. `audit/hypotheses/H06/report018_order46_figure_label_refresh/visual_qa.csv`.
6. `audit/hypotheses/H06/report018_order46_figure_label_refresh/protected_inventory.csv`.
7. `audit/hypotheses/H06/report018_order46_figure_label_refresh/package_versions.csv`.

The post-reseal manifest must therefore have exactly 308 unique data rows. Require an exact 13-row update set, exact seven-row append set, row-level before/after evidence, reverse proof to the 301-row preimage, no duplicate path, and no circular row. Preserve every historical REPORT-017 order 37 and 37a file byte-for-byte.

Create after the current manifest is sealed:

- `manifest_row_changes.csv`;
- `completion_record.md`; and
- a non-circular `owner_evidence_manifest.csv` that excludes itself and pins the complete order package.

## Verification and stop

Run the dedicated focused test once under the normal R 4.6.1 project environment after the complete package is assembled. It must check all preconditions, authorized label transitions, source and geometry equality, export pairs, final manifest rows, protected identities, and prohibited-call scan. Run scoped `git diff --check` and the project no-em-dash check for the new order-owned prose.

The following must remain byte-identical:

- both accepted hourly QMDs and the H06 worker handoff;
- H06 daily result and companion sources;
- all eight frozen figure-source CSVs and the site registry;
- every H06 model, table, diagnostic, sample, sensitivity, source-data, and figure artifact outside the 11 exact targets;
- Stage 2 and preparation manifests and all pre-existing tests;
- both stale H06 HTML files and every `_build` path;
- profile, semantic hook, output catalog, corpus manifest, central ledgers, manuscript files, packages, and `renv.lock`.

If any candidate, focused test, preservation, or visual check fails, stop once with one complete defect list. Do not patch and rerun within this order after the final candidate run. Return the exact temporary directory, pre/post identities, test output, visual evidence, manifest identities, and complete owner seal for independent acceptance.

No Quarto command is authorized. After independent acceptance, the harmonizer will issue a separate H06 result-only render order. The companion, H06 daily, H07 and every later target remain held.
