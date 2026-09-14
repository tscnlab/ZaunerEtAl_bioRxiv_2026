# REPORT-018 sealed Order 71b2c: Word validator-only completion

Date: 2026-09-03

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_DISPATCH`

## Purpose and protected state

Order 71b2b successfully produced the repaired candidate, then stopped before
page rendering or promotion because two adjacent legacy validator loops do not
recognize the accepted combined Supplementary Figure and Table headings.

Preserve without change:

- repaired candidate SHA-256
  `9dd88539d7fea176423ecc5b201ea1ef8c92b925c561ffd5cb6ee9b5463f0e92`,
  28,794,774 bytes;
- postprocessor SHA-256
  `aeeabb11d97d812627de53b29e92e92f7fc6a87c5dc7006d223232c2f2ab20a4`,
  47,981 bytes;
- raw DOCX, prior stopped candidate, canonical DOCX, accepted QMDs, accepted
  HTML, accepted direct S6 SVG and integrated website at their dispatch pins.

No postprocessor invocation is needed or authorized.

## Authorized validator correction

Starting from `verify_order71b_docx.py` at SHA-256
`497eadb6a25c682df131d67bf6b40007856b2dde2d2c492753dde16dcf4b1a6b`
and 27,012 bytes, replace only the adjacent stale Supplementary Figure and
Supplementary Table cardinality loops. Require the exact 61-paragraph
identity and style inventory documented in the sealed probe:

1. Figures S1 to S12: one period-form `Heading 3` plus one period-form
   `Body Text`; S8 also has one `Caption` continuation.
2. Figures S13 to S17: one combined `Heading 3` pairing the figure with Table
   S11 to S15, plus one period-form `Body Text` figure caption.
3. Tables S1 to S10: one period-form `Heading 3` plus one period-form
   `Body Text` caption.
4. Tables S11 to S15: the corresponding combined heading plus one
   period-form `Caption`; S11 also has one `Caption` continuation.
5. No additional supplementary figure or table identity paragraph.

Record an exact focused diff and reverse proof to the 27,012-byte validator
preimage. Do not change the bookmark-specific wrapper except for evidence
paths if needed.

## Authorized completion

1. Replay the dispatch manifest and the complete validator/harness probe.
2. Reconfirm the preserved repaired candidate and every protected identity.
3. Apply only the validator correction above.
4. Run the complete corrected base validator and bookmark-specific wrapper
   exactly once against the preserved repaired candidate. Require every
   package, author, text, style, citation, table, figure, crop, section,
   bookmark and hyperlink gate to pass.
5. Only after full structural PASS, run the still-unused bundled
   `render_docx.py` exactly once into the empty designated `page_render`
   directory.
6. Inspect every rendered page at original resolution. Require no blank page,
   clipping, overlap, missing glyph, orphaned heading or caption, unreadable
   display, broken reference or altered crop. Preserve the accepted two-page
   Supplementary Figure S8 treatment.
7. Only after structural and every-page visual PASS, promote the preserved
   repaired candidate once to the canonical DOCX path.
8. Return the exact canonical postimage, corrected validator identity,
   complete non-circular evidence manifest, page inventory and every-page QA
   record.

No postprocessor run, Quarto render, browser capture, display regeneration,
scientific change, manuscript-content change, accepted HTML change, website
change, second artifact marker or second page render is authorized. Preserve
the accepted direct Supplementary Figure S6 SVG in the Quarto/HTML chain.
Stop on any mismatch.

Order 71c remains held until independent acceptance of the promoted canonical
DOCX.
