# REPORT-014/017 order 33b: H02 final masked-test correction

Date: 2026-08-14

Owner task: `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Controlling reader-harmonization decisions: REPORT-014 and REPORT-017

Status: authorized after a complete independent replay of the remaining source-only test paths

## Purpose

Order 33a corrected all seven failures from order 33. Its single verifier exposed two older test defects, and the independent full temporary-copy replay exposed two more farther down the same tests. All four are now known together. The temporary replay passes the complete reader, preparation, and paired-placement test paths under R 4.6.1.

Apply the four test-only corrections below as one coherent change, then run exactly one complete order-33 verifier. Do not edit either H02 QMD or reopen the document rewrite.

## Required preflight identities

Stop without editing if any of these differ:

| Path | SHA-256 |
|---|---|
| `notebooks/hypotheses/H02.qmd` | `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d` |
| `audit/hypotheses/H02/H02_analysis_preparation.qmd` | `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1` |
| `tests/hypotheses/H02/test_h02_reader_report.R` | `b7eed310a4939ab566faa7c1b8b818bc2f7ab105f59076d6c186bf783704d137` |
| `tests/hypotheses/H02/test_h02_preparation_report.R` | `b19c5a0beb18d9faf7506ab9dde9d73964a5d5b9fb9a13259865b5a358132a6d` |
| `tests/hypotheses/H02/test_h02_paired_placement_display.R` | `873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R` | `ce7ad12f41e728ec3faf271855b0cdf82545ca934b3b1efbaedd3f265a5a7c2a` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_execution_record.md` | `0f22403fcd348cca85e3f0efd3ad882e1c622ec3c03e368749be092132d809c7` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_source_audit.csv` | `faa6ff578195007129b6c20bbf236780f8bb3674875db42bbd214400146bb0ee` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_test_results.csv` | `98adb6c17170f4079eb9825693bba9f7fe40790338ddde483d0503fe2f5cec5d` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33a_unlabeled_chunk_proof.csv` | `92ecfd3218aed87525b8f1a0ef6b90ede0d737e2159bf104edcd637c74ed2313` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33a_companion_numeric_token_delta.csv` | `90f83bd98ef3af0762220aee65d6299342b1bcf867c4b86c7439fcad46f0ddfd` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_source_manifest.csv` | `a4485f8ebeb641172014a3b6cfd60312721817a20315aa27a7032edf1a1ebe63` |
| `audit/handoffs/H02_worker_handoff.md` | `fbb74b2ed98756e1e8eb7f4b0be14cc8ec4a1873d766c1828390ebd9f5793441` |
| `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv` | `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7` |
| `artifacts/12_manifests/H02/H02_worker_output_hashes.csv` | `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331` |
| `_build/nathealth/notebooks/hypotheses/H02.html` | `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164` |
| `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html` | `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa` |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The dispatch-time coordination-matrix identity is evidence only, not an owner execution pin.

## Exact permitted corrections

### 1. Multiline registered-hypothesis assertion

In `tests/hypotheses/H02/test_h02_reader_report.R`:

- derive a semantic source string by removing only leading Markdown blockquote markers and collapsing whitespace;
- require the exact sentence `Within-participant variance in hourly melanopic EDI, with participants nested in sites, exceeds variance between sites.` in that semantic string;
- do not change the QMD or weaken any formula, sample, value, endpoint, or link assertion.

The accepted source intentionally wraps the statement across blockquote lines 733 and 734.

### 2. Reader-terminology scope

In the same reader test:

- derive reader-visible prose by removing complete fenced code blocks while retaining all surrounding prose and inline code;
- apply the existing `v0`, `submitted`, `manuscript`, `legacy`, and `pilot` exclusion to that reader-visible prose;
- retain all existing assignment, artifact-reference, endpoint, source-data, and no-scientific-call protections for executable source;
- preserve the code-only protected names `manuscript_prepared_stability.csv` and `manuscript_prepared_data__glasses__all_available`.

Fail if any forbidden term remains in reader-visible prose. Do not rename code objects or artifacts.

### 3. Literal Markdown model-frame definition

In `tests/hypotheses/H02/test_h02_preparation_report.R`:

- collapse source whitespace for this assertion;
- use a fixed literal match for `A **model frame** is the exact set of rows and variables used for one fitted model`;
- do not pass unescaped Markdown asterisks to PCRE.

### 4. Parsed forbidden-call audit

In the same preparation test, replace only the raw-text call-like regex scan with a parsed source audit:

- parse every R chunk without evaluating it;
- recursively collect actual function-call heads, including namespace-qualified calls such as `mgcv::bam`;
- require the complete existing forbidden-call set to be absent;
- ignore string literals and comments when classifying calls;
- preserve the visible model-specification string `mgcv::bam()` in `tbl-h02-prep-parameters` because it describes the accepted stored analysis and does not execute a model.

Retain the existing no-write, endpoint, formula, artifact, historical-manifest, and protected-identity checks. Do not source or run QMD chunks.

## Files that may change

- `tests/hypotheses/H02/test_h02_reader_report.R`;
- `tests/hypotheses/H02/test_h02_preparation_report.R`;
- directly dependent files under `audit/hypotheses/H02/report017_order33_source_rewrite/`;
- `audit/handoffs/H02_worker_handoff.md`;
- one new non-circular order-33b correction record and manifest under the H02 evidence directory.

The verifier, paired-placement test, both QMDs, historical manifests, existing HTML files, scientific artifacts, profile, and lockfile must remain byte-identical.

## One-suite execution rule

Before execution, inspect and parse both corrected tests completely. Then run the complete order-33 source-only verifier exactly once under R 4.6.1. It must execute every audit check and all three focused tests.

Do not run preliminary project tests. The independent harmonizer has already replayed the four changes on temporary copies and obtained PASS for all three complete focused test paths.

The single verifier must report:

- 42 of 42 audit checks PASS;
- three of three focused tests PASS;
- exact 15-table and five-figure result endpoint set and order;
- exact 16-table and four-figure companion endpoint set and order;
- exact 22 registration-link occurrences and 18 unique central anchors;
- exact six-path worker and three-path preparation historical mismatch sets;
- 30 of 30 protected identities;
- a passing non-circular source-manifest row audit;
- scoped `git diff --check` PASS.

If any other check fails, stop without patching or rerunning and return the complete failure set.

After a fully passing verifier, perform only the previously authorized non-analytical seal step. Update the handoff, correction record, and non-circular source manifest so their final identities are mutually current. Audit all manifest rows and byte counts under R 4.6.1. Do not rerun the verifier during sealing.

## Required final evidence

Return:

- exact pre/post hashes and bytes for both corrected tests;
- one exact diff covering all four corrections;
- R 4.6.1 parse success for both tests;
- the single verifier command, runtime, exit status, 42-check result, and three-test result;
- proof that the blockquote sentence is matched after marker removal and whitespace normalization;
- proof that forbidden reader terms are absent from visible prose and that the two protected code-only names remain;
- the parsed actual-call inventory and absence of every forbidden call;
- preservation of all order-33a corrections and evidence;
- unchanged QMD, verifier, paired test, historical manifests, HTML, profile, lockfile, and scientific artifacts;
- final execution record, audit CSV, test-results CSV, handoff, correction record, verifier, and non-circular manifest identities;
- scoped `git diff --check`.

Stop for independent harmonizer acceptance. No H02 render is released.

## Prohibitions

No Quarto render, QMD execution, model fit or refit, prediction, simulation, bootstrap, Shapley calculation, p-value calculation, figure or table regeneration, broad manifest builder, package or lockfile change, shared-profile edit, central-ledger edit, harmonizer-global edit, commit, push, or work on another hypothesis.
