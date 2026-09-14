# Nature Health final landing production browser QA

Date: 2026-09-02

Status: `PASS`

The promoted `_build/nathealth` site was served from the exact build root on
`127.0.0.1:57471` after a zero-symbolic-link scan. All 37 registered routes
passed at 708 by 1,000 pixels and 390 by 844 pixels. Each route check opened
the collapsed mobile `On this page` disclosure, followed its first fragment,
verified that the disclosure closed, reopened it, and confirmed that its link
order matched the canonical right-hand TOC. The audit also checked the navbar,
footer, images, error nodes, canonical TOC count, and page width.

The exact route classification is 2 `CLEAN_NEW_LANDING_PAGE`, 71
`CLEAN_UNCHANGED_ROUTE`, and 1
`ACCEPTED_LEGACY_OVERFLOW_BASELINE_PRESERVED`. The sole preserved exception is
`notebooks/descriptives.html` at 708 pixels, where an accepted inner figure
scroller remains wider than its container without adding page-level overflow.
All 390-pixel routes are width-clean. The H06 daily pages retain Quarto's
hidden narrow-screen TOC clone; the audit counts only the canonical
`#quarto-margin-sidebar > #TOC`, while recording the clone separately.

The manuscript landing page passed detailed checks at 1,440, 708, and 390
pixels: 28 authors, 19 tables, 20 figure endpoints, 74 images, 17 loaded Table
3 thumbnails, the accepted embedded Brown SVG, Supplementary Figures S8 and
S12, search, footer, previous/next navigation, the Word download, and the
desktop/mobile TOC states. No page-level overflow, broken image, rendered error
node, console warning, or console error was found. Supplementary Figure S8
shows the complete four-panel representation, and Supplementary Figure S12
has no MDER legend.

The 19-row curated screenshot manifest covers manuscript, preparation, result,
analysis-provenance companion, and sensitivity routes at all three widths,
plus Table 3 and settled views of Supplementary Figures S6, S8, and S12. A
browser-default request for undeclared `/favicon.ico` returned 404; it is not a
document reference and produced no console error. Two exploratory test-harness
probes attempted unsupported mutation methods in the browser's read-only
evaluation scope before the recorded audit. They were discarded without
changing page, source, candidate, build, or evidence content.

The task-owned QA tab was closed, the viewport override was reset, the server
was stopped, and both bounded QA ports were confirmed listener-free.
