# REPORT-018 owner order 61: H11 companion test link and target render

Date: 2026-08-22

Owner: H11 task `019fba59-0f3c-74a0-ab3d-58d389365ad1`

Scope: one preparation-test target correction, one H11 companion render, one
dedicated helper execution, one preparation-test execution, and complete
integration QA

Status: `SEALED_FOR_ONE_DISPATCH`

## Authority and result acceptance

The H11 result page is independently accepted under
`audit/report_harmonization/report018_h11_order60c_result_independent_acceptance.md`,
SHA-256
`383e8df225e6af343f1e8c7c3fb25c9281953e992e3f30ba829348ec4bd835ae`.
The owner 107-row completion manifest is exact, unique, and non-circular. An
independent R 4.6.1 replay passed all 14 result domains. The accepted result
QMD and HTML are fixed at
`7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`
and
`2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a`.

The complete companion preflight passed 11 of 11 domains using the durable
checker
`scripts/report_harmonization/check_report018_h11_order60c_acceptance_and_companion_preflight.R`,
SHA-256
`709c1b9d974da2e614bce1b96e3fdac62fbc185289f5268c03743fd46ea434fa`.
It found all integration transitions together before release. This order is
the single bounded companion completion pass.

The shared coordination matrix remains byte-identical at SHA-256
`c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac`,
42,552 bytes. Its H11 `active_order60_h11_result_target_render` token is a
checker invariant, not current execution authority. Order 61 activation is
recorded by its non-circular dispatch receipt. Do not edit the matrix during
owner execution.

## Fixed preflight identities

Before any edit or render, require all of the following:

- companion QMD
  `audit/hypotheses/H11/H11_analysis_preparation.qmd`, SHA-256
  `3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816`,
  54,527 bytes;
- stale canonical companion HTML
  `_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html`,
  SHA-256
  `fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11`,
  775,131 bytes;
- source-side historical companion HTML and support directory absent;
- preparation test
  `tests/hypotheses/H11/test_h11_preparation_report.R`, SHA-256
  `7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f`,
  10,562 bytes;
- dedicated helper
  `scripts/hypotheses/H11/build_h11_preparation_report_manifest.R`, SHA-256
  `317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8`,
  10,130 bytes;
- current 282-row preparation manifest
  `artifacts/12_manifests/H11/H11_preparation_report_manifest.csv`, SHA-256
  `00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c`,
  72,966 bytes;
- Stage 3 reader test
  `b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0`;
- REPORT-016 hourly-disposition test
  `3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b`;
- Stage 3 manifest
  `2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645`;
- handoff
  `5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289`;
- profile
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- lockfile
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`;
- sensitivity QMD and HTML
  `d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70`
  and
  `b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780`;
  and
- accepted result QMD and HTML exactly as stated above.

Require the Order 61 dispatch manifest exact and non-circular. Re-run the
central companion preflight and require its 11 of 11 PASS before applying the
test correction. Require no competing H11, Quarto, Pandoc, semantic-hook,
helper, or task-owned loopback process. Use the established narrowly elevated
read-only process inventory if the sandbox cannot inspect processes. Leave
unrelated processes untouched.

Record pre-render build, protected, scientific, critical-identity, and
user-owned Quarto Sass-cache inventories. Require zero symlinks below
`_build/nathealth`. Do not copy cache contents into the project.

## Exact preparation-test correction

Change only the unique source-link assertion in
`tests/hypotheses/H11/test_h11_preparation_report.R`:

```text
../../../notebooks/hypotheses/H11.html
```

to:

```text
../../../notebooks/hypotheses/H11.qmd
```

The exact required postimage is
`4c31cb4120fdb0530609906df707c161b875c0859a917de61f3baa1050d24180`,
10,561 bytes. Require exactly one changed line, R 4.6.1 parse, Air 0.4.1
format check without formatter mutation, scoped whitespace PASS, and raw-byte
reversal to the fixed preimage. No other test, source, helper, manifest, or
handoff line may change before the render.

Do not execute the preparation test before rendering and running the helper.
The full test has already passed prospectively with this exact correction,
the source-identical QMD state, and the truthful 283-row live inventory.

## Complete historical and prospective manifest contract

Before render, require the current 282-row preparation manifest to contain
exactly 276 live-exact rows and exactly these six accepted transitions:

1. `tests/hypotheses/H11/test_h11_stage3_reader_report.R`;
2. `audit/decisions/figure_readability_and_layout.md`;
3. `audit/hypotheses/H11/H11_analysis_preparation.qmd`;
4. `_build/nathealth/notebooks/hypotheses/H11.html`;
5. `notebooks/hypotheses/H11.qmd`; and
6. `_quarto-nathealth.yml`.

Require the helper's complete prospective path set to have exactly 283 unique
paths. Relative to the current manifest, the exact one added path must be
`tests/hypotheses/H11/test_h11_report016_hourly_disposition.R`, with no removed
path. Fail on any other addition, removal, duplicate, missing path, or seventh
pre-render mismatch.

## One companion target render

Create one fresh empty absolute semantic-audit directory under `/private/tmp`.
From the project root, invoke exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library \
quarto render audit/hypotheses/H11/H11_analysis_preparation.qmd --profile nathealth
```

