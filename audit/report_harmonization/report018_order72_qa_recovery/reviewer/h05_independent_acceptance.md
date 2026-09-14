# REPORT-018 Orders 72b and 72c: H05 independent SVG acceptance

Date: 2026-09-11

Gate: `REPORT018-ORDER72-SVG-REVIEW`

Status: PASS for this individual candidate. Manuscript promotion and the
separate Brown dependency remain outside this acceptance.

## Frozen identities

- Candidate: `audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/candidate/H05_reader_near_eye_effects.svg`
- Candidate SHA-256: `e9d7d60100403aea3ac25282f9be33f981b182a09e74479cd160bdc296ae63b3`
- Accepted PNG: `artifacts/10_figures/H05/H05_reader_near_eye_effects.png`
- Accepted PNG SHA-256: `70c1013d51f7619fafe0d38664db7dcf55692990993098948ed443e83c35e1a5`
- Owner final manifest: `audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/order72c_final_manifest.csv`
- Owner final manifest SHA-256: `65cc8ff2d77fa4a776d9b9319bb7e7d1a8f990b2860572072b5a77ae7c51951e`

## Independent checks

- The 21-row runtime owner manifest, 33-row final owner manifest and 188-row
  Order 72c release manifest all rehashed exactly under R 4.6.1.
- The candidate remained byte-identical before and after wrapper preparation,
  Quick Look rasterization and exact-rectangle extraction.
- Root size and viewBox are 648 by 648 pt and `0 0 648.00 648.00`.
- The SVG contains 386 native vector elements and 101 text elements, with no
  image, script, foreign object, external reference, event attribute or
  privacy hit. All three internal clip-path references resolve exactly once.
  The resolved font is Arial.
- The continuous colour guide contains 300 native rectangles and no embedded
  raster. All 300 ordered legend colours and all 101 text nodes match the
  failed predecessor exactly. Removing only the old and new legend elements
  leaves identical normalized SVG DOMs.
- Original-size 2700 by 2700 and reader-size 643 by 643 comparisons show the
  same matrix, reader-scale effect values, unfit cells, metric and factor
  order, labels, palette, legend limits and breaks, whitespace and clipping as
  the accepted PNG. Differences are limited to rasterizer antialiasing and the
  intended 300-step vector realization of the formerly rasterized gradient.
- This is a single-panel display, so a panel tag is not applicable.

Disposition: independently accepted for inclusion in the seven-row SVG
integration manifest.

