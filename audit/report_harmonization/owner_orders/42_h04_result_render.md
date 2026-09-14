# REPORT-018 owner order 42: H04 result render

Date: 2026-08-20

Owner: H04 worker `019febf4-4868-72f3-bd97-31a85e86f8f0`

Status: **released as the sole serial render target**

## Authority and scheduling

H03 result and companion integration is independently accepted by
`audit/report_harmonization/report018_h03_companion_independent_acceptance.md`,
SHA-256
`745a2c933b2c41450a957630f650790e04f8d17ca1e484145b7a0c1618eebb7d`,
with 19-row non-circular manifest
`bb5ead573fbe23900f9ec7f435a1764743caef17355c5101f20d2bd545ac6a59`.

REPORT-018 now releases only the H04 result page. The H04 companion and every
later target remain held. This is render-completion integration of the already
accepted source. Do not open a language, style, optional-link,
historical-test, or cosmetic cleanup loop.

The dispatch-time coordination matrix is
`fa9146da6f288c18f0159d5706e7bd826d258562187b64a53b8345995a613c80`.
It is coordination evidence, not a mutable global hard pin for owner
execution.

## Hard preflight pins

Stop before rendering if any owner-scoped pin differs:

- H04 result QMD:
  `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`,
  83,285 bytes;
- held H04 companion QMD:
  `efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`,
  91,202 bytes;
- stale result HTML:
  `cad724ca28c651db62f2bb11a51d0d53adbf133785a6d9477f600900269e3cbe`,
  380,116 bytes;
- held companion HTML:
  `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`,
  1,207,573 bytes;
- accepted source test:
  `tests/hypotheses/H04/test_h04_report017_source_harmonization.R`,
  `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`,
  33,144 bytes;
- participant random-intercept stored-output test:
  `247523ec05b484e161e2717a21d33314375370b84413a3bbcfb150582b86ad90`,
  9,022 bytes;
- Stage 3 reader test, retained as historical/current execution context:
  `53a5d68b3f56856c20824c43a4703f208bd0984cd81a443fab7111b07e783e17`,
  23,170 bytes;
- Stage 3 artifact manifest:
  `6215a9496f5f542ff92c19536b5601aa49c1ca804523eb7f9ff8bfdff852e115`;
- reader asset manifest:
  `b7963a6bf11617ea4831ce8e53baaf1e9d6746a0bd147ca866cd1fbbb8901be3`;
- reader derivation manifest:
  `fc75b0a25eccff2028194de8ed9a2e9bcc7744254cdc2f5c38ec31b59e880582`;
- H04 handoff:
  `99de6fd036b7e7c52a55406615642024092e3177317255101c4a5db1ff391036`;
- source-only acceptance:
  `085d974c4c7d8d905434777612befe12f47e8cfd7910da607a1f42f3c5208101`;
- source-only acceptance manifest:
  `417e6a16deb8aab4a05be30f92be3a0b1c303533f6635771c3e3a6e6a9b3b44a`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.

The current build preflight contains 836 files and zero symlinks. Reinventory
the complete build and the H04 protected scientific set before rendering.
Central ledger and coordination records may advance concurrently and must be
classified separately from owner scope.

## Pre-render checks

Under R 4.6.1, rerun only the accepted H04 source harmonization test and the
participant random-intercept stored-output test. Both must pass. Confirm the
source contains exactly 17 table endpoints and seven figure endpoints, with
`fig-h04-primary-estimates` the first figure and
`tbl-h04-primary-results` the first table.

Do not edit a test or source because a historical build-side pin is stale.
Under REPORT-018, retain such a pin as historical evidence and verify the
fresh page directly. Stop only for a current source, scientific, execution,
semantic, missing-output, or unresolved internal-link defect.

## Sole render

Create one fresh absolute empty semantic-audit directory under `/private/tmp`,
mode 0700, and run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-directory> quarto render notebooks/hypotheses/H04.qmd --profile nathealth`

Use normal R 4.6.1 project/renv startup and only the established narrow access
to the user-owned renv cache. Do not render the H04 companion, another page,
or the full project.

The reader page may read and format accepted stored artifacts. It must not fit
or refit a model, predict, simulate, bootstrap, resample, recompute
multiplicity, regenerate a scientific artifact, or alter a scientific value.

## Post-render acceptance

Require:

- exit 0 and semantic disposition `REPAIRED` or a proven already-repaired
  state;
- exactly 17 native gt tables and seven figure endpoints in accepted order;
- zero duplicate document IDs, every explicit `headers` token resolving
  exactly once within its own table, and no unsupported ID references;
- the accepted principal figure and table first in their endpoint classes;
- reciprocal result and companion links, registration and deviation anchors,
  navigation, country-coded sites, source-data links, and zero unresolved
  internal reader links;
- no embedded error, warning, or stderr node;
- both H04 sources, held companion HTML, profile, semantic tools, tests,
  manifests, handoff, and the full protected scientific set byte-identical;
- build content changes confined to the H04 result HTML, normal search and
  sitemap outputs, and source-identical target resources. A source-identical
  build QMD, byte-identical framework duplicate, directory metadata change,
  or exact noncanonical relocation of historical untracked output is
  nonblocking when recorded and when the canonical reader target is correct.
  Fail on any unexplained content change.

Do not run a broad manifest builder. Do not reseal historical H04 manifests
inside this result-render order.

## Visual acceptance

After static gates pass, serve only `_build/nathealth` through one read-only
HTTP server bound to `127.0.0.1` after a zero-symlink preflight. Inspect only:

`notebooks/hypotheses/H04.html`

Check 1440 by 1000, 708 by 1000, and 200-percent-equivalent layouts. Inspect
all 17 native tables and all seven figures. HTML tables must be usable at a
typical desktop/laptop width; narrow tables may use contained horizontal
scrolling. For exported figures, the stored PNG versions are the controlling
final-size check. Inspect labels, legends, axes, captions, callouts,
navigation, disclosures, wrapping, clipping, overlap, and page overflow.

Stop the server, prove no listener remains, reset the viewport, close QA tabs,
and prove post-QA source, profile, protected, and build stability.

## Return and prohibitions

Return one complete acceptance package or one combined fail-closed defect
list. Do not patch or rerender within this order. Defer nonblocking language,
style, optional-link, historical-test, and cosmetic findings.

No source edit, companion render, later render, full project render, model
execution, scientific artifact change, profile, package, lockfile, ledger or
manuscript edit, broad manifest build, commit, push, upload, or publication is
authorized.
