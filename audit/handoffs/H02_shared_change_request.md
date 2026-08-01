# H02 shared-artifact change notification and coordinator request

Date: 2026-07-31
Status: **Resolved by coordinator decision `H02-INPUT-001`; H02-specific
inputs were re-pinned and rebuilt, and no shared code or shared data was
modified by the H02 worker**
Requester: H02 hypothesis worker
Owner for review: coordinating Nature Health retargeting task

## Resolution

`audit/decisions/h02_shared_input_transition.md` approved the final bundle as
one indivisible transition and superseded every earlier identity below:

| Shared artifact | Approved SHA-256 |
|---|---|
| `artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds` | `afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5` |
| `artifacts/06_model_data/base/metrics_chest_30_minute_context.rds` | `01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2` |
| `artifacts/12_manifests/base_model_data_artifacts.csv` | `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4` |
| `artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds` | `69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a` |
| `artifacts/06_model_data/temporal_provenance/true_utc_source_bins.rds` | `08d1adfb3e55c93da043b74d07dfade203c34f720c88062fa83eec5ebd1844f9` |
| `artifacts/06_model_data/temporal_provenance/artifact_manifest.csv` | `9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d` |

Independent base and temporal verification passed under R 4.6.1. The final
base contains 816 near-eye and 902 chest participant-days. H02 rebuilt all
eight model frames and replaced every fit from an earlier bundle. The
transition chronology below is retained as audit history; references to
“current” or “paused” in that chronology describe the state at the time of
the corresponding notification and are superseded by this resolution.

## Trigger

The H02 worker validated and fitted the approved shared 30-minute and temporal
provenance artifacts under the following SHA-256 identities:

| Shared artifact | Identity used for the first completed H02 fit |
|---|---|
| `artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds` | `9ed5ebd0445a92ce67f0d535f45f5e69d4e06cf6c65f5f332ce90b107bbec8a0` |
| `artifacts/06_model_data/base/metrics_chest_30_minute_context.rds` | `44dd1035abbce316e72d3ff968cad02a6f27c3c877d3439d29ffb05581a44465` |
| `artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds` | `a617893e74bbbd760950c185d0c548ff55692c52ded554a527dad2d72f2e6eb4` |
| `artifacts/06_model_data/temporal_provenance/true_utc_source_bins.rds` | `87c05a2534479c02ed62e16bc74a4c8a6a061aff125a528e404f403b3e2ff46b` |

While the selected H02 models were running, those four shared files were
replaced outside the H02 worker scope. Their current identities are:

| Shared artifact | Current SHA-256 | Current manifest status |
|---|---|---|
| `artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds` | `72edbccfe43e2852885170c72068a9aafc855fc789dc54cb7c54442e837349d2` | `PASS` |
| `artifacts/06_model_data/base/metrics_chest_30_minute_context.rds` | `7c6453716effe2d65318a937059e216c4100a791abbb10600fafef2c9e4c8bf9` | `PASS` |
| `artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds` | `f294d2c5758c6b65edf5f175cf7b1eb4c0b5ea747848dc9452a01ae0363ec4c6` | `PASS` |
| `artifacts/06_model_data/temporal_provenance/true_utc_source_bins.rds` | `3b7e28974652b1951f0b9070b28d52cc3d01027677bfb6d5c752f906bed91f66` | `PASS` |

The current verification-manifest identities are
`91013d641b8e1dc9559dafb5e789d6cbff61f0ee2ec0fb1c6ab3b0c78641d8bb`
for `artifacts/12_manifests/base_model_data_artifacts.csv` and
`728871dbe1d31b1c455bbbb792602dfc4468095856f7b6190c01f59fc9fcdbaa`
for
`artifacts/06_model_data/temporal_provenance/artifact_manifest.csv`.
These two manifest files were regenerated once more during H02 finalization.
Their H02 target rows still verify the unchanged current data identities shown
above with status `PASS`; this second transition therefore changes provenance
metadata but not any H02 scientific input or fitted result.

### Further transition detected during the `sz` refit

After the identities above had passed the H02 contract test, all three
coordinator-owned temporal-provenance identities changed again while the H02
worker was fitting the revised hypothesis-specific model:

| Shared artifact | Previously pinned SHA-256 | Newly observed SHA-256 |
|---|---|---|
| `artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds` | `f294d2c5758c6b65edf5f175cf7b1eb4c0b5ea747848dc9452a01ae0363ec4c6` | `69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a` |
| `artifacts/06_model_data/temporal_provenance/true_utc_source_bins.rds` | `3b7e28974652b1951f0b9070b28d52cc3d01027677bfb6d5c752f906bed91f66` | `08d1adfb3e55c93da043b74d07dfade203c34f720c88062fa83eec5ebd1844f9` |
| `artifacts/06_model_data/temporal_provenance/artifact_manifest.csv` | `728871dbe1d31b1c455bbbb792602dfc4468095856f7b6190c01f59fc9fcdbaa` | `9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d` |

