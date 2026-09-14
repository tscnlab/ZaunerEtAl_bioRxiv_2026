# REPORT-018 owner order 47d: H06 hourly preparation companion render

Date: 2026-08-21  
Owner: H06 hourly  
Scope: one preparation/provenance companion render and target-owned integration  
Status: sealed for central concurrence before dispatch

## Controlling acceptance

The H06 hourly result is independently accepted under:

- `audit/report_harmonization/report018_h06_result_independent_acceptance.md`
  at SHA-256
  `1e5097504278defa98cbc42cc6798d85926cb525316886c12d4cf8f3c7f8f7a1`,
  5,097 bytes; and
- `audit/report_harmonization/report018_h06_result_independent_acceptance_manifest.csv`
  at SHA-256
  `920d3b384046231d3d404f41fbf61cc2504583bbd1b0e5769fbe8f2fa9c1f32f`,
  3,459 bytes, with 21 exact unique non-circular rows.

Accepted result identities:

- source
  `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`,
  60,791 bytes;
- HTML
  `8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa`,
  4,874,263 bytes; and
- H06 contract
  `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`,
  13,468 bytes.

These files are protected. The result page must not be rerendered.

## Current companion boundary

Hard current pins:

- authoring source
  `audit/hypotheses/H06/H06_analysis_preparation.qmd`, SHA-256
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
  59,613 bytes;
- stale companion HTML
  `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html`,
  SHA-256
  `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`,
  771,694 bytes;
- stale website QMD copy
  `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.qmd`,
  SHA-256
  `a4b35a1997fdae48b2e751d31a70147bd4149354eddd2a703d6473abbc67ea97`,
  50,898 bytes;
- preparation test
  `tests/hypotheses/H06/test_h06_preparation_report.R`, SHA-256
  `2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc`,
  12,918 bytes;
- dedicated integration helper
  `scripts/hypotheses/H06/build_h06_preparation_report_manifest.R`, SHA-256
  `bc53e754478a3fa17de0aaf498aea8720d58b958949050f7447d25c5ec23e2fb`,
  9,615 bytes; and
- current preparation manifest
  `artifacts/12_manifests/H06/H06_preparation_report_manifest.csv`, SHA-256
  `db976477b9cdbce2a6d4575e382b2f04062e8834c086f1d82cb25d7e8a2176e4`,
  78,784 bytes and 315 unique rows.

Static R 4.6.1 preflight parses all 34 companion R chunks and finds exactly
30 unique `tbl-h06-prep-*` endpoints and three unique
`fig-h06-prep-*` endpoints. The accepted source-only order-37a verification
remains controlling for formulas, scientific values, links, artifact reads,
and the no-fit/no-write execution boundary.

The current 315-row preparation manifest has exactly 20 live mismatches. They
are the accepted result/profile/base-input/figure and source-only transitions
accumulated before companion integration:

1. accepted result HTML;
2. current profile;
3. eleven refreshed H06 reader figure PDF/PNG/SVG files;
4. current H06 Stage 3 artifact manifest;
5. current base-model-data manifest;
6. companion authoring source;
7. accepted result source;
8. two accepted H06 figure builders; and
9. the accepted H06 contract.

Require exact set equality for these 20 paths and exact live identities for
the other 295 rows before rendering. This mismatch set is expected historical
manifest state, not permission to change any scientific artifact.

## Preflight

Before execution:

1. reproduce every hard row in
   `audit/report_harmonization/report018_h06_order47d_dispatch_manifest.csv`;
2. treat the coordination matrix as dispatch-time evidence only;
3. require no active Quarto, Pandoc, H06 semantic, or competing render process;
4. require zero symlinks under `_build/nathealth`;
5. create complete pre-render inventories for the build tree, the 315-row
   preparation manifest, the accepted result, the companion source and target,
   all H06 scientific inputs and artifacts, and the shared profile and lock;
6. create one fresh absolute empty semantic-audit directory under
   `/private/tmp`; and
7. stop before execution on any drift outside the exact 20-path historical
   mismatch set.

Do not edit the companion QMD, helper, test, profile, contract, manifest, or
any artifact before the target render.

## Sole target render

