# Order72k: S2 passed; Word SVG compatibility stop

Date: 2026-09-11. Status: **STOPPED_DOCX_SVG_PRECONDITION**.
Return gate: `REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW`.
Owner: Writer `019ffb39-372e-7262-bfac-192751fd0e63`.

## Outcome

S2 attempt5 passed its actual capture, visual review and protected-content
checks. The three remaining correction renders completed successfully. Before
Word assembly, a new read-only precondition check identified an incompatibility
between the rendered DOCX structure and the frozen SVG-embedding helper.
No assembly, SVG embedding, office QA, native Word inspection or further
render was attempted. This is a packaging stop, not a scientific discrepancy.

The controlling accessibility recovery is
`audit/report_harmonization/owner_orders/72k_s2_accessibility_guard_recovery_001.md`,
SHA-256 `016b67d9d2ed689f69ccfe9eea84ea9ad2794f0770b5cd07a77e57d54e5657c8`.
Original Order72k's fail-closed boundary and non-promotion conditions remain
controlling. No frozen helper was modified after discovering the Word issue.

## Completed S2 repair

The exact centrally supplied helper postimage is
`ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec`.
Its zero-fuzz reverse proof reproduces the retained 7f5c preimage byte-for-byte.
Both candidate CSS files remain the approved 03d9 postimage. Widths, fonts,
padding, three row partitions and A3 landscape geometry remain unchanged.

The completed capture manifest is
`../capture_s2_attempt5/word_table_png_manifest.json`, SHA-256
`ca9b338b1eb8ee35251190048973b3a37ff09c06cfc2ddefe5f9f511512b0ead`.
All 244 body cells, 17 distribution payloads, 17 metric rows, six groups,
14 columns, three headers, final notes and the runtime 7/5/5 hidden-description
proofs passed. All three source-size PNGs and all three intended-Word-size
surrogates were inspected. Unit and Scaling labels, miniplots and right edges
are complete. These six views are not a substitute for native Word inspection.

The first new reconciliation checker had an extra closing parenthesis and
stopped during parsing. The failed script was retained unchanged; the separately
named verified checker corrected only that parenthesis and its recorded script
name. The successful checker passed 13/13 checks without relaxing a test or
rerunning capture. See `checker_parse_correction.md` and `s2_visual_review.md`.

The new `word_table_manifest_attempt5.json` maps 19 tables to 29 PNG parts:
three new S2 parts, four previously passed S5/S6/S10 parts and 22 unchanged
parts. The separate SVG map still contains 22 exact sources and 23 appearances,
for a prospective 52-drawing document. No assembly has consumed this map.
Historical correction and capture manifests were not edited or rerun.

## Correction render outputs, not final deliverables

All commands, actual narrow permission requests and tool completion receipts
are retained in `render_execution_receipts.json` and the three attempt2 logs.
Each command used the installed Quarto 1.9.37 with `--no-execute`, its existing
normal cache and the verified three-Lua dependency closure. No full-project
or research-report render was run.

| Output | Exact SHA-256 | Result |
|---|---|---|
| Selection candidate `../../../consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/render_attempt2/selection.html` | `724d401d66fb99558e43c261db3ee9cdfe7c1a8ec5f9bf9a423f17df6e651b06` | Render exit 0; structural checks pass; corrected visual review pending |
| Main candidate `../project/render_html_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.html` | `acf0400d876a2d6ff9e1d69694e5843f79360573e9fc5a9db4bdbcf4b7cd2c78` | Render exit 0; structural checks pass; corrected visual review pending |
| Raw Word candidate `../project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx` | `a36009b0e7f52f61a89650a795dfcc0f7854b1c8be4dff235336135f68ee0d82` | Render exit 0; three conversion warnings; not assembled or visually accepted |

Exact absolute paths and sizes are in `stopped_correction_render_output_pins.csv`.
The paired HTML structural review passed 12/12 checks, including all 19 tables
on each page, resolving IDs/headers/internal links/images and separate S7/S15
image blocks. No corrected-HTML browser visual acceptance is claimed.

