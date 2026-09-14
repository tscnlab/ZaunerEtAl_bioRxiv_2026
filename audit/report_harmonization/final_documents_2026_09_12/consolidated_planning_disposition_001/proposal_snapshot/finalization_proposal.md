# Consolidated final-document proposal

Date: 2026-09-12, Europe/Berlin. Planning only, not an execution release.
Prepared by Harmonizer with Writer's separate read-only document inventory.
No scientific execution, source/helper edit, render, capture, browser/server,
promotion or additional owner activation was performed for this inventory.
The separately authorized native Word lease is identified below.

Project root, abbreviated ROOT below:
`/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026`.
Relative paths below resolve under ROOT unless explicitly absolute.

## 1. Current authority and reusable outputs

The current Word preview is structurally accepted, not final:
`audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/Nature_Health_non_S5_preview_attempt1.docx`,
SHA-256 `f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c`,
13,498,777 bytes. It and its old assembly/capture evidence must remain immutable.
Coordinator reconciliation is `c8690ec7209cf3da599b133185782923b639227b52a6b29b86ec2cd89a23663e`,
with 561-member manifest `00dfd5842ab298eaa43b44edc3472d09d7ee3c63bd0c4530c1f75bbad417cb18`.
Writer's 507-member manifest remains `aa4ccbbd1bf9f2e796dd18bc3e7d228d99b3031130c902b95af06e862cba5e01`.

Reusable inputs include the 22 exact SVG sources/23 appearances, unaffected
PNG table parts, approved Table 3, S7/S15 independent native components,
S8 crop windows, and repaired Table S5/S6/S10 Arial captures. Table 3 already
uses Duration, Dynamics, Exposure history, Level, Spectrum, Timing and the
approved 17-metric Descriptives order. Do not rebuild it merely to finalize.

Current corrected selection HTML:
`audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/render_attempt2/selection.html`,
`724d401d66fb99558e43c261db3ee9cdfe7c1a8ec5f9bf9a423f17df6e651b06`.
Current corrected main HTML:
`audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/project/render_html_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.html`,
`acf0400d876a2d6ff9e1d69694e5843f79360573e9fc5a9db4bdbcf4b7cd2c78`.
Both freshly rehashed. They are staged previews, not a complete-site rebuild.

All nineteen separate native editable Word tables freshly reproduce their
manifest hashes. The manifest is `manuscript/R0_NatHealth/editable_tables/table_manifest.json`,
`5582dfdbaed925b9152680f3e0e86226a1fce43d1cf1b9a1092d977e3a5e9833`.
The ZIP is `editable_manuscript_tables.zip`,
`14271fef83177d0af3abcf5a3f0ed0c954f6ede6ded18422c257c3ed742df605`.
Writer independently confirmed one native table per document and explicit
Arial on every text-bearing run. S2 is A3 landscape; S1/S9 are A4 portrait;
others are A4 landscape. Existing 28 rendered table-page PNGs and their prior
visual review are retained evidence, not native Word review of the new main
document. Their exact identities are in Writer's readiness return.
The three retained visual-inventory/manifest files and Writer's artifact.md
are also pinned in `current_inputs_and_outputs.csv`. The nineteen-file CSV
preserves Writer's source-table identities and export characteristics; the
separate mapping CSV distinguishes those from complete source-fragment hashes.

## 2. Website baseline and every freshness transition

The live corpus manifest is **not** the older `983b1613...` REPORT-018 seal.
It is the later Order71c 37-route manifest:
`audit/report_harmonization/phase4_corpus_manifest.csv`,
`01a2fdc1f1d11db45e28834893c79d620aa5321be1f49cff612b34589e068008`.
Authority: `audit/report_harmonization/report018_navigation_order71c_independent_acceptance.md`.
The full current build inventory is
`audit/report_harmonization/nathealth_final_landing_resync_2026_09_03/post_promotion_build_inventory.csv`,
`9195ac44c8fbcde08dac36bc3b4762c4e20feea30629cc5e5e645aad0f1564f4`.
Fresh checks reproduce all 893 regular build files, with no additions, missing
members or symlinks, and all 37 registered HTML hashes.

Only 21 of 37 live QMD sources match that ledger. These sixteen source-only
freshness transitions require classification and render reconciliation:

