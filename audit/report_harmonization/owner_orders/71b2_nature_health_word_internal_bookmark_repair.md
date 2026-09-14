# REPORT-018 sealed Order 71b2: Word internal-display bookmarks

Date: 2026-09-03

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_DISPATCH`

## Purpose and exact boundary

Order 71b stopped correctly after one DOCX render and one postprocessing pass,
but before page rendering or canonical promotion, because 22 internal display
hyperlinks had no bookmark targets. Independent predispatch proof confirmed an
unambiguous transport-only repair.

This continuation authorizes one focused postprocessor edit and one new
postprocessing pass from the already rendered raw DOCX. It authorizes no
Quarto render, no browser capture, no manuscript-content edit, and no second
document artifact marker. The marker already run for Order 71b remains the
single marker for the one requested canonical DOCX output.

## Frozen inputs

- Fresh raw DOCX: SHA-256
  `9cb087d8ee3d3e24fe17dea265e3898b2078c90e3cdd10bd02d4012b72f99786`,
  9,916,085 bytes.
- Stopped candidate evidence: SHA-256
  `313311f6cf87fdf7bf37fc27129cfc7b7048304587d1383ea53e77424756399d`,
  28,794,471 bytes.
- Current postprocessor preimage: SHA-256
  `1a2b8091b34cd0fa88dcf6143cf336c52b531773e66e1578ac818fddfba97adf`,
  38,747 bytes.
- Current DOCX-only config: SHA-256
  `3ed50e7dc3339bd42fc19393f10480baf733f485a65f34c03980fe4d466c5cf0`,
  561 bytes.
- Fresh table and figure manifests: SHA-256
  `6c7093de3f83be5e95fc6ddb299c6b05b1bde4935fff871abe6a1b3008e40b39`
  and
  `923410142cc15e5e655757e76200e78067cdec91bad5e545c31ccba9577118b6`.
- Protected canonical DOCX preimage: SHA-256
  `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`.

All other identities are fixed by
`report018_writer_order71b2_bookmark_predispatch_manifest.csv`.

## Authorized repair

1. Reconfirm every frozen identity and ensure that no competing postprocessor
   or document renderer acts on the manuscript paths.
2. Patch only `scripts/manuscript_nature_health/prepare_word_manuscript.py` to
   add one fail-closed display-bookmark helper, called exactly once after all
   display-wrapper replacements and before saving.
3. Before mutation, the helper must require exactly 124 internal hyperlinks,
   102 unique internal target names, 173 unique existing bookmark names, and
   the exact 22-name missing set reproduced in the predispatch proof. It must
   require `fig-s3` already to resolve.
4. Resolve the six main targets to the unique top-level caption paragraphs
   beginning `Figure 1:`, `Figure 2:`, `Figure 3:`, `Table 1:`, `Table 2:`, and
   `Table 3:`. Resolve each of the 16 supplementary targets to the unique
   Heading 3 paragraph beginning `Supplementary Figure S<n>.` or
   `Supplementary Figure S<n> and Table`.
5. Add exactly 22 zero-width `w:bookmarkStart` and `w:bookmarkEnd` pairs at the
   start of those destination paragraphs. Use 22 unique numeric IDs greater
   than every existing bookmark ID. Use the exact missing target names as
   `w:name`. Add no visible text and do not move, replace, or modify an
   existing run, paragraph, bookmark, hyperlink, relationship, image, or
   section element.
6. After mutation, require 195 unique bookmark names, the same 124 hyperlinks
   and 102 unique target names, zero unresolved targets, zero duplicate names
   or IDs, and exact preservation of all 173 pre-existing bookmark elements.
   Require the package relationship signature, body text, ordered numeric
   tokens, citations, styles, and all non-bookmark XML nodes to remain as
   produced by the accepted postprocessing logic.
7. Record a focused diff and exact reversal proof. Do not change the DOCX-only
   Quarto configuration, QMD, accepted HTML, captures, scientific artifacts,
   canonical DOCX, or website in this step.
8. Run the postprocessor exactly once from the frozen fresh raw DOCX and the
   sealed fresh table and figure manifests into a new candidate path. Preserve
   the stopped candidate unchanged as evidence. Do not run Quarto.
9. Run the complete Order 71b ZIP, OOXML, author-block, styles, text, ordered
   numbers, citations, tables, figures, captions, alt text, image hashes,
   crops, section geometry, line-number, footer, PAGE-field, and hyperlink
   validation against the new candidate. Add explicit before-and-after
   bookmark inventories and require every one of the 124 internal hyperlinks
   to resolve.
10. Only after all structural gates pass, run the still-unused single bundled
    `render_docx.py` page render. Inspect every page at original resolution and
    require no blank page, clipping, overlap, missing glyph, orphaned heading
    or caption, unreadable display, broken reference, or altered crop. Preserve
    the accepted two-page Supplementary Figure S8 treatment.
11. Only after all gates pass, promote the new candidate once to the canonical
    DOCX path. Return exact postimage identity, complete non-circular evidence
    manifest, structural results, page inventory, and every-page QA record to
    the Harmonizer and Coordinator.

Stop without page rendering or promotion on any mismatch. There is no second
repair, postprocessing pass, or page render in this continuation. Do not
commit, push, upload, submit, contact the journal, or delete evidence.

Order 71c remains held until the Harmonizer independently accepts the promoted
canonical DOCX.
