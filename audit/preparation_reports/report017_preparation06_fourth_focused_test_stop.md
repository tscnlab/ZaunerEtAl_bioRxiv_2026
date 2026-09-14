# REPORT-017 Preparation 06 fourth focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target test: `tests/test_preparation06_report.R`  
Outcome: **STOP. The authorized invariance-sentence replacement was exact and reversible, the MDER contract advanced without another failure, and the focused test exposed a separate stale internal reporting-label assertion.**

No Quarto render, semantic HTML audit, browser server, or visual QA occurred.
The accepted QMD, existing HTML, profile, handoff, figure, source data,
scientific artifacts, and decisions were not edited. Preparation 07 remained
held.

## Preserved third stop

The preceding stopped checkpoint remains sealed in:

- `report017_preparation06_third_focused_test_stop.md`, SHA-256
  `e8cfa9bb16c6cab0f90492c195f2f942a2cf254a5c23f1794f4b71d9b641ac0f`;
- `report017_preparation06_third_focused_test_stop_manifest.csv`, SHA-256
  `62d79527234b4166b612dc426c968708a393210209ca6c2db9931ada243dec70`.

The earlier stopped records and manifests also retain their sealed identities.

## Authorized third test-only edit

The test changed from the sealed post-second-repair SHA-256
`1947081d5103ccb91820184079377cd4b0515eed6b6493ef3a1b4a25d7654184`,
17,004 bytes, to
`54f7ca192b3d051093acefe2423dfd711bb562892bc921ec40dff810a225be7b`,
17,096 bytes. The only authorized hunk was:

```diff
-  "25,620 non-MDER participant-day cells were exactly unchanged",
+  "The stored comparison found all 25,620 non-MDER participant-day cells exactly unchanged and retained all 618 × 47 site/daylight context values exactly.",
```

An in-memory reverse substitution reproduced the exact pre-edit SHA-256
`1947081d5103ccb91820184079377cd4b0515eed6b6493ef3a1b4a25d7654184`.
The replacement count was exactly one. Every other assertion remained
unchanged, including the current MDER method, active counts, `618 × 47`
site-context invariance, provenance paths and identities, table and figure
contracts, terminology, and forbidden execution gates. `git diff --check`
passed.

The revised test parsed successfully under normal project R 4.6.1 startup,
the project `.Rprofile`, `renv/activate.R`, and the project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. No package was installed or
updated, and `renv.lock` was not edited.

## Actual focused-test result

The focused test was run once after the authorized replacement against the
unchanged HTML:

```text
Rscript tests/test_preparation06_report.R _build/nathealth/notebooks/preparation/06_model_ready_datasets.html
```

The normal R 4.6.1 project startup completed. The run took 15.719 seconds and
returned exit status 1 with:

```text
Error: REPORT-011 QA is not declared.
Execution halted
```

The assertion occurs at current test line 400:

```r
expect_true(grepl("REPORT-011", visible_prose, fixed = TRUE), "REPORT-011 QA is not declared.")
```

The accepted reader-facing QMD does not contain the internal identifier
`REPORT-011`. The failure occurs after the complete `mder_contract` loop and
the other source, table, path, identity, and figure checks preceding line 400.
It is therefore a separate reporting-label assertion, not an MDER assertion
and not evidence that a scientific artifact or display value changed. No
disposition or repair of this assertion was inferred.

## Preservation result

The current scoped comparison contains 168 rows. It reports 167 byte-identical
paths, the one test file containing the coordinator-authorized test-only
changes, and zero unexpected changes. The comparison is
`report017_preparation06_testrepair3_scoped_verification.csv`, SHA-256
`e9b7e86bda56cdf155b0b7eec057116246c11fd725d7227c373a6816e4eaa3c7`.

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
record seals the fourth stopped state before any separately authorized test
disposition.