- `notebooks/descriptives.qmd`;
- every result QMD `notebooks/hypotheses/H01.qmd` through `H11.qmd`;
- `notebooks/hypotheses/H06_daily.qmd`;
- `audit/hypotheses/H01/H01_analysis_preparation.qmd`;
- `audit/hypotheses/H04/H04_analysis_preparation.qmd`;
- `audit/hypotheses/H06/H06_analysis_preparation.qmd`.

The accompanying CSVs contain every old source pin, current source pin,
rendered-file pin, exact output path and route order. A hash mismatch means a
freshness transition, not proof of a scientific discrepancy. Do not revert
these source changes to make an old checker pass. Verify their accepted
source-only provenance before releasing report execution.

There are also explicit integration gaps outside those sixteen:

1. Root `index.qmd` still has the earlier manuscript source, while accepted
   `_build/nathealth/index.html` is an Order71c direct HTML integration of the
   manuscript. Its current displayed title is "The multiscale architecture
   of personal light exposure"; the current Writer source/candidate title is
   "The health-relevant architecture of the everyday light exposome".
   A plain rerender of root index would regress accepted manuscript content.
2. Root `supplementary_information.qmd` and its current build remain a
   placeholder, not the complete Writer supplementary outline/standalone.
3. The site Word download remains `74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8`,
   not the later `f055f0c0...` preview or a future final document.
4. Canonical Writer/selection sources have not received the latest candidate
   S7/S15 component/CSS/S2 integration. Preserve the latest candidate deltas
   explicitly instead of rebuilding from older canonical content.
5. The complete native-table source HTML recorded in export provenance is
   the older `revision_2026_09_11/manuscript_render/ZaunerEtAl2026_NatHealth_phase3_brown.html`
   (`6a9b6b57...`), not the corrected candidate main HTML. Changed S2 and later
   accepted Brown outputs require refreshed source provenance and exports.
6. Brown-dependent Table 2, its associated displays/prose and S5 await the
   new scientific package. S3/S4 retain descriptive/exploratory context and
   must be explicitly reconfirmed or revised by that package, not inferred.
7. S2's new no-break repair must reach selection, main and standalone HTML,
   three manuscript PNG parts, native Table_S2.docx, ZIP and site downloads.

Profile `_quarto-nathealth.yml` is
`e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7`.
It targets `_build/nathealth`, explicitly sets `freeze: false`, and runs the
semantic post-render wrapper. Default `_quarto.yml` / `_quarto-website.yml`
target the old `docs`/root-RQ architecture and are not this finishing corpus.
The accepted Nature Health navigation CSS and mobile TOC should be retained.

## 3. True prerequisites versus exclusions

**Required science:** The Coordinator verified the actual direct author
message in Brown at 2026-09-12T07:38:47.039Z after its explicit fitting hold.
The normal task tool accepted one same-owner continuation, now active as
turn `01a0949c-4964-7cc1-b7b7-d61746e5b845`. Authority is
`audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12/`:
decision `27effcf84d1683a9571266dcb17260e5869a256d551de2ab0a816e29fabc7097`,
22-row dispatch `be96d9e2b65ebbbc49cb9e7a6628418261f040f985258ff617036a258fa046c9`,
six-row receipt manifest `9e8e1a0e84f27b4b093e05fcb3eee7d62b3e662f72bfc9201a10545347924ba2`.
This inventory independently rehashed all 22 dispatch rows and six receipt
rows with exact byte counts; see `brown_authority_dispatch_current_check.csv`.
The prior rejected dispatch remains historical evidence. Do not redispatch
Brown. Retain the original finite scope, 1,200-second accumulated compute cap
and already consumed 11.036231749982107 seconds, without reset. This is not
acceptance of unseen results or downstream integration authority. The next
scientific stop is BA-LB-G2-REVIEW. Writer receives only a subsequently
accepted, pinned Brown package. Historical S5 must not be cosmetically
relabelled as the new scientific result. Four old shared-root read-only R
probes, separately classified by the Coordinator, remain untouched and are
not Brown jobs. Their metadata are in the authority root's process_snapshot.json.

**Required display:** S2 no-break correction, eventual scientifically accepted
S5 replacement, any actual new native findings, source-to-build synchronization,
download synchronization and final structural/visual review. During the newly
authorized native session Writer has reported accessible exact f055 identity
and again observed historical S5 with only A/B tags and absent plots. That
specific native defect is confirmed, not a LibreOffice-only issue.

