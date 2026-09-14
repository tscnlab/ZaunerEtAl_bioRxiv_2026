# REPORT-018 Order 72e: accepted SVG selection and Quarto preview

Date: 2026-09-11

Status: SEALED FOR ONE EXPLICIT HARMONIZER DISPATCH.

Authority: the author explicitly requests the accepted SVG assets in the
integrated figure/table Quarto and manuscript preview, without PNG substitution.
This order implements the already approved display selection. It does not
change science, expand the selection or promote a production manuscript.

## Scope and exact preimages

Executor: Harmonizer task `019ff52e-48ac-77b3-9a0e-9a87749a3bba`.

The only existing source endpoint permitted to change is:

`audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`

SHA-256 `1e29b5f4a83343978bbb4bf8e841072d1b941832991e3fa78139517738044676`,
48,345 bytes.

Its paired preview HTML may be replaced once after candidate acceptance:

`audit/manuscript_nature_health/manuscript_figure_table_selection.html`

Preimage SHA-256
`82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6`,
30,925,051 bytes.

The sole new durable owner write root is:

`audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/`

Require that root absent before starting. Preserve exact copies of both
endpoint preimages there before changing either. Keep the complete original
builders, replay, checker, manifests, table fragments, SVGs, existing QA and
all Writer-owned manuscript sources byte-identical. Do not run the old builder,
replay or old checker: their historical PNG, H06_daily and count contracts
are explicitly superseded for this preview, not repaired or resealed in place.

## Incorporated exact contracts

Central root:
`audit/report_harmonization/report018_order72e_selection_svg_preview/`

Read and rehash its complete release_manifest.csv, plus:

- `figure_reconciliation.csv`, SHA-256
  `42043f4f7bb308284ce8ac720d94d3008978db778f21f12216213e9a614cc529`;
- `retained_table_contract.csv`, SHA-256
  `9e392e02f824a944588bcfd0b85ec20c2aff9d17c31c198df9b720a9e2ee0e90`;
- `approved_insert_caption_blocks.json`, SHA-256
  `86edb84cfea2c64d67c4228f9f0b77037f20536bbfb3b797b2fdfb15881c76a3`;
- `input_and_preservation_pins.csv`, SHA-256
  `04226607b95164a3cb6da81cde646ec35e3550d9ed4e902e1f5b6e10805bacfb`;
- `standalone_render_context.json`, SHA-256
  `c9f21257526eaf9e12532d9502a4d4fc2b08c96382905a707dfcacf6e56479e6`;
- `coordinator_preflight_checks.csv`, SHA-256
  `ceac837b19df32e8d8ee7f33c4d8c16d7e719003e13b1a76cfe976a3f11cc8ff`.

The accepted 20-SVG JSON remains
`audit/report_harmonization/report018_order72d_writer_svg_integration/combined_accepted_svg_manifest.json`,
SHA-256 `0e0618520fedb387ef030b685e11597e7332ae46fa7ad9ad76d865c24b1c91b2`.

Coordinator independently reproduced all reported source/helper/manifest pins,
all 20 SVG identities, all 20 current include targets and all 19 current figure
paths. The figure matrix accounts for all of them: retain or replace 18
references, insert two already approved figures, remove the excluded H06_daily
figure. No other figure deletion or addition is authorized.

The retained table contract specifies 19 immutable gt fragments: three main
tables and 15 logical supplementary tables, with S11 continuing across two
fragments. Only the H06_daily table include is removed. In particular, preserve
the exact Table 3 fragment
`figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html`,
including its agreed Descriptives row order, every cell, label and source byte.

## One coherent source revision

Build the source revision in the new owner root and complete its source checks
before promoting the QMD once. Apply only the matrix-specified image-reference,
selection-status and numbering transitions. Resolve by path/endpoint, never
by an old ordinal alone.

The final image order is Main Figures 1, 2 and 3 followed by S1 through S17,
each appearing once in this Quarto page. The Word-specific second cropped
appearance of S8 does not apply here. Insert the accepted participant raincloud
as S6 and the accepted hourly site-significance screen as S12. Copy their
caption and alt-text strings exactly from the sealed inserted blocks, changing
only their image src to the matrix's selection-page relative path and using
the existing selection-page figure wrapper/style. Preserve their qualifications,
especially anonymous non-ranking raincloud interpretation and the distinction
between unadjusted intervals and predictor-specific FDR decisions.

Remove only the excluded H06_daily scientific display/table block, its
Supplementary-retention statements, blank-table repair note and coordination
rows. Remove or narrowly replace the stale raincloud-exclusion row. Renumber
the existing figure/table headings, caption labels, internal references and
coordination labels to the approved final mapping. Remove the no-longer-relevant
H06_daily clause from the cross-display contract while preserving the separate
sensor-position qualification. Do not leave contradictory old selection claims.

No broad prose, caption, terminology, layout, table or scientific revision is
released. All non-numbering caption text remains exact except the two inserted
approved blocks and removal of the excluded block. Other numbers, claims,
uncertainty, multiplicity, limitations, symbols, colours and figure semantics
remain protected. Keep existing appropriate alt text for all retained figures.

