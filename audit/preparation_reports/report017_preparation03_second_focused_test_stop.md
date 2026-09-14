# REPORT-017 Preparation 03 second focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `tests/test_preparation03_report.R`  
Outcome: **STOPPED at the pre-existing literal MDER-decision-link assertion after the separately authorized non-discrepancy assertion repair passed.**

This is distinct from the first focused-test stop recorded in
`report017_preparation03_failed_focused_test_verification.md`. No Quarto
render, QMD edit, configuration edit, scientific computation, artifact edit,
or loopback server occurred during this recovery attempt.

## Starting identities

| File | SHA-256 |
|---|---|
| `tests/test_preparation03_report.R` | `fe07283d1b6fc0dfaa66c72b2201a2ebb05dd36cdb7bcd7cd993d7a895beea03` |
| `notebooks/preparation/03_reference_profiles.qmd` | `a0d9bc85a906b6c83edd8019421b012220c11e2d72988724fd9d1439fbc57a3a` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `_build/nathealth/notebooks/preparation/03_reference_profiles.html` | `262705d82ad3add77028492502f94b45d526424c25c1f5f3c8b4ac33b75b4c2c` |
| `artifacts/12_manifests/reference_profile_artifacts.csv` | `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062` |

The prior test-only change replaced the stale literal
`This provenance gap is not evidence` with a semantic two-part requirement
for the accepted wording. It requires both the current `not evidence`
language and the qualification concerning a current profile, metric, or
downstream result. Reverse substitution reproduced the authorized pre-edit
test SHA-256
`28f8f68e87d391faa6c45269dfc267165fa0cd3299e95603c11f220fba120841`
exactly.

## Checks and second stop

The edited test parsed successfully under R 4.6.1. The focused command was:

```text
/usr/local/bin/Rscript tests/test_preparation03_report.R _build/nathealth/notebooks/preparation/03_reference_profiles.html
```

The test passed the repaired non-discrepancy assertion and then exited with
status 1 at the next assertion:

```text
Error: The controlling MDER decision is not linked.
Execution halted
```

The failing assertion required the reader QMD to contain the literal path
`audit/decisions/mder_mean_of_viable_ratios.md`. The accepted reader QMD does
not contain that path. This did not imply a scientific MDER discrepancy. The
same test separately retained scientific checks that:

- current MDER uses no reference-profile weights, scales, or gates;
- the historical paired-channel maps are not active Preparation 04 inputs;
- the superseded paired-observation claim is absent; and
- the controlling MDER decision file exists and has its exact approved
  SHA-256.

The test also separately required visible `METRIC-010`, although that internal
decision identifier is not necessary to establish the reader-facing
scientific statements above.

## Preservation gate

A read-only R 4.6.1 comparison passed all 39 scoped Preparation 03 identities.
The source, configuration, rendered HTML, and current reference-profile
manifest retained the exact hashes listed above. `git diff --check` passed for
the focused test. No secure loopback visual QA was started because the release
condition required the focused test to pass first.

Coordinator authorization is required before changing either the literal
reader-link requirement or the visible internal-identifier requirement.
Preparation 04 remains held.
