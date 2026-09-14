# REPORT-018 H11 result and companion independent acceptance

Disposition: `ACCEPTED_RESULT_AND_COMPANION`

The H11 result page and preparation companion are independently accepted. Order 61a completed the authorized H11-local test correction and direct preparation-manifest reseal without rerendering either page. Its single preparation-test execution passed, and its static, semantic, link, protected-identity, build, responsive-layout, final-size, and teardown checks all passed.

## Accepted reader endpoints

- result source: `notebooks/hypotheses/H11.qmd`, SHA-256 `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`;
- result HTML: `_build/nathealth/notebooks/hypotheses/H11.html`, SHA-256 `2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a`;
- companion source and build source copy: SHA-256 `3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816`;
- companion HTML: `_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html`, SHA-256 `58518d708e4feb6145bd8eb773b6b9ae4937afdf4a9e44e19d4215d9ca86162c`;
- H11-local preparation test: SHA-256 `64b427b4bc11f79a1ea2cd539eee7e30184271ef05cbba7b3f511a2f105a15a3`;
- current 283-row preparation manifest: SHA-256 `bd34dbfd6d2e929c825fe76281dfd384d8b0ef851b3d99a52b155c3216cfc6d9`;
- normal profile: SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

## Independent R 4.6.1 replay

The independent checker `scripts/report_harmonization/check_report018_h11_order61a_result_companion_acceptance.R`, SHA-256 `8f698052b80c12c3f26ac3fd0ebe4c711256c1dca4d6cd823a7f9a0b4b479e78`, passed all 12 acceptance domains:

- the 47-row owner stop manifest is exact, unique, and non-circular;
- the current preparation manifest is 283 of 283 live-exact and unique;
- the preparation test ran exactly once, exited zero, and reported PASS;
- the semantic repair reverses and reapplies exactly, with 26 tables, 179 ID substitutions, 801 `headers` substitutions, and 980 substitutions in total;
- the companion DOM contains one reader `main`, 26 native `gt` tables, three figures, 29 captions, one top-down Mermaid diagram, zero duplicate document IDs, and 1,193 of 1,193 scoped header tokens resolving exactly once;
- the source link contract has 20 occurrences, 17 unique targets, and 14 resolving fragments, while all nine served HEAD checks returned HTTP 200;
- the pre-QA and post-QA build, protected, scientific, and critical inventories are byte-identical;
- the live build inventory has 1,180 exact members, the protected inventory has 336 exact paths, and all 193 scientific and 25 critical paths remain exact;
- all 78 table-by-viewport containment checks pass;
- all three figures pass at exactly 642 pixels wide, with essential and minor text at or above 7 points;
- no listener remains on `127.0.0.1:53671`.

## Screenshot evidence classification

The owner finalizer stopped only because 13 task-owned screenshot evidence files use a `.png` filename suffix while containing valid JPEG/JFIF bytes. Independent decoding reproduced the JPEG/JFIF signature and recorded dimensions for all 13 files. Representative desktop, narrow, navigation, and 642-pixel figure views were independently inspected and display correctly.

This is an evidence filename/content mismatch, not a page, visual, scientific, semantic, or integration defect. The screenshot files remain byte-identical to the 47-row owner seal. None was renamed, converted, regenerated, or deleted.

## Preservation and next gate

No Quarto command, rerender, helper execution, QMD execution, model fit, prediction, scientific recomputation, package or lockfile change, commit, push, or upload occurred during Order 61a or this independent acceptance. The sensitivity-battery source and held HTML remain exact at `d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70` and `b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780`.

H11 result and companion integration is closed. The sensitivity battery remains held until a separate read-only downstream preflight and exact serial render order are sealed.
