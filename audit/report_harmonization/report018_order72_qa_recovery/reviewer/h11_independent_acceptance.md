# REPORT-018 Order 72b: H11 independent SVG acceptance

Date: 2026-09-11

Gate: `REPORT018-ORDER72-SVG-REVIEW`

Status: PASS for this individual candidate. This is not the seven-candidate
aggregate release and is not manuscript-promotion authority.

## Frozen identities

- Candidate: `audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg`
- Candidate SHA-256: `ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe`
- Accepted PNG: `artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png`
- Accepted PNG SHA-256: `33ac814200fc1d69dcf462d0a156b2b950ef0588f47974881fb56f140a414f70`

## Independent checks

- The 163-row recovery release manifest rehashed exactly under R 4.6.1.
- The candidate remained byte-identical before and after wrapper preparation,
  Quick Look rasterization and exact-rectangle extraction.
- Root size and viewBox are 756 by 792 pt and `0 0 756.00 792.00`.
- The SVG contains 71 native vector elements and 34 text elements, with no
  image, script, foreign object, external reference, event attribute or
  privacy hit. The resolved font is Helvetica.
- Original-size 3150 by 3300 and reader-size 643 by 674 comparisons show the
  same sex-specific curves, confidence ribbons, open-circle support markers,
  reference line, civil-night shading, scales, labels, legend, explanatory
  copy, whitespace and clipping as the accepted PNG. Differences are limited
  to rasterizer antialiasing.
- Panel headings begin with capital A and B at the left edge of their
  respective panels.

Disposition: independently accepted and held for the seven-row aggregate.

