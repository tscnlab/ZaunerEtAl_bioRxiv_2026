# H06_daily remaining non-L10 bounded-pilot transition

- Gate: `H06-D-G2P-NONL10`
- Date: 2026-08-12
- Status: `verified_awaiting_author_decision`

## Controlling authorization

- `H06-007 / CHG-116` selects the completed hourly H06 analysis as primary and
  assigns H06_daily the complementary, preregistration-oriented participant-day
  role.
- `H06-D-007 / CHG-117` authorizes only the current-source/reuse checks, the
  15-cell primary near-eye timing-family pilot, and exactly 50 representative
  participant/site deletion refits.
- No full remaining grid, BH update, bootstrap, simulation, Stage 3, Stage 4,
  main-H06 edit, or final H06 integration was authorized or run.

## Completed bounded scope

1. All 26 current-source and historical pins passed.
2. The candidate inventory contains 468 exact frames: 13 unfinished non-L10
   registry slots × 3 predictors × 12 scenario/placement/sample roles.
3. Current wide-RDS and long-CSV non-L10 metrics reconcile under the project's
   `1e-12` numeric-representation tolerance. The maximum scaled difference is
   `2.22e-16`; missingness and estimability are identical.
4. The three earlier representative additive objects pass exact analytical
   reuse: response/source vectors, fitted frame, formula, design matrix,
   contrasts, family/link, optimizer, warnings, convergence, and software are
   identical. Only an unrelated global `metric_settings` tibble attribute was
   repinned upstream.
5. Fifteen timing cells fitted 99 model components. Three cells—all three
   predictors for mean timing above 250 lx melEDI—are `ACCEPTABLE`.
6. The remaining 12 timing cells are not acceptable:
   - M10 midpoint: three temporal-stability failures;
   - L10 midpoint: three Gaussian-core failures;
   - first timing above 250 lx melEDI: two Gaussian-core failures and one
     temporal-stability failure; and
   - last timing above 250 lx melEDI: three temporal-stability failures.
7. Nine cells triggered and fitted the actual-date, gap-aware AR counterpart.
   None of those nine met the post-AR site-specific residual threshold; one was
   singular.
8. Exactly 50 serial deletion refits completed with zero fit failures, zero
   warnings, and zero direction reversals. Four usable representative classes
   had maximum shifts below one full-model SE. The already failed strict-clock
   runtime representative shifted by 1.10 SE, a major limitation that does not
   rescue that family.
9. The clock pilot took 3.6 seconds; the 50 fitted deletion models took 1.3
   cumulative seconds. A full 468-frame participant/site deletion battery is
   projected to require 66,664 refits and 30.5 minutes; base fits add about 1.9
   minutes. This is a lower bound before triggered AR fits, diagnostic outputs,
   and rendering.
10. All 535 protected pre-existing H06_daily files remained byte-identical.

## Multiplicity and frozen branches

- No BH update was run. Pilot likelihood-ratio p-values are stored as raw
  production-code checks only and are not interpreted.
- L10 mean remains the named missing slot 3 under the accepted two-part route.
- MDER slot 15 remains frozen; no raw MDER model, estimate, interval,
  diagnostic, sensitivity, or claim changed.
- The accepted 30-minute temporal analysis and pre-sleep no-nugget sensitivity
  remain frozen.
- Main hourly H06 remains primary and frozen.

## Recommended author disposition

Accept this bounded pilot and keep the unchanged full 13-slot production batch
stopped. Authorize a new bounded, prespecified repair pilot for the four failed
timing outcomes before deciding production. The repair must not use deletion,
predictor-specific model selection, or an unregistered family to convert a
failed diagnostic into an accepted result.

An alternative author choice is to release production for the eight non-timing
outcomes plus mean timing above 250 lx melEDI while retaining the other four
timing outcomes on hold. That split production route is not recommended because
it would create a second response-family gate inside production.

## Stop state

The task is stopped at `H06-D-G2P-NONL10` pending explicit author disposition.
Stage 3 and Stage 4 remain unauthorized and separate. The reader-facing gate is
`audit/hypotheses/H06_daily/10_non_l10_pilot.html`.
