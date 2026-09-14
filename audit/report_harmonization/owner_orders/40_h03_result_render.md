# REPORT-018 owner order 40: H03 result render

Date: 2026-08-20

Owner: H03 worker `019fbe52-c067-7521-b2cf-62d9398d173b`

Status: **released for exactly one H03 result render**

## Scheduling authority

REPORT-018 prioritizes successful integration of the remaining reader-facing
Quarto pages and prohibits a new language, style, optional-link, test-literal,
or cosmetic cleanup loop. H02 result and companion integration is accepted.
This order releases only the H03 result page. The H03 companion and every
later target remain held.

The dispatch-time coordination matrix identity is SHA-256
`287dc360fb738c2802a0e2f6586fda08583374da4ac2c03a3e1b08d58bcbc33e`.
This identity is coordination evidence, not a mutable owner execution pin.

Controlling completed H02 acceptance:

- `audit/report_harmonization/report018_h02_companion_independent_acceptance.md`,
  SHA-256
  `d3334682d6f71dc65f0d12dd929feb36932faa8c98c8d8a4b1e081a08089aee5`;
- `audit/report_harmonization/report018_h02_companion_acceptance_manifest.csv`,
  SHA-256
  `122fae1bb59f7ab245236320b797a13341a75019db24d682556da56048316bc9`.

## Hard preflight pins

Stop before rendering if any of these identities differ:

- result QMD `notebooks/hypotheses/H03.qmd`:
  `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41`,
  68,198 bytes;
- held companion QMD
  `audit/hypotheses/H03/H03_analysis_preparation.qmd`:
  `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131`,
  75,638 bytes;
- accepted source test
  `tests/hypotheses/H03/test_h03_report017_source_harmonization.R`:
  `1783acab381999fb123b8a7d11873b42e8b331f0c684ad65585e69ce41febd51`,
  26,503 bytes;
- auxiliary stored-output test
  `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R`:
  `30fa488114886eb4e9feeccc55f6f752e229585bfc1f2eb5b5a85bfba582bfc8`,
  7,568 bytes;
- H03 handoff `audit/handoffs/H03_worker_handoff.md`:
  `49beea589f5709e598975703f2bed4337e203c40a1ec64d4e218be4eda4a6a48`,
  30,095 bytes;
- source acceptance
  `audit/report_harmonization/report017_h03_order34a_source_independent_acceptance.md`:
  `611282cd186a9645936e2f5862f657be380a7259b2717b832edbe818fd835852`;
- 18-row source acceptance manifest
  `audit/report_harmonization/report017_h03_order34a_source_acceptance_manifest.csv`:
  `c9ab4292ba18cbc1afae3d4dba80e179307c7f153eb52dded6be1f393111e9be`;
- profile `_quarto-nathealth.yml`:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- post-render wrapper
  `scripts/report_harmonization/post_render_gt_html_semantics.R`:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic repair engine
  `scripts/report_harmonization/repair_gt_html_semantics.R`:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H03.html`:
  `68aa07eb7470286d0d6da76114ce7bf346ee635974fe7403c1860ad4560c3d25`,
  330,938 bytes;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H03/H03_analysis_preparation.html`:
  `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`,
  900,339 bytes.

The harmonizer independently reran both accepted H03 source tests through the
normal project profile under R 4.6.1 immediately before dispatch. Both passed,
and no QMD was executed.

## Scientific and source boundary

The result render may read and format the already accepted H03 artifacts. It
must not fit or refit a model, calculate new inference, predict, bootstrap,
simulate, recompute Shapley or dominance allocations, regenerate a scientific
artifact, or change a scientific value.

Preserve the distinction between the population-mean quasi-Tweedie
within-/between-participant sensitivity and the descriptive auxiliary
participant random-intercept assessment. The latter remains supplementary,
model-dependent evidence. `fig-h03-primary-estimates` and
`tbl-h03-primary-results` remain the provisional principal H03 outputs.

Do not edit any QMD, test, handoff, manifest, profile, package, lockfile,
ledger, manuscript, source data, table, figure, model, or scientific artifact.
Do not run a broad manifest builder. The current Phase 4 corpus manifest and
the historical H03 Stage 3 and preparation manifests remain unchanged until
the final integrated corpus audit.

The historical
`tests/hypotheses/H03/test_h03_stage3_reader_report.R` is not a controlling
order-40 test because its all-row manifest branch pins pre-harmonization
source and HTML identities. Preserve it byte-for-byte and do not edit it.
Current source and rendered-output acceptance is instead controlled by the
accepted order-34a source test, the protected scientific inventory, and the
fresh order-40 HTML audit below.

## Pre-render evidence

Before the command:

1. Rehash every hard pin.
2. Record complete protected H03 scientific, source, profile, and accepted
   H02/Supplementary identities.
