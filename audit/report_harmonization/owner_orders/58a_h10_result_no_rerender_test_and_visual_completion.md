# REPORT-018 H10 order 58a: no-rerender test and visual completion

Date: 2026-08-22

Owner: H10 task `019fdc1b-b77b-7972-aed0-784da328e115`

Status: `RELEASED_ONCE_AFTER_INDEPENDENT_STOP_ACCEPTANCE`

## Purpose and authority

Order 58 completed the first and only H10 result render, semantic repair, and one reader-test execution. It then stopped correctly because the test required one stale caption phrase. Independent acceptance `audit/report_harmonization/report018_h10_order58_stopped_independent_acceptance.md`, SHA-256 `d8267c73e0efb33a0e6332c9f1ec4a03bd945c16c7aa579d5b8cfd6cd75d2ec2`, proves that the fresh page and its science are sound and that one exact test-only repair exposes no masked downstream failure.

This order authorizes one no-rerender continuation. It may edit only `tests/hypotheses/H10/test_h10_stage3_reader_report.R`, run that reader test exactly once against the preserved fresh HTML, and, only after PASS, finish the previously authorized static and secure-loopback visual QA.

## Hard preflight pins

Before editing, require all of the following:

- owner fail-closed record `ae2053164f866770b04443b3b51e3e95288cae7e3d468ed1ba85698441c124f8`, 2,392 bytes;
- owner 13-row non-circular seal `b23e04f9aae30c71c95a2d0f07b461e763fedda2dd75d0fd9bed2d83584cdf04`, 2,522 bytes, with 13 of 13 members exact;
- independent stopped acceptance `d8267c73e0efb33a0e6332c9f1ec4a03bd945c16c7aa579d5b8cfd6cd75d2ec2`;
- independent 21-row acceptance manifest `f6461dddb21a33dc2b09101e2a167f5e73c570be3866e5e72036de5a5cf68adf`, with 21 of 21 members exact, unique, and non-circular;
- independent downstream checker `57f1e45bfa4d528e1c3aac027e7fe2b8007bce7a3f36a5aa28715465bfa042b7`, 24,956 bytes;
- current reader test `ad792acdb7c9d2fe9290a6837a2a3c994811d7f5c9a64eaea01b0edd9f9b4db1`, 25,796 bytes;
- result QMD `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d`, 49,224 bytes;
- fresh result HTML `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`, 359,702 bytes;
- companion QMD `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`, 58,446 bytes;
- both held companion HTML copies `efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8`, 617,113 bytes;
- profile `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- external semantic summary `23c7f36ee58748a3146f2f30a9575972cdd317d057b753e809fb56e02ea7c5e5`, 456 bytes;
- external semantic ledger `094c126424e79332133cb82a879362d2b9a7dbd8c075983cfe7ba2c287574ed9`, 178,781 bytes;
- all 57 scientific assets exact;
- all 150 protected order-58 pre-render members exact; and
- the current build tree at 1,180 entries with zero symlinks and exactly the three sealed order-58 transitions for H10 HTML, `search.json`, and `sitemap.xml`.

Use the established narrowly elevated read-only process inventory if the sandbox blocks it. Require no competing H10, Quarto, Pandoc, semantic-hook, or H10 loopback process. Unrelated user services are not competing processes. The coordination matrix is dispatch evidence only and is not an owner execution pin.

## Sole authorized edit

In `tests/hypotheses/H10/test_h10_stage3_reader_report.R`, replace exactly one literal:

`Overview of statistically supported associations`

with:

`The 11 main associations retained after FDR adjustment.`

The first literal must occur exactly once before editing. The accepted replacement must already occur in both the frozen result QMD and fresh HTML. No other byte may change.

The exact required postimage is SHA-256 `dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af`, 25,803 bytes. R parse and Air 0.4.1 must pass. Replacing only the new literal with the old literal must reconstruct `ad792ac...`, 25,796 bytes, exactly. Seal a one-hunk, zero-context diff and exact reverse proof before test execution.

## Single reader-test execution

Run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla tests/hypotheses/H10/test_h10_stage3_reader_report.R
```

