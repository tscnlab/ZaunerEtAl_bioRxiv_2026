# REPORT-014/017 order 33a: H02 consolidated verification-harness correction

Date: 2026-08-14

Owner task: `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Controlling reader-harmonization decisions: REPORT-014 and REPORT-017

Status: authorized after independent harmonizer review of the complete order-33 stopped return

## Purpose

Order 33 completed the one-pass H02 result and preparation/provenance rewrite, then stopped after its single permitted source-only verification suite. Independent review confirms that the seven failures are verification-classification defects. They do not demonstrate drift in the H02 sources, formulas, estimands, values, endpoints, links, or protected scientific artifacts.

This order corrects all seven known verification issues together and permits exactly one complete source-only R 4.6.1 suite. It does not reopen the H02 document rewrite.

## Required preflight identities

Stop without editing if any of these differ:

| Path | SHA-256 |
|---|---|
| `notebooks/hypotheses/H02.qmd` | `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d` |
| `audit/hypotheses/H02/H02_analysis_preparation.qmd` | `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1` |
| `tests/hypotheses/H02/test_h02_reader_report.R` | `a78625dfa4ce50135d488fc273bc7c023fb646782dbf1d619906dc3043923a8f` |
| `tests/hypotheses/H02/test_h02_preparation_report.R` | `8e111af709ba482ab677f04ed19e443b8420c0144de1d981cd7c9017bb0970d8` |
| `tests/hypotheses/H02/test_h02_paired_placement_display.R` | `e6d907140256a3710c633a0c215fbe5e1c5c7b37caecdab999c59c53d5b4af9f` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R` | `1e30541f8ca1c5593d326b012075d42d304d28bed436eb135573500fae78432e` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_source_manifest.csv` | `53ba7ed55f481ad97fab281e481ec3f1809dfe2a587d0632f2906e6622ded57d` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_execution_record.md` | `47f3ef27827f2569eaba04434fed18046f0f28c6333936d010890d45ba5e2e42` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_source_audit.csv` | `896d964e8c3521748f614731d02a274582870af06d2e67f2b68e51646c8e641d` |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_test_results.csv` | `1c1807693c3eca861ab6710754c54c6691ebe817b3d3b8b954a561055b88ff48` |
| `audit/handoffs/H02_worker_handoff.md` | `fbb74b2ed98756e1e8eb7f4b0be14cc8ec4a1873d766c1828390ebd9f5793441` |
| `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv` | `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7` |
| `artifacts/12_manifests/H02/H02_worker_output_hashes.csv` | `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331` |
| `_build/nathealth/notebooks/hypotheses/H02.html` | `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164` |
| `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html` | `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa` |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The dispatch-time coordination-matrix identity is coordination evidence only and is not an owner execution pin.

## Exact permitted corrections

### 1. Stable unlabeled-chunk classification

In `run_h02_order33_source_audit.R`, replace the line-number-dependent comparison for the companion's one unlabeled R chunk with a fail-closed structural contract:

- compare all explicit chunk labels exactly as an unordered set;
- require exactly one unlabeled R chunk before and exactly one after;
- require the complete body of that unlabeled chunk to be byte-identical before and after;
- retain parsing of every chunk;
- do not add a label to the QMD.

Independent R 4.6.1 review has already confirmed one unlabeled chunk in each source and byte-identical bodies. The synthetic names `unnamed-line-309` and `unnamed-line-319` are not document identifiers.

### 2. Exact companion numeric-token transition

Keep a fail-closed numeric-token comparison. Do not drop numeric-token protection or compare counts alone.

For the companion only, require all of the following:

- 476 numeric tokens before and 476 after;
- every token multiplicity other than tokens `2` and `11` is identical;
- token `2` occurs exactly once fewer after the rewrite;
- token `11` occurs exactly once more after the rewrite;
- the already required frozen `artifacts/11_source_data/H02/...` links are present;
- the internal `H02-F1-site-pattern` reader label is absent;
- formulas, inline R, assignments, endpoint code, artifact references, and protected scientific outputs retain their existing independent checks.

This exact delta comes from the approved removal of the internal family identifier and addition of the frozen `11_source_data` link path. Any different token, count, or multiplicity change must fail.

### 3. Endpoint set comparison without positional names

In `run_h02_order33_source_audit.R`, compare the result endpoint values after removing only R vector names introduced by `unlist()`. Require:

