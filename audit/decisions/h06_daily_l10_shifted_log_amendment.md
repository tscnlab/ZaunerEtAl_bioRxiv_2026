# H06 daily L10 shifted-log amendment

Decision ID: `H06-D-003`  
Gate: `H06-D-G2P-L10-SHIFTLOG`  
Date: 2026-08-12  
Status: approved amendment; representative pilot authorized but compute-queued

## Author amendment

The author explicitly directs H06-daily to move forward with the H01-consistent
one-part shifted-log approach for L10 mean melEDI. This is a new primary
candidate estimand and model route, not a repair or reinterpretation of the
accepted two-part analysis.

The response is

```r
response_value <- log10(l10_mean_meledi_lx + 0.1)
```

Exact zero is retained and maps to `-1`. No zero participant-day is discarded,
and no occurrence or positive-only component is used in the amended primary
test.

For a predictor contrast or increment with coefficient `beta`, `10^beta` is a
multiplicative contrast in the fitted geometric mean of
`L10 mean melEDI + 0.1 lx`. It is not a ratio of unshifted L10, not a ratio of
arithmetic integrals, and not the conditional mean among positive days.
Reader-facing reporting must pair this shifted-scale contrast with
equal-site-adjusted fitted means and 95% confidence intervals back-transformed
as `10^eta - 0.1 lx`, without silently clipping a negative back-transform or
calling the coefficient an exact raw-L10 ratio.

## Historical preservation

H06-D-001 and H06-D-002 remain the complete verified and author-accepted
historical record of the failed two-part route. Its source, HTML, models,
diagnostics, manifests, transition, and closure evidence must remain
byte-for-byte unchanged. Its `NON_ESTIMABLE_COMPONENT_FAILURE` classifications
continue to describe that estimand correctly.

The shifted-log amendment is developed in a separate H06-daily-owned output
tree and report. It may replace the historical missing L10 slot only after its
own pilot, full bounded implementation, diagnostics, multiplicity
reconstruction, and author gate are accepted.

## Exact bounded scientific scope

The amendment is L10-only and covers the three already approved predictors:

1. free day versus work day;
2. Active versus Sedentary day; and
3. per one-hour greater previous-night sleep duration.

The six already authorized scenarios are:

1. primary near eye, all available;
2. primary chest, all available;
3. primary near eye, paired/common;
4. primary chest, paired/common;
5. gap-timing-unaware near eye, all available; and
6. gap-timing-unaware chest, all available.

Near-eye primary and gap-timing-unaware near-eye results supply the declared
inferential-family slots. Chest and paired/common scenarios remain
complementary estimates and sensitivity evidence, not additional significance
screens.

## Model hierarchy

Every reduced, additive, and heterogeneity comparison must use the same frozen,
ordered complete-case frame, sum-to-zero site contrasts, and participant random
intercept. The exact Wilkinson formulas supplied to the model are:

```r
# Reduced
response_value ~ site + (1 | participant_key)

# Candidate primary additive model
response_value ~ site + predictor + (1 | participant_key)

# Predictor-by-site heterogeneity model
response_value ~ site * predictor + (1 | participant_key)
```

For Gaussian likelihood comparisons, reduced versus additive supplies the
association test and additive versus heterogeneity supplies the site-
heterogeneity test. Both comparisons use ML on identical rows. The selected
Gaussian model is refitted with REML for estimates and intervals. The primary
association is interpreted with equal site weight; it is not weighted by site
sample size.

The exact registered random-site/random-slope model remains a labelled
benchmark only:

```r
response_value ~ predictor + (predictor | site) +
  (1 | site:participant_key)
```

It is not promoted when the fixed-site route fails. The Student-t shifted-log
counterpart is a prespecified distributional sensitivity where estimable, not
a significance-selected replacement.

An actual-date, gap-aware AR(1) counterpart is fitted only when the existing
H06-daily residual-lag trigger fires. Missing calendar dates start a new
sequence and are never compressed into artificial adjacency. The counterpart
must satisfy the existing convergence, Hessian, singularity, correlation-
boundary, residual, and effect-stability rules before it can support the
amended route.

