# REPORT-018 Order 72c: H05 native-vector colour legend

Date: 2026-09-11

Status: sealed for one explicit H05 repair/export dispatch, followed by the
already released shared independent QA. No other owner is restarted.

## Independent stopped-state disposition

The single Order 72b H05 export produced an SVG with one embedded PNG: its
continuous colour guide. This genuinely violates the native-vector contract.
Its source rows, estimates, labels and panel drawing are not at issue. The
separate URL checker rejected valid local clip-path IDs ending in equals.
Neither finding permits weakening the no-raster or privacy rules.

Stopped SVG:
`audit/hypotheses/H05/report018_order72_svg_export/candidate/H05_reader_near_eye_effects.svg`

SHA-256 `d1b39fc64044832f1862f2409bf6e3078b9099170996ca646f5f942e7b50567e`,
32,260 bytes.

Stopped exporter SHA-256:
`dbaf4f34f5383c36b87955bfb03f8f277313829bdb2b2810e8afbea80169a389`,
23,937 bytes.

The owner stopped before its post-export inventory and complete manifest.
The coordinator independently rehashed all eight existing H05 stop files,
all 71 original release members and all 163 Order 72b recovery members.
Nothing in the old H05 root is to be changed or resealed in place.

## Complete prospective verification

The installed ggplot2 4.0.3 guide_colourbar defaults to a 300-bin raster
guide. Its rectangles mode supports the same 300 ordered colours without an
embedded image. A byte-exact isolated snapshot of all 164 referenced inputs
was used to execute the complete prospective exporter under R 4.6.1 and the
same libraries. It reached CANDIDATE_READY_FOR_SHARED_QA, passed all native,
privacy, visible-label and protected checks, and wrote its full 21-row owner
manifest without error. No project input or owner candidate was changed by
that temporary preflight.

An independent SVG check proved:

- exactly one old embedded legend image becomes 300 native rectangles;
- all 300 ordered legend colours match the old embedded legend exactly;
- all 101 text nodes match in exact sequence; and
- after removal of only those legend elements, the complete normalized SVG
  DOM is identical, including every mark, coordinate, style, label and viewBox.

The original-size wrapper extraction passed at 2700 x 2700. Its 643-pixel
reader comparison to the accepted PNG was inspected: the matrix, unfit cells,
labels, legend, colours and geometry remain consistent, without clipping.
The prospective SVG is proof only, not an accepted owner endpoint.

## Exact allowed repair and one owner export

Only H05 task `019fba35-6fd8-73c3-970f-e41f8b759bb6` may act after receiving
this order and its non-circular release manifest directly from Coordinator.

Rehash the new seal, original 71-row release, Order 72b 163-row release and
the five original H05 input pins. Require the new subdirectory absent before
copying the sealed script. The sole new owner write root is:

`audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/`

Copy the exact central prospective_exporter.R to that directory as
`export_h05_reader_near_eye_effects_svg.R`. Copy the provided exact static
review CSV to its `checks/static_exporter_review.csv` before execution.
Do not retype, format, broaden or otherwise alter the sealed postimage.

Prospective exporter SHA-256:
`d3260f625ae8664136de91daacff97cd329456ac0a09100e2f29f95204a9dabd`,
24,295 bytes.

Its exact patch map has three changes only:

1. Relocate all new outputs into the new vector_legend_repair subdirectory.
2. Add guide_colourbar(display = "rectangles", nbin = 300) to the existing
   fill scale. Preserve limits, breaks, palette, labels, orientation and
   guide dimensions. Do not touch the matrix or any other plotting code.
3. Accept local URL fragments only when they resolve exactly once to a real
   clipPath ID in that SVG. This includes valid IDs ending in equals, but
   never permits an external reference, script or embedded raster.

The exact reverse reconstructs the stopped exporter. The copied exporter
retains the parent Order 72b runtime provenance strings and membership
because that order remains incorporated. This Order 72c record supplies the
additional current authority and must be cited in the owner's new handoff.

After one parse/static review and exact reverse proof, invoke this exporter
exactly once with R 4.6.1, Rscript --vanilla,
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE and the existing accepted libraries.
Do not run a device probe, source a builder, or invoke a report renderer.

Expected repaired candidate:
`audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/candidate/H05_reader_near_eye_effects.svg`

Expected SHA-256:
`e9d7d60100403aea3ac25282f9be33f981b182a09e74479cd160bdc296ae63b3`,
66,573 bytes; 648 x 648 pt and unchanged viewBox.

Require the complete candidate-ready path and 21-row manifest to pass. Run
the sealed check_h05_legend_only.R once against the old and new candidate,
writing its three outputs directly below the new root; it must reproduce the five exact
preservation checks above. Preserve all old evidence. On a new failure, seal
the observed state and post-pin hashes, return the exact blocker, and do not
patch or retry.

Keep that generated 21-row owner_manifest.csv unchanged as runtime evidence.
Write order72c_reverse_and_authority_checks.csv and order72c_handoff.md, then
one separate order72c_final_manifest.csv containing exactly 33 unique members:
the original 21 members, owner_manifest.csv itself, the three legend-checker
outputs, those two new check/handoff files, and six controlling central files
(this order, its release manifest, check_h05_legend_only.R,
prospective_exporter.R, patch_map.json and static_exporter_review.csv).
The final manifest excludes itself. These enumerated leaf additions are
already authorized and must not cause another approval stop.

## Independent QA and remaining holds

Return the exact candidate, script, new checks, old-state preservation and
unique non-circular owner manifest to Coordinator and Harmonizer. Do not
claim visual or central acceptance. No H05 rasterizer or visual-QA command
is released; Harmonizer applies Order 72b section A to this exact repaired
candidate at 2700 x 2700 and 643 x 643 using the sealed wrapper helper. The
old embedded-raster SVG remains failed evidence and cannot be substituted.

The other six SVGs already have independent candidate acceptance and must
not be regenerated. Only when this seventh candidate also passes may a
seven-row accepted-SVG identity manifest be returned for separate Writer
integration authority. Production promotion and the separate Brown
scientific dependency remain held.

No scientific value, inference, source CSV, model, model read, prediction,
sample, palette, table, source QMD, canonical figure, HTML, DOCX, manuscript,
package, lockfile, profile, science ledger, Quarto/knitr/Pandoc execution,
commit, push or upload change is authorized. H06_daily remains excluded.

Mandatory stop: `REPORT018-ORDER72-SVG-REVIEW`.