**Optional/excluded:** H11's Arial/safe-margin trial `ca613c88...` stays excluded.
Retain accepted S17 `ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe`.
Its historical LibreOffice note/font limitation is distinct from native Word
behavior. It need not block finishing with the accepted SVG, but record any
remaining converter limitation honestly. H06_daily stays excluded from
numbered manuscript displays; its two existing analysis routes remain in
the 37-page corpus. New scientific analysis, optional visual redesign,
publishing/uploading, broad accessibility remediation and unrelated wording
changes are not inferred from this finalization plan.

## 4. S2 repair ownership and exact invariant contract

Originating owner: Descriptives, task `019fb87f-41b5-75c1-bc11-aa7fa233ef89`.
Originating function: `metric_table_markdown()` in
`scripts/descriptives/build_publication_tables.R:376`,
`d944e4b4343b98f27a02beb50219f197007cd6c5cb6eecb5ed6f71b14d4ab886`.
The function already emits one `white-space:nowrap` span for mean ± SD.
All 170 mean/SD spans in accepted
`audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html`
(`6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97`)
retain that style. No raw data, metric formatter or scientific value change
is needed. Descriptives has not been activated by this planning request.

The Harmonizer's broad selection builder extracts that table from the rendered
Descriptives endpoint at line 2175 onward. Do not invoke the whole builder for
S2: it writes many tables/assets/plans and reconstructs other summaries.
Likewise, `run_descriptive_display_refresh.R` writes the descriptive CSV,
regenerates figures and changes manifests. It is not the narrow repair route.

The loss points are Writer-owned downstream code:

- Both Order72k `project/order72k_layout.css` copies force numeric-cell
  descendants to `white-space:normal!important`.
- `helpers/capture_word_tables.mjs:667` repeats that override; the current
  fixed site widths are 86 px at 12 px capture font.
- Native `scripts/manuscript_nature_health/export_editable_tables.py:141`
  collapses all whitespace in `add_run()` and ignores CSS nowrap, so inserting
  NBSP only in HTML would be lost again.

Proposed single candidate correction: preserve the existing semantic source,
protect only each complete mean/SD span and its descendants from the broad
wrapping override, and preserve equivalent unbreakable spacing through the
native export. If a class marker is needed, add it only to exact identified
mean/SD spans in the new candidate, with source/visible-text equivalence proof.
Do not alter hidden accessible descriptions or introduce blanket nowrap on
the whole table. Reallocate available column width if necessary, preserving
the total section/display geometry and all 14 columns. The author's additive
permission allows **one point less for S2 numeric text only**, if width/no-break
preservation is insufficient. This is not one CSS pixel and not a global font
reduction; calculate the CSS-point conversion explicitly in the eventual
layout contract. Record base/final font and intended Word physical size.

Require unchanged values, units, rounding, row order, seventeen metrics,
six groups, seventeen exact density PNG payloads and hidden descriptions,
captions/notes, cell inventory, three-part continuation and A3 section contract.
Native normal-space/NBSP changes must be an explicit typography-only allowlist,
with exact normalized text and numeric-token proof. Verify each full mean ± SD
occupies one line without clipping/overflow, all columns remain visible and
no font goes below the newly authorized S2-only minimum. If those conditions
cannot coexist, stop with the specific geometry conflict instead of shrinking
again or altering numbers.

The first new S2 candidate must validate HTML and native export together before
the final whole-document assembly. Existing consumed capture/render/assembly
slots are not reused. Headless browser capture cannot be used to work around
the binding browser denial; an actually permissible capture route must be
resolved in the future release, otherwise this step remains blocked.

## 5. Exact serial proposal and target commands, NOT EXECUTED

Proposed new finishing root P, to be approved and absent before creation:
`audit/manuscript_nature_health/final_review_2026_09_12`.
Use P for new candidates; retain every old candidate and seal. The site staging
project is `P/site_project` with its own `_build/nathealth` output. A bounded
dependency closure, not a whole project copy, is required before creation.
No new helper or copied project is created by this proposal.

### Release A: science and current native findings

Brown continues under the accepted same-owner authority, then stops for the
existing scientific review chain. Do not dispatch it again. Separately, Writer completes its
one already-granted read-only FINAL-DOCS-WORD-REVIEW-001 session and releases it.
Consolidate native findings once. Do not repair f055 inside Word.

