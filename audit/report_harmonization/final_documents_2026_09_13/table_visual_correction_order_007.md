# Consolidated table layout corrections and actual localhost review

14 September 2026. Owner: Writer, task 019ffb39-372e-7262-bfac-192751fd0e63.
Status: RELEASED_FOR_CANDIDATE_LAYOUT_CORRECTION_AND_LOCALHOST_VISUAL_QA.
Author instruction: "Then coordinate the corrections."

## Purpose and supersession

Correct the actual browser findings TABLE-VIS-001 through TABLE-VIS-003 as one coherent implementation. Preserve the accepted single primary-sample Table 2, whose desktop and contained narrow-screen presentation passed the coordinator's inspection. Do not reopen Brown scientific review or create another proposal-only step.

The coordinator successfully inspected all six actual attempt_04 pages using the selected in-app browser at http://127.0.0.1:59715. Browser access was permitted through the normal route. No security setting was changed, no rejection was bypassed, and no alternative browser was used. The server is stopped and its postflight proves unchanged inputs. Durable findings and pre/post evidence accompany this order under table_visual_inspection_007/.

For these revised table pages, this order supersedes the earlier source-only restriction in Order 005 and the visual-pending limitation of acceptance 006. Actual localhost inspection and candidate screenshot evidence are now explicitly authorized. The old file-URL rejection remains historical evidence, not a blanket blocker. A fresh specific denial must still be respected without changing browser surfaces or devising a workaround.

## Immutable baseline

Baseline root: audit/manuscript_nature_health/table_layout_revision_2026_09_13/.
Use attempt_04 only; all earlier attempts remain historical.

- package_manifest.csv: 7be9e008ac1e16399ba9f92c5b5634cf5c0cee33143bdb2723b45e32be8a0232, 176 unique non-circular members, freshly rehashed 176/176 before this release.
- package_manifest.sha256: 251907db356c443202368877b0470116f1f60b5a1e1c12072d1dbcb76148b2cb.
- Main candidate QMD: c3569b3c18632abb50249ea8fa8de6d80651c8f98838b385a82c1960f9ec7555.
- SI candidate QMD: 292830fb62ad0a77e0b9e41dcc12b89de084607452ca7863e176127799981907.
- Table 2 fragment: 6951fdf95260c8f4c51a77e906f290b80aa9bc090124fc0adeef4769c2ed7991.
- Accepted source/static disposition: single_table2_source_acceptance_006.md, 1550f32de4d3879d9268798b5f9d66703bb125bdf3da2e65a6289571d6cbf026.

Preserve this entire baseline root byte-for-byte, including its manifest and completion record. Do not append evidence into that sealed root.

## Write boundary

Create one new task-owned root:

`audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/`

Only this new root may receive candidate HTML/CSS fragments, wrapper pages, copied source/maps, narrow layout utilities, verification output, screenshots/candidate captures, source-to-capture mapping, logs, final evidence, and a non-circular manifest. Temporary read-only QA infrastructure and immutable copies may use /private/tmp. Do not edit coordinator records.

Keep the live manuscript/SI sources, accepted reports, all scientific/display source artifacts, prior packages, old screenshots, Word outputs, _build/nathealth, project profiles, lockfile and other workers' files unchanged. No commit, push, upload, installation or package change.

## Exact correction scope

### TABLE-VIS-001: contain S2 page overflow

At 708 pixels, S2 part 3 exposes a 1,985-pixel document width. Scrolling outside the table moved the whole window to scrollX=708 and a blank screen, while the actual table scroller remained at zero. Visually hidden absolute description spans extended beyond the container and are the leading diagnosis to verify.

Repair only the relevant positioning/containment styles in the candidate. Keep all accessible description text and associations; do not remove alt text, hide meaningful content, or suppress all overflow to conceal a clipped table. The page must stay within its viewport while the table region independently scrolls to both ends. Check all three S2 parts, including outside-region scrolling and keyboard access to the table region.

### TABLE-VIS-002: use one S2 column grid and deliberate wrapping

Measured S2 table widths varied between about 1,945 and 1,968 pixels, and the Unit column varied between about 48 and 85 pixels. Build one content-aware unequal-width column specification using the longest content across all three parts, and apply it consistently. Verify computed rendered column widths, not just a shared CSS declaration. Allow only normal subpixel rounding.

Reallocate width/padding so unit labels, numeric summaries and the Scaling column have adequate space. Avoid the five-line Symlog label with an isolated '1)' line. Deliberate semantic line breaks are permitted without changing the text or meaning. Preserve the 16px S2 source base and all 170 complete mean-plus/minus-SD units. Do not introduce a global font reduction, ellipses, cropping or hidden cell content.

Keep all 14 columns, existing row partitions, group labels, country labels, non-colour cues and complete final notes. Preserve all 17 embedded S2 PNG payloads byte-for-byte and their aspect ratios. The current distribution plots display at only 177 x 70.8 pixels; assess a larger distribution-column allocation within the coherent layout and inspect complete plots at the documented intended size. Do not redraw or regenerate plots. If intrinsic source-image resolution remains a real legibility limit, report it precisely instead of claiming that dimensions prove readability.

