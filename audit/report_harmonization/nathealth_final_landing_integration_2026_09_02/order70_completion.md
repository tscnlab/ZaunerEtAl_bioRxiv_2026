# REPORT-018 Order 70 completion

Date: 2026-09-02

Status: `PASS`

The accepted final Nature Health manuscript is integrated into the manuscript landing page on `rewrite/NH` without running Quarto or scientific code. The accepted site navbar, search, footer, route sequence, right-hand desktop TOC, and collapsed mobile TOC remain in place.

The production build contains 893 regular files and zero symlinks. Relative to the accepted 892-file build, only `index.html` changed and the exact corrected Word file was added. The other 891 files, including all other 36 HTML routes, remain byte-identical.

The landing page preserves 28 authors, 19 native semantic tables, 20 figure endpoints, 2,762 resolving table-header tokens, 124 resolving manuscript fragment links, 74 embedded images, and the exact accepted Brown SVG. The new landing page has no duplicate IDs or unresolved IDREF/header tokens.

Candidate and production browser QA passed all 37 routes at 708 and 390 pixels, plus the complete landing page at 1,440, 708, and 390 pixels. The sole accepted legacy overflow classification remains the unchanged Descriptives route at 708 pixels. Both bounded servers were stopped and their listeners were verified absent.

The 37-row corpus manifest retains all historical source identities and updates only the landing HTML hash.
