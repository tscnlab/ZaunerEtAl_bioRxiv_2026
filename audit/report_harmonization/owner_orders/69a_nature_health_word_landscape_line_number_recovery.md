# REPORT-018 owner order 69a: Nature Health Word typography and landscape line-number recovery

Date: 2026-09-02

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_POSTPROCESSOR_ONLY_RECOVERY`

## Authority and serial boundary

Order 69 produced the required reference-DOCX-based A4 manuscript, but visual
QA found that continuous line-number leading digits are clipped on all 44
landscape pages. This is a genuine Word-only layout defect caused by inherited
line numbering combined with the accepted 0.45-inch landscape margins.

Before dispatch, the author also approved 11-point Arial body text while
retaining the reference document's title and heading hierarchy and its
1.5-line prose spacing. This order therefore authorizes one exact Normal-style
override plus two exact changes inside `section_break_paragraph()` in the Word
postprocessor, one postprocessing pass against the preserved raw Quarto DOCX,
one candidate page render, full structural and page-by-page QA, and one
promotion only if every check passes. It does not authorize another Quarto
render, display recapture, HTML render, website integration, scientific
execution, or manuscript-content change.

Website Order 70 remains held until the repaired DOCX receives independent
acceptance.

## Exact recovery inputs and protected identities

Require these identities before mutation:

- current Word postprocessor:
  `scripts/manuscript_nature_health/prepare_word_manuscript.py`
  - SHA-256 `aae7c9307510ee5adc295e9e4d93e39496b0b50cc47d46bcfe5f22c6cf28e2c7`
  - 26,518 bytes
- sole permitted postprocessor input:
  `audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/raw_reference_docx_quarto.docx`
  - SHA-256 `a3f73e877106d8576a6aed362d6447551d68d366fd2e4c7a82ca7909329fb405`
  - 9,915,026 bytes
- stopped Order 69 candidate:
  `audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/candidate_reference_styled.docx`
  - SHA-256 `218b6ba29fcc70fb5754725476c3e804eb84bd5700540ba673cb9554372fb009`
  - 28,792,251 bytes
- stopped canonical DOCX:
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
- exact repository reference document: `assets/reference.docx`
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

Preserve all existing Order 69 orders, dispatch records, receipts,
dispositions, test evidence, rendered pages, and stopped artifacts. The
accepted 37-route website corpus and its manifest remain immutable.

## One exact three-part postprocessor edit

Edit only `main()` and `section_break_paragraph()` in
`scripts/manuscript_nature_health/prepare_word_manuscript.py`:

1. Immediately after loading the input DOCX in `main()`, require the `Normal`
   paragraph style to exist, then set that style's font to Arial 11 pt. Do not
   change its paragraph spacing. Require `Body Text`, `First Paragraph`,
   `Compact`, and `Bibliography` to continue inheriting body typography from
   `Normal`. Preserve the explicit reference-document sizes and font treatment
   for `Title` and `Heading 1`, `Heading 2`, and `Heading 3`, which are 26, 18,
   16, and 14 pt respectively in the raw DOCX.
2. On copied landscape section properties only, require exactly one inherited
   `w:lnNumType` element and set its `w:distance` attribute to exactly `72`
   twips. Leave page size, 0.45-inch left and right margins, 0.55-inch top and
   bottom margins, section type, and all portrait section line-number
   properties unchanged.
3. Add exactly one `w:suppressLineNumbers` element to the paragraph properties
   of every postprocessor-inserted section-break paragraph. This must prevent
   a blank break paragraph from receiving a footer line number without
   disabling continuous line numbering on manuscript content.

Do not edit any other function or file. Require a focused diff limited to these
three parts and an exact reverse proof from the postimage to the 26,518-byte
preimage at SHA-256 `aae7c930...`. Compile-check the postimage before execution.
If the Normal style is absent, the stated inheriting styles do not preserve the
required inheritance, an explicit title or heading size changes, or the
inherited landscape `w:lnNumType` count is not exactly one, stop.

## One postprocessor-only recovery pass

Create a fresh candidate path. Run the repaired postprocessor exactly once
using the preserved raw Quarto DOCX at SHA-256 `a3f73e877...` as its sole DOCX
input and the already accepted table and supplementary-figure PNG manifests.
Do not run Quarto, Pandoc, R, knitr, capture scripts, or any scientific code.
Do not regenerate or recapture a display. Do not use the stopped postprocessed
DOCX as an input.

Before execution, require no competing Word postprocessing or shared-build
process in this repository. Leave unrelated processes outside the project
untouched.

## Required structural and visual verification

Before promotion, require all of the following:

- the exact A4 geometry and reference-document style checks already accepted
  under Order 69;
- the `Normal` paragraph style is Arial 11 pt, while its reference 1.5-line
  paragraph spacing remains unchanged;
- `Body Text`, `First Paragraph`, `Compact`, and `Bibliography` inherit the
  Normal body typography, while `Title` and `Heading 1`, `Heading 2`, and
  `Heading 3` retain their explicit reference-document hierarchy and sizes;
- all 19 tables remain the already accepted 32 PNG parts with their compact
  internal spacing; do not apply a table-line-spacing change;
- record the resulting total, portrait, and landscape page counts; a change
  from 111 pages is permitted because of the authorized 11-point body font,
  but every landscape display must remain complete;
- zero blank pages;
- zero out-of-bounds glyphs across all rendered pages;
- continuous line numbering on content paragraphs;
- no visible line number on any inserted section-break paragraph;
- exactly one inherited `w:lnNumType` with `w:distance="72"` on every generated
  landscape section;
- unchanged portrait `w:lnNumType` properties;
- unchanged A4 page dimensions, landscape orientation, and accepted margins;
- complete preservation of all manuscript text, styles, captions, alternative
  text, media identities, display order, 32 table parts, 17 supplementary
  figures, and the accepted two-page Supplementary Figure S8 treatment;
- zero native `gt` conversion remnants and zero one-cell float wrappers; and
- full-resolution page-by-page visual inspection of every resulting page, with
  explicit checks for clipping, overlap, missing glyphs, blank pages, broken
  references, orphaned headings or captions, split display-caption pairs,
  unreadable displays, and altered S8 cropping.

Render the fresh candidate to page images exactly once for this QA. The fixed
72-twip distance is a single sealed parameter. If it does not eliminate all
out-of-bounds line-number glyphs while preserving the required content and
pagination, stop. Do not try another value or another repair.

## Promotion, stability, and return

Promote the fresh candidate to the canonical DOCX exactly once only after all
checks pass. Then prove that the QMD, nested profile, accepted HTML, reference
DOCX, capture manifests and files, scientific artifacts, package state,
lockfiles, website sources, all 892 accepted website files, and corpus manifest
remain unchanged.

Return:

1. the postprocessor postimage SHA-256 and byte count;
2. the focused three-part diff, compile check, and exact reverse proof;
3. the fresh candidate and promoted canonical DOCX identities;
4. the exact postprocessor invocation and proof that the preserved raw DOCX
   was the sole DOCX input;
5. complete OOXML structural results, including landscape and portrait
   line-number properties;
6. the page-render identity, page count, blank-page result, and complete
   out-of-bounds-glyph result;
7. page-by-page visual QA evidence covering every resulting page;
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

Stop once on any new input, structure, content, style, geometry, pagination,
line-number, rendering, visual, preservation, process, or teardown defect. Do
not patch or retry inside this order. The mandatory next gate is independent
acceptance of the repaired canonical DOCX before Order 70 may be dispatched.
