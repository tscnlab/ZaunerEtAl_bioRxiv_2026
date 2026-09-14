# Current Preparation 06 base-model input gate

Decision ID: `PREP06-BASE-002`  
Date: 2026-08-07; repinned 2026-08-12  
Status: **approved for downstream fitting; current metric, MDER, and numerical-zero reconstruction verified, state-support reconstruction remains qualified**

## Scope

This decision identifies the current shared inputs for hypotheses that use the
Preparation 06 model-ready data. It supersedes
`audit/reconciliation/preparation06/base_model_gate.md` only for selecting
current downstream inputs. The earlier gate remains an accurate historical
record for metric-manifest identity `944f395e...` and its 811 near-eye and 897
chest participant-days; it must not be presented as verification of the
current artifacts.

## Current approved identities

| Artifact | SHA-256 or current value |
|---|---|
| Metric-artifact manifest | `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e` |
| Base-model-data manifest | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| Base-model input bundle | `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916` |
| Site/daylight-context manifest | `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518` |
| Gap-timing-unaware preparation manifest | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` |
| Numerical-zero evidence manifest | `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb` |
| MDER audit manifest | `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb` |
| Historical MDER-support manifest (not active under `METRIC-010`) | `9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b` |
| State-support manifest | `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619` |
| Near-eye participant-day context RDS | 816 rows; SHA-256 `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a` |
| Chest participant-day context RDS | 902 rows; SHA-256 `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057` |

The corresponding participant-level objects contain 141 near-eye and 154
chest participants. Under `METRIC-010`, MDER is available for 702 of 816
near-eye participant-days (137 participants represented) and 732 of 902 chest
participant-days (152 participants represented). MDER failure remains
metric-specific and does not remove a participant-day from other analyses.

## Verification performed

On 2026-08-11, fresh R 4.6.1 sessions using the project library independently
reconstructed the `METRIC-010` minute-level ratios, viable-minute support,
daily MDER values, failure reasons, output tables, and metric manifest. The
metric verifier returned `PASS`. A downstream rebuild then ran
`verify_base_model_data_artifacts()` against the repinned files; it returned
`PASS`, independently reconstructed the model-ready joins and contract, and
returned the base-manifest and input-bundle identities listed above. Direct
reads of the two participant-day base objects returned 816 and 902 rows.

This verifies that the current Preparation 06 model-ready layer faithfully
uses the current metric objects and preserves its declared joins, fields,
dimensions, and file identities. At the `METRIC-010` repin, an exact
participant-day comparison found zero changed cells across all 43 shared
non-MDER metric fields at either placement. Under the later `METRIC-011`
repin, exactly eight L10 mean cells changed from source-proven floating-point
residuals to exact zero; every other participant-day field and every
30-minute, hourly, participant-level, and site/daylight-context scientific
value remained exactly unchanged.

The later gap-timing-unaware MDER repair repinned the context and base bundle
once more because that prepared participant-day file supplies supplemental
dates to the context builder. The context values remained exactly unchanged,
the two participant-day base-object hashes remained byte-identical, and all
six accepted H06 hourly frames remained identical with tolerance zero and
attributes included. The new manifest and bundle identities above therefore
represent a provenance-only transition for non-MDER analyses.

On 2026-08-12, `METRIC-011` rebuilt the complete primary metric package and
repinned the context, base, H01 primary, H01 gap adapter, and descriptive
pre-analysis comparison. Independent R 4.6.1 verification proved that only
eight primary L10 mean values changed scientifically, from
`4.163336342344337e-17` lx to zero. The gap-timing-unaware scientific values
were unchanged. The complete transition and row-level source evidence are
sealed under `audit/reconciliation/l10_METRIC-011/`.

## Remaining verification boundary

`PREP-003` and `FIND-044` are now resolved for the current metric manifest and
for the active MDER definition: both have matching independent reconstruction
records. The remaining boundary is narrower: no stored record independently
reconstructs every state-support classification against the exact current
state-support manifest. This is a provenance limitation, not evidence that
the current data are wrong. It must not be generalized into a qualification
of the now-verified metric or MDER artifacts.

## Downstream authorization

H09, H10, and other downstream hypothesis tasks may build model frames and
fit models from the current identities above, provided that they:

1. pin and verify the current manifest and direct-input hashes before fitting;
2. carry the remaining `PREP-003`/`FIND-044` state-support qualification in
   their provenance records when state-supported outcomes are used;
3. describe the current metric and MDER artifacts as independently verified,
   but do not extend that statement to the exact current state-support
   classifications;
4. stop if any current identity, row count, key invariant, or expected support
   count differs; and
5. reopen affected results if later current-manifest reconstruction identifies
   a discrepancy.

For placement-matched participant-level IS and IV, no current artifact
recomputes those metrics on identical paired participant-day sets. They must
therefore remain unavailable/non-estimable in paired placement comparisons.
H10 may retain all-available near-eye IS/IV as primary and all-available chest
IS/IV as complementary evidence, but must not approximate a paired comparison
from those unequal day sets. No shared recomputation is authorized by this
decision.

## Reopening conditions

Reopen if any identity above changes, the metric or base verifier no longer
passes, a matching current state-support reconstruction is produced, or a
reconstruction finds a discrepancy in metric values, support classifications,
sample flow, or linkage.