### Release B: source/candidate preparation only

Writer prepares one protected candidate from the latest accepted main,
supplement and selection deltas, accepted Brown outputs when available, and
the exact S2 correction. Harmonizer owns table-fragment/selection consistency;
the existing navigation owner, task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`,
owns the eventual website wrapper/navigation/download integration if separately
activated. No separate Descriptives rebuild is needed for existing nowrap.

Before any generation, seal old/new source mapping, allowed code diffs,
output destinations and consumed/new trial ledger. Fix the landing and
supplement **sources**, not only their rendered HTML: reuse accepted Writer
body/metadata/captions with exact path rebasing and retain the site navigation.
Do not let root index's old prose or root supplement's placeholders reappear.

### Release C: bounded static manuscript renders and S2 export

Quarto 1.9.37 was identified by read-only local help. The complete candidate
main/selection/standalone sources have no analytical chunks and must remain so.
Proposed commands, each once from the stated candidate working directory:

```
# cwd ROOT/P/manuscript_project
/usr/local/bin/quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd --to html --no-execute --output-dir render_html
/usr/local/bin/quarto render supplementary_information_standalone.qmd --to html --no-execute --output-dir render_supplement
/usr/local/bin/quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd --to docx --no-execute --output-dir render_docx
# cwd ROOT/P/selection_project
/usr/local/bin/quarto render selection.qmd --to html --no-execute --output-dir render_html
```

These run Pandoc/Lua filters, Sass and resource copying and may update Quarto
cache/xref files in the new project. They must not run knitr science, mutate
canonical caches or inherit the complete root render list. Each code/resource
dependency and expected cache write needs an explicit new-root allowlist.

Use a candidate copy of the native exporter, restricted to the S2 whitespace
fix and any explicitly accepted Brown-dependent table changes. Its CLI is:

```
BUNDLED_PYTHON P/helpers/export_editable_tables.py P/manuscript_project/render_html/ZaunerEtAl2026_NatHealth_phase3_brown.html assets/reference.docx P/editable_tables --only Table_S2
```

This is an exact argument contract, with ROOT-relative P as defined above and
BUNDLED_PYTHON resolved to
`/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`.
Set `PYTHONDONTWRITEBYTECODE=1`. Add only the accepted Brown table labels to the
same invocation's `--only` list once the scientific return identifies them.
The exporter still parses all nineteen tables, writes selected DOCXs, merges
the manifest and rewrites the ZIP when all 19 records exist. Seed unchanged
candidate DOCXs from exact accepted files, not regeneration. README and export
provenance must be intentionally synchronized; the current archive loop omits
export_provenance.json although the current ZIP contains it. Repair that
packaging inconsistency in the explicit future scope. The accompanying
`table_source_export_dependencies.csv` maps all nineteen canonical source
fragments to current DOCXs and the latest corrected candidate HTML. Its
fragment hashes are whole-file hashes; the existing table manifest's
source_table_sha256 is a serialized table-element hash, a different object.

The old capture CLI is `BUNDLED_NODE P/helpers/capture_word_tables.mjs SOURCE_URL P/capture_s2 only-s2`.
It launches headless Chromium and is **not currently executable authority**.
Do not supply a file URL or server route to evade the browser denial. If a
permissible capture mechanism is separately established, allow one coherent
S2 capture trial and a specifically bounded correction, preserving the old
three-part mapping and all unaffected images. Otherwise report the unresolved
capture prerequisite. Do not silently change the manuscript table medium.

### Release D: one assembly and SVG embedding after inputs pass

The accepted assembly helper remains `e89329f60bb477bf726fb1ccc0f3acecd107bab81d4541a1fca2633cf54415aa`;
embedder postimage remains `75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b`.
Reuse their behavior with new output/maps, not old entrypoint destinations:

```
BUNDLED_PYTHON P/helpers/prepare_word_manuscript.py P/manuscript_project/render_docx/ZaunerEtAl2026_NatHealth_phase3_brown.docx P/word_table_manifest.json P/word_figure_svg_manifest.json P/manuscript_assembled.docx
BUNDLED_PYTHON P/helpers/embed_accepted_svg_figures.py P/manuscript_assembled.docx P/expanded_svg_manifest.json P/Nature_Health_final_review.docx --report P/svg_embedding.json
```

Both commands write new OOXML packages. Pin maps and expected counts before
execution. A scientifically approved flat/native S5 may change member names
but not the predeclared logical display contract. Require exact SVG payloads,
native-main preservation, only documented relationship changes, unchanged
unrelated package members, captions, bookmarks, internal links, author block,
section starts and table geometry. Existing known checker corrections must
be retained; do not hard-code older manifest hashes into a new final gate.

### Release E: routine automated office QA, then focused native check

Use serial packaged LibreOffice screenshot rendering as routine DOCX QA after
separate bounded release. This avoids manual opening on every iteration.
Reuse unchanged table-file visual evidence; render every changed native table
and the complete new main document once, with at most one consolidated
layout-only correction round if explicitly released. Name the exact changed
table set and render count before dispatch. There is no global 19-table
restyling, and existing office 0/2 is not silently converted into new trials.

The existing wrapper `render_editable_table_qa.py` uses two concurrent workers.
Do not use it unmodified for a serial assignment. Direct serial CLI:

```
BUNDLED_PYTHON /Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py P/editable_tables/Table_S2.docx --output_dir P/qa_office/Table_S2 --emit_pdf
BUNDLED_PYTHON /Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py P/Nature_Health_final_review.docx --output_dir P/qa_office/main --emit_pdf
```

Resolve office binaries through the bundled override directory, not desktop
LibreOffice. These commands create PDFs/PNGs and temporary office state; they
do not modify input DOCXs. Seal pre/post hashes and inspect all generated pages.
After the new package is structurally and converter-checked, one focused
native Word non-regression session is required for SVG-critical displays,
especially S5. LibreOffice success alone is insufficient because S5 is again
confirmed blank in Word. Do not require new native opening for every draft.

### Release F: complete source-consistent 37-route website

First approve the sixteen source transitions and the two root-source repairs.
Stage the exact approved sources/resources under P/site_project, keeping
`_quarto-nathealth.yml`'s intrinsic output location there. Its post-render hook
requires its project-local `_build/nathealth`; a bare `--output-dir` override
to an unrelated path would violate its checks. The full closure must resolve
all report code inputs without exposing raw research files as downloads.

Use the exact 37 sources and `render_position` order in
`corpus_37_current_readiness.csv`: preparation and reports first, root index
and supplement last. The command contract for each named route is:

```
# cwd ROOT/P/site_project; one route at a time, no broad default render
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library /usr/local/bin/quarto render EXACT_SOURCE_FROM_CSV --profile nathealth --to html --no-clean
```

`future_route_commands_NOT_EXECUTED.csv` expands this contract for all 37
routes, with the exact proposed working directory and output path, flags,
serial order, input-freshness condition and required execution preflight.
These are proposed commands, not an execution log or a release.

For the four static routes (index, supplement, placement decision,
preregistration deviations), append `--no-execute` after the root-source
repairs. Thirty-three routes contain R chunks. Do not apply `--no-execute`
indiscriminately: that would omit generated tables/report content. With current
`freeze:false`, knitr report code really executes, reads stored CSV/RDS,
constructs displayed tables/plots and loads helpers. The H01 companion also
queries the Quarto version. Static scanning found no direct producer write
call in those chunks, but this is not a transitive side-effect proof. Full
code/input closure and render-only owner concurrence are a prerequisite to
release. Do not run fit/rebuild/refresh entrypoints or enable unseen chunks.
Keep all authoritative scientific artifacts unchanged and verify numerical,
denominator, interval and source-table correspondence in R after each report.
Require exact S2 distribution payloads downstream; do not silently accept
different miniplots from report regeneration.

The pinned post-render wrapper `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`
loads pinned semantic repair engine `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`,
requires R 4.6.1 and gt 1.3.0, and modifies only declared generated HTML ID/header
semantics. A dedicated absolute `GT_HTML_SEMANTIC_AUDIT_DIR`, outside project
and output trees and already existing, should retain the audit. Pin this
directory and each exact future command at release. Do not run the historical
manifest builder/sealers in place: they overwrite the accepted ledger and
some contain old fixed-hash assumptions. A new acceptance record must preserve
the old ledger and explicitly version the final source/build transition.

### Release G: synchronized final review links and promotion

After all checks, update canonical sources/assets and downloads only under an
explicit reviewed promotion list, preserving recoverable preimages. Proposed
final review targets, with exact final hashes still to be generated:

- Main Word: `P/Nature_Health_final_review.docx`, then approved publication
  copies at `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
  and `_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx`.
