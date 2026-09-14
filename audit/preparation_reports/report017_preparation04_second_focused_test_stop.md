# REPORT-017 Preparation 04 second focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target test: `tests/test_preparation04_report.R`  
Outcome: **STOP. The authorized literal replacement was applied exactly, normal project startup completed, and the focused test exposed a distinct search-scope mismatch.**

No Quarto render, browser server, or visual QA occurred during this recovery.
The accepted QMD, rendered HTML, profile, handoff, figure, data, artifacts,
decisions, and scientific outputs were not edited. Preparation 05 remained
held.

## Preserved first stop

The successful-render and stale-literal stop remains sealed in:

- `report017_preparation04_failed_focused_test_verification.md`, SHA-256
  `74c62c477ab2acad960b67872f662e12c7a61b27147a6b9387d7f570af9c1a92`;
- `report017_preparation04_failed_focused_test_manifest.csv`, SHA-256
  `430625c29f3d79ac009dce1adff127c3cb13556ec5a133939a36f191b3defa6a`.

## Authorized test-only edit

The test changed from SHA-256
`bab6b85bcd7c445c41681231ce84e1420816a7cc5887883b90e27534ae92080d`,
13,332 bytes, to
`ee48dc13b6d019095bf2cef39da220ffe59b0342ca3bcb0eec4ff31c2ba1d26a`,
13,268 bytes. The only recovery hunk replaced these two obsolete tokens:

```r
"earlier 725 near-eye and 729 chest availability wording",
"is superseded by these independently verified counts",
```

with the accepted visible literal:

```r
"earlier 725/729 availability record is superseded",
```

The assertions for `687 of 811`, `723 of 897`, current means and medians,
`25,620 non-MDER participant-day cells exactly unchanged`, METRIC-010,
METRIC-011, PREP-003, FIND-044, decisions, manifests, tables, figures, paths,
hashes, and forbidden execution calls remained unchanged. `git diff --check`
passed.

## Actual focused-test result

The focused test was run once after that edit:

```text
Rscript tests/test_preparation04_report.R _build/nathealth/notebooks/preparation/04_metric_derivation.html
```

The run completed `.Rprofile` and `renv` activation under R 4.6.1 with the
approved narrow access to the existing user-owned cache. It then returned exit
status 1 with this assertion result:

```text
Error: Missing MDER rule: earlier 725/729 availability record is superseded
Execution halted
```

This was not an environment-startup failure. The test defines `visible_flat`
from `strip_fenced_blocks(lines)`, which intentionally removes every fenced R
chunk. The accepted literal is produced by a native `gt` table and therefore
occurs inside the table-producing R chunk rather than in prose outside fenced
blocks. It is present in the complete QMD source and appears twice in the
existing rendered HTML. The prose-only `visible_flat` object cannot contain
it by construction.

This is a test-harness search-scope mismatch, not a scientific discrepancy or
a missing reader-facing statement.

## Preservation result

The current scoped comparison contains 106 rows. It reports 105 unchanged
paths, one coordinator-authorized test-file change, and zero unexpected
changes. The comparison is
`report017_preparation04_testrepair_scoped_verification.csv`, SHA-256
`d98329dec9e57dca303978bcc09066d0c40695c0964868ff0c0abeed9440b875`.

The protected identities remained:

| File | SHA-256 |
|---|---|
| `notebooks/preparation/04_metric_derivation.qmd` | `86041585edfb60ba0f3137d268418e7479b369be859b41350d2347bd81e064a6` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `audit/handoffs/preparation_reports_worker_handoff.md` | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` |
| `_build/nathealth/notebooks/preparation/04_metric_derivation.html` | `fba5e6f81251123b16deb6728321a558c3722c6bc26c4a946edf8712c570dd06` |
| `_build/nathealth/notebooks/preparation/04_metric_derivation_files/figure-html/fig-mder-availability-1.png` | `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce` |

This record seals the second stopped state before any separately authorized
test-harness repair.
