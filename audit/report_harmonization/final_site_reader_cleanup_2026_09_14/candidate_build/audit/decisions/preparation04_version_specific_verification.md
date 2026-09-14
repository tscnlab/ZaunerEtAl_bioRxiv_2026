# Preparation 04 version-specific verification reporting

Decision ID: `PREP-003`  
Date: 2026-08-01  
Status: partially resolved on 2026-08-11; current metric and MDER verified,
exact current state-support reconstruction remains open

## Resolution update: `METRIC-010`

The author-approved MDER change produced a new current metric manifest,
`7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`.
A fresh independent R 4.6.1 verification reconstructed every active MDER value,
viable-minute classification, failure reason, output table, and manifest entry
from the one-minute inputs. Its audit-manifest SHA-256 is
`5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb`.

The active MDER rule retains 702 of 816 near-eye and 732 of 902 chest
participant-days. The earlier MDER support-gate manifests below describe the
superseded ratio-of-integrals estimand and are retained only as historical
evidence. They are no longer a missing verification requirement for current
MDER.

Accordingly, `PREP-003` and `FIND-044` are closed for the current metric
manifest and active MDER calculation. Their remaining open scope is limited
to complete independent reconstruction of the exact current state-support
manifest
`755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619`.
Preparation reports must distinguish this narrow remaining qualification from
the now-verified metric and MDER artifacts.

## Evidence at the original 2026-08-01 decision

The current stored Preparation 04 artifacts are identified by these manifest
SHA-256 values:

- metric artifacts: `6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8`;
- MDER support gate: `9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b`;
- state-support gate: `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619`.

The current stored metric settings contain 816 near-eye and 902 chest
participant-days. The current MDER summary retains 760 of 816 near-eye and
850 of 902 chest participant-days at the 80% support threshold.

The complete stored independent Preparation 04 reconstruction instead
identifies metric-manifest SHA-256
`ac0325716421f2d90bb83b445ffb6ad965b131e382373e45f4ad6157eac5937d`
and 811 near-eye and 897 chest participant-days. The stored independent MDER
record identifies manifest SHA-256
`c4ecfab41892e44b38dd78097277ccef5f94a379b44c7b309de281e9215a7b3c`
and retains 733 of 811 near-eye and 825 of 897 chest participant-days. CHG-046
records the intervening metric-manifest identity
`944f395e00735e6f8200798d4cde387454441d39b9defda68f583bd8778cd34b`;
it is also not the current metric manifest.

No stored record was found that independently reconstructs all metric values,
MDER classifications, and state-support classifications against all three
current manifest identities. Later downstream manifests pin current input
identities, but an identity check is not an independent reconstruction of the
scientific values or classifications.

## Original decision

The requirements below document the boundary in force on 2026-08-01. The
`METRIC-010` resolution update above now controls current metric and MDER
reporting; only its stated state-support qualification remains active.

The Preparation 04 reader-facing rewrite may continue without rerunning any
scientific computation. It must:

1. identify the three current manifests and report only checks and stored
   summaries demonstrably tied to those current identities;
2. attribute the complete metric reconstruction and MDER support-gate result
   only to their explicitly identified earlier manifests and samples, if those
   results are useful context;
3. not describe the current metric, MDER, or state-support artifacts as having
   passed those earlier complete independent verifications; and
4. retain independent current-manifest reconstruction of all three artifact
   families as open audit item `FIND-044`.

This provenance gap is not evidence that the current artifacts or downstream
results are incorrect. Conversely, successful downstream reads, file
fingerprints, and stored summaries cannot substitute for an independent
reconstruction of scientific values and support classifications.

Under this authorization, the preparation-report worker must not run a metric
builder, `verify_metric_derivation_core()`,
`verify_mder_support_gate_artifacts()`, a state-support verifier, or any
downstream hypothesis computation. Those checks can be scheduled separately
as scientific audit work. If they pass against the current manifests, the
reader-facing report may then be updated to state that result.

## Reopening condition

Reopen if any current manifest changes, a matching independent-verifier record
is found or produced, or verification identifies a discrepancy in metric
values, support classifications, sample flow, linkage, or artifact identity.