- Each native table: `manuscript/R0_NatHealth/editable_tables/Table_1.docx`,
  `Table_2.docx`, `Table_3.docx`, `Table_S1.docx` through `Table_S10.docx`,
  `Table_S11a.docx`, `Table_S11b.docx`, `Table_S12.docx` through `Table_S15.docx`.
- Table bundle/metadata: that directory's ZIP, README, table_manifest.json
  and export_provenance.json; corresponding exact copies under the website's
  `editable_tables/` download directory if that destination is released.
- Figure/table selection: `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`
  and `.html`, promoted from the checked selection candidate.
- Standalone supplement: `manuscript/R0_NatHealth/_output/supplementary_information_standalone.html`.
- Complete website landing `_build/nathealth/index.html`, supplement
  `_build/nathealth/supplementary_information.html`, and every subpage listed
  in the 37-route CSV. The same relative paths under P/site_project provide
  pre-promotion final-review links.

Return one readable review index with direct absolute local links to main
Word, all nineteen individual native tables, ZIP, selection, supplement and
all 37 website routes. Do not present the older 74193a7a site download as final.
Local completion does not authorize push, upload, deployment or submission.

## 6. Common validation and stop rules

Require complete figures/tables, uppercase left-side panel tags, intact
captions/footnotes, consistent numbering, country/site and activity colour
contracts, semantic table scope/headers, unique document IDs, resolving
IDREFs, alt-text/hidden-description preservation and no literal escaped image
markup. Match all local links/fragments and resource bytes, protect against
path traversal/symlinks/private-resource exposure, and exclude raw files,
participant-level data, caches, credentials, absolute local paths and live
external dependencies from any newly created downloadable package. Compare
privacy changes against the reviewed resource allowlist, not a wholesale
copy of the repository or its caches.

