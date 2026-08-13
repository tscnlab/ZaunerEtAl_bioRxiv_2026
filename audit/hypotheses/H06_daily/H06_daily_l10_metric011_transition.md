# H06_daily METRIC-011 L10 amendment transition

- Date: 2026-08-12
- Gate: **H06-D-G2P-L10-METRIC011**
- Parent workflow: **H06-D-G2P-AR remains open only through this distinct
  L10 amendment gate**
- Central acceptance: **H06-D-002 / CHG-109, author approved on 2026-08-12**
- Status: **accepted exactly as recommended; gate closed and frozen**
- Remaining daily production grid: **frozen and not authorized**
- Approved pre-sleep no-nugget branch: **unchanged and frozen**

## Controlling amendment

Shared METRIC-011 reclassified exactly eight provenance-proven roundoff
remnants as exact-zero L10 mean melEDI values: three near-eye and five chest
participant-days. An exact zero remains in the zero-occurrence component and
is excluded only from the strictly positive magnitude component. No
participant-day is discarded merely because L10 is zero.

The current controlling inputs are pinned in the amendment input contract,
including:

- the decision at SHA-256
  `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`;
- the independent evidence manifest at
  `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`;
- the metric manifest at
  `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e`;
- the site/context manifest at
  `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518`;
- the base manifest at
  `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`;
- the near-eye participant-day source at
  `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a`;
  and
- the chest participant-day source at
  `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057`.

All 13 direct identities passed. All 12 gap-timing-unaware component frames
were exactly invariant to METRIC-011. They were fitted only to complete the
previously held L10 branch because no accepted production L10 fits existed;
they are not a METRIC-011 scientific repair.

## Completed bounded analysis

The authorized branch comprised three predictors in six scenarios, each with
a zero-occurrence and a strictly positive magnitude component:

1. primary near-eye all available;
2. primary chest all available;
3. primary near-eye paired/common;
4. primary chest paired/common;
5. gap-timing-unaware near-eye all available; and
6. gap-timing-unaware chest all available.

The fixed-site primary component formula was:

```r
response_value ~ site + predictor + (1 | participant_key)
```

Occurrence used binomial logit; positive magnitude used Gaussian identity on
`log10(L10)` with a Student-t identity sensitivity. Exact registered
random-site/random-slope models remained benchmarks only. Actual-date AR(1)
counterparts were evaluated only after the prespecified residual-lag trigger.

The batch ran serially in one R process. The 18 scenario-by-predictor analyses
took 156.67 seconds. The positive-only influence batch completed 440 serial
participant/site deletion refits in 38.76 seconds after a 50-refit pilot. No
occurrence or joint deletion model was fitted after those components were
classified non-estimable.

## Estimability disposition

All primary near-eye ordinary occurrence models show complete or
quasi-complete separation. UCR has no exact-zero L10 participant-day in either
work/free cell, either activity cell, or across the observed previous-night
sleep support. The work/free actual-date occurrence AR counterpart additionally
failed at `rho = -0.999964`.

Therefore all primary and gap near-eye joint association and
site-heterogeneity tests are
`NON_ESTIMABLE_COMPONENT_FAILURE`. Their ordinary raw p-values and their BH
adjusted p-values are `NA`. The L10 metric remains slot 3 in every 15-slot
family; no component p-value or regularized estimate substitutes for the
failed joint slot.

The coordinator-authorized normal-prior fixed-site occurrence fits at prior
standard deviations 1.5, 3, and 6 are diagnostic MAP sensitivities only. They
have no ordinary confidence interval, p-value, BH entry, or significance
decision. The exact registered random-site occurrence model remains a
benchmark and is not promoted.

## Positive component

The primary near-eye Gaussian estimates, conditional on L10 greater than zero,
are:

| Context contrast | Conditional ratio (pointwise 95% CI) | Limitation |
|---|---:|---|
| Free day versus Work day | 0.925 (0.759 to 1.128) | Student-t ratio 1.061; 1.35-SE shift and direction reversal |
| Active versus Sedentary | 0.864 (0.674 to 1.107) | 0.61-SE family shift; 1.04-SE shift after deleting MPI |
| Per +1 h previous-night sleep | 0.775 (0.722 to 0.832) | Student-t fit failed its numerical gate; interval withheld |

These ratios are conditional geometric-mean ratios among positive days. They
do not represent the overall L10 association and support no standalone
confirmatory or directional claim. All displayed intervals are pointwise; no
simultaneous interval was constructed.

## Preservation

All 194 fitted-model subobjects were object-identical before and after the
no-refit coordinator disposition update. All 294 pre-existing H06_daily
scientific/report files in the protected baseline passed byte-for-byte
preservation after production. This includes the approved pre-sleep no-nugget
frame, standalone reference, model, report, and manifests. No non-L10 result
was recomputed or revised.

## Author acceptance and gate closure

The author explicitly accepted **H06-D-G2P-L10-METRIC011** exactly as
recommended on 2026-08-12. The controlling central acceptance is
`audit/decisions/h06_daily_metric011_l10_acceptance.md`, SHA-256
`5c1e7204e9bdd7f76ffbb0f960f2505ac5a4b23a4c94018d0dff3a33fcf4d9ea`.
The preceding independent verification remains H06-D-001, SHA-256
`e6816a31b5253675c93ab7f3cacac7f2d415d4fd7159762475fa65bf2a142c28`.

The accepted disposition is therefore frozen:

1. all 12 primary and gap-timing-unaware near-eye joint L10 association and
   site-heterogeneity tests remain `NON_ESTIMABLE_COMPONENT_FAILURE`; L10
   remains slot 3 in each 15-metric family, with raw and BH-adjusted p-values
   missing;
2. positive-magnitude estimates remain conditional descriptive diagnostics
   among participant-days with L10 greater than zero and do not replace the
   joint estimand;
3. normal-prior fixed-site occurrence fits remain diagnostic MAP
   sensitivities without ordinary confidence intervals, p-values,
   multiplicity entries, or significance decisions; and
4. the joint L10 slots remain missing unless a later explicit scientific
   amendment changes the primary occurrence hierarchy.

No hierarchy substitution is accepted. This includes promoting the registered
random-site benchmark, deleting UCR, pooling sites, changing the fixed-site
hierarchy, using the positive-only component as the joint result, or promoting
the regularized fit. A one-part Gaussian model of
`log10(L10 + 0.1 lx)` can accommodate zeros and avoid the separated occurrence
component, but it is a different unconditional shifted-log estimand; it is not
substituted by this acceptance and would require a new explicit amendment.

The amendment report at
`audit/hypotheses/H06_daily/08_l10_metric011_amendment.qmd` and its
self-contained HTML remain byte-identical to the verified author-gate record.
This closure performed no model fit, refit, prediction, resampling, or
scientific-result change.

The remaining daily production grid, Stage 3/4, main H06, and final H06 version
selection remain frozen and unauthorized. The worker stops after resealing the
bounded closure identities.
