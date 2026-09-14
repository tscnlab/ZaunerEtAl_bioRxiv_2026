# Order 007: screenshot-crop clarification

14 September 2026. Owner: Writer, task 019ffb39-372e-7262-bfac-192751fd0e63.
Status: RELEASED, bounded continuation of Order 007.

The writer requested R-only postprocessing of already permitted full browser screenshots because the supported clipping API returned a half-scaled table with outside-page content. Independent inspection of the retained full and clipped Table 2 images confirms that defect. File-signature inspection confirms that the returned bytes are JPEG, including the failed clip saved with a .png extension. This is not a browser access rejection and does not justify or require a different browser surface.

The full Table 2 screenshot is 2,200 x 1,250 pixels at SHA-256 9a1b0b80609efb8974875693fc5744d95e2b3d5ad9e5ad47d71636a4c5aa2b7d. Its accompanying before/after DOM record identifies the complete table at x=21, y=166.5, width=1320.0234375, height=586.546875, with all three note blocks inside it. The outward-rounded requested rectangle is x=21, y=166, width=1321, height=588. The complete table is visibly present in the full screenshot; the failed clipped output is not a valid table-only capture.

## Authorized operation

Within the existing Order 007 candidate root only, use R and installed libraries to decode each complete, unchanged browser-returned screenshot, select its verified table pixel rectangle, and write a new table-only PNG. This is screenshot postprocessing, not a scientific image rebuild or alternate browser capture.

Requirements:

1. Retain the original screenshot bytes, failed clipping probes and original metadata unchanged. Record actual MIME/signature and dimensions. Do not silently treat JPEG bytes as PNG or rewrite failed evidence as successful.
2. Bind each crop to the exact source HTML/fragment, URL, viewport, before/after DOM rectangle, scroll offsets and original screenshot hash. Verify the screenshot-to-DOM pixel scale before choosing coordinates. A 1:1 crop requires matching actual screenshot pixel dimensions and viewport dimensions, with stable layout and no transform or zoom that changes the mapping.
3. Use an outward-rounded integer rectangle covering the whole table, all applicable notes, borders and any required shadows. It must be wholly inside the original screenshot. Preserve a minimal border margin if needed; record it. Do not crop from a horizontally or vertically incomplete table slice.
4. No resizing, interpolation, redrawing, sharpening, denoising, colour changes, annotation, compositing or stitching. No AI image generation. Use no new browser surface, raw protocol or hidden rendering engine.
5. Re-decode the output PNG in R and prove every RGB/RGBA pixel equals the selected subarray from the same R-decoded original screenshot. Record R/library versions, input/output dimensions, integer bounds, pixel-equality result and hashes. PNG preserves the decoded JPEG pixels; it does not recover information lost in the original JPEG encoding. Do not call it a native lossless browser export or claim greater resolution.
6. Visually inspect every final crop at native and documented intended display size. Check all headers, labels, rows, plots, notes and table edges. A successful pixel check alone is not visual acceptance or final Word acceptance.
7. Complete any still-needed full screenshots through the same permitted internal-browser localhost route within Order 007, then perform normal teardown and no-drift verification. If a complete screenshot or valid pixel mapping cannot be established, retain the full screenshot and report that exact capture limitation. Do not fabricate missing image content.

Use a new derived-capture subdirectory and a source-to-screenshot-to-crop manifest. Include originals and crop-verification evidence in the final non-circular package. The existing source, scientific, package, Word/native assembly and website-promotion boundaries are unchanged. The coordinator has not yet independently accepted the completed owner package.
