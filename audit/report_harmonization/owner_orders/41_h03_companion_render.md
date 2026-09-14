# REPORT-018 owner order 41: H03 preparation and provenance companion render

Date: 2026-08-20

Owner: H03 worker `019fbe52-c067-7521-b2cf-62d9398d173b`

Status: **released for exactly one H03 companion render**

## Scheduling authority

REPORT-018 prioritizes successful integration of all remaining reader-facing
Quarto pages and prohibits a new language, style, optional-link, historical
test-literal, or cosmetic cleanup loop. H03 result integration is independently
accepted. This order releases only the H03 preparation and provenance
companion. H04 and every later target remain held.

The dispatch-time coordination matrix identity is recorded as coordination
evidence rather than a mutable owner execution pin.

Controlling H03 result acceptance:

- `audit/report_harmonization/report018_h03_result_independent_acceptance.md`,
  SHA-256
  `13df2fbabb90976ba06663105fd6474f00cd2a466fbafe5da0167e41524346ed`;
- `audit/report_harmonization/report018_h03_result_acceptance_manifest.csv`,
  SHA-256
  `a0da2bfd4c3752e1e25200f786b32b66e8e47ea3ed9b376ac21d2c0957faa75f`.

## Hard preflight pins

Stop before rendering if any of these live identities differ:

- companion QMD
  `audit/hypotheses/H03/H03_analysis_preparation.qmd`:
  `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131`,
  75,638 bytes;
- accepted result QMD `notebooks/hypotheses/H03.qmd`:
  `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41`,
  68,198 bytes;
- accepted result HTML
  `_build/nathealth/notebooks/hypotheses/H03.html`:
  `abe4be0b127c66b357eca66ab5e90609e0ac7902ca611c5f0e8a9adf410f2cc1`,
  335,521 bytes;
- stale held companion HTML
  `_build/nathealth/audit/hypotheses/H03/H03_analysis_preparation.html`:
  `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`,
  900,339 bytes;
- H03 handoff `audit/handoffs/H03_worker_handoff.md`:
  `49beea589f5709e598975703f2bed4337e203c40a1ec64d4e218be4eda4a6a48`,
  30,095 bytes;
- source-only acceptance
  `audit/report_harmonization/report017_h03_order34a_source_independent_acceptance.md`:
  `611282cd186a9645936e2f5862f657be380a7259b2717b832edbe818fd835852`;
- preparation test `tests/hypotheses/H03/test_h03_preparation_report.R`:
  `bddaa2393ead9317c5f526a00f75d2fd86e0e7efeaf84dcd2737e61b149a058a`,
  8,412 bytes;
- auxiliary stored-output test
  `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R`:
  `30fa488114886eb4e9feeccc55f6f752e229585bfc1f2eb5b5a85bfba582bfc8`,
  7,568 bytes;
- historical preparation manifest
  `artifacts/12_manifests/H03/H03_preparation_report_manifest.csv`:
  `5235b02c6c542a010336eca9569b77b269deb673d4659d794393d2427146393a`,
  81,124 bytes;
- historical preparation helper
  `scripts/hypotheses/H03/build_h03_preparation_report_manifest.R`:
  `d9527beb4fdb94186e4955d1e730b8346aef4a7ff213253d91f795ded3b1a79e`,
  9,155 bytes;
- profile `_quarto-nathealth.yml`:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- post-render wrapper
  `scripts/report_harmonization/post_render_gt_html_semantics.R`:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic repair engine
  `scripts/report_harmonization/repair_gt_html_semantics.R`:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.

Also recheck the 23-row result acceptance manifest under R 4.6.1 and stop on
any mismatch outside the accepted result HTML transition already sealed there.

## Historical companion state, deliberately not repaired

The companion source is accepted, while several old integration records remain
historical. They are not defects under REPORT-018 and must not start a cleanup
loop:

- the direct authoring-tree HTML remains SHA-256
  `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`;
- the website QMD copy remains stale at SHA-256
  `dfc17bbb68db4815f3678e43b76f773007799692ea98a3880c3d47b532d77f76`,
  62,305 bytes;
- the 319-row historical preparation manifest currently has exactly seven live
  mismatches: accepted result HTML, profile, Stage 3 manifest, figure-layout
  decision, companion authoring QMD, result QMD, and Stage 3 reader test;
- the historical helper still implements the former direct-render copy model;
  executing it could replace the accepted website target with the stale direct
  HTML;
- the preparation test consumes those historical copy and manifest contracts.

Do not edit or execute the helper. Do not edit or run the preparation test in
this order. Preserve the historical manifest byte-for-byte. After rendering,
record the companion HTML as one additional expected live transition. If Quarto
itself refreshes a target-owned build QMD, accept it only when it is
source-identical to the accepted companion QMD and classify it explicitly.
Otherwise preserve the stale build QMD for later archival disposition.

