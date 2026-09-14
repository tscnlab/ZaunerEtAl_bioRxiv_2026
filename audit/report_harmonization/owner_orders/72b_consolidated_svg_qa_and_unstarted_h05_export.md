# REPORT-018 Order 72b: consolidated native SVG QA recovery

Date: 2026-09-11

Status: sealed for explicit direct dispatch. File presence is not execution
authority. No owner other than the named H05 task is to be restarted.

## Disposition and unchanged scientific boundary

Order 72 produced two owner-PASS H06 candidates and four other native SVG
candidates that stopped before valid visual comparison. H05 produced no
candidate. All 71 original release pins remain exact. The completed and
stopped owner records, scripts, candidates and manifests are historical
evidence and must not be edited, resealed in place or deleted.

The H08 completion manifest uses owner-root-relative paths. Resolve those
14 rows against its containing Order 72 directory without changing that
manifest. The other stopped manifests use project-relative paths. The
central recovery seal records fully resolved project-relative members.

The common rasterizer problem is now independently reproduced. Direct macOS
Quick Look thumbnails use a square viewport. A landscape SVG can appear at
the top of that viewport; a portrait SVG can be enlarged to the viewport
width and truncated below it. Therefore neither a center crop nor a blind
top-left crop of an unwrapped portrait is a valid comparison method.

Three synthetic probes establish a bounded solution: a temporary square
outer SVG viewport containing the candidate as an unchanged nested drawing,
with only the nested viewport's temporary x/y/width/height placement set for
the requested raster dimensions. Quick Look then renders the square
wrapper, and R extracts the exact top-left requested rectangle. The original
SVG file is not modified. Inner drawing nodes, text, style, data-independent
geometry and viewBox remain exact. One-raster-pixel edge antialiasing from
rounded viewport dimensions is allowed in the synthetic probe, not missing
content or changed geometry in a research figure.

This method passed landscape, portrait and square probes and produced a
2820 x 3900 raster from the unchanged H10 candidate. The central H10 tag
comparison is retained as supporting evidence, not full visual acceptance.

## Exact stopped classifications

- H02: sips returned status 13 when asked to rasterize its SVG. Preserve the
  generated SVG and all 19 stopped-manifest members. No re-export is allowed.
- H08: center-cropped Quick Look comparison images omitted content. Preserve
  the SVG and all 14 stopped-manifest members. No re-export is allowed.
- H11: direct Quick Look square rasters did not have the required portrait
  dimensions. Preserve the SVG, all 13 failure-manifest members and the
  separately supplied full gate report. No re-export is allowed.
- H10: requiring a path element specifically is not a native-vector
  criterion. Lines, rectangles, circles, polygons and polylines also qualify.
  Literal font-weight:bold is not a sufficient standalone acceptance gate
  for its tags: the accepted plotting code declares bold tags, but the
  effective accepted PNG and unchanged extracted plotting code, not an
  assumed serialized declaration, control this format-only export. Require
  exact A/B/C occurrence, geometry, size, weight and appearance against the
  accepted selection PNG. Do not make tags bold, change font size or waive a
  real visible difference. Preserve all 21 stopped-manifest members and
  leave the old verifier unchanged. The new independent QA may implement
  these two precise classifications; every other check remains required.
- H05: the 1-inch base-graphics device probe failed at plot.new() because
  default margins did not fit. sips was not reached and no figure data,
  candidate or durable H05 root was created. Preserve the original scratch
  file and the byte-identical central evidence copy. Do not repeat this
  probe. One actual H05 export is released below, using the already tested
  svglite device and the original scope.

These are bounded infrastructure or checker classifications. They are not
advance acceptance of an SVG, a scientific reopening, or authority to change
accepted display content.

## A. Shared independent QA, Harmonizer only

Task `019ff52e-48ac-77b3-9a0e-9a87749a3bba` may create new independent QA code,
wrappers, raster proofs, checks, session/command records and non-circular
acceptance or stopped evidence only under:

`audit/report_harmonization/report018_order72_qa_recovery/reviewer/`

A fresh private temporary directory is allowed for the same QA. Every old
owner directory is read-only, including its failed proofs and SVG. Do not
start H02, H08, H10 or H11, rerun their exporters, or edit their checkers.

Use the sealed `qa_svg_canvas.R` beside this order's release manifest. Its
three aspect-ratio cases were tested centrally. It accepts mode, input SVG,
requested width, requested height and a fresh output directory. For each
required proof:

