# Order 69a visual-QA stop

Date: 2026-09-02

## Outcome

The single authorized Order 69a postprocessing pass and the single authorized page render completed, but the candidate is not eligible for promotion. Full-resolution visual inspection found visible line numbers attached to inserted section transitions despite the prescribed `w:suppressLineNumbers` elements.

No second postprocessing pass, Quarto render, table recapture, website build, HTML edit, or canonical-DOCX promotion was performed.

## Candidate identity

- Candidate: `candidate_reference_styled_11pt_linefix.docx`
- SHA-256: `30fc35924e573ae4311b413127f08388bb3aa2bcb771ffaa1b7ae9e5ff200a25`
- Size: 28,792,313 bytes
- Source raw Quarto DOCX SHA-256: `a3f73e877106d8576a6aed362d6447551d68d366fd2e4c7a82ca7909329fb405`
- Postprocessor SHA-256: `f4cec2eaddf7d5ce375573af5bd2c0ad92366d8869d7c23d66d4bb435e139135`

## Passing checks

- Structural validation: 301 checks passed. See `order69a_candidate_structural_checks.json`.
- Page render: 102 A4 pages, comprising 60 portrait pages and 42 landscape pages.
- No blank-page candidate was detected.
- No glyph extended beyond a page boundary.
- The prior landscape-page line-number clipping was resolved.
- Arial 11 pt reduced the document from 111 to 102 pages while preserving readable inspected tables and their accepted raster styling.

## Failing visual criterion

Pages 5 through 7 visibly show additional line numbers around the footer and inserted section transitions:

- page 5: `9` and `10`
- page 6: `11` and `12`
- page 7: `13` and `14`

These are distinct from the normal continuous manuscript line numbers and from the centered page numbers. Their persistence fails the Order 69a requirement that inserted section-break paragraphs have no visible line number. The candidate OOXML nevertheless contains exactly one `w:suppressLineNumbers` element on each inserted section-break paragraph, so the current evidence is consistent with the rendering engine ignoring suppression on a section-property-only paragraph or assigning the visible number to an adjacent paragraph. That mechanism is not adjudicated here.

## Evidence

- Full-resolution pages: `docx_pages_11pt_linefix/page-5.png`, `page-6.png`, and `page-7.png`
- Contact sheet: `docx_page_contact_sheets_11pt_linefix/pages_005_008.png`
- Page inventory: `order69a_docx_page_inventory.csv`
- Page inventory summary: `order69a_docx_page_inventory_summary.json`

## Disposition

Order 69a is stopped at visual QA. The candidate must not replace the manuscript DOCX. The current manuscript DOCX therefore remains the stopped Order 69 candidate with SHA-256 `218b6ba29fcc70fb5754725476c3e804eb84bd5700540ba673cb9554372fb009` pending a new bounded recovery disposition.
