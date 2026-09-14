# REPORT-018 Order 71c completion

Date: 2026-09-03

Status: `PASS`

The accepted final Nature Health manuscript is integrated into the manuscript landing page on `rewrite/NH` without running Quarto or scientific code. The accepted site navbar, search, footer, route sequence, right-hand desktop TOC, and collapsed mobile TOC remain in place.

The production build contains 893 regular files and zero symlinks. Relative to the accepted 893-file build, only `index.html` and the exact Word download changed. The other 891 files, including all other 36 HTML routes, remain byte-identical.

The landing page preserves 28 authors, 19 native semantic tables, 20 figure endpoints, 2,762 resolving table-header tokens, 124 resolving manuscript fragment links, 74 embedded images, the accepted Table 3 metric order, the two-panel S5 SVG, and the exact accepted S6 SVG. S12 has no MDER legend. The landing page has no duplicate IDs or unresolved IDREF/header tokens.

Candidate and production browser QA passed all 37 routes at 1,440, 708, and 390 pixels, plus focused complete-landing checks at the same widths. The unchanged Descriptives route retains its accepted legacy overflow at 708 pixels and the independently classified pre-existing overflow at 1,440 pixels; it is clean at 390 pixels. Both bounded servers were stopped and their listeners were verified absent.

The 37-row corpus manifest retains all historical source identities and updates only the landing HTML hash.
