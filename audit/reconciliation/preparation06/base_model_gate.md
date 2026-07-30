# Preparation 06 base-model-data gate

Status: **PASS**  
Verified: 2026-07-30  
Authoritative runtime: R 4.6.1

## Scope

This gate verifies the deterministic, hypothesis-neutral model-data layer. It
preserves every main-analysis metric row and analytical outcome value on its
original key, removes four internal M10/L10 boundary diagnostics from the
model-ready schema, attaches participant-level questionnaire fields and
site-date context with asserted join cardinality, and applies no complete-case
or hypothesis-specific selection.

## Verified inputs

- Metric-artifact manifest SHA-256:
  `944f395e00735e6f8200798d4cde387454441d39b9defda68f583bd8778cd34b`
- Site/solar-context manifest SHA-256:
  `727f48016f430d1d48f1fe091c47bc7721011d72786fc691f3ca0d25a0a8386b`
- Normalized-model-input manifest SHA-256:
  `e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab`
- Combined verified-input-bundle SHA-256:
  `b6262d925937f505514834ea9d5b733a6be76c00b1a8ec6855a9a10947bfb900`

The TUM exercise diary is read from the modality-specific immutable pin at
commit `618fda8521f3cf581661ceb2c026e3de7cd9ba82`. The corrected source contains
seven exercise records for `TUM_S001`, none for `TUM_S101`, and no duplicate
participant-date key.

## Verified outputs

The manifest contains 21 deterministic artifacts and has SHA-256
`fd48dc5d1ecd5da125dd2c360c32239f0adfe7009eca881f5838b0e61b81b13d`.

| Domain | Placement | Rows | Participants |
|---|---:|---:|---:|
| Participant-day metrics | Near-eye | 811 | 141 |
| Participant-day metrics | Chest | 897 | 154 |
| Participant metrics | Near-eye | 141 | 141 |
| Participant metrics | Chest | 154 | 154 |
| 30-minute outcomes | Near-eye | 38,928 | 141 |
| 30-minute outcomes | Chest | 43,056 | 154 |
| One-hour outcomes | Near-eye | 19,464 | 141 |
| One-hour outcomes | Chest | 21,528 | 154 |

The participant metadata union contains 191 unique participants and 51
audited questionnaire fields. Eight participant records have no canonical
light-metric row, but no participant lacks the normalized questionnaire
modalities needed to define that union. All metric-key and context joins have
their expected cardinality, retain input row order and count, and contain no
unmatched required context.

The metric-registry firewall contains eight input records. It removes
`m10_onset_clock_minute`, `m10_offset_clock_minute`,
`l10_onset_clock_minute`, and `l10_offset_clock_minute` from each of the two
participant-day inputs and verifies their absence from every model-ready
artifact. No row, key, midpoint, window level, or other outcome value is
recalculated. The four boundary fields remain available only in the verified
Preparation 04 diagnostic artifacts used to check window duration, wrapping,
and ties.

## Independent verification

- The builder and verifier pass under R 4.6.1.
- Unit, tamper-rejection, deterministic-byte, and alternate-working-directory
  tests pass.
- A root-independence defect in manifest byte-size collection was reproduced:
  sequential tibble evaluation shadowed the input path and returned missing
  sizes outside the project working directory. The builder now captures input
  sizes before constructing the manifest. The alternate-directory regression
  test verifies the repair.
- `TUM_S101` is absent from participant availability; `TUM_S001` has the
  corrected source-derived exercise availability.
- The registry firewall is independently reconstructed from the original
  metric artifacts; the verifier rejects any endpoint field in a model-ready
  output.
- Four numerical roundoff values in darkest 10-hour mean melEDI were
  regenerated as exact zero rather than approximately
  \(-5.55 \times 10^{-17}\) lx. No row, key or other metric changed, and the
  verifier rejects a materially negative exposure level.
- Rebuilding after removal of runtime timestamps and absolute paths from the
  site/solar-context manifest changed only `input_provenance.csv`. All 20
  other base-model artifacts, including every model-facing RDS, remained
  byte-identical.

## Interpretation

This gate establishes a verified common base, not a fitted-model sample.
Outcome-specific admissibility, missing-predictor handling, interaction
support, multiplicity families, and model exclusions remain explicit
hypothesis gates. The requested pre-analysis comparison is therefore run
against these artifacts before H01 is fitted.

## Reopening conditions

Reopen this gate if an upstream manifest, source pin, normalization rule,
metric artifact, site-context producer, participant identity, join
cardinality, metadata field, or base-data schema changes.
