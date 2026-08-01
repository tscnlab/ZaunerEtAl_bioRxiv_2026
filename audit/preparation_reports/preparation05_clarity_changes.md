# Preparation 05 clarity and display record

Date: 2026-08-01

Source: `notebooks/preparation/05_model_input_acquisition.qmd`

Rendered HTML:
`_build/nathealth/notebooks/preparation/05_model_input_acquisition.html`

## Meaning preserved

- The expected input remains the complete 9-site × 7-modality grid: 63
  questionnaire and diary files.
- Every site-wide release remains fixed by repository, complete commit
  identifier, and DOI. The TUM exercise diary alone retains its scoped
  corrected upstream release, fixed SHA-256, and byte size.
- The nine sleep diaries remain exact reuses of the Preparation 01 files.
- Acquisition still stores separate source objects without cleaning,
  combining, scoring, recoding, normalizing, or filtering scientific values.
- Object and column audits still record the declared single object, class,
  dimensions, ordered names, classes, and storage types.
- No source object, participant response, questionnaire score, factor level,
  diary row, timestamp, model input, model sample, or downstream result
  changed.

## Reader-facing changes

- Replaced disabled builder/verifier code and raw `kable` output with direct
  reads of the current acquisition manifest, four fixed registries, and the
  stored object and column audits.
- Added the purpose, exact inputs, position between Preparations 01 and 06,
  an explicit no-network/no-raw-object render boundary, and an accessible
  process diagram.
- Explained fixed releases, commit-specific addresses, cache reuse, exact
  Preparation 01 sleep-diary reuse, and the TUM modality-specific correction
  in plain scientific language.
- Added nine semantic `gt` tables covering exact registries, site releases,
  the TUM pin, modality content, acquisition outcomes, production scripts,
  stored hand-off artifacts, bounded current checks, and stored independent
  verification.
- Applied the submitted-manuscript site names, order, and colours.
- Used 38%/62% layouts for provenance-heavy two-column tables and widened the
  modality table's final numeric column to prevent an undesirable narrow
  header cell.
- Reported 63/63 present files, 53 verified model-input-cache reuses, nine
  Preparation 01 sleep-diary reuses, one fixed-release download, 63 declared
  objects, and 963 recorded source columns.

## Verification

- Static and rendered-HTML bounded-render test: **PASS**.
- Final-profile page-specific read-set baseline: 128 entries; SHA-256
  `c9aee2be47e89ccaf36759ce448c3b003421a185ceb19c5c86a4c06704c909ad`.
- Final post-render comparison: 128 unchanged, 0 mismatches.
- Current acquisition-manifest SHA-256:
  `ac79a83c2d60dde1ac563f6e2cb09c58d4d7d3b06549d9b9262e4acd5a50a58b`.
- Fixed source-pin registry SHA-256:
  `3fbf9f40125c60e1d0779d2b2d524e79534597586c60ec236a1ce16299e18831`.
- Rendered HTML SHA-256:
  `1e3cddd7e66168159e5fb97564aa3fa274fb760571265bd0c6eb84597b72291d`.
- Rendered HTML contains nine semantic `gt` tables, nine resolved table
  captions, the complete submitted site display, and no unresolved table
  cross-reference or raw tibble output.
- Render context: R 4.6.1, `gt` 1.3.0, and Quarto 1.9.37 using the
  `nathealth` profile.

## REPORT-011 and layout QA

- Preparation 05 contains no reader-facing figure; no figure typography or
  source-data artifact was required.
- Narrative-heavy tables use broad two-column layouts. Numeric table columns
  are compact but wide enough for their headers and values.
- Long commits, hashes, paths, repository names, and DOI links receive wrap
  opportunities; no high-content prose is placed in a narrow residual
  column.
