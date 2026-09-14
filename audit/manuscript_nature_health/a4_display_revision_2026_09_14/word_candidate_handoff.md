# A4 display revision: Word candidate and bounded HTML delta

14 September 2026. Writer Order012. Final Word candidate: attempt_04.

Status: Word implementation, full-page review and nonbrowser content verification complete. The HTML delta is prepared and passes structural/content verification. Browser QA remains held by the coordinator while Order013 uses the serial slot. No live promotion is claimed or authorized here.

## Files for review

- `deliverables/Nature_Health_manuscript.docx`, SHA-256 `6f0ce7a50b608f91d24c31ae0b9b0edefe15828ed4f966732ea616c6e395a570`.
- `deliverables/editable_tables/`: all 19 native Word exports. S4 and S7 are revised; the other 17 are exact accepted files.
- `deliverables/Nature_Health_editable_tables.zip`: the same 19 individual table documents in one download.
- `html_candidate_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html`, SHA-256 `d7ee926c0910227004581915040f30ae01142290f0759839e897fa2b3f5f10aa`.
- `html_candidate_round2/delta_manifest.json` and its paired fragments specify the reversible, minimal webpage change. This is based on accepted C, not an uncontrolled copy of the concurrent website build.

## Author requests implemented

| Item | Final Word placement or presentation |
|---|---|
| All manuscript pages | 98 pages, all A4; 37 A4 portrait/landscape sections |
| Main Figure 1 | Page 6, portrait, full normal text width, proportional |
| Main Figure 2 | Page 13, portrait, full normal text width, proportional, complete caption on the same page |
| Main Table 2 | Page 10, portrait, normal full text width, all notes retained |
| Main Table 3 | Pages 15–18, A4 landscape, complete four-part table |
| Main Figure 3 | Page 21, A4 portrait, complete source image and caption |
| Supplementary Table S4 | Page 69, one A4 landscape page; one native table |
| Supplementary Table S7 | Pages 75–76, two A4 landscape pages; matching eight-column widths, split before Timing |
| Supplementary Figure S8 | Page 78, one uncropped complete source image and full caption on A4 portrait |
| Former Supplementary Figure S15A/B | New S15 on page 91 and S16 on page 92, each with its own heading and caption |
| Following figures | Former S16 becomes S17 on page 94; former S17 becomes S18 on page 96 |

Figures 1 and 2 were proportional in the accepted baseline but undersized. Figure 1 changed from 4.62 × 4.4 inches to approximately 6.268 × 5.970 inches; Figure 2 changed from approximately 4.204 × 5.35 inches to 6.268 × 7.978 inches. Both drawing extents and inner transforms agree with the unchanged SVG aspect ratios. No independent horizontal/vertical stretching is used.

S4 omits only the redundant column repeating the four-test FDR family. Every estimate, interval, adjusted p-value, sample and qualification remains. Its complete family note is retained. S7 retains all 17 metric rows, all eight columns and every exact sample string. Explicit line breaks separate participant and participant-day fields. The webpage keeps S7 as one continuous semantic table, not two artificial web pages.

All 23 SVG payloads remain byte-exact. All 24 retained table-image appearances are proportionally scaled source PNGs. The three newly embedded native table pieces are one S4 and two S7 pieces, not three new scientific tables. There are 21 numbered figure groups, 23 figure appearances and 18 numbered table groups. The 19 native exports include separately downloadable S11a and S11b.

The assembled manuscript is entirely A4. The 17 unchanged native exports retain their separately accepted layouts. In particular, native S2 remains its accepted A3 landscape export, while S2 in the assembled manuscript is now proportionally scaled to A4 landscape. Native Table 2 likewise retains its accepted separate-export layout; its assembled manuscript appearance is portrait A4. Order012 expressly protects those other 17 native files.

## Text and numbering preservation

The approved 20-row cumulative prose-change Markdown and CSV remain exact. No general prose editing was undertaken. The separate amendment ledger records the two Results references, split S15/S16 captions and headings, dependent S17/S18 labels, removal of the obsolete S8 continuation heading, and five accessible titles. Internal artwork and internal subpanel labels are unchanged.

