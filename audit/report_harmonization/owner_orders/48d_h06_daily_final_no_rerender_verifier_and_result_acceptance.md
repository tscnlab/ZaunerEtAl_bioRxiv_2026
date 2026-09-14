# REPORT-018 H06_daily order 48d: final no-rerender verifier and result acceptance

Date: 2026-08-21

Status: `RELEASED_ONCE_NO_RERENDER`

Owner: H06_daily

## Objective

Complete the already rendered H06_daily result page without another Quarto render. Repair only the focused verifier harness so it recognizes the exact authorized verifier transition at its earlier display-manifest gate and uses stable XML-node closure names in the table and figure audit tibbles. Then execute the complete post-render verifier once, perform the deferred secure-loopback visual review, and execute the post-QA verifier once.

This order does not authorize a source, page, display, semantic, or scientific change.

## Controlling independent disposition

The accepted order48c stop is recorded at:

- `audit/report_harmonization/report018_h06_daily_order48c_verifier_gate_stop_independent_acceptance.md`, SHA-256 `b975ed9d386360c381fb139d8b3acfb7b59a3ebb3f162605ef075b1cdc7e947a`, 3,206 bytes; and
- `audit/report_harmonization/report018_h06_daily_order48c_verifier_gate_stop_independent_acceptance_manifest.csv`, SHA-256 `8336dbae4b05ce8dce6934ce7e344fa657d6debeab90e53a2838d4e013338e33`, 2,665 bytes, 15/15 exact under R 4.6.1.

The independent checker is:

`scripts/report_harmonization/check_h06_daily_order48c_verifier_gate_stop.R`

SHA-256 `97af7cd915912214346d44bf57ee239453935e966ada7a108384106d7ddd958d`, 6,641 bytes.

It returns:

```text
H06_DAILY_ORDER48C_STOP=PASS owner=22 display=28/29 mismatch=verifier main=1 html=74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c R=4.6.1
```

The prospective verifier audit is:

`audit/report_harmonization/owner_orders/48d_h06_daily_prospective_verifier_audit.csv`

SHA-256 `738a9d18a4b412edf554fdec21edea0af4b4f3f3634cd94743bff727b476a125`, 1,551 bytes. Its complete temporary replay passed the post-render path with 14 tables, five figures, seven dynamic links, eight build deltas, and 3,386 protected members. A separate structural-only post-QA replay passed with 846 build files, 3,386 protected members, and a 111-row prospective completion manifest. Synthetic temporary QA fixtures used in that bookkeeping replay are not visual acceptance. The live browser review remains mandatory below.

## Mandatory preflight

Before editing, reproduce all of these identities:

- focused verifier: `54ed2e2ece2e90d1e316f3a94869b280d0cc7487b88df9ba480f560f7b25f543`, 66,167 bytes;
- 29-row current display manifest: `395c112968c00294cbc085246894feae9cd7746e4e5c5714b96cb9e59fd90fc6`, 5,361 bytes;
- result QMD: `8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`, 65,349 bytes;
- result HTML: `74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`, 11,946,551 bytes;
- held companion QMD: `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`;
- held companion HTML: `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`;
- profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, 7,480 bytes;
- display-refresh implementation: `154091b99da11b51b8e41a53f1532c0bf7a57f44ec6e58b35d0fa19913bf2ce6`;
- corpus manifest: `73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334`;
- semantic summary: `bafde8ff09dda671e725d72adfa458f58bd599cba41a6881ed5a75862c9a917a`;
- semantic ledger: `09fde59b3495da6e3bac7b6e0d389d09fa7ded61c5a5c72283913945e4ea310e`; and
- semantic reverse audit: `ad34e4bd128448d90354bdb65d527a0681648d71f6c53c578804b4993fc85e2c`.

Reaudit the owner order48c stop manifest at SHA-256 `3dd55e637c2766336f8b0b9ade9817f88c42a85f6ed3d2db5ecc6aa9da82482c` as 22/22 exact, unique, and non-circular.

Reaudit these two external authorization records:

- `audit/report_harmonization/owner_orders/48d_h06_daily_authorized_verifier_transition.csv`, SHA-256 `e985c74053d4e9ce7c3793a2453dd7b6b888cfeb806d4db9d1bedf83206f204c`, 429 bytes; and
- `audit/report_harmonization/owner_orders/48d_h06_daily_authorized_evidence_additions.csv`, SHA-256 `78c2977ca017decde7cd88ad0df077e821f64cd68bd0c57c9224e6692cbc3f9f`, 3,361 bytes, 17/17 live-exact and unique.

The preserved semantic directory `/private/tmp/H06_daily-order48b-semantic.SbpRAI` must contain exactly the accepted summary and ledger. Confirm no H06_daily Quarto, Pandoc, semantic-hook, verifier, browser server, or loopback process is active. Stop before editing on any mismatch.

Do not create a new order48d evidence directory inside `audit/hypotheses/H06_daily/` before the post-QA verifier passes. Execution logs before that gate must remain outside the protected project set.

## Sole permitted live edit

Edit only:

`tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R`

The required postimage is SHA-256 `06abb903f7de51792d1dbb57d8ffcfd26ddf02ebd2455f646ae3f12db6ee6109`, 66,973 bytes.

Apply exactly these bounded verifier-harness corrections.

### 1. Earlier display-manifest transition classification

Immediately after the existing `display_manifest_path` definition:

1. define `authorized_verifier_transition_path` for `audit/report_harmonization/owner_orders/48d_h06_daily_authorized_verifier_transition.csv`;
2. add `read_authorized_verifier_transition()` that requires exactly one unique row, the exact verifier path, and the live verifier post-hash and byte count; and
3. return that validated row.

