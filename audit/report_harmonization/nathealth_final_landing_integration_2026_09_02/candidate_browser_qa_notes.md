# Order 70e candidate browser QA notes

Status: `PASS`

The candidate passed 74 of 74 route checks at 708 by 1,000 and 390 by 844 pixels, plus complete landing-page checks at 1,440 by 1,000, 708 by 1,000, and 390 by 844 pixels. All tested local pages loaded, all images resolved, mobile TOC links were visible and focusable, the first link resolved and closed the disclosure, and no page-attributable console warning or error occurred.

The sole page-level overflow is the accepted immutable `notebooks/descriptives.html` row at 708 pixels. It reproduced the sealed geometry exactly: document client width 693, document scroll width 1,720, body scroll width 1,721, main width 642, and the locally contained `near-eye-metric-summary` scroller at 642 by 1,798 pixels. Opening its TOC added no width. Every route was width-clean at 390 pixels.

At narrow widths, Quarto creates an additional hidden `#TOC` clone on `notebooks/hypotheses/H06_daily.html` inside `#quarto-toc-toggle`. The accepted canonical TOC remains the single `#quarto-margin-sidebar > #TOC`. The route has ten canonical links, and all ten cloned links matched that canonical order at both tested widths. The audit records the hidden Quarto clone separately instead of treating it as a second canonical TOC.

The landing page remained width-clean at all three sizes and preserved 28 authors, 19 tables, 20 figure endpoints, 74 loaded images, the 17 Table 3 density thumbnails, the accepted Brown SVG, Supplementary Figures S8 and S12, site navigation, search, footer, next-page route, and the sole `MS Word` link. The desktop Word link is visible in the right TOC at 1,440 pixels; the accepted mobile TOC behavior clones the manuscript section list only.

The server made one browser-default request for `/favicon.ico`, which returned 404 because the page does not declare a favicon. It produced no browser console error and is not a document reference. All 46,071 document-local references passed the static checker.
