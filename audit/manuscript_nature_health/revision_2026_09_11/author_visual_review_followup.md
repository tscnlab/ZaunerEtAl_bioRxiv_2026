# Author visual review follow-up

Date: 2026-09-11.

This additive record follows the immutable, stopped Order72d evidence seal.
It does not amend that candidate or authorize shared/source mutations. The
author is reviewing the complete-SVG Word candidate, SHA-256
`933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9`.

| ID | Author request or finding | Writer observation and next disposition |
|---|---|---|
| VIS-A01 | “Figure S15 really should be two images, especially since Panel B contains its own subpanels” | Split the accepted association-contrast and chronotype/site displays into independent image blocks. Preserve the latter's internal panels. Do not assume permission to renumber the entire supplementary series. Harmonizer/coordinator asked for exact component identities, layout and caption disposition. |
| VIS-A02 | “Same with Figure S7 - they should just be two separate images” | Split geographic support and nonlinear photoperiod into independent image blocks while preserving their scientific content. Coordinate the same source layout across selection preview, manuscript, Word and webpage. |
| VIS-A03 | Table S10 appears in Times New Roman; Tables S6 and S5 also have a font mismatch | Confirmed serif text in the unchanged pre-SVG manuscript images on pages 79, 80 and 96, compared with surrounding Arial. This is not a new SVG-induced Word font substitution. The separate editable DOCX table exports declare Arial on every text run. Correct the manuscript table capture/export pathway and verify all tables. |
| VIS-A04 | “Figure S5 does not show anything” | Independently confirmed in native Microsoft Word on page 74: outer A/B tags appear but both plot panels are absent. The packaged LibreOffice page 74 shows both panels. This is an actual native-Word SVG compatibility failure. The complete-SVG candidate remains stopped. |
| VIS-A05 | Table S2 should have one width, narrower site columns, and distribution plots must not be cut off on the right | Use one horizontal column set containing every site, with compact numeric columns and complete distribution graphics. Vertical pagination with repeated headers is acceptable; separate horizontal column panels are not the requested presentation. Preserve every cell, note and distribution. |

## Exact source/display trace for table font findings

Current manuscript inclusions:

- S5: `audit/manuscript_nature_health/figure_table_selection_assets/remaining_gt_candidates/tbl-plan-h02-glasses-variation-shapley-gt-candidate.html`.
- S6: `audit/manuscript_nature_health/figure_table_selection_assets/remaining_gt_candidates/tbl-plan-h02-chest-variation-shapley-gt-candidate.html`.
- S10: `manuscript/R0_NatHealth/display_assets/table_s8_person_level_synthesis.html`.

All three HTML sources specify a sans-serif font stack. Their older Word table
images visibly use a serif font. `scripts/manuscript_nature_health/capture_word_tables.mjs`
copies selected table markup into standalone HTML and sets table font sizes but
does not explicitly enforce the Arial font family in the capture stylesheet.
Loss of inherited styling in this route is a plausible cause, but the exact
computed-style failure has not yet been reproduced. Do not treat the hypothesis
as a demonstrated cause until checked within the released repair boundary.

The current full manuscript uses the table images listed in
`manuscript/R0_NatHealth/_word_test/table_pngs_v2/word_table_png_manifest.json`.
S5 and S6 each have one image; S10 has two vertical parts. Table S2 currently
has two horizontal column sets and three vertical row ranges. This capture
design must change to satisfy VIS-A05.

The separate native editable files are
`manuscript/R0_NatHealth/editable_tables/Table_S5.docx`, `Table_S6.docx` and
`Table_S10.docx`. A read-only OOXML font inventory of all 19 exported table
documents found explicit Arial ASCII/high-ANSI declarations on every text run.
No exported table document was changed. This does not establish visual
correctness of the manuscript's separately embedded table images.

## Native-Word finding and release boundary

Current S5 composite:
`audit/manuscript_nature_health/figure_table_selection_assets/brown_supplementary_figure_s5.svg`.

The full accepted source identity is in the copied combined SVG manifest and
embedding report inside `svg_complete_order72d/`. The native Word screenshot
showing the absent panels is retained in the task transcript. No DOCX save,
fallback creation, SVG rewrite, manual crop or source edit was performed.
The stopped seal remains unchanged.

The S17 LibreOffice-only font/note problem remains a separate recorded finding.
Before any complete-SVG Word release, all selected figures need native-Word
inspection; XML validity and a different renderer's success are insufficient.
Any compatibility remedy must retain authoritative native-vector scientific
content and be coordinated with the relevant source owner. A writer-only
divergent figure is not authorized.

The coordinator and harmonizer have been notified of these additive requests.
They require a separate exact display/layout boundary, not a retry of Order72d.
Brown main-analysis claims remain held while the alignment reopening proceeds.
No analysis was run and no numerical claim was recalculated in this review.
