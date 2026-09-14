# REPORT-018 Order 72 H06 candidate SVG completion

Date: 2026-09-11

Status: **OWNER PASS, STOPPED AT `REPORT018-ORDER72-SVG-REVIEW`**

This is a candidate-only format export. It is not central acceptance or manuscript integration.

## Candidate endpoints

| Display | Candidate SVG | SHA-256 | Bytes | Native canvas | SVG viewBox |
|---|---|---|---:|---:|---|
| Current S9 | `candidate/H06_paired_placement_effects.svg` | `e9d44034ace69fc82f67079fdabb266827cc06e053f948bd47e90d6ce1a47e14` | 7,423 | 170 x 120 mm | `0 0 481.89 340.16` |
| Current S12 | `candidate/H06_stage3_site_specific_significance_screen.svg` | `2b955196ce35eae1c973201a00523e538a6535ac59c8abe240160611a74c8b83` | 29,707 | 170 x 135 mm | `0 0 481.89 382.68` |

Minimal export script:
`export_h06_order72_svg.R`

SHA-256: `9ae135e43d024ac8a27a323081db5b87d9eebb94b1a209d5f94ca105057ec554`

Bytes: 17,134

## Frozen inputs

The single durable export reproduced all nine H06 pins before reading the display rows. These include both accepted PNG/PDF pairs, both frozen plotting CSVs, both accepted builder references, and the site display registry. The six-row S9 source and 27-row S12 source were read unchanged. S12 site names, order, and colours agreed exactly with the registry.

After all visual QA, all 71 paths in the sealed release manifest still matched their exact SHA-256 and byte-size pins. See `input_pin_checks.csv` and `post_qa_release_manifest_recheck.csv`.

## Native-vector and privacy checks

Both candidates contain native SVG vector drawing and text elements. Both passed checks for:

- no embedded raster image or raster payload;
- no script or executable content;
- no external resource or hidden display-source payload;
- no participant identifier;
- complete required visible labels;
- valid native dimensions and viewBox; and
- resolved local Arial font at `/System/Library/Fonts/Supplemental/Arial.ttf`.

See `svg_structure_checks.csv` and `font_resolution.csv`.

## Visual comparison

Quick Look rasterized both SVGs once onto its square, top-aligned thumbnail canvas. R 4.6.1 then extracted the unchanged figure canvas at the accepted PNG dimensions and made 643-pixel-wide reader copies corresponding to 170 mm at 96 dpi. The initial center-crop files are retained only as renderer-method diagnostics and were not used to assess the candidates.

The accepted PNG is on the left and the candidate raster is on the right in each comparison proof. Inspection at accepted pixel dimensions and at intended reader width found matching panels, layers, estimates, intervals, line positions, marks, colours, labels, legends where applicable, captions, and whitespace. No clipping, overlap, missing layer, changed panel meaning, or unavailable font was found. Visible differences are limited to rendering-device antialiasing.

The smallest essential nominal and effective final text is 8 pt for S9 and 7.5 pt for S12. Both are at scale factor 1.0 at the intended 170-mm width. See `visual_qa.csv` and the four files whose names contain `comparison`.

## Runtime and preservation

R version: 4.6.1

Library paths:

- `/Users/zauner/Library/R/arm64/4.6/library`
- `/Library/Frameworks/R.framework/Versions/4.6/Resources/library`

Consequential versions are recorded in `package_versions.csv`; full runtime detail is in `session_info.txt`; executed commands and the rasterizer diagnostic are in `commands.txt`.

Only `audit/hypotheses/H06/report018_order72_svg_export/` was written durably. No accepted figure, source CSV, builder, QMD, HTML, manuscript file, H06_daily path, fitted model, scientific artifact, shared configuration, central ledger, package, profile, or lockfile was changed. No broad builder, Quarto render, scientific computation, canonical promotion, commit, push, or upload was performed.

Mandatory stop reached: `REPORT018-ORDER72-SVG-REVIEW`.