Run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H06/H06_analysis_preparation.qmd --profile nathealth
```

Use the normal R 4.6.1 project profile and renv startup, with only the
established narrow access to the existing user-owned renv cache. The
configured semantic hook must run normally. Do not use `--no-execute`, bypass
the hook, render the result, render H06 daily, render another target, or render
the full project.

The companion may read only its accepted stored inputs and format them. No
model fit or refit, prediction, bootstrap, simulation, resampling, influence
recalculation, scientific artifact regeneration, or source-data rewrite is
authorized.

## Target-owned integration

If and only if the render exits 0 and the semantic hook succeeds:

1. run
   `scripts/hypotheses/H06/build_h06_preparation_report_manifest.R` exactly
   once under R 4.6.1;
2. allow that dedicated helper to synchronize only the authoring companion
   QMD to its existing website QMD path and to rebuild only
   `artifacts/12_manifests/H06/H06_preparation_report_manifest.csv`;
3. require authoring and website QMDs to be byte-identical at the accepted
   `f952d5ec...` identity;
4. require the rebuilt manifest to contain unique, live-exact, non-circular
   rows for the complete dedicated H06 preparation inventory;
5. preserve the helper and test byte-for-byte;
6. do not run any broad worker, Stage 3, phase-4, or project manifest builder;
   and
7. run the unchanged complete preparation test exactly once after helper
   integration:

```sh
Rscript --vanilla tests/hypotheses/H06/test_h06_preparation_report.R
```

The normal project library may be supplied explicitly without changing the
profile or lockfile. The test must pass through its full rendered-HTML branch.

## Required nonvisual acceptance

Require all of the following:

1. exactly 30 native gt tables, three figure endpoints, and one top-down TD
   Mermaid in the accepted source order;
2. every table and figure has its intended caption, note, alt text, values,
   rows, columns, labels, and source-data relationship;
3. the semantic hook reports `REPAIRED` or `ALREADY_REPAIRED` as structurally
   appropriate and retains its external summary and reversible ledger;
4. document IDs are unique, every explicit table `headers` token resolves
   exactly once within its own table to the intended `th`, and no unsupported
   ID reference remains;
5. exact reciprocal result/companion links, all declared deviation targets and
   anchors, active `H06 preparation and provenance` navigation, all nine
   country-coded study sites, and no forbidden local or build-path link;
6. no embedded execution error, warning, stderr node, unresolved
   cross-reference, or raw internal path;
7. all three companion figure PNGs match the accepted physical-size QA pins in
   `H06_preparation_figure_readability_qa.csv`, including their dimensions and
   SHA-256 identities;
8. the accepted result QMD and HTML, H06 contract, all scientific inputs and
   artifacts, profile, semantic tools, package lock, H06 daily files, and every
   unrelated source and build member remain byte-identical; and
9. the build delta is confined to the companion HTML, byte-identical website
   QMD copy, target-owned figure/page assets, search and sitemap, and any
   source-identical or mtime-only framework refresh classified separately.

Resource-fetch, favicon, optional-font, language, style, stale-test, and other
nonblocking cosmetic observations are recorded and deferred under REPORT-018
if all actual internal targets resolve and no warning is embedded in the page.
They do not authorize a source edit or rerender.

## Secure loopback visual QA

After nonvisual acceptance:

1. preflight `_build/nathealth` again for symlinks;
2. serve exactly that directory read-only on one unused high port bound only to
   `127.0.0.1`;
3. inspect only the exact H06 companion route at 1440 by 1000, 708 by 1000,
   and 720 by 500 as the 200-percent-equivalent view;
4. inspect all 30 tables, all three figures, the TD Mermaid, headings,
   callouts, captions, links, navigation, wrapping, clipping, overlap, and
   page overflow;
5. apply the accepted table policy: desktop and laptop usability control the
   HTML table check, while a narrow table may use a visible contained
   horizontal scroller without page overflow;
6. inspect the three exported PNGs directly at their controlling 170-mm final
   size for titles, axes, legends, site labels, symbols, panels, units,
   clipping, overlap, and typography of at least 7 points;
7. record screenshots and measurements;
8. stop the server, prove no listener remains, close/reset the QA surface, and
   rehash the complete build and protected inventories.

## Return and prohibitions

Return one complete acceptance package or one consolidated fail-closed defect
list. Do not patch or rerender within this order if a genuine source,
scientific, semantic, protection, or display defect appears. Finish all safe
read-only inspection before returning.

No source, scientific value, model, artifact, profile, package, lockfile,
central ledger, manuscript, catalog, navigation, commit, push, upload, or
publication change is authorized. H06 daily and every later REPORT-018 target
remain held pending independent companion acceptance.