### TABLE-VIS-003: S7 header and sample-label flow

Both S7 tail parts have a 'Photoperiod FDR-adjusted p' header whose measured scrollWidth is 73 pixels in a 65-pixel cell. Widen/rebalance the affected header and other narrow p-value columns as necessary. Use the same resulting column specification in parts 3 and 4. No character-level breaks, overflow, overlap or clipped header is acceptable.

Reflow the exact fitted sample into two deliberate, readable lines: participant count and participant-day count. Keep each label and its associated value together; avoid breaking after 'participant-'. Preserve all numbers, subscript semantics, punctuation meaning and row identity. Retain the 12px S7 source base, all rows, complete final-part notes and unchanged reuse of S7 parts 1 and 2.

### TABLE-VIS-004: preserve main Table 2

Reuse the accepted Table 2 fragment byte-identically. Keep one primary any-valid table, three rows, seven columns, separate descriptive/model spanners, all current estimates and intervals, and the existing notes. Do not recreate Table 2A/2B or add sensitivity rows. Generic wrapper/scroller/evidence wording may change consistently across the six pages, provided Table 2 itself does not regress. Do not shrink it to fit an arbitrary viewport.

## Source and scientific preservation

This is display-only. Use R 4.6.1 and the accepted library for any numerical/content reconciliation. No model loading, fitting, prediction, contrast computation, p-value/FDR recalculation, resampling or scientific regeneration.

Carry forward the complete baseline content/source checks. Reconcile all 407 page cells by semantic row/column identity, allowing only whitespace/line-break markup changes needed by this order. Preserve every estimate, interval, p-value, decision, unit, label, note, image payload and source identity. Keep valid semantic headers and ID references, with zero duplicate IDs per page.

Copy the accepted main and SI candidate QMDs unchanged where possible. Only literal include/resource path relocation needed to point candidate copies/maps to the new matching layout files is allowed; no narrative or scientific change. Record any such path-only change exactly. Preserve the cumulative 20-position editorial record, unaffected reuse choices, row partitions, one-main-Table-2 status and the 19-native-table/30-table-image-part/24-figure-appearance/54-drawing specification.

Update candidate-only source maps and manifests to point to the actual revised fragments rather than unmodified originals. Never reseal a historical manifest to conceal a changed identity.

## Implementation and visual checks in the same owner pass

Candidate-only HTML/CSS iterations are authorized until these known layout findings are corrected. Retain meaningful failed evidence, but do not stop for new permission after each harmless width or wrapping adjustment. Run a full final source/static suite on the selected candidate. A genuinely new scientific discrepancy, unexpected protected-file change or explicit tool denial remains a stop condition.

Use the quarto-authoring bounded local visual procedure. No Quarto render or QMD execution is needed for these static HTML layout changes. Serve only the six candidate HTML pages and required candidate assets through one GET/HEAD server bound strictly to 127.0.0.1. Perform mandatory symlink preflight; never serve the repository, data, credentials or a broader directory. Use the selected internal browser and normal permission flow. Do not switch surfaces after a rejection.

Inspect all six pages at 1440 x 1000 and 708 x 1000, both ends of every wide table, all rows and final notes. Distinguish intentional contained table scrolling from document-level overflow. Verify header/cell clipping, wrapping, collisions, consistent column geometry, accessible descriptions, complete images, working scrollers and console errors. Capture actual screenshots when supported, with source/hash/route/viewport metadata. Do not label DOM checks as screenshots or source checks as visual acceptance.

Also record actual table rectangles and physical-size implications using the existing production map: Table 2 and S7 width 10.55 inches, maximum height 6.2 inches; S2 width 15.55 inches, maximum height 9.2 inches. These are the inherited production dimensions, not an authorization to squeeze them into an arbitrary 170mm width. Check intended-size legibility and record effective text sizes. Candidate table-only source-matched captures are allowed through the supported browser mechanism; they must include the whole table and its applicable notes, not just one visible slice of a horizontal scroller. Do not claim final Word/print acceptance without the corresponding final-output inspection.

Stop the server after QA, prove no listener, close only task-created tabs, reset viewport overrides, and rehash sources and candidate outputs. Preserve actual QA history and report what was really performed. Wrapper warnings such as 'No automated inspection has occurred' should not be presented as current status after this review; maintain truthful candidate versus completed evidence wording without mutating old pages.

## Return and remaining production boundary

Return one consolidated implementation, full content/preservation checks, visual findings closure table, viewport evidence, exact dimensions, remaining intrinsic-image/print limitations if any, source-to-capture map when captures were supported, and a unique non-circular final manifest inside the new root. Notify the coordinator that the package is ready for independent acceptance.

The coordinator will independently review the revised actual pages. This order does not release live manuscript replacement, final Word/native-table assembly, office conversion, website promotion or any broad render. Those remain the subsequent production step, not another Brown scientific approval or a reason to leave these authorized layout repairs unimplemented.
