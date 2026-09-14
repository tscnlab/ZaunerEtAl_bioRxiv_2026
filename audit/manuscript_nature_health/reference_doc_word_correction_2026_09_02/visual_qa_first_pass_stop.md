# Order 69 visual QA first-pass stop

Date: 2026-09-02

Status: stopped for a genuine layout defect.

The canonical reference-styled DOCX rendered through the isolated document workflow to 111 A4 pages: 67 portrait and 44 landscape. No page was blank. The increase from the prior 83 pages is explained by the reference document's 12-point Arial typography and 1.5-line body spacing; accepted body text and embedded media are unchanged.

## Defect

All 44 landscape pages inherit continuous line numbering from `assets/reference.docx` while preserving the accepted 0.45-inch left and right landscape margins. The default line-number distance places the leading digit or digits of three- and four-digit line numbers outside the PDF page boundary.

- affected pages: all 44 landscape pages;
- out-of-bounds glyphs: 222;
- glyph content: digits only;
- horizontal start range: -8.30 to -1.65 points;
- manuscript prose, captions, figures, and tables outside the page boundary: none.

Full-resolution visual inspection confirmed the clipped line numbers on pages 6 and 7. Portrait line numbers remain within the page boundary. Inserted section-break paragraphs also produce isolated line numbers near some page footers, visible on page 5 and following display pages.

The page-level programmatic evidence is in `docx_page_inventory.csv` and `docx_page_inventory_summary.json`; the complete rendered pages and 28 labelled contact sheets are preserved in `docx_pages/` and `docx_page_contact_sheets/`.

## Disposition request

Preserve the reference template, A4 page geometry, continuous line numbering in prose, and the accepted wide-table margins. A new bounded authorization is required before changing the landscape line-number distance or suppressing line numbering on inserted section-break paragraphs. No Quarto rerender, HTML render, display recapture, or website write is needed for such a repair.

No further mutation occurred after discovery. Website integration remains held.
