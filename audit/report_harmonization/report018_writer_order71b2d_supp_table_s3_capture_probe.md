# REPORT-018 Order 71b2d Supplementary Table S3 capture probe

Date: 2026-09-03

Status: `PASS_FORMATTING_ONLY`

## Frozen inputs

- Accepted self-contained HTML:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`,
  SHA-256 `438f80545e09eb1844d15c3d4495d7d2d4dbc07bcf039f4c8e4430b18e79ee0c`.
- Existing Word capture:
  `audit/manuscript_nature_health/order71b_execution_2026_09_03/word_capture/supp_table_s3_part_01.png`,
  SHA-256 `d0d0216799239d4a11892b99ee26f06623d93761af7a7559a2cbddc150e8c4c7`,
  406,108 bytes, 2,118 by 1,464 device pixels.
- Existing accepted bookmarked DOCX candidate:
  `audit/manuscript_nature_health/order71b_execution_2026_09_03/docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks.docx`,
  SHA-256 `9dd88539d7fea176423ecc5b201ea1ef8c92b925c561ffd5cb6ee9b5463f0e92`.

No QMD, HTML, scientific value, analysis output, canonical DOCX or website
artifact was changed by this probe.

## Reproduction and result

The formatting-only Playwright probe
`audit/report_harmonization/probe_supp_table_s3_capture.mjs` at SHA-256
`d94f5d40ce125ed9d703a93035c6674afda1b34bb2d8839bf87e421eed0d9945`
measured cell `scrollWidth` against `clientWidth` in the accepted HTML table.
At the existing 1,059 CSS-pixel table width, 12-pixel capture font, five-pixel
horizontal cell padding and equal column allocation, five Overall-row cells
clip. The largest deficit is the Total cell: 133 required pixels versus 117
available pixels.

A width-only sweep found that 1,200 CSS pixels is the smallest tested equal-
column width with no clipped cell. A same-dimension alternative is preferable
for Word because it permits an exact media-part replacement without changing
drawing geometry or pagination. The passing table-specific settings are:

- table width: 1,059 CSS pixels;
- device scale factor: 2;
- font size: 12 CSS pixels, unchanged;
- horizontal padding: 2 CSS pixels per side;
- column widths in CSS pixels, from Site through Unclassified:
  `97, 117, 118, 118, 128, 122, 118, 122, 118`.

The instrumented result has zero cells with `scrollWidth > clientWidth + 1`.
The original-resolution image visibly preserves all labels and exact
numerator/denominator strings, including `555,738 / 1,086,468` and every
Overall-row denominator of `1,175,160`, with no overlap, clipping or wrapping.
It remains exactly 2,118 by 1,464 device pixels and preserves the 12-pixel
capture font.

Probe JSON SHA-256:
`ddc52380e3afa784b7aa5a489495668d7e211fd78a740aece3202df061c3a9fb`.

Passing image SHA-256:
`e8847874e5b1d08db8e67527c7ff4742fbd9912bae58ac161fecc21df6219e4c`.

The old capture occurs byte-for-byte as `word/media/image15.png` in the
bookmarked DOCX candidate. Therefore the repair can replace only that media
part in a copied candidate while keeping `word/document.xml`, bookmarks,
relationships, drawing extents, crops, page geometry and every other package
part byte-identical.
