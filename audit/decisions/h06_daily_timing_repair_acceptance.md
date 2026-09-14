# H06_daily timing-repair route acceptance

Decision ID: `H06-D-011`  
Change ID: `CHG-121`  
Date: 2026-08-12  
Status: author approved; production not authorized

## Author decision

The author accepts the participant-cluster HC3 route exactly as recommended at
`H06-D-G2P-TIMING-REPAIR` and independently verified under `H06-D-010`.

This accepts a prospective method for the four held participant-day timing
outcomes. It does **not** accept any pilot estimate or p-value and does **not**
authorize the complete remaining non-L10 production grid.

## Accepted route

For the four timing outcomes and three approved predictors, the accepted
candidate route retains the sealed participant-day outcomes, clock encodings,
fixed site adjustment, and predictor contrasts. Its reduced, additive, and
predictor-by-site mean structures use fixed-site linear models, with
participant-cluster HC3 covariance calculated by
`sandwich::vcovCL(type = "HC3", cadjust = TRUE, fix = FALSE)`.

This route may be used only in a separately authorized production contract.
It must retain cluster-minus-one t/F reference distributions, full-precision
raw tests, the declared 15-slot multiplicity families, and the complete
diagnostic record.

## Retained qualifications

The author accepts the route with all of these qualifications unchanged:

- the Student-t association sensitivity for first timing above 250 lx melEDI,
  work versus free day, shifts by 1.23 HC3 standard errors and is a major
  limitation;
- the no-nugget AR association sensitivity for L10-midpoint activity shifts by
  1.26 HC3 standard errors and is a major limitation;
- three additive no-nugget AR diagnostics remain unresolved because their fits
  do not converge;
- no no-nugget AR structure meets the descriptive pooled-and-every-site
  residual-lag rule;
- timing predictor-by-site interactions remain sensitivity-dependent: most
  Student-t interaction comparisons are unstable, while several no-nugget AR
  interaction fits are unstable or nonconverged; and
- timing interaction results cannot support an unqualified interaction or
  site-specific claim. If later production is authorized, the prespecified
  robust interaction tests and multiplicity slots remain for transparent
  reporting, with these limitations attached.

These qualifications are part of the accepted method. They may not be removed
because a later test is statistically significant or because another
sensitivity gives a more favorable coefficient.

## Pilot status

All 24 raw pilot Wald tests remain labelled
`PILOT_RAW_ONLY_NO_BH_UPDATE`. Their adjusted-p fields remain missing. The
pilot made no BH update, accepted association, reader-facing result, or claim.

The accepted evidence is the report
`audit/hypotheses/H06_daily/11_timing_repair_pilot.html`, SHA-256
`faa4efecd2a969284dfe399684eb7cf73a0bebdb0fb391227d85cc3b0112794e`.
The independent gate is
`audit/decisions/h06_daily_timing_repair_pilot_gate.md`, SHA-256
`f398f748369351e084f19caba05a11636e8aead3df9ccd3586c8338100083461`.

## Exact bounded closure authorization

The H06_daily task may perform one no-refit closure step in new task-owned
files only:

1. create
   `audit/hypotheses/H06_daily/H06_daily_timing_repair_acceptance.md` as a
   concise acceptance addendum pinning `H06-D-010`, this decision, the accepted
   report, transition, manifests, model bundle, focused test, and retained
   qualifications;
2. create a non-circular acceptance manifest under
   `artifacts/12_manifests/H06_daily/` that pins the addendum and all controlling
   inputs but excludes itself and any later coordinator verification;
3. create a focused H06_daily test that verifies the decision identities, 12
   accepted candidate cells, 24 raw-only tests with missing adjusted values,
   the two named 1–<2-SE limitations, the three unresolved additive AR checks,
   the sensitivity-dependent interaction disposition, and all 571 protected
   prior identities; and
4. stop with no authorized analytical next step.

The closure must not edit or rerender the historical pilot report, transition,
models, diagnostics, tables, figures, source data, or existing manifests.

## Explicitly unauthorized

This author decision does not authorize any model fit or refit, full timing or
non-L10 production grid, BH update, deletion battery, bootstrap, simulation,
new sensitivity, chest or paired/common analysis, gap-timing-unaware analysis,
Stage 2 merge, Stage 3, Stage 4, website integration, shared edit, L10 or MDER
change, temporal-GAMM or pre-sleep change, main-H06 change, commit, or push.

A separate explicit author decision is required before production. A bare
reference to this acceptance is insufficient production authorization.

## Reopening condition

Reopen if a controlling identity or verifier fails; an accepted frame,
outcome, predictor, covariance, limitation, multiplicity rule, protected file,
or interpretation changes; or the author separately authorizes production or
selects a different route.
