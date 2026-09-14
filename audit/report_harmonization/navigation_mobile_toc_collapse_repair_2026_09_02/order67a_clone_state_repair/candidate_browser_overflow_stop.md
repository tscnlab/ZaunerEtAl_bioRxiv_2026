# REPORT-018 Order 67a candidate browser QA stop

Date: 2026-09-02

Disposition: `FAIL_CLOSED_PREEXISTING_DESCRIPTIVES_OVERFLOW_NO_PROMOTION`

The corrected Order 67a implementation passed its single authorized candidate execution under R 4.6.1. The isolated candidate contains 892 files and zero symbolic links. Its exact build delta remains the 37 registered HTML routes, each carrying only the authorized 154-byte mobile table-of-contents script substitution. Static checks passed for 46,834 local references, 574 semantic tables, 177 figures, all preserved ordered identifiers and legacy duplicate-ID counts, the H06 semantic reversal, and the prospective HTML-hash-only corpus reseal.

Candidate browser QA then stopped at `notebooks/descriptives.html` at 708 by 1,000 pixels. The route passes the mobile table-of-contents contract: one disclosure, initially closed, all 17 links visible and keyboard focusable when opened, source-list order preserved, the first fragment resolves, and the disclosure closes after following its link. It has no broken image, console warning, console error, or TOC clipping.

The fail-closed condition is horizontal page overflow. With the mobile table of contents closed, the document client width is 693 pixels and the document scroll width is 1,720 pixels. The primary offender is the accepted `div#near-eye-metric-summary`, whose 642-pixel viewport contains a 1,798-pixel table. This wide gt table is part of the accepted substantive page content. It is not introduced by the Order 67a script, which preserves visible content, stylesheets, and the non-script DOM and reverses exactly to the live accepted HTML.

The partial browser matrix contains 20 unique route rows at 708 by 1,000 pixels. Nineteen pass. Descriptives is the single failure. Testing stopped immediately under the controlling one-combined-stop rule. No 390-pixel, desktop, production, or deferred H06 browser QA was attempted.

No promotion, corpus-manifest reseal, Quarto command, render, QMD edit, scientific edit, stylesheet edit, or live build mutation occurred. The shared include and live corpus manifest retain their preimages. The isolated server on port 57367 was stopped, its listener was cleared, the viewport was reset, and only the owner-created browser tabs were closed.
