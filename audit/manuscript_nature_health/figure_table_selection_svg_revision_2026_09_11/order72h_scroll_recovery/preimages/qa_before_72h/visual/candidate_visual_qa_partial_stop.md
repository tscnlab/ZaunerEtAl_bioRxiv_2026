# Candidate visual QA partial stop

Date: 2026-09-11

Candidate: `rendered/manuscript_figure_table_selection.html`

Candidate SHA-256: `7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4`

The candidate was served byte-for-byte from the owner root on loopback and
reviewed in the in-app browser at 1440, 708, and 390 CSS-pixel wrapper widths.
All 11 disclosures were opened before each complete count. The review found 20
rendered accepted SVG figures, 22 tables, 19 `gt` tables, and 11 disclosures at
each width. No SVG was broken or outside its display container. No table was
hidden. Wide scientific tables remained inside their intended local horizontal
scrollers.

All 20 SVG displays were visually reviewed at desktop, tablet, and mobile
widths. All 22 tables were visually reviewed at desktop width. Table 3, the
full Descriptives table, and a person-level table were additionally inspected
inside their scrollers at tablet width. Panel tags are uppercase and at the
left side of their panels where applicable. Supplementary Figure S5 is one
two-panel SVG. Supplementary Figure S12 has no MDER legend.

Desktop and tablet passed with document scroll width equal to root client
width. At the 390 CSS-pixel viewport, the root client width was 375 px and the
document scroll width was 383 px. The resulting 8 px page-level horizontal
overflow is visible in the browser review. The unwrapped Markdown table under
`Coordination status` is the page-level source: its bounding box was 25.50 to
382.86 px, width 357.36 px, while the root client width was 375 px. The
scientific images and tables are not the source of this defect.

The exact narrow fix proposed to the Coordinator is to wrap only the
`Coordination status` Markdown table in the existing `local-table-scroll`
region pattern. No QMD, CSS, candidate, canonical HTML, accepted SVG, table
fragment, or scientific output was changed after this finding. The browser
screenshots were emitted in the in-app review session. The browser interface
does not expose a supported local screenshot-save path, so no separate raster
copy was manufactured.

One console error appeared at initial iframe harness load and did not recur
when the candidate itself was navigated directly. Its timestamp predated the
direct candidate check, so it is classified as harness-only rather than a
candidate error.

Status: stopped pending a sealed wrapper and single replacement-render
recovery authorization.
