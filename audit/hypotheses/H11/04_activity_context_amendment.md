# H11 activity-context amendment

Status: **author approved for implementation**  
Decision date: 2026-08-03

## Reason for reopening Stage 2

The accepted participant-cluster-robust global test addresses the complete
Female-minus-Male 24-hour curve. Its support is not invalidated when the
secondary two-component decomposition cannot independently identify a level
or cyclic-shape contribution after its two-test Benjamini-Hochberg adjustment.
Reader-facing reporting must therefore lead with the supported global result
and describe the decomposition only as an unsuccessful attempt to separate
that joint result into two correlated components.

The author additionally requested the V0 exploratory activity context in the
model to assess whether adjustment attenuates the apparent sex association.
This is an exploratory contextual sensitivity analysis, not a causal mediation
analysis and not a replacement for the accepted primary test.

## Frozen activity-data contract

The source is
`artifacts/06_model_data/normalized_inputs/lightexposurediary.rds`. Only diary
intervals that passed the general analysis-eligibility rule and had exactly
one of the eight declared activity flags selected are eligible. The historical
long pivot is prohibited because multiple selected flags duplicated an hourly
outcome. Exactly-one `act_other` intervals are excluded because the normalized
input does not contain an outcome-blind row-level recoding for their free-text
content.

The remaining flags use the recognizable V0 five-level mapping:

| Source flag | Activity context |
|---|---|
| `act_home` | Home (reference) |
| `act_sleep` | Sleep |
| `act_road_vehicle` | Public transport/car |
| `act_working_indoor` | Indoor work/home office |
| `act_road_open`, `act_working_outdoor`, `act_free_outdoor` | Outdoors/active travel |

Each eligible one-hour diary interval is assigned to every retained 30-minute
exposure observation wholly contained within that interval. The join must be
many exposure observations to one unique diary interval and must neither
duplicate nor reorder exposure rows. Rows without an eligible mapped interval
are excluded. After filtering, the inherited true-time `AR.start` boundary is
preserved and an additional boundary is inserted after every newly introduced
30-minute gap.

## Common-sample estimand and models

For each placement separately, the comparison uses one exact activity-complete
sample for both models. Near eye remains primary and chest remains
complementary. No gap-timing sensitivity model is added because crossing a
data-preparation sensitivity with this contextual sensitivity would change two
axes at once.

The restricted unadjusted model is the accepted H11 temporal structure:

```r
response ~ sex +
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, by = sex_smooth, bs = "cc", k = 12) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

The activity-adjusted model adds an activity-context level and a cyclic,
shared-smoothing activity-specific temporal deviation while leaving every
accepted H02/H11 term unchanged:

```r
response ~ sex + activity +
  s(time_hour, bs = "cc", k = 12) +
  s(time_hour, by = sex_smooth, bs = "cc", k = 12) +
  s(time_hour, by = activity_smooth, bs = "cc", k = 12, id = 2) +
  s(time_hour, site, bs = "sz", k = 12) +
  s(time_hour, participant, bs = "fs", k = 10) +
  s(participant_day, bs = "re")
```

`activity` is a treatment-coded factor with Home as reference.
`activity_smooth` is the corresponding ordered factor, so Home is the
reference curve. One boundary-aware rho is estimated from the preliminary
activity-adjusted model and then held fixed for both common-sample final fits.
Both use fREML, `discrete = TRUE`, the accepted cyclic knots at 0 and 24 hours,
the accepted participant/day hierarchy, and the accepted participant-cluster
robust covariance/test implementation.

The exploratory estimand is the complete adjusted Female-minus-Male 24-hour
curve, conditional on the same activity context. Because activity enters
additively and has no sex-by-activity interaction, this contrast is invariant
to which valid activity level is used to construct the prediction grid. The
primary comparison is attenuation between the restricted-unadjusted and
activity-adjusted sex curves and their global robust tests on the identical
sample. Crossing a conventional 0.050 threshold is not, by itself, evidence
that activity explains or mediates the association.

## Inference, uncertainty, and display

- Report raw exploratory global p-values with full precision in scientific
  artifacts and the shared three-decimal display convention in reports.
- Treat near-eye and chest as separate one-test placement-specific families;
  the exploratory adjustment cannot overturn the accepted primary conclusion.
- Use participant-cluster-robust pointwise 95% confidence intervals for curves.
- Report exact participants, participant-days, 30-minute observations, nominal
  hours, sites, and activity-category support.
- Diagnose convergence/warnings, cyclic closure, boundary-aware residual ACF,
  basis dimensions, site sum-to-zero constraint, residual behavior,
  concurvity, robust covariance, and delete-one-participant influence.
- Reader-facing melEDI axes use
  `LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`, which is linear
  from 0 to 1 lx and logarithmic above 1 lx. Multiplicative ratio panels retain
  their natural logarithmic ratio scale around the null ratio of 1.
