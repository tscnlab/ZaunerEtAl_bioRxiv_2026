# REPORT-018 order 58: H10 result test reconciliation and result render

Date: 2026-08-22

Owner: H10 owner `019fdc1b-b77b-7972-aed0-784da328e115`

Status: released for one exact result-test reconciliation and exactly one H10
result-page render. The H10 companion, H11, and every later target remain held.

## Controlling acceptance and complete preflight

H10 order 32 source-only work is independently accepted:

- `audit/report_harmonization/report018_h10_order32_source_independent_acceptance.md`,
  SHA-256 `a31196756f10b80b88ce9433dd3bffc7d897b688cfe7b78cf2446aa553b88ba4`,
  5,185 bytes;
- its 25-row non-circular manifest, SHA-256
  `8f3767d9505d3a13c5c0fbb6320d826f38b1d31a64e2f7f4c2d8302165b81522`,
  4,299 bytes; and
- the independent R 4.6.1 checker
  `scripts/report_harmonization/check_report018_h10_order32_source_acceptance_and_result_preflight.R`,
  SHA-256 `2d1ee55525da9717b506d6a1d38c32ae66fdd1e53cbb82af698da5c8d7c428ed`,
  28,936 bytes.

The checker passed 31/31 contracts: four exact reverse proofs, 24 result and
23 companion chunks, both source tests, 21 immutable dispatch members, eight
live historical planning rows plus the exact four authorized transitions,
57/57 scientific assets, and the complete prospective result test.

Before execution, reproduce this order, the complete dispatch manifest, and
every non-matrix hard pin. The coordination matrix is dispatch-time evidence
only. It will change when this order is released and must not be treated as an
owner execution pin. Do not rerun the central checker after that expected
matrix transition.

## Frozen page, companion, and environment identities

Require these exact pre-execution identities:

- result QMD `notebooks/hypotheses/H10.qmd`, SHA-256
  `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d`,
  49,224 bytes;
- held companion QMD
  `audit/hypotheses/H10/H10_analysis_preparation.qmd`, SHA-256
  `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`,
  58,446 bytes;
- current result test
  `tests/hypotheses/H10/test_h10_stage3_reader_report.R`, SHA-256
  `803f4139c6c99b56e49ed160b1ae644244a7ac8acbfa80328e7945eb326242f1`,
  23,710 bytes;
- held companion test
  `tests/hypotheses/H10/test_h10_preparation_report.R`, SHA-256
  `15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4`,
  15,201 bytes;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H10.html`,
  SHA-256 `6bd3da932b7f743c2c28b2b5abe7a3772fc2ee6587c75f6fff1dca8910332c84`,
  315,514 bytes;
- held companion HTML at both canonical build and source-side paths, SHA-256
  `efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8`,
  617,113 bytes each;
- historical Stage 3 manifest, SHA-256
  `b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e`,
  147,622 bytes;
- held preparation manifest, SHA-256
  `091c2661020dce63826ea7a21745dd3a1328681f343ba256b04f852b9fef518c`,
  170,241 bytes;
- H10 handoff, SHA-256
  `70f4b211d329f893ce5f75ac3e494e634546e160f96761509259f7ba6518087f`;
- normal profile, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper and engine, SHA-256 `28c11058...` and `7c949930...`;
- `renv.lock`, SHA-256 `3bf99c63...`; and
- held H11 result source, SHA-256
  `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`.

Use R 4.6.1, Quarto 1.9.37, and the accepted project library at
`renv/library/macos/R-4.6/aarch64-apple-darwin23`.

## Exact result-test reconciliation

The result test has five masked REPORT-017-era classifications. Replace only
`tests/hypotheses/H10/test_h10_stage3_reader_report.R` with the exact accepted
prospective postimage retained at:

- `audit/report_harmonization/report018_h10_order32_source_acceptance/prospective_test_h10_stage3_reader_report.R`;
- SHA-256 `ad792acdb7c9d2fe9290a6837a2a3c994811d7f5c9a64eaea01b0edd9f9b4db1`;
- 25,796 bytes.

The actual result test must become byte-identical to that evidence file. Prove
the exact reverse to `803f4139...` and retain a zero-context diff. The only
permitted hunks are:

1. accepted FDR wording in QMD and HTML assertions;
2. the current near-eye sensor-position context assertion;
3. the current `Core residual checks` heading assertion;
4. the current remaining-gap definition and its proximity check;
5. positive rendered-page biological-sex/gender assertions and the two false-
   phrase prohibitions; and
6. the exact six-path historical-to-live Stage 3 manifest classifier.

The historical Stage 3 manifest remains byte-identical. Before render it has
exactly five mismatches: result QMD, companion QMD, result test, companion
test, and profile. After render it must have exactly those five plus result
HTML. The postimage test must fail on a seventh mismatch. Its own live identity
is pinned by this order and the owner completion seal, not recursively inside
the test.

Do not edit or execute the companion test. Do not edit or rebuild either H10
manifest.

## Complete pre-render gate

After the exact test postimage is in place and before rendering:

1. Rehash every non-matrix dispatch member and require exact agreement.
2. Parse the 24 result R chunks without executing the QMD and parse the exact
   postimage result test.
3. Require exactly 15 unique native `tbl-*` endpoints and eight unique
   `fig-*` endpoints in source order.
4. Require all 26 relative Markdown-link occurrences and 24 unique targets,
   including the reciprocal companion QMD target, Preparation 04 and 06, and
   DEV-003, DEV-040, and DEV-041.
5. Require the accepted biological-sex and gender wording, the exact five
   Wilkinson formulas, four complete 17-test FDR families, and all scientific
   contracts already replayed by the central checker.
6. Require zero model fitting, refitting, prediction, simulation, bootstrap,
   resampling, p-value recalculation, or scientific-artifact writing calls.
7. Rehash all 57 scientific display assets and the accepted demographics,
   model-frame, model-manifest, and Stage 1 pins.
8. Require the historical Stage 3 manifest to have exactly its five accepted
   pre-render transitions and all other 203 rows live-exact.
9. Inventory the complete `_build/nathealth` tree and protected H10 scope.
   Require zero build symlinks.
10. Confirm no competing Quarto, Pandoc, H10 semantic-hook, or loopback
    process. Use the established narrowly elevated read-only process inventory
    if sandbox policy blocks the probe.
11. Create one fresh empty absolute semantic-evidence directory under
    `/private/tmp`.

Do not execute the result test before render because its sixth transition is
the fresh result HTML. The complete prospective R 4.6.1 replay is already
sealed at `prospective_result_test_replay.txt`, SHA-256
`d2deb52ade1051d29192446a138bb3e1f91f5dfebe20b6d50509d314a3733019`.

## Sole render

Run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render notebooks/hypotheses/H10.qmd --profile nathealth
```