## New Word compatibility precondition

Quarto reports that `rsvg-convert` is unavailable for the three main SVGs.
Nevertheless, all three SVGs are embedded byte-exactly in the DOCX, through
`asvg:svgBlip` relationships rId21, rId28 and rId35. R 4.6.1 independently
verified each embedded member against the accepted explicit source map.

For these three drawings, the base `a:blip` has no `r:embed` attribute.
Its extension list contains both the standard `a14:useLocalDpi` extension
and the native SVG extension. The frozen embedding helper assumes a resolving
base image relationship and requires exactly one extension when an SVG already
exists. It would therefore fail on this unchanged Pandoc output. The main
float/caption structure itself remains complete and unique.

See `docx_svg_relationship_diagnosis.json`, the retained diagnostic scripts,
`stopped_docx_main_svg_identity.csv` and the render warnings. This was found
before consuming any assembly/embedding invocation. No renderer installation,
SVG rasterization, asset rewriting, model execution or implicit retry occurred.
A narrowly authorized compatibility adaptation could use the already exact
native SVG relationships and preserve the standard DPI extension. This return
does not authorize or implement that change, and grants no additional render.

## Preservation and runtime classification

The final R 4.6.1 verification reproduced all 4,339 pinned historical versions.
The four authorized source aliases match both live path and expected hash.
The prior helper/CSS versions resolve only to their exact retained preimages.
All other source, helper, asset, capture and historical evidence remains exact.

Eight candidate-local Quarto cache/xref files were copied byte-exactly before
the correction renders. Only one changed: main `.quarto/xref/b24ea1e3`, from
`421c5057ace152812a53e675ce68115c117c6d6afa9a51b777e787b260d1478e` to
`28e3f3bd8566bb9b0e501572950b4e959ca3b2d0788a83f6e9b19f6c67db9a8f`.
Its 9,279-byte pre-render version is preserved. This is a separately recorded
ordinary Quarto-owned runtime transition under the environment-cache order,
not a source exemption or a rewritten historical manifest. The other seven
files remain live-exact. No cache repair, deletion, chmod or runtime patch occurred.

The three candidate authoring sources, 29 mapped table PNGs, all 22 SVG sources
and original counterparts, both CSS files, immutable 12-file served set and all
prior captures remain exact. No numerical manuscript claim was recalculated.
R version, package versions, commands and verification outputs are retained.

## Teardown, lease and remaining work

The capture server PID 45047 closed at 21:21:17 UTC after its one bounded use.
Fresh checks at 21:38:11 UTC found no listener at 127.0.0.1:58005, no such PID
and no task-profile capture process. All three correction render sessions have
completed. No new preview server, browser tab or native document was opened.
No unrelated process was signalled. **Writer explicitly releases
`ORDER72K-VISUAL-LEASE-004` with this consolidated stopped return.**

Selection HTML, main HTML and main DOCX correction slots are consumed. The
S2 attempt5 allowance is consumed with PASS. Assembly/SVG embedding and office
QA remain 0 of 2, but are held for the new compatibility disposition. Native
Word review also awaits author unlock confirmation. No automatic unlock or
alternate native surface was used. Precise counts are in `trial_update.csv`.

Brown analysis/replacement and historical Figure S5 remain held. The separate
pending-status notice and bedside sleep-environment qualification remain
unchanged. Optional H11 compatibility remains excluded. Standalone editable
Word-table exports remain a separate nineteen-file deliverable, untouched by
this manuscript PNG-fallback repair. The accepted website, canonical sources,
outputs, scientific inputs, locks and central ledgers were not modified.

The owner snapshot is sealed non-circularly by `stopped_owner_manifest.csv`
and `stopped_owner_seal.json`. It excludes only that manifest and seal. This
package is returned for independent disposition, not canonical promotion.
