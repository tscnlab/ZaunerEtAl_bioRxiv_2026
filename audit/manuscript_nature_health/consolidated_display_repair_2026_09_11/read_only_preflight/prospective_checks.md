# Prospective implementation and acceptance checks

Date: 2026-09-11

These checks define the later candidate boundary. They do not authorize implementation.

## Provenance and execution

- Use R 4.6.1 with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` for every source-data or figure-export check that can affect scientific content.
- Pin SHA-256 and byte size for every source, comparator, script, accepted component, candidate asset, rendered artifact, and manuscript source before and after each phase.
- Read only frozen display rows for H07 and H09 exports. Do not read model objects, refit, predict, transform source data, or recalculate inferential quantities.
- Record the R session and consequential package versions for each owner export.
- Keep candidate roots separate from accepted and stopped artifacts.

## SVG structure and identity

- Every promoted SVG parses as XML and contains zero `<image>` elements, zero base64 raster payloads, and no unresolved references.
- S5 is one flat SVG with two prefixed graphical groups in the accepted left-right geometry. Uppercase A and B are positioned on the left side of their respective panels.
- Reverse S5 by extracting both groups, undoing the documented transforms, and comparing canonical structure and rendered geometry with the accepted BA-017 input panels.
- S7 panel A remains byte-identical to SHA-256 `4ddf972fc4c8082594d13a3b446537ae8a525ca35077e0605967f9c4c0ce519e`.
- H07 and H09 SVGs have layer-to-frozen-row manifests and rendered comparisons against the accepted PNG and PDF comparators.
- The S17 candidate diff, if attempted, contains only the approved font-family substitution and bottom canvas/viewBox extension. Every coordinate and scientific text token must remain unchanged. Applying the inverse mutation must reproduce SHA-256 `ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe`.
- Accepted-manifest target after S7 and S15 are split: 22 unique SVG sources and 23 Word drawing appearances.

## Quarto structure, captions, links, and alt text

- The candidate contains exactly 20 numbered figures, matching the accepted Order72h count.
- S7 contains exactly one `fig-s7` container, two independent image blocks, one shared caption, two distinct nonempty alt texts, and no wrapper composite.
- S15 contains exactly one `fig-s15` container, two independent image blocks, one shared caption, two distinct nonempty alt texts, and no wrapper composite.
- S5 contains exactly one flat SVG image block and one caption. It is not assembled from two Quarto image blocks.
- All prior inbound links resolve, and all figure/table numbering after S5, S7, and S15 is unchanged.
- Panel tags are capital letters and appear at the left edge throughout the complete candidate, unless a source has no panel subdivision.
- The approved instruction to drop unnecessary uses of “primary” is applied only to display prose and captions where “near-eye” is sufficient. It must not rename protected source paths, model terms, or historical identifiers.
- The Coordinator-sealed S5 sleep-period wording is used consistently in the caption, surrounding prose, and alt text.

## Supplementary Table S2

- The accepted source remains SHA-256 `6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97`.
- The capture includes all 14 columns, all 17 metric rows, all 17 distribution plots, every note, and the exact accepted row and column order.
- There is one horizontal column set. Any continuation is vertical and repeats the full 14-column header.
- Every cell bounding box is inside the capture viewport. Every distribution image uses contain-fit behavior, preserves its intrinsic aspect ratio, and lies entirely inside its cell.
- Embedded distribution image bytes match the source HTML payloads exactly.
- Reconstructing ordered text and image keys from all vertical parts yields the accepted semantic table with no duplicate or missing data row.
- The Word section is A3 landscape, approximately 16.535 by 11.693 inches, with verified picture extents no greater than the actual printable area. The anticipated working bound is approximately 15.60 by 10.10 inches, subject to package inspection.
- Let `n_s2_parts` be the accepted number of vertical S2 parts. The expected Word inline-shape count is `49 + n_s2_parts`. Do not hardcode the part count before the candidate geometry is accepted.

## Supplementary Tables S5, S6, and S10

- Before each screenshot, computed `font-family` for a title, column header, stub, body cell, and note begins with Arial.
- The capture rule applies to `#word-table-capture`, its table, th, td, and every descendant with `font-family: Arial, Helvetica, sans-serif !important`.
- Text, order, values, source HTML bytes, and table semantics remain unchanged.
- Separate editable DOCX table exports remain untouched.

## Protected displays and source state

- Table 3 remains byte-identical to the accepted gt fragment and retains the six approved groups and 17-metric Descriptives order.
- S12 remains byte-identical to SHA-256 `2b955196ce35eae1c973201a00523e538a6535ac59c8abe240160611a74c8b83`, with zero case-insensitive occurrences of MDER.
- H06_daily contributes zero image references, numbered displays, captions, manifest rows, media relationships, or Word drawings.
- The stopped Order72d DOCX remains SHA-256 `933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9`.
- The accepted Order72h QMD and HTML remain at their sealed hashes until a later promotion order.

## Browser, Word, and LibreOffice QA

- Browser: inspect the complete full-width candidate at standard and narrow viewports. Confirm no horizontal page overflow, clipped miniplots, missing panels, awkward overlay, or broken table containment.
- Native Word: inspect every changed figure, table, caption, page break, cross-reference, and drawing description. Confirm S5 renders, S7 and S15 are two stacked drawings each, S2 is readable, and S5/S6/S10 are Arial.
- LibreOffice: inspect S17 font and note containment, plus visibility of S5, S7, and S15. LibreOffice-only shortcomings do not invalidate a source that still passes the declared native Word target unless the Coordinator explicitly broadens the acceptance target.
- Extract the DOCX package and compare every embedded SVG SHA-256 with the accepted manifest. Verify drawing relationships, descriptions, order, and the prospective 23 SVG appearances.

## Teardown and seals

- Close any Word or LibreOffice document opened for QA without saving the accepted or stopped artifacts.
- Stop any browser server or office process started by the implementation order.
- Remove only explicitly created scratch directories after their hashes and evidence are sealed.
- Produce owner manifests first, then an independent central manifest that excludes itself. The acceptance report records the manifest hash externally so there is no circular seal.
