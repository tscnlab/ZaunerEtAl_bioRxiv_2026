# REPORT-018 sealed owner order 71b: compact Word author block

Date: 2026-09-02

Prospective owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_DISPATCH`

This record supersedes the execution sequence in
`71_nature_health_word_compact_author_block_and_download_resync_queued.md`.
That historical queue record remains unchanged. Order 70 and Order 71a are
independently accepted. Word generation must use the exact QMD, Supplementary
Information source, and HTML accepted after Order 71a.

## Controlling identities

- Main QMD: SHA-256
  `a527b6cb9ba689ab15370a05776280c632073ef27b79320a271feca96b27c69f`,
  81,434 bytes.
- Supplementary Information QMD: SHA-256
  `fbfdde52cd24a60a5ff19eefb7901d3b7dcb268d97c2c922e0e87e7c944c652e`,
  25,590 bytes.
- Accepted self-contained HTML: SHA-256
  `438f80545e09eb1844d15c3d4495d7d2d4dbc07bcf039f4c8e4430b18e79ee0c`,
  30,877,834 bytes.
- Protected preimage canonical DOCX: SHA-256
  `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`,
  28,792,333 bytes.
- Order 71a independent acceptance: SHA-256
  `40536b9bdea257b3c7e79d05d49b2f96dabb25cbbe741c507ece17faf6447cb6`.
- Order 71b predispatch proof:
  `audit/report_harmonization/report018_writer_order71b_predispatch_proof.md`.

The predispatch proof passed with one correction to the historical candidate
helper. Both the isolated filtered raw DOCX and current canonical DOCX style
the unique `Abstract` paragraph as `Normal`, not `Abstract Title`. Therefore,
the historical helper at SHA-256
`90f6e4b0f9d993950f4b317651463e901ba1ac4e541736aed8f51292adda4744`
must not be copied or invoked unchanged.

## Exact bounded implementation

The Writer is authorized to perform exactly this sequence:

1. Confirm every controlling identity and ensure that no competing Quarto,
   Pandoc, DOCX postprocessor, or document renderer is acting on the nested
   manuscript paths.
2. Immediately before the first DOCX create or edit command for this order,
   run the documents-workflow artifact-operation marker exactly once with
   operation kind `edit`, expected output count `1`, and format `docx`.
3. Enable `_extensions/kapsner/authors-block/authors-block.lua` for the nested
   Nature Health DOCX format only. The HTML format must be byte unchanged.
4. Add one narrow helper to
   `scripts/manuscript_nature_health/prepare_word_manuscript.py` and call it
   exactly once in the existing postprocessing sequence. It must find exactly
   one complete 14-affiliation paragraph, exactly one correspondence
   paragraph, exactly one ISO date, and exactly one paragraph whose normalized
   text is `Abstract`, independent of paragraph style. It must require the raw
   affiliation and correspondence blocks to follow the abstract, then move
   only those two existing paragraph elements directly after Date and directly
   before Abstract. It must preserve their text, numbering, runs, styles,
   relationships, and order. Any zero or multiple match, unexpected order, or
   changed content must stop without producing an eligible candidate.
5. Make no other manuscript-source, scientific, display, caption, or
   postprocessor change. Record focused diffs and exact reversal proofs before
   creating the candidate.
6. Run exactly one manuscript-only DOCX render from the accepted QMD and exact
   reference document. Do not render HTML, the website, Supplementary
   Information separately, any report, or the full project.
7. Run the accepted Word postprocessor exactly once on that fresh raw DOCX.
   Do not use an earlier candidate or canonical DOCX as its input.
8. Verify the candidate completely before promotion. Require one compact
   numbered author line with all 28 accepted authors in order, exactly 14
   deduplicated affiliations in order, complete correspondence, and the exact
   consecutive front order Date, Affiliations, Correspondence, Abstract.
9. Run complete ZIP and OOXML checks for duplicate or orphaned parts,
   relationships, content types, styles, section geometry, landscape ranges,
   continuous line numbering, footer suppression, PAGE fields, image crops,
   drawings, captions, headings, references, tables, figures, and alternative
   text. Replay all protected manuscript text, citations, and ordered numeric
   tokens against the accepted source. Require zero unexpected differences.
10. Render the candidate once with the bundled documents `render_docx.py`
    workflow and inspect every rendered page at original resolution. Require
    no blank page, clipping, overlap, missing glyph, orphaned heading or
    caption, unreadable display, broken reference, or altered crop. Preserve
    the accepted two-page Supplementary Figure S8 treatment.
11. Only after every gate passes, replace
    `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
    once with the accepted candidate. Return exact preimage and postimage
    identities, evidence manifest, structural results, page inventory, and
    page-by-page QA record to the Harmonizer and Coordinator.

Preserve all 28 authors in accepted order, all manuscript text, values,
citations, figures, tables, captions, SVG-backed HTML authority, accepted
landscape ranges, line numbering, page fields, image crops, alternative text,
and the two-page Supplementary Figure S8 treatment. Promote only the accepted
canonical DOCX. Do not alter HTML or website output in this order.

The accepted Supplementary Figure S6 SVG remains the source authority at
SHA-256
`200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`.
If the DOCX transport converts it while packaging, the conversion must be
derived directly from that exact SVG and must remain sharp at original page
render resolution. Do not substitute a separately authored raster asset.

## Stop conditions and held follow-on

There is no second render, postprocessing pass, repair attempt, or patch cycle
within this dispatch. Stop on the first failed gate and report the exact
failure without promoting the candidate. Do not commit, push, upload, submit,
contact the journal, or delete historical evidence.

Order 71c is still held. It may synchronize the website download copy only
after the Harmonizer independently accepts the corrected canonical DOCX.
