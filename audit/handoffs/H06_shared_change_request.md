# H06 shared change request

Status: **no active upstream blocker; H06 Stage 4 website integration and the
METRIC-010 provenance-only repin are resolved**

## Resolved: H06 preparation-page website integration

The coordinator added
`audit/hypotheses/H06/H06_analysis_preparation.qmd` immediately after
`notebooks/hypotheses/H06.qmd` in both the Nature Health profile render list
and Hypothesis analyses navigation. The integrated `_quarto-nathealth.yml`
SHA-256 is
`02aed2be2851444d81cfe26a9845e830a91a851379d605252508ac4cb2c72f02`.
No other shared file was edited for this request. Narrow profile renders of
the H06 result and preparation pages pass, their reciprocal links verify, and
the H06 preparation source is copied byte-identically into the website build.
No further shared configuration change is requested.

## 0. Resolved: METRIC-010 provenance-only repin

### Detection

At 2026-08-11 12:15:28–12:15:29 +0200, while rebuilding only the requested
Stage 3 site-screen display, the unchanged H06 input-contract check stopped
before producing output. Both shared hourly objects had new hashes because
METRIC-010 repinned their upstream manifest/provenance attributes:

| Input role | Accepted H06 SHA-256 | Current SHA-256 |
|---|---|---|
| Primary near-eye hourly input | `cee864bb0e329b98444088b777c7245250be68111ec9f24db7c0e3f395ed6445` | `27b17c0232a90b6982377b1944b30e5574a02e691217a81f671ab14e45916f67` |
| Complementary chest hourly input | `50f50ca5d39d621d06f2794037c4b769e01fc7329a70432e79a51203727ed209` | `99885940c952c60ff6981ce029758ac43aec22c41cc27f22176fb3ab4f9c7186` |

The affected shared files are
`artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds` and
`artifacts/06_model_data/base/metrics_chest_one_hour_context.rds`. The H06
worker did not change either file, update the H06 pin, bypass the contract,
or refit a model.

### Coordinator verification and disposition

The coordinator rebuilt all six H06 Stage 2 analysis frames from the repinned
shared inputs under R 4.6.1 and compared them with the accepted frozen H06
frames with tolerance 0 and attributes included. All six were exactly
identical. The verification evidence is:

- `audit/scripts/verify_mder_METRIC_010_h06_hourly_invariance.R`
- `artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/h06_hourly_frame_invariance.csv`
- evidence SHA-256
  `75794d5dc13392a05cd81ac57456bd03ccc5f12713f8f774db72f2bfab44de4f`

The coordinator authorized the H06-local near-eye and chest pins to be updated
to the current hashes while retaining the accepted frozen Stage 2 models and
results as controlling. The local contract now verifies both current objects.
This was an upstream provenance-only repin: it caused zero H06 model-frame,
estimate, interval, diagnostic, sensitivity, or claim change. No H06 model was
refit, and no shared source, preparation, or configuration change is requested.

## Explicit non-request: TUM exercise participant identity

No source or package change is requested for the TUM S001/S101 transition.
DEV-056 is approved, and the current analytical contract is already correct:
`melidosData` 1.0.6, immutable exercise-diary commit
`618fda8521f3cf581661ceb2c026e3de7cd9ba82`, DOI
`10.5281/zenodo.16893901`, and object SHA-256
`0db56324e9826d427c42984fdfc43eb1e7487211365f222a1c0b2ecff618f1ef`.
The normalized input contains seven `TUM_S001` records and zero `TUM_S101`
records, with no local rewrite. Per coordinator direction, H06 must not fetch
remote HEAD, update `melidosData`, or rebuild shared preparation. Stage 2 will
not be reopened; its read-only seven/zero assertion already passed.

## 1. Supersede the stale Preparation 06 base-model narrative

### Target

`audit/reconciliation/preparation06/base_model_gate.md`

### Confirmed discrepancy

The narrative still records the earlier base-model contract: 811 near-eye and
897 chest participant-days, artifact-manifest SHA-256
`fd48dc5d1ecd5da125dd2c360c32239f0adfe7009eca881f5838b0e61b81b13d`,
and its associated upstream hashes. The direct current inputs consumed by H06
instead implement the approved `H02-INPUT-001` transition and contain 816
near-eye and 902 chest participant-days. Their current base manifest is
`artifacts/12_manifests/base_model_data_artifacts.csv`, SHA-256
`142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4`.

### Coordinator disposition

The coordinator classified this as nonblocking documentation drift and
directed H06 not to edit shared preparation. A later shared documentation
refresh may identify the current approved base-data contract, counts, and
hashes, but H06 must not revert the current artifacts to the older counts.
Stage 2 reverified the pinned current direct artifacts and required no shared
rerun.

### Impact on H06

This is provenance-documentation drift, not a reason to rewrite H06 inputs.
The Stage 1 candidate-sample audit and H06-002 Stage 2 implementation remain
reproducible from the current artifacts. It does not require a data rerun and
does not block the current H06-G3 author review.

## 2. Resolved for H06 exploratory use: 3,600-second sedentary value

### Affected record

- site: `KNUST`
- participant: `KNUST_S005`
- local date: `2024-11-04`
- normalized field: sitting/reclining time (source numeral `3,600` under a
  minutes-labelled field)
- current input: the normalized exercise diary consumed by H06

### Author disposition

The author has specified that this one numeral represents **3,600 seconds**,
or **1 hour**. This resolves the H06 analysis gate for explicitly labelled
exploratory sedentary-time work. Sedentary time remains outside the approved
primary analysis and every confirmatory multiplicity family.

### H06 implementation boundary

H06 will not edit the normalized diary or any shared source. Its owned
analysis adapter derives `sedentary_h = 1` for exactly this row, preserves the
source-labelled 60-hour conversion separately for provenance, and asserts the
one-row mapping during render. Any future source-package correction remains a
coordinator/source-owner change and would require a pinned comparison before
it could replace the current analytical source.

No upstream data edit or shared-preparation rerun is requested by H06 for this
record.

## Scope guard

The H06 worker did not edit shared preparation, central ledgers/configuration,
normalized diaries, manuscript files, or another hypothesis. Only the
H06-local input-contract pins were updated after the coordinator's exact-frame
verification and authorization.
The stale Preparation 06 narrative remains a documentation-only upstream note
(H06-S1-011). The sedentary interpretation is resolved locally for
exploration (H06-S1-010), and the already-resolved TUM identity is
H06-S1-009. Stage 4 is complete and the worker stops at H06-G4; there is no
upstream source, data, or website-integration blocker.
