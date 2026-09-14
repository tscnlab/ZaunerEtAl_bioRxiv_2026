# REPORT-017 order 31c: H01 reporting-manifest QMD-pin reseal

Date: 2026-08-14

Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released for one manifest-only source-seal repair. No QMD, test,
render, durable HTML, scientific artifact, profile, package, lockfile, ledger,
manuscript, commit, or push change is authorized.**

## Accepted input identities

Recheck these identities immediately before editing and stop on any drift:

- H01 result QMD:
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`,
  90,640 bytes;
- H01 focused test:
  `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`,
  21,025 bytes;
- H01 companion QMD:
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`,
  54,405 bytes;
- Nature Health profile:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`,
  7,404 bytes;
- sealed pre-render H01 HTML:
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`,
  1,371,249 bytes;
- stored L10 support CSV:
  `5814d5518ab23b3578dac54b19c6c6deea46e8d76aff2f3a6e30bce28752a26a`,
  3,003 bytes;
- `artifacts/12_manifests/H01_reporting_artifacts.csv`:
  `54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676`,
  11,054 bytes and 49 data rows; and
- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`:
  `684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8`,
  22,735 bytes and 95 data rows.

The independent Stage B acceptance is
`audit/report_harmonization/report017_h01_order31b_source_test_independent_acceptance.md`,
SHA-256
`a0c81ff5f916d6a66c6a350b65a1f4a1eae020844799a37f5692409f77e475c2`.

## Exact permitted edits

Edit only these two CSV rows:

1. `artifacts/12_manifests/H01_reporting_artifacts.csv`, data row 46,
   path `notebooks/hypotheses/H01.qmd`;
2. `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`, data row 92,
   path `notebooks/hypotheses/H01.qmd`.

In each row replace only:

- SHA-256
  `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`
  with
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`;
  and
- byte count `90547` with `90640`.

Preserve every other row, field, path, role, producer, R version, order, line
ending, and byte exactly. Do not rebuild either manifest from a broader input
set.

## Required R 4.6.1 verification

After the two-row repair:

1. verify all 49/49 reporting-manifest rows and all 95/95 Stage 3
   reporting-manifest rows against their current files, including exact hashes
   and byte counts;
2. run the complete focused test:

   ```text
   Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R
   ```

3. verify that its sealed-pre-render HTML branch still requires exactly eight
   `Primary 17-test BH family` cells and zero `Primary 17-test FDR family`
   cells in the unchanged durable HTML;
4. verify that the QMD source still requires the future display mapping from
   the stored BH label to `Primary 17-test FDR family`;
5. prove that reverse-substituting only the two new hash/byte pairs reproduces
   both pre-edit manifest hashes and byte counts exactly;
6. prove that every non-QMD manifest row is unchanged and that the H01 result
   QMD, focused test, companion, durable HTML, stored L10 CSV, profile, and all
   scientific artifacts retain their accepted identities; and
7. run R parse and scoped whitespace/diff checks.

## Return evidence

Return:

- both post-edit manifest SHA-256 identities and byte counts;
- an exact two-row, four-field change map and reverse proof;
- 49/49 and 95/95 all-row identity results;
- the complete focused-test result and R/package versions;
- the preserved source/test/HTML/companion/CSV/profile identities; and
- scoped status and diff evidence showing exactly the two authorized manifest
  files.

Stop and report any additional mismatch. Do not render H01. The profile hook,
durable semantic repair, H01 companion, and every later REPORT-017 target
remain held.
