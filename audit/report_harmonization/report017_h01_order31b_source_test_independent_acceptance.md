# REPORT-017 H01 order 31b source/test independent acceptance

Date: 2026-08-14

Status: **ACCEPTED for the bounded source/test display-label change. The two
H01 reporting-manifest QMD pins remain pending a separately dispatched
manifest-only owner order. No render or durable HTML change is authorized.**

## Scope and identities

The controlling owner order is
`audit/report_harmonization/owner_orders/31b_h01_fdr_display_label_source_only.md`,
SHA-256
`6b7b10ef378ccfc593bbeaeb6462db38731420ef5e816043279248671a5392a0`.

Accepted Stage B files are:

- `notebooks/hypotheses/H01.qmd`, SHA-256
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`,
  90,640 bytes; and
- `tests/hypotheses/H01/test_h01_reporting_inputs.R`, SHA-256
  `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`,
  21,025 bytes.

## Exact bounded change

The H01 result source changes only the displayed `Multiplicity` mapping in
`tbl-h01-l10-noon-support`. The stored value `Primary 17-test BH family` is
mapped at display time to `Primary 17-test FDR family`. The eight stored CSV
cells, their row order, tests, estimates, intervals, p-values, decisions, and
the full multiplicity method remain unchanged.

Replacing the four-line display recode with the preceding assignment
`Multiplicity = .data$multiplicity` reproduces the pre-order source exactly:

- SHA-256
  `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`;
- 90,547 bytes.

The owner test adds one source/display transition gate. It requires the new
source mapping exactly once. It also distinguishes the sealed pre-render HTML
from a future refreshed HTML: the current durable HTML must retain eight old
BH display labels and zero FDR labels, while a future refreshed HTML must have
eight FDR labels and zero BH labels. Removing only that 52-line gate reproduces
the preceding test exactly:

- SHA-256
  `6e7b4de5a6580d95c81656f953e24a65743c6af5bf940eb1ce3ef628fc041f83`;
- 19,445 bytes.

## Independent R 4.6.1 checks

The source-only command

```text
H01_SOURCE_ONLY_DISPLAY_TEST=true Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R
```

passes. The static source seal retains 37 chunk labels, 124 parsed R
expressions, 36 table endpoints, 10 figure endpoints, five formula blocks, and
42 artifact references. No code chunk or model was executed by this
acceptance.

The complete focused test presently stops at its manifest identity check, as
expected. An independent R 4.6.1 audit of both manifests finds exactly two
mismatches among 144 rows:

- reporting manifest row 46; and
- Stage 3 reporting manifest row 92.

Both rows are the H01 result QMD and both still pin the preceding source at
SHA-256
`5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`
and 90,547 bytes. All other 142 rows match their current files exactly.

## Preservation

The following remain exact:

- durable H01 HTML, SHA-256
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`;
- H01 companion QMD, SHA-256
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`;
- Nature Health profile, SHA-256
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- stored L10 support CSV, SHA-256
  `5814d5518ab23b3578dac54b19c6c6deea46e8d76aff2f3a6e30bce28752a26a`;
- pre-reseal reporting manifest, SHA-256
  `54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676`;
  and
- pre-reseal Stage 3 reporting manifest, SHA-256
  `684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8`.

Scoped whitespace and diff checks pass. No scientific artifact, QMD other
than the owned H01 result source, profile, durable HTML, package, lockfile,
ledger, or manuscript file changed in order 31b.

## Next gate

The next authorized action is a manifest-only owner order that changes only
the QMD SHA-256 and byte fields in reporting-manifest row 46 and Stage 3
reporting-manifest row 92. The profile hook, durable semantic repair, H01
result rerender, H01 companion, and all later REPORT-017 targets remain held.
