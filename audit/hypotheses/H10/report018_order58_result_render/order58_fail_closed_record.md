# REPORT-018 H10 order 58 fail-closed record

Sealed UTC: 2026-08-22 13:06:56 UTC

## Disposition

Order 58 is stopped after its single authorized result render and single authorized postimage reader-test execution. No retry, companion render, scientific recomputation, visual-QA server, browser QA, source-page edit, historical-manifest edit, profile edit, H11 action, commit, push, or upload was performed.

The render itself exited 0 and produced the fresh result HTML at SHA-256 `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`. The semantic hook reported `REPAIRED` for all 15 native gt tables and its 1,130 substitutions reverse exactly to the recorded pre-hook HTML and reapply exactly to the current HTML.

The exact accepted postimage test then exited 1 at its required rendered-text list. A read-only diagnosis found exactly one missing string: `Overview of statistically supported associations`. That string is absent from both the frozen accepted result QMD and the fresh result HTML. The rendered Table 4 instead carries the accepted caption `The 11 main associations retained after FDR adjustment.` All other 28 required rendered strings in that test list are present.

This is an accepted-test/checker contract defect exposed by a genuine fresh render, not a source or scientific defect. The frozen QMD, held companion, 57 scientific assets, model and demographic inputs, historical manifests, profile, hook, engine, lockfile, phase-4 manifest, and H11 source retain their required identities. The corrected biological-sex and gender boundary is present in prose and Figure 3, both prohibited false phrases remain absent, and the no-inference-about-gender-identity limitation is intact.

## Required next action

The coordinator must issue a new sealed order with an independently accepted reader-test correction before any result test retry, rerender, or visual QA. The current fresh HTML and external semantic evidence directory are retained for that decision.

## External semantic evidence

- `/private/tmp/h10-order58-semantic.UelLEK/gt_html_semantic_post_render_summary.csv`, SHA-256 `23c7f36ee58748a3146f2f30a9575972cdd317d057b753e809fb56e02ea7c5e5`.
- `/private/tmp/h10-order58-semantic.UelLEK/001__build__nathealth__notebooks__hypotheses__H10.html_gt_semantic_ledger.csv`, SHA-256 `094c126424e79332133cb82a879362d2b9a7dbd8c075983cfe7ba2c287574ed9`.

