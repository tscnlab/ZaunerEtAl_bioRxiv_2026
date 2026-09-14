# Order72h served visual QA

Date: 2026-09-11

Result: PASS for the exact Order72h replacement candidate at SHA-256
`7055fc384bd845f8b42e3d37901c846060aeef6b8248536dc75240070e7a51e4`.

## Surface and viewport disclosure

The candidate was staged read-only and served from the Order72h recovery root
on one HTTP server bound only to `127.0.0.1:8765`. One supported in-app browser
surface was used. Fixed-width wrapper pages supplied inner iframe widths of
1440, 708 and 390 CSS pixels. The corresponding usable document widths were
1425, 693 and 375 CSS pixels because of the vertical scrollbar. The wrapper
label stated both requested width and display scaling. No source tree was
served.

## Inventory and semantic checks

At every width, the rendered document contained all 20 accepted SVG display
images, with zero broken SVGs, all 22 tables including 19 native gt tables, and
all 11 disclosure elements. Every disclosure was opened for review. The copied
R verifier separately passed all 43 HTML checks, including all 20 decoded SVG
hashes, every table cell vector, captions, retained values and exact visible
text relative to the accepted predecessor candidate.

Table 3 retained the Descriptives order exactly:

1. Duration: Time above 1,000 lx melEDI; Time above 250 lx melEDI during wake;
   Time below 10 lx melEDI before sleep; Time below 1 lx melEDI during sleep;
   Longest period above 250 lx melEDI.
2. Dynamics: Interdaily stability; Intradaily variability.
3. Exposure history: melEDI dose.
4. Level: Mean melEDI; Brightest 10 h geometric mean; Darkest 10 h geometric
   mean.
5. Spectrum: Melanopic daylight efficacy ratio.
6. Timing: Midpoint of the brightest 10 hours; Midpoint of the darkest 10
   hours; First light timing above 250 lx melEDI; Last light timing above 250
   lx melEDI; Mean timing of exposure above 250 lx melEDI.

All metric names were bold, the full word `Participants` was retained, R-squared
quantities were percentages, supported FDR decisions were bold, and the row and
group spacing matched the approved Table 3 candidate.

## Visual review

All 20 SVGs were brought into view and inspected at each of the three widths.
They remained contained, complete and undistorted. Uppercase panel tags were
positioned at the left side of their panels. Supplementary Figure S5 appeared
as one true two-panel SVG in the browser candidate. Supplementary Figure S12
showed no MDER legend. The current S7 and S15 composites rendered cleanly in
this sealed candidate; the author's later request to split each into separate
image blocks is explicitly queued for a subsequent display order and was not
mixed into Order72h.

All 22 tables were inspected on desktop. At tablet and mobile widths, all table
elements were visible and every one of their cell boxes fell inside the full
content extent of either its local scroller or its non-scrolling table box. The
first and last cell coordinates for every table were checked against that
extent. Representative wide tables, including Tables 2 and 3, Supplementary
Table S10, the H11 global-test table and Coordination status, were also
visually reviewed at the reduced widths. No table forced page-level overflow.

The browser Coordination status region was unique, retained all 45 cells,
declared `role="region"`, `aria-label="Coordination status"` and `tabindex="0"`,
and used local `overflow-x: auto`. Click focus placed the region itself in the
active element. At 1440 CSS pixels, three ArrowRight presses changed its
`scrollLeft` from 0 to 120. At 390 CSS pixels, eight presses changed it from 0
to 320, and forty further presses reached 1365.5 of the 1366-pixel maximum.
The final cell remained present and legible. The scrollbar was local.

For the complete page, `documentElement.scrollWidth` equalled
`documentElement.clientWidth` at every width: 1425/1425, 693/693 and 375/375.
Therefore no page-level horizontal overflow remained, including at the actual
375-pixel usable width inside the 390-pixel wrapper.

## Findings outside this sealed candidate

Writer's later native-Word review identified a blank-panel failure for
Supplementary Figure S5, horizontal splitting and pre-existing cropped
distribution plots in Supplementary Table S2, manuscript table-image font
mismatches for S5, S6 and S10, and requested separate image blocks for S7 and
S15. These are Word/cross-display follow-up findings, not defects in the exact
Order72h browser candidate. They have been returned to the Coordinator for a
new bounded repair order. No scientific values or accepted SVG bytes were
changed during this QA.

