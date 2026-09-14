# REPORT-018 owner order 43: H04 companion render

Date: 2026-08-20

Owner: H04 worker `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: **released as the sole serial render target**

## Authority and scheduling

The H04 result page is independently accepted by
`audit/report_harmonization/report018_h04_result_independent_acceptance.md`,
SHA-256
`de38edaf96fe13087a5b0f3199e906150f2e046c09f8ad7c275be74f34fcffd9`,
with 14-row non-circular manifest
`6e98e464ef78ef7b954949eac976a2dd4c969cb1321facaf353273f57ada1852`.
The accepted result HTML is
`da5f7f7195da843e46014d4796d35381f74d223ba79c37bb78fb8ce6dfa67c9f`.

REPORT-018 releases only the H04 preparation and provenance companion. Every
later render remains held. This is render-completion integration of accepted
source. Do not open a language, style, optional-link, historical-test, or
cosmetic cleanup loop.

The companion render must resolve the exact result-to-companion anchor
classified in
`audit/report_harmonization/report018_h04_order42a_held_companion_link_classification.md`,
SHA-256
`2abf48068f7364509c13fa2de4c6287ae0772d1b7fe3ea67c676c8fc54b4f987`.

## Hard preflight pins

Stop before execution if any owner-scoped pin differs:

- companion QMD:
  `efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`,
  91,202 bytes;
- held stale companion HTML:
  `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`,
  1,207,573 bytes;
- accepted result QMD:
  `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`,
  83,285 bytes;
- accepted result HTML:
  `da5f7f7195da843e46014d4796d35381f74d223ba79c37bb78fb8ce6dfa67c9f`,
  387,968 bytes;
- current stale website QMD copy:
  `28e44e527f1048cdd2b56cf2d7d7ed4b6a1faea5b8cd2c6765068fb2bf994d3d`,
  89,045 bytes;
- preparation manifest:
  `ba6164aa81a38d79670ddf7d89b7b9b17bfd8e906d45293c568f01c079c5d524`,
  63,415 bytes, 252 unique rows;
- preparation-manifest helper:
  `108842c73bf066fc33ae9f2ba3330893c332097572b5036a55f324e6947d5de7`,
  8,952 bytes;
- preparation test:
  `8a862e0acece4d77392647a55df4f659410fbc94e2fc6ae40b642c47c2184935`,
  14,036 bytes;
- source harmonization test:
  `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`;
- participant stored-output test:
  `247523ec05b484e161e2717a21d33314375370b84413a3bbcfb150582b86ad90`;
- H04 handoff:
  `99de6fd036b7e7c52a55406615642024092e3177317255101c4a5db1ff391036`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- `renv.lock`:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

The accepted companion source contains exactly 37 unique table endpoints,
four unique figure endpoints, one top-down Mermaid, and the explicit
`sec-h04-prep-participant-random-intercept` anchor exactly once. Reinventory
the complete build and H04 protected set and require zero symlinks before
execution.

## Sole render

Create one fresh absolute empty semantic-audit directory under `/private/tmp`
with mode 0700. Run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-directory> quarto render audit/hypotheses/H04/H04_analysis_preparation.qmd --profile nathealth`

Use normal R 4.6.1 project and renv startup with
`sandbox_permissions=require_escalated`, or the exact narrow task-equivalent
permission that permits transient writes only to the existing user-owned renv
cache. Preserve `.Rprofile` and `renv/activate.R`. Do not run a preliminary
test, startup probe, or dry run. Do not render the result page, another page,
or the full project.

The companion may read and display accepted stored artifacts. It must not fit
or refit a model, predict, simulate, bootstrap, resample, recompute
multiplicity, regenerate a scientific artifact, or change a scientific value.

## Bounded companion integration

If and only if the render exits 0 and the semantic hook succeeds, run the
unchanged helper exactly once under R 4.6.1:

`Rscript --vanilla scripts/hypotheses/H04/build_h04_preparation_report_manifest.R`

The helper may only copy the accepted authoring companion QMD byte-for-byte to
the existing website QMD path and rebuild
`artifacts/12_manifests/H04/H04_preparation_report_manifest.csv`. Require the
website QMD to equal the authoring QMD exactly. Require one unique live-exact
manifest row for every declared path. Record the exact new row count and
identity. No broad or shared manifest builder is authorized.

Then run exactly once:

`Rscript --vanilla tests/hypotheses/H04/test_h04_preparation_report.R`

The complete test must pass against the fresh companion HTML, source-identical
website QMD, current result page, and rebuilt manifest. Do not edit the helper,
test, QMD, HTML, or manifest manually. Stop on any failure without a retry or
patch.

## Static acceptance

Require:

- semantic disposition `REPAIRED` or a proven already-repaired state;
- exactly 37 native gt tables, four figures, and one top-down Mermaid in the
  accepted order, with all captions and alt text present;
- zero duplicate document IDs, every explicit `headers` token resolving once
  to the intended header within its own table, and zero unsupported ID refs;
- the explicit participant-random-intercept anchor present exactly once;
- the accepted H04 result link resolving to that anchor;
- reciprocal result and companion links, deviation anchors, active
  navigation, country-coded sites, source-data links, and zero unresolved
  internal reader links;
- zero embedded error, warning, or stderr nodes;
- accepted result QMD and HTML, both authoring QMDs, profile, semantic tools,
  helper and test sources, handoff, and all scientific artifacts unchanged;
  and
- every build delta classified as target companion HTML, source-identical
  website QMD, target-owned page assets, normal search or sitemap output, or
  the explicitly rebuilt H04 preparation manifest. Fail on any unclassified
  change.

## Secure-loopback visual QA

After nonvisual gates pass, preflight zero symlinks and start one read-only
static server rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1`. Inspect only
`audit/hypotheses/H04/H04_analysis_preparation.html` at 1440 by 1000, 708 by
1000, and a 200-percent-equivalent viewport.

Inspect all 37 tables, all four figures, the top-down Mermaid, callouts,
disclosures, headings, captions, alt text, links, and navigation. HTML tables
must be usable at typical desktop or laptop width. Narrow tables may use
contained horizontal scrolling. Stored PNGs control exported final-size
figure acceptance. Check typography, labels, legends, axes, wrapping,
clipping, overlap, and page overflow.

Stop the server, prove no listener remains, reset the viewport, close QA tabs,
and prove post-QA source, profile, protected, and build stability.

## Return and prohibitions

Return one companion acceptance package or one combined fail-closed defect
list. Do not patch or rerender inside this order. No result rerender, later
render, source edit, model execution, scientific artifact change, profile,
package, lockfile, ledger, manuscript, broad-manifest, commit, push, upload,
deletion, or publication action is authorized.