The established narrow access to the existing user-owned Quarto, Sass, and R
caches is authorized for this exact command if required. Do not change `HOME`,
redirect a cache into the project, install or restore packages, bypass the
profile or semantic hook, render the companion, render another page, or render
the full project. If startup fails before QMD execution, stop once with complete
environment evidence. Do not retry.

The render may read accepted stored tables, source CSVs, registries, and
figures and format their frozen values. It must not fit or refit a model,
predict, bootstrap, simulate, resample, recalculate p-values, change a
classification, or rebuild a scientific artifact.

## Complete post-render verification

After a successful render, run the exact postimage result test once and create
one order-specific verifier under
`audit/hypotheses/H10/report018_order58_result_render/`. Require:

- render exit 0, no embedded error, warning, stderr, unresolved reference, or
  raw execution trace;
- exactly 15 native `gt` tables and eight figures in accepted source order;
- every endpoint, caption, note, cell, label, alt text, and paired-source
  relationship preserved;
- the exact corrected biological-sex/gender boundary in prose and Figure 3,
  with both false phrases absent and the no-inference-about-gender-identity
  limitation intact;
- semantic-hook disposition `REPAIRED`, or separately evidenced
  already-repaired status, with external summary, complete ledger, exact
  reverse to recorded pre-hook HTML, exact reapplication, zero duplicate
  document IDs, and every `headers` token resolving exactly once to an intended
  `th` inside its own table;
- the accepted Answer in brief, exact samples, primary near-eye and
  complementary chest hierarchy, 11 FDR-retained main findings, two
  complementary-chest interactions, four complete 17-test FDR families,
  diagnostics, sensitivities, provenance qualification, and non-causal scope;
- all 26 relative link occurrences and 24 unique targets after dynamic QMD-to-
  HTML conversion, reciprocal companion link, Preparation 04 and 06, DEV-003,
  DEV-040, DEV-041, active navigation, and country-coded sites;
- all eight accepted result figures and paired source data, all 57 scientific
  assets, accepted inputs, companion QMD/test/HTML, profile, hook, engine,
  lockfile, central ledgers, H11 source, and unrelated build members exact;
- the immutable Stage 3 manifest has exactly six post-render transitions and
  no seventh mismatch;
- `audit/report_harmonization/phase4_corpus_manifest.csv` remains byte-exact at
  `73f1a371...`, with its H10 result-HTML row classified as the expected
  historical-to-fresh transition; and
- every build delta is target-owned, source-identical, or an expected search
  or sitemap integration change. Any target-regenerated display requires
  deterministic same-source and visible-content verification.

Do not run the H10 preparation test or helper. Do not open a new language,
cosmetic, display-refresh, or manifest-cleanup loop.

## Secure loopback visual QA

Only after all nonvisual checks pass, serve exactly `_build/nathealth` through
one temporary read-only server bound only to `127.0.0.1`. First require no
symlink under the served root to escape that root.

Inspect only the H10 result route at 1440 by 1000, 708 by 1000, and 720 by 500
as the 200-percent-equivalent view. Inspect the complete reader flow, all 15
tables, all eight figures, callouts, headings, captions, links, navigation,
wrapping, axes, legends, symbols, site codes, clipping, overlap, and page
overflow. Exercise any contained narrow table scroller. Inspect every exported
figure at its intended 170-mm final size.

The accepted Stage 3 figure QA records 5.696-point minimum peripheral or
essential text and 7.120-point minimum central text at 170 mm. Under the
author's REPORT-018 render-completion priority, preserve these accepted baked
figures and do not open a display-refresh loop solely from that historical
calculation. Require actual final-size legibility, no clipped or missing text,
and at least the sealed minima. A genuine unreadable or clipped page element is
a consolidated fail-closed defect.

Stop the server immediately after QA. Close the QA tab, reset the viewport,
wait for process exit, prove that no listener remains, and rehash the QMD,
test, profile, result HTML, held companion, complete build inventory, and
protected inventory. Pre-QA and post-QA inventories must match exactly.

## Return and hold

Return one complete acceptance record and one unique, non-circular evidence
manifest, or one consolidated fail-closed record. Retain external semantic
evidence until independent acceptance.

No QMD or companion source edit, scientific artifact, historical or current
manifest edit, profile, central ledger, package, lockfile, companion render,
H11 action, later render, full-project render, retry, commit, push, upload, or
publication change is authorized.
