# REPORT-018 Order 72 H08 fail-closed record

Date: 2026-09-11

Status: STOPPED, FAIL CLOSED

Mandatory stop token: REPORT018-ORDER72-SVG-REVIEW

## Completed checks

- The controlling released and proposed orders and the dispatch release manifest matched their dispatched SHA-256 identities.
- All 71 release-manifest members were present, unique, non-circular, and exact before the H08 output root was created.
- The H08 output root was absent before dispatch.
- The candidate SVG was exported exactly once under R 4.6.1 with the accepted user library and the renv autoloader disabled.
- Native SVG structural inspection passed. The file has a 170 mm by 136 mm canvas, a matching viewBox, vector and text elements, no embedded raster image, no script or foreign object, no external reference, and the expected display strings and colours.

## Exact blocker

The first required raster-comparison preparation failed. macOS Quick Look emitted square, top-aligned thumbnails. The attempted central crops therefore omitted the title and subtitle and, for the original-size proof, additional lower content. This invalidates the required visual-comparison proof. It does not by itself establish a scientific or native-SVG layout defect.

The order requires stopping on the first failed visual check and prohibits patching or retrying within the release. No crop, rasterization, export, or rendering correction was attempted after the failure.

## Preserved identities

- Candidate SVG: `candidate/H08_near_eye_effects.svg`, SHA-256 `f0f77bbd896739941d8ae63bb24ed889528a410a963c2123b07ca3a825f7ddee`, 12,850 bytes.
- Export script: `export_h08_s14_svg.R`, SHA-256 `98f806ab6d3625d7b7f285176ce74005b5f767c64158ff449f1414322b9241bc`, 5,640 bytes.
- Failed original-size crop: `qa/candidate_original_2007x1606.png`, SHA-256 `c81ac13ec152d154d1390b2eb76569a5694081fbf65f786308a2f794d29e62a8`, 238,264 bytes.
- Failed intended-reader-size crop: `qa/candidate_reader_643x514.png`, SHA-256 `b433c2602b926f594b11cddb10997370a74cb7876726b4d47a9b548e6021b9c8`, 51,497 bytes.
- Accepted intended-reader-size reference: `qa/accepted_reader_643x514.png`, SHA-256 `bc8479871a428cd583b17b254246f84bbfa4079052bf6d5262bf8889796680f6`, 57,129 bytes.

## Disposition

The candidate is not promoted and no acceptance PASS is claimed. A new explicit release is required before any alternate rasterization or corrected visual-comparison attempt. No source, canonical asset, QMD, HTML, DOCX, manuscript, helper, test, profile, or scientific result was edited or rendered.
