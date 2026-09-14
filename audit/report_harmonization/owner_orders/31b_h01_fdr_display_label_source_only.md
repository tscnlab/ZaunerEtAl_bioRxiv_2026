# REPORT-017 order 31b: H01 compact FDR display label

Date: 2026-08-14

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: released for one source-only reader-display repair. No render is
authorized.

## Accepted pre-edit pins

- `notebooks/hypotheses/H01.qmd`:
  `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`
- `tests/hypotheses/H01/test_h01_reporting_inputs.R`:
  `6e7b4de5a6580d95c81656f953e24a65743c6af5bf940eb1ce3ef628fc041f83`
- retained result HTML:
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`
- stored L10 noon-sensitivity CSV:
  `5814d5518ab23b3578dac54b19c6c6deea46e8d76aff2f3a6e30bce28752a26a`
- reporting manifest:
  `54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676`
- Stage 3 reporting manifest:
  `684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8`
- Nature Health profile:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`

Stop before editing if any pin differs.

## Exact source repair

Edit only `notebooks/hypotheses/H01.qmd` and one focused H01 test under
`tests/hypotheses/H01/`.

In the `tbl-h01-l10-noon-support` pipeline, change only the displayed
`Multiplicity` mapping so each stored value
`Primary 17-test BH family` is presented as
`Primary 17-test FDR family`. Use an explicit display-only mapping such as
`recode()` within the table pipeline. Do not alter `l10_noon`, its stored CSV,
or the underlying multiplicity method.

The accepted compact reader term is `FDR`. Preserve the full method name or
the analytical `BH` method token in technical code and provenance where it is
needed for reproducibility. Do not replace code-level method identifiers.

## Focused test contract

Add or update a focused H01 reader-display assertion that:

1. requires the exact source mapping from the stored BH-labelled value to the
   displayed FDR-labelled value;
2. scopes rendered checking to `tbl-h01-l10-noon-support`;
3. after a future fresh render, requires exactly eight visible
   `Primary 17-test FDR family` cells and zero visible
   `Primary 17-test BH family` cells in that table; and
4. permits the current retained HTML only while its hash is exactly the sealed
   pre-render identity above, documenting that it contains the eight stale
   labels pending the separately authorized rerender.

Do not weaken any analytical, manifest, formula, table-count, figure-count,
sample, p-value, or stored-artifact assertion. Do not edit a reporting
manifest under this order. If the complete pre-existing focused test stops
only because the accepted QMD source identity is not yet repinned in those
manifests, seal that exact stop and request a separate bounded manifest
disposition.

## Preservation boundary

Do not render Quarto or execute a report chunk. Do not fit or refit a model,
recalculate an adjustment, estimate, interval, p-value, diagnostic, or
sensitivity, regenerate an artifact, or alter any data. Do not edit the H01
companion, profile, HTML, source CSV, manifests, central ledgers, lockfile,
manuscript, or another hypothesis.

Under R 4.6.1, require:

- static parsing of every H01 result R chunk without execution;
- exact chunk-label, table/figure endpoint, formula, artifact-reference, and
  accepted numeric-token preservation;
- exact pre/post hashes for the source and focused test;
- reverse-substitution evidence reproducing both pre-edit identities;
- exact preservation of the stored CSV, both reporting manifests, accepted
  HTML, companion QMD/HTML, profile, and protected scientific artifacts;
- the new source-only display test passing; and
- scoped `git diff --check` passing.

Return the exact changed lines, test command and result, all post-edit
identities, and any manifest-only stop. Do not render, commit, or push.