1. Run Rscript --vanilla qa_svg_canvas.R prepare with the frozen SVG and
   target dimensions. It checks aspect ratio, exact descendants and source
   hash, then writes a QA-only square wrapper and contract.
2. Run /usr/bin/qlmanage -t -s MAX_DIMENSION -o QA_DIRECTORY WRAPPER.svg
   using narrowly approved Quick Look access if sandbox services require it.
   This is local figure comparison, not a Quarto or scientific render.
3. Run the same helper with mode extract. It checks the wrapper and source
   hashes, requires an exact square raster, extracts the original-size
   canvas and proves extraction fidelity. Never promote the wrapper.
4. Compare the raster to the accepted PNG at original size and the reader
   dimensions below. Record complete text, panel/tag placement, mark/line
   and interval geometry, colours, source-row representation, legends,
   captions, canvas ratio, whitespace and clipping. Also complete every
   native-vector, privacy, font, source-equivalence and no-drift check that
   the stopped owner had not yet reached.

| Owner | Preserved candidate SHA-256 | Original raster | Reader raster |
|---|---|---|---|
| H02 | 2f9493540f12c9c660d213ee619bc726f1e3a0e34ce52c0e59bdf6bd8102a5cd | 3300 x 4200 | 680 x 865, approximately 180 mm |
| H08 | f0f77bbd896739941d8ae63bb24ed889528a410a963c2123b07ca3a825f7ddee | 2007 x 1606 | 643 x 514, approximately 170 mm |
| H10 | 1340491390703f642e30b0284bd4e0416a704015bc717dd2a6e56a8073901799 | 2820 x 3900 | 643 x 889, approximately 170 mm |
| H11 | ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe | 3150 x 3300 | 643 x 674, approximately 170 mm |
| H05, once its single export returns | Pin from its new owner completion before QA | 2700 x 2700 | 643 x 643, approximately 170 mm |

The H11 old 642 x 673 proof remains historical and is not repaired. The new
reader proof uses the same approximately 170-mm convention as the other
supplementary figures. These are comparison-only pixel choices; native SVG
dimensions are frozen.

Run the complete new QA once per candidate after source/manifest verification.
If any genuinely new source, export, semantic, privacy or visible discrepancy
appears, stop that candidate with one consolidated record. No candidate
regeneration or patch-and-retry is released. Independent H06 acceptance may
be recorded separately from its already valid owner proofs; do not rerun H06.

## B. H05's one unstarted export

Only H05 task `019fba35-6fd8-73c3-970f-e41f8b759bb6` may resume once after a
direct dispatch of this order. Rehash its five original inputs, the original
71-row release and this recovery seal; require the output root still absent.
Read only the frozen near-eye/chest display CSVs as specified by Order 72.

Create the minimal native-SVG export script and exactly one candidate at:

`audit/hypotheses/H05/report018_order72_svg_export/candidate/H05_reader_near_eye_effects.svg`

All new H05 code and evidence must remain in that allocated root. R parse,
pure plotting-code review, library availability checks and pin checks are
allowed before the one export. Do not run another preliminary device probe,
base-graphics plot.new(), sips, Quick Look, broad builder, model input,
scientific calculation, report or manuscript renderer.

Perform native-vector, privacy, visible-label and protected-hash checks and
seal a unique non-circular owner package. Return CANDIDATE_READY_FOR_SHARED_QA,
not visual PASS or central acceptance, to Coordinator and Harmonizer. Section
A then supplies the required complete original/reader-size visual QA without
another owner export. Preserve the original common colour scale from the
frozen chest and near-eye values, with no source-data regeneration.

If the first actual export or a substantive check fails, preserve the
candidate/evidence and return the exact blocker. No second export is allowed.

## Preserved gate and aggregate release

R remains 4.6.1 with RENV_CONFIG_AUTOLOADER_ENABLED=FALSE, Rscript --vanilla,
and the existing accepted user/system libraries. No package installation,
profile or lock edit, fitted model, prediction, inference, QMD, HTML, DOCX,
canonical asset, science ledger, manuscript or production change is allowed.

Mandatory gate remains `REPORT018-ORDER72-SVG-REVIEW`. The original order,
proposal and release manifest remain byte-identical. All old owner seals are
immutable. Mutable coordinator status is separate from this release manifest.

Only after independent acceptance of all seven candidate paths and hashes
may a separate seven-row accepted-SVG manifest be sent to Writer. This order
does not authorize manuscript or production promotion or resolve the separate
Brown scientific dependency. H06_daily remains excluded.
