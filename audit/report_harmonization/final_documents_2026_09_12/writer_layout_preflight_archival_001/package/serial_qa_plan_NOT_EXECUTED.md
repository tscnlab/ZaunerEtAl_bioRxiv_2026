# Serial future generation and QA contract

Nothing in this file is currently released for execution. This is one proposed
order for the coordinator to reconcile and seal after the prerequisite returns.
The previous browser/capture restrictions remain binding. Old render, capture,
assembly and embedding allowances remain consumed; office 0/2 remains unused
and unreleased, not automatically repurposed.

## Candidate and source boundaries

Proposed new output root, absent before implementation:
`/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/manuscript_nature_health/final_review_2026_09_12`

Call that exact path P below. No directory at P is created by this preflight.
Do not promote or modify f055 or a canonical output in place. Stage only the
dependency closure separately approved by the Harmonizer, not a project copy.
Reconcile accepted Writer prose with the latest candidate display overlay,
then the accepted Brown result changes. Pin the exact render QMD, reference
DOCX, bibliography, filters, resources, maps and helpers before generation.

The supplied prospective helper entrypoints intentionally stop. Removing their
stop guards is itself contingent on the separately sealed implementation order.
Their parse checks below are not run-time validation or a render permission.

## Fixed order and trial accounting

1. Receive the accepted Brown package and determine the exact changed table set
   B from `Table_2`, `Table_S3` and `Table_S4`, or an expressly approved expansion.
   Confirm unaffected Brown-derived figures and descriptive tables rather than
   assuming that the new analysis changes all of them. Resolve historical S5
   with a scientifically identical accepted Word-compatible display source.
2. Finish the source/route authority reconciliation. Approve the one consolidated
   candidate source and display diff. Set the actual S2 numeric reduction to
   zero for the first width/no-break trial.
3. Render the static manuscript/selection candidates only under separately
   released commands and writes. No knitr analysis or full root render.
4. Resolve a genuinely permissible capture route, or an explicit author-supplied
   artifact with exact source/layout proof. This prerequisite is unresolved.
   The old helper's Chromium entrypoint is not an alternative route or bypass.
   The image need is five new files: three S2 parts and two S7 tail parts.
   S7 parts 1/2 and other unaffected images are reused. Brown replacements have
   their own accepted display bindings. A proposed single initial capture
   trial plus at most one explicitly released consolidated correction is not
   permission for ad hoc reruns. Any failed layout trial is recorded as consumed.
   Merge each partial new capture return into a complete 19-key manifest before
   assembly. For S7 the files must be ordered reused part 1, reused part 2, new
   part 3, new part 4. Do not pass its two-file tail-only capture manifest directly
   to the assembler. Verify row ranges partition `[0,23)` once, without omission
   or repetition, and retain the exact notes on the final part only.
5. Seed all unchanged native DOCX files and per-table provenance byte-exact into
   P/editable_tables. Rebase manifest paths without claiming a new export.
   Prepare the new README and export provenance with exact per-table source
   bindings, reused/regenerated status and named changed set. Export S2 and B
   once, preserving all other native files. The updated exporter requires all
   three metadata files and packages exactly 19 documents.
6. Run the automatic S2 DOCX QA first, serially. If it fails, do not assemble the
   main manuscript. Return one consolidated correction request, including whether
   the conditional one-point S2 numeric reduction is genuinely required. No
   global font reduction, additional S2 part or hidden cropping is allowed.
7. Run each changed Brown native table through the same automatic renderer, one
   command at a time, in numerical table order. Reuse prior page QA only for
   native files that remain byte-identical to their previously reviewed files.
8. Once all table images, native tables and accepted SVG sources pass their
   input checks, assemble the main Word once and embed the SVGs once. Require
   the resolved 19-key part-count contract, exact expanded figure manifest and
   unchanged scientific/caption text. New destinations only. No old 29-part
   guard or old output-manifest identity is copied into a final checker.
9. Render the entire new main DOCX automatically once. Inspect every resulting
   page, including all repaired transitions, small labels and end matter.
   If one consolidated correction round is separately released, rerender only
   genuinely changed native files and the corrected whole main document.
10. After structural and converter QA, conduct one separately released focused
    native Word compatibility session. Then complete the source-consistent
    37-route site and synchronized download checks under the Harmonizer's plan.

Initial routine DOCX QA count is **2 + |B|**: one S2 document, every explicitly
changed Brown native table and one whole main document. If only Table 2 changes
in B, that is three document-render commands. The value of B is not yet accepted,
so no final count is silently fixed at two. Old 0/2 is not a new allowance.

