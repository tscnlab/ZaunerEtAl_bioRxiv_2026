# REPORT-017 H06_daily corpus-contract repair: independent acceptance

Date: 2026-08-14

Status: **accepted**

## Scope

This record accepts the coordinator-authorized harmonizer-owned structural
repair needed after the H01 order 31 target render. The repair changed only:

1. `scripts/report_harmonization/build_phase4_corpus_manifest.R`;
2. `tests/report_harmonization/test_navigation_contract.R`; and
3. the generated
   `audit/report_harmonization/phase4_corpus_manifest.csv`.

No QMD, Nature Health profile, scientific artifact, rendered HTML, central
ledger, manuscript file, model, estimate, interval, p-value, diagnostic,
sensitivity, or source-data file changed. Quarto, knitr, and the in-app Browser
were not run.

## Exact repair

The corpus builder now inserts the H06 complementary daily result and its
preparation/provenance companion immediately after the main H06 result and
companion. Exactly those two paths were removed from the forbidden-source
list. The navigation test's sole corpus-size assertion changed from 35 to 37.
No other test assertion changed.

The generated manifest has 37 unique reader sources. The relevant sequence is:

| Logical order | Render position | Sidebar position | Source |
|---:|---:|---:|---|
| 23 | 21 | 23 | `notebooks/hypotheses/H06.qmd` |
| 24 | 22 | 24 | `audit/hypotheses/H06/H06_analysis_preparation.qmd` |
| 25 | 23 | 25 | `notebooks/hypotheses/H06_daily.qmd` |
| 26 | 24 | 26 | `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd` |
| 27 | 25 | 27 | `notebooks/hypotheses/H07.qmd` |

The 35 previously catalogued sources retain their relative source order and
their invariant role, title, expected-HTML path, and HTML-existence metadata.
The rebuild refreshes the manifest's current source, render-position, sidebar,
and HTML identities as intended.

## Identities

| File | Before | After |
|---|---|---|
| Corpus builder | `aae5a8a4b2663cf44f23ebe181c7cd6c00877eec4de841776ba2bf35787d110d` | `c01f0dc86e25bcf4a37685515cd692e2007774a004a4e902eac5936521749e2e` |
| Navigation test | `c7cf87bd012a97bd4dae0f7e0da3255dc8063726c11a0ef885d70f2a5e8529bb` | `1ba59346328e8e4fb2aa898c5806313763711867514097969f5e4df1c22d3407` |
| Corpus manifest | `72acb2d3df86be233dd8bc143366ab6319d363122b1facd53d41ae76ae9aada1` | `52baecfc4d40288cf26cbe259115abddb72f749eae7e538eebafae97ced6aafb` |

Exact in-memory reverse substitutions reproduce both accepted pre-edit script
hashes. The generated manifest verifies the current SHA-256 identity of every
one of its 37 sources and every one of its 36 existing HTML targets.

## R 4.6.1 verification

All checks ran with R 4.6.1 using static or file-identity operations only.

- Both edited R files parse.
- The builder writes 37 unique rows and reports 36 existing HTML files.
- The navigation contract passes for all 37 sources.
- The reader-link contract passes for all 37 QMD sources and all 86 deviation
  IDs and anchors.
- The country-coded site-name contract passes for all 37 reader-facing QMDs.
- All 37 source hashes and all 36 existing HTML hashes in the rebuilt manifest
  match their current files.
- The H06, H06_daily, and H07 source order matches the profile in both render
  and sidebar positions.
- Scoped diff and whitespace checks pass.

## Preserved H01 order 31 evidence

The already fresh H01 result remains available for the separately authorized
semantic and secure-loopback QA without rerendering:

- result QMD:
  `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`;
- companion QMD:
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`;
- Nature Health profile:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- fresh H01 result HTML:
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`.

The H01 companion and every later hypothesis target remain held.
