# REPORT-017 order 33c: H02 recovered-baseline single verifier retry

Date: 2026-08-15

Owner task: `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Status: prepared for coordinator release; do not execute before release

## Purpose

Order 33b applied and parsed all four authorized test-only corrections. Its
single verifier process exited before the verifier suite began because the
temporary pre-order-33 baseline had disappeared across an environment restart.
The exact six-file baseline has now been reconstructed from the sealed full
source diff and independently verified by both SHA-256 and Git blob identity.

This continuation changes no source or test. It permits one environment-
evidence recovery and one retry of the exact unchanged verifier. It is not a
new document rewrite or a second test-patching loop.

Controlling recovery verification:
`audit/report_harmonization/report017_h02_order33b_baseline_recovery_verification.md`,
SHA-256 `dfa414ff95c9eaab475a1b7912be42c8eaccba00b46367f199ed834413551994`,
4,163 bytes.

## Current hard pins

Stop before execution if any differs:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H02.qmd` | `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d` | 57,148 |
| `audit/hypotheses/H02/H02_analysis_preparation.qmd` | `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1` | 55,146 |
| `tests/hypotheses/H02/test_h02_reader_report.R` | `0b044d2995645f6cfa50e28e2bdf330b8801002761a84520b169a1a3eb6771db` | 16,044 |
| `tests/hypotheses/H02/test_h02_preparation_report.R` | `d7ff45696f15d7bc02e8e66adabd02ee0c1f952f71fca35280885418c6b1181b` | 14,726 |
| `tests/hypotheses/H02/test_h02_paired_placement_display.R` | `873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a` | 3,790 |
| `audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R` | `ce7ad12f41e728ec3faf271855b0cdf82545ca934b3b1efbaedd3f265a5a7c2a` | 43,237 |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_source_diff.patch` | `7e05106b5da43332b13467bddabebae0f2b427db59a6c1a96b63cd85840a6543` | 73,581 |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_execution_record.md` | `0f22403fcd348cca85e3f0efd3ad882e1c622ec3c03e368749be092132d809c7` | 2,421 |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_source_audit.csv` | `faa6ff578195007129b6c20bbf236780f8bb3674875db42bbd214400146bb0ee` | 16,988 |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_test_results.csv` | `98adb6c17170f4079eb9825693bba9f7fe40790338ddde483d0503fe2f5cec5d` | 1,701 |
| `audit/hypotheses/H02/report017_order33_source_rewrite/H02_order33_source_manifest.csv` | `a4485f8ebeb641172014a3b6cfd60312721817a20315aa27a7032edf1a1ebe63` | 14,272 |
| `audit/handoffs/H02_worker_handoff.md` | `fbb74b2ed98756e1e8eb7f4b0be14cc8ec4a1873d766c1828390ebd9f5793441` | 45,489 |
| `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv` | `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7` | 12,457 |
| `artifacts/12_manifests/H02/H02_worker_output_hashes.csv` | `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331` | 40,049 |
| `_build/nathealth/notebooks/hypotheses/H02.html` | `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164` | 270,001 |
| `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html` | `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa` | 580,722 |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` | 7,480 |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` | 603,493 |

The coordination matrix is dispatch evidence only, not an owner hard pin.

## Recovery assets

Preserve and verify:

- recovery script
  `scripts/report_harmonization/reconstruct_h02_order33_baseline.R`, SHA-256
  `a06d9d73b5dd0bd74a75e50620803686eeda90a330b79cef6d62c999db3ba4ed`,
  5,861 bytes;
- recovered order-33a reader test copy
  `b7eed310a4939ab566faa7c1b8b818bc2f7ab105f59076d6c186bf783704d137`,
  15,038 bytes;
- recovered order-33a preparation test copy
  `b19c5a0beb18d9faf7506ab9dde9d73964a5d5b9fb9a13259865b5a358132a6d`,
  13,645 bytes;
- six-row reconstructed baseline inventory
  `e6f7869f1d32cecbfb7f421726731f8bfbbaab0c9f62bbc72f6fa6537344df49`,
  1,171 bytes.

The independently verified recovered baseline currently exists at
`/private/tmp/H02-order33-recovered.HO2BJm`. Rehash its six declared baseline
files against the durable six-row inventory before use. Extra recovery patch
and inventory files in that directory do not enter the verifier comparison.

If and only if that directory no longer exists, create one fresh empty
temporary directory and run the recovery script exactly once. Require the same
six SHA-256 values, byte counts, full Git blob identities, and PASS statuses
recorded in the durable inventory before continuing. Do not reconstruct by
hand or from Git history.

## Exactly one verifier retry

Do not edit either corrected test, the verifier, a QMD, or any other current
file before the retry. Do not run a preliminary focused test.

Run exactly once under R 4.6.1:

```bash
NATHEALTH_PROJECT_ROOT=<project-root> Rscript --vanilla \
  audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R \
  <verified-recovered-baseline-directory> \
  audit/hypotheses/H02/report017_order33_source_rewrite
```

Require the complete suite to report:

- 42 of 42 audit checks PASS;
- three of three focused tests PASS;
- 15 result tables and five result figures in the accepted order;
- 16 companion tables and four companion figures in the accepted order;
- 22 registration-link occurrences and 18 unique central anchors;
- the exact six-path worker and three-path preparation historical mismatch sets;
- 30 of 30 protected identities;
- passing non-circular source-manifest row audit and scoped diff check.

If any suite assertion fails, stop once without patching or rerunning and
return the complete failure set. If it passes, perform only the already
authorized non-analytical seal step. Update the handoff and current order-33
evidence so the final identities are mutually current. Do not rerun the
verifier while sealing.

## Preservation and prohibitions

No QMD or scientific artifact may change. Preserve the paired test, historical
manifests, stored HTML, profile, lockfile, and all non-H02 paths. No Quarto,
render, QMD execution, model fit or refit, prediction, simulation, bootstrap,
Shapley allocation, p-value calculation, figure or table regeneration, broad
manifest builder, shared edit, central ledger, package change, commit, push,
or upload.

Stop for independent harmonizer acceptance. H02 has no render authorization.
