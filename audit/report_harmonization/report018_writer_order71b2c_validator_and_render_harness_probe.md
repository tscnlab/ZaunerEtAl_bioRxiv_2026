# REPORT-018 Order 71b2c validator and render-harness probe

Date: 2026-09-03

Disposition: `PASS_FOR_VALIDATOR_ONLY_COMPLETION`

## Preserved repaired candidate

The repaired candidate is 28,794,774 bytes with SHA-256
`9dd88539d7fea176423ecc5b201ea1ef8c92b925c561ffd5cb6ee9b5463f0e92`.
Its built-in bookmark contract passed before the legacy validator stop.

## Complete validator replay

The entire base Order 71b validator and the complete Order 71b2b
bookmark-specific remainder were replayed with only the two stale
supplementary-identity loops corrected in memory. Both returned `PASS`.
No project source, DOCX, HTML or website file was changed.

The accepted identity and style inventory is:

- Supplementary Figures S1 through S12 each have one `Heading 3` and one
  `Body Text` paragraph in the period form. S8 also has its accepted single
  `Caption` continuation paragraph.
- Supplementary Figures S13 through S17 each have one combined `Heading 3`
  of the form `Supplementary Figure S<n> and Table S<n-2>.` and one
  period-form `Body Text` caption.
- Supplementary Tables S1 through S10 each have one period-form `Heading 3`
  and one period-form `Body Text` caption.
- Supplementary Tables S11 through S15 each have one combined heading shared
  with Figures S13 through S17 and one period-form `Caption` paragraph. S11
  also has its accepted single `Caption` continuation paragraph.
- The resulting supplementary identity inventory contains exactly 61
  paragraphs in the protected order.

The complete replay also confirmed the 87-part valid DOCX package, 28 authors,
14 affiliations, 91 bibliography entries, 53 images, zero native tables, 27
sections, 32 exact table PNGs, 18 exact supplementary-figure PNG drawings,
three protected main figures, 124 resolved hyperlinks, 102 unique targets,
195 bookmarks, exact preservation of all 173 prior bookmark pairs, exact
22-pair reversal and continued absence of `fig-s3`.

## Page-render harness preflight

- Bundled renderer: `render_docx.py`, SHA-256
  `d8fe979f76e11215e146e53484bb4cb4e5f3906b58debed6844171073b187286`,
  15,525 bytes.
- Renderer help and required Python imports passed.
- LibreOffice runtime responded as version
  `LibreOfficeDev 26.8.0.0.alpha0 2c87e51eeaa2b413ff4ae097b2705eea1995d8e5`.
- The designated `page_render` directory exists and contains zero files.
- No DOCX page render has been executed. The single page-render allowance
  remains unused.

No further masked structural assertion remains after the two consolidated
supplementary-identity corrections.

