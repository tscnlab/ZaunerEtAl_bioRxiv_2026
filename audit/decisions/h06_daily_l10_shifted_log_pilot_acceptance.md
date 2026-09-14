# H06 daily L10 shifted-log pilot acceptance

Decision ID: `H06-D-005`  
Date: 2026-08-12  
Status: approved; shifted-log production stopped

## Author decision

The author explicitly accepted the recommendation in `H06-D-004` exactly as
stated:

1. accept the bounded shifted-log pilot as an adequate evaluation of the
   candidate route;
2. retain `NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE` for all three pilot
   predictors;
3. stop the full shifted-log L10 batch under the current temporal rule; and
4. retain the accepted two-part non-estimable record as the current H06-daily
   L10 result.

This closes `H06-D-G2P-L10-SHIFTLOG`. It does not amend the temporal rule,
substitute a hierarchy, or authorize a different L10 estimand.

## Controlling evidence

The independently verified gate is
`audit/decisions/h06_daily_l10_shifted_log_pilot_gate.md` (`H06-D-004` /
`CHG-113`; SHA-256
`7e17e0b12ca8295a40c66cfbde5f574eb1019a54d1248445a46743fbc29bfda6`).
It established that the one-part shifted-log hierarchy is estimable but that
all three triggered actual-date AR counterparts fail the prespecified post-AR
residual-dependence gate. The barrier is scientific adequacy, not runtime.

The accepted candidate pilot estimates remain diagnostic evidence only. Its
six likelihood-ratio p-values remain raw-only with
`PILOT_RAW_ONLY_NO_BH_UPDATE`; no adjusted value or decision exists.

## Result and computation boundary

The following remain stopped and unauthorized:

- the full six-scenario shifted-log L10 batch;
- any L10 BH-slot population or BH-family update;
- influence or deletion refits beyond the completed pilot;
- the remaining H06-daily production grid;
- H06-daily Stage 3 or Stage 4;
- any main-H06 change;
- final selection between main H06 and H06-daily;
- any fixed-site, random-site, temporal, family, or hierarchy substitution;
  and
- any silent weakening or reinterpretation of the temporal acceptance rule.

The accepted `H06-D-001`/`H06-D-002` two-part failure record remains the
current H06-daily L10 result: all twelve planned joint association and
site-heterogeneity L10 slots are non-estimable with missing raw and adjusted
p-values, while positive-only and MAP outputs remain descriptive diagnostics
only.

## Authorized no-refit closure

The H06-daily task may perform one bounded documentation/checksum closure:

- create a **new**, separate task-owned acceptance addendum that pins this
  decision and `H06-D-004`;
- create a non-circular acceptance manifest and focused identity test; and
- verify that the pilot report, transition, model bundle, input/code/output/
  software/report manifests, all 118 historical identities, and all accepted
  two-part artifacts remain byte-identical.

It must not edit or rerender the existing pilot QMD/HTML, alter the pilot
transition or report manifest, modify the frozen worker handoff, fit or refit a
model, recompute a diagnostic or p-value, update a BH field, or touch shared
preparation, main H06, Stage 3/4, or final-version records. After returning the
new acceptance-addendum and manifest identities, the task must stop.

## Next analytical step

There is no automatically authorized analytical next step in H06-daily. A
later author decision would be required to resume any remaining non-L10 daily
grid or reporting work. Final H06 version selection remains deferred under
`H06-006`.

## Reopening condition

Reopen only if a controlling identity or verifier fails, the author explicitly
revises the temporal estimand or acceptance rule, or a later author decision
separately authorizes the remaining non-L10 daily grid. Mere compute
availability does not reopen the gate.
