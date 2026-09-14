# REPORT-018 H06 order 47d stopped record

Date: 2026-08-21
Owner: H06 hourly
Outcome: **STOPPED at the mandatory integration and figure-identity gates**
Scope: one H06 preparation companion render and target-owned integration

## Outcome

The sole authorized companion render exited 0, and the configured semantic
hook repaired all 30 native gt tables. The dedicated helper then exited 0,
synchronized the website QMD copy, and rebuilt a 411-row live-exact preparation
manifest. The unchanged full preparation test exited 1 on a stale literal-link
assertion. Safe post-render inspection also found that one of the three
regenerated companion PNGs no longer matched its accepted SHA-256 and byte pin.

No patch, second test run, second helper run, or second render was attempted.
Secure-loopback and final-size visual QA were not started because the mandatory
nonvisual acceptance gates did not pass.

## Controlling identities and preflight

- Order: `audit/report_harmonization/owner_orders/47d_h06_hourly_companion_render.md`,
  SHA-256 `fe25c05e3fb20b9a76c41bd2fd67810e9b2cf7845fb52ffc1b92cd01d0663523`.
- Dispatch manifest: SHA-256
  `9067ddc6607ea7e5f94fa7bb8d8259073137ac740a606ddcea9431e6dd052a47`.
- Central concurrence: SHA-256
  `cd9941b10481c04b7172ecad123273236e7e54d3c71ce9abccf835a037f8f390`.
- Central concurrence manifest: SHA-256
  `823f73451f3284ae696c1e6d5665394a9c4038cedaf108fd91f8a444c537d9dd`.
- Coordination matrix: dispatch evidence only, current SHA-256
  `e50de62b5882855f681d13d0561355155a1211797f5b8d3cde05fa701337541c`.
- Definitive R 4.6.1 preflight reproduced 36 of 36 dispatch hard rows and
  19 of 19 concurrence-manifest hard rows after excluding the matrix.
- All 34 companion R chunks parsed. Source contained exactly 30 table
  endpoints, three figure endpoints, and one top-down Mermaid.
- The 315-row pre-integration preparation manifest had exactly the sealed set
  of 20 historical mismatches and 295 live-exact rows.
- The pre-render build inventory contained 836 files and no symlink.

One preliminary temporary preflight verifier stopped on its own vectorization
error. The verifier alone was corrected, then the definitive preflight passed.
No project file or authorized once-only command was affected.

## Sole render and semantic repair