## Diagnostics required

H01 adequacy does not transfer. H06-daily must independently assess, on every
exact frame used:

- optimizer convergence, positive-definite Hessian, rank, and singularity;
- shifted-log residual shape, tails, heteroscedasticity, and outliers;
- the exact-zero mass at `-1` and whether the one-part Gaussian working
  distribution remains scientifically adequate despite that mass;
- fitted and interval behavior after `10^eta - 0.1`, with no silent clipping;
- participant and site influence;
- Student-t shifted-log sensitivity, including direction and standardized
  effect shifts; and
- actual-date residual dependence and any triggered AR counterpart.

The earlier H06-daily engineering pilot's concern about L10 zero mass is not
overruled by H01. It must be reassessed under the current METRIC-011 inputs and
explicitly accepted or rejected at this amendment's gate.

## Multiplicity contract

L10 remains metric slot 3 in every named 15-slot family. If and only if the
amended one-part route passes its gates, its reduced-versus-additive and
additive-versus-heterogeneity raw p-values populate that slot in:

- `primary__H06-D-A01` and `primary__H06-D-H01` for work/free day;
- `primary__H06-D-A03` and `primary__H06-D-H03` for activity;
- `primary__H06-D-A11` and `primary__H06-D-H11` for previous-night sleep;
- and the corresponding six `gap_timing_unaware__...` families.

All non-L10 raw p-values and model objects remain frozen. Only adjusted
p-values, ranks, and decisions mathematically dependent on replacing the L10
slot may be reconstructed. A non-estimable amended test remains a named `NA`
slot; it is never dropped to reduce the family denominator below 15.

## Representative pilot authorization

A production-code pilot is scientifically authorized for the primary near-eye
all-available scenario only, covering all three predictors so that both binary
and continuous designs are tested. It may fit the reduced, additive,
heterogeneity, REML estimation, Student-t sensitivity, registered benchmark,
and any trigger-required actual-date AR counterparts needed to assess this
route.

The pilot must:

- consume the current METRIC-011-pinned frame and preserve exact zeros;
- write only to a new H06-daily shifted-log pilot tree;
- calculate no BH decision and replace no historical L10 slot;
- run no full participant/site deletion batch and no remaining daily grid;
- report exact samples, formulas, convergence and diagnostic classifications,
  one-part versus historical two-part estimand differences, wall time, and a
  projected full six-scenario L10 runtime; and
- stop at `H06-D-G2P-L10-SHIFTLOG` for explicit author review before the full
  L10 batch.

An existing one-part object may be reused only if a focused R verifier proves
that it used the current METRIC-011 frame, identical response values, formula,
contrasts, family, fitting method, and package versions. Otherwise the pilot
must refit from the current frame. Reuse is an exact-provenance decision, not a
numerical-similarity shortcut.

## Compute launch gate

At authorization, the H01 four-target production bootstrap is actively
running and H05 is preparing a bounded L10 reseal with additional model fits.
The H06-daily representative pilot is therefore compute-queued and must not
launch concurrently. Static contract and exact-reuse checks may continue.
The coordinator will give a separate compute-clearance message after the
active H01 process has ended and no H05 fit batch is competing.

## Frozen boundaries

The remaining H06-daily 15-metric production grid, H06-daily Stage 3 and Stage
4, the accepted main H06 analysis, and final H06 version selection remain
frozen. No shared preparation, central ledger, shared Quarto configuration,
manuscript, dependency, or other-hypothesis file may be changed by the
H06-daily worker.

## Reopening condition

Reopen this amendment if the offset, response interpretation, predictor set,
six-scenario scope, formula hierarchy, site weighting, random-site role,
Student-t or AR rules, diagnostic gates, multiplicity family, exact current
frame, pilot scope, or frozen preservation boundary changes. Full L10
production requires a later explicit author decision after the representative
pilot.
