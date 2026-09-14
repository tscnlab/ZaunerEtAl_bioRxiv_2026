# REPORT-017 Preparation 06 third focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target test: `tests/test_preparation06_report.R`  
Outcome: **STOP. The authorized two-line deletion was exact and reversible, the test parsed, and the focused test exposed a third stale exact-string assertion for non-MDER invariance wording.**

No Quarto render, semantic HTML audit, browser server, or visual QA occurred.
The accepted QMD, existing HTML, profile, handoff, figure, source data,
scientific artifacts, and decisions were not edited. Preparation 07 remained
held.

## Preserved second stop

The preceding stopped checkpoint remains sealed in:

- `report017_preparation06_second_focused_test_stop.md`, SHA-256
  `36a6dce56e43ea5ca3d143edb9990fdcd0dc683c769d8d4d972e9feceee52d1e`;
- `report017_preparation06_second_focused_test_stop_manifest.csv`, SHA-256
  `44f31ff2ab392ab9ea2fd8895f2bc29cb47cfe48cea4e801947e12169643293d`.

The first stopped record and manifest also retain their sealed identities
`f85b4bb9a924fa2550aa902e4f28722db2389782a3a8c758a4fb7a814868bf27`
and `e23bac3f14d8c72357ff5699ee40e430baf86cea32469a8ba3ed82bc01087275`.

## Authorized second test-only edit

The test changed from the sealed post-first-repair SHA-256
`84e86cce8b9116474bd16f7234b8df2fd4d0896218a70b832f5cb06be3f76dce`,
17,120 bytes, to
`1947081d5103ccb91820184079377cd4b0515eed6b6493ef3a1b4a25d7654184`,
17,004 bytes. Exactly these two adjacent entries were deleted from
`mder_contract`:

```diff
-  "earlier 725 near-eye and 729 chest availability wording",
-  "superseded by these independently verified counts",
```

An in-memory reverse insertion at the original location reproduced the exact
pre-edit SHA-256
`84e86cce8b9116474bd16f7234b8df2fd4d0896218a70b832f5cb06be3f76dce`.
The already authorized reader-facing historical-method sentence and every
active-count, current-method, invariance, path, hash, table, figure,
provenance, qualification, and forbidden-call assertion remained unchanged.
`git diff --check` passed.

The revised test parsed successfully under normal project R 4.6.1 startup,
the project `.Rprofile`, `renv/activate.R`, and the project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. No package was installed or
updated, and `renv.lock` was not edited.

## Actual focused-test result

The focused test was run once after the authorized deletion against the
unchanged HTML:

```text
Rscript tests/test_preparation06_report.R _build/nathealth/notebooks/preparation/06_model_ready_datasets.html
```

The normal R 4.6.1 project startup completed. The run took 15.858 seconds and
returned exit status 1 with:

```text
Error: Missing MDER reporting contract: 25,620 non-MDER participant-day cells were exactly unchanged
Execution halted
```

The third failing literal is at current test line 188 inside `mder_contract`:

```r
"25,620 non-MDER participant-day cells were exactly unchanged",
```

The accepted reader-facing QMD states at lines 1946 to 1948 that the stored
comparison found `all 25,620 non-MDER participant-day cells exactly unchanged`
and retained all `618 × 47` site/daylight context values exactly. The test
requires a different exact word order. This is another reporting-test literal
mismatch, not evidence that the stored invariance result or any scientific
artifact changed. No disposition or repair of this third assertion was
inferred.

## Preservation result

The current scoped comparison contains 168 rows. It reports 167 byte-identical
paths, the one test file containing the two coordinator-authorized test-only
changes, and zero unexpected changes. The comparison is
`report017_preparation06_testrepair2_scoped_verification.csv`, SHA-256
`23823c23c5b06004c9824add12a3e5e995bbbacd5c15587f96e639e68469744a`.

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
record seals the third stopped state before any separately authorized test
disposition.