Historical accessibility limitations on older routes are documented, not
silently declared fixed. Recheck regenerated pages and explicitly classify
remaining accepted issues. Maintain accepted responsive shell/navigation and
page-local scrolling; ordinary structural checks do not prove visual behavior.
Browser denial is binding. Do not use file/loopback/alternate-browser/CDP or
another task to reproduce a blocked action. Manual author screenshots or a
genuinely newly permissible surface can inform later review, but no bypass is
proposed. A local file link is an honest delivery mechanism, not a visual PASS.

Native Word lease FINAL-DOCS-WORD-REVIEW-001 was read, independently verified
7/7 and delivered once to Writer. Exact f055 access is confirmed and the
read-only session is ongoing at this planning snapshot; its final sealed
observation/teardown record is still awaited. Office conversion remains 0/2
and uninvoked. No concurrent surface assignment is allowed. Complete that
lease before future office/capture/other visual work. Brown result acceptance,
capture permission, final native review and source/output acceptance remain
real prerequisites, not administrative checks that a broad rerender closes.
The current native order is
`audit/report_harmonization/final_documents_2026_09_12/native_word_read_only_review_order.md`,
`48911c7eeab36eace190a6ce8b9fb908d39969711519cffef8da6ee3e51bce8a`.
Its dispatch manifest is `eb8e81ced60f371adb7c2372918e402a54e0558af220b5cf07a1cb500ee1bdab`.
The separately returned native report will be linked by an additive closure
record, without rewriting this planning snapshot or old review seals.

## Evidence scope

The CSVs beside this proposal were generated by inline read-only R 4.6.1
infrastructure queries. They do not calculate scientific estimates. The
first two transient R text-scanner queries failed on string/regular-expression
escaping before changing any file; the separate fixed-string scan succeeded.
One later structural mapping query stopped on a data-frame class mismatch
after writing only the proposed command inventory. Converting the checksum
class to plain text resolved it; all nineteen mappings and 28 Brown authority
rows then passed. No source or scientific artifact was changed by either query.
All current-file pin checks succeeded, with the sixteen old-versus-live QMD
freshness transitions explicitly retained. No historical checker or sealer was
rerun in place. Writer's native session is a separate explicitly released
operation and does not broaden this proposal's authority.
