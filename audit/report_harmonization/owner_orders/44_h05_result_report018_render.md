# REPORT-018 owner order 44: H05 result-page render

Date: 2026-08-20

Owner: H05 worker `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Status: **released for exactly one H05 result-page render**

## Serial authority

H04 result and companion integration is independently accepted in `audit/report_harmonization/report018_h04_companion_independent_acceptance.md`, SHA-256 `9621bc7fc334fed506f94494eeae855240aa1400fa8cff980298b6ff3589c46d`. Its 22-row manifest is SHA-256 `b2e6cf69db4431e32ce253cebf13abf0eb6b6d6e6d462c0a7844bb47928f2eab` and passes 22/22 exact under R 4.6.1.

H05 source-only order 36 is independently accepted at `audit/report_harmonization/report017_h05_order36_source_independent_acceptance.md`, SHA-256 `07ae1d95e8374c9b29659e9fc760d392047b229252320e2767d7d68404ea07ec`. Its 16-row acceptance manifest is SHA-256 `580d5f63dab78e1a5f427384a17009125231dacdf8bc4d2d8ab521d3bb94c7f4` and currently passes 16/16 exact, unique rows under R 4.6.1.

Release only the H05 result page. The H05 companion and every later target remain held.

## Hard preflight pins

- result QMD `notebooks/hypotheses/H05.qmd`: `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`, 74,309 bytes;
- held companion QMD `audit/hypotheses/H05/H05_analysis_preparation.qmd`: `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`, 75,630 bytes;
- final source verifier `tests/hypotheses/H05/test_h05_report017_source_harmonization.R`: `ba09ce33344d6c1ab959c1395d7ab7cd52abc3d7312586e705924a018b1cf179`, 60,101 bytes;
- source manifest `audit/hypotheses/H05/report017_order36/H05_report017_order36_source_manifest.csv`: `3c7e2379ce890b424dea10fe3764fd725b8ca7916bf48214541621320c467be0`, 25,001 bytes;
- stage-3 reader test `tests/hypotheses/H05/test_h05_stage3_reader_report.R`: `982162ccbd55def924beff3fbb0e98d31a94884aeb8cc683f817189e1171d4f4`;
- stage-3 manifest `artifacts/12_manifests/H05/H05_stage3_artifacts.csv`: `9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100`;
- preparation test `tests/hypotheses/H05/test_h05_preparation_report.R`: `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`;
- preparation manifest `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`: `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36`;
- H05 handoff `audit/handoffs/H05_stage4_handoff.md`: `71a8d4664504da7b6e621d5b24aa699df793ee120373ae28aeb75d1c980246da`, 19,132 bytes;
- Nature Health profile `_quarto-nathealth.yml`: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, 7,480 bytes;
- post-render wrapper `scripts/report_harmonization/post_render_gt_html_semantics.R`: `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic repair engine `scripts/report_harmonization/repair_gt_html_semantics.R`: `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- `renv.lock`: `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H05.html`: `58be9b4da8bb67a4322af7096472de1bf97c47d17c79f39078692577a2788b96`, 573,311 bytes;
- held companion HTML `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html`: `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`, 839,152 bytes.

The source has exactly 30 unique `tbl-h05-*` endpoints and seven unique `fig-h05-*` endpoints. The accepted source verifier passed 54/54 gates. No source or scientific discrepancy is open. Before rendering, recheck the hard pins, inventory the protected H05 scientific set and complete `_build/nathealth`, and require zero build symlinks. Stop on unexpected drift.

The coordination-matrix identity is dispatch-time coordination evidence, not a mutable owner hard pin.

## Sole render command

Create one fresh absolute mode-0700 semantic-audit directory under `/private/tmp`, record its path and emptiness, then run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H05.qmd --profile nathealth`

Use the normal R 4.6.1 project profile and renv startup with only the established narrow access to the existing user-owned renv cache if needed. Do not bypass `.Rprofile`, `renv/activate.R`, or the configured semantic hook. Do not use `--no-execute`, render the companion, render another target, or run the full project.

