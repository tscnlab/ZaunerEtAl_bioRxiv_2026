# Order 69b completion record

Date: 2026-09-02

Status: `PASS_AND_PROMOTED_PENDING_INDEPENDENT_ACCEPTANCE`

## Authorized correction

Order 69b authorized only a footer line-number suppression repair in the Word
postprocessor, one postprocessing pass from the preserved raw Quarto DOCX, one
page render, complete structural and visual verification, and one promotion
on complete PASS. No manuscript prose, result, table, figure, bibliography,
Quarto source, HTML, website source, research output, package state, or
lockfile was edited or rendered.

The postprocessor postimage is 31,160 bytes at SHA-256
`05ed9ca826757c643970a6d201fbcc15cfc83648d2ebdc8d44f707d85f214727`.
The focused diff is `order69b_postprocessor.diff`. Compilation passed with the
bundled document Python runtime. Reversing the focused diff against a
temporary copy of the postimage reproduced the 28,151-byte Order 69a preimage
at SHA-256
`f4cec2eaddf7d5ce375573af5bd2c0ad92366d8869d7c23d66d4bb435e139135`.

## Single postprocessing invocation

The postprocessor was executed once as follows:

```text
/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 scripts/manuscript_nature_health/prepare_word_manuscript.py audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/raw_reference_docx_quarto.docx audit/manuscript_nature_health/final_production_render_2026_09_02/word_capture/word_table_png_manifest.json audit/manuscript_nature_health/final_production_render_2026_09_02/word_capture/word_figure_png_manifest.json audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/candidate_reference_styled_11pt_footerfix.docx
```

The preserved raw DOCX at SHA-256
`a3f73e877106d8576a6aed362d6447551d68d366fd2e4c7a82ca7909329fb405`
was the sole DOCX input. The two accepted PNG manifests were read-only display
inputs. No earlier postprocessed candidate was used as input. The fresh
candidate is 28,792,333 bytes at SHA-256
`6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`.

## Structural verification

All 308 checks passed with zero failures. This includes all 301 inherited
Order 69a checks and seven footer-specific checks.

- The document has exactly two linked footer parts.
- Each footer has exactly two paragraph descendants and one preserved PAGE
  field.
- Each of the four footer paragraphs has exactly one
  `w:suppressLineNumbers` element.
- All 26 generated body section-break paragraphs retain exactly one
  `w:suppressLineNumbers` element.
- The document retains 27 sections, comprising 14 portrait and 13 landscape
  sections. Every generated landscape section retains a 72-twip line-number
  distance, and portrait settings remain unchanged.
- Normal remains Arial 11 point with 1.5-line prose spacing. Tables remain
  accepted PNG displays with compact internal spacing rather than manuscript
  body spacing.
- The reference title and heading sizes, A4 geometry, margins, continuous
  content line numbering, page fields, text, styles, captions, alternative
  text, media identities, display order, 32 table parts, 17 supplementary
  figures, and the two-page Supplementary Figure S8 crop are preserved.
- There are zero native `gt` conversion remnants and zero one-cell float
  wrappers.

The complete machine-readable result is in
`order69b_candidate_structural_checks.json`.

## Page render and visual verification

The fresh candidate was rendered to page images exactly once with the bundled
document renderer. The emitted PDF is 14,534,582 bytes at SHA-256
`bf80090749ff7e334422f8e584455b1c10ff147a01728745b71a8f984f559c73`.

The render contains exactly 102 A4 pages: 60 portrait and 42 landscape. There
are zero blank candidates and zero pages with characters outside page bounds.
All 102 page PNGs were inspected individually at original resolution.

The inspection covered clipping, overlap, missing glyphs, footer artifacts,
visible page numbers, continuous content line numbering, references, heading
and caption placement, display-caption continuations, table and figure
readability, and crop integrity. Pages 5 through 7 no longer contain the
stray footer-area values found in Order 69a. Content line numbers and centered
page numbers remain visible and correct. All table colors and compact cell
spacing are retained. Landscape tables use the available width without
clipping. Sparse orientation-transition pages and captions continued onto a
following page were checked as direct, intact continuations. Supplementary
Figure S8 remains an exact two-page display with panels A to C on page 82 and
panel D plus the complete caption on page 83. No duplicated or missing panel,
unreadable display, broken reference, or altered crop was found.

## Promotion and stability

After all checks passed, the candidate was copied once to the canonical path:

`manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`

The promoted canonical DOCX is byte-identical to the candidate: 28,792,333
bytes, SHA-256
`6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`.

Postflight verification confirmed the frozen QMD, nested profile, accepted
HTML, immutable reference DOCX, bibliography, stylesheet, validator, capture
script, PNG manifests and their embedded media, preserved raw DOCX, failed
Order 69a candidate, `.Rprofile`, `renv.lock`, root website sources, website
corpus manifest, and website index at their required identities. The accepted
website build remains exact for 892 of 892 files, with zero missing, added, or
changed files and zero symbolic links. Details are recorded in
`order69b_postflight_stability.json`.

The repaired canonical DOCX is ready for independent acceptance. Website
Order 70 remains held and was not started.
