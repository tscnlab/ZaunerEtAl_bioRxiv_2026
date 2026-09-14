# REPORT-017 H01 order 31c manifest reseal independent acceptance

Date: 2026-08-14

Status: **ACCEPTED. Both H01 reporting manifests are fully sealed to the
accepted order 31b source, and the complete H01 reporting test passes. No
render, profile hook, or durable HTML change is authorized by this record.**

## Controlling order and exact changes

The controlling order is
`audit/report_harmonization/owner_orders/31c_h01_reporting_manifest_qmd_pin_reseal.md`,
SHA-256
`5d4e85c29c41c8e01f43b6f2f3401addf58eba448765d4fbf50e8eb522276907`.

Only these manifest fields changed:

- `artifacts/12_manifests/H01_reporting_artifacts.csv`, data row 46,
  `notebooks/hypotheses/H01.qmd`: SHA-256 changed from
  `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`
  to
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`,
  and bytes changed from 90,547 to 90,640;
- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`, data row 92,
  the same QMD path: the same SHA-256 and byte replacements.

Every other field and row is byte-identical. Reverse-substituting only these
four fields reproduces both preceding manifest identities exactly:

- reporting manifest:
  `54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676`,
  11,054 bytes; and
- Stage 3 reporting manifest:
  `684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8`,
  22,735 bytes.

## Accepted manifest identities

- `artifacts/12_manifests/H01_reporting_artifacts.csv`, SHA-256
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`,
  11,054 bytes, with all 49/49 file hashes and byte counts exact;
- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`, SHA-256
  `08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`,
  22,735 bytes, with all 95/95 file hashes and byte counts exact.

## Independent R 4.6.1 verification

The complete command

```text
Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R
```

passes with `H01 reporting input and HTML structure tests passed`. The test
parses to 69 top-level expressions. The sealed pre-render HTML still contains
exactly eight `Primary 17-test BH family` cells and zero
`Primary 17-test FDR family` cells. The accepted QMD contains exactly one
future display mapping to `Primary 17-test FDR family`.

The verified runtime is R 4.6.1 with dplyr 1.2.1, knitr 1.51, readr 2.2.0,
rvest 1.0.5, and openssl 2.4.2.

## Protected identities

The following remain exact:

- H01 result QMD:
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`,
  90,640 bytes;
- H01 focused owner test:
  `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`,
  21,025 bytes;
- H01 companion QMD:
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`,
  54,405 bytes;
- sealed durable H01 HTML:
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`,
  1,371,249 bytes;
- stored L10 support CSV:
  `5814d5518ab23b3578dac54b19c6c6deea46e8d76aff2f3a6e30bce28752a26a`,
  3,003 bytes; and
- Nature Health profile:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`,
  7,404 bytes.

Scoped parse, all-row identity, reverse-substitution, whitespace, and diff
checks pass. No QMD, test, durable HTML, profile, scientific artifact,
package, lockfile, ledger, manuscript, commit, or push changed in order 31c.

## Next gate

The final Stage A dependency refresh is separately sealed. A profile hook,
durable semantic repair, fresh H01 render, H01 companion work, and all later
REPORT-017 targets remain held pending a new coordinator authorization.
