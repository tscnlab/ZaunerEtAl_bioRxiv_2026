# H06_daily gap clock-hour repair transition

- Date: 2026-08-12
- Task-local authorization: `TASK_LOCAL_AUTHOR_APPROVAL_2026-08-12`
- Parent diagnostic amendment: `H06-D-014`
- Accepted Stage 2 decision: `H06-D-015` / `CHG-133`
- Current author gate: `H06-D-G3`
- Status: **Stage 2 accepted; complementary Stage 3 authorized**

## Author acceptance and Stage 3 transition

The author replied `approve - continue` at
`H06-D-G2B-GAP-CLOCK-REPAIR`. The controlling acceptance is
`audit/decisions/h06_daily_stage2_acceptance_stage3_transition.md`
(SHA-256
`26e3cf5302db74156a2ad929a80a1352eac6967ccf0e0e1adb5cdcfa71b9954e`).
This accepts all five dispositions requested below and closes the Stage 2
repair gate.

Under `H06-007`, the next bounded deliverable is the compact standalone
reader-facing report at `notebooks/hypotheses/H06_daily.qmd`. The daily-metric
analysis remains complementary to the completed main hourly H06 analysis.
Only stored accepted outputs and display-only calculations may be used. The
task must stop at `H06-D-G3` for explicit author review; Stage 4, website
integration, shared configuration, main-H06 changes, manuscript edits,
scientific recomputation, commit, and push remain unauthorized.

## Completed bounded repair

The repair normalized only the five gap-timing-unaware clock outcomes in the
H06_daily task-owned frame builder. The shared gap source stores these values
in clock hours; the frozen H06_daily response adapter expects minutes and then
divides by 60. The task-owned normalizer therefore multiplies only those gap
values by 60 immediately before the frozen adapter. The modeled response is
the source clock-hour value after exactly one net conversion.

Exact affected scope:

- metric slots 9–13: M10 midpoint, L10 midpoint, mean timing above 250 lx
  melEDI, first timing above 250 lx melEDI, and last timing above 250 lx
  melEDI;
- two placements, three sample roles, and three predictors;
- 90 fitted cells, 30 primary-gap raw tests, and six gap 15-slot BH families.

Exact protected scope:

- 378 unaffected non-L10 cells remained frame-identical;
- all six primary BH families remained unchanged;
- L10 mean slot 3 remains named NA;
- MDER slot 15 models, estimates, intervals, raw p-values, support, and
  scientific result remain frozen; only dependent gap-family BH fields were
  allowed to update;
- 1,011 protected historical identities and all 997 H06-D-G2A output
  identities were verified; and
- no shared preparation, other hypothesis, main H06, manuscript, website,
  central ledger, commit, or push was touched.

## Scientific and diagnostic disposition

All 90 repaired cells pass the construct, support, fit, rank/covariance, and
estimability hard gates. Direct visual review of every repaired
residual-versus-fitted and normal Q-Q display found 90
`REVIEW_LIMITATION` verdicts and zero `FAIL_GROSS` verdicts. The complete
468-cell non-L10 grid is therefore `WARN_REVIEW` / acceptable with limitations,
with zero hard failures.

AR, response-family, participant/site deletion, and exact-period evidence
remains row-linked and mandatory but nonblocking under H06-D-014. In the
repaired cells:

- the HC3 additive Student-t comparison was stable in 70/72 and a substantial
  limitation in 2/72;
- the HC3 no-nugget AR additive comparison was stable in 42/72, substantially
  shifted in 4/72, unstable in 5/72, and numerically unresolved in 21/72;
- the mixed-model AR counterpart was not triggered in 11/18, with three
  numerical failures, one singular fit, and three unresolved post-AR residual
  dependence cases among the remainder; and
- deletion influence was stable in 67/90, a substantial limitation in 19/90,
  and unstable in 4/90, with zero failed deletion refits.

These findings must remain explicit in result summaries. None substitutes a
p-value or changes the accepted primary route.

## Repaired near-eye gap timing pattern

Within the five repaired near-eye all-available timing outcomes:

- all five work/free-day association slots retained BH support;
- all five previous-night sleep-duration association slots retained BH
  support;
- none of the five daily activity-status association slots retained BH
  support; and
- none of the 15 repaired timing predictor-by-site tests retained BH support.

The activity contrast for last timing above 250 lx melEDI had raw p = 0.041
but BH q = 0.089 and therefore does not support a multiplicity-adjusted claim.
All claims remain observational and the gap branch remains a sensitivity, not
a replacement for the primary daily or hourly H06 estimand.

## H06-D-G2B author decisions requested

Please decide whether to:

1. accept the task-owned unit normalization and the exact 90-cell repair;
2. accept the H01-aligned post-repair diagnostic disposition of zero hard
   failures and 90 visually reviewed limitations;
3. accept the restored six gap 15-slot BH families, including the frozen L10
   and MDER boundaries;
4. retain the AR, response-family, influence, and HC3 interaction limitations
   in all downstream summaries; and
5. close this Stage 2 repair gate.

These five decisions were accepted by the author under `H06-D-015`. Stage 3
is now authorized only within the bounded scope recorded above. Stage 4
remains separately gated and unauthorized.
