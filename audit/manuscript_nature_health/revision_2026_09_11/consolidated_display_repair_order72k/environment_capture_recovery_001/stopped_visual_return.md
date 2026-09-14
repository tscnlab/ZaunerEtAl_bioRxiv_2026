# S2 recovery visual stop

Date: 2026-09-11. Status: STOPPED_VISUAL, no candidate acceptance or promotion.
Gate: REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW.
Controlling recovery order: 3399f0aa937333f8ac512b016b742004f6779f82dc6cb13484017e7d9f1cf4e8.

## Execution outcome

The exact final S2-only command received tool permission and exited 0.
The unchanged helper produced three PNG parts. No additional capture,
browser substitution, runtime modification or retry occurred. The exact
command, permission outcome, HTTP 200 response and tool sessions are in
`execution_receipt.json`. Chrome's PID was not exposed by its successful
output and has not been inferred.

This consumed the final S2 vertical-adjustment allowance. The output manifest
is `../capture_s2_attempt3/word_table_png_manifest.json`, SHA-256
`b1f42b304201c317e5a87ab0867d3bce4b28f8129ea70c3b982e0fe46909eff1`.
It identifies a visually failed candidate and is not an accepted assembly
manifest.

## Visual failure and exact files

All three PNGs were inspected. Numerical content now wraps and all site
columns and distribution images are visible. However, the narrow Unit and
Scaling columns clip text at their right edge. This fails the no-clipping
requirement even though the underlying text remains exact.

Paths below are relative to the project root:

| PNG | Clearest visible issue | SHA-256 |
| --- | --- | --- |
| `audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/capture_s2_attempt3/supp_table_s2_part_01.png` | `HH:MM` loses part of its last glyph in duration rows. `threshold` is displayed as `threshol` in the Scaling column. | `18ea89fd3a050713fae09a3f90f659360fee280b2d4a42dcff818169437be108` |
| `audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/capture_s2_attempt3/supp_table_s2_part_02.png` | `threshold` is cut at the right edge in the dose and level rows. | `adf493216d689d9ecc69bab6eb28711379ceaf9fc74c2852dbd48c0c71684fe3` |
| `audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/capture_s2_attempt3/supp_table_s2_part_03.png` | The Unit cell's `HH:MM` first line is clipped above `clock`. | `6c3d8c2532ba5b535d2b53ff2bd5a6c0b1d249b05fe55b0bc2f44ea0895fca07` |

The original images are 2800 by 1738, 2800 by 1452 and 2800 by 1480 pixels.
The image viewer downscaled their tool previews, but the clipped labels are
already visible there. Intended Word-size inspection was not performed after
this failure, and no Word acceptance is claimed.

The frozen helper is `../helpers/capture_word_tables.mjs`, SHA-256
`8dd21ba1d978e36d1cafa0669b7c2456306b66e996f013f44b86ebc2549e0174`.
Line 178 sets the complete width list:

```text
fixedWidths: [200, 40, 105, 86, 86, 86, 86, 86, 86, 86, 86, 86, 50, 231]
```

Unit is column 2 at 40 CSS pixels; Scaling is column 13 at 50 CSS pixels.
The wrapping selector at line 368 and numerical text-rectangle selector at
line 437 cover only columns 3 through 12. They therefore did not test these
two labels. The source `.gt_row` rule also has `overflow-x: hidden` and
5-pixel left/right padding. No width or check was modified after the stop.

Disposition needed: the two fixed widths and containment checks covering
their text, with a separately explicit capture allowance. This is a proposed
layout repair, not authority to execute one. No scientific data, source cell,
distribution payload or figure needs to change.

## Preservation and reconciliation

Preflight and post-capture R 4.6.1 checks reproduced all 854 recovery,
stopped-package and original-authority rows. All 19 completed initial capture
files and all 12 served source/copy pairs remained exact. The protected
helper, initial HTMLs, old receipts, old trial ledger and old 263-member
stopped manifest remain unchanged.

The new S2 output retains 14 columns, 17 metric rows, six group rows, all 244
body cells, three complete repeated headers, the notes on the final part and
17 byte-exact distribution-image payloads. Each captured body cell equals
the immutable rendered source character-for-character. The original
unrendered fragment and final captures differ only in HTML whitespace.

The first post-capture checker compared the unrendered fragment's indentation
and blank lines literally against serialized browser HTML and reported three
false mismatches. Its failed record remains in
`capture_structure_and_visual_checks.csv`. The explicit supplemental
`reconcile_capture.R` adds a strict character-exact comparison against the
frozen rendered-source extraction and a separately documented whitespace-only
comparison against the original fragment. All six follow-up checks pass;
`all_cell_text_comparison.csv` retains every raw string. No content test or
visual failure was waived. No render/capture was run to fix this checker.

The helper's numerical text-rectangle checks passed for columns 3 through 12.
That limited pass must not be represented as all-column visual containment.

## Remaining work and unchanged holds

No S2 trial remains under the current order. S5/S6/S10 recapture is unnecessary;
their four passed initial PNG parts remain byte-exact and reusable. All other
table captures and every scientific SVG remain protected.

The single consolidated correction pass is entirely unused: one selection
HTML, one main HTML and one main DOCX. Word assembly/SVG embedding and office
QA are each 0 of 2 consumed. These steps were conditional on S2 passing and
were not started. The three accepted Lua dependencies remain copied and ready.
No Order72k DOCX exists. The initial HTMLs remain the fullest available preview.

The Mac-unlock reply is still outstanding. No native-app or automatic-unlock
operation was attempted during this recovery. Native Word acceptance remains
unavailable, independently of this layout failure. Brown science, historical
Figure S5, the optional H11 compatibility candidate and canonical promotion
remain held. No manuscript-language change was made.

## Teardown and lease release

The restart-only server used PID 38247 and 127.0.0.1:58005. Its receipt records
start at 19:47:44 UTC and closure at 19:52:17 UTC. After checking its exact
command, Writer sent SIGINT to that task-owned PID only. The final listener
check returned no port 58005 listener; the PID was absent. A narrowly scoped
process check found no browser using the task's temporary Playwright profile.

The helper closed its capture browser normally. No CUA tab or native Word
document was created during this recovery. No unrelated process was touched.
Served bytes and prior captures were rehashed after shutdown.

Writer explicitly releases ORDER72K-VISUAL-LEASE-002 with this STOPPED_VISUAL
return and remains stopped pending separate coordinator disposition.
