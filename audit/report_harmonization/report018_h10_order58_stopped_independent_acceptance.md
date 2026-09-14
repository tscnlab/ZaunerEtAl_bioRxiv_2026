# REPORT-018 H10 order 58 stopped-state independent acceptance

Date: 2026-08-22

Disposition: `ACCEPTED_FAIL_CLOSED_TEST_CONTRACT_STOP`

## Accepted owner return

The order 58 owner stopped correctly after the first and only H10 result render and the first and only authorized reader-test execution. The render exited 0. The reader test then exited 1 at one stale rendered-caption assertion, and the owner performed no retry, source edit, companion action, visual QA, or further page mutation.

The owner record is exact at `audit/hypotheses/H10/report018_order58_result_render/order58_fail_closed_record.md`, SHA-256 `ae2053164f866770b04443b3b51e3e95288cae7e3d468ed1ba85698441c124f8`, 2,392 bytes. Its non-circular evidence manifest is exact at SHA-256 `b23e04f9aae30c71c95a2d0f07b461e763fedda2dd75d0fd9bed2d83584cdf04`, 2,522 bytes. R 4.6.1 independently rehashed all 13 members exactly, with unique paths and no self-inclusion.

The fresh result endpoint remains `_build/nathealth/notebooks/hypotheses/H10.html`, SHA-256 `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`, 359,702 bytes. The result QMD remains `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d`. The companion QMD and held HTML remain `706fe46f...` and `efd4c91f...`. The profile remains `80dd0557...`.

## Independent scientific and integration disposition

There is no source, scientific, semantic, link, build, or reader-page discrepancy.

The sole failed assertion required `Overview of statistically supported associations`. That phrase occurs exactly once in the current test and occurs nowhere in the accepted result QMD or fresh result HTML. The accepted Table 4 caption occurs in both source and HTML exactly as `The 11 main associations retained after FDR adjustment.` Replacing only the stale test literal yields prospective test SHA-256 `dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af`, 25,803 bytes, and reverses exactly to the stopped test `ad792acd...`, 25,796 bytes.

The complete prospective reader test was executed once in memory under R 4.6.1. It passed through every later assertion and returned `H10 standalone reader-report checks passed`. This replay did not edit the live test or any H10 source or output.

Independent post-render checks also pass:

- semantic disposition `REPAIRED`, with 15 native tables, 92 internal IDs, 1,038 header relationships, and 1,130 substitutions;
- exact semantic reversal to pre-hook SHA-256 `d3d1ac75...` and exact reapplication to current HTML;
- zero duplicate document IDs and all 1,038 `headers` tokens resolving exactly once to an intended scoped `th` in their own table;
- exactly 15 table and eight figure endpoints in the immutable QMD order;
- zero embedded error, stderr, or unresolved-reference nodes;
- 26 source link occurrences to 24 unique relative targets and 26 rendered links to 24 unique targets, all existing, with all deviation fragments resolving exactly once;
- exactly six immutable Stage 3 historical transitions and no seventh mismatch;
- all 57 scientific table, figure, and paired-source artifacts exact;
- exactly three target-owned build transitions, comprising H10 HTML, `search.json`, and `sitemap.xml`, across 1,180 entries and zero symlinks;
- all 150 protected pre-render members exact, with the prospective test transition as the sole permitted no-rerender protected change; and
- all 11 secure-loopback QA-harness preconditions ready for desktop, narrow, 200-percent-equivalent, and 170-mm inspection.

A narrowly elevated read-only process inventory found no competing H10, Quarto, Pandoc, semantic-hook, or H10 loopback process. The unrelated LightLogWeb R service and two unrelated `mirai` daemons are outside H10 and are not classified as competing processes.

## Controlling independent evidence

The durable checker is `scripts/report_harmonization/check_report018_h10_order58_stop_and_no_rerender_preflight.R`, SHA-256 `57f1e45bfa4d528e1c3aac027e7fe2b8007bce7a3f36a5aa28715465bfa042b7`, 24,956 bytes. Air 0.4.1 and R 4.6.1 pass. Its complete result is:

`REPORT018_H10_ORDER58_STOP_NO_RERENDER_PREFLIGHT=PASS checks=14 owner=13/13 prospective=dac8e70f.../25803 test=PASS tables=15 figures=8 semantic=1130 build=3 protected=150 qa=11 R=4.6.1`

## Authorized next boundary

One no-rerender, test-only continuation is scientifically and operationally safe. It may replace only the one stale caption literal in `tests/hypotheses/H10/test_h10_stage3_reader_report.R`, require the exact `dac8e70f...` postimage and exact reverse proof, run the complete reader test exactly once against the preserved fresh HTML, and proceed only after PASS to the already authorized static and secure-loopback visual QA. It may not rerender, edit either QMD, change scientific artifacts or manifests, touch the held companion, release H11, or start any later target.
