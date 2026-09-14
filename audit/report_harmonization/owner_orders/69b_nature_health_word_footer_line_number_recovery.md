# REPORT-018 owner order 69b: Nature Health Word footer line-number recovery

Date: 2026-09-02

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_OUTPUT_ONLY_FOOTER_RECOVERY`

## Authority and serial boundary

Order 69a repaired the clipped landscape line numbers and applied the
author-approved Arial 11-point Normal style. Its candidate passed 301
structural checks and rendered to 102 A4 pages with zero blank pages and zero
out-of-bounds glyphs. Visual QA nevertheless found two stray footer-area line
numbers per affected page around section transitions.

Independent diagnosis proved that the stray values do not belong to the 26
postprocessor-inserted body section-break paragraphs, all of which already
carry `w:suppressLineNumbers`. The preserved raw DOCX and the Order 69a
candidate each contain exactly two linked footer parts. Each footer contains
exactly two `w:p` descendants: one PAGE-field paragraph inside `w:sdt` and one
trailing blank paragraph. None of those four footer paragraphs carries
`w:suppressLineNumbers`. The two visible stray values per affected page match
those footer paragraphs.

This order authorizes one exact footer-suppression helper in the Word
postprocessor, one invocation of that helper from `main()`, one postprocessing
pass from the preserved raw Quarto DOCX, one candidate page render, complete
structural and visual QA, and one promotion only on complete PASS. It does not
authorize another Quarto render, display recapture, HTML render, website
integration, scientific execution, or manuscript-content change. Website
Order 70 remains held until this DOCX receives independent acceptance.

## Exact recovery inputs and protected identities

Require these identities before mutation:

- Order 69a postprocessor postimage:
  `scripts/manuscript_nature_health/prepare_word_manuscript.py`
  - SHA-256 `f4cec2eaddf7d5ce375573af5bd2c0ad92366d8869d7c23d66d4bb435e139135`
  - 28,151 bytes
- sole permitted postprocessor input:
  `audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/raw_reference_docx_quarto.docx`
  - SHA-256 `a3f73e877106d8576a6aed362d6447551d68d366fd2e4c7a82ca7909329fb405`
  - 9,915,026 bytes
- failed Order 69a candidate, which is evidence only:
  `audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/candidate_reference_styled_11pt_linefix.docx`
  - SHA-256 `30fc35924e573ae4311b413127f08388bb3aa2bcb771ffaa1b7ae9e5ff200a25`
  - 28,792,313 bytes
- unchanged stopped canonical DOCX:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
  - SHA-256 `218b6ba29fcc70fb5754725476c3e804eb84bd5700540ba673cb9554372fb009`
  - 28,792,251 bytes
- frozen manuscript source:
  `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`
  - SHA-256 `9853f0bd462c8c6ed0e74dae8a7bae9a570fdc8ba6f13644dfbc0d88109657d0`
  - 80,774 bytes
- accepted canonical HTML:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
  - SHA-256 `8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac`
  - 30,881,505 bytes
- accepted nested profile postimage:
  `manuscript/R0_NatHealth/_quarto.yml`
  - SHA-256 `c7c3fc8a96f1e65914cfb88c8d4de2bf8bcacb75fcf37902b262c79d2becae24`
  - 482 bytes
- immutable repository reference document: `assets/reference.docx`
  - SHA-256 `8c0cf634a4958aa05412de3f5f15aa92c40cbb5331a2319f761530472697e15f`
  - 60,429 bytes
- accepted table PNG manifest:
  `audit/manuscript_nature_health/final_production_render_2026_09_02/word_capture/word_table_png_manifest.json`
  - SHA-256 `8dcb34ea1692dc1091d7e16625be86bc45c65636ffeb6b863a99c7dacc914398`
  - 18,358 bytes
- accepted supplementary-figure PNG manifest:
  `audit/manuscript_nature_health/final_production_render_2026_09_02/word_capture/word_figure_png_manifest.json`
  - SHA-256 `375970be6b8567a52ec1589b0f89971819c6d85b75591768970bc1d4198fb881`
  - 7,241 bytes

Preserve all prior orders, dispatch records, receipts, dispositions, failed
candidates, test evidence, and page renders as immutable evidence. Preserve
the accepted website corpus and its manifest byte-for-byte.

## One exact postprocessor edit

In `scripts/manuscript_nature_health/prepare_word_manuscript.py`, add one
narrowly scoped helper and one call from `main()`:

1. Resolve the footer parts actually linked by the generated document. Require
   exactly two unique footer parts.
2. In each footer part, require exactly two `w:p` descendants and exactly one
   PAGE field. Require that none of the four paragraphs already contains
   `w:suppressLineNumbers`.
3. Append exactly one `w:suppressLineNumbers` element to the `w:pPr` of each
   of the four footer paragraphs, creating `w:pPr` only where absent.
4. Preserve every footer PAGE field, text node, style, structured-document tag,
   relationship, section reference, and all non-footer XML. The helper must not
   alter the visible page number itself.
5. Invoke the helper exactly once from `main()` before saving the generated
   candidate.

Retain the accepted Order 69a Normal-style override, 72-twip landscape
`w:lnNumType` distance, body section-break suppression, A4 geometry, margins,
and all other postprocessor behavior exactly. Do not edit any other file.

Require a focused diff limited to the helper and its one call, a compile check,
and an exact reverse proof from the new postimage to the 28,151-byte Order 69a
preimage at SHA-256 `f4cec2ea...`. Stop before execution on any mismatch.

## One postprocessor-only recovery pass

Create one fresh candidate path. Run the repaired postprocessor exactly once
using the preserved raw Quarto DOCX at SHA-256 `a3f73e877...` as its sole DOCX
input and the accepted table and supplementary-figure PNG manifests. Do not
run Quarto, Pandoc, R, knitr, capture scripts, or scientific code. Do not use a
prior postprocessed candidate as input. Do not regenerate or recapture any
display.

Before execution, require no competing Word postprocessing or shared-build
process in this repository. Leave unrelated processes outside the project
untouched.

## Required structural and visual verification

Before promotion, require all of the following:

- all 301 accepted Order 69a structural checks remain PASS;
- exactly two linked footer parts, exactly two `w:p` descendants per part,
  exactly one preserved PAGE field per part, and exactly one
  `w:suppressLineNumbers` per footer paragraph;
- all 26 inserted body section-break paragraphs retain exactly one
  `w:suppressLineNumbers`;
- every generated landscape section retains `w:distance="72"`, with portrait
  line-number properties unchanged;
- Normal remains Arial 11 pt with 1.5-line prose spacing, the inheriting body
  styles remain correct, and the explicit reference title and heading sizes
  remain unchanged;
- exactly 102 A4 pages, with 60 portrait and 42 landscape pages; footer-only
  suppression must not change pagination or orientation counts;
- zero blank pages and zero out-of-bounds glyphs;
- no stray line number in any footer or transition area, including the
  previously affected pages 5 through 7;
- continuous line numbering remains visible on content paragraphs;
- all visible PAGE fields remain correct;
- complete preservation of manuscript text, styles, captions, alternative
  text, media identities, display order, 32 table parts, 17 supplementary
  figures, and the accepted two-page Supplementary Figure S8 treatment;
- zero native `gt` conversion remnants and zero one-cell float wrappers; and
- full-resolution page-by-page visual inspection of all 102 pages, explicitly
  checking clipping, overlap, missing glyphs, footer artifacts, page numbers,
  broken references, orphaned headings or captions, split display-caption
  pairs, unreadable displays, and altered S8 cropping.

Render the fresh candidate to page images exactly once. If footer suppression
is ignored, pagination changes, a visible PAGE field changes, or any other
criterion fails, stop. Do not retry or alter the repair.

## Promotion, stability, and return

Promote the fresh candidate to the canonical DOCX exactly once only after all
checks pass. Then prove that the QMD, nested profile, accepted HTML, reference
DOCX, capture manifests and files, scientific artifacts, package state,
lockfiles, website sources, all 892 accepted website files, and corpus manifest
remain unchanged.

Return:

1. the postprocessor postimage SHA-256 and byte count;
2. the focused helper-and-call diff, compile check, and exact reverse proof;
3. the fresh candidate and promoted canonical DOCX identities;
4. the exact postprocessor invocation and proof that preserved raw DOCX
   `a3f73e877...` was the sole DOCX input;
5. footer-part, footer-paragraph, PAGE-field, section-break, style, geometry,
   line-number, content, and media structural results;
6. the page-render identity, exact 102-page count, 60/42 orientation count,
   blank-page result, and complete out-of-bounds-glyph result;
7. page-by-page visual QA evidence covering all 102 pages, including the prior
   failure area on pages 5 through 7;
8. protected-path and website-corpus stability evidence;
9. one completion record and one unique, non-circular evidence manifest; and
10. complete process teardown evidence.

## Prohibitions and mandatory stop

Do not edit the QMD, nested profile, bibliography, stylesheet, tables,
figures, captions, claims, numeric tokens, validators, capture scripts,
reference DOCX, legacy V0 DOCX, package state, lockfile, website source, or any
file below `_build/nathealth`. Do not render Quarto, HTML, a supplementary
document, a hypothesis page, the root website, or the full project. Do not
recompute science, recapture displays, commit, push, upload, submit, or contact
the journal.

Stop once on any new footer, field, structure, content, style, geometry,
pagination, line-number, rendering, visual, preservation, process, or teardown
defect. Do not patch or retry inside this order. The mandatory next gate is
independent acceptance of the repaired canonical DOCX before Order 70 may be
dispatched.
