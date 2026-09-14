# REPORT-018 owner order 70b: landing-page legacy overflow baseline clarification

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `NARROW_BROWSER_GATE_CORRECTION_WITHOUT_NEW_EXECUTION_AUTHORITY`

## Reason for clarification

Order 70 correctly freezes the other 36 website routes byte-for-byte, but its
absolute all-route browser phrase rejecting any horizontal page overflow is
incompatible with the accepted Navigation Order 67a browser baseline. The
navigation owner identified the contradiction before creating a candidate,
an Order 70 evidence directory, or any live write.

The accepted Order 67a production evidence contains exactly one immutable
exception at 708 by 1,000 pixels: `notebooks/descriptives.html`. Its exact
geometry is a 693-pixel document client width, 1,720-pixel document scroll
width, 1,721-pixel body scroll width, and 642-pixel main-content width. The
sole offender is the accepted `div#near-eye-metric-summary`, a 642-pixel
`overflow-x: auto` container holding a 1,798-pixel table. Opening its mobile
TOC adds zero pixels to the document width. At 390 by 844 pixels all 37 routes
are width-clean. This accepted historical responsive debt cannot be removed
by a landing-page-only order.

## Corrected browser gate

This clarification replaces only the impossible absolute overflow condition
in Order 70. Every other Order 70 and Order 70a authority, pin, candidate
gate, promotion rule, stop rule, and prohibition remains unchanged.

1. The new landing page must have zero page-level horizontal overflow at
   1,440 by 1,000, 708 by 1,000, and 390 by 844 pixels. Every wide manuscript
   table or display must remain contained in its local scroller or layout
   region without widening the document or body.
2. The other 36 routes must remain byte-identical and reproduce the complete
   accepted Order 67a browser and overflow baseline exactly.
3. At 708 by 1,000, the only permitted raw `page_overflow = TRUE` row is
   `notebooks/descriptives.html`. It may pass only if the exact document,
   body, main-content, offender, and contained-scroller measurements above
   reproduce; opening the mobile TOC adds zero width; all 17 cloned TOC links
   remain visible, focusable, and ordered; its first link resolves and closes
   the disclosure; and there is no broken image or page-attributable console
   warning or error.
4. At 390 by 844, all 37 routes must retain raw
   `page_overflow = FALSE`. Every unchanged route other than the sole
   Descriptives 708 row must also retain raw `page_overflow = FALSE` at 708.
5. Fail closed on any new affected route, new offender, increased document,
   body, main-content, offender, or table width, increased overflow range,
   loss of local containment, mobile-TOC-induced width, new clipping or
   overlap, changed route classification, or any other worsening.
6. The 37-route candidate and production browser matrices must classify rows
   explicitly as `CLEAN_NEW_LANDING_PAGE`,
   `ACCEPTED_LEGACY_OVERFLOW_BASELINE_PRESERVED`, or
   `CLEAN_UNCHANGED_ROUTE`. Any `NEW_DEFECT` classification is a mandatory
   stop.
7. Candidate and production evidence must compare complete raw geometry and
   browser behavior, not only pass flags or aggregate counts. Exact byte
   identity of the other 36 route files remains an independent gate.

## Controlling baseline evidence

The owner must reproduce exactly before candidate construction:

- the accepted overflow disposition at SHA-256 `33168944...`, 5,332 bytes;
- its non-circular manifest at SHA-256 `4b6e4371...`, 3,642 bytes;
- the central Descriptives width baseline at SHA-256 `10228df4...`, 887
  bytes; and
- the accepted Order 67a production browser route matrix at SHA-256
  `9571ee93...`, 75,495 bytes.

The new landing page has no inherited exception. It must meet the absolute
zero-overflow standard while preserving all accepted manuscript content and
all Order 70 navigation and responsive requirements.

## Boundary

This clarification grants no new candidate-generation, file-write, render,
retry, scientific, stylesheet, shared-include, QMD, or route authority. It
does not authorize a second Order 70 execution. It permits the already
acknowledged Order 70 to continue once from its untouched pre-candidate state
under the corrected baseline-aware browser gate.
