# H06_daily bounded timing-repair pilot authorization

Decision ID: `H06-D-009`  
Change ID: `CHG-119`  
Date: 2026-08-12  
Status: author approved; bounded pilot compute cleared

## Author decision

The author accepts `H06-D-G2P-NONL10` and authorizes the recommended bounded
repair pilot for the four timing outcomes that did not have an acceptable
model route in the first pilot:

- midpoint of the brightest 10 hours (`m10_midpoint`);
- midpoint of the darkest 10 hours (`l10_midpoint`);
- first timing above 250 lx melEDI (`first_timing_above_250`); and
- last timing above 250 lx melEDI (`last_timing_above_250`).

The pilot covers each outcome with the three already approved predictors:
work versus free day, Active versus Sedentary day, and previous-night sleep
duration. It is restricted to the primary near-eye, all-available
participant-day sample. The next stop gate is
`H06-D-G2P-TIMING-REPAIR`.

## Scientific question and fixed estimands

The repair does not redefine any outcome or predictor. It retains one row per
eligible participant-day, the accepted support rules, the existing fixed-site
adjustment, and the existing predictor contrasts. The response encodings are
also fixed:

- M10 midpoint, first timing above 250 lx melEDI, and last timing above 250 lx
  melEDI remain in their already-audited continuous local-clock-hour
  encodings;
- L10 midpoint retains the prespecified after-16:00 midnight unwrapping, so
  post-midnight times are represented on the same continuous night-centred
  scale; and
- no cutpoint search, outcome-specific re-expression, circular-mean
  substitution, data deletion, or predictor-specific method selection is
  permitted.

The first pilot's source-support audit found no midnight-cut or unsupported
clock problem in these 12 frames. This repair therefore targets uncertainty
under repeated participant-days and sensitivity to residual tails; it does
not alter the scientific timing estimands.

## Exact authorized frames

The complete 26-row input contract in
`artifacts/12_manifests/H06_daily/H06_daily_non_l10_pilot_input_manifest.csv`
must first verify byte-for-byte (file SHA-256
`38e5b87564b7b234de85b5af5fa4e30edc389c4f83b87f6a9d7ddf119d225aec`).
The pilot must then use exactly these sealed frame objects from
`artifacts/06_model_data/H06_daily/H06_daily_non_l10_pilot_timing_frames.rds`
(file SHA-256
`89a6db7ce1de5d08ebf854d44ac292a9c4c1143c7d2f68aa850eb114e012a751`):

| Outcome | Predictor | Participants | Participant-days | Sites | Frame-object SHA-256 |
|---|---|---:|---:|---:|---|
| M10 midpoint | Work/free day | 141 | 784 | 9 | `2ef675e201a4999eb164c9771f023118e2e66866b539a80727be698c9e066e1b` |
| M10 midpoint | Activity status | 137 | 734 | 9 | `1d4796d1c9fe8cac1a900e8c18a9e05da11142861a4d0e4d69c51b53eedf236d` |
| M10 midpoint | Previous-night sleep | 141 | 784 | 9 | `98e9d399d49cf3056d6ef4133346bae4dacfd34f57487685cfb60402633bf074` |
| L10 midpoint | Work/free day | 141 | 784 | 9 | `74eaa3b8d040a985afb150ff4944de22ebf15a8180d9406578801e27a8e5cc08` |
| L10 midpoint | Activity status | 137 | 734 | 9 | `6668f2f72c5f01aad76982ce697dea0292728c445bc8e377be29386a0ee2b0e1` |
| L10 midpoint | Previous-night sleep | 141 | 784 | 9 | `04b9b71e0a6d8f01e0641e083eee5b2efb177e407d6df5f78e561ce7386e3e50` |
| First timing above 250 lx melEDI | Work/free day | 140 | 701 | 9 | `30c172f46a1814d05b73d851d82496b16c530b30b68334cb132f0916147289a0` |
| First timing above 250 lx melEDI | Activity status | 136 | 658 | 9 | `332eb6aa7ba4c7769308ad9e06467ea35ceda4780dca88b50933a87a3fb79862` |
| First timing above 250 lx melEDI | Previous-night sleep | 140 | 701 | 9 | `af3f47b187787fd562901b87464291b25b7f3864d10bfabeea516090df5fe6a9` |
| Last timing above 250 lx melEDI | Work/free day | 141 | 661 | 9 | `8eb2552ad0c29a5c1aa028b92db464ba7cab20eef0893e079b7ce84b537ecb00` |
| Last timing above 250 lx melEDI | Activity status | 137 | 626 | 9 | `f5608dc0e83fbcb54747e5bf2dddda785ee7d2ae5125497918c49fc55462d7ca` |
| Last timing above 250 lx melEDI | Previous-night sleep | 141 | 661 | 9 | `f9a92b7deabdbbc9cc7896925ee69ecce387bc14ceb9504b6204eb51757cb696` |

The frame inventory itself is pinned at SHA-256
`639eaa04595f5fc83ef9633da4b66bd14123480a1322c43e5e6ac4d80eb40bce`.

## Uniform candidate inferential route

The only candidate inferential repair is a marginal fixed-site linear model
with participant-cluster HC3 sandwich covariance. For every one of the 12
cells, use the same three mean-model formulas:

```r
response_value ~ site
response_value ~ site + predictor
response_value ~ site * predictor
```

Requirements:

1. Fit the formulas with `stats::lm()` to the unchanged complete frame, using
   the stored sum-to-zero site contrast and stored predictor coding.