Command:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order47d_semantic.7o8aQn quarto render audit/hypotheses/H06/H06_analysis_preparation.qmd --profile nathealth
```

- Execution count: one.
- Exit status: 0.
- R: 4.6.1.
- Quarto: 1.9.37.
- Pre-hook HTML: SHA-256
  `e9e3fce00d1b37fae376aac380952987ca7c27f70ad7045a8cbf4613bd855259`,
  820,579 bytes.
- Final HTML: SHA-256
  `f9a4f51db555454a2e7cd0ea70895978b71016e6bd2c7310ae5033ad3c7ed378`,
  851,041 bytes.
- Semantic disposition: `REPAIRED`.
- Native gt tables: 30.
- Repaired IDs: 169.
- Repaired header references: 816.
- Reversible substitutions: 985.
- Ledger: 985 data rows, SHA-256
  `c2bc57a6606c0dfb118b8405cb153e044a8c96e4008609e0c8b40b12892b6100`.
- Summary: SHA-256
  `d520b2660419f896eb3733846e9347e0d254849bc31c2b9bdc5d9bd4032d8ecd`.
- Ledger reversal reconstructed the pre-hook HTML exactly, and reapplication
  reconstructed the final HTML exactly.

The render completed all companion chunks and Pandoc conversion. Three
dependency-discovery timing notes appeared at 59, 65, and 68 seconds. No
execution error or Pandoc resource warning appeared.

## Dedicated integration helper

Command:

```sh
Rscript --vanilla scripts/hypotheses/H06/build_h06_preparation_report_manifest.R
```

- Execution count: one.
- Exit status: 0.
- Output: `H06 preparation-report manifest completed: 411 files`.
- Authoring and website QMDs are byte-identical at SHA-256
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
  59,613 bytes.
- Rebuilt manifest: SHA-256
  `a3bd413daf9e154d78f32e49caea0697303c8d86ce387892ab081b06ae8b6bbc`,
  103,739 bytes and 411 unique rows.
- All 411 rows were live-exact after the helper. The manifest contains no
  self row. This owner seal was created afterwards and remains non-circular.
- The helper and unchanged test retained their accepted hashes.

## Mandatory test failure

Command:

```sh
Rscript --vanilla tests/hypotheses/H06/test_h06_preparation_report.R
```

- Execution count: one.
- Exit status: 1.
- Exact assertion failure:
  `grepl("../../../notebooks/hypotheses/H06.html", qmd, fixed = TRUE) is not TRUE`.
- Test line 56 still requires the retired literal `.html` source link.
- The accepted companion authoring source and byte-identical website copy use
  the dynamic Quarto `.qmd` target at lines 285 and 1625.
- The final HTML resolves both links to the existing accepted result HTML.
- The unchanged test remains SHA-256
  `2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc`.

The test did not reach its complete rendered-HTML branch. This violates the
order's mandatory test gate even though direct link resolution passed.

## Accepted PNG identity failure

Two companion PNGs remained exact. The response-distribution PNG did not:

- accepted SHA-256:
  `5cf25ad6cef9840e78a217ab083ca816105eacb37568ac788d3cd82c4bc31f46`;
- live SHA-256:
  `ab51417026d3b3edd9c0af7a455961b9e018cd0d4396bc6ba2f615ac98e7f7a1`;
- accepted bytes: 105,897;
- live bytes: 105,561; and
- accepted and live dimensions: 1920 by 1113 pixels.

This is the sole unexpected protected-content change. No attempt was made to
replace, regenerate, or visually adjudicate it after the failed nonvisual gate.

## Safe read-only post-render checks

Ten structural and protection checks passed:

- 411-row unique, live-exact, non-circular preparation manifest;
- byte-identical authoring and website QMDs;
- exact semantic ledger reversal and reapplication;
- 30 native gt tables, 2,807 unique document IDs, and 1,142 table-header
  tokens with zero unresolved or ambiguous references;
- exact source order for 30 table endpoints and three figure endpoints, one
  top-down Mermaid, nonempty captions, and nonempty figure alt text;
- 2,508 unique hrefs, including 2,505 internal hrefs, with zero missing
  targets, invalid fragments, forbidden local paths, or build paths;
- two companion-to-result links and one reciprocal result-to-companion link;
- exact `DEV-015`, `DEV-030`, `DEV-031`, and `DEV-032` targets;
- active `H06 preparation and provenance` navigation and all nine
  country-coded study sites; and
- zero embedded execution error, warning, stderr, unresolved cross-reference,
  or raw internal-path markers.

The check summary reports two failures: the PNG identity check and the
protected-path check caused by that same PNG. They are one underlying artifact
identity defect. Temporary read-only post-check code was corrected only for
its own data-table scoping and endpoint XPath logic. Its final run is retained.
No project source, rendered page, manifest, or artifact was changed by those
checker corrections.

## Build and protection reconciliation

- Build files: 836 before and 821 after.
- Added files: 0.
- Removed files: 15 target-local page-library copies under the companion's
  page-asset directory. All final internal links resolve through retained
  site libraries.
- Content changes: five, consisting of the companion HTML, synchronized
  website QMD, response-distribution PNG, `search.json`, and `sitemap.xml`.
- Mtime-only changes: 140, all content-identical.
- Unexpected build-path changes outside the allowed target-owned boundary: 0.
- Build symlinks: 0.
- Protected paths checked: 335.
- Expected protected changes: companion HTML, website QMD, and rebuilt
  preparation manifest.
- Unexpected protected change: only the response-distribution PNG described
  above.

The render also refreshed its target-owned Quarto support state outside the
website build tree. The retained postimages are `.quarto/xref/5b793063` at
SHA-256 `4581d250a68bea9c4f9e3eb9d79eb2a785fad6141448c6ddd367ac35fb43ad0a`,
the companion freeze record at SHA-256
`8e395cc805f552b9589501b748ef1c0164434ea8dc6d41c538db82c3166f4049`,
and the three freeze PNGs. The freeze PNG identities equal their website
counterparts, including the one failed response-distribution pin. No unrelated
Quarto support file has a render-time modification timestamp.

The accepted result and held H06-daily files remain exact:

- result QMD: `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`;
- result HTML: `8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa`;
- H06 contract: `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`;
- profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper: `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine: `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- lockfile: `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`;
- H06-daily result QMD: `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`;
- H06-daily companion QMD: `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`;
- H06-daily result HTML: `5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3`;
- H06-daily companion HTML:
  `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`.

## Stop boundary

No secure-loopback server was started, so no listener or browser surface
needed shutdown. No visual QA screenshot was created. No source, test,
scientific value, model, source CSV, stored scientific artifact, profile,
package, lockfile, central ledger, navigation, manuscript, or H06-daily file
was edited. No fit, refit, prediction, bootstrap, simulation, resampling,
inference recalculation, commit, push, upload, publication action, companion
rerender, result render, H06-daily render, later target, or full-project render
occurred beyond the single authorized companion render.

Order 47d is fail-closed pending coordinator disposition of the stale test
contract and the response-distribution PNG identity drift.
