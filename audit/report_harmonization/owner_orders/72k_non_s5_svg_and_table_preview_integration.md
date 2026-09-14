# REPORT-018 Order72k: non-S5 SVG and table preview integration

Date: 2026-09-11.

Status: released for candidate-only integration after the accompanying
non-circular release and dispatch seals reproduce. No canonical promotion.

Dispatcher and independent reviewer: Harmonizer
`019ff52e-48ac-77b3-9a0e-9a87749a3bba`.
Sole implementation owner: Nature Health Writer
`019ffb39-372e-7262-bfac-192751fd0e63`.

## Authority and deliberate separation from Brown

The author requested SVG integration of ready figures, approved Table 3 and
its order, requested separate image blocks for S7 and S15, and identified
the S2 capture and S5/S6/S10 table-font defects. The preceding Order72i matrix
and author visual follow-up record those display decisions. The Harmonizer's
Order72j component review is independently accepted for static eligibility
only. The new H07/H09 components still require their first actual visual
acceptance in this integrated candidate.

This order supersedes only the integration sequencing in the proposed
Order72i plan: one Writer may prepare the paired selection and manuscript
candidates coherently, with Harmonizer review. No additional component export
is needed. Do not wait for Brown to prepare the non-S5 preview.

Brown Supplementary Figure S5 remains unchanged and held. The rejected BA-018
scientific recovery is not dispatched, delegated, copied for execution, or
resumed under this order. Do not run any Brown checker, fit driver, model,
prediction, inference, likelihood, compiler, or data preparation. Do not modify
the Brown worktree or any scientific artifact. The optional H11 compatibility
candidate also remains unpromoted and must not enter this candidate.

The mandatory return gate is `REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW`.
Even a full PASS here leaves final S5, Brown scientific closure, canonical
selection replacement, and final manuscript promotion held.

## Frozen starting state

All paths below are relative to the shared project root unless absolute.
The accompanying `integration_input_pins.csv` is the exact 186-path execution
and preservation inventory. Reproduce every row before implementation.

- Selection QMD: `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`,
  SHA-256 `197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9`.
- Selection HTML: same stem, `.html`,
  `7055fc384bd845f8b42e3d37901c846060aeef6b8248536dc75240070e7a51e4`.