2. Calculate covariance with
   `sandwich::vcovCL(model, cluster = ~ participant_key, type = "HC3",
   cadjust = TRUE, fix = FALSE)`.
3. Treat participant as the sole clustering unit. This permits arbitrary
   heteroscedasticity and correlation among a participant's retained days;
   it does not assert that those days are independent.
4. Test the predictor term in the additive model and the complete
   predictor-by-site interaction block in the interaction model with robust
   Wald statistics. For a block of rank `q`, use `F = W / q` with numerator
   degrees of freedom `q` and denominator degrees of freedom equal to the
   number of participant clusters minus one. Use the same cluster-minus-one
   t reference for 95% confidence intervals.
5. Keep raw pilot p-values at full precision in an audit artifact, label every
   one `PILOT_RAW_ONLY_NO_BH_UPDATE`, and leave every adjusted-p field missing.
   No pilot p-value enters a 15-slot family.

This changes the uncertainty estimator, not the observational participant-day
question. The fixed mean model gives each retained participant-day one row;
the clustered covariance protects inference from repeated days within the
same participant. It is not a causal model.

## Required diagnostic sensitivities

These fits are diagnostic checks only and cannot replace the candidate route
or contribute a p-value:

1. **Tail-robust sensitivity.** Fit the same fixed mean structures with
   `glmmTMB::t_family(link = "identity")`. Report convergence, Hessian status,
   estimated degrees of freedom, and the predictor and interaction effect
   shifts in units of the HC3 standard error. Do not use its p-values for
   selection or multiplicity.
2. **Structured temporal sensitivity.** Fit the already specified actual-date,
   day/gap-bounded AR counterpart without an independent residual nugget
   (`dispformula = ~0`) using the same outcome encoding, frame, and fixed mean
   structure. Report convergence, singularity or covariance-rank status,
   estimated AR parameter, pooled and maximum site residual lag, and the
   effect shift. It is not an alternative primary test and supplies no
   multiplicity value.

The pilot must apply both sensitivities uniformly to all 12 cells. It may not
choose a different family, temporal structure, or transform for a particular
outcome or predictor because that choice gives a smaller p-value.

## Pilot acceptance and reporting rules

For every cell, record:

- exact participants, participant-days, sites, and predictor category cells;
- formula/model-matrix rank and number of participant clusters;
- finite coefficients and covariance entries;
- whether the unmodified HC3 covariance is symmetric and positive
  semidefinite, without using `fix = TRUE` to conceal a failure;
- cluster leverage or other identifiable high-influence warnings;
- the HC3 estimate, 95% confidence interval, raw pilot p-value, and site
  interaction test;
- the existing Gaussian/AR failure that motivated the repair;
- Student-t and no-nugget AR diagnostic results; and
- effect-stability classification: less than one HC3 standard error is
  stable, one to less than two is a substantial limitation, and at least two
  or a direction reversal is unstable.

The prior residual-lag thresholds remain descriptive diagnostics but are not
an independence requirement for HC3 inference: the candidate covariance is
explicitly designed to remain valid with within-participant dependence. This
distinction must be stated plainly in the gate report.

An outcome may be recommended for later production only if all three
predictor cells use the same fixed candidate route and satisfy the source,
design-rank, covariance, and numerical gates. No predictor-specific release
is permitted. Any sensitivity divergence must be carried to the author gate,
not resolved by selecting the more favorable fit.

## Protected boundary

The pilot must write only new H06_daily-owned code, artifacts, tests, and a
separate gate report. It must verify the existing preservation record
`artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_pilot_preservation_final.csv`
(SHA-256
`c716a55da1d6f0c3add00f8f8e6cb42f425431e024108b14ac7b369a02c94c99`)
and keep all earlier H06_daily outputs byte-identical.

Specifically frozen are:

- the accepted mean timing above 250 lx melEDI cells;
- all eight non-timing outcomes;
- both accepted L10 records and L10 slot 3;
- MDER and slot 15;
- the accepted temporal GAMM and pre-sleep no-nugget records;
- all main hourly H06 files and results;
- every BH family and adjusted p-value;
- all deletion batches, Stage 3, Stage 4, and shared files.

No participant-day may be deleted as a repair. No deletion refit, bootstrap,
simulation, full grid, chest, paired/common, gap-timing-unaware, random-site,
reader-report, or provenance-companion work is authorized.

## Compute clearance and stop gate

The coordinator inspected current project tasks immediately before release.
No other scientific model fitting or heavy resampling is active; the only
other active project task is conducting bounded report-harmonization review.
The H06_daily pilot may therefore run serially now.

No separate runtime pilot is required: the scope is exactly 12 primary cells,
no deletion battery, and no resampling. Record elapsed time. If the bounded
execution unexpectedly projects beyond two minutes before launch, or if any
additional model family or compute is proposed, stop and request a new gate.

After the static pin check and bounded fits, stop at
`H06-D-G2P-TIMING-REPAIR` for explicit author review. No pilot result is an
accepted association, no BH value changes, and no production or reporting
stage follows without a new author decision.

## Software identity

The contract was checked in R 4.6.1 with the synchronized project library:
`sandwich` 3.1.1, `lmtest` 0.9-40, and `glmmTMB` 1.1.14. No package may be
installed or updated for this pilot.

## Reopening condition

Reopen this decision if an input or frame identity changes; an outcome,
cutpoint, predictor, contrast, formula, clustering unit, covariance type,
diagnostic sensitivity, multiplicity rule, protected file, compute scope, or
stop gate changes; or if the author requests a different repair route.
