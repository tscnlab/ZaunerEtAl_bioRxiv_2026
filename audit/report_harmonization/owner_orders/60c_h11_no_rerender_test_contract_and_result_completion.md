# REPORT-018 owner order 60c: H11 no-rerender test contract and result completion

Date: 2026-08-22

Owner: H11 task `019fba59-0f3c-74a0-ab3d-58d389365ad1`

Scope: one exact test-only correction, one complete post-render verification,
and bounded result-page visual QA

Status: `SEALED_FOR_ONE_DISPATCH`

## Authority

Order 60b is independently accepted at a rendered no-rerender stop under
`audit/report_harmonization/report018_h11_order60b_rendered_stop_independent_acceptance.md`.
The one H11 result render is consumed and must not be repeated. The fresh
post-hook HTML remains fixed at
`2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a`,
306,265 bytes.

The complete independent R 4.6.1 replay passes after exactly three historical
rendered-literal transitions and one checker storage-type classification. No
page, source, model, scientific, semantic, link, manifest-history, build, or
environment defect remains.

## Coordination boundary

Keep `audit/report_harmonization/coordination_matrix.csv` byte-identical at
SHA-256
`c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac`,
42,552 bytes. Its H11 state remains the active result-target state required by
the complete historical checker. Record Order 60c through a separate durable
dispatch receipt. Do not advance the shared matrix during owner execution.

## Mandatory preflight

Before editing, the owner must:

1. reproduce the non-circular Order 60c dispatch manifest exactly;
2. reproduce the independent Order 60b acceptance manifest exactly;
3. run
   `scripts/report_harmonization/check_report018_h11_order60b_rendered_stop_and_downstream_replay.R`
   under R 4.6.1 and require 10/10 PASS, including owner 67/67, semantic
   reversal and reapplication, complete 14/14 downstream replay, build
   1,180/1,180, protected 336/336, science 193/193, and cache 25/25;
4. require the result QMD `7909ba06...`, companion QMD `3f5a0d2e...`, result
   HTML `2c8a34ec...`, held companion HTML `fd6307a6...`, profile `80dd0557...`,
   lockfile `3bf99c63...`, and sensitivity QMD/HTML
   `d2d17770...`/`b9af89c0...` exact;
5. require the current Stage 3 reader test at `088e0a12...`, 16,736 bytes;
6. require zero symlinks below `_build/nathealth`; and
7. use the established read-only process inventory to require no competing
   H11, Quarto, Pandoc, semantic-hook, or task-owned loopback process. Leave
   unrelated services untouched.

Stop without mutation on any failed condition.

## Sole project edit

Edit only
`tests/hypotheses/H11/test_h11_stage3_reader_report.R`. Apply exactly these
three line-local replacements in the `required_text` vector:

1. `"Gender is a distinct construct",` to
   `"Gender identity is a distinct construct",`;
2. `"pointwise 95% intervals",` to
   `"pointwise 95% confidence intervals",`; and
3. `"0.050214",` to
   `"displayed as FDR-adjusted p = 0.050",`.

Require exactly one occurrence of each preimage and postimage. The exact
postimage must be SHA-256
`b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0`,
16,783 bytes. Reverse substitution must reproduce the accepted preimage
`088e0a1235d2561515613271e497ae55124a2bbe39f5fa9e2173583df131dea8`,
16,736 bytes. Require R parse, Air 0.4.1, scoped whitespace, and exactly three
changed lines. Do not edit a QMD, HTML, helper, manifest, handoff, profile, or
scientific file.

## One complete no-rerender verifier

Create one task-owned verifier under
`audit/hypotheses/H11/report018_order60c_no_rerender_completion/` by copying
the accepted complete checker
`scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R`.
Make only these exact verifier classifications:

1. pin the current Stage 3 reader test to `b0af2794...`, 16,783 bytes;
2. add that test path to the exact Stage 3 historical mismatch set and pin its
   live postimage;
3. add that test path to the exact held preparation-manifest mismatch set;
4. add that test path and pin to the temporary Stage 3 manifest classifier;
5. compare the 193-row scientific inventory by exact path, exact SHA-256, and
   numeric byte value instead of whole-data-frame storage type.

Preserve every other checker line and assertion. Require an exact forward and
reverse diff to the accepted checker. Run the resulting verifier exactly once
with:

- `H11_RESULT_PHASE=postrender`;
- `H11_SEMANTIC_AUDIT_DIR` pointing to the preserved Order 60b semantic
  evidence; and
- `H11_RESULT_CHECK_DIR` pointing to the new Order 60c evidence directory.

Require complete 14/14 PASS. This includes both complete transition-aware
tests, the exact three Stage 3 historical transitions plus the authorized test
transition, the five held preparation transitions plus the authorized test
transition, 15 tables, eight figures, 584 scoped header tokens, unique IDs,
resolved links and deviation anchors, 193 scientific assets, 34
source-identical build resources, and zero symlinks. Do not run the preparation
helper, preparation test, Quarto, Pandoc, or semantic hook.

## Bounded loopback QA

Only after the complete verifier passes, apply the active
`$quarto-authoring` boundary:

1. repeat the zero-symlink preflight;
2. serve only `_build/nathealth` on one unused high port bound to
   `127.0.0.1`;
3. inspect exactly `/notebooks/hypotheses/H11.html` at 1,440 by 1,000, 708 by
   1,000, and 720 by 500;
4. inspect all 15 tables, eight figures, captions, alt text, table scrollers,
   disclosures, navigation, reciprocal links, deviation links, and source-data
   links;
5. inspect exported figures at 642 pixels and the exact 170-mm display width,
   requiring at least 7-point essential text;
6. reject overflow, clipping, overlap, missing content, broken interaction,
   privacy leakage, or page-attributable console warning or error;
7. close or reset the QA surface, stop the server, and prove no listener
   remains; and
8. rerun the no-drift gate and require byte-identical build inventories across
   QA plus exact result HTML, source, companion, profile, lockfile, science,
   and historical evidence.

## Writes, prohibitions, and stop

Writes are limited to the one Stage 3 reader test, one task-owned verifier,
and new bounded non-circular Order 60c execution, semantic-reuse, static,
link, screenshot, visual-QA, lifecycle, inventory, and completion evidence.

No Quarto command, render, QMD execution, source QMD edit, HTML edit, semantic
rewrite, helper, manifest rewrite, model, estimate, interval, p-value, FDR
decision, diagnostic, scientific artifact, companion, sensitivity, profile,
package, lockfile, ledger, later target, full-project action, commit, push, or
upload is authorized.

Return one complete non-circular acceptance package or one combined
fail-closed stop for a genuinely new defect. H11 companion and sensitivity
remain held pending independent H11 result acceptance.
