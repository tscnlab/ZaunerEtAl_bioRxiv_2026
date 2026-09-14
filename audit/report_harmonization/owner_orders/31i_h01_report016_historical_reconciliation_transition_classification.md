# REPORT-017 order 31i: H01 historical reconciliation transition classification

Date: 2026-08-14

Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released for one bounded test-only seven-transition
classification and direct worker-manifest reseal. No render or scientific
execution is authorized. H01 and every later REPORT-017 target remain held.**

## Authority and dispatch state

The coordinator independently accepted order 31h as a legitimate controlled
stop and authorized this smallest follow-up. The H01 owner was verified idle,
and the full current H01 handoff was read before dispatch.

Stop on any drift from these pins:

- coordination matrix:
  `c7201df514faab0d7982b55a29d7c47031835ec3873a090345bbaf8fa529e701`;
- current H01 handoff:
  `00ae3a8e9aa6a9203f598d57f21ef462cbc676407f50c162fa0ab14c3457d9b0`;
- order 31h independent acceptance:
  `ae48ac36da18f054b61d4dd9a3c19a5154ae352cdbfeb066337ff236cb7d3985`;
- order 31h independent manifest:
  `d46a834c95075ad93bcef4be16b9c8ab69eed028e3d4b99ecd03c1aa1dcd1b66`;
- current REPORT-016 test:
  `b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620`,
  10,146 bytes;
- current worker manifest:
  `9a369002e9ebfdc9d99ba08c1bb86b2588d6308b7e844b36fea6336f95e47328`,
  393,672 bytes;
- current Stage 3 manifest:
  `16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e`,
  26,497 bytes;
- current reporting manifest:
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`,
  11,054 bytes;
- frozen historical reconciliation manifest:
  `audit/hypotheses/H01/report016/H01_REPORT016_reconciliation_manifest.csv`,
  SHA-256
  `15f88d244450f380112f1ab7adfadade56f518ea43daf8ef4fb0454278cdd5bf`,
  3,556 bytes;
- result QMD:
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`,
  90,640 bytes;
- preparation companion:
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`,
  54,405 bytes;
- stopped result HTML:
  `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`,
  1,626,484 bytes;
- reporting builder:
  `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`,
  68,214 bytes;
- model-support PNG:
  `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b`;
- model-support SVG:
  `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966`;
- focused display-refresh test:
  `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`;
- complete reporting test:
  `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`;
- accepted order 31f core manifest:
  `0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12`;
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- central deviation page:
  `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.

## Historical-manifest boundary

Preserve
`audit/hypotheses/H01/report016/H01_REPORT016_reconciliation_manifest.csv`
byte-for-byte. It remains truthful historical evidence. Do not refresh or
rewrite any row.

The manifest contains 15 data rows. Require its exact row set, exact frozen
hashes and byte counts, and exact current classification:

1. Eight rows must remain live-exact. Every one must match both its frozen
   identity in the historical manifest and its current file. Fail if any of
   these eight rows changes or is missing.
2. Exactly seven rows may differ from their frozen identities. The mismatch
   path set must equal the seven paths below with no omission, duplicate, or
   additional row.
3. Fail on an eighth mismatch, any unexpected path, any changed historical
   identity, or any changed live identity.

The seven exact historical-to-live transitions are:

| Path | Frozen SHA-256 / bytes | Required live SHA-256 / bytes |
|---|---|---|
| `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` | `476fa10db3383b2de82bb1824e9e5d89b8629d1666d080fe79520c5b81800806` / 22,735 | `16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e` / 26,497 |
| `artifacts/12_manifests/H01_reporting_artifacts.csv` | `4d39e9b1f76fed6fa56d8f9d210d5fd83b2d744e1e6dc67f60fcefe82b24b6b6` / 11,054 | `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079` / 11,054 |
| `notebooks/hypotheses/H01.qmd` | `8c7ca4e7382b1f9cc5fe07bb9cdf8a1318fd6e311f7df4e86556ae3e390abe96` / 87,441 | `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6` / 90,640 |
| `audit/hypotheses/H01/H01_analysis_preparation.qmd` | `685641fcb163e55b96b34778f25b276d8ce289bacd0ad73ece4351d859ebb4cb` / 54,286 | `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8` / 54,405 |
| `_build/nathealth/notebooks/hypotheses/H01.html` | `53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f` / 1,351,940 | `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa` / 1,626,484 |
| `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R` | `eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c` / 68,213 | `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7` / 68,214 |
| `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R` | `55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765` / 6,617 | Resolve from the exact current worker-manifest row after this test-only edit |

