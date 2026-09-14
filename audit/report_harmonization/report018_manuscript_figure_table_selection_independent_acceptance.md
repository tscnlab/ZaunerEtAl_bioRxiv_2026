# REPORT-018 Nature Health figure and table selection independent acceptance

Date: 2026-08-31

Status: `ACCEPTED`

## Final disposition

The bounded local-table containment repair closes the visual-only stop recorded in `report018_manuscript_figure_table_selection_independent_review.md`. The current selection source, generated assets, target HTML, scientific selection boundaries, structural checks, responsive layout, and accessible local table scrolling independently pass.

No planning-package file, hypothesis source, scientific artifact, accepted reader report, model, manuscript source, or production figure was changed by this independent acceptance.

## Accepted current identities

- `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`: SHA-256 `61b476682f021cd1220a6ac2f8f39b4f57199cc0de69953ccbb1666a61809949`, 48,688 bytes.
- `audit/manuscript_nature_health/manuscript_figure_table_selection.html`: SHA-256 `1d1fac68e29fa2cfef140b1d322c4fa2d6ffe0ead977213af31f7a6c60cdb366`, 27,418,080 bytes.
- `scripts/report_harmonization/build_manuscript_figure_table_selection.R`: unchanged SHA-256 `52fcf891e153c45587e247c658f906b6e586a9082db4ecde6a8363ebb256e40f`, 64,834 bytes.
- `scripts/report_harmonization/check_manuscript_figure_table_selection.R`: SHA-256 `54bc8f4a144623f18be2e10b7bd9dcd222a7238cedc1958e94cd1f2819343710`, 16,120 bytes.
- Current 33-check record: SHA-256 `25326382f9c1b1fb14cd4b69918acd2b5620b79a04473cb05f4b6073a553ec22`, 2,506 bytes.
- Current 31-row asset manifest remains unchanged at SHA-256 `a6cb974b2393f55827fd98b7c153bedefb592fed9fb179f815540674b71a8647`.

## Independent structural replay

The complete current checker was run under R 4.6.1 in `/private/tmp/nathealth-selection-acceptance.ttq1WE`, against a byte-exact copy of the planning package and read-only links to its accepted source and reader inputs. It passed 33 of 33 checks: 26 tables, 19 native `gt` tables, 40 embedded images, 3,909 resolved header tokens, exact 13-row Supplementary Table S2 support, unique document IDs, resolving links, and exactly three accessible local table regions. The generated check record was byte-identical to the held check record.

## Responsive visual acceptance

- At 1440 by 1000 pixels, the document client and scroll widths were both 1,425 pixels. The fixed right table of contents, main order, tables, figures, captions, and coordination notes were complete.
- At 708 by 1000 pixels, the document client and scroll widths were both 693 pixels.
- At 390 by 844 pixels, the document client and scroll widths were both 375 pixels.
- All three widths therefore had zero document-level horizontal overflow.
- All 40 images loaded at every inspected width.
- The browser console contained no warning or error.

Exactly three `.local-table-scroll` regions are present: Proposed manuscript display order, Recommendation adherence by recommendation window and day type, and Person-level evidence synthesis. Each region has `role="region"`, a specific accessible name, `tabindex="0"`, `overflow-x: auto`, and exactly one direct table. Pointer scrolling moved each region horizontally while the document remained at `scrollX = 0`. The focused regions showed a visible focus outline and a local horizontal scrollbar.

## Scientific boundary retained

The accepted content findings from the prior independent review remain controlling:

- Supplementary Table S2 uses exactly 13 pre-existing accepted scalar counts and introduces no derived sample value.
- The H01 MDER descriptive distribution uses the accepted mean of viable minute-level ratios, while its eight H01 model cells remain explicitly pending because the accepted model used the superseded ratio-of-integrals definition.
- Brown cross-window findings remain separate from main Table 2, retain one four-test FDR set, withhold within-participant claims, and qualify the between-participant results.
- The seven-item main display order remains exact.

This planning package is accepted for author selection and coordination use. It is not itself scientific authority, does not authorize manuscript implementation, and does not release any Brown, H03, H04, H06_daily, H09, H10, H01, manuscript, or reader-report edit or render. Those actions remain separately owner-gated.

## Historical evidence

The prior visual-only stop and its 16-row seal remain immutable historical evidence. The root 37-row package manifest and two earlier prose QA records also remain classified as historical package snapshots. The current central acceptance record and its non-circular seal are the authoritative acceptance evidence for the repaired package.

## Loopback teardown

The exact accepted HTML was served as the sole file from `127.0.0.1:54451`. The QA tab was closed, the viewport override was reset, the server was stopped, and `lsof` found no listener on the port. Post-QA rehashes reproduced every accepted current identity.
