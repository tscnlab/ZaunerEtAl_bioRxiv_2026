# REPORT-018 Order 72: candidate-only native SVG export release

Date: 2026-09-11

Status: **SEALED FOR SINGLE DISPATCH TO EACH NAMED OWNER**

Authority: the author's requirement for actual SVG manuscript figures and the
coordinator's independent pre-dispatch review. This is a format-only execution
order under REPORT-018, not a scientific reopening or a production render.

## Exact incorporated specification

The complete scope, seven candidate paths, 37 input pins, and per-owner
plotting restrictions are incorporated without changing scientific meaning
from:

`audit/report_harmonization/owner_orders/72_manuscript_svg_exports_proposed.md`

SHA-256:
`d3f329a2149149663c47e5db4514cbb7771b0afb6362afc8b911871068d0ebcd`

This release overrides only that packet's PROPOSED / NOT RELEASED status.
It does not erase or rewrite the proposal. Each owner may execute only after
receiving a direct coordinator message identifying this release and its exact
non-circular dispatch manifest. A file appearing on disk is not a dispatch.

The corrected H02 destination is H02, not H01. The independent R 4.6.1 review
reproduced all 37 current input hashes and inspected all seven frozen plotting
sources. The nine initially missing display dependencies are now explicit.

## Owner allocation and write boundary

All paths below are relative to the shared project checkout:

`/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026`

| Owner | Task ID | Figures | Sole durable write root |
|---|---|---|---|
| H02 | 019fb4d0-9d07-75a2-bb73-71cd6b2d0e44 | Main Figure 2 | audit/hypotheses/H02/report018_order72_svg_export/ |
| H06 | 019fbd4a-288b-7a72-ac70-2d17ba6d2f04 | Current S9 and S12 | audit/hypotheses/H06/report018_order72_svg_export/ |
| H05 | 019fba35-6fd8-73c3-970f-e41f8b759bb6 | Current S13 | audit/hypotheses/H05/report018_order72_svg_export/ |
| H08 | 019fbdb6-b6a8-7e53-8e84-7a2967af9ea5 | Current S14 | audit/hypotheses/H08/report018_order72_svg_export/ |
| H10 | 019fdc1b-b77b-7972-aed0-784da328e115 | Current S16 | audit/hypotheses/H10/report018_order72_svg_export/ |
| H11 | 019fba59-0f3c-74a0-ab3d-58d389365ad1 | Current S17 | audit/hypotheses/H11/report018_order72_svg_export/ |

Address the figures by the incorporated candidate and source paths, not by
ordinal alone. The current manuscript has three main and 17 supplemental
figures. H06_daily remains removed. Brown's new linkage-B work and H01's
completed METRIC-010 work are not part of this order.

Create only new export code, SVG candidates, rasterized comparison proofs,
checks, session and command records, a completion or stopped record, and a
non-circular manifest under the allocated root. A fresh private temporary
directory is allowed for device scratch or comparison rendering. Do not
overwrite existing evidence. Do not write into another owner's root.

## Execution and preservation

1. Before any output, verify the release manifest and the applicable frozen
   input pins. Preserve the accepted PNG/PDF and all stored values. Source
   CSVs and the H02 plotting RDS are read-only. They are not regenerated.
2. Use R 4.6.1 and the existing accepted user library. For this export-only
   work, use `Rscript --vanilla` with
   `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`. Existing library paths are
   `/Users/zauner/Library/R/arm64/4.6/library` and the R 4.6 system library.
   Record the actual library paths and consequential package versions.
   No package installation, restore, update, lockfile or profile edit is
   released. Stop if a required dependency is unavailable.
3. Extract only the pure plotting functions or expressions described by the
   packet. Do not source or execute a broad builder. In particular, do not
   call `h02_build_figure_contract()` or H06's model-reading screening path.
   Rebuilding factors, palettes, night rectangles, and other display-only
   structures from frozen rows is allowed; fitting, predicting, estimating
   uncertainty, recalculating p-values/FDR, or making scientific summaries
   is not. H05's frozen common colour limit is the explicit display exception.
4. Retain existing labels, panel tags, tag positions, limits, geometry,
   colours, marks, intervals and captions. No terminology or cosmetic repair
   is released. H10's selection PNG and frozen display-text contract control
   its layout; its canonical PDF is reference provenance only.
5. Perform native-vector and privacy checks, then rasterize the SVG only for
   side-by-side comparison at the accepted PNG dimensions and intended reader
   width. This local figure QA is allowed. Quarto, knitr, Pandoc, manuscript
   renders, website renders, DOCX edits, and production promotion are not.
   Rendering-device antialiasing alone is not a scientific or layout defect;
   changed text, missing layers, shifted panel meaning, clipping, raster
   embedding, or unavailable font rendering must stop the package.
6. Stop once on a failed source, export, semantic, visual or manifest check.
   Preserve the failed candidate and evidence. Do not silently patch and
   retry, regenerate a source, substitute another figure, or broaden the job.
7. Return the exact SVG path, SHA-256 and bytes, source and script identities,
   dimensions, checks, visual observations, session, commands, and a unique
   non-circular completion manifest. Rehash the frozen inputs and protected
   source/configuration files after QA. Owner PASS is not central acceptance.

The six tasks have disjoint output roots and may run their lightweight export
jobs concurrently. This does not release any scientific parallel-compute job.
The Writer and Harmonizer may continue separately authorized work in their own
paths. Their concurrent changes, and other Order 72 evidence roots, must not be
claimed as changes made by an export owner. If using a broad inventory, record
those exact concurrent paths separately; never exempt a changed input pin or
scientific artifact. No owner may edit coordination records, existing
manifests, the scientific ledgers, any QMD, production HTML, or manuscript.

## Gate and coordination record

Mandatory owner stop: `REPORT018-ORDER72-SVG-REVIEW`.

The dispatch ledger is
`audit/report_harmonization/report018_order72_release/dispatch_ledger.csv`.
It records sent receipts separately from the frozen release manifest and must
not be used as an immutable execution pin. The historical 15-row hypothesis
matrix and science-decision ledgers remain unchanged by this export release.

After independent acceptance of all seven exact SVG endpoints, the coordinator
will issue the Writer a seven-row accepted SVG identity manifest. Only a later
explicit integration instruction may change manuscript resources or the
production landing/download. The Writer's separate 13-SVG candidate and the
new Brown primary-analysis dependency are not accepted or released by this
order.
