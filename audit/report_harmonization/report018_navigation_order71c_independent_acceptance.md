# REPORT-018 navigation Order 71c independent acceptance

Date: 2026-09-03

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Disposition: `ACCEPTED_AND_CLOSED`

## Accepted production identities

- Landing page `_build/nathealth/index.html`: SHA-256
  `9c1beea41a0b203b8a8b032eade2ba7e4ab5067857d39e296a8503231af46eec`,
  29,019,392 bytes.
- Word download `_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx`:
  SHA-256 `74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8`,
  28,793,619 bytes.
- Thirty-seven-route corpus manifest
  `audit/report_harmonization/phase4_corpus_manifest.csv`: SHA-256
  `01a2fdc1f1d11db45e28834893c79d620aa5321be1f49cff612b34589e068008`,
  11,479 bytes.
- Supplementary Figure S6 SVG authority: SHA-256
  `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`,
  108,600 bytes.

## Independent verification

- The non-circular completion manifest reproduced 80 of 80 unique file
  identities and byte counts under R 4.6.1.
- All 25 postflight checks passed.
- Candidate and production browser checks each passed 111 of 111 route-width
  combinations across 37 routes at 1,440, 708, and 390 CSS pixels.
- Candidate and production focused landing checks each passed at all three
  widths, with clean browser consoles.
- All nine production server-lifecycle checks passed, including clean shutdown
  and an absent listener.
- The production build contains 893 regular files and zero symlinks. Relative
  to the accepted preimage, only `index.html` and the Word download changed;
  the other 891 files and all other 36 HTML routes remain byte-identical.
- The 37-row corpus manifest preserves all source identities and every other
  route hash, changing only the landing HTML hash.
- The landing page contains 28 authors, 19 semantic tables, 20 figure
  endpoints, 2,762 resolving table-header tokens, 124 resolving manuscript
  fragments, and 46,071 resolving local references, with no duplicate IDs or
  unresolved IDREF/header tokens.
- Table 3 follows the accepted descriptive-table metric order: Duration,
  Dynamics, Exposure history, Level, Spectrum, Timing.
- Supplementary Figure S5 is one real two-panel SVG. Supplementary Figure S6
  remains the exact accepted direct SVG. Supplementary Figure S12 contains no
  MDER legend.

The owner's final replay assertion encountered the already characterized
named-versus-unnamed `vapply()` comparison issue only after all evidence had
been written. Independent R 4.6.1 comparison of the values reproduced all 80
manifest rows. This is a checker-expression issue, not a content, rendering,
or scientific discrepancy.

Order 71c is accepted and closed. No Quarto, Pandoc, knitr, or scientific code
was run, and no commit, push, upload, deployment, or submission occurred.