3. Inventory the complete `_build/nathealth` tree, including path, type,
   SHA-256, bytes, permissions, and modification time.
4. Preflight the build tree for symlinks. Stop if any symlink resolves outside
   `_build/nathealth`.
5. Create one fresh empty absolute semantic-audit directory with `mktemp -d`
   under `/private/tmp` and retain it through independent acceptance.

## Sole render command

Run exactly once through the normal R 4.6.1 project profile and renv startup,
using only the established narrow access to the existing user-owned renv
cache:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H03.qmd --profile nathealth
```

Do not use `--no-execute`, bypass `.Rprofile` or `renv/activate.R`, render the
companion, render another target, or render the full project.

## Required nonvisual acceptance

After the one render:

1. Require exit 0 and semantic-hook disposition `REPAIRED` for the exact H03
   result HTML.
2. Retain the external summary and reversible ledger. Verify the ledger's
   recorded pre/post hashes, reverse the durable HTML to the exact pre-hook
   identity, and require normalized DOM and visible text to remain unchanged
   across the semantic repair.
3. Require document-wide unique IDs. Every explicit `headers` token must
   resolve exactly once within its own native table to the intended header.
   Reject dangling or unsupported ID references.
4. Require exactly 14 native gt table endpoints and eight figure endpoints in
   the accepted source order. Require one nonempty Quarto-owned caption per
   endpoint, complete figure alt text, all intended source-data links, and no
   competing renderer or caption.
5. Require `tbl-h03-primary-results` and `fig-h03-primary-estimates` to be the
   first result table and figure endpoints. Preserve all accepted values,
   notes, FDR decisions, formulas, output roles, and qualifications.
6. Run the unchanged order-34a source harmonization test and the unchanged
   auxiliary stored-output test under R 4.6.1. Both must pass.
7. Verify the five H03 result links to five unique preregistration-deviation
   anchors, the dynamic result-to-companion link and anchor, Supplementary
   information, active navigation, external-link classification, all source
   downloads, and every internal target and anchor. No `file:`, `_build`,
   absolute local path, unresolved cross-reference, raw error, warning, or
   stderr node may appear.
8. Require all nine study sites to use the accepted country-coded labels.
9. Rehash the complete protected inventory. Both QMDs, the held companion
   HTML, all scientific artifacts, tests, handoff, profile, semantic tools,
   H02 accepted pages, packages, lockfile, and ledgers must remain
   byte-identical, apart from separately identified concurrent
   coordinator-owned records.
10. Classify the complete build delta. Authorized content changes are the H03
    result HTML, normal `search.json` and `sitemap.xml` updates, and
    source-identical target QMD or target-owned asset refreshes produced by the
    exact render. Fail on any unclassified content change. Record
    byte-identical mtime-only framework touches separately.

## Secure-loopback visual acceptance

If the nonvisual gates pass:

1. Serve only `_build/nathealth` through one temporary read-only static server
   bound only to `127.0.0.1` on an unused high port.
2. Navigate only to the exact H03 result route in the in-app Browser.
3. Inspect the complete page at 1440 x 1000, 708 x 1000, and a
   200-percent-equivalent viewport.
4. Inspect all 14 native tables at ordinary desktop size. At narrow width,
   wide tables may use a contained, working horizontal scroller, but the page
   itself must not overflow.
5. Inspect all eight figures at final displayed size. Inspect every exported
   PNG at its intended final-size equivalent or native output size. Give
   particular attention to the principal table and figure, participant
   random-intercept table, temporal figures, diagnostic figures, latitude
   figure, and paired-placement figure.
6. Check typography, axes, legends, symbols, labels, panels, captions, alt
   text, disclosures, callouts, navigation, link usability, wrapping,
   clipping, overlap, and page overflow.
7. Stop the server, prove no listener remains, reset the viewport, close the QA
   tab, and prove post-QA source, profile, protected, and build stability.

## REPORT-018 disposition rule

Return one complete acceptance package or one consolidated fail-closed defect
list. Do not patch or rerender within this order.

Stop acceptance for a render or startup error, scientific or protected-input
drift, missing target or required endpoint, broken semantic accessibility,
unresolved required internal link, embedded execution error, or material
display/usability defect.

Record language, style, optional-link, historical-test-literal, favicon, and
minor cosmetic findings as `DEFERRED_NONBLOCKING` and complete the integration
when every controlling render, semantic, protection, link, and usability gate
passes. Do not open a cleanup loop for such findings.

## Prohibitions

No source edit, scientific recomputation, artifact regeneration, companion or
later render, full-project render, broad manifest builder, profile, package,
lockfile, ledger, manuscript, or shared configuration change, commit, push,
upload, or publication is authorized.

The H03 companion and every later REPORT-018 target remain held pending
independent acceptance of this result page.
