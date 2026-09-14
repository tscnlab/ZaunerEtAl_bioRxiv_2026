# REPORT-018 sealed Order 71b1: accepted Word capture refresh

Date: 2026-09-03

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_DISPATCH`

## Reason and serial boundary

Order 71b preflight correctly stopped before its artifact marker, DOCX render,
postprocessing pass, or any canonical write. The existing Word Table 3 PNGs
predate the accepted Table 3 replacement and therefore cannot be used as
evidence for the accepted 17-metric order. No current accepted replacement
capture manifest exists.

This continuation authorizes one preparatory capture invocation only. It does
not change the one-DOCX-render, one-postprocessing-pass, and one-page-render
limits in Order 71b. Order 71c remains held.

## Exact inputs

- Accepted self-contained HTML:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`,
  SHA-256
  `438f80545e09eb1844d15c3d4495d7d2d4dbc07bcf039f4c8e4430b18e79ee0c`,
  30,877,834 bytes.
- Frozen capture implementation:
  `scripts/manuscript_nature_health/capture_word_tables.mjs`, SHA-256
  `9a38f12b93bd03f3332de2f3c862bedbd035659bd762b386b98166800a04af07`,
  14,753 bytes.
- Accepted Table 3 fragment: SHA-256
  `d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2`.
- Accepted Supplementary Figure S6 SVG: SHA-256
  `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`.
- Accepted Supplementary Figure S5 SVG: SHA-256
  `61e8d4671939659ecf5eca6c6688c03414bb849d15b9d3f59f39c96ca7069cfd`.
- Accepted Supplementary Figure S12 PNG without an MDER legend: SHA-256
  `88aeef89cda1208a80ead843ca9551011350ed5f78734c57ceee380bf994f02e`.

## Authorized capture

1. Reconfirm every exact input identity and preserve the historical Word
   capture directory byte-for-byte.
2. Create a fresh task-owned directory under
   `audit/manuscript_nature_health/order71b_execution_2026_09_03/word_capture/`.
3. Invoke the frozen capture script exactly once with the accepted HTML as its
   only rendered-page source and the fresh directory as its output. Use the
   bundled Node runtime and Playwright dependency. This is a browser capture,
   not a Quarto or DOCX render.
4. A loopback HTTP server may serve only the accepted HTML output after a
   zero-symlink preflight. If used, record its exact command, bind it only to
   loopback, and tear it down immediately after capture. Do not serve the
   repository root.
5. Because the frozen script also captures the Word figure fallbacks, require
   exactly 19 table selector entries and exactly 17 figure entries. Require
   every expected part, non-zero files, decodable PNGs, and the expected image
   dimensions. The figure manifest must point Supplementary Figure S6 directly
   to the exact accepted SVG above, Supplementary Figure S5 to its accepted
   SVG, and Supplementary Figure S12 to the accepted no-MDER-legend PNG.
6. Inspect all new Table 3 parts and prove that they show all 17 metrics in the
   exact descriptive-table order accepted in Order 71a. Require no clipped,
   blank, duplicated, missing, or stale row and no broken density thumbnail.
7. Record a complete manifest with SHA-256 and byte count for every new PNG and
   both JSON manifests. Seal it before continuing.
8. If any input, selector, count, decode, dimension, content, or visual gate
   fails, stop without running the DOCX artifact marker or any DOCX command.
   Do not patch or rerun the capture in this continuation.

After every capture gate passes, resume the already dispatched Order 71b from
its initial preflight. Use only the sealed fresh capture manifests as the
table and figure inputs to the single DOCX postprocessing pass.

Do not modify the QMD, accepted HTML, canonical DOCX, website, scientific
artifacts, old capture directory, package state, or lockfiles in this capture
continuation. Do not commit, push, upload, submit, or delete evidence.
