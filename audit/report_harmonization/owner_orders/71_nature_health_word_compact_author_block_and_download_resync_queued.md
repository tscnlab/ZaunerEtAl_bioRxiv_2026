# REPORT-018 queued owner order 71: compact Word author block and later download resynchronization

Date: 2026-09-02

Prospective owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `QUEUED_NOT_DISPATCHED_WAITING_FOR_ORDER70_ACCEPTANCE`

## Purpose and serial blocker

The V0 Word manuscript uses the bundled Kapsner author-block filter to produce
a compact numbered author line and deduplicated affiliation block. The current
Nature Health DOCX instead contains 28 separate Author paragraphs. A Writer
read-only isolated test indicates that the current Nature Health metadata is
compatible with the same filter and that a narrow postprocessor relocation is
needed because the stock filter places affiliations after the YAML abstract.

This order is queued only. It grants no execution or write authority while
Order 70 is active. Its blocker is exactly
`WAITING_FOR_ORDER70_ACCEPTANCE`. It must not be dispatched until the final
manuscript landing-page integration has completed and received independent
acceptance.

## Required independent pre-dispatch proof

At the next serial safe point, the Harmonizer must independently reproduce:

1. V0 `docs/index.docx` at SHA-256
   `9d86291fb0cac81d4c9749107cfb4b8c8207035ad7321a4451b53903f234b4dd`;
2. `assets/reference.docx` at SHA-256
   `8c0cf634a4958aa05412de3f5f15aa92c40cbb5331a2319f761530472697e15f`;
3. the exact author, affiliation, corresponding-author, date, abstract, and
   style structure of the V0 DOCX;
4. the isolated Writer DOCX-only filter result, including one compact numbered
   author block, exactly 14 deduplicated affiliations, preserved author order,
   preserved affiliation numbering, and unchanged manuscript metadata; and
5. the exact need and deterministic behavior of the proposed affiliation and
   correspondence relocation.

The Writer's temporary files are evidence candidates, not accepted inputs,
until this independent proof passes. Any mismatch stops release.

## Prospective bounded implementation

Only after the blocker closes and the pre-dispatch proof passes, a sealed
dispatch may authorize exactly:

1. enabling `_extensions/kapsner/authors-block/authors-block.lua` for the
   nested Nature Health DOCX format only, with no HTML-format effect;
2. adding one fail-closed helper to the accepted Word postprocessor that finds
   exactly the generated affiliation and correspondence paragraphs and moves
   them immediately after the Date paragraph and immediately before
   `AbstractTitle`, without changing their text, numbering, runs, styles,
   relationships, or order;
3. invoking that helper exactly once in the Word postprocessing sequence;
4. generating one fresh raw DOCX from the frozen accepted manuscript source,
   the exact reference DOCX, and the accepted display manifests, followed by
   one postprocessing pass from that raw DOCX;
5. complete OOXML, metadata, relationship, style, geometry, line-number,
   table-image, figure-image, alternative-text, page-number, and content
   verification;
6. exactly one page render of the candidate and full-resolution visual review
   of every page; and
7. one canonical DOCX replacement only after every gate passes.

The author line must be compact and preserve all 28 authors in the accepted
order. Affiliations must be deduplicated to exactly 14 entries and placed
between Date and AbstractTitle. The corresponding-author text and markers
must remain complete. The abstract, manuscript body, references, captions,
tables, figures, Supplementary Information, numeric tokens, citations, and
accepted two-page Supplementary Figure S8 treatment must remain unchanged.

The accepted A4 section geometry, reference-document styles, Arial 11-point
Normal body style, 1.5-line prose spacing, landscape 72-twip line-number
distance, body and footer line-number suppression, PAGE fields, native-table
absence, high-resolution table parts, and SVG-backed HTML authority remain
controlling.

## Candidate and visual gates

Before promotion, require:

- a focused source/config and postprocessor diff with exact reversal proofs;
- one and only one DOCX render, with no HTML, website, supplementary, report,
  hypothesis, or full-project render;
- exact preservation of all protected text and ordered numeric tokens;
- valid ZIP and OOXML relationships with no duplicate or orphaned parts;
- exact author and affiliation structure described above;
- complete headings, references, fields, captions, drawings, alternative
  text, tables, figures, and Supplementary Information;
- continuous line numbering on manuscript content, no line numbers in footer
  or section-break artifacts, and correct visible page numbers;
- no blank page, clipping, overlap, missing glyph, orphaned heading or caption,
  unreadable display, broken reference, or altered crop; and
- complete page-by-page inspection at original rendered resolution.

Stop once on any defect. Do not patch or retry within the released execution.

## Promotion and later website synchronization

Promote only the accepted candidate to
`manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
after all candidate gates pass. Preserve the canonical HTML, manuscript QMD
content, scientific artifacts, website, package state, and lockfiles.

After the corrected DOCX receives separate independent acceptance, issue a
separate no-render synchronization order to replace only
`_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx` with the exact
accepted canonical DOCX. That later synchronization must prove the landing
page HTML and all 36 other routes unchanged, the download link resolved, the
complete build live-exact, and the Order 70 browser and navigation result
unchanged. This queued order itself does not authorize the website copy.

## Prohibitions

Do not dispatch or execute before Order 70 independent acceptance. Do not
change scientific data, analyses, estimates, intervals, p-values, tables,
figures, captions, citations, manuscript prose, HTML, website source or
output, shared navigation, stylesheets, corpus manifest, packages, or
lockfiles. Do not run a full-profile or full-project render. Do not commit,
push, upload, deploy, submit, contact the journal, or delete historical
evidence.
