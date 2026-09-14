# REPORT-018 Order 72b: H08 independent SVG acceptance

Date: 2026-09-11

Gate: `REPORT018-ORDER72-SVG-REVIEW`

Status: PASS for this individual candidate. This is not the seven-candidate
aggregate release and is not manuscript-promotion authority.

## Frozen identities

- Candidate: `audit/hypotheses/H08/report018_order72_svg_export/candidate/H08_near_eye_effects.svg`
- Candidate SHA-256: `f0f77bbd896739941d8ae63bb24ed889528a410a963c2123b07ca3a825f7ddee`
- Accepted PNG: `artifacts/10_figures/H08/H08_near_eye_effects.png`
- Accepted PNG SHA-256: `f1cc8e33829cdf821140e95238d20b1516d5796f741002a1f27568d3f9fd7405`

## Independent checks

- The 163-row recovery release manifest rehashed exactly under R 4.6.1.
- The candidate remained byte-identical before and after wrapper preparation,
  Quick Look rasterization and exact-rectangle extraction.
- Root size and viewBox are 481.89 by 385.51 pt and
  `0 0 481.89 385.51`.
- The SVG contains 62 native vector elements and 23 text elements, with no
  image, script, foreign object, external reference, event attribute or
  privacy hit. The resolved font is Arial.
- Original-size 2007 by 1606 and reader-size 643 by 514 comparisons show the
  same estimates, 95% intervals, zero lines, metric order, group labels,
  captions, scales, colours, whitespace and clipping as the accepted PNG.
  Differences are limited to rasterizer antialiasing.
- This is a single-panel display, so a panel tag is not applicable.

Disposition: independently accepted and held for the seven-row aggregate.