The result page may read and format the frozen accepted H05 artifacts already declared by the source contract. It may not fit or refit a model, run prediction, bootstrap, simulation, resampling, Shapley or dominance computation, regenerate a scientific artifact, or alter a scientific value.

## Required nonvisual acceptance

After the one render:

1. Require Quarto exit 0 and semantic-hook disposition `REPAIRED` or `ALREADY_REPAIRED` as appropriate. Retain the external summary and reversible ledger through independent acceptance.
2. Require exactly 30 native gt tables and seven intended figures, in accepted source order, with one caption per endpoint, complete alt text, source-data links, and all accepted values, notes, and styles.
3. Require document-wide unique IDs. Every explicit `headers` token must resolve exactly once to its intended `th` inside its own table. Require zero dangling or unsupported ID references and exact semantic-ledger reversal to the hook's pre-repair HTML identity.
4. Verify reciprocal result and companion links, all preregistration-deviation links and anchors, the now-built Supplementary information target, active navigation, external-link classification, all nine country-coded study-site labels, source-data targets, and zero forbidden local, absolute, `_build`, or `file:` reader links.
5. Require zero embedded error, warning, or stderr nodes and no unresolved Quarto cross-reference.
6. Reconcile the complete protected H05 inventory. Both QMDs, held companion HTML, profile, lockfile, accepted source tests and manifests, input data, models, estimates, figures, source-data files, ledgers, and all other scientific artifacts must remain byte-identical.
7. Classify every build delta. Only the H05 result HTML and target-owned page assets or source-identical copies, plus normal `search.json` and `sitemap.xml` changes, are eligible. Fail on any unclassified content change. Record byte-identical mtime-only framework touches separately.
8. Run the accepted order-36 source verifier or its non-mutating equivalent to confirm the source boundary. The existing stage-3 reader test and stage-3 manifest are historical integration contracts. If their only failures are stale pre-render HTML or already accepted source/profile identities, record them as deferred test metadata under REPORT-018. Do not patch or rerender. Scientific, endpoint, semantic, link, or rendered-content failures remain blocking.

## Visual acceptance

Only after the nonvisual render and semantic gates pass, start one temporary read-only static server rooted exactly at `_build/nathealth`, bound only to `127.0.0.1`, after a symlink preflight. Inspect only the exact H05 result route.

Inspect the full page at 1440 by 1000, 708 by 1000, and a 200-percent-equivalent viewport. Inspect all 30 HTML tables and all seven figures. The HTML tables must be usable at a typical desktop or laptop width. At narrow width, a table may use a contained, working horizontal scroller without causing page-level overflow. For exported or stored figure outputs, the PNG or SVG at intended final size is the controlling visual check.

Inspect the provisional principal figure `fig-h05-near-effects` and the continued principal table `tbl-h05-near-results-a` plus `tbl-h05-near-results-b` closely. Check figure labels, legends, axes, symbols, panels, captions, alt text, table headers, notes, disclosures, headings, callouts, navigation, links, clipping, overlap, and unreachable content. Exercise representative narrow scrollers and disclosures.

Under REPORT-018, do not open a language, style, optional-link, test-literal, or minor cosmetic cleanup loop. Record such nonblocking observations for later whole-corpus review. Stop only for a render failure, scientific or provenance discrepancy, semantic-accessibility failure, broken required internal target, missing output, uncontained layout failure, or unreadable principal output.

Stop the server, prove no listener remains, reset the viewport, close QA tabs, and prove post-QA build, source, profile, companion, and protected-scientific stability.

## Return and prohibitions

Return one complete acceptance package or one consolidated fail-closed defect list. Do not patch or rerender within this order. Do not edit any QMD, HTML by hand, source data, model, scientific artifact, figure, manifest history, profile, semantic hook, package, lockfile, ledger, manuscript, or another hypothesis. Do not commit, push, upload, delete, publish, or start a later target.

The H05 companion and every later REPORT-018 render remain held pending independent H05 result acceptance.
