# REPORT-018 order 47: H06 hourly result render

Date: 2026-08-21

Owner: H06 hourly owner `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: released for exactly one H06 hourly result-page render. The H06 companion and every later target remain held.

## Accepted authority

- Source-only acceptance remains result QMD `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`, companion QMD `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`, handoff `21b37d161f07ec27a2802239a3999621f484b9d697c7cddaf3a73f6c09fe4e90`, and source verifier `fd8b4b5243d9942075a4845ea3fe21ace64fd5cc62300d8cd42b4b86c3eadb61`.
- Artifact acceptance: `audit/report_harmonization/report018_h06_order46_artifact_independent_acceptance.md`, SHA-256 `a1e637bce2659c0cec0f1af52b4bc4124d4678dc4bdb3307b13c5baa4e7ac6b3`, 6,417 bytes.
- Artifact acceptance manifest: `audit/report_harmonization/report018_h06_order46_artifact_independent_acceptance_manifest.csv`, SHA-256 `9b709948ee796b485805f41935d0bc8f0ac5780f7ffa3cbc4ed144e2be5b0a4e`, 5,790 bytes, with 36 exact, unique, non-circular rows under R 4.6.1.
- The focused artifact verifier has passed after durable promotion: 308 unique Stage 3 rows, 13 updates, seven appends, 11 paired exports, four visual-QA families, and all protected identities.
- Profile: `_quarto-nathealth.yml`, SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Semantic wrapper: `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`.
- Semantic repair engine: `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.
- Stale result HTML: `ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`, 6,109,797 bytes.
- Held companion HTML: `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`, 771,694 bytes.

## Hard preflight

Before rendering, reproduce every non-matrix path in the order-47 dispatch manifest. Require:

- all accepted source, test, profile, hook, manifest, builder, figure, source-data, stale-HTML, companion, H06 daily, and package-lock identities exact;
- the Stage 3 manifest at `d4cbb953428123510bbc1e996ec681dbfbafe4c3a79a66c93a581453584308f1`, 75,394 bytes, with 308 unique rows;
- all 11 promoted exports at their accepted identities;
- the complete `_build/nathealth` preinventory, with no symlink;
- no active Quarto, Pandoc, H06 render, or loopback server process;
- one fresh, empty, absolute semantic-audit directory under `/private/tmp`.

Stop before rendering on any drift. The coordination matrix is dispatch-time evidence only and is not an owner mutation target.

## Sole render command

Run exactly once through normal R 4.6.1 project-profile and renv startup, using only the established narrow access to the existing user-owned renv cache:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

No other Quarto command, target, or full-project render is authorized. Do not use `--no-execute`, bypass the profile, or bypass the post-render semantic hook.

## Execution and preservation contract

- The page may read accepted stored CSVs and format their frozen values. It must not fit or refit a model, generate predictions, bootstrap, simulate, resample, recompute p-values or FDR decisions, regenerate scientific source data, or execute a full builder.
- Preserve both authoring QMDs, the held companion HTML, profile, hook, engine, H06 daily sources, source-only test, artifact verifier, Stage 3 manifest, all 11 durable exports, all frozen source CSVs, scientific artifacts, package lock, central ledgers, and every unrelated build member byte-for-byte.
- The accepted result QMD must remain `468ecebe...`. The accepted companion QMD must remain `f952d5ec...`.
- Expected content-changing build outputs are the target H06 HTML, normal `search.json` and `sitemap.xml` changes, and target-owned source-identical resource copies created or refreshed by Quarto. Any H06 PNG, source CSV, CSS, or QMD build copy may change only to become byte-identical to its accepted authoring source. Classify byte-identical framework mtime touches separately. Stop on any unclassified build-content change.

## Nonvisual acceptance

Require all of the following against the fresh HTML:

1. Quarto 1.9.37 and R 4.6.1, target render exit 0, and no embedded cell error, warning, stderr, unresolved cross-reference, or raw execution trace.
2. Semantic-hook disposition `REPAIRED` for exactly 11 native gt tables. Record its pre/post hashes, table count, ID changes, headers changes, and substitution count. Retain the external summary and reversible ledger.
3. Exactly 11 unique Quarto `tbl-*` endpoints and six unique Quarto `fig-*` endpoints in the accepted source order. Preserve every caption, alt text, value, source note, source-data link, table row/column order, and figure order.
4. Zero duplicate document IDs. Every explicit `headers` token must resolve exactly once inside its own table to the intended `th`. All supported document ID references must resolve.
5. All four DEV links resolve to their exact central anchors. Preparation 06, the hourly companion, artifact/source-data downloads, navigation, and Supplementary information must resolve.
6. The single reader link to `H06_daily.qmd` may remain an unresolved output target only because the complementary daily result is scheduled after the hourly result and companion. Classify exactly that target as held. Fail on any second unresolved internal reader link.
7. All nine reader-visible sites use country codes. Preserve the hourly-main and daily-complement hierarchy.
8. The accepted source-only verifier and artifact verifier PASS states remain controlling pre-render evidence. Do not rerun them after rendering because their protected sets truthfully pin the pre-render HTML. Do not run the historically coupled `test_h06_stage3.R` or companion `test_h06_preparation_report.R` in this result-only order. Their later render-state reconciliation is deferred under REPORT-018 and must not open a cleanup loop.
9. Reverse the semantic-hook ledger into a temporary copy and require the reconstructed hash to equal the hook pre-hash. Reapply or structurally compare as required to prove visible text, values, element order, captions, notes, links, endpoint counts, and table geometry are unchanged across the hook.
10. Reconcile the complete protected and build inventories. Preserve the held companion HTML exactly.

## Secure loopback visual QA

After all nonvisual checks pass:

1. Preflight `_build/nathealth` for symlinks. Stop if any symlink resolves outside the build root.
2. Start one temporary read-only static server with document root exactly `_build/nathealth`, bound only to `127.0.0.1` on one unused high port. Record command, PID, port, root, start time, and exact H06 route.
3. Use only the supported in-app Browser. Inspect the exact H06 result route at 1440 x 1000 and 708 x 1000, plus a 200-percent-equivalent view.
4. Inspect all 11 native tables and all six figures. HTML tables must work reasonably at a typical desktop/laptop size. At narrow width, a wide table may use a contained, usable horizontal scroller without breaking the page. For exported visual artifacts, the accepted PNG versions are the controlling final-size checks, with their PDF/SVG counterparts checked structurally.
5. Inspect the principal table and figure plus every repaired figure at intended final display size. Check text size, labels, legends, axes, symbols, site codes, wrapping, clipping, overlap, panel geometry, callouts, disclosures, captions, alt text, navigation, and link usability.
6. Nonblocking language, optional-link, test-literal, and cosmetic findings are deferred under REPORT-018. Stop only for a real execution, scientific, semantic, navigation, missing-required-output, or materially unusable display defect.
7. Stop the server immediately after QA. Prove no listener remains, reset the viewport, close the QA tab, and rehash source, profile, protected, and complete build inventories.

## Return and hold

Return one complete acceptance package or one consolidated fail-closed defect list. Preserve the semantic-audit directory until independent acceptance. Do not patch or rerender within this order.

No source edit, test edit, manifest edit, model computation, artifact regeneration, companion render, H06 daily render, later target render, profile or ledger change, package or lock change, broad builder, commit, push, upload, or publication is authorized.

The H06 companion, H06 daily result and companion, H07, and every later REPORT-018 target remain held pending independent acceptance of this result page.
