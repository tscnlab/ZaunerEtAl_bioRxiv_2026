# REPORT-017 order 32c visual QA record

## Loopback lifecycle

- Document root: `_build/nathealth`
- Command: `python3 -m http.server 0 --bind 127.0.0.1 --directory _build/nathealth`
- PID: 44777
- Address and port: `127.0.0.1:56205`
- Result URL: `http://127.0.0.1:56205/notebooks/hypotheses/H01.html`
- First retained HTTP request: 2026-08-15T08:05:22+02:00
- Teardown: Ctrl-C after the complete inspection
- Listener verification: `lsof -nP -iTCP:56205 -sTCP:LISTEN` exited 1 with no output
- Browser console errors or warnings: zero
- Server log anomaly: only an irrelevant `favicon.ico` 404

The exact launch timestamp and exact Ctrl-C timestamp were not separately
persisted. The retained first request, PID, port, command, route, teardown
output, and no-listener check bound the lifecycle. This evidence limitation is
included in the combined stopped-state record.

## Coverage

- Entire result route inspected at 1440 by 1000 and 708 by 1000.
- All 13 reader sections captured and inspected at both widths.
- All ten figures inspected at final desktop display size.
- Principal figure and principal table inspected at desktop, narrow, and a
  retained 200 percent enlargement.
- Exported principal figure inspected at 1021 by 720 CSS pixels, corresponding
  to approximately 10.6 inches at 96 CSS pixels per inch and its intended
  10.5-inch final-size equivalent.
- All four tabbed diagnostic figures were opened and inspected.
- All captions, legends, callouts, table scrollers, links, and page navigation
  were reviewed.

The browser capture service returned JPEG-encoded screenshot bytes even when
the requested evidence filenames used a `.png` suffix. The files are retained
unchanged and are valid readable images; this is an evidence-format note, not
a page-layout defect.

## Layout results

- At 708 pixels, the document had client width and scroll width of 693 pixels.
  There was no document-level horizontal overflow.
- Five wide gt tables and two code blocks used contained horizontal scrollers.
  No element overflowed without a scrollable ancestor.
- The principal publication table remained readable on desktop and usable in
  its narrow presentation.
- No clipping, broken page navigation, missing figure, missing caption, or
  missing alt text was observed.

## Reader-facing defects

1. Figure 5 has overlapping direct labels in the dense central clusters of
   the matched near-eye and chest panels. Several labels cannot be read
   independently at final display size.
2. Important raster-figure text is too small at the 708-pixel width,
   especially in Figure 1 and Figure 6. The labels are present but do not meet
   the normal 7-point final-size readability target.

No display repair was made because the order requires a consolidated stop
without patching or rerendering.
