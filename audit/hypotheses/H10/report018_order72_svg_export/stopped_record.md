# REPORT-018 Order 72 H10 stopped record

Status: **STOPPED, fail closed**

Mandatory owner stop: `REPORT018-ORDER72-SVG-REVIEW`

## Controlling release

- Released order: `audit/report_harmonization/owner_orders/72_manuscript_svg_exports_released.md`, SHA-256 `d14575d7c262b01fe58ba85d343f966d5953601a0fb41cc0f61c25279eb4071c`.
- Incorporated proposal: `audit/report_harmonization/owner_orders/72_manuscript_svg_exports_proposed.md`, SHA-256 `d3f329a2149149663c47e5db4514cbb7771b0afb6362afc8b911871068d0ebcd`.
- Release manifest: `audit/report_harmonization/report018_order72_release/release_manifest.csv`, SHA-256 `8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526`.

Before the first durable output, R 4.6.1 verified all 71 release-manifest rows as exact and unique. The allocated H10 output root was absent. The five H10 display inputs were exact, including the 322-row frozen plotting CSV and the 2820 by 3900 accepted selection PNG.

## Export result

The single export command completed successfully from the frozen rows and display-text contract. It did not source the broad builder and did not execute a model, prediction, scientific calculation, Quarto, knitr, Pandoc, or manuscript render.

- Candidate: `audit/hypotheses/H10/report018_order72_svg_export/candidate/H10_age_site_significant_associations_selection_candidate.svg`
- SHA-256: `1340491390703f642e30b0284bd4e0416a704015bc717dd2a6e56a8073901799`
- Bytes: `88725`
- Width: `676.80pt`
- Height: `936.00pt`
- ViewBox: `0 0 676.80 936.00`
- Export script: `audit/hypotheses/H10/report018_order72_svg_export/export_h10_selection_svg.R`
- Export script SHA-256: `309401b5c73e0841beb6efad1b72df391cb646c0abc173d3e62b32a1628db36a`

## Why the package stopped

The one automated QA command exited nonzero before rasterization because two checker predicates failed:

1. It required at least one SVG `path` element. This was narrower than the sealed native-vector contract. The candidate has no `path` element but contains 56 `line`, 24 `rect`, 191 `circle`, 150 `polygon`, and 113 `polyline` elements. It has no `image`, `script`, or `foreignObject` element.
2. It required the A, B, and C SVG text nodes to contain a literal `font-weight: bold` declaration. All three tags are present exactly once, but their SVG text styles omit that declaration. Order 72 controls the accepted PNG and frozen display text and expressly releases no cosmetic repair. The bold predicate was an extra checker requirement, not a released source edit.

These are checker-contract defects. They did not expose a frozen-source, model, estimate, interval, sample, site-order, colour, label, or other scientific defect. Nevertheless, Order 72 requires a stop after any failed check and forbids patching and retrying within the same order. The verifier was not changed or rerun. No rasterized comparison proof was produced. The candidate is preserved as stopped evidence and is not presented as an owner PASS or central acceptance.

- Failed verifier: `audit/hypotheses/H10/report018_order72_svg_export/verify_h10_selection_svg.R`
- Failed verifier SHA-256: `2d9fb64875dca28d0cd029f3142c4d233e4257ab0d3399d3da1aae557ee51d31`
- Failed verifier command exit status: `1`

## Preservation

No existing source, QMD, HTML, scientific artifact, manifest, profile, lockfile, manuscript file, canonical figure, or accepted selection asset was edited. No package was installed or updated. No commit, push, upload, or Writer contact occurred.

A fresh coordinator recovery order is required to replace the checker contract and authorize the remaining raster and visual QA.