The regenerated manifest identifies the two newly observed RDS files and
labels its build `PASS`, but the H02 input contract and existing H02 model
frames remain pinned to the preceding identities. The scientific effect of
this latest transition has not been adjudicated. The H02 worker therefore
stopped before re-pinning, rebuilding model data, or fitting reportable
results against the new shared state.

### Concurrent base-model-data transition detected during dominance work

While the H02 worker implemented the requested dominance analysis, the two
coordinator-owned base 30-minute artifacts and their verification manifest
also changed:

| Shared artifact | H02-pinned SHA-256 | Newly observed SHA-256 | Current manifest rows | Current manifest status |
|---|---|---|---:|---|
| `artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds` | `72edbccfe43e2852885170c72068a9aafc855fc789dc54cb7c54442e837349d2` | `afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5` | 39,168 | `PASS` |
| `artifacts/06_model_data/base/metrics_chest_30_minute_context.rds` | `7c6453716effe2d65318a937059e216c4100a791abbb10600fafef2c9e4c8bf9` | `01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2` | 43,296 | `PASS` |
| `artifacts/12_manifests/base_model_data_artifacts.csv` | `91013d641b8e1dc9559dafb5e789d6cbff61f0ee2ec0fb1c6ab3b0c78641d8bb` | `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4` | — | — |

The manifest-level `PASS` labels verify internal artifact consistency; they do
not resolve whether the new bundle is the coordinator-approved superseding
input for H02. The H02 contract test and the new dominance runner therefore
fail closed before any output is written. No H02 hash has been re-pinned and
no H02 model frame has been rebuilt from this transition.

## Analytical effect on H02

A read-only R comparison of the previously pinned H02 model frames with model
frames built in memory from the replacement shared artifacts found:

| Placement | Previous participant-days | Current participant-days | Previous fitted 30-min observations | Current fitted 30-min observations | New-only observations | Changed common melEDI values | Changed common AR-start flags |
|---|---:|---:|---:|---:|---:|---:|---:|
| Near eye | 811 | 818 | 37,394 | 37,852 | 458 | 0 | 80 |
| Chest | 897 | 905 | 41,469 | 41,986 | 517 | 0 | 84 |

The replacements add seven near-eye and eight chest participant-days; no
previously fitted day is removed and no common melEDI value changes. The
temporal-provenance rebuild changes AR sequence-start status for common rows,
so the earlier H02 models cannot be treated as current even though most
outcomes are identical.

The exact added participant-days are:

| Placement | Site | Participant | Local date |
|---|---|---|---|
| Near eye and chest | BAUA | `BAUA_S015` | 2025-07-25 |
| Near eye only | FUSPCEU | `FUSPCEU_S008` | 2024-10-28 |
| Near eye and chest | FUSPCEU | `FUSPCEU_S025` | 2025-02-09 |
| Near eye and chest | IZTECH | `IZTECH_S010` | 2025-04-17 |
| Near eye and chest | KNUST | `KNUST_S001` | 2024-10-10 |
| Near eye and chest | UCR | `UCR_S003` | 2025-06-20 |
| Near eye and chest | UCR | `UCR_S005` | 2025-06-27 |
| Chest only | UCR | `UCR_S022` | 2025-08-01 |
| Chest only | UCR | `UCR_S022` | 2025-08-02 |

## Historical requested coordinator action

The H02-specific approval requests in items 1, 5, and 6 were satisfied by
`H02-INPUT-001`. Broader cross-hypothesis propagation remains coordinator
owned.

1. Confirm that the current `PASS` manifests supersede the earlier shared
   identities and record the reason for the rebuild in the central change
   ledger.
2. Update the stale hashes in
   `audit/findings/h02_h11_true_time_sequence_provenance.md`.
3. Notify H11 that both the H02 temporal specification and the regenerated
   temporal-provenance inputs must be inherited from the new identities.
4. Audit every hypothesis-specific input pin derived from the regenerated
   coverage, metric, base-model-data, or temporal-provenance bundles before
   accepting any result fitted during the transition.
5. Confirm whether the further identities
   `69232e8f...`, `08d1adfb...`, and `9355f7ca...` supersede the preceding
   temporal-provenance bundle. If they do, authorize the H02 worker to repin
   its hypothesis-specific contract and rebuild H02 model frames; if they do
   not, restore the coordinator-approved bundle before H02 refitting resumes.
6. Confirm whether the current base-model identities
   `afa5a233...`, `01a4a85e...`, and `142d1044...` supersede the H02-pinned
   base bundle. Record the upstream reason and every affected downstream
   hypothesis before authorizing an H02 rebuild.

The H02 worker did not edit any shared producer, shared artifact, central
ledger, or shared Quarto configuration. H02-specific artifacts were rebuilt
only after pinning the current `PASS` manifests and verifying their target
rows.

## Affected downstream hypotheses

Directly affected by the changed 30-minute outcome/provenance artifacts:

- H02; and
- H11.

Potentially affected by the regenerated shared coverage/metric/base bundle
and therefore requiring coordinator hash-propagation checks:

- H01 through H11;
- placement and descriptive summaries;
- manuscript and supplementary outputs that consume any regenerated result.

The direct H02/H11 effect is established. The broader list is a provenance
notification, not a claim that every fitted estimate must change.
