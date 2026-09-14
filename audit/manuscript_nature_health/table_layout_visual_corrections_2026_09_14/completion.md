# Table layout corrections: completed owner review

14 September 2026. Selected candidate: `attempt_02`.

Status: ready for the coordinator's independent acceptance and subsequent production disposition. This is a completed candidate full-page review, not a claim that final Word files or the integrated website have been replaced.

The author's instruction to prioritise the complete page layout controls. Cropped browser screenshots are secondary and are not an acceptance or production-release gate.

## Result

All six candidate pages were actually inspected at 1440 × 1000 and 708 × 1000, including both ends of wide tables, all rows, distribution plots and applicable final notes. All six also received an actual inherited-width browser proof. Six additional complete, unscaled full-viewport screenshots retain the whole table at once.

| Finding | Resolution | Evidence |
|---|---|---|
| TABLE-VIS-001: S2 escaped the page width | Fixed. The document stays within its viewport, including when scrolling outside the table. Keyboard scrolling reaches both table ends. Accessible descriptions remain intact. | All three narrow S2 cases and outside-scroll records |
| TABLE-VIS-002: unequal S2 grids and awkward wrapping | Fixed. All three parts render the same 14-column, 2088.008-pixel grid. The 16-pixel source base, all 170 complete mean ± SD units and all 17 original PNG payloads are retained. Scaling text uses semantic line breaks. | Recorded column widths, full-page screenshots and content checks |
| TABLE-VIS-003: S7 header and sample-label overflow | Fixed. Both tail parts use the same grid. The affected FDR columns render at approximately 84 pixels, with no header or cell overflow. Participant and participant-day counts each occupy one complete line. | S7 desktop/narrow screenshots and exact source checks |
| TABLE-VIS-004: preserve main Table 2 | Preserved. The fragment is byte-identical to accepted Table 2, with three primary-sample rows and seven columns. Complete notes and intervals are visible. | Full-page Table 2 screenshots and fragment SHA-256 check |

Final verification:

- Revised candidate: **3,266/3,266** content, source and structural checks passed after final map reconciliation.
- Visual-evidence and preservation reconciliation: **854/854** checks passed. These support the recorded actual visual review; they do not substitute for it.
- Complete inherited baseline suite: **1,118/1,118** checks passed in a redirected output directory.
- Immutable baseline: all **176/176** members remain exact.
- All **407** page cells, all **170** whole mean ± SD units, all **17** embedded PNGs and the cumulative **20-position** editorial record are preserved.
- All 24 unaffected table-image records, 17 unaffected native-table records and 48 unaffected drawing records remain byte-identical CSV records.
- Seven browser console records contain no warnings or errors.

## Physical-size implications

These are proportional image-placement implications from the measured unscaled table rectangles, not final Word measurements. Actual browser intended-width proofs were also inspected.

| Table | Measured CSS rectangle, pixels | Intended width | Proportional height | Allowed height |
|---|---|---|---|---|
| Table 2 | 1320.023 × 586.547 | 10.55 in | 4.688 in | 6.2 in |
| S2, part 1 | 2088.008 × 894.711 | 15.55 in | 6.663 in | 9.2 in |
| S2, part 2 | 2088.008 × 739.906 | 15.55 in | 5.510 in | 9.2 in |
| S2, part 3 | 2088.008 × 749.508 | 15.55 in | 5.582 in | 9.2 in |
| S7, part 3 | 896.008 × 361.188 | 10.55 in | 4.253 in | 6.2 in |
| S7, part 4 | 896.008 × 305.594 | 10.55 in | 3.598 in | 6.2 in |

At the inherited width, S2's base text corresponds to approximately 8.58 points. Its existing secondary sample-count and rationale text correspond to approximately 5.36 and 5.63 points. These are small print elements and must remain a qualification for final Word/print review. The plot shapes are complete and larger than before, but their embedded axis text is still small at the intended physical width. This is a compact-display legibility limitation, not a shortage of source PNG pixels: the original PNGs are 1250 × 500 and now display at approximately 244.008 × 97.602 CSS pixels. No plot was redrawn or resampled.

## Screenshot interpretation

The original browser bytes are retained unchanged. Many earlier files have a `.png` suffix but contain JPEG bytes; `actual_screenshot_formats.csv` records their true MIME type, dimensions and hashes. This format clarification does not change any source or screenshot bytes.

The browser's clipped-screenshot operation returned a half-scaled table with outside content. Both failed probes are retained and explicitly rejected as table-only captures. Complete full-page/full-viewport images work and were used for review.

The optional R crop attempt was stopped by its strict mapping guard at S2 part 1. That complete JPEG is 2185 × 1241 pixels for a 2200 × 1250 CSS viewport. No assumed coordinate rescaling, interpolation or stitching was attempted. A first Table 2 crop had already passed exact decoded-pixel equality and is retained as partial secondary evidence, not an accepted production image. The coordinator confirmed that this optional capture issue must not delay full-page acceptance.

## Boundaries and teardown

Only this new candidate root was written. The live manuscript/SI, accepted scientific sources, earlier packages, Word files, integrated website, profiles, data, models and lockfile remain unchanged. No Quarto render, QMD execution, model work, office conversion, installation, commit, upload or website promotion occurred.

The 127.0.0.1 servers on ports 61111 and 61388 were stopped. Postflight records show no protected-input drift, and no listener remained on either port. Only task-created browser tabs 4 and 5 were closed. The viewport override was reset; user tabs were retained.

The production specification remains **19 native-table files/elements, 30 table-image parts, 24 figure appearances and 54 drawings**. Table 2 and S2 are the two changed native-table candidates. S7's native file and its first two image parts retain their existing reuse decisions. Final Word/native-table assembly and the complete website update require the coordinator's subsequent production disposition.

## Where to review

- Current source-table pages and exact identities: `attempt_02/maps/six_page_manifest.csv`.
- Complete screenshots with exact source/route/MIME/dimensions: `attempt_02/maps/source_to_full_screenshot_map.csv`.
- Actual viewport evidence: `attempt_02/final_visual_verification_03/viewport_cases.csv`.
- Actual recorded header widths: `attempt_02/final_visual_verification_03/recorded_rendered_header_widths.csv`.
- Physical size and text-size implications: `attempt_02/maps/physical_size_implications.csv`.
- Final content check: `attempt_02/static_verification_postqa_final/result.json`.
- Actual QA history and failed secondary evidence: `run_history.md` and the retained session directories.
- Unchanged author-facing passage comparison: `attempt_02/evidence/cumulative_passage_changes.md`.

The root package manifest is non-circular and excludes itself and its detached seal. Earlier attempts and failed secondary evidence are retained rather than rewritten as successful output.
