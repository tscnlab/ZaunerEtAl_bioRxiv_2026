# Complete-page review and renderer compatibility

14 September 2026. This is a candidate review, not final delivery approval. Complete-page layout controls; the narrow browser view is secondary.

## Scope and unchanged identities

All 107 pages of the packaged-renderer PDF were inspected through their original page PNGs. The initial page-by-page findings remain unchanged in `main_round2_full_page_review.json`. Microsoft Word displayed 108 pages, so its page numbers must not be substituted for the converter page numbers.

- Main candidate: `deliverables/Nature_Health_manuscript_round2.docx`, SHA-256 `3f33431ed4e85b042f8a98e232b25b9617d8dae16bc8eff8df9595c05a80d611`.
- Editable S2: `editable_tables/round2/Table_S2.docx`, SHA-256 `0c834387ff6462b737381d028f0482636c5e55ad0443234f1cb8c165dda75334`.
- Both identities were rechecked after native Word inspection. No save, print, field update, link update or document edit was performed. AutoSave remained off. The zoom was returned from 200% to the original 119%; documents were closed without a save prompt.
- Browser observations are actual screenshots displayed in the task transcript, not claims based only on DOM or text extraction. The first review used desktop and 390 × 844 viewports. A separate 1280 × 720 read-only review resolved the S12 and S15B questions. No source or rendered file was changed during either review.

## Adjudication of initial suspicions

| Item | Initial converter observation | Native Word or browser evidence | Disposition |
|---|---|---|---|
| Editable S2 | Some mean ± SD units wrapped after ± in LibreOffice, including the brightest-10-hour mean row. | Native Word page 2, inspected at 200% and then complete-width 119%, kept `214.866 ± 508.56` and `422.54 ± 1,209.616` on one line. All 170 units also remain structurally intact as whole non-breaking units. | Converter-specific wrapping. Preserve the approved font sizes, column vector and current native candidate. No further font-size gate. |
| Main S2 table images | Need to verify all columns and distributions at actual page size. | Converter pages 60–62 were completely inspected: all 14 columns, 17 plots, complete units and final notes are visible. | Complete-page PASS at the already accepted secondary type size. |
| S10 first table part | Final MEQ result appeared cut off near the bottom of converter page 92. | The protected source PNG contains the complete final value ending `-0.189)`. Native Word page 93 also displayed it completely. | Suspected clipping disproved. Do not replace this protected PNG. Caption pagination remains a separate issue. |
| S12 figure | Internal subtitle appeared truncated at the right of converter page 90. | The browser displayed the entire subtitle through `open: not retained`, all three panel headers, axes and embedded notes. | Source clipping disproved; converter-specific presentation. Keep the accepted SVG unchanged. Native Word S12 was not separately inspected. |
| S15B figure | Top facet-strip labels appeared horizontally clipped on converter page 101. | The browser confirmed clipping in all three top scatterplot facets: `MCTQ MSFsc (hours)` extends beyond the narrow grey strips. The lower MEQ strips and right-hand boxplot header are complete. | Genuine accepted-source layout issue, not just conversion. Request a label/layout-only owner correction and updated source identity. Do not refit, alter plotted values, or rewrite the scientific caption. |
| S17 figure | Serif substitution and right-clipped embedded notes on converter page 105. | Browser and native Microsoft Word page 106 show sans-serif text and complete notes, including the final `base-10 above 1 lx` phrase. The SVG uses Helvetica and explicit text lengths. | Converter-specific SVG font handling. Keep the accepted SVG exact; no redraw or source font mutation. |

## Confirmed full-page corrections required

1. **S3 image content is clipped.** The actual protected `production_images/supp_table_s3_part_01.png`, SHA-256 `8139eb4ea512629f6457ad4f5dc6c586304b65c14f3324f22b6707a118b1cb4b`, cuts long denominator strings at cell boundaries in the Overall and some site rows. It is a Writer-owned static table-image problem. The accepted HTML fragment and editable native table retain their values. Replacing this one image requires an explicit addition to the six-image permission; no Brown analysis change is required.
2. **T2/S2 integrated HTML column widths.** Quarto removed the accepted pixel-width colgroups. At desktop width T2 became seven equal columns, and S2 became 14 equal columns. Preserve the accepted width vectors through the staged HTML conversion/CSS layer. Do not change font size, table values or distribution payloads. S2's descriptor and distribution columns must regain their accepted relative widths.
3. **Figure sizing at print size.** Main Figure 3 (converter page 22) and S16 (page 103) are too small for their dense labels and embedded tables. S7B (page 78) and both existing S8 appearances (pages 85–86) should be included in the same placement review. Increase physical display space or change the surrounding section orientation/page size while preserving accepted SVG bytes and existing panel/crop identities.
4. **Captions and headings.** Pair T3's caption on page 15 with the first table part on page 16; reduce S1 fragmentation over pages 57–59; pair the S3 caption on page 64 with its image; pair the S8 table caption on page 84 with page 83; pair S10's caption on page 94 with its final part; move the S9 heading from page 86 with the figure on page 87. Preserve all caption text and author-required top-level section starts.
5. **S15B top facet strips.** Obtain the narrowly corrected source described above. Enlargement alone does not restore source text clipped by a facet boundary.

The complete S5 A/B images on pages 69–70, with a full legend on page 71, are present. Their legend arrangement is a lower-priority pagination consideration, not a missing-figure defect. Source JPEG compression in the six current image crops remains honestly documented; no sharpening or invented pixels were used.

## Browser containment and cleanup

The 390 × 844 check showed a 375-pixel document width, with the 2,088-pixel S2 table contained in its 324-pixel wrapper. A keyboard ArrowRight action moved that wrapper by 40 pixels without widening the page. All 17 distribution images loaded. This is a containment check, not acceptance of the incorrect equal-column proportions.

The first round-2 server was PID 99834 at `127.0.0.1:63770`; the SVG adjudication server was PID 5242 at `127.0.0.1:64734`. Both served only the unchanged published candidate directory, accepted GET/HEAD only, rejected symlinks and directory listings, were stopped after inspection, and had no remaining listener. Their before/after inventories are exact. Task-created tabs were closed, temporary viewport overrides reset, and the three pre-existing user tabs left unchanged. Final website routes and download binding remain a separate coordinator-controlled integration step.