The provenance paragraph may identify this SVG-only integration order and its
already-existing accepted manifest. Preserve links to the old extraction
records but identify them as historical provenance, not a current exhaustive
selection seal. Do not link to an as-yet-nonexistent completion manifest or
modify old manifests to make new source hashes appear historically accepted.

## One narrow candidate render

Installed Quarto is 1.9.37. Coordinator's read-only `quarto inspect` identifies
the current selection source as Markdown-only, execute.enabled false and
embed-resources true, with local project directory audit/manuscript_nature_health.
It has no inherited website output directory or post-render hook. It does not
use the nathealth production profile. Recheck that context on the proposed
source and all included fragments before rendering: no R/other executable
cell, inline R, analysis call, or added filter is allowed.

After the complete source/mapping/protection preflight passes, invoke exactly
one narrow render from `audit/manuscript_nature_health`:

```text
quarto render manuscript_figure_table_selection.qmd --to html --output-dir figure_table_selection_svg_revision_2026_09_11/rendered
```

Keep the existing standalone YAML and embedded-resource configuration. Record
the effective command, environment, version and output path. This command may
write only the new owner render root and normal temporary Quarto/Sass scratch.
Use established narrowly elevated access to the existing user-owned Quarto
cache if necessary. Do not alter HOME, packages, profiles, lockfiles or caches,
clear caches, bypass protections, or run an exploratory second render.
The accepted R library and RENV_CONFIG_AUTOLOADER_ENABLED=FALSE apply to the
separate R 4.6.1 checks. Quarto must not start a computational engine here.

Do not run a full project render, --profile nathealth, quarto preview, a
manuscript render, or any hypothesis/Brown QMD. Do not write `_build/nathealth`.

## Candidate verification, visual QA and one HTML replacement

Use a new-root verifier, not the stale historical selection checker. Exercise
its complete prospective source contract before rendering and the complete
actual-output contract after rendering. Required final page contracts are:

- exactly 20 unique selected display images, in the approved order, each an
  embedded SVG whose decoded bytes match its accepted SVG source exactly;
- 19 native gt tables, 22 total HTML tables and 11 disclosures;
- exact retained table endpoint set, cell strings, order, grouping and all
  Table 3 source bytes/order;
- valid nonempty alt text, intact captions, unique document IDs and every
  table-header IDREF resolving once to the intended header in its own table;
- no selected figure using PNG, a PNG renamed SVG, a raster-wrapped SVG, or
  a wrong same-name candidate. Unchanged embedded table-cell distribution
  thumbnails are not figure substitutions and may retain their accepted
  raster format;
- no H06_daily selection or stale raincloud-exclusion/status claim, no
  unapproved source/claim/number change, no em dash or embedded render error;
- valid internal anchors and scoped local link targets. Check repository
  provenance links relative to the canonical paired HTML location, not the
  temporary candidate directory. Preserve those targets; do not serve source
  trees merely to make technical download links accessible during QA.

If an actual native-table semantic ID/header repair is needed, use only the
pinned accepted repair engine on the candidate HTML with exact reverse/reapply
ledger and unchanged visible DOM/content. This conditional no-rerender semantic
normalization is already within the order. Any other new defect stops the
single render with preserved evidence, not a hidden source patch or retry.

Perform served visual QA of the immutable, self-contained candidate using the
active quarto-authoring bounded procedure. Stage only the rendered HTML and
its necessary rendered assets, never the project or source-data root. Perform
the mandatory symlink containment check before starting one read-only GET/HEAD
server bound exclusively to 127.0.0.1. Record its exact root, PID, port and URL.
Inspect all 20 figures and the tables/disclosures at 1440, 708 and 390 pixels,
including actual intended display sizes, with no clipping, missing SVG layers,
overflow, unreadable legends, broken scroller, blank table or page console
error. Check Table 3's complete ordering visually as well as structurally.
Do not switch browser surfaces or work around a policy rejection. Stop the
listener after QA, close the review tab, prove teardown and rehash.

Only after complete candidate PASS, replace the paired selection HTML exactly
once with those accepted candidate bytes. Rehash the QMD, canonical HTML and
all protected inputs. No fresh render is needed for this byte-exact placement.
Preserve both old endpoint preimages and all temporary failed evidence, if any.
Create a new current completion record and unique non-circular manifest only
inside the new owner root. The manifest excludes itself and preserves the
historical asset/QA manifests without direct or broad resealing.

## Final holds

Mandatory return: `REPORT018-ORDER72E-SELECTION-SVG-PREVIEW-REVIEW`.

Return exact QMD/HTML identities, SVG mapping, source diff/reverse proof,
retained table proof, checks, screenshots, renderer/session, lifecycle and
non-circular manifest to Coordinator. Notify Writer of the accepted source
mapping only after independent acceptance, without granting another render.

Writer's separate Order72d authorizes the Word review candidate. Its sources,
production download and candidate inputs remain outside Harmonizer ownership.
The separate Brown scientific dependency remains held. Existing Brown panels
are retained historical review content, not acceptance of a new analysis.
No model, inference, scientific data/artifact, source figure, package/lock,
configuration, corpus manifest, production website, production manuscript,
commit, push, submission or upload change is authorized here.
