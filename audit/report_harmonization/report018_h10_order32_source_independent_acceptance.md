# REPORT-018 H10 order 32 source independent acceptance

Date: 2026-08-22

Disposition: `ACCEPTED_SOURCE_ONLY_AND_RESULT_PREFLIGHT_COMPLETE`

## Accepted source-only transition

The H10 biological-sex and gender construct correction is independently
accepted. Exactly the two authorized result-source passages, two authorized
companion-source passages, and their dependent source assertions changed.
No H10 model, input, sample, estimand, formula, estimate, interval, p-value,
FDR decision, diagnostic, table, figure, paired source data, manifest, HTML,
profile, package, lockfile, H11 path, or later target changed.

Accepted postimages are:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H10.qmd` | `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d` | 49,224 |
| `audit/hypotheses/H10/H10_analysis_preparation.qmd` | `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6` | 58,446 |
| `tests/hypotheses/H10/test_h10_stage3_reader_report.R` | `803f4139c6c99b56e49ed160b1ae644244a7ac8acbfa80328e7945eb326242f1` | 23,710 |
| `tests/hypotheses/H10/test_h10_preparation_report.R` | `15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4` | 15,201 |

R 4.6.1 exact reverse substitution reconstructed all four dispatch preimages:

| Path | Reconstructed SHA-256 | Bytes |
|---|---|---:|
| result QMD | `3c8d6891854a298e4fad69d1d7499c4d45a7d7c522f50e920b6b6aa1e4abac3f` | 49,191 |
| companion QMD | `c46d6ae965daba94750220e6eeaf95aa01b5cff4bc929117848f72090b7583f1` | 58,413 |
| result test | `9f683babf2fd036bf33acf71ce5ef694d4a78a2893b5c6d4b54df9b9c01a1c3c` | 23,426 |
| companion test | `836a6b48250946375c512895d05a50c77e6472ccccf987510675a33235cdcb22` | 14,764 |

The corrected source states that biological sex and gender were recorded as
separate variables, the accepted analyses used biological sex coded Female or
Male, gender was not analysed, and the gender variable did not enter a model.
The protected limitation remains exact: the analysis provides no inference
about gender identity. The false phrases `neither measured nor inferred` and
`No gender field` are absent.

## Independent R 4.6.1 replay

The durable checker
`scripts/report_harmonization/check_report018_h10_order32_source_acceptance_and_result_preflight.R`
passed 31 checks. It verified:

- exact current and reconstructed identities for all four edited files;
- 24 result and 23 companion R chunks parse without execution;
- both current tests parse;
- QMD chunk labels, 15 result-table endpoints, eight result-figure endpoints,
  19 companion-table endpoints, two companion-figure endpoints, artifact
  references, numeric tokens, and executable R outside the authorized caption
  remain invariant;
- 21/21 immutable dispatch paths remain exact;
- eight historical planning rows remain live-exact and the other four are
  exactly the authorized source/test transitions;
- 57/57 H10 scientific display assets remain exact, comprising 13 table
  files, 29 figure files, and 15 paired source-data files; and
- the demographics, model frames, model manifest, Stage 1 source, held result
  and companion HTMLs, and normal profile retain their sealed identities.

No QMD execution, Quarto, model, prediction, simulation, resampling, builder,
artifact regeneration, manifest update, browser server, commit, push, or
upload occurred during source acceptance.

## Consolidated result-render preflight

The current immutable Stage 3 manifest has exactly five accepted historical
transitions and no others:

1. companion QMD;
2. companion preparation test;
3. result reader test;
4. result QMD; and
5. normal profile.

The result reader test also contains older REPORT-017 terminology and an
all-live historical-manifest assertion. A complete temporary R 4.6.1 replay
tested the entire downstream reader test after one consolidated exact
classification patch. It passed through all scientific, numerical, figure,
link, source-data, PDF, typography, and manifest assertions. The exact
prospective test is retained as evidence at:

- `audit/report_harmonization/report018_h10_order32_source_acceptance/prospective_test_h10_stage3_reader_report.R`
- SHA-256 `ad792acdb7c9d2fe9290a6837a2a3c994811d7f5c9a64eaea01b0edd9f9b4db1`
- 25,796 bytes.

The patch replaces only five stale test classifications: accepted FDR
terminology, the current near-eye measurement-context sentence, the current
core-residual heading, the current remaining-gap definition, and the exact
historical-to-live manifest transition set. It adds rendered-page assertions
for the accepted biological-sex and gender boundary. It preserves every
scientific assertion and fails on a seventh manifest mismatch. The result test
self-transition is pinned externally by the render order and completion seal;
the test itself does not contain a recursive self-hash.

The fresh render must add exactly one sixth historical transition, the result
HTML. It must produce exactly 15 native `gt` tables and eight figure endpoints,
apply a reversible semantic repair, preserve all source data and scientific
artifacts, and pass secure loopback visual QA. The H10 companion, H11, and all
later targets remain held.