R4.6.1 verified all 295 other nonempty body paragraphs exactly and in order, including title, author/affiliation text, abstract, manuscript prose, declarations and references. All 87 ZIP members other than `word/document.xml` are exact to the accepted main Word, including styles, relationships, embedded artwork and document resources.

## Verification evidence

- `attempt_04/evidence/word_pre_render_checks.csv`: 42/42 pass under R4.6.1.
- `html_candidate_round2/structural_content_checks.csv`: 15/15 pass under R4.6.1.
- `evidence/final_word/all_101_page_review.csv`: all 98 main pages and all three changed-native pages are A4 and pixel-file-identical to the individually inspected, full-resolution attempt_03 pages.
- `evidence/final_word/review_basis.json`: the complete original inspection notes and immutable inspection-record identity.
- `evidence/final_word/display_source_geometry_and_placement.csv`: all 47 drawing appearances, source geometry, original/new/actual dimensions, ratios, actual final pages and orientations.
- `evidence/final_word/native_table_actual_placements.csv`: the three native pieces and actual manuscript/native page numbers.
- `evidence/final_word/native19_source_binding_map.csv`: exact accepted inputs and the 19 final postimages.
- `evidence/final_word/caption_reference_and_presentation_amendments.json`: separate exact old/new record.
- `evidence/final_word/figure_renumber_map.csv`: collision-safe S15–S18 map.
- `evidence/final_word/C271_final_rehash.csv`: 271/271 exact.
- `evidence/final_word/N145_final_rehash.csv`: 145/145 exact.
- `evidence/final_word/accepted_svg23_final_rehash.csv`: 23/23 exact.
- `evidence/final_word/final_native19_rehash.csv`: 19/19 delivery files exact to the new binding map.
- `evidence/final_word/unchanged_dispatch49_final_rehash.csv`: 49/49 non-site/non-corpus dispatch members exact, including the approved text-history records and S4/S7 sources.

The last attempt changes only five stale accessible-title attributes from attempt_03. Re-rendering the main file and both changed native exports with the prescribed bundled renderer produced all 101 page PNGs byte-identically. Therefore the full-resolution review applies to the exact final render, not merely to a similar earlier layout. QA PDFs and PNGs remain internal evidence.

One existing converter qualification is retained: the right-edge footnote in the unchanged biological-sex SVG has the same appearance in accepted N page 100 and new S18 page 96. Source artwork is byte-exact. This was not introduced by the A4 scaling and was not redrawn or reopened under this placement-only order.

## Concurrent website ownership and remaining step

No browser, capture, server, live website, shared source, scientific builder or other owner's task was used or changed. The prescribed full-project/Quarto/Pandoc prohibitions were observed. The Harmonizer was not contacted or interrupted.

The active site promotion changed `audit/report_harmonization/phase4_corpus_manifest.csv` from the Order012 dispatch identity `01a2fdc1f1d11db45e28834893c79d620aa5321be1f49cff612b34589e068008` to observed `b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f`. Both are 11,479 bytes. The coordinator independently classified exactly this transition as authorized concurrent Order013 promotion in `audit/report_harmonization/final_documents_2026_09_13/writer012_external_order013_corpus_classification.md`, SHA-256 `e6d76a7e687bc452043e96c9518445934cc2a93d56ae0333e8431a631a389e84`. Its eight-member manifest `97bb79ce58e893b245aedee7d933f5d3e1afcdb8e045939bbb6e277c3dcd3352` reproduces exactly. The original 52-member dispatch seal and initial exact preflight remain immutable. The later preimage mismatch remains recorded in `static_dispatch50_final_rehash.csv`, with the precise authorized transition separately recorded in `authorized_external_transition.csv`. This is not a broader exemption. Frozen C and N and all other 49 applicable members remain exact. This classification does not release the browser slot.

Next: coordinator independent candidate review and, after explicit safe-point release, bounded browser QA of the six affected HTML endpoints. Subsequent website integration must apply only the accepted deltas to the completed website baseline. The prepared candidate must not replace the full website or interrupt Order013.
