# REPORT-018 H06 order 47d response-PNG delta classification

Date: 2026-08-21

Disposition: `ACCEPT_EXPECTED_TARGET_OWNED_DETERMINISTIC_REGENERATION`

## Classified path

`_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation_files/figure-html/fig-h06-prep-response-distribution-1.png`

- Sealed pre-render SHA-256: `5cf25ad6cef9840e78a217ab083ca816105eacb37568ac788d3cd82c4bc31f46`
- Sealed pre-render bytes: 105,897
- Current SHA-256: `ab51417026d3b3edd9c0af7a455961b9e018cd0d4396bc6ba2f615ac98e7f7a1`
- Current bytes: 105,561
- Pre-render and current dimensions: 1920 by 1113 pixels

The historical PNG was not retained as a separate file, so a historical pixel-level comparison is unavailable. Its identity, byte count, and geometry remain durably recorded in the order-47d owner evidence.

## Independent R reproduction

The central checker is `scripts/report_harmonization/check_h06_order47d_response_png_delta.R`, SHA-256 `bae2fe34025a8ec623fceba6d3cdab0bb821db9bfeddc2cdc2bb88a788ae80d6`, 7,162 bytes.

Under R 4.6.1 it:

1. verified the accepted companion source at `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`;
2. verified the frozen two-row source CSV at `d8ef3376d9bf72cbdd3a1d6519c4f567e23911c803dd738b528376413005afd4`;
3. extracted and parsed the exact accepted `fig-h06-prep-response-distribution` chunk from the companion QMD;
4. confirmed that the chunk contains the complete placement, percentile, median, P99, and exact-zero mappings and contains no random, fit, prediction, inferential, write, source, or system call;
5. evaluated that exact chunk from the frozen CSV and accepted placement colours into a fresh temporary PNG using the accepted 10-inch by 5.8-inch, 192-dpi device contract;
6. reproduced the current build PNG byte-for-byte at `ab51417026d3b3edd9c0af7a455961b9e018cd0d4396bc6ba2f615ac98e7f7a1`, 105,561 bytes and 1920 by 1113 pixels;
7. verified that the Quarto freeze PNG is byte-identical to the current build PNG; and
8. verified that the other two target-generated companion PNGs retain their sealed pre-render SHA-256 and byte identities.

Direct independent original-size inspection confirms both placements, the P10 to P90 and P25 to P75 intervals, median and open P99 markers, exact-zero shares, titles, subtitles, axes, colours, symbols, and labels are present, legible, and unclipped. The plotted zero shares agree with the frozen source rows: 4,697 of 16,596 near-eye hours and 5,337 of 18,352 chest hours.

The owner stopped-state manifest is exact for 64 of 64 unique, non-circular paths. The accepted result, companion source, source CSV, result page, H06 contract, profile, semantic tools, package lock, and H06 daily files remain unchanged.

## Classification and continuation boundary

The PNG transition is expected target-owned deterministic regeneration during the sole authorized companion render. It is not scientific-artifact drift, a source defect, or a page defect.

The current PNG may be accepted as the live companion build asset and as the current 411-row preparation-manifest identity. The historical readability-QA record and its old PNG hash remain byte-identical historical evidence and must not be rewritten or promoted. Final QA must inspect the current PNG directly at the controlling 170-mm display size and retain the existing content, clipping, and at-least-7-point typography gates.

The no-rerender continuation authorized in `report018_h06_order47d_test_stop_no_rerender_concurrence.md` may classify exactly this one PNG transition as an accepted build delta. It must still preserve every source, CSV, scientific artifact, test, helper, manifest, profile, result, and unrelated build member and must complete the specified browser, final-size, teardown, and post-QA checks.

No source edit, artifact promotion, test edit or rerun, helper rerun, Quarto rerender, scientific computation, H06 daily render, later render, commit, push, or upload is authorized.

There is no blocking requirement. H06 daily and later renders remain held until independent H06 companion acceptance.
