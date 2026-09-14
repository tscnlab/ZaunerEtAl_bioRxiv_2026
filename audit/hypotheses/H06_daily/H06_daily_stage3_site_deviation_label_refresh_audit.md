# H06_daily Stage 3 site-deviation label refresh audit

Date: 2026-08-13

Scope: REPORT-014 display-only order 21

Verdict: PASS

## Authorized change

Only the baked text in `artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.png` was refreshed. The title, subtitle, and explanatory footer now use `site-average` in place of `equal-site`. Plot data, mappings, ordering, layers, scales, facets, geometry, colours, dimensions, resolution, and theme values were preserved.

The controlling order is `audit/report_harmonization/owner_orders/21_h06_daily_baked_figure_labels.md`, SHA-256 `30fa855f2039002bb24a06a4ce905c48ab000effc261f29957330275d2afc95f`.

## Frozen inputs and accepted sources

| Item | SHA-256 before and after | Bytes | Status |
|---|---|---:|---|
| Frozen figure CSV | `12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc` | 85,705 | byte-identical |
| Site display registry | `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809` | 295 | byte-identical |
| Accepted Stage 3 QMD | `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08` | 65,344 | byte-identical |
| Accepted Stage 4 QMD | `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709` | 35,409 | byte-identical |
| Protected SVG | `b23f9a6838c2ecc476bdb5e68c203e0c7a85d05479a65841f75ee02d21e20b1c` | 72,789 | byte-identical |
| Historical alt-text CSV | `a8be1b85d4c0c98922b98080148dcd87b43a28a3ee1fe6a1c55b979c1791200f` | 794 | byte-identical |

The frozen CSV contains 90 rows, 29 columns, ten interaction panels, and nine country-coded sites in every panel. Its plotting columns are complete. Its site, display order, display name, and colour mapping are exactly identical to the accepted site registry.

The protected inventory is recorded in `audit/hypotheses/H06_daily/H06_daily_stage3_site_deviation_label_refresh_protected_inventory.csv`. All 34 entries reproduced their recorded SHA-256 and byte count after execution. This includes main H06, shared configuration, the synchronized library lock, frozen plot inputs, accepted H06_daily scientific outputs and manifests, the broad historical builder, and ten referenced model objects checked by file identity only. No model object was deserialized or loaded.

## Dedicated display script boundary

The dedicated script is `scripts/hypotheses/H06_daily/refresh_h06_daily_stage3_site_deviation_labels.R`, SHA-256 `6ecdf76296fca9f479a06d319274cc6c5d03366867e0f69c5c8b15845013ab8d`, 7,436 bytes.

Static inspection and parsing confirmed that it:

- reads only the frozen figure CSV and site display registry;
- writes only the authorized PNG;
- contains no model-loading, prediction, inferential, p-value, FDR, source-data-writing, Quarto, knitr, render, or broad-builder path;
- checks the two input hashes, R version, frame dimensions, required plot columns, panel support, country-coded site names, and registry mapping before writing; and
- contains no `equal-site` text.

An abstract-syntax-tree comparison against the accepted plot construction in `scripts/hypotheses/H06_daily/build_h06_daily_stage3_revision_inputs.R` returned `plot_ast_identical=TRUE` after normalizing namespace qualification, single-expression braces, and only the three authorized old/new label strings. The literal output settings also remain 260 by 360 mm, 300 dpi, with a white background. This establishes that the mapping, ordering, layers, scales, facets, geometry, colours, dimensions, and theme were not changed.

## Execution record

The final bounded command was:

```sh
R_PROFILE_USER=/dev/null R_ENVIRON_USER=/dev/null R_LIBS_USER="$PWD/renv/library/macos/R-4.6/aarch64-apple-darwin23" NATHEALTH_PROJECT_ROOT="$PWD" /usr/bin/time -p R --vanilla --slave -f scripts/hypotheses/H06_daily/refresh_h06_daily_stage3_site_deviation_labels.R
```

| Field | Value |
|---|---|
| Exit status | 0 |
| R | 4.6.1 |
| digest | 0.6.39 |
| dplyr | 1.2.1 |
| ggplot2 | 4.0.3 |
| readr | 2.2.0 |
| Plot-save elapsed time | 0.448 seconds |
| Command wall time | 1.02 seconds |
| Command user time | 0.95 seconds |
| Command system time | 0.06 seconds |
| Warnings | 0 |

Execution-history disclosure: the first attempt stopped before writing because a validation-only `identical()` comparison retained a numeric-versus-integer type difference in the registry order. The target PNG still had its accepted pre-repair hash. The validation was corrected with an explicit integer cast. The next successful execution produced the final PNG but reported four tidyselect lifecycle warnings in validation-only column selection. Replacing those selections with `all_of()` and applying Air formatting yielded the warning-free final command above. The two successful executions produced exactly the same PNG SHA-256, so the validation cleanup did not alter the display.

## PNG identity

| Property | Accepted pre-repair | Refreshed |
|---|---|---|
| SHA-256 | `69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c` | `a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1` |
| Bytes | 475,439 | 476,355 |
| Pixels | 3070 by 4251 | 3070 by 4251 |
| Resolution | 300 dpi | 300 dpi |
| Colour mode | RGB | RGB |

The changed PNG identity is expected because the three baked text labels changed. Size, resolution, geometry, and plot content remain otherwise unchanged.

## Visual QA

The refreshed PNG was inspected at original resolution and in a temporary 2008 by 2780 pixel, 300-dpi proxy representing a 170 mm final width. The proxy was created only under `/tmp` and is not a durable project artifact.

Both inspections passed. They confirmed:

- the exact new title, subtitle, and footer phrase;
- all ten facet labels and nine country-coded site labels per panel;
- 90 points, 90 confidence intervals, and ten null-reference lines;
- preserved log-scale axis labels, site colours, facets, and panel balance;
- legible effective text size at 170 mm;
- no clipping, overlap, problematic wrapping, uncoded site name, or visible `equal-site`; and
- no unintended change to plot marks.

The row-level record is `audit/hypotheses/H06_daily/H06_daily_stage3_site_deviation_label_refresh_visual_qa.csv`, SHA-256 `976f7e7f1381392fb3f9fb6afaaa48eab8577a4adb9a5323bc54f51b246316a5`.

## Scope conclusion

No estimate, interval, p-value, FDR decision, diagnostic, sensitivity, source row, model, QMD, SVG, alt-text CSV, main-H06 file, shared file, or accepted scientific output changed. Quarto and knitr were not run. No commit, push, or profile integration was performed.
