# REPORT-018 Order 67a Descriptives overflow disposition

Date: 2026-09-02

Status: `PREEXISTING_RESPONSIVE_DEBT_ACCEPTED_NO_NEW_DRIFT_CONTINUATION`

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

This is a browser-gate clarification inside the already dispatched Order 67a.
It supplies no new candidate-generation, promotion, render, content-repair, or
scientific authority.

## Independent finding

The candidate browser stop is accepted as an out-of-scope pre-existing
Descriptives layout condition, not an Order 67a mobile-table-of-contents
defect.

Independent served-page inspection used exact accepted production and
candidate builds after zero-symbolic-link preflight. At 708 by 1,000 pixels:

- 36 of 37 accepted production routes have no horizontal page overflow;
- `notebooks/descriptives.html` is the sole accepted exception;
- production and candidate Descriptives geometry are exact: document client
  width 693 pixels, document scroll width 1,720 pixels, body scroll width
  1,721 pixels, and main-content width 642 pixels;
- the accepted `div#near-eye-metric-summary` is a 642-pixel
  `overflow-x: auto` container holding the 1,798-pixel table;
- the candidate mobile TOC opens within the 642-pixel content column, exposes
  all 17 links, and adds zero pixels to the document width; and
- candidate and production have the same page-level horizontal-scroll range.

At 390 by 844 pixels, all 37 accepted production routes are width-clean. The
candidate must retain that condition. The two independent loopback servers
were stopped, both listeners were cleared, temporary viewport overrides were
reset, and only the audit-created browser tabs were closed.

The Order 67a candidate remains an exact 154-byte embedded-script transition
on each of the 37 HTML routes. Visible text, non-script DOM, stylesheet,
scientific content, and every production path remain unchanged. The corrected
candidate passed all 37 static routes, 46,834 local references, 574 tables,
177 figures, 38 reversals, and the 424-row H06 semantic composition before
browser inspection.

The Descriptives page-level width is genuine historical responsive debt. It
may be repaired only under a separate later content/layout order. Order 67a
must neither fix nor worsen it.

## Exact browser-gate correction

Preserve the corrected candidate, its complete first and second stopped
evidence, and the implementation at `e3f1b14a...`, 65,208 bytes. Create one
new task-owned implementation postimage. Do not regenerate the candidate.

In `validate_browser_rows()`, immediately after reading `rows`, define:

```r
allowed_baseline_overflow <-
  rows$page_overflow &
  rows$route == "notebooks/descriptives.html" &
  rows$viewport_width == 708L &
  rows$viewport_height == 1000L
```

Add both exact cardinality gates:

```r
sum(rows$page_overflow) == 1L
sum(allowed_baseline_overflow) == 1L
```

Replace only:

```r
all(!rows$page_overflow)
```

with:

```r
all(!rows$page_overflow | allowed_baseline_overflow)
```

The same function validates the complete candidate matrix before promotion,
the retained candidate matrix during postflight, and the complete production
matrix. It therefore requires exactly the same one-route 708-pixel baseline
in all three evaluations and fails on any second route, any 390-pixel
overflow, removal or reassignment of the exception, or other changed width
classification.

Require R 4.6.1 parse, raw exact diff, exact reverse to `e3f1b14a...`, and the
same differential Air-parity rule already sealed. Do not format a project
implementation file. Seal the new postimage before its first use.

## Single browser continuation

The owner may start one new candidate-only loopback session against the
retained candidate. Preserve the 20-row partial stop matrix unchanged. Create
one complete new 74-row candidate mobile matrix covering all 37 routes at 708
by 1,000 and 390 by 844 pixels. For the sole Descriptives 708-pixel row,
record raw `page_overflow = TRUE`, the accepted-baseline classification, and
`pass = TRUE` only if all of these hold:

- client, document-scroll, body-scroll, offender, and contained-scroller
  measurements exactly reproduce the sealed central width baseline;
- the closed and opened mobile TOC add no document width;
- all 17 cloned links are visible, focusable, and in desktop-TOC order;
- following the first link resolves its fragment and closes the disclosure;
- the TOC itself is contained, usable, and unclipped; and
- no broken image or page-attributable console warning or error occurs.

Every other route and viewport must retain raw `page_overflow = FALSE`. Run
the already authorized three-route desktop candidate check, stop the server,
and prove its listener absent.

Only after complete candidate QA passes may the owner continue the already
authorized single atomic promotion, direct HTML-hash-only corpus reseal,
production browser QA, H06 deferred QA, and final postflight. Production must
reproduce the same exact Descriptives exception and no other overflow. Include
the central width baseline and a final candidate/production reconciliation in
the completion seal.

Stop and seal on any genuinely new defect. Do not regenerate the candidate,
edit CSS or page content, run Quarto, patch a QMD, alter science, expand the
exception, or retry again.

