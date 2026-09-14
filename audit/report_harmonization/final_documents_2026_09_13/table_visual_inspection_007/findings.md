# Actual localhost table inspection, 14 September 2026

## Access disposition

The six revised attempt_04 HTML pages opened successfully in the selected Codex in-app browser through the normal localhost access flow. This is actual report-page inspection, not a generic browser-capability test. No browser permission was changed, no denied URL was bypassed, and no alternate browser surface was used. The older file-URL denial remains historical evidence; it is not a current blanket prohibition on these successfully accessed pages.

Served origin: `http://127.0.0.1:59715`. The read-only server exposed only the six exact HTML routes, enforced their hashes, and offered no directory listing. The server used the explicitly approved local bind permission. No upload, external transmission, Quarto command, QMD execution, scientific computation, source revision, or production promotion occurred.

## Inspection coverage

- All six pages were inspected through actual browser screenshots and read-only rendered DOM geometry at a 1440 x 1000 desktop viewport: Table 2; S2 parts 1, 2 and 3; S7 parts 3 and 4.
- Both sides of the wide S2 tables were inspected using their real horizontal scrollers.
- Additional 708 x 1000 inspection covered Table 2, S2 part 3 and S7 part 4, including the rightmost columns.
- S2 part 1 was vertically scrolled to inspect its bottom rows.
- Screenshots were reviewed in tool output. No screenshot files, submission images, Word files or final-print captures were produced.
- Final print-size and Word-layout acceptance are not established by this browser review.

## Findings

### TABLE-VIS-001: S2 page-level overflow

The S2 table scroller works, but the page itself also scrolls horizontally into a blank area. At a 708-pixel viewport, S2 part 3 reported document width 1,985 pixels. A normal horizontal scroll over the page header changed window scrollX from 0 to 708 while the table-region scrollLeft remained 0; the resulting screenshot was blank. This is a genuine containment defect, distinct from intentional table scrolling.

The positioned, visually hidden description spans associated with the distribution plots extend to approximately x=1,985.3 and are a likely cause. A repair must retain their accessible descriptions while containing their layout contribution. No repair was attempted during this inspection.

### TABLE-VIS-002: S2 column alignment and wrapping

The three S2 parts do not have one stable rendered column grid. Actual table widths were approximately 1,951.4, 1,945.1 and 1,968.3 pixels. The Unit column varied from approximately 65.9 to 48 to 85.3 pixels. Some numerical columns also expanded differently. This makes continuation-page alignment inconsistent.

The Scaling column was only about 76 to 79 pixels wide. The Symlog label wrapped into five lines, including an isolated final '1)'. The distribution images were complete but displayed at only 177 x 70.8 pixels; their axes were very small. The existing full numerical rows and images must be preserved during any layout adjustment. No td/th scroll-width overflow was detected in the S2 data cells, and the intended mean-plus-SD units remained on one line.

### TABLE-VIS-003: S7 header overflow and sample-label wrapping

Both S7 tails have a confirmed header overflow: 'Photoperiod FDR-adjusted p' occupies scrollWidth 73 pixels inside a 65-pixel cell. The header and adjacent narrow p-value columns need a better width allocation. In the exact-sample column, the participant-day subscript breaks awkwardly after 'participant-'; putting the two sample descriptors on deliberate separate lines would be clearer without changing content.

Both S7 tables otherwise render at approximately 896 pixels with the same column widths. S7 part 4's notes are present. At 708 pixels, the contained scroller reaches the final columns and the page itself remains 708 pixels wide.

### TABLE-VIS-004: Main Table 2 desktop inspection

The single three-row, seven-column primary-sample Table 2 is complete and readable at desktop width. Its table is approximately 1,320 pixels wide; the Work and Free columns are 180 pixels each, with estimates and complete intervals on separate deliberate lines. No cell clipping or multi-line interval fragmentation was seen. At 708 pixels, its contained table scroller reaches the FDR column without page-level overflow. This is a browser-layout finding, not final-print or Word acceptance.

## Preservation and teardown

The task-created browser tab was closed and the viewport override was reset. Server PID 82036 was stopped by SIGINT and exited 0. A separate `lsof -nP -iTCP:59715 -sTCP:LISTEN` returned no listener. The server's postflight.json confirms every served page, protected source file, package manifest and detached seal stayed byte-identical.

The accepted source package manifest remains `7be9e008ac1e16399ba9f92c5b5634cf5c0cee33143bdb2723b45e32be8a0232`. Remaining blockers concern layout and final output production, not an inability to inspect these localhost pages.
