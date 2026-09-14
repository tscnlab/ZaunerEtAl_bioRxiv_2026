# REPORT-017 H01 order 30 pre-render seal: independent acceptance

Date: 2026-08-14

Outcome: **ACCEPTED.** The two H01 reporting manifests now pin the accepted
reader QMDs, and the focused test recognizes the source sentence across its
adjacent R string boundary while preserving the exact rendered-HTML check.
This record does not release or perform a render.

## Accepted identities

| Item | SHA-256 |
|---|---|
| Result QMD | `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9` |
| Companion QMD | `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8` |
| Reporting manifest | `54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676` |
| Stage 3 reporting manifest | `684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8` |
| Focused reporting test | `6e7b4de5a6580d95c81656f953e24a65743c6af5bf940eb1ce3ef628fc041f83` |
| Existing result HTML | `53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f` |
| Existing companion HTML | `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |

## Exact bounded changes

Each manifest changed only the `sha256` and `bytes` fields for the same two
QMD paths:

- the companion changed from `685641f...` / `54286` to `962b286...` /
  `54405`;
- the result changed from `8c7ca4e...` / `87441` to `5a3f1a0...` /
  `90547`.

Roles, producers, R versions, row order, and every non-QMD row remain
unchanged. In the focused test, only the source-side fixed-literal assertion
for “All models include nine sites” became whitespace and string-boundary
tolerant. The later exact assertion against the rendered publication table
remains unchanged.

In-memory reverse substitution reproduced all three dispatch identities
exactly:

- reporting manifest
  `4d39e9b1f76fed6fa56d8f9d210d5fd83b2d744e1e6dc67f60fcefe82b24b6b6`;
- Stage 3 manifest
  `476fa10db3383b2de82bb1824e9e5d89b8629d1666d080fe79520c5b81800806`;
- focused test
  `ba4b08b5a20bdb862cac5209a2bb64c6bade3dab6b6f103253c6c7d02791ad59`.

## Independent verification

R 4.6.1 verified all 49/49 rows in the reporting manifest and all 95/95 rows
in the Stage 3 manifest against current file hashes and byte counts. It also
parsed the edited test and confirmed the accepted QMD, existing HTML, and
profile identities above.

The complete normal-profile command

```text
Rscript tests/hypotheses/H01/test_h01_reporting_inputs.R
```

ran against the existing H01 HTML and exited 0 with
“H01 reporting input and HTML structure tests passed.” It did not invoke
Quarto, fit a model, rebuild reporting inputs, or modify a scientific output.
The owner additionally verified a 1,215-file pre/post protected inventory,
including 1,213 non-QMD files, with no byte change.

Scoped `git diff --check` passes. The result QMD, companion QMD, both existing
HTML pages, profile, source data, models, estimates, intervals, p-values,
diagnostics, sensitivities, figures, tables, and other scientific artifacts
remain unchanged.

## Disposition

The H01 pre-render source seal is accepted. A separate coordinator release is
still required before rendering only `notebooks/hypotheses/H01.qmd`. The H01
companion and every later hypothesis target remain held. DOC-001 remains open,
and all principal and supplemental output roles remain provisional pending
author visual review.
