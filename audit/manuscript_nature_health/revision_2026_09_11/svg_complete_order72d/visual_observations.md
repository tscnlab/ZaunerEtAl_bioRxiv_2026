# Order72d document and native-Word visual observations

Date: 2026-09-11. Review stopped for a new renderer-specific defect.

The packaged document renderer produced 109 pages. All 21 figure appearances
were inspected as full-page rendered images. The other 88 pages are byte-identical
to the previously visually reviewed pre-SVG rendering, as recorded in
`page_comparison.json`. A further new contact-sheet pass was not completed after
the stop finding. Contact sheets are retained as generated evidence, not as a
claim that a separate new inspection of every sheet was completed.

| Document page | Figure appearance | Rendered-page observation |
|---|---|---|
| 6 | Main Figure 1 | Complete panels, colours, labels and caption; no new clipping observed. |
| 14 | Main Figure 2 | Complete curves, ribbons, site facets and caption; no new clipping observed. |
| 23 | Main Figure 3 | Complete composite; existing dense size and caption on page 24 preserved. |
| 70 | Supplementary Figure S1 | Complete metric distribution panels; no new clipping observed. |
| 71 | Supplementary Figure S2 | Worked derivation and labels visible; no new clipping observed. |
| 72 | Supplementary Figure S3 | Photoperiod graphic and legend complete at the retained display size. |
| 73 | Supplementary Figure S4 | Points, intervals, window labels and caption complete. Brown content remains historical pending replacement. |
| 74 | Supplementary Figure S5 | Both panels, legends and symbols complete. Brown content remains historical pending replacement. |
| 78 | Supplementary Figure S6 | Participant points, connecting lines, distributions and window labels visible. |
| 81 | Supplementary Figure S7 | Both composite panels visible at the retained dense display size; no new clipping observed. |
| 89 | Supplementary Figure S8, panels A-C | The first crop preserves all three temporal panels and their internal notes. |
| 90 | Supplementary Figure S8, panel D | The second crop preserves the site-category display and internal notes; caption and pagination preserved. |
| 91 | Supplementary Figure S9 | Paired-position points, intervals, legend and caption complete. |
| 92 | Supplementary Figure S10 | Three panels, bands, markers, support bars and internal notes visible. |
| 93 | Supplementary Figure S11 | Three panels, bands, markers, support bars and internal notes visible. |
| 94 | Supplementary Figure S12 | Three predictor panels, site labels, markers, intervals and internal notes visible. |
| 98 | Supplementary Figure S13 | Heatmap, cell labels and the accepted vector colour legend visible. |
| 101 | Supplementary Figure S14 | Both unit-specific portions and all interval rows visible. |
| 103 | Supplementary Figure S15 | Both composite panels, site colours and caption visible. |
| 105 | Supplementary Figure S16 | Selected three-panel layout, labels, intervals and caption visible. |
| 107 | Supplementary Figure S17 | STOP: the LibreOffice SVG renderer uses a serif face in place of the baseline sans-serif face and clips the right ends of the internal figure note. |

## S17 finding and comparison

Finding identifier: `ORDER72D-VIS-01`.

The defect is visible in `rendered_pages/page-107.png`. Compare the protected
pre-SVG baseline at
`../manuscript_qa_reference_case_final/page-107.png`.
The baseline note is complete and its figure text is sans serif. The current
render has a changed typeface and truncated right-aligned note. This is a
document/graphics observation, not an analytical finding.

The embedded S17 payload is byte-identical to the accepted H11 SVG:

`audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg`

SHA-256: `ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe`.

No source, font declaration, crop, extent, scientific value or document content
was changed to work around the finding. No second integration or render was run.

## Native Microsoft Word observations

The author opened the exact complete-SVG DOCX in Microsoft Word. Its native
accessibility state confirmed the exact candidate URL and 109 pages, with
AutoSave off. The document was not saved or edited during inspection. Native
screenshots in the task transcript were inspected for Main Figures 1 and 2,
both appearances of S8, and S17. These are representative application checks,
not a claim that every figure was reviewed in native Word.

Main Figures 1 and 2 and both S8 crops displayed successfully. At the current
130% Word view, S17 is sans serif and its note appears intact. Thus the visible
failure is currently isolated to the packaged LibreOffice preview, not proven
to affect native Word. The transcript screenshots are the native-application
evidence; no native screenshot files or application-created fallback image
parts were generated. The candidate DOCX hash remained unchanged after inspection.

The coordinator and harmonizer were notified. Order72d stops at its prescribed
review gate for classification of this rendering discrepancy. Production and
manuscript-source promotion remain unauthorized.
