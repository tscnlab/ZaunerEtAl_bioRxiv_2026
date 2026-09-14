# Preparation 06 model-input normalization gate

Status: `PASS`  
Date: 2026-07-30  
Runtime: R 4.6.1

## Verified inputs

- Acquisition manifest:
  `ac79a83c2d60dde1ac563f6e2cb09c58d4d7d3b06549d9b9262e4acd5a50a58b`
- Normalization manifest:
  `e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab`
- Source releases: nine exact site commits and DOIs from
  `config/site_sources.csv`, with one immutable modality-specific upstream
  pin for the corrected TUM exercise diary. The source-pin manifest SHA-256
  is
  `3fbf9f40125c60e1d0779d2b2d524e79534597586c60ec236a1ce16299e18831`.

## Canonical outputs

| Modality | Rows |
|---|---:|
| Demographics | 191 |
| Chronotype | 186 |
| LEBA | 184 |
| VLSQ-8 | 184 |
| Exercise diary | 1,174 |
| Light-exposure diary | 30,199 |
| Sleep diary | 1,276 |

The deterministic 15-row, 11-column manifest contains seven one-object
analytical RDS files and eight audit CSVs. Runtime write timestamps are not
part of this content-addressed manifest; output hashes, byte sizes, dimensions,
producer, R version, and exact input-manifest identity remain recorded. The
independent verifier reconstructed all 963 source columns and
confirmed exact values, missingness, scores, factor levels, units, labels,
release provenance, row traces, and derived true-UTC/local-wall coordinates.
All 963 value-preservation checks passed.

The TUM exercise diary is pinned to commit
`618fda8521f3cf581661ceb2c026e3de7cd9ba82`, SHA-256
`0db56324e9826d427c42984fdfc43eb1e7487211365f222a1c0b2ecff618f1ef`
(2,662 bytes). The upstream object now contains seven `TUM_S001` dates from
13--19 May 2024, no `TUM_S101` row, and no duplicate participant-day key.
No normalization-time ID rewrite is applied.

A fail-closed predecessor/current comparison confirmed that the only retained
analytic-field change is `Id` on source rows 4--7. The regenerated upstream
object also lost three `type_english` values on rows 4, 5, and 7. This is
recorded as a non-analytic free-text difference: both `type` and
`type_english` remain prohibited from analytical RDS files, and no free-text
content is exported. Column-level comparison hashes and row-only difference
locations are in
`audit/reconciliation/preparation06/tum_exercise_source_transition_columns.csv`
(SHA-256
`ed59acfa957817871db777c498c1544e30937363e02c623dccff26cfcaeffdc9`).

## Retained interval issues

- Light-exposure diary: 30,172 analysis-eligible intervals and 27 retained,
  reason-coded quarantined rows (one RISE and 26 THUAS), all missing both
  interval endpoints.
- Sleep diary: 1,275 analysis-eligible intervals and one retained,
  reason-coded quarantined MPI row with a missing wake time.
- Exercise and light-diary form-completion timestamps remain metadata and are
  explicitly excluded from interval analysis.

No source questionnaire score was recalculated. Free-text fields were audited
only for aggregate presence and missingness; their contents do not enter any
analytical RDS or audit CSV.

## Verification

The following checks passed:

1. acquisition regression test;
2. focused normalization helper, builder, and corruption tests;
3. source-pin expiry, duplicate-pin, manifest-tamper, and upstream-transition
   tests;
4. independent production verifier under R 4.6.1;
5. exact 15-artifact manifest hash, byte-size, dimensions, and input
   provenance checks;
6. two consecutive regenerations with an identical manifest SHA-256; and
7. zero duplicate or missing declared keys in the normalized outputs.

This gate closes immutable acquisition and lossless normalization only. It
does not authorize a hypothesis-specific join, complete-case exclusion,
category recoding, scoring change, model, or claim. Those remain separately
gated in Preparation 06 and H01–H11.

## Reopening condition

Reopen after any source commit, DOI, object name, schema, score, factor level,
label, time-zone rule, free-text policy, interval disposition, acquisition
manifest, or normalization implementation change.
