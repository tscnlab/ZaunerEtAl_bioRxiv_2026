# REPORT-018 Order 72b: H02 independent SVG acceptance

Date: 2026-09-11

Gate: `REPORT018-ORDER72-SVG-REVIEW`

Status: PASS for this individual candidate. This is not the seven-candidate
aggregate release and is not manuscript-promotion authority.

## Frozen identities

- Candidate: `audit/hypotheses/H02/report018_order72_svg_export/candidate/figure4_exact_layout_replication.svg`
- Candidate SHA-256: `2f9493540f12c9c660d213ee619bc726f1e3a0e34ce52c0e59bdf6bd8102a5cd`
- Accepted PNG: `artifacts/10_figures/H02/figure4_exact_layout_replication.png`
- Accepted PNG SHA-256: `2d31f38a169659b37a16c44b9845605186709e4dc7734a8f97342408711f9ac2`

## Independent checks

- The 163-row recovery release manifest rehashed exactly under R 4.6.1.
- The candidate remained byte-identical before and after wrapper preparation,
  Quick Look rasterization and exact-rectangle extraction.
- Root size and viewBox are 792 by 1008 pt and `0 0 792.00 1008.00`.
- The SVG contains 3,466 native vector elements and 146 text elements, with
  no image, script, foreign object, external reference, event attribute or
  privacy hit. Resolved fonts are Arial and Symbol.
- Original-size 3300 by 4200 and reader-size 680 by 865 comparisons show the
  same four-panel geometry, curves, uncertainty bands, red clock-specific
  segments, site facets, scales, labels, legends, colours, sample annotation,
  whitespace and clipping as the accepted PNG. Differences are limited to
  rasterizer antialiasing.
- Panel tags A, B, C and D are capital letters at the left edge of their
  respective panels.

Disposition: independently accepted and held for the seven-row aggregate.

