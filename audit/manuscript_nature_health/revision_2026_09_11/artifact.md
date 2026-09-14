# Word revision and editable table design contract

Date: 11 September 2026.

The retained base is `assets/reference.docx`, SHA-256 `8c0cf634a4958aa05412de3f5f15aa92c40cbb5331a2319f761530472697e15f`. Its single page was rendered and visually inspected in `reference_pages`. The reference contains the author and affiliation example and is retained unchanged.

The manuscript uses its established A4 page system, 1-inch portrait margins, 26-point Title, 18-point Heading 1, 16-point Heading 2 and 14-point Heading 3. Normal has 1.5-line spacing. The author has previously approved 11-point Arial body text. The current author request adds normal Abstract and Introduction Heading 1 paragraphs and a new page before every top-level manuscript section. Existing authors, affiliations, all figures, table images, notes, citations and internal links are preserved when producing the revised manuscript DOCX. New data-note references necessarily renumber later citations. Brown numerical content remains the accepted previous package until replacement analysis approval.

Separate table documents copy the 19 native HTML tables, each into one editable Word table. The HTML cell strings and hierarchy are the content authority. This operation does not recompute any scientific value. The source table grouping, spanner headers, site colours, shading, bold and italic text, superscripts, footnotes and distribution thumbnails are retained where Word supports them. The thumbnails remain images inside editable cells. No whole-table screenshot is used.

The author requests consistent typography and greater readability. Table body text uses Arial 10 pt, explanatory text and footnotes 9 pt, single line spacing, expandable rows, deliberate column widths, repeating header rows and 0.55-inch margins. Narrow tables S1 and S9 use A4 portrait; the other tables use A4 landscape except the 14-column S2 dictionary, which uses A3 landscape to preserve readable text and its distribution column. A3 is an implementation choice for this separate editing document, not a change to the manuscript paper size. Main and supplementary numbering is retained; the existing two components of S11 are exported as S11a and S11b.

Checks: compare every source cell's displayed text with the native Word cell; verify exactly one native table per document, intact embedded images, no scientific calculations, and source table SHA-256 identities. Render each document, review every page, and adjust widths, row pagination and spacing when needed. The Brown-derived documents are explicitly held from final evidence release while the author-directed grouping update is in progress.

## Completed independent revision

The QMD now has ordinary level-one Abstract and Introduction headings. The abstract and title wording are unchanged, pending author review of proposals. The only changed coded manuscript paragraph is P-M01, which now cites the Ghana and Türkiye site data notes together. No previous citation key was removed. The two dataset citations remain intact. Proper-name capitalisation is protected in the two data-note bibliography titles.

The revised Word candidate is `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_revision_2026_09_11.docx`, SHA-256 `acb6548997c29e96a065dfd5a26a682a3f0fb08170185e0c57aab3b1b0b256c0`. It is a review candidate, not a production release. The 13 top-level sections have explicit page-break-before formatting. The author and affiliation block remains on its own first page, followed by Abstract and Introduction. All accepted figure and table image content, 126 internal hyperlinks, 199 uniquely named bookmarks, declarations and the AI-assistance statement are retained. The manuscript still uses the previous accepted image pipeline; it does not yet implement the later SVG direction.

All 19 editable table documents are in `manuscript/R0_NatHealth/editable_tables/`. Each has one native table, exact displayed source-cell text, and preserved notes and captions. They contain 28 rendered pages in total. All pages were visually reviewed using the final `table_qa_main_caption_final` main-table renders and `table_qa_final` supplementary renders, with current contact sheets in `table_page_sheets_release_candidate`. No text clipping or overlapping cells was observed. Main-table captions are above the table and left-aligned. The small distribution illustrations remain pictures inside otherwise editable cells; no whole-table picture substitutes for a native table.

The full Word candidate has 109 rendered pages. All pages were visually reviewed in `manuscript_qa_final`; the subsequent bibliography proper-case repair changed only pages 47 and 48, which were separately inspected in `manuscript_qa_reference_case_final`. Page count and every other page image remained exact. The pre-existing, accepted display pagination remains; this check does not claim to have redesigned all existing figure and table-image page breaks.

`structural_validation.json` records 150 passing checks out of 150, including identical protected scientific content and HTML display strings. `visual_qa_page_inventory.json` records the exact final rendered-page paths and hashes. Native Word rendering was verified with LibreOffice through the document-rendering skill. No claim of a separate interactive Microsoft Word application review is made.

## Türkiye data-note verification

Access date: 11 September 2026. The official Open Research Europe article record identifies Akgun and colleagues, *Physiologically relevant real-world light exposure and its behavioural and environmental determinants in Izmir, Türkiye*, volume 6, article 333, published 8 September 2026, version 1, DOI `10.12688/openreseurope.24060.1`. The official catalogue reports that version 1 is awaiting peer review. The DOI's CSL metadata independently supplied the author list, article title, journal, volume, article number and publication date.

- Article: <https://open-research-europe.ec.europa.eu/articles/6-333/v1>
- DOI metadata: <https://doi.org/10.12688/openreseurope.24060.1>, requested with `Accept: application/vnd.citationstyles.csl+json`.
- Official catalogue used to verify current version and publication status: <https://open-research-europe.ec.europa.eu/search>.

