# REPORT018-ORDER72-SVG-REVIEW

Status: **STOPPED, NOT ACCEPTED**

The single released H11 S17 export attempt stopped at the raster-comparison
dimension contract. No retry, repair, or canonical promotion was performed.

## Exact blocker

- Accepted original: 3150 x 3300 px.
- Required candidate comparison raster: 3150 x 3300 px.
- Quick Look output at the original-size request: 3300 x 3300 px.
- Required 170-mm reader comparison: 642 x 673 px.
- Quick Look output at the reader-size request: 673 x 673 px.

The native SVG itself has the accepted 10.5:11 canvas ratio, but the available
Quick Look thumbnail endpoint placed both rasterizations on square canvases.
Therefore the required like-for-like raster comparison could not proceed.

## Preserved failed candidate

- Path: `audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg`
- SHA-256: `ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe`
- Bytes: 25,379
- Width: 756.00 pt
- Height: 792.00 pt
- ViewBox: `0 0 756.00 792.00`

The reached structural check found 13 rectangles, 3 lines, 41 polylines,
3 polygons, 11 circles, and 34 text nodes. It found no image, script,
foreign-object, or metadata node. The later complete privacy, text-equivalence,
and visual checks were not reached, so this candidate is not an owner PASS.

## Preservation and evidence

- R: 4.6.1
- Export script SHA-256: `ec454b47001c2b3182eac354211129ca85c5cde7f7305e8902fe7bf5847f9f7a`
- Post-stop protected rehash: 71/71 release-manifest members PASS.
- Failure manifest: `failure_manifest.csv`
- Failure-manifest SHA-256: `f88f909b6691e71a6b3d80d5ce2a8767abd70e76ecb2dff45f2230fac5ed7110`
- Failure-manifest rows: 13, unique and non-circular.

All durable writes are confined to the released H11 evidence root. No model,
scientific source, QMD, HTML, DOCX, package, lockfile, canonical figure,
manuscript source, or shared coordination file was changed.