For the self-referential test transition, require exactly one worker-manifest
row for the test path. Read its live SHA-256 and byte count from that row,
require the row to match the edited test file, and use that resolved identity
as the seventh live transition. Do not hard-code the test's post-edit hash
inside the test itself.

## Exact test-only implementation

Edit only
`tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`.
Replace only the historical reconciliation-manifest all-rows equality gate
with the seven-transition classification above.

Preserve all existing gates, including:

- the accepted 40-target and 36-anchor dynamic deviation-link contract;
- the two exact order 31f image-transition classification;
- deviation-row and local-to-central ID mapping checks;
- every historical REPORT-016 scientific-protection check;
- the Stage 3, reporting, and worker-manifest gates; and
- every scientific artifact, result, and display-preservation assertion.

Require an exact one-file test diff and an exact reverse reconstruction to
the pre-edit test SHA-256
`b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620`.

## Direct worker-manifest reseal

After the test edit, update only the exact existing row for
`tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R` in
`artifacts/12_manifests/H01_worker_artifacts.csv`. Replace only that row's
SHA-256 and byte-count fields with the edited test's current identity.
Preserve the row path, producer, R version, ordinal position, and every other
row and field exactly.

Do not run the broad worker-manifest builder. Require:

- exactly one changed existing worker-manifest row;
- an exact row-level before/after ledger;
- exact reverse reconstruction to worker-manifest SHA-256
  `9a369002e9ebfdc9d99ba08c1bb86b2588d6308b7e844b36fea6336f95e47328`;
- every other worker-manifest row unchanged; and
- a complete all-row identity audit, retaining the already documented six
  accepted older pins outside this order and permitting no new mismatch.

Create only bounded new evidence and a non-circular owner seal for order 31i.
Do not rewrite any order 31f, 31g, or 31h historical record.

## Required verification

Use R 4.6.1 with the synchronized project library. Run only:

- parse checks for the edited test and new bounded evidence code;
- the complete REPORT-016 test;
- the order 31f focused display-refresh test;
- the complete H01 reporting test;
- exact historical-manifest row, frozen-identity, eight-live-exact, and
  seven-transition-set checks;
- exact worker-manifest row and all-row identity checks;
- exact preservation checks for the Stage 3 and reporting manifests and all
  files under `audit/hypotheses/H01/report016/`;
- exact test and worker-manifest diff and reverse proofs; and
- scoped `git diff --check`.

Record exact commands, runtimes, exit status, R and consequential package
versions, changed-file list, pre/post hashes and byte counts, the eight exact
rows, the seven transition rows, the worker-manifest row change, and all test
results.

## Prohibited actions and stop

Do not edit any QMD, historical reconciliation manifest, Stage 3 manifest,
reporting manifest, builder, PNG, SVG, HTML, source CSV, model, scientific
artifact, profile, semantic hook, package, lockfile, central ledger,
manuscript file, or another test. Do not render Quarto, fit or refit, predict,
simulate, bootstrap, resample, commit, push, or release another REPORT-017
target.

The only existing mutable H01 paths are the REPORT-016 test and its direct
worker-manifest row. New files are limited to bounded order 31i evidence.
Stop for independent harmonizer acceptance. H01 rerender, the H01 companion,
H02, the queued H03 synchronization, H04, and every later target remain held.