- Main QMD: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`,
  `c6beb79ca34128c0b69d882c1e3ea332cb88664ce9a3c0883b39d1569db0a0d0`.
- Supplement source: `manuscript/R0_NatHealth/supplementary_information_outline.qmd`,
  `fbfdde52cd24a60a5ff19eefb7901d3b7dcb268d97c2c922e0e87e7c944c652e`.
- Main Table 3 accepted fragment:
  `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html`,
  `d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2`.
- Historical S5 SVG:
  `audit/manuscript_nature_health/figure_table_selection_assets/brown_supplementary_figure_s5.svg`,
  `61e8d4671939659ecf5eca6c6688c03414bb849d15b9d3f59f39c96ca7069cfd`.
- Stopped Order72d DOCX:
  `audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx`,
  `933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9`.

The main title, abstract, scientific narrative, numbers, citations, bibliography,
claims, sample definitions, tables, cell values, intervals, multiplicity,
source rows, and all unlisted display content remain frozen. No broad wording
or cosmetic review is released. Existing 19 editable table DOCX files and all
accepted/stopped packages remain untouched.

## Exact new write boundary

Writer may create only new candidates, copied implementation helpers, local
configurations, copied frozen resources, render scratch, checks, screenshots,
logs, and non-circular evidence inside these previously unused roots:

1. `audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/`
2. `audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/`

Use the first root for the standalone selection QMD/HTML candidate and its
minimal served output. Use the second for the copied manuscript/supplement,
candidate-only table captures, copied helper implementations, candidate HTML,
DOCX and rendered QA pages. Preserve the original relative input meaning when
rebasing resource links; record each old/new path and prove resolved-byte
identity. Copies are allowed, symlinks are not needed. Source-owned paths,
canonical helper scripts, source HTML fragments and existing assets are
read-only inputs. No edit to the project profiles, website, build corpus,
central ledgers, package library, lockfile, manuscript source tree or outputs.

Temporary Quarto caches, office user profiles and read-only serve staging may
use fresh task-specific `/private/tmp` directories. Record their exact paths.
No arbitrary directory deletion, recursive broad copy, or existing cache repair.

Harmonizer writes coordination/lease/independent-review evidence only under
`audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/`.
Do not edit the unrelated hypothesis coordination matrix for this work.

## Figure integration, with no asset rebuild

Retain the accepted 20-figure mapping, replacing only the two wrapper mappings
for S7 and S15 with the following four independent source blocks:

| Display block | Frozen native SVG | SHA-256 |
|---|---|---|
| S7-A | `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg` | `4ddf972fc4c8082594d13a3b446537ae8a525ca35077e0605967f9c4c0ce519e` |
| S7-B | `audit/hypotheses/H07/report018_order72j_split_svg_export/candidate/H07_revised_smooth_derivative_pairs_near_eye.svg` | `f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57` |
| S15-A | `audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_primary_effects.svg` | `a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a` |
| S15-B | `audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_observed_timing_patterns.svg` | `c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3` |

Use one `fig-s7` container and one `fig-s15` container, each with two stacked
full-width images, separate meaningful alt text, uppercase external A/B tags
aligned to the left, and one shared caption. Preserve internal component
panels, coordinate geometry, aspect ratio and every source byte. Do not make
a new SVG wrapper, flatten, crop, recolour, change fonts within, or rasterize
these scientific SVG sources. Add tags outside the source images only.

The selection source presently uses heading/image/caption blocks, not literal
figure containers for every display. Preserve the original heading anchors
and add the two explicit figure containers without duplicate anchors or
renumbering. Do not mistake markup representation for missing content.

Use each current manuscript S7/S15 shared caption as the existing accepted
reader-language source. Mirror its content in the selection candidate, allowing
only the surrounding caption wrapper. This removes the obsolete 'Accepted
single composite' notes and synchronizes the already accepted near-eye and
complementary chest distinction. All other captions remain unchanged. New
component alt texts must describe the two actual components separately without
new scientific claims, hidden identifiers, or an invented interpretation.

Retain accepted S17 exactly:
`audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg`,
`ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe`.
Do not use the optional `ca613c88...` candidate or reproduce its rejected
comparison through another browser, local server, or indirect route.

Retain S12 exactly:
`audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_stage3_site_specific_significance_screen.svg`,
`2b955196ce35eae1c973201a00523e538a6535ac59c8abe240160611a74c8b83`.
Its MDER legend stays absent. H06_daily stays excluded from all numbered
displays, image paths, captions and drawing/media relationships.

Mirror the accepted SVG choices for the remaining displays in the copied
manuscript, including any old PNG references that the established SVG mapping
already supersedes. Prove this as path-to-exact-accepted-SVG substitution,
never a new export. The resulting map has 22 distinct SVG sources and 23
appearances, including the preserved historical S5 exception. Do not describe
that held nested SVG as a newly accepted flat/native replacement.

Keep S5 image bytes, alt text and caption in each copied source unchanged
apart from path rebasing to the same bytes. Add a clearly separate preview
status notice outside the numbered display and scientific narrative:

> Non-S5 display-integration preview. The historical Brown Figure S5 and
> existing Brown results are retained for context and are not updated or
> newly scientifically accepted here. The Brown linkage-B replacement remains
> held pending explicit fit authorization and scientific review. During sleep,
> the unworn device describes the bedside sleep environment, not verified
> ocular exposure; contrary historical caption wording is not endorsed.

This notice identifies the known historical limitation. It does not authorize
a Brown source edit, replacement, compatibility trial or scientific execution.

## Table-display repairs

Main Table 3 is protected, not rebuilt or restyled. Reuse its exact approved
fragment, six groups and 17-metric Descriptives order, percentages, supported
FDR emphasis, wording, dimensions, miniplot payloads and spacing.

Supplementary Table S2 uses frozen HTML
`audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html`,
`6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97`.
Create a candidate capture using all 14 columns in one horizontal set, all
17 metric data rows, all 17 unchanged distribution images, and every group,
header and note. Narrow numeric columns and use contain-fit distributions
with their intrinsic aspect ratios. Continuation is vertical only, with the
complete header repeated. No crop, horizontal split, data/label shortening or
loss of a source cell is allowed. Exact row/cell/image reconciliation must
distinguish data rows from group-heading rows.

Give S2 a dedicated A3 landscape Word section, approximately 16.535 by
11.693 inches, with verified printable extents and no spill into another
section. Preserve the rest of the page geometry. Derive the number of vertical
parts from the verified layout. The prior prospective drawing formula is
`49 + n_s2_parts`, but reconcile this against the complete explicit drawing map
before using it as a hard gate.

Supplementary Tables S5, S6 and S10 are table-font repairs and are not the held
Brown Figure S5. Use the three pinned HTML sources in the input inventory.
Apply Arial, Helvetica, sans-serif explicitly to the temporary capture root,
its table, th/td and descendants. Verify computed family for a title, header,
stub, body cell and note before capture. Preserve all cell text, notes, colours,
order, source HTML bytes and existing vertical continuation. Do not alter the
separate editable table documents.

Copy, do not edit, `capture_word_tables.mjs`, `prepare_word_manuscript.py` and
`embed_accepted_svg_figures.py` into the candidate helper directory. Restrict
adaptations to new output/root parameters, the four table-capture cases,
S7/S15 independent drawings, the expanded exact SVG map and S2 section layout.
Skip their old broad figure-capture loop. Reuse unaffected frozen table
captures byte-exactly. Record the complete helper diff and test output paths
before any generation so no helper can overwrite an existing destination.

## Bounded execution and verification

Before generation, prepare one complete dry-run manifest of source copies,
include/resource resolutions, commands, output destinations, SVG/drawing map,
table parts, and expected changes. Parse copied code, inspect all remaining
assembly assertions, and verify bibliography/style/figure/table dependencies.
No analytical cells or inline R are present in the three current authoring
sources. Do not introduce any. If unexpected analytical execution appears,
stop before it rather than relying on `--no-execute` to suppress it.

Use an isolated candidate default Quarto project with execution disabled and
explicit narrow targets. Do not inherit the full website render list or run
the project profile. The installed Quarto is 1.9.37. New caches stay in the
fresh candidate or task-specific temporary boundary. R identity/semantic
checks use R 4.6.1 with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and the accepted
library. No package installation or profile/lock modification.

The complete candidate allowance is one initial pass plus one consolidated
layout-only correction pass: each pass may render the selection candidate to
HTML once, the complete manuscript candidate to HTML once, and the complete
manuscript candidate to DOCX once, then perform one candidate-only Word
assembly/SVG embedding and one local office QA rendering. Do not separately
render the supplement or any research report. The correction pass is limited
to the already listed layout/capture/link-path/wrapper issues and consumes no
new scientific computation. Retain both attempts. No automatic retries.

S2 may have one initial geometry capture and up to two vertical-pagination
adjustments before final assembly. S5/S6/S10 tables may have one initial
capture and one consolidated font-only correction. Source cells and input
images cannot change during these trials. Seal candidates before document
assembly; no repeated full-document loop merely to tune captures.

The owner may correct a plainly mechanical candidate-only checker defect
before consuming its final complete acceptance run, with exact before/after,
independent evidence and no weakened content test. A scientific discrepancy,
unexplained input drift, a new display defect outside this list, an output
escaping the candidate roots, or exhausted trial allowance causes one
consolidated stopped return, not another implicit retry.

Require exact input/protected rehashes, all frozen table cells and image bytes,
resolved links and captions, stable figure/table numbering, no duplicate IDs,
scoped resolving gt headers, accessible distinct image descriptions, zero
missing displays and no embedded execution errors. A reversible established
gt id/headers semantic repair is allowed only on the new candidate HTMLs,
with exact ledger/reverse proof and unchanged visible content.

Extract candidate DOCX media and require every embedded SVG byte hash to match
the explicit 22-source map and every drawing to its 23-appearance contract.
Do not replace native SVGs with raster-only approximations. Preserve internal
hyperlinks and other drawing/bookmark associations. Do not copy old hard-coded
21-drawing expectations into the revised map.

## Serial visual acceptance and permissions

Harmonizer grants one exclusive QA lease at a time. Browser checks, table
capture, native Word inspection and any office-render inspection are serial.
No prior Order72j lease remains active.

Inspect the new integrated preview through the permitted browser surface at
1440, 708 and 390 CSS pixels and figures at 642 CSS pixels, the intended
170-mm equivalent. Check all changed displays, especially S7/S15 component
visibility, figure-internal panels, left-side tags, legibility, captions,
table continuation, complete miniplots and contained scrolling. Static DOM
success does not substitute for these visual observations.

Use only a minimal candidate rendered-output root. Mandatory symlink and
private-resource preflight precedes one read-only GET/HEAD server bound to
127.0.0.1 on an unused high port. Never serve the project, models, raw data or
evidence tree. If sandbox permission is required, request the narrowly scoped
server permission through the tool before binding. This order does not grant
OS permission or authorize bypassing a rejection. On browser security rejection,
stop that route and request author screenshots; do not change browser surface,
use CDP, or tunnel around it. The previously rejected optional H11 comparison
is excluded, not retried under a different name.

Native Word is the document-compatibility target. Inspect S7/S15, S2, table
S5/S6/S10, and retained S17 at intended size. Do not save any accepted or
stopped document during QA. LibreOffice checks may record known viewer-specific
S17 limitations but cannot promote its optional replacement. Historical
Figure S5's known Word blank-panel limitation remains explicitly held and must
not be counted as newly repaired. If native Word or browser inspection is
unavailable, return the complete candidate as VISUAL_QA_PENDING with exact
missing evidence, not as accepted.

Close task-created tabs and documents, stop task-created listeners/processes,
prove no listener, and rehash every input and candidate after QA. Never kill
unrelated R processes or use a blanket process predicate that treats harmless
read-only inspections as a render conflict.

## Dispatch and final return

After rehashing the sealed release, Harmonizer checks Writer is idle, sends
this exact order once, and records the actual tool receipt and task state.
Report dispatch failure honestly; a sealed order alone is not a dispatch.
No other component/scientific task is woken. If delivery is rejected, preserve
the rejection and do not route execution through another task.

Return the fullest current candidate preview and candidate DOCX with a change
map, input-preservation proof, source/render/semantic/visual checks, precise
remaining S5/Brown and viewer limitations, command/trial ledger, teardown and
one non-circular owner manifest. Harmonizer independently reviews that package
and returns it to the coordinator at the mandatory gate. No canonical source,
asset, HTML, DOCX, build, manifest or scientific promotion is released here.
