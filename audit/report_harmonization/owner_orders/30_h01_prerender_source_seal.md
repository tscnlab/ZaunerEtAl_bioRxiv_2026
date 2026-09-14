# REPORT-017 order 30: H01 pre-render source seal

Date: 2026-08-14  
Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`  
Coordinator decision: REPORT-017 / CHG-134  
Dispatch mode: manifest-row and test-only sealing, with no render

## Gate and accepted inputs

Preparations 01 through 07 are accepted. H01 is the first hypothesis target,
but its result-page render remains held. Independent R 4.6.1 preflight found
only three source-seal mismatches: two accepted QMD revisions are not yet
reflected in two H01 manifests, and one source-side test assertion expects a
visible sentence that the QMD constructs from adjacent R string literals.

Recheck these identities immediately before editing and stop on drift:

| Item | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H01.qmd` | `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9` | 90,547 |
| `audit/hypotheses/H01/H01_analysis_preparation.qmd` | `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8` | 54,405 |
| `artifacts/12_manifests/H01_reporting_artifacts.csv` | `4d39e9b1f76fed6fa56d8f9d210d5fd83b2d744e1e6dc67f60fcefe82b24b6b6` | current file size |
| `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` | `476fa10db3383b2de82bb1824e9e5d89b8629d1666d080fe79520c5b81800806` | current file size |
| `tests/hypotheses/H01/test_h01_reporting_inputs.R` | `ba4b08b5a20bdb862cac5209a2bb64c6bade3dab6b6f103253c6c7d02791ad59` | current file size |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` | current file size |

Both manifests currently have exactly two mismatches, and both are the two
accepted QMD revisions above. With only those rows reconciled in memory, every
other manifest row is exact. With the source assertion made string-boundary
tolerant in memory, the complete focused source and existing-HTML test passes.

## Authorized manifest-row changes

Edit only the `sha256` and `bytes` fields for the two exact QMD paths in each
of these files:

- `artifacts/12_manifests/H01_reporting_artifacts.csv`;
- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`.

For the result row, set:

- path: `notebooks/hypotheses/H01.qmd`;
- SHA-256: `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`;
- bytes: `90547`.

For the companion row, set:

- path: `audit/hypotheses/H01/H01_analysis_preparation.qmd`;
- SHA-256: `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`;
- bytes: `54405`.

Preserve every other row and every other field byte-for-byte, including row
order, role, producer, and R version. Do not regenerate either manifest or
refresh another recorded identity.

## Authorized test-only change

In `tests/hypotheses/H01/test_h01_reporting_inputs.R`, change only the
source-side assertion currently written as:

```r
grepl("All models include nine sites", qmd_text, fixed = TRUE),
```

Make this one assertion tolerant of whitespace and the adjacent R string
boundary while retaining the complete semantic phrase. A suitable bounded
replacement is:

```r
grepl(
  "All[[:space:]\"',]*models include nine sites",
  qmd_text,
  perl = TRUE
),
```

Preserve the later exact rendered-HTML assertion against
`publication_table_text` and every other source, HTML, manifest, figure,
table, site, link, value, and no-error gate.

## Prohibited actions

Do not edit either H01 QMD, either H01 HTML, `_quarto-nathealth.yml`, another
test, source data, scientific artifacts, model results, figures, tables,
handoffs, worker manifests, central ledgers, lockfiles, or manuscript files.
Do not fit, refit, predict, simulate, bootstrap, rebuild reporting inputs,
regenerate an asset, run Quarto, or render any page.

The H01 result render, H01 companion render, and every other hypothesis target
remain held. This order seals inputs only.

## Required verification and return

Use R 4.6.1 and return:

1. pre-edit and post-edit SHA-256 identities and byte counts for the two
   manifests and focused test;
2. exact four-row before/after evidence showing that only the two QMD rows in
   each manifest changed and that only `sha256` and `bytes` differ;
3. reverse-substitution proof reproducing both pre-edit manifest identities;
4. exact test diff and reverse-substitution proof reproducing
   `ba4b08b5a20bdb862cac5209a2bb64c6bade3dab6b6f103253c6c7d02791ad59`;
5. a comparison proving all non-QMD manifest rows and all other fields in the
   two QMD rows are unchanged;
6. R parse success for the edited test;
7. a full PASS from
   `Rscript tests/hypotheses/H01/test_h01_reporting_inputs.R` against the
   existing H01 HTML, without rendering;
8. exact preservation of both accepted QMDs, both existing H01 HTML pages,
   the profile, every non-QMD manifest member, and all scientific artifacts;
9. scoped ownership and `git diff --check` evidence showing only the three
   authorized files changed for this order.

Stop on any additional mismatch, test failure, scientific discrepancy, or
unintended worktree change. After the owner return, the harmonizer will
independently verify the seal and request a separate release for only
`notebooks/hypotheses/H01.qmd`.
