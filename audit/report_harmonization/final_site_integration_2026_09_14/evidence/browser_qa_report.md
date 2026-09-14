# Order011 candidate browser verification

14 September 2026. Candidate only. No live promotion.

## Scope and evidence

The supported Codex in-app browser inspected the candidate through a temporary GET/HEAD-only server bound to `127.0.0.1:51424`. Its root was only `candidate_build`; the symlink preflight found no symlinks. No alternate browser, raw CDP, file URL, upload, Office conversion or Quarto render was used.

`browser_capture_identities.tsv` records 267 timestamped tool-capture identities. Images were emitted in the task's tool conversation, not saved as standalone PNG files. The ledger distinguishes 261 ordinary capture records, one invalid stale-paint record, and five limited records. These are evidence records, not 267 independent acceptance tests. Date, route, viewport width, label and byte length identify the corresponding tool images. The viewport height was 1300 CSS pixels. `index`, `SI`, `P01` and `H06` designate `index.html`, `supplementary_information.html`, `notebooks/preparation/01_import_state_alignment.html` and `notebooks/hypotheses/H06.html` under that origin.

`browser_measurements.json` preserves the six complete entry-page DOM summaries, non-table prose bounds, exact narrow-layout equivalence checks, typography observations, interactions and cleanup evidence. JavaScript inspected layout and UI state only. The reported scientific content was reconciled separately in R 4.6.1.

## Observed layouts

| Requested viewport | Usable page width | Index usual SVG width | Supplement usual SVG width |
|---|---:|---:|---:|
| 1440 × 1300 | 1425 px | 849 px | 799 px |
| 708 × 1300 | 693 px | 642 px | 642 px |
| 390 × 1300 | 375 px | 324 px | 324 px |

The narrower geographic-range figure retains its accepted desktop width proportion. Both routes retain their own website shells. Desktop width differences between the two routes therefore remain intentional: thirteen supplementary tables are 1039 px in the index shell and 1014 px in the supplementary shell. Only S12 and S14 differ in table height, by 14 px; the other compared table heights agree. At 708 and 390 px, all sixteen supplementary tables have identical measured width, height and sampled text size between routes, and all twenty supplementary SVG image elements have identical dimensions.

Every entry-page inventory showed all SVG images loaded: 23 in index and 20 in the separate supplement. All nineteen index tables and sixteen supplementary tables had positive-height rows. All 317 non-table manuscript prose/heading/reference blocks and all 48 corresponding supplement blocks fitted the page horizontally at all three widths. Footer and page-navigation elements remained present. Wide tables scroll locally, without widening the whole page.

The table and figure review covered the complete main display sequence, all seventeen supplementary figure groups, their captions, and all sixteen supplementary tables. Long displays used overlapping upper, middle and lower views. The complete supplementary content was visually reviewed in the dedicated supplement at each width; the index supplement was additionally reviewed at desktop. At the two narrow widths, its exact content and measured layout equality bind the same component checks to the index route, rather than claiming a second independent screenshot reading of every duplicate cell.

Table 3 retains its accepted metric order, compact row structure, bold metric names, FDR wording, percentage R² summaries and distribution images. S2's rightmost distributions were checked through overlapping vertical views at all three widths. The table remains 2088.0078125 px wide. An explicit computed-style check found 16 px body cells, 10 px count text and 10.5 px metric-definition text. These match the frozen accepted display. An earlier generic table sample found the 20 px title; that value is not a body-font measurement. The R reconciliation confirms all seventeen S2 distribution payloads and all 170 complete mean/SD runs without recomputation.

Dense SVG labels naturally become small when the entire figure fits a phone-width viewport. Their vector payloads and accepted crop styles were preserved, not rasterized or regenerated. Existing accepted details, including the S8 whitespace and S5's two separately embedded SVGs, were not redesigned under this integration order.

## Utilities and interactions

- All 22 download labels and local targets were inspected: the complete manuscript, nineteen editable tables, and the unchanged passage-change CSV and Markdown. A separate loopback GET/HEAD check verified status 200 and exact accepted response bytes for all 22 files. No browser download-folder writes were needed.
- The revision utility shows all twenty ordered position/old/new rows, with source text escaped rather than executed. All twenty were reviewed in overlapping desktop captures. Narrow views retain horizontal scrolling, and keyboard Right moved the revision wrapper from 0 to 40 px. S2 keyboard Right likewise moved its scroll position from 0 to 40 px.
- Nested table scroll areas were exercised, including S3's inner and outer wrappers, S7's outer wrapper, and Table 1's rightmost site columns. A repeated phone-width Table 1 capture documents the final rightmost view after an earlier tool-output failure.
- The desktop Study & data menu opened and its Preparation 01 link navigated correctly. The phone navbar opened and closed. At 708 px, the collapsed supplementary contents control opened and its Daily architecture link reached the expected fragment.
- Searching for `recommendation adherence` returned the manuscript and supplement, with current section matches. Enter navigated to `index.html#recommendation-adherence`, and the overlay closed. Static checks independently verify all 942 unique search records, their fragments and the exact 37-route closure. Revision old-text cells and utility text are excluded from scientific search.
- Preparation 01 and the main hourly H06 report were smoke-tested at 1440 and 390 px. Their initial prose, responsive navigation and subsequent content displayed. This was not a new full review or render of the other 35 unchanged reports.
- The final requested browser error/warning log queries returned empty lists. This does not establish offline availability or negate the four inherited missing Datatype font references retained by the static gate.

## Capture limitations

1. Capture 3 used an immediate Playwright screenshot that retained the preceding paint. It is invalid for F3 and was superseded by native observations and later F3 captures. Early full-viewport captures before this timestamped ledger, including initial setup views, are not presented as saved screenshot files.
2. Capture 121 scrolled outside a short table and did not move it. Captures 124 and 125 supersede that attempted S9 pan.
3. Capture 187 used a pointer below Table 3 and repeated the prior horizontal position. Capture 188 supplies the corrected left-tail view.
4. Capture 200 recorded metadata, but a later selector timeout in the same tool call discarded image output. Capture 252 repeats and confirms the same rightmost Table 1 view.
5. Capture 241 moved the desktop TOC rather than the page. It repeats the already complete S5/S6 view in capture 240.
6. Capture 265's image output was discarded by a subsequent selector timeout. The destination URL, target position and closed search overlay were separately returned as DOM evidence. Capture 264 is the actual search-results image.

Some labels describe the intended display rather than every item appearing in the viewport. The associated screenshots, not those labels alone, establish visible coverage. Several lower views include a caption or the next display. Some original hash targets place the top heading close to the sticky header; the document remains vertically scrollable. No pixel-perfect cross-browser, print-layout, accessibility-certification or offline-site claim is made.

## Cleanup

The viewport reset method completed. The immediately observed tab dimensions still read 390 × 1300 before closure, so no instantaneous physical resize is asserted. Only task-created tab 2 was closed, and the subsequent browser tab inventory was empty.

Server PID 19328 stopped normally at `2026-09-14T12:51:31.001117+00:00`, with exec exit code 0. A normal approved read-only `/usr/sbin/lsof -nP -iTCP:51424 -sTCP:LISTEN` check returned exit code 1 and no output, confirming no listener on that port. The earlier first-pass listener was already stopped before the correction-pass server started. Final protected-file and candidate hashes were checked after cleanup.

Result: candidate browser QA passes within the accepted static-integration scope, with the evidence limitations above. The four historical font-reference misses and historical source-provenance gaps remain explicitly inherited. Central acceptance of these exact postimages is still required before any live update.
