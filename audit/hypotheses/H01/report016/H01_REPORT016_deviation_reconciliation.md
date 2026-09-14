# H01 REPORT-016 deviation reconciliation

Date: 2026-08-12  
Status: H01-owner reconciliation complete; central mapping confirmation and dynamic-link release pending

## Boundary

This bounded repair changes only the stored H01 deviation display, its deterministic producer, and audit/manifests that describe the repair.
No model, prediction, bootstrap, p-value, FDR value, estimate, interval, sample, diagnostic, sensitivity result, or claim was recomputed.

The pre-correction CSV is preserved byte-for-byte at
`audit/hypotheses/H01/report016/H01_stage3_deviations_pre_REPORT016.csv` with SHA-256 `ecbf772d084582c643e1ee4523a8171db419d4e998f5d846ea34228238a6f709`.

## Reconciled scientific wording

The current display now defines MDER under DEV-058/METRIC-010 as the arithmetic mean of viable momentary one-minute ratios, assigns DEV-057 to the complete exact-zero melEDI-day exclusion, and states that the registered longest-period midpoint is retained while mean timing is a separately labelled adapted sensitivity.

Exact row-level before/after evidence is in `audit/hypotheses/H01/report016/H01_REPORT016_row_reconciliation.csv`.

## H01-local decision IDs

All eight H01-local IDs were classified by the H01 scientific owner as decision-layer aliases or implementation details of existing central records; no genuinely distinct unresolved deviation was identified.
The explicit proposed mapping is in `audit/hypotheses/H01/report016/H01_REPORT016_local_id_mapping.csv`.
The coordinator must confirm that mapping before REPORT-016 adds any dynamic preregistration-deviation link.

## Preservation evidence

The protected inventory contains 1161 non-display H01 scientific artifacts. Every SHA-256 and byte count matched before and after this repair.
The inventory is `audit/hypotheses/H01/report016/H01_REPORT016_protected_scientific_artifacts.csv`.

Held source/report identities were not changed. Current identities:

- `artifacts/09_tables/H01/stage3/H01_stage3_deviations.csv`: `2671fc9af9d6764a8b64c1417c8c84b3eb63a2f0a0c2c4ff4adb4eddeb03a347` (5916 bytes)
- `notebooks/hypotheses/H01.qmd`: `8c7ca4e7382b1f9cc5fe07bb9cdf8a1318fd6e311f7df4e86556ae3e390abe96` (87441 bytes)
- `audit/hypotheses/H01/H01_analysis_preparation.qmd`: `685641fcb163e55b96b34778f25b276d8ce289bacd0ad73ece4351d859ebb4cb` (54286 bytes)
- `_build/nathealth/notebooks/hypotheses/H01.html`: `53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f` (1351940 bytes)
- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`: `476fa10db3383b2de82bb1824e9e5d89b8629d1666d080fe79520c5b81800806` (22735 bytes)
- `artifacts/12_manifests/H01_reporting_artifacts.csv`: `4d39e9b1f76fed6fa56d8f9d210d5fd83b2d744e1e6dc67f60fcefe82b24b6b6` (11054 bytes)
- `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`: `eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c` (68213 bytes)

The main report has deliberately not been rendered in this bounded pass.
No dynamic deviation-page link has been added.
