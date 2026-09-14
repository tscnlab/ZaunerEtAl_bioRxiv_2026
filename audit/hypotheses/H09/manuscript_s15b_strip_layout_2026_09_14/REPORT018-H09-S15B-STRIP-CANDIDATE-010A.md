# REPORT018 H09 S15B strip candidate 010a

Date: 2026-09-14

Status: `CANDIDATE_PASS_AWAITING_COORDINATOR_ACCEPTANCE`

## Candidate

The sole new candidate is
`candidate/H09_observed_timing_patterns.svg`, SHA-256
`0a3d0cabcd6cdb67db072cfa566448a885a774db519bea442a973896a7d616e8`,
1,245,095 bytes.

An R 4.6.1 literal transformation changed exactly six rectangle attribute
prefixes. For the three upper left-panel strips, each clipPath rectangle and
visible grey background was centered on the unchanged label and widened from
158.96 to 192.00 units. The new x positions are 89.13, 308.21 and 527.28.
Every selected rectangle retains y 86.06 and height 47.66.

The exact reverse reproduces the accepted input SVG byte for byte at SHA-256
`c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3`.
After masking only the six selected prefixes, input and candidate are byte
identical. Text-node content and attributes, fonts, labels, node order,
identifiers, plot panels, axes, points, lines, intervals, boxplots, legend,
canvas dimensions and viewBox are unchanged.

Each 172.83-unit label has 9.585 units of inset on both sides. Adjacent strip
gaps remain positive. The fourth right-hand MCTQ label and its strip are
unchanged and complete. The frozen display CSV and primary-effects SVG were
hashed but their contents were not read or changed.

## Browser QA

The native candidate was served from the two-file, symlink-free temporary root
`/private/tmp/h09-s15b-order010a-preview.rHnqmH` on
`127.0.0.1:43137`. The server exposed only the wrapper and candidate SVG.
There were no external resources.

Supported in-app-browser checks passed at:

- original vector size, 1512 by 1224 CSS pixels in a 1600 by 1400 viewport;
- intended 600 CSS-pixel width, 600 by 485.7109375 in a 1280 by 800 viewport;
- narrow responsive view, 358 by 289.8046875 in a 390 by 844 viewport.

At original and 600-pixel sizes, all three full `MCTQ MSFsc (hours)` labels
are visibly complete, centered and legible. The extended grey headers have
clean boundaries and remain separated. No clipping, overlap or distortion is
visible. Axes, panels, points, model lines, intervals, boxplots, legend and
uppercase A/B tags appear intact.

The complete figure fits the narrow viewport with no horizontal overflow.
Fine figure text is naturally small at the 358-pixel overview scale, but the
corrected labels remain complete. This is recorded as an expected narrow-scale
limitation, not a candidate-specific clipping defect. Console errors and
warnings were zero.

Three viewport screenshots were captured and emitted by the supported browser.
Their SHA-256 identities and byte sizes are recorded in
`evidence/browser_screenshot_identities.csv`; the browser interface did not
provide a persistent screenshot-file path.

## Teardown and holds

The temporary viewport override was reset. The sole task-created tab was
closed and zero browser tabs remained. The server exited normally after one
interrupt, and a port-specific check found zero remaining listeners.

No scientific or display builder, Quarto, Pandoc, model, RDS reader, source
CSV reader, manuscript assembler or Writer process was run. No accepted
asset, old Order72j file, live manuscript, website, report, QMD, HTML, lockfile
or scientific result was edited. The candidate has not been promoted or sent
to Writer. Acceptance remains with the coordinator.