## Exact execution boundary

1. Rehash all hard pins and the protected H03 scientific set. Stop on drift.
2. Inventory the complete `_build/nathealth` tree and require zero symlinks.
3. Create one fresh absolute directory under `/private/tmp` for semantic-hook
   evidence and record its path, permissions, and emptiness.
4. Run exactly once through the normal R 4.6.1 project profile and established
   narrow user-owned renv-cache access:

   ```text
   GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H03/H03_analysis_preparation.qmd --profile nathealth
   ```

5. Do not use `--no-execute`, bypass `.Rprofile`, render the result again,
   render another target, or run the full project.
6. If startup or rendering fails, do not patch or retry. Complete safe read-only
   inspection and return one consolidated stopped record.

## Scientific preservation boundary

The render may read accepted stored inputs and format them. It must not fit or
refit a model, calculate new inference, predict, simulate, bootstrap, resample,
recompute Shapley or dominance allocations, or regenerate durable scientific
artifacts. Preserve all samples, formulas, estimates, intervals, p-values, FDR
decisions, diagnostics, sensitivities, figures, source data, and the distinct
population-mean versus participant random-intercept interpretation.

No source, test, helper, current or historical manifest, handoff, profile,
package, lockfile, ledger, manuscript, or accepted result HTML edit is
authorized.

## Required semantic and reader checks

After the sole render:

1. Require semantic-hook disposition `REPAIRED` or `ALREADY_REPAIRED` as
   appropriate for the fresh target. Retain the external summary and reversible
   ledger.
2. Require exactly 27 native gt-table endpoints, four figure endpoints, and one
   top-down Mermaid diagram, in accepted source order.
3. Require one Quarto-owned caption per endpoint, complete figure alt text,
   preserved values, notes, table order, figure order, and source links.
4. Require document-wide unique IDs. Every explicit `headers` token must
   resolve exactly once to the intended `th` in its own table. Every supported
   document ID reference must resolve.
5. Require the result-to-companion link to resolve and require the fresh
   companion HTML to contain
   `sec-h03-prep-participant-random-intercept` exactly once. Preserve the
   reciprocal companion-to-result link.
6. Require all preregistration-deviation links and anchors, Supplementary
   information, source-data downloads, navigation, and all country-coded site
   labels to resolve.
7. Require zero forbidden `file:`, `_build`, or absolute-local reader targets,
   unresolved cross-references, embedded errors, warnings, or stderr nodes.
8. Independently rerun only the unchanged auxiliary participant
   random-intercept stored-output test. Use structural current-HTML checks for
   the companion instead of executing the known historical preparation test.

## Build and protected-input contract

The accepted result QMD and HTML, both H03 authoring QMDs, profile, semantic
tools, scientific inputs and artifacts, source data, handoff, tests, helper,
and historical manifests must remain byte-identical.

Classify every build change. Expected content changes are the companion HTML,
normal `search.json` and `sitemap.xml` updates, and target-owned page assets
produced directly by this companion render. A build QMD change is allowed only
when it is byte-identical to the accepted companion source. Byte-identical
framework or target-resource modification-time touches may be classified
separately. Stop on every other unclassified addition, deletion, or content
change.

## Secure-loopback visual QA

Only after nonvisual checks pass:

1. Preflight `_build/nathealth` for symlinks again.
2. Start one temporary read-only static server rooted exactly at
   `_build/nathealth`, bound only to `127.0.0.1` on one unused high port.
3. Inspect only the exact H03 companion route in the in-app browser.
4. Inspect 1440 x 1000, 708 x 1000, and 720 x 500
   200-percent-equivalent layouts. Inspect all 27 tables, all four figures, the
   Mermaid diagram, title, headings, callouts, captions, links, navigation,
   wrapping, clipping, overlap, and page overflow.
5. Apply the accepted table policy: desktop tables must be usable at normal
   laptop width; narrow tables may use contained, usable horizontal scrolling.
6. Inspect all four exported PNGs at their native or intended final size.
7. Record console warnings and errors. The optional favicon 404 is nonblocking.
8. Close the QA tab, reset the viewport, stop the server, and prove no listener
   remains. Rehash protected and build inventories after QA.

## REPORT-018 disposition

Do not patch or rerender for language, style, historical test literals,
historical helper/manifest metadata, optional links, favicon, or minor cosmetic
observations. Record them as deferred. Return one complete PASS package if the
page renders, its scientific and structural contracts hold, and no material
display defect appears. Otherwise return one consolidated blocking defect
list.

No commit, push, upload, publication, later render, or broader integration
action is authorized. H04 and all later REPORT-018 targets remain held pending
independent H03 companion acceptance.