This is an additional data-note citation, not a substitute for the data repository.

## Brown chronology and scientific hold

The author requested that the main adherence analysis use the same grouping as the exploratory cross-window analysis. The Brown owner confirmed the target sequence as preceding sleep, the complete ensuing daytime interval, and the following three-hour pre-sleep window, all assigned the work/free label of the wake-start date. The earlier main analysis also retained a complete daytime interval. The change concerns which pre-sleep window is paired and labelled; it must not be described as repairing a split daytime interval.

Only a partial earlier sensitivity exists for this alternative grouping. The owner requires a bounded replacement model and reporting package, including both coverage samples, inference families, calibration, temporal-dependence and influence checks, chest context, and variance descriptions. The author-directed replacement is being coordinated centrally. The writer has not fitted, recalculated, or relabelled any scientific result. Brown Methods, Results, tables and figures remain the previous accepted package until the replacement is accepted. The existing cross-window extension remains separately exploratory and subject to the accepted withheld within-participant claim.

## Later SVG instruction and numbering reconciliation

The harmonizer conveyed the author's direction to embed actual SVG image parts in Word, not manually rasterize them. A Word-generated compatibility preview may coexist only when the SVG remains the authoritative embedded source. This is an additional integration dependency, not completed by the independent candidate above.

`figure_format_inventory.json` pins the 20 current manuscript figures, comprising three main and 17 supplementary figures. Five current figure references already use SVG. Eight further same-name SVG files exist, but file existence is not acceptance. Seven current figures have no same-name SVG equivalent: main Figure 2 and current supplementary S9, S12, S13, S14, S16 and S17. The coordinator has reconciled these exact endpoints and is arranging bounded, export-only owner work. No SVG substitution or shared figure edit was made by this task.

The older display-selection numbering must not govern current integration. The anonymous Brown raincloud is current S6; geographic context is S7; light-source context is S8; paired hourly routine analysis is S9; day-type and activity-environment temporal figures are S10 and S11; the site-specific hourly routine comparison is S12. The complementary daily-routine analysis was expressly removed by the author and will not be reinstated. The Table 3 source remains byte-identical to the harmonizer's approved compact candidate, SHA-256 `d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2`, with Duration, Dynamics, Exposure history, Level, Spectrum and Timing in the approved order.

## Baseline identity clarification

The production download remains SHA-256 `74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8`; the production landing page remains `9c1beea41a0b203b8a8b032eade2ba7e4ab5067857d39e296a8503231af46eec`. Neither was edited.

The pre-existing local `_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx` is a distinct 3 September file with SHA-256 `45c866bec516919da064d7e86adbda57e6435db7b04f7ae10032f59000c77f79`. An initial validation incorrectly assumed it matched the production download. The failed assumption is preserved in `structural_validation_initial_baseline_assumption.json`. Its referenced display media match the production file; the latter additionally contains unused media members. The reason for the historical difference has not been established. This task did not restore or overwrite the local file. The corrected validator uses the accepted production download as media authority and protects both existing files separately.

## Runtime and reproducible document commands

Document conversion used Python 3.12.14, python-docx 1.2.0, lxml 6.1.1 and Pillow 12.3.0. These operations only copied displayed text, inspected structure and document layout, converted document representations, counted words/pages, or calculated file checksums. No scientific verification or research computation was performed. Quarto 1.9.37 rendered only the manuscript, with code execution disabled. The shared report-render queue and production output directory were not used.

```sh
# Run from manuscript/R0_NatHealth.
quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd --to html --no-execute --output-dir ../../audit/manuscript_nature_health/revision_2026_09_11/manuscript_render
quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd --to docx --no-execute --output-dir ../../audit/manuscript_nature_health/revision_2026_09_11/manuscript_raw

# Run from the repository root with the bundled Python runtime.
python scripts/manuscript_nature_health/prepare_word_manuscript.py audit/manuscript_nature_health/revision_2026_09_11/manuscript_raw/ZaunerEtAl2026_NatHealth_phase3_brown.docx audit/manuscript_nature_health/order71b_execution_2026_09_03/word_capture_s3_repair/word_table_png_manifest_s3fixed.json audit/manuscript_nature_health/order71b_execution_2026_09_03/word_capture/word_figure_png_manifest.json manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_revision_2026_09_11.docx
python tests/manuscript_nature_health/verify_revision_2026_09_11.py
python scripts/manuscript_nature_health/summarize_revision_visual_qa.py
python scripts/manuscript_nature_health/inventory_manuscript_figure_formats.py
```

The exact per-table rendering commands are retained in the two final table render manifests. Manuscript pages were produced with the bundled documents skill's `render_docx.py --emit_pdf`.

Used skills: `clarify-scientific-writing` for the meaning-preserving editorial proposals, `quarto-authoring` for headings/citations and isolated rendering, and `documents` for native Word construction and render-and-inspect verification. No model-analysis skill or scientific computation was used for this revision.
