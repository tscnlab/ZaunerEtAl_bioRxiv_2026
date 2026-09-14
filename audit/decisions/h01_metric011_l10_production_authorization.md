# H01 METRIC-011 L10 production authorization

Decision ID: `H01-013`  
Date: 2026-08-12  
Status: approved; bounded production in progress

## Author decision

The author explicitly replied `accept` in the H01 task after being presented
with the three dispositions verified under H01-012. This accepts all three:

1. retain the established Gaussian `log10(melEDI + 0.1)` models as acceptable
   with limitations for the four affected primary L10 targets;
2. accept that METRIC-011 changes no fitted sample, inferential-support
   decision, sensitivity classification, or scientific claim; and
3. authorize at least 1,000 successful joint bootstrap refits for each of the
   four affected primary L10 targets.

## Authorized production scope

The H01 worker may run the pilot-verified production implementation for only:

- primary near-eye, all available;
- primary chest, all available;
- primary near-eye, paired/common; and
- primary chest, paired/common.

Each target must retain at least 1,000 successful joint bootstrap refits. The
run may use the verified checkpoints and production function. Its pilot-based
wall-time estimate is 24.65 minutes for all four targets.

After production, the worker must run the focused verifier before replacing
any accepted output. Only if verification passes may it integrate the affected
L10 bootstrap intervals, dependent L10 summaries, complete-family
multiplicity derivatives that consume the current L10 slot, and corresponding
L10 portions of the H01 Stage 2--4 reports, tests, manifests, and handoff.

## Preservation boundary

This authorization does not permit refitting or altering:

- any non-L10 model, raw test, diagnostic, sensitivity, prediction, or
  bootstrap artifact;
- any unchanged gap-timing-unaware L10 fit or bootstrap output;
- the separate METRIC-010 MDER gate or its artifacts;
- shared preparation, central ledgers, shared Quarto configuration, or
  manuscript files; or
- an accepted H01 claim beyond the verified METRIC-011 scope.

The 830 protected non-L10 artifacts remain hash-guarded. If production or its
focused verification changes a support decision, diagnostic gate,
sensitivity classification, or scientific claim, the worker must stop at a
new author gate before report integration. Otherwise, bounded integration may
proceed after verification and must return final identities for coordinator
closure.

## Controlling verified gate

H01-012 remains the independent point-and-pilot verification record. Its
decision-file SHA-256 at authorization is
`30b43ef447a2310edd05b245c0c36d0c6a6966f2394f1a149db13d4afe384445`.
The verified author-gate, point-fit, pilot, and focused-test identities are
listed there.

## Reopening condition

Reopen production authorization if the target set, successful-refit minimum,
model family, input pin, checkpoint implementation, pilot result, runtime
projection, protected-artifact guard, or focused verifier changes. Stop and
seek a new author decision if production changes a support decision,
diagnostic classification, sensitivity classification, or claim.
