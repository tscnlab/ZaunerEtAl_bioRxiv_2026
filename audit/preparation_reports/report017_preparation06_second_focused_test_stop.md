# REPORT-017 Preparation 06 second focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target test: `tests/test_preparation06_report.R`  
Outcome: **STOP. The authorized literal replacement was applied exactly, the test parsed, and the focused test exposed a second stale exact-string assertion for superseded MDER availability wording.**

No Quarto render, browser server, semantic HTML audit, or visual QA occurred
during this recovery. The accepted QMD, rendered HTML, profile, handoff,
figure, source data, scientific artifacts, and decisions were not edited.
Preparation 07 remained held.

## Preserved first stop

The successful-render and first stale-literal stop remain sealed in:

- `report017_preparation06_failed_focused_test_verification.md`, SHA-256
  `f85b4bb9a924fa2550aa902e4f28722db2389782a3a8c758a4fb7a814868bf27`;
- `report017_preparation06_failed_focused_test_manifest.csv`, SHA-256
  `e23bac3f14d8c72357ff5699ee40e430baf86cea32469a8ba3ed82bc01087275`.

## Authorized test-only edit

The test changed from SHA-256
`e4b02061832be158372b54e1c473e0f221ab84cdd0aa7fb38e7d41cfb82f6f51`,
17,041 bytes, to
`84e86cce8b9116474bd16f7234b8df2fd4d0896218a70b832f5cb06be3f76dce`,
17,120 bytes. The only authorized hunk was:

```diff
-  "historical METRIC-003 provenance",
+  "The older ratio-of-integrals and profile-based exclusion records document an earlier method and are not active.",
```

An in-memory reverse substitution of the new literal with the old literal
reproduced the exact pre-edit SHA-256
`e4b02061832be158372b54e1c473e0f221ab84cdd0aa7fb38e7d41cfb82f6f51`.
The replacement count was exactly one. Every other MDER contract token,
negative assertion, path, hash, table, figure, terminology, and forbidden-call
gate remained unchanged. `git diff --check` passed.

The test parsed successfully under normal project R 4.6.1 startup with the
project `.Rprofile`, `renv/activate.R`, and project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. No package was installed or
updated, and `renv.lock` was not edited.

## Actual focused-test result

The focused test was run once after the authorized edit against the existing
HTML:

```text
Rscript tests/test_preparation06_report.R _build/nathealth/notebooks/preparation/06_model_ready_datasets.html
```

The normal R 4.6.1 project startup completed. The run took 16.433 seconds and
returned exit status 1 with:

```text
Error: Missing MDER reporting contract: earlier 725 near-eye and 729 chest availability wording
Execution halted
```

The second failing literal is at current test line 188 inside `mder_contract`:

```r
"earlier 725 near-eye and 729 chest availability wording",
```

The test searches this contract in reader-visible text after fenced code is
removed. The accepted QMD retains `725` and `729` within a protected internal
validation check, but it does not contain this reader-facing exact sentence.
The focused test therefore stopped on another exact-string reporting
assertion. This is not evidence that a scientific artifact or current MDER
value changed. No disposition or repair of this second assertion was inferred.

## Preservation result

The current scoped comparison contains 168 rows. It reports 167 byte-identical
paths, the one coordinator-authorized test-file change, and zero unexpected
changes. The comparison is
`report017_preparation06_testrepair_scoped_verification.csv`, SHA-256
`75e140351579a55b457600846ba61c11f88315ff20301fd0a86e37c7b0a37e37`.

The protected identities remained:

| File | SHA-256 |
|---|---|
| `notebooks/preparation/06_model_ready_datasets.qmd` | `2067db45d46b49bec34985f68eb9e10d5e35377548c5103218321261d50f4c5b` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `_build/nathealth/notebooks/preparation/06_model_ready_datasets.html` | `2179253dc28326c0cef4084327e3eb76f755bdc1d493209697da02f5c3855814` |
| `_build/nathealth/notebooks/preparation/06_model_ready_datasets_files/figure-html/fig-site-composition-1.png` | `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da` |
| `artifacts/08_diagnostics/preanalysis_comparison/categorical_levels.csv` | `809d109d3647ef4ac1798ef9eb59c06e2c7db41f5b9ce1dade4d0a8b583f0a22` |
| `audit/handoffs/preparation_reports_worker_handoff.md` | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` |

No loopback server was started and no browser was opened for this page. This
record seals the second stopped state before any separately authorized test
disposition.
