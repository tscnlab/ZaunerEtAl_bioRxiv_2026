# First candidate layout check

S4 native export is complete on one A4 landscape page. S7 is complete on two A4 landscape pages with all notes and exact sample fields, but the Photoperiod header has an awkward mid-word wrap. Widen that column, retaining the font size and matching widths on both parts and the continuous HTML table.

Main Figures 1 and 2 are proportional and now full text width. Figure 1 and its complete caption fit together. Figure 2 requires a dedicated A4 display section with smaller vertical margins so its full-width artwork and complete caption can share the page. No body font changes are needed. Main Figure 3 needs a lower proportional height to retain its complete caption on the same portrait A4 page.

The first HTML candidate retained every image and table value, but seven S7 sample cells already had a deliberate line break. Add a break only to cells lacking one, rather than duplicating it. The failed content check and initial candidate are retained.

A bounded PDF text-index attempt was cancelled because a whole-document text extraction stalled on the complex SVG pages. The converter succeeded. A per-page text index with timeouts is used only as an inspection aid; full-page images remain the layout authority.

An empty unused placeholder was accidentally created at the repository root during helper preparation and immediately removed with apply_patch. It contained no user data. No accepted source or package was modified.
