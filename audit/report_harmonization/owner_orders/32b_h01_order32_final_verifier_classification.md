# REPORT-017 order 32b: H01 final consolidated verifier classification

Date: 2026-08-15

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: coordinator-authorized verifier-only order; all H01 rendering remains held

## Purpose

Resolve all four order-32a failures together without revising the assembled H01 documents. Three failures share one empty-result type cause. The fourth is the exact technical identifier `SHA-256` being counted as a scientific number. All four focused tests already pass.

Controlling records:

- Order-32a stopped-state independent acceptance: `audit/report_harmonization/report017_h01_order32a_stopped_state_independent_acceptance.md`.
- Complete four-failure disposition: `audit/report_harmonization/report017_h01_order32a_four_failure_disposition.md`.
- Order-32a owner manifest: `audit/hypotheses/H01/report017_order32a_verifier_repair/H01_order32a_stopped_non_circular_manifest.csv`, SHA-256 `81b1e6000219987b8fb3ca9ff721647e72438dab324d857652b1fbfa55697427`.
- Current order-32a verifier: `audit/hypotheses/H01/report017_order32a_verifier_repair/run_h01_order32a_source_audit.R`, SHA-256 `620b2fe71fcf25c542afa9c435f925887454db895059cbd4aa8617046369ea18`, 34,808 bytes.
- Retained exact baseline: `/private/tmp/H01-order32a-baseline.A5iuk8`.
- Dispatch-time coordination evidence: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `50b02a88ad0c45d83e1d3505d4281385029329699d55820ac013194ae44d009d`. This mutable global identity is evidence only and is not an owner execution pin.

## Hard preservation contract

Before writing, require every row of the order-32a owner manifest and all 28 order-32a dispatch identities to remain exact. Independently require the retained baseline to contain exactly the following six files and identities:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H01.qmd` | `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6` | 90,640 |
| `audit/hypotheses/H01/H01_analysis_preparation.qmd` | `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8` | 54,405 |
| `artifacts/12_manifests/H01_reporting_artifacts.csv` | `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079` | 11,054 |
| `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` | `16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e` | 26,497 |
| `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv` | `bae856c2bb75df317f476e7e993178061628c0fcdbc6795a4b88f78843f8d9d0` | 13,841 |
| `artifacts/12_manifests/H01_worker_artifacts.csv` | `debce70f59c8e2c401ad36291694604246349633079bcd4d706aba6cf4d548c5` | 393,672 |

Preserve every current H01 source, test, current manifest, handoff, held HTML, profile, original verifier and stopped record, complete order-32a verifier and evidence file, and baseline byte-for-byte.

## Authorized files and exact changes

Create only a new directory:

`audit/hypotheses/H01/report017_order32b_final_verifier_classification/`

Inside it:

1. Copy the order-32a verifier to `run_h01_order32b_source_audit.R`.
2. In `multiset_difference()`, wrap the existing returned `unlist(...)` expression in `as.character(...)`. Do not change its table construction, positive-difference selection, replication, order, or `use.names = FALSE` behavior.
3. At the start of `extract_numeric_tokens()`, before `regmatches()`, add exactly:

   ```r
   text <- gsub("SHA-256", "SHA", text, fixed = TRUE)
   ```

4. Preserve every other verifier byte and all 66 source contracts and four focused-test calls.
5. Create only a bounded seal script, execution record, reverse proof, and non-circular manifest inside this new directory.

The reverse proof must undo exactly the two classification changes and reproduce the order-32a verifier SHA-256 `620b2fe71fcf25c542afa9c435f925887454db895059cbd4aa8617046369ea18`, 34,808 bytes.

## Single complete execution

Do not run a preliminary parse, focused test, partial verifier, or dry run. Run the complete order-32b verifier exactly once under R 4.6.1 against the retained exact baseline:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  NATHEALTH_PROJECT_ROOT=<project> \
  Rscript --vanilla \
  audit/hypotheses/H01/report017_order32b_final_verifier_classification/run_h01_order32b_source_audit.R \
  /private/tmp/H01-order32a-baseline.A5iuk8 \
  audit/hypotheses/H01/report017_order32b_final_verifier_classification
```

Require all 66 source contracts and all four focused tests to pass. The complete verifier must retain every existing formula, numeric-token, endpoint, link, registration, historical, manifest, and source-preservation check.

If R startup or any assertion fails, do not patch or rerun. Seal the complete failure list and all identities once, then stop.

If the verifier passes, run only the bounded evidence seal. Require:

- exact preservation of every hard input and all six baseline files;
- exact two-change reverse proof;
- complete verifier output and acceptance record;
- exact R version, package versions, command, environment, runtime, and exit status;
- a non-circular manifest that excludes itself;
- scoped `git diff --check`.

## Prohibited work

Do not edit a QMD, test, current manifest, handoff, HTML, profile, configuration, previous verifier or evidence file, scientific artifact, source data, package, or lockfile. Do not execute Quarto or a QMD, render, fit, refit, predict, simulate, bootstrap, resample, run a reporting builder, recompute a scientific quantity, regenerate an artifact, commit, or push.

Stop after the one complete verifier run and sealed return. H01 result and companion renders and every later REPORT-017 render remain held pending independent acceptance.
