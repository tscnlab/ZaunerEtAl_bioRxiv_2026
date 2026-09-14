# REPORT-018 sealed Order 71b2d: Word Supplementary Table S3 media repair

Date: 2026-09-03

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_DISPATCH`

## Purpose and protected state

Order 71b2c passed the complete structural suite and rendered 102 Word pages.
Original-resolution inspection found one genuine display defect before
promotion: long Overall-row denominators are clipped in Supplementary Table
S3 on page 61. All other pages passed.

Preserve without change:

- accepted bookmarked DOCX candidate SHA-256
  `9dd88539d7fea176423ecc5b201ea1ef8c92b925c561ffd5cb6ee9b5463f0e92`;
- existing Supplementary Table S3 capture SHA-256
  `d0d0216799239d4a11892b99ee26f06623d93761af7a7559a2cbddc150e8c4c7`,
  2,118 by 1,464 device pixels;
- corrected validators, accepted QMDs, accepted HTML, accepted direct
  Supplementary Figure S6 SVG, all other table and figure captures, the
  canonical DOCX preimage and integrated website at their dispatch pins.

The old S3 capture occurs exactly as `word/media/image15.png` in the accepted
bookmarked candidate. The canonical DOCX has not been promoted.

## Sealed repair

Replay the formatting-only probe and require the exact contract in
`report018_writer_order71b2d_supp_table_s3_capture_probe.md`.

Run exactly one table-only browser capture using the sealed probe helper and
the accepted HTML. Use one width and one font combination only:

```text
node audit/report_harmonization/probe_supp_table_s3_capture.mjs \
  file:///.../manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html \
  audit/manuscript_nature_health/order71b_execution_2026_09_03/word_capture_s3_repair \
  1059 12 2 97,117,118,118,128,122,118,122,118
```

Require all of the following before touching a DOCX:

1. the accepted HTML and helper reproduce their dispatch hashes;
2. the result reports zero clipped body cells;
3. the PNG is exactly 2,118 by 1,464 device pixels;
4. every label and numerator/denominator is visible at original resolution,
   including `555,738 / 1,086,468` and the four Overall-row denominators of
   `1,175,160`;
5. the PNG reproduces probe SHA-256
   `e8847874e5b1d08db8e67527c7ff4742fbd9912bae58ac161fecc21df6219e4c`.

Create a new candidate by copying the accepted bookmarked candidate to
`ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks_s3fixed.docx` and
replacing only ZIP member `word/media/image15.png` with the accepted repaired
PNG. Preserve the old candidate. Preserve ZIP member names and uncompressed
payloads exactly for all other members. Do not run the Quarto render or the
Word postprocessor.

Create a new table-manifest evidence copy that changes only the S3 file path
to the repaired PNG. Its recorded CSS width and height remain 1,059 by 732.
The original table manifest and capture remain immutable. A validator wrapper
may override only candidate, table-manifest and evidence-output paths.

## Required validation and promotion

1. Replay the dispatch manifest under R 4.6.1.
2. Require identical DOCX member sets between the accepted bookmarked
   candidate and the S3-fixed candidate.
3. Require `word/media/image15.png` to be the only changed uncompressed DOCX
   member. Require `word/document.xml`, relationships, bookmarks, hyperlinks,
   drawing extents, crops, sections and all other media to be byte-identical.
4. Run the complete corrected Order 71b structural validator against the new
   candidate and new table-manifest evidence copy. Require every package,
   author, text, style, citation, table, figure, crop, section, bookmark and
   hyperlink gate to pass.
5. Run a 71b2d wrapper that additionally proves the one-member media change,
   the exact 2,118 by 1,464 embedded image dimensions, 124 resolved internal
   hyperlinks, 102 unique targets, 195 bookmarks, the exact 22 repaired
   destinations, and continued absence of `fig-s3` from both hyperlink and
   bookmark sets.
6. Because the sole 71b2c page render exposed the defect, one replacement
   bundled `render_docx.py` invocation is authorized into a new empty
   `page_render_s3fixed` directory. No third render is authorized.
7. Require exactly 102 pages with unchanged page dimensions. Compare decoded
   page pixels with the 71b2c render: pages 1 to 60 and 62 to 102 must be
   pixel-identical; page 61 must differ only within the Supplementary Table S3
   image region. Inspect every page at original resolution and require no
   clipping, overlap, missing glyph, orphaned heading or caption, unreadable
   display, broken reference or altered crop.
8. Only after all gates pass, promote the S3-fixed candidate once to
   `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`.
9. Return the canonical postimage, exact helper and repaired-media identities,
   non-circular completion manifest, structural outputs, 102-page inventory,
   page-comparison record and every-page QA record.

No scientific, prose, QMD, HTML, website, table-value, figure, SVG, package,
lockfile or unrelated capture change is authorized. In particular, preserve
the accepted direct Supplementary Figure S6 SVG in the Quarto and HTML chain.
Stop on any mismatch.

Order 71c remains held until independent acceptance of the promoted canonical
DOCX.