Inside `verify_promoted_display()`:

1. read the validated transition before auditing manifest members;
2. retain ordinary live-exact rows as `UNCHANGED`;
3. classify `AUTHORIZED_VERIFIER_TRANSITION` only when path, historical manifest hash and bytes, and live postimage hash and bytes all equal the external transition row;
4. classify every other mismatch as `UNAUTHORIZED_MISMATCH`; and
5. require exactly one authorized verifier transition and every row to pass.

Do not edit or reseal `H06_daily_order48a_display_manifest.csv`. Its historical verifier row must remain byte-identical.

### 2. Stable XML-node closure names

In the 14-table endpoint audit only, rename the lapply closure scalar from `endpoint` to `endpoint_node` and use `endpoint_node` for every rvest call. Preserve the reader-facing tibble column name `endpoint`.

In the five-figure endpoint audit only, make the same closure-scalar change from `endpoint` to `endpoint_node` and use it for every rvest call. Preserve the tibble column name `endpoint`.

These two corrections prevent tibble data masking from replacing the XML node with the newly created character endpoint column. Do not alter any endpoint set, expected caption, table value, figure hash, source hash, semantic rule, or message.

### 3. Current protected-evidence classification

In the existing post-render block:

1. change only the evidence manifest filename from the 48c record to `48d_h06_daily_authorized_evidence_additions.csv`;
2. require exactly 17 entries rather than 10;
3. replace the duplicate inline verifier-transition reader with `read_authorized_verifier_transition()`; and
4. preserve all existing result-HTML, evidence-addition, verifier-transition, removal, and unexpected-delta failure rules.

No other verifier code may change.

## Required source checks and reverse seals

After the edit and before execution:

1. require the exact postimage SHA and byte count above;
2. require R parse under R 4.6.1;
3. require `air format --check` to pass;
4. require an exact reverse patch from the postimage to the immediate order48c preimage `54ed2e2ece2e90d1e316f3a94869b280d0cc7487b88df9ba480f560f7b25f543`, 66,167 bytes;
5. require the already sealed order48c reverse to the historical display-manifest identity `aca33f5815bb34979513caa7a50a9a38ba66e7bb22d228c8c04f6afb010e42f7`, 63,149 bytes; and
6. require the display manifest, QMD, HTML, semantic evidence, profile, companion, figures, source data, refresh script, and scientific artifacts to remain exact.

Do not run a preliminary live verifier.

## One post-render verifier execution

Using R 4.6.1 and the established narrow access to the existing user-owned renv cache, run exactly once:

```text
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 ORDER48A_VERIFY_PHASE=postrender GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order48b-semantic.SbpRAI R --vanilla --slave -f tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R
```

This is a verifier execution against preserved output, not a Quarto render or QMD execution. It must return:

```text
ORDER48A_POSTRENDER=PASS tables=14 figures=5 links=7 build_delta=8 protected=3386
```

Require the complete semantic reversal, 14 native gt tables, predictor-specific 3 by 4 by 15 placement-table contract, five figures, seven dynamic links, navigation, country-coded sites, reciprocal links, no-error checks, 846-file build inventory, exact source-identical build deltas, and the complete 3,386-member protected reconciliation.

Stop without patch or retry on any failure.

## Secure-loopback visual QA

Only after the post-render verifier passes, serve the existing `_build/nathealth` output on a fresh port bound only to `127.0.0.1`.

Review the existing H06_daily result page at:

- 1440 by 1000 desktop;
- 708 by 1000 narrow;
- 720 by 500 as the established 200-percent equivalent; and
- the intended 170-mm final figure size.

Require:

- all 14 tables and five figures present and correctly ordered;
- Tables 5 through 7 to remain predictor-specific and readable;
- Figures 1 through 4 to retain at least 7-point essential text at both 170 mm and 708 px;
- Figure 5 to remain unchanged and readable;
- no clipping, collision, overlap, missing label, broken table scroller, or unexpected horizontal page overflow;
- captions, alt text, source-data links, dynamic navigation, country-coded sites, disclosures, and reciprocal links to remain correct;
- no console error attributable to the page; and
- the HTML, build, protected files, semantic evidence, QMD, profile, companion, figures, and source data to remain unchanged during QA.

Write the required visual files only into the existing excluded order48a evidence directory with the exact names already required by the verifier. Stop the server, close the QA tab, and prove that no listener remains.

## One post-QA verifier execution

After teardown, run exactly once:

```text
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 ORDER48A_VERIFY_PHASE=postqa GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order48b-semantic.SbpRAI R --vanilla --slave -f tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R
```

Require `ORDER48A_POSTQA=PASS`, 846/846 build stability, 3,386/3,386 protected stability, and a unique non-circular final acceptance manifest. The final HTML must remain `74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`.

After this passes, create one bounded owner completion record and one non-circular completion manifest. It may preserve the exact order48b and order48c stop evidence as historical inputs. Return every endpoint, verifier, semantic, QA, teardown, and manifest identity for independent acceptance.

## Absolute prohibitions

Do not run Quarto. Do not edit or replace the result QMD, result HTML, display manifest, figure, source data, companion, profile, corpus manifest, helper, refresh implementation, semantic engine, package state, lockfile, ledger, model, estimate, interval, p-value, FDR decision, or scientific artifact. Do not execute a model, prediction, bootstrap, simulation, resampling step, broad builder, commit, push, upload, companion render, or later render.

If a genuinely new failure appears, return one complete fail-closed stop. Do not patch or rerun.
