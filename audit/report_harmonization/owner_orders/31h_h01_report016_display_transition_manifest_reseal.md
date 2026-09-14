# REPORT-017 order 31h: H01 display-transition classification and manifest reseal

Date: 2026-08-14

Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released for one bounded test-classification and current-manifest
reseal. No QMD, builder, image, HTML, profile, scientific artifact, or Quarto
render is authorized. H01 and every later REPORT-017 target remain held.**

## Authority and dispatch state

The coordinator accepted the order 31g controlled stop and authorized an
exact transition-only classification plus a manual direct-dependency manifest
reseal. The dispatch baseline is the harmonizer coordination matrix SHA-256
`ab99c7b26ccbdf3775dbaed7e20c988bbb40f163430bb683030ef3f236e8c323`.
The H01 owner was independently verified idle immediately before dispatch.

Stop on any drift from these pins:

- H01 QMD:
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`;
- current REPORT-016 test:
  `bbb994c0c339b39798307dcc8d4f98512518db55856e805ed53684594f6effea`,
  7,861 bytes;
- frozen historical REPORT-016 protection inventory:
  `audit/hypotheses/H01/report016/H01_REPORT016_protected_scientific_artifacts.csv`,
  SHA-256
  `94130a6de2e9e127b42267aed5e6dae52e2acc961fa3fb62666ffbf61b3789c7`;
- accepted order 31f core manifest:
  `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_core_manifest.csv`,
  SHA-256
  `0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12`;
- builder:
  `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`,
  68,214 bytes;
- model-support PNG:
  `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b`,
  238,682 bytes;
- model-support SVG:
  `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966`,
  54,757 bytes;
- dedicated refresh script:
  `f87486c0975dc560887c92e98f9423baaa56a926a3d6533e6197b625e23c4353`;
- focused display test:
  `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`;
- current Stage 3 manifest:
  `08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`;
- current worker manifest:
  `51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006`;
- reporting manifest, which must remain byte-identical:
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`;
- stopped H01 HTML:
  `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`;
- order 31g independent stop acceptance:
  `audit/report_harmonization/report017_h01_order31g_test_repair_stop_independent_acceptance.md`,
  SHA-256
  `c896e62e95a84f5f6536b1f2515d9425932f69cdd7ac829e189fa7b673cc2e95`;
  and
- order 31g 27-row owner manifest:
  `523bb9a7431d7cae032af92452947754ad2de0ac73caacfbc4a1ebe3c0041af3`.

## Exact REPORT-016 test classification

Edit only
`tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`.
Retain the accepted positive 40-target, 36-anchor dynamic-link contract
byte-for-byte. Replace only the historical all-rows equality gate with a
two-class fail-closed check:

1. Every frozen protected row except the two exact model-support image paths
   must match its historical SHA-256 and byte count exactly.
2. The exact exception set must equal, with no omission or extra row:
   - `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png`;
   - `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg`.
3. The historical CSV must continue to contain these exact frozen identities:
   - PNG SHA-256
     `601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a`,
     238,260 bytes;
   - SVG SHA-256
     `c054674bacdd41ca2d02fff0a784955dfd77caf7604dacc166ccd0c8e1cfc098`,
     54,756 bytes.
4. Their exact approved live transitions must be:
   - PNG SHA-256
     `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b`,
     238,682 bytes;
   - SVG SHA-256
     `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966`,
     54,757 bytes.
5. Verify the live image identities against the accepted order 31f core
   manifest at SHA-256
   `0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12`.
6. Fail on any third protected mismatch, duplicate exception, absent path,
   changed historical row, changed live transition, or changed core-manifest
   identity.

Do not weaken or replace any deviation-row, local-to-central ID, dynamic-link,
scientific-protection, historical-evidence, or other manifest gate. Require an
exact test diff and reverse reconstruction to the order 31g test identity.

Every file under `audit/hypotheses/H01/report016/`, especially the historical
protected inventory, must remain byte-for-byte unchanged.

## Manual Stage 3 manifest reseal

Edit
`artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` manually through a
bounded H01-owned reseal script. Do not run the general Stage 3 builder.

Update only these three existing rows to their exact current hashes and byte
counts:

- `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`;
- `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png`; and
- `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg`.

Add only the missing member paths from the accepted 18-row order 31f core
manifest. The core manifest is the closed allowlist. Existing member paths
must not be duplicated. The expected new paths are:

- `scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R`;
- `tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_stage3_model_support_pre_refresh.png`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_stage3_model_support_pre_refresh.svg`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_sealed_source_comparison.csv`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_plot_keys.csv`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_png_difference.csv`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_svg_difference.csv`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_package_versions.csv`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_audit.csv`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_execution.csv`;
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_protected_inventory_pre.csv`; and
- `audit/hypotheses/H01/report017_model_support_fdr_refresh/collect_h01_report017_31f_inventory.R`.

Append new rows in this closed allowlist order so every pre-existing row keeps
its original ordinal position. Use the core manifest's exact identity, byte,
role, producer, and R-version fields for new rows. Preserve every other
pre-existing row and field exactly. Require a row-level before/after ledger and
an exact reverse reconstruction of the pre-reseal Stage 3 manifest.

## Manual worker-manifest reseal

Edit `artifacts/12_manifests/H01_worker_artifacts.csv` manually through the
same bounded reseal implementation. Do not run the broad worker-manifest
builder because it could sweep unrelated accepted drift.

Update only this direct dependency chain:

- the existing builder, model-support PNG, and model-support SVG rows;
- the existing
  `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` row after the
  Stage 3 reseal;
- the existing
  `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R` row
  after the transition-classification edit; and
- the same closed set of missing order 31f core-manifest member paths added to
  the Stage 3 manifest.

Append new rows in the same closed allowlist order. Use existing worker
manifest conventions for new row metadata and record their exact producer and
R version. Preserve every unrelated pre-existing row, field, and ordinal
position exactly, including all accepted historical identities outside this
order. Require a row-level before/after ledger and exact reverse
reconstruction of the pre-reseal worker manifest.

Keep `artifacts/12_manifests/H01_reporting_artifacts.csv` byte-identical at
SHA-256
`d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`.

Do not rewrite the historical order 31f or order 31g owner manifests. Create a
new bounded transition/reseal record and a new non-circular owner manifest.

## Required verification

Use R 4.6.1 and the synchronized project library. Run only:

- parse checks for the edited test and new bounded reseal/evidence code;
- the complete REPORT-016 test;
- the order 31f focused display-refresh test;
- the complete H01 reporting test;
- exact all-row audits of the resealed Stage 3 and worker manifests;
- exact two-transition and exception-set checks;
- byte-for-byte preservation checks for every historical REPORT-016 file;
- exact row-level manifest diff and reverse checks;
- exact preservation of every unlisted row and path; and
- scoped `git diff --check`.

Record exact commands, runtime, exit status, R and consequential package
versions, changed-file list, pre/post hashes and byte counts, manifest row
counts, transition rows, preserved-row counts, and all test results.

## Prohibited actions and stop

Do not edit a QMD, builder, PNG, SVG, source CSV, model, estimate, interval,
p-value, FDR decision, diagnostic, scientific artifact, durable HTML, profile,
semantic hook, package, lockfile, central ledger, manuscript file, or another
test. Do not render Quarto, fit or refit, predict, simulate, bootstrap,
resample, commit, push, or release another REPORT-017 target.

The only mutable H01 paths are the REPORT-016 test, the two current manifests,
and new bounded transition/reseal evidence. Stop for independent harmonizer
acceptance. H01 rerender, the H01 companion, H02, the queued H03
synchronization, and every later target remain held.