Require exit 0 and the exact terminal message `H10 standalone reader-report checks passed`. Do not run the preparation test. Do not rerun the reader test. On any failure, stop once and seal the complete failure.

## Complete static verification after PASS

Create new evidence only under `audit/hypotheses/H10/report018_order58a_no_rerender_completion/`. Do not modify or replace any order-58 evidence.

Require all of the following against the preserved HTML:

1. The result QMD, result HTML, companion QMD and HTML, preparation test, profile, lockfile, phase-4 manifest, H11 source, and every scientific input remain at their hard pins.
2. The result page has exactly one `main#quarto-document-content`, 15 native `gt` tables, eight figures, zero duplicate document IDs, and the exact immutable QMD endpoint order.
3. The external semantic evidence remains exact. Reverse all 1,130 substitutions to pre-hook SHA-256 `d3d1ac754480216b4cd022a16989ec9ad711d3cd385c8d0f895d682421ad7e32`, reapply exactly to the current HTML, and require all 1,038 `headers` tokens to resolve exactly once to intended scoped `th` elements inside their own table.
4. The corrected biological-sex and gender boundary, all samples, 11 FDR-retained associations, four complete 17-test FDR families, diagnostics, sensitivities, and no-inference-about-gender-identity limitation remain exact. Both prohibited false phrases remain absent.
5. All 26 relative source-link occurrences and 24 unique targets remain present. The rendered page must contain the corresponding 26 links to 24 unique targets; all files and all DEV fragments must resolve.
6. The immutable Stage 3 manifest has exactly the same six mismatch paths and no seventh path. The live reader-test identity must be the exact authorized `dac8e70f...` postimage.
7. All 57 scientific assets remain exact.
8. Relative to the order-58 pre-render build inventory, the only build changes remain H10 HTML, `search.json`, and `sitemap.xml`. No build path, hash, byte count, type, or symlink may change during this continuation.
9. Relative to the order-58 protected inventory, exactly one path changes: the authorized reader test from `ad792acd...` to `dac8e70f...`. Every other protected row remains exact.
10. There are zero embedded error, stderr, warning, or unresolved-reference nodes and no broken navigation or country-coded site label.

Run one complete static verifier after the reader-test PASS. It may be rerun once after visual QA only for the post-QA no-drift comparison. This does not authorize another reader-test execution.

## Secure-loopback visual QA

Only after the test and complete static verifier pass, serve exactly `_build/nathealth` with one temporary read-only server bound only to `127.0.0.1`. First prove that no symlink under the served root escapes the root.

Inspect only the H10 result route at:

- 1440 by 1000 desktop;
- 708 by 1000 narrow;
- 720 by 500 as the 200-percent-equivalent view; and
- each exported figure at its intended 170-mm final size.

Inspect the complete reader flow, all 15 tables, all eight figures, headings, callouts, captions, notes, links, active navigation, site codes, axes, legends, symbols, wrapping, clipping, overlap, and page overflow. Exercise every contained narrow table scroller. Require actual legibility and at least the sealed 5.696-point peripheral or essential and 7.120-point central minima. Do not open a cosmetic or display-refresh loop solely because the accepted peripheral minimum is below 7 points.

Close the QA tab, reset the viewport, stop the server, wait for exit, and prove no listener remains. Rehash the QMD, test, profile, result HTML, held companion, semantic files, complete build inventory, and protected inventory. Pre-QA and post-QA inventories must be byte-identical.

## Prohibitions and return

Do not run Quarto, knitr, Pandoc, the semantic hook, the preparation test, a model, a prediction, a builder, a manifest helper, or any scientific computation. Do not edit either QMD, either HTML, any scientific artifact, historical or current manifest, profile, central ledger, package, lockfile, companion, H11, or later target. Do not commit, push, upload, delete retained evidence, or retry a failed step.

Return one complete acceptance record and one unique non-circular manifest, or one consolidated fail-closed record for a genuinely new defect. H10 companion, H11, and every later target remain held pending independent H10 result acceptance.
