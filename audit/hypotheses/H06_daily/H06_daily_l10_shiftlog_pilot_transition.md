# H06_daily L10 shifted-log pilot transition

- Date: 2026-08-12
- Decision: **H06-D-003 / CHG-111**
- Gate: **H06-D-G2P-L10-SHIFTLOG**
- Scope: **primary near-eye all-available pilot, three predictors only**
- Status: **pilot complete; not acceptable under the current temporal rule;
  awaiting explicit author disposition**
- Remaining six-scenario L10 batch: **frozen and not authorized**
- Remaining daily production grid, Stage 3/4, main H06, and final version
  selection: **frozen and not authorized**

## Estimand and historical boundary

The amended response is

```r
response_value <- log10(l10_mean_meledi_lx + 0.1)
```

Exact zeros remain and map to -1. A coefficient exponentiated as `10^beta`
is a ratio of fitted geometric means of `L10 mean melEDI + 0.1 lx`; it is not
an unshifted raw-L10 ratio and not a positive-only mean. Reader-scale fitted
values use the unclipped inverse transform `10^eta - 0.1 lx`.

The H06-D-001/H06-D-002 two-part analysis, its separation failure, report,
models, diagnostics, manifests, transition, and closure remain byte-for-byte
historical records. The shifted-log pilot does not reinterpret or overwrite
them.

## Exact pilot scope and reuse

The pilot covered Work/Free day, Sedentary/Active day, and per one-hour greater
previous-night sleep duration in the primary near-eye all-available scenario.
Exact samples were:

| Predictor | Participant-days | Participants | Sites | Exact zeros |
|---|---:|---:|---:|---:|
| Work/Free day | 784 | 141 | 9 | 107 |
| Activity | 734 | 137 | 9 | 92 |
| Previous-night sleep | 784 | 141 | 9 | 107 |

The three Gaussian additive REML objects were reused without relabel refitting
only after exact verification of the current frame, response, formula, model
matrix, contrasts, family, method, optimizer, R/package identities,
convergence, and serialized object identity. Reduced/additive ML,
heterogeneity ML, Student-t REML, registered benchmark, independent-engine
calibration, and triggered actual-date AR counterparts were the only new
pilot fits. No BH update, deletion batch, full scenario batch, or non-L10 fit
was run.

## Pilot findings

The one-part route removes the separated occurrence component. All three
fixed-site hierarchies are estimable, converge, and are non-singular. Gaussian
candidate shifted-scale ratios with pointwise 95% intervals are:

| Contrast | Ratio for fitted geometric mean of L10 + 0.1 lx |
|---|---:|
| Free day versus Work day | 0.988 (0.918 to 1.065) |
| Active versus Sedentary | 0.929 (0.845 to 1.021) |
| +1 h previous-night sleep | 0.899 (0.876 to 0.923) |

These values remain pilot diagnostics. The six model-comparison p-values are
raw only, with `PILOT_RAW_ONLY_NO_BH_UPDATE`; no adjusted decision exists.

All three Gaussian fits are acceptable only with a residual limitation.
Exact zeros comprise 12.5%--13.6% of the frames and remain an explicit
scientific limitation; H01 adequacy was not transferred. Activity and sleep
have major Student-t sensitivity shifts of 1.28 and 1.23 Gaussian standard
errors. The sleep fit has 2.30% slightly negative individual inverse-
transformed fitted points, minimum -0.018 lx, with no silent clipping.

All three temporal screens triggered because a site-level absolute lag
exceeded 0.30. MPI supplied the maximum with 115--119 true adjacent pairs from
26 participants. The actual-date AR fits converged with positive-definite
Hessians, full-rank structured covariance, nonboundary rho 0.576--0.609, and
effect shifts below 0.31 Gaussian standard errors. They nevertheless fail the
complete temporal gate: post-AR pooled residual lag is -0.273 to -0.285 and
maximum site absolute lag is 0.479--0.500.

The final per-predictor disposition is therefore
`NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE`, and the recommendation is
`DO_NOT_RELEASE_FULL_L10_SHIFTED_LOG_BATCH`.

## Runtime and reproducibility

The final successful pilot took 1.80 seconds wall time; new fit time summed to
0.90 seconds. A conservative projection for the later 18
predictor-by-scenario analyses and 440 influence refits is 47.2 seconds. The
barrier is scientific authorization rather than compute load.

Two preliminary compute-cleared executions aborted before final scientific
output writing because of bounded implementation errors. A later preliminary
successful run exposed an inappropriate determinant-based singularity check
for the structured AR block. The final run retained the identical data,
formulas, and authorized model scope and used random-effect SDs plus scaled
covariance eigenvalues, with the AR-correlation boundary checked separately.

All 118 H06-D-001/H06-D-002 historical manifest entries remain byte-for-byte
identical. Scientific computation used R 4.6.1 and the synchronized project
library in one serial R process.

## Author decision required

The recommended decision is to accept the pilot verdict and stop the
shifted-log route under the current temporal acceptance rule.

Continuing for H01 consistency would require a new explicit author amendment
to the temporal estimand or acceptance rule and an explicit treatment of the
remaining post-AR dependence. This gate does not authorize silently ignoring
that failure. Only after such an amendment could the bounded later L10-only
scope be considered: three predictors across primary near-eye/chest
all-available, paired/common near-eye/chest, and gap-timing-unaware near-eye/
chest, with Student-t, triggered AR, influence, exact samples, and only the
dependent 15-slot BH fields.

Until that decision is explicit, stop at H06-D-G2P-L10-SHIFTLOG.
