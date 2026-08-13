# H06_daily L10 shifted-log pilot acceptance addendum

- Date: 2026-08-12
- Acceptance decision: **H06-D-005 / CHG-114**
- Closed gate: **H06-D-G2P-L10-SHIFTLOG**
- Status: **approved_stopped**
- Scientific computation in this closure: **none**

## Controlling author acceptance

The author accepted the H06-D-004 recommendation exactly as stated. The
controlling acceptance is
`audit/decisions/h06_daily_l10_shifted_log_pilot_acceptance.md`, SHA-256
`6485e1d6fdd950aed6c8c983407a55c72085c10059bd4a03120a6746109b9fbb`.
The independently verified author gate remains
`audit/decisions/h06_daily_l10_shifted_log_pilot_gate.md`, SHA-256
`7e17e0b12ca8295a40c66cfbde5f574eb1019a54d1248445a46743fbc29bfda6`.

The accepted disposition is:

1. accept the bounded shifted-log pilot as an adequate evaluation of the
   candidate one-part route;
2. retain `NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE` for Work/Free day,
   activity, and previous-night sleep;
3. stop the full six-scenario shifted-log L10 batch under the current temporal
   acceptance rule; and
4. retain the accepted two-part non-estimable record as the current H06-daily
   L10 result.

This acceptance does not amend the temporal rule, promote the registered
benchmark, substitute another hierarchy or family, or authorize a different
L10 estimand.

## Frozen pilot result

The pilot report, HTML, transition, model bundle, input/code/output/software/
report manifests, and both existing focused tests retain their verified
identities. No existing file was edited or rerendered for this closure.

All three pilot rows retain the temporal disposition
`NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE`, overall disposition
`NOT_ACCEPTABLE`, and recommendation
`DO_NOT_RELEASE_FULL_L10_SHIFTED_LOG_BATCH`. The six pilot likelihood-ratio
p-values remain diagnostic raw-only values with
`PILOT_RAW_ONLY_NO_BH_UPDATE`; every pilot adjusted-p and adjusted-decision
field remains missing.

The accepted two-part result remains unchanged. Its twelve primary and gap-
timing-unaware near-eye joint association or site-heterogeneity slots retain
`NON_ESTIMABLE_COMPONENT_FAILURE`. L10 remains metric slot 3 in each named
15-slot family, with raw p-values, Benjamini--Hochberg adjusted p-values, and
adjusted decisions missing. Positive-only and MAP outputs remain descriptive
diagnostics and do not substitute for a joint result.

## Preservation and no-refit closure

The final historical-preservation evidence contains 118 H06-D-001/H06-D-002
entries. Every current file still matches its recorded SHA-256 and byte count,
including the frozen worker handoff. This closure did not fit or refit a model,
recompute a diagnostic or p-value, update a BH field, run a deletion analysis,
or execute a render.

The new non-circular acceptance manifest is
`artifacts/12_manifests/H06_daily/H06_daily_l10_shiftlog_pilot_acceptance_manifest.csv`.
It pins this addendum and its focused identity test, but deliberately does not
hash itself. The focused no-refit verifier is
`tests/hypotheses/H06_daily/test_h06_daily_l10_shiftlog_acceptance.R`.

## Stop boundary and next step

The gate is closed and the shifted-log L10 production route is stopped. No
full L10 batch, BH update, deletion batch, remaining H06-daily grid, Stage 3,
Stage 4, main-H06 change, or final H06 version selection is authorized.

There is no automatic analytical next step. Resuming any non-L10 daily grid
requires a separate later author decision. Revisiting shifted-log L10 requires
an explicit amendment to the temporal estimand or acceptance rule. Final H06
version selection remains deferred under H06-006.
