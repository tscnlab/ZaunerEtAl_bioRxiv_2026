# REPORT-017 H01 order 32e stopped-state independent acceptance

Date: 2026-08-15

Status: **Accepted as a clean fail-closed implementation stop. The three new
findings are display-refresh harness defects, not scientific discrepancies.
No durable figure, builder, manifest, QMD, HTML, profile, or scientific
artifact changed. Quarto did not run.**

## Controlling identities

- order 32e:
  `audit/report_harmonization/owner_orders/32e_h01_order32d_consolidated_continuation.md`,
  SHA-256
  `affbf8e38a8c49edc4eb3a33dddcea4b8a8184e9576273c381902ee51be077ff`;
- dispatch manifest:
  `audit/report_harmonization/report017_h01_order32e_dispatch_manifest.csv`,
  SHA-256
  `4a74df8e8ce092d16340a06e58b93efa7ea649a5ba8bbc2ea1393557b97e4647`;
- accepted order-32d stopped state:
  `audit/report_harmonization/report017_h01_order32d_stopped_state_independent_acceptance.md`,
  SHA-256
  `b1c46acc3369b6c878bafff9ab3981d2ece296bedcba27c42fe21481ba89664d`;
- current refresh implementation:
  `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`, SHA-256
  `999637d9d84ec3544db95d423b6c363d4d0c4ccfe588a76139bf6062e674638f`;
- post-guard, pre-Air source:
  `audit/hypotheses/H01/report017_order32e_continuation/refresh_h01_order32d_figures_postguard_preair.R`,
  SHA-256
  `e7091fd905eec6bb706d6c8b9d037046200b2ba343d4f90b4441173047aad070`;
- repaired-classification preflight:
  `audit/hypotheses/H01/report017_order32e_continuation/run_h01_order32e_repaired_classification_preflight.R`,
  SHA-256
  `0e1386b5ccf6109bf5aa3986ce15098001f4156e7c68fdfa8d5103d35d0284f7`;
- copied continuation sealer:
  `audit/hypotheses/H01/report017_order32e_continuation/seal_h01_order32e_continuation.R`,
  SHA-256
  `f9b4afdd5c65d142b83316eb83e88d849c2368f16b32f3dd1479d172f23b9abd`.

## Independently reproduced completed work

R 4.6.1 reproduced the following:

1. Forty-two of the 43 dispatch rows remain byte-exact. The sole changed row
   is the authorized refresh implementation transition from `71062634...` to
   `999637d9...`. There is no unexpected dispatch mismatch.
2. The two observed-category guards now require exactly the observed values:
   `Not supported` and `Supported`; and `Not applicable`, `Pass`, and
   `Review`. The broader declared plotting levels, including unused
   `Not estimable` and `Fail`, remain present.
3. The parsed pre-Air and post-Air implementation ASTs have the identical
   SHA-256
   `e66792fb0b5325de8b4bd425e8958fbc97f6802c3dd336e4ece898c118daac80`.
4. The continuation sealer differs from the stopped order-32d sealer in one
   expression only. Its build comparison uses
   `expected_quarantine$recovery_relative_path`; its protected comparison
   still uses `expected_quarantine$original_path`.
5. All three recovery files remain exact and regular nonsymlink files under
   `/private/tmp/H01-order32d-quarantine.Xc28uF`; all three original duplicate
   build paths remain absent. The order-32d failed candidate directory remains
   empty.
6. The fresh order-32e temporary directory
   `/private/tmp/H01-order32e-candidates.hltKEs` contains exactly 12 files:
   baseline and candidate PNG/SVG outputs for Figures 1, 5, and 6.
7. Both QMDs, both durable HTML pages, the builder, profile, six durable
   figures, three frozen display-source CSVs, and the remaining dispatch paths
   retain their accepted identities.

## Confirmed findings

### H01-32E-HARNESS-001: temporary output-inventory data-mask collision

Classification: confirmed implementation-harness defect; no durable output
written.

Inside `path_rows()`, the `tibble()` call creates the column `figure_id`
before evaluating later expressions such as `paths[[figure_id]]`. Tidy data
masking therefore resolves `figure_id` to the new column rather than the
scalar closure argument and produces `subscript out of bounds`.

The bounded correction is to bind the selected file vector before entering
`tibble()`, using a distinct scalar name, and then build all columns from that
preselected vector. This avoids reliance on data-mask lookup and changes no
plot construction.

### H01-32E-PROV-001: Figure 1 sealed baseline has intentional title-only provenance

Classification: confirmed display-provenance contract mismatch; no data,
result, or figure-content discrepancy.

The current full source-derived Figure 1 baseline differs from the sealed
artifact only in the legend region:

- 9,477 changed pixels, 0.119 percent of the raster, within one-based bounds
  x = 1927 to 2496 and y = 2256 to 2325;
- four SVG lines, 366 to 369; and
- a three-point horizontal shift of the two legend keys and their two labels.

The cause is verified in the accepted order-31f refresh implementation,
`scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R`, SHA-256
`f87486c0975dc560887c92e98f9423baaa56a926a3d6533e6197b625e23c4353`.
That implementation deliberately reconstructed the older BH-title plot,
spliced only the FDR legend-title raster region, and replaced only the SVG
title line. It therefore preserved the older legend-key positions. A fresh
full construction using the current FDR title centers the complete legend and
moves the keys and labels three points.

The next validation must preserve this truthful provenance. It should require
exact reproduction for Figures 5 and 6, while classifying only the exact
9,477-pixel/four-line Figure 1 legend difference above as the known transition.
It must then apply the already authorized Figure 1 size changes and retain all
136 source rows, tiles, symbols, statuses, colours, ordering, dimensions, and
DPI.

### H01-32E-HARNESS-002: SVG `textLength` unit parsing

Classification: confirmed validation-harness defect; no label collision found.

`label_boxes()` calls `as.numeric()` directly on SVG `textLength` values such
as `35.13px`, producing `NA`. The validator also lacks an explicit finite-value
gate. An independent R 4.6.1 check stripped the required terminal `px`, found
all 30 expected labels exactly once, found zero nonfinite widths, and found
zero label-to-label collisions with the accepted 0.5-unit clearance.

The bounded correction is to require the expected numeric-plus-`px` form,
strip only that terminal suffix, convert, and fail closed on any nonfinite
value before computing boxes.

## Temporary candidate observations

- all three candidate PNGs retain their authorized dimensions and
  approximately 320 dpi;
- estimated minimum 708-pixel text sizes are 7.133 pt for Figure 1 and
  7.095 pt for Figure 6;
- the paired and diagnostic source-derived baselines reproduce their sealed
  PNG and SVG files exactly; and
- the temporary candidates remain evidence only. They are not accepted and
  must not replace durable artifacts without a separately authorized complete
  validation pass.

## Preservation and disposition

No model, fit, inference, prediction, bootstrap, Shapley allocation, source
data, scientific table, QMD, HTML, profile, package, lockfile, or durable
figure changed. No Quarto command, loopback server, browser QA, commit, push,
upload, or deletion occurred.

The smallest safe next action is one final consolidated continuation that
corrects all three harness contracts above, formats and verifies the single
refresh implementation, preserves the current temporary directory as stopped
evidence, creates one fresh candidate directory, and then completes the
already authorized candidate, one-write, direct-reseal, exactly-one-result-
render, semantic, and visual-QA workflow. The H01 companion and every later
REPORT-017 render remain held.
