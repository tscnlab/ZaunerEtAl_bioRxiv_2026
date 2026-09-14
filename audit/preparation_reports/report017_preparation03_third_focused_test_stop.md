# REPORT-017 Preparation 03 third focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `tests/test_preparation03_report.R`  
Outcome: **STOPPED at the retained exact-hash check because its literal identified an earlier version of the controlling MDER decision.**

This record is distinct from the first non-discrepancy-literal stop and the
second reader-link stop. No Quarto render, QMD edit, configuration edit,
scientific computation, artifact edit, decision-file edit, or loopback server
occurred during this recovery attempt.

## Starting identities

| File | SHA-256 |
|---|---|
| `tests/test_preparation03_report.R` | `7b0d2677a343b17f1fb6817c27879431fa982c85b7576291567cf462660c7406` |
| `audit/decisions/mder_mean_of_viable_ratios.md` | `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de` |
| `notebooks/preparation/03_reference_profiles.qmd` | `a0d9bc85a906b6c83edd8019421b012220c11e2d72988724fd9d1439fbc57a3a` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `_build/nathealth/notebooks/preparation/03_reference_profiles.html` | `262705d82ad3add77028492502f94b45d526424c25c1f5f3c8b4ac33b75b4c2c` |
| `artifacts/12_manifests/reference_profile_artifacts.csv` | `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062` |

## Authorized second recovery and third stop

The second recovery removed only two reader-facing requirements from the
focused test: a literal link to the internal MDER decision path and visible
use of the internal identifier `METRIC-010`. It retained the scientific
assertions that current MDER uses no reference-profile weights, scales, or
gates, that historical paired-channel maps are not active Preparation 04
inputs, and that the superseded paired-observation claim is absent. It also
retained the decision-file existence check and exact SHA-256 comparison.

The revised test parsed successfully under R 4.6.1. The focused command was:

```text
/usr/local/bin/Rscript tests/test_preparation03_report.R _build/nathealth/notebooks/preparation/03_reference_profiles.html
```

The test passed the authorized reader-facing repairs and then exited with
status 1:

```text
Error: The controlling MDER decision identity changed.
Execution halted
```

The exact-hash assertion compared:

```text
Pinned in test: 44f93b12c8536574153eb0e0bcca85f4233eda71899353fa0ea350102cd8b83f
Current file:   1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de
```

The test did not weaken or bypass the check. The coordinator subsequently
accepted the current decision-file identity and separately authorized a
literal-only test update.

## Preservation gate

A read-only R 4.6.1 comparison passed all 39 Preparation 03 scoped
identities. The page source, profile configuration, rendered HTML, and current
reference-profile manifest retained the exact identities listed above.
`git diff --check` passed for the focused test. No secure loopback visual QA
was started because the test had not passed. Preparation 04 remained held.