- exactly the same 15 table IDs and five figure IDs before and after;
- no duplicate endpoint ID;
- every endpoint exactly once;
- the already implemented exact reader-first endpoint order check to remain unchanged and pass;
- the existing endpoint-code byte-preservation check to remain unchanged and pass.

Do not weaken the endpoint set or order contracts.

### 4. Exact historical worker-manifest mismatch set

The historical worker manifest must remain byte-identical. Its exact live mismatch set now contains the original three paths plus the three tests that order 33 explicitly changed:

1. `audit/handoffs/H02_shared_change_request.md`
2. `audit/hypotheses/H02/H02_analysis_preparation.qmd`
3. `notebooks/hypotheses/H02.qmd`
4. `tests/hypotheses/H02/test_h02_paired_placement_display.R`
5. `tests/hypotheses/H02/test_h02_preparation_report.R`
6. `tests/hypotheses/H02/test_h02_reader_report.R`

Update this exact expected set in:

- `run_h02_order33_source_audit.R`;
- `tests/hypotheses/H02/test_h02_reader_report.R`;
- `tests/hypotheses/H02/test_h02_preparation_report.R`.

Require exact set equality and fail on a seventh path. Preserve the historical manifest SHA-256 assertion and the unchanged three-path preparation-manifest mismatch contract.

### 5. Semantic FDR assertion

In `tests/hypotheses/H02/test_h02_paired_placement_display.R`, replace only the over-specific literal `FDR-adjusted` source assertion with the accepted semantic vocabulary contract. Require:

- `false-discovery-rate (FDR)-adjusted` at first use;
- `FDR adjustment` as the later compact term;
- no reader-facing standalone `BH` abbreviation;
- no reader-facing `H02-F1-site-pattern` identifier.

Do not change the QMD wording.

## Files that may change

- `audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R`;
- `tests/hypotheses/H02/test_h02_reader_report.R`;
- `tests/hypotheses/H02/test_h02_preparation_report.R`;
- `tests/hypotheses/H02/test_h02_paired_placement_display.R`;
- directly dependent files under `audit/hypotheses/H02/report017_order33_source_rewrite/`;
- `audit/handoffs/H02_worker_handoff.md`;
- one new non-circular order-33a correction record and manifest under `audit/hypotheses/H02/report017_order33_source_rewrite/`.

Do not edit either H02 QMD, any historical H02 manifest, any HTML or `_build` file, any source-data or scientific artifact, the profile, a shared file, another hypothesis, or a harmonizer-owned global record.

## One-suite execution rule

Before execution, inspect and parse the complete corrected verifier and all three corrected tests. Then run the complete order-33 source-only verifier exactly once under R 4.6.1. That one verifier invocation must run all three focused tests and every existing source, formula, inline-R, endpoint, registration-link, no-write, historical-manifest, protected-artifact, reverse, and scoped-diff check.

Do not run a preliminary subset of the same tests. If any check fails beyond the seven corrections specified here, stop without patching or rerunning and return the complete new failure set.

After a fully passing suite, a non-analytical seal-only step may update the handoff and rebuild the non-circular source manifest so that their final hashes are mutually current. It must not rerun the QMDs or scientific checks. Audit every manifest row and byte count under R 4.6.1.

## Required final evidence

Return:

- exact pre/post hashes and byte counts for the verifier and three tests;
- an exact diff proving only the five permitted logical corrections above;
- R 4.6.1 parse success for all four R files;
- the single verifier command, runtime, exit status, and full 42-check and three-test result;
- explicit proof of the one/one byte-identical unlabeled chunk body;
- the exact 476/476 numeric-token delta table;
- exact endpoint set, uniqueness, count, order, and endpoint-code preservation;
- exact six-path worker mismatch and three-path preparation mismatch sets;
- 30/30 protected identities;
- unchanged QMD, historical-manifest, HTML, profile, `renv.lock`, and scientific-artifact identities;
- final handoff, execution record, audit CSV, test-results CSV, verifier, and non-circular manifest identities;
- scoped `git diff --check`.

Stop for independent harmonizer acceptance. No H02 render is released by this order.

## Prohibitions

No Quarto render, QMD execution, model fit or refit, prediction, simulation, bootstrap, Shapley calculation, p-value calculation, figure or table regeneration, broad manifest builder, package or lockfile change, shared-profile edit, central-ledger edit, commit, push, or work on another hypothesis.
