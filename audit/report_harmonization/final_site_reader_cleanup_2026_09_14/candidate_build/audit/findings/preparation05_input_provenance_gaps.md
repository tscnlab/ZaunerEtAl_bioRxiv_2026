# Preparation 05 input-provenance gaps

Finding ID: `FIND-020`  
Status: repair verified  
Date: 2026-07-30  
Severity: high for reproducibility; no model has yet consumed an unpinned input

## Finding

The canonical acquisition manifest currently pins 35 files from nine
site-specific repositories:

- nine near-eye light files;
- eight chest light files;
- nine sleep-diary files; and
- nine wear-log files.

All 35 cached paths exist and carry repository, full commit, DOI, URL,
SHA-256, byte-size, and acquisition metadata. This is sufficient for
Preparations 01--04, but not for the H01--H11 model-data layer.

The current analysis code obtains several additional domains through
`melidosData::load_data()`. In installed `melidosData` 1.0.6, that function
constructs URLs using `/main/data/imported/`. It therefore retrieves moving
repository state rather than the nine commits already fixed in
`config/site_sources.csv`.

The following required domains have no canonical pinned cache, one-object
artifact, source hash, schema contract, or join report:

| Domain | Main consumers | Required key or resolution |
|---|---|---|
| Demographics | H10, H11, descriptives | one row per site-participant |
| Chronotype, including MCTQ and MEQ | H09, descriptives | one row per site-participant plus scoring provenance |
| LEBA factors/items | H05 | one row per site-participant plus factor construction |
| VLSQ-8 items/score | H08 | one row per site-participant plus scoring provenance |
| Exercise diary | H06 | normalized participant-day or interval keys |
| Hourly light-exposure/activity diary | H03, H04, placement context, H11 sensitivity | site-participant-time with category/cardinality audit |
| Site coordinates and daily solar variables | H01, H02, H07, H11, descriptives | one site row plus deterministic site-date solar fields |

Historical `.RData` objects contain some derived demographics and
photoperiod fields. They are reconciliation evidence from a filtered cohort,
not authoritative source artifacts, and must not replace independent pinned
inputs.

## Verified canonical inputs already available

R 4.6.1 inspection found:

| Placement | Participant-day metrics | Participant metrics | 30-minute rows | One-hour rows |
|---|---:|---:|---:|---:|
| Near eye | 811 | 141 | 38,928 | 19,464 |
| Chest | 897 | 154 | 43,056 | 21,528 |

The coverage artifacts additionally retain the true-UTC, wall-clock, state,
context, channel, source, and support fields required to normalize new
inputs. `artifacts/06_model_data/` currently contains no files, so no
canonical hypothesis result has yet been contaminated by a moving input.

The pinned sleep-diary releases contain the day-type and sleep fields needed
for H06. They should be normalized from their pinned source files rather than
recovered from the reduced state-interval artifacts. One missing wake record
at MPI must remain visible and reason coded.

## Required repair

Before Preparation 05 joins or models:

1. specify every required modality at the existing site-specific commit;
2. download once, hash, and manifest the exact file or record a
   reason-coded site/modality absence;
3. load each expected object into an isolated environment and fail on
   unexpected object names or schemas;
4. normalize each domain to explicit RDS/CSV artifacts with dictionaries,
   keys, duplicates, missingness, and source provenance;
5. produce one audited site metadata artifact and deterministic solar/
   photoperiod fields; and
6. prohibit `melidosData::load_data()` in executable hypothesis notebooks.

Preparation 05 should first build H02/H07 and other no-questionnaire
scaffolds, then participant-level sources, daily diaries, and hourly context.
H06 must preserve both its registered daily-metric candidate and the current
hourly-outcome candidate until its estimand gate is decided.

## Repair verification

The seven required questionnaire and diary modalities are now acquired from
immutable commits and normalized into one-object RDS artifacts. The
acquisition manifest contains 63 site-modality records: 54 immutable
commit-pinned non-sleep sources and nine exact Preparation 01 sleep-diary
reuses. In the current regeneration, one corrected TUM exercise source was
downloaded and 53 unchanged model-input files were hash-verified cache reuses.
The normalization manifest contains seven analytical RDS files and eight
audit CSVs.

The TUM exercise source uses a modality-specific pin rather than changing the
site-wide commit: commit
`618fda8521f3cf581661ceb2c026e3de7cd9ba82`, source SHA-256
`0db56324e9826d427c42984fdfc43eb1e7487211365f222a1c0b2ecff618f1ef`,
and source-pin-manifest SHA-256
`3fbf9f40125c60e1d0779d2b2d524e79534597586c60ec236a1ce16299e18831`.
This preserves the existing Preparation 01 and light-source pins. The
upstream object corrects four participant IDs without a normalization-time
rewrite. Its only other predecessor difference is three newly missing
`type_english` entries; that field and `type` are excluded free text and
remain absent from analytical RDS and audit content.

Under R 4.6.1, the independent verifier reconstructed all 963 source columns
and confirmed exact values, missingness, scores, factor levels, units, labels,
release provenance, source-row traces, and true-UTC/local-wall coordinates.
It also confirmed that free-text content is absent from analytical outputs,
the 27 incomplete light-diary intervals remain retained and quarantined, and
the one incomplete MPI sleep interval remains retained and quarantined.

Canonical site/solar context is separately verified for 616 site-dates with
zero unmatched metric joins. No hypothesis-specific join, model sample, or
claim was changed while closing this provenance finding. See
`audit/reconciliation/preparation06/normalization_gate.md`. The current
acquisition and normalization manifest SHA-256 values are
`ac79a83c2d60dde1ac563f6e2cb09c58d4d7d3b06549d9b9262e4acd5a50a58b`
and
`e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab`,
respectively.

## Reopening condition

Reopen after any source commit, repository layout, object/schema, scoring
rule, site/date metadata producer, or model-data join changes.