The packaged renderer was read, not executed. It normally performs one direct
DOCX-to-PDF office process per command, but can attempt DOCX-to-ODT and ODT-to-PDF
after a failed direct conversion. Therefore its conservative bound is **three
serial office subprocesses per document-render command**, not one. The future
release must explicitly account for that internal fallback or choose a separately
reviewed no-fallback wrapper. Do not conceal it as a free retry. All conversion
attempts must be logged. A fallback PDF is not proof of native Word fidelity.
Its rasterization uses up to eight Poppler workers within one PDF; there are no
parallel document/office jobs in this plan. The existing two-document-worker
`render_editable_table_qa.py` wrapper is not used.

## Exact automatic renderer argument contract

Use the bundled Python executable, which makes this renderer resolve the
bundled `dependencies/bin/override/soffice` and Poppler. Do not use desktop
LibreOffice. `PYTHONDONTWRITEBYTECODE=1` is the only caller environment addition.
The renderer creates isolated temporary office profiles below `/private/tmp`.
Source DOCX hashes must be identical before and after each command.

The following commands are **NOT EXECUTED**. P is the literal absolute path
declared above, to be substituted by the implementation order, not an unresolved
environment variable. Every output directory must be new.

```text
/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py P/editable_tables/Table_S2.docx --output_dir P/qa_office/round1/Table_S2 --dpi 150 --emit_pdf --verbose
/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py P/Nature_Health_final_review.docx --output_dir P/qa_office/round1/main --dpi 150 --emit_pdf --verbose
```

Insert between them exactly one analogous command for each accepted changed
Brown native file, with its label in both input and output. `--dpi 150` avoids
the renderer inferring DPI from only the first section of a mixed A4/A3 document
or performing an extra PDF conversion to infer DPI. PDFs and page PNGs are QA
evidence, not substitute final deliverables. Use intended physical print size
when judging readability, not a blown-up raster crop.

The native export argument contract is the proposed candidate helper plus
`P/manuscript_project/render_html/ZaunerEtAl2026_NatHealth_phase3_brown.html`,
the exact unchanged `assets/reference.docx`, `P/editable_tables`,
`--only Table_S2` followed by only the accepted B labels, and
`--s2-numeric-reduction-pt 0`. A reduction argument of 1 needs the documented
width-first failure and the separately released correction. No other native
table is re-exported merely because the complete HTML acquired a new hash.

Assembly uses the existing four positional arguments and additionally
`--part-count-contract P/part_count_contract.json`. Its unresolved draft is
provided in this package and deliberately rejects null Brown entries.

## Required structural and visual evidence

- Pin old/new sources and all generated file identities. Keep text/number/citation
  integrity separate from appearance. No scientific result is verified by a PNG.
- All manuscript and caption text remains exact except separately accepted Brown
  revisions. Preserve authors, 14 affiliation markers, AI statement, CRediT,
  funding, competing interests, data/code declarations, links and bookmark IDs.
- Main document image parts follow the exact resolved manifest. S2 remains three
  full-width parts, S7 becomes four equal-width parts. All 19 editable table
  keys remain. Table 3 retains its accepted images, order and design.
- Every S2 whole mean ± SD unit stays on one line in HTML/image and native DOCX.
  All 14 columns and 17 distribution plots are fully visible with preserved
  aspect ratio. Normalize only allowed space/NBSP substitutions for native
  text integrity; no change in punctuation, precision, value or note text.
- All 13 top-level sections start fresh Word pages. No empty portrait section
  remains between S1/S2/S3; no blanket empty-paragraph removal is performed.
- Main Table 2/3 and Figure 3 captions, all listed supplementary captions and
  headings remain coherent with their display. If a preserved-scale block does
  not physically fit, report it rather than silently shrinking the table.
- Check dense Figure 3, S1, S7, S8 lower crop, S10, S11 and S16 at intended size.
  Preserve S7/S15 independent images, both accepted S8 crops and accepted S17.
- Validate the native ZIP's 19 DOCXs and README, table manifest and export
  provenance against their individual files. Verify every website download
  returns the exact corresponding final Word/ZIP, not the older website file.

## One focused native compatibility session

Only after a new explicit visual release, use the new pinned document, not the
old open f055 file. The author need not manually open each interim table. The
routine page images above provide the full layout review; the native session
has a narrow compatibility remit.

Baseline focus: the accepted S5 replacement, S7 A/B, S8 upper/lower crops,
S15 A/B and retained S17, eight existing logical appearances. Add only any
newly changed SVG appearances named in the accepted Brown manifest. Confirm
actual plots, labels and crops are visible in Word at intended size. Confirm
the shared S7 caption remains adjacent to A with B beginning separately.
Do not update fields, save, export or print the document in that read-only
session. Record any converter-only difference separately. Do not infer native
link activation from structural bookmark checks; test a small set only if
supported controls and the new release allow it.

Final acceptance requires the complete main Word, nineteen native table files,
ZIP and all 37 source-consistent website routes. This preflight delivers none
of those final artifacts and does not mark an old preview as final.
