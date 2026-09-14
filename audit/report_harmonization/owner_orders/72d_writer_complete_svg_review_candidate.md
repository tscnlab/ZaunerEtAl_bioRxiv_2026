# REPORT-018 Order 72d: complete native-SVG Word review candidate

Date: 2026-09-11

Status: SEALED FOR ONE EXPLICIT WRITER INTEGRATION DISPATCH.

This is the separate format-only integration authority following the author's
requirement for actual SVG manuscript figures. It is not production promotion
and does not reopen science, manuscript prose, selection, or Brown analysis.

## Accepted inputs and coordinator concurrence

The seven previously missing candidates now pass
`REPORT018-ORDER72-SVG-REVIEW`. Their exact paths, manuscript labels, hashes,
sizes and owner/independent evidence are in:

`audit/report_harmonization/report018_order72_svg_acceptance/seven_accepted_svg_manifest.csv`

SHA-256 `f36d92cfdabe571005090b939a04e42ff4be260deb84b500060c13a5bf722ef0`.

The independent release record is `seven_accepted_svg_release.md` in that
directory, SHA-256
`5a7b19bc06afcd1c5b95e6e96abad54a27dde0103f3d584ac6c6a275e49fbe08`.

Coordinator independently rehashed all seven SVGs and their evidence, all six
independent acceptance manifests, and the 13 existing accepted SVGs. The H05
reader-size comparison was also inspected. Its raster legend is now 300 native
rectangles with exact colours, text and non-legend geometry. All seven new
SVGs have no embedded raster, script or foreign object.

The combined input manifest is:

`audit/report_harmonization/report018_order72d_writer_svg_integration/combined_accepted_svg_manifest.json`

SHA-256 `0e0618520fedb387ef030b685e11597e7332ae46fa7ad9ad76d865c24b1c91b2`.

It contains exactly 20 distinct selected figures: three main and 17
supplementary. There are 21 drawing appearances because Supplementary Figure
S8 deliberately occupies two cropped appearances. The seven added SVGs are
Main Figure 2 and S9, S12, S13, S14, S16 and S17. Do not infer other mappings
from filenames or replace the H10 selection layout with its broader source.

## Frozen document baseline and separate outputs

Writer task `019ffb39-372e-7262-bfac-192751fd0e63` is the sole executor.
At the next safe point of its current task, rehash this order's dispatch seal
and the complete input_and_preservation_pins.csv before acting.

Use the unchanged pre-embedding revision candidate as input:

`manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_revision_2026_09_11.docx`

SHA-256 `acb6548997c29e96a065dfd5a26a682a3f0fb08170185e0c57aab3b1b0b256c0`,
28,793,433 bytes.

Coordinator's read-only OOXML preflight finds no existing SVG part in this
baseline and reproduces all 20 figure mappings and 21 appearances exactly.
Use the combined manifest against this baseline, not an incremental second
pass over the partial-SVG candidate. That keeps the existing exact reversal
check valid and avoids stripping previously added SVG extension nodes.

Preserve the partial candidate at SHA-256
`252d17764c21ad1a07e541946d1c49e66ef0734b438f0845194ba45882ed86ff`.
Preserve the accepted production download
`_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx`, SHA-256
`74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8`.

The sole new durable write root for this order is:

`audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/`

Require that root to be absent before creation. Store the copied combined
manifest, any bounded integration wrapper, raw and current-order checks,
new review DOCX, rendered QA pages/PDF, visual observations, handoff and
non-circular evidence manifest inside it. Temporary document-render scratch
may use one fresh private temporary directory. Do not edit existing scripts,
manifests, documents, accepted SVGs, or another owner's evidence.

## One candidate integration and complete review

1. Use the existing byte-exact SVG OOXML embedding mechanism with the combined
   manifest. The inspected helper is
   `scripts/manuscript_nature_health/embed_accepted_svg_figures.py`, SHA-256
   `2b5533b192013b7efabbbc6eb963d40f8a8ec1cfb9bd1286a4be30eb1f2197d6`.
   No SVG data, drawing geometry, crop, alt text, caption, table, manuscript
   text, citation, bookmark, page break or section setting may be rewritten.
   Only necessary image relationships, SVG content types and SVG extension
   nodes change. Remove an old raster member only from the new candidate and
   only when no relationship references it.
2. Produce one separate complete review DOCX. Require all 20 authoritative
   SVG payloads to match the accepted source bytes exactly and all 21 drawing
   appearances to retain their original extents and crops. Preserve the S8
   two-part layout. Require exact document-XML reversal and every unaffected
   package member unchanged. No renamed PNG, raster-wrapped SVG or whole-page
   screenshot satisfies this authority.
3. The helper's old hard-coded report sentence still mentions seven held
   exports. It is legacy metadata, not the current gate. Preserve it as raw
   execution evidence if using the helper unchanged, and state the current
   20/20 outcome in a separate Order72d handoff. A new-root wrapper or copied
   helper may correct only that status metadata and its root/path resolution;
   preserve and prove the underlying embedding algorithm unchanged. Do not
   stop solely to request this enumerated metadata classification.
4. Perform the existing document-render and visual QA procedure on the new
   candidate only. Inspect every figure appearance at its actual document
   size, including all seven added displays and both S8 crops. Check labels,
   legends, symbols, fonts, colour, aspect, intervals/bands as drawn, no
   clipping or missing layers, captions and surrounding pagination. Inspect
   all rendered pages for unintended collateral layout changes. This is
   document/graphics QA, not Quarto or scientific execution.
5. SVG must remain the authoritative OOXML image payload. Application-created
   compatibility previews are permitted only as supplemental Word fallback
   parts with all accepted SVG bytes retained and resolved. Do not manually
   substitute raster figures or claim native Word compatibility from XML
   validity alone. Record the actual renderer and any native-Word review or
   outstanding application permission. Do not bypass an approval or tool
   security boundary.
6. Rehash all accepted inputs, the pre-embedding baseline, partial candidate
   and production download after QA. Write the completed or stopped handoff
   and a unique non-circular manifest of the exact new output/evidence files
   plus controlling authorities. Exclude the manifest itself. Return exact
   DOCX and embedded-SVG identities, appearance mapping, structural checks,
   visual results and preservation proofs. A genuinely new integration or
   visual defect stops this order; retain the candidate and evidence rather
   than changing source figures, prose, or retrying blindly.

## Holds and mandatory return

Mandatory stop: `REPORT018-ORDER72D-WRITER-SVG-CANDIDATE-REVIEW`.

Return to Coordinator and Harmonizer. This order does not authorize replacing
the production manuscript/download, changing manuscript QMD or HTML, broad
rendering, submission, commit, push or upload. It does not authorize model
reads, fits, predictions, calculations, new scientific claims, scientific
artifact regeneration, package/configuration changes or a language loop.

The existing Brown panels remain the frozen historical content of the review
baseline. Their presence here neither resolves the separate Brown scientific
dependency nor authorizes its reopening or replacement. H06_daily remains
excluded. The author's separately authorized writer work is not cancelled,
but must not mutate this pinned candidate baseline during this operation.
