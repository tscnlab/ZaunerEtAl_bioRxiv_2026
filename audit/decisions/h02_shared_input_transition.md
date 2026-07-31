# H02/H11 shared-input transition

Decision ID: `H02-INPUT-001`
Date: 2026-07-31
Status: approved; H02 and H11 hypothesis-specific rebuilding required
Owner: coordinating Nature Health retargeting task

## Decision

The six shared artifacts below are the approved H02/H11 input bundle. They
supersede every earlier identity listed in
`audit/handoffs/H02_shared_change_request.md`.

| Shared artifact | Approved SHA-256 |
|---|---|
| `artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds` | `afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5` |
| `artifacts/06_model_data/base/metrics_chest_30_minute_context.rds` | `01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2` |
| `artifacts/12_manifests/base_model_data_artifacts.csv` | `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4` |
| `artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds` | `69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a` |
| `artifacts/06_model_data/temporal_provenance/true_utc_source_bins.rds` | `08d1adfb3e55c93da043b74d07dfade203c34f720c88062fa83eec5ebd1844f9` |
| `artifacts/06_model_data/temporal_provenance/artifact_manifest.csv` | `9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d` |

The bundle is approved as one indivisible transition. A hypothesis must not
mix an artifact from this table with an earlier base-data or temporal-
provenance identity.

## Why the identities changed

The artifacts were regenerated through the approved Preparation 02--06
pipeline after the support-rule repairs and the exact-all-zero melEDI day
exclusion. The final base data contain 816 near-eye participant-days and 902
chest participant-days, not the interim 818 and 905 days described in the
worker request. No participant was removed by the exact-all-zero rule.

The temporal artifacts were regenerated from the final verified minute-level
coverage and 30-minute outcomes. Their changed identities therefore represent
the current shared data and sequence boundaries; they are not metadata-only
substitutions from the point of view of H02 or H11.

## Independent verification

Under R 4.6.1 on 2026-07-31:

- `verify_base_model_data_artifacts()` returned `PASS`, with base-manifest
  SHA-256
  `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4`;
- the near-eye 30-minute table contained 39,168 rows, 141 participants and 816
  participant-days;
- the chest 30-minute table contained 43,296 rows, 154 participants and 902
  participant-days;
- `verify_temporal_sequence_provenance_artifacts()` returned `PASS`, with
  123,702 true-UTC source bins, 123,696 wall-outcome links, 119,537
  sequence-eligible bins and 2,632 sequence starts; and
- all four rows of the temporal manifest reported `PASS` and named coverage
  manifest
  `0281118bfd0975181f6cf5fe39237f49271fa309c6de2d42d261b48450a5ba8d`
  and metric manifest
  `6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8`.

The independent verifiers reconstruct the expected data and temporal links;
the decision is not based only on the `PASS` strings stored in the manifests.

## Required downstream action

- H02 is authorized to repin all six identities, rebuild every H02 model
  frame, rerun the selected model and diagnostics, and replace results fitted
  to any earlier bundle. No earlier H02 fit is current.
- H11 must inherit this approved temporal-provenance bundle and the approved
  H02 temporal specification. H11 must not copy H02 fitted values or a fitted
  autocorrelation parameter.
- Every other downstream hypothesis or descriptive output must verify its own
  direct shared-input pins after the Preparation 02--06 regeneration.

## Reopening condition

Reopen this decision if any of the six hashes changes, either independent
verifier fails, the accepted coverage or exact-all-zero rule changes, or H02
or H11 would use a different elapsed-time sequence definition.