Use narrow elevated filesystem access only if required for Quarto's normal
transactional use of the existing user-owned Sass cache under
`/Users/zauner/Library/Caches/quarto/sass`. Do not change `HOME`,
`XDG_CACHE_HOME`, `DENO_DIR`, the R library, the autoloader setting, the
target, or the profile. Do not delete, clear, replace, redirect, copy, rename,
chmod, or chown any cache file.

If the render fails, stop and seal the complete one-attempt state. Do not
retry, patch, bypass the profile, choose another cache, or render another
target.

## Successful-render integration

Only after render exit 0 and semantic-hook completion:

1. require a fresh canonical companion HTML and a source-identical build QMD;
2. require the source-side historical HTML and support directory to remain
   absent;
3. require semantic repair for exactly 26 native `gt` tables, exact reversal
   to the raw rendered HTML, exact reapplication to the accepted HTML, unique
   document IDs, and every scoped table-header token resolving exactly once
   inside its table;
4. require exactly three figure-image endpoints, one top-down Mermaid, all 26
   table endpoints in source order, nonempty captions and alt text, zero
   embedded errors or warning nodes, and no unresolved reference;
5. require all 20 relative-link occurrences to 17 unique targets and all 14
   source fragments to resolve, including reciprocal H11 result/preparation,
   H02 preparation, deviations, and paired source-data links;
6. run the dedicated helper exactly once, with no broad manifest builder;
7. require the helper to synchronize the authoring and build companion QMDs
   byte-for-byte and write exactly 283 unique, non-circular, live-exact rows,
   including the one newly discovered REPORT-016 test path;
8. run the corrected preparation test exactly once and require complete PASS;
9. require all accepted result identities, 193 scientific assets, helper,
   profile, lockfile, handoff, Stage 3 manifest, and sensitivity endpoints
   exact; and
10. classify only the companion HTML, source-identical build QMD, target-owned
    companion support files, direct 283-row preparation manifest, ordinary
    search/sitemap synchronization, the one preparation-test transition, the
    external semantic evidence, and bounded Order 61 evidence. Fail on any
    other project or build delta.

Do not run the helper or preparation test a second time. Do not edit a test or
source after the render. A failure at any point produces one sealed combined
stop.

## Required `$quarto-authoring` visual QA

Only after complete post-render integration PASS:

1. repeat the zero-symlink preflight;
2. serve only `_build/nathealth` from one unused high port bound to
   `127.0.0.1`;
3. inspect exactly
   `/audit/hypotheses/H11/H11_analysis_preparation.html` at 1,440 by 1,000,
   708 by 1,000, and 720 by 500;
4. inspect all 26 tables, three figures, the Mermaid, code disclosures,
   scrollers, captions, alt text, navigation, reciprocal links, deviations,
   and paired source-data links;
5. inspect all three exported figures at exactly 642 pixels or 170-mm final
   placement, requiring at least 7-point essential and minor text;
6. reject page overflow, clipping, overlap, missing content, broken
   interaction, privacy leakage, or page-attributable console warning or
   error;
7. close or reset the browser surface, stop the server, and prove no listener
   remains; and
8. require byte-identical build, protected, scientific, and critical
   inventories across QA.

One automatic favicon request may be classified nonblocking only if it has no
reader impact and produces no page-console warning or error.

## Writes, prohibitions, and mandatory stop

Authorized writes are limited to:

- the exact one-line preparation-test correction;
- the canonical H11 companion HTML and ordinary target-owned companion
  resources from the single render;
- the source-identical build companion QMD;
- the dedicated 283-row preparation manifest from the one helper execution;
- ordinary profile-owned `search.json` and `sitemap.xml` synchronization;
- the fresh external semantic directory; and
- bounded non-circular Order 61 render, test, manifest, semantic, structural,
  screenshot, visual-QA, lifecycle, and completion evidence under
  `audit/hypotheses/H11/report018_order61_companion_render/`.

No companion QMD, result QMD or HTML, source data, model, estimate, interval,
p-value, FDR decision, diagnostic, scientific artifact, Stage 3 manifest,
handoff, profile, package, lockfile, sensitivity file, ledger, or shared
configuration may change. No fit, refit, prediction, simulation, bootstrap,
resampling, scientific regeneration, result rerender, sensitivity execution,
later target, alternate render, full-project render, commit, push, or upload
is authorized.

Return one non-circular completion or one complete fail-closed stop. The
mandatory next stop is independent H11 result-and-companion acceptance. The
sensitivity battery and every later target remain held.
