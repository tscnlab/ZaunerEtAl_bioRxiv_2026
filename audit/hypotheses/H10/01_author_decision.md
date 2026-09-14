# H10 Stage 1 author decision

Date: 2026-08-07  
Gate: Stage 1 to Stage 2  
Status: **approved, including amended `H10-G3`; shared preparation prerequisite resolved**

## Decision received in the H10 task

The author explicitly approved the H10 Stage 1 gates after reviewing
`audit/hypotheses/H10/01_audit_and_plan.html`.

This approves `H10-G1` through `H10-G13` as proposed:

1. four separate complete 17-member Benjamini–Hochberg families for age main,
   biological-sex main, age-by-site, and biological-sex-by-site tests, with
   separate analogous complementary chest families;
2. common site-adjusted age and biological-sex associations as the primary
   estimands, with predictor-by-site interactions treated as heterogeneity;
3. the approved shared 17-metric response-family and transformation package
   as H10's starting package, without inheriting another hypothesis's fitted
   result;
4. `(1 | site:Id)` for participant-day outcomes and ordinary site-adjusted
   models for participant-level IS and IV, with temporal dependence retained
   as a diagnostic gate;
5. `age_decade = age / 10`, biological sex coded Male then Female, the
   Female-minus-Male contrast, explicit site contrasts, and no substitution
   or inference of gender;
6. primary near-eye and complementary chest analyses without pooling or an
   equivalence claim;
7. the identical-implementation gap-timing-unaware and exact common-key data
   sensitivities;
8. the proposed longest-period, L10, MDER, and preregistered-exclusion
   sensitivities, while keeping response-family alternatives behind a new
   gate;
9. explicit acceptable / acceptable with specified limitations / not
   acceptable diagnostic classifications;
10. model-based 95% confidence intervals and practical-scale
    back-transformations, with no bootstrap unless diagnostics require a
    separately gated pilot;
11. non-selective site-specific heterogeneity summaries after an omnibus
    interaction, without undeclared site-specific significance tests;
12. paired/common IS and IV remaining unavailable unless an approved upstream
    process recomputes them from identical paired days; and
13. no H10 fitting until the coordinator reconciles or explicitly accepts the
    stale/version-specific Preparation 04/06 input record.

## Age scaling clarification

Before approval, the author asked why `age_decade` is used. It is retained as
approved because it is only `age / 10`: it changes the reported unit from one
year to ten years without changing fitted values, likelihoods, model
comparisons, p-values, or scientific conclusions. Per-year effects will also
be derived from the same estimate and interval.

## Remaining prerequisite

The coordinator closed the shared preparation gate through
`PREP06-BASE-002`, authorizing H10 Stage 2 against the pinned current 816/902
base objects while carrying `PREP-003` / `FIND-044` as a provenance
qualification.

After that resolution and before any H10 fit, the worker found that the Stage
1 response table had reconstructed one row from the superseded H01 prefit
package. The final shared package selects Gaussian identity for
`duration_below_10_pre_sleep`, whereas the reviewed H10 table printed Tweedie
with a log link. The exact amendment request is recorded in
`audit/hypotheses/H10/01_response_contract_amendment.md`. Because this changes
the engine, effect scale, interval, and model-comparison likelihood, it is not
covered by the earlier approval of response-family alternatives remaining
behind a new gate.

The author then explicitly approved amended `H10-G3` on 2026-08-07 by
directing the worker to update the contract and use Gaussian. The final H10
starting package therefore uses untransformed pre-sleep TBT10 hours in a
Gaussian identity mixed model; the other 16 response specifications remain
unchanged.

No H10 model, prediction, simulation, diagnostic model, sensitivity model, or
bootstrap had been run when this approval was recorded.
