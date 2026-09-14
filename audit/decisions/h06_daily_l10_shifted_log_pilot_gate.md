# H06 daily L10 shifted-log pilot author gate

Decision ID: `H06-D-004`  
Date: 2026-08-12  
Status: verified; awaiting explicit author decision

## Recommended decision

Accept the bounded `H06-D-003` pilot evidence and **do not release the full
H06-daily shifted-log L10 batch under the current temporal acceptance rule**.
The one-part response solves the two-part separation problem, but all three
triggered actual-date AR counterparts fail the prespecified post-AR residual-
dependence gate. This decision gate authorizes no production analysis, BH
update, deletion batch, remaining daily grid, Stage 3 or Stage 4 work, main-H06
change, or final H06 version selection.

Continuing for consistency with H01 would require a new, explicit author
amendment that states how the remaining post-AR dependence is to be handled.
The current gate does not permit silently weakening or ignoring that rule.

## Candidate estimand and pilot scope

The candidate response was

```r
response_value <- log10(l10_mean_meledi_lx + 0.1)
```

Exact zeros map to -1. Exponentiated coefficients are ratios of fitted
geometric means of `L10 mean melEDI + 0.1 lx`; they are neither unshifted raw-
L10 ratios nor positive-only means. Individual reader-scale fitted values used
the unclipped inverse transform `10^eta - 0.1 lx`.

The representative pilot covered only the primary near-eye, all-available
scenario for the three approved predictors:

| Predictor | Participant-days | Participants | Sites | Exact zeros |
|---|---:|---:|---:|---:|
| Work/Free day | 784 | 141 | 9 | 107 |
| Activity | 734 | 137 | 9 | 92 |
| Previous-night sleep | 784 | 141 | 9 | 107 |

The three additive Gaussian REML objects were reused only after exact current-
frame, response, formula, model-matrix, contrast, family, optimizer,
environment, convergence, and serialized-object verification. All other
pilot comparison, sensitivity, benchmark, calibration, and triggered AR fits
were bounded new pilot computations.

## Pilot evidence

All three fixed-site hierarchies are estimable, converged, and non-singular.
The candidate Gaussian shifted-scale ratios with pointwise 95% intervals are:

| Contrast | Ratio for fitted geometric mean of L10 + 0.1 lx |
|---|---:|
| Free day versus Work day | 0.988 (0.918 to 1.065) |
| Active versus Sedentary | 0.929 (0.845 to 1.021) |
| +1 h previous-night sleep | 0.899 (0.876 to 0.923) |

The six association or site-heterogeneity likelihood-ratio p-values remain
`PILOT_RAW_ONLY_NO_BH_UPDATE`; every adjusted-p and adjusted-decision field is
missing. No 15-slot family changed.

The Gaussian residual distributions are acceptable only with limitations.
Exact zeros comprise 12.5%--13.6% of the model frames, so the H06-specific
zero-mass question remains open and no H01 adequacy conclusion transfers.
Student-t sensitivity shifts are 0.58, 1.28, and 1.23 Gaussian standard
errors for Work/Free day, activity, and sleep, respectively; activity and
sleep therefore carry a major response-family limitation. For the sleep fit,
2.30% of individual inverse-transformed fitted values are slightly negative,
with a minimum of approximately -0.018 lx; none was silently clipped.

All three actual-date AR fits converge with positive-definite Hessians,
non-singular structured covariance, minimum scaled covariance eigenvalues of
0.083--0.097, nonboundary rho of 0.576--0.609, and effect shifts below 0.31
Gaussian standard errors. Nevertheless, pooled post-AR residual lag-1 remains
-0.273 to -0.285 and maximum site absolute lag-1 remains 0.479--0.500. Each
temporal disposition is therefore
`NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE`, making the overall pilot
disposition `NOT_ACCEPTABLE` under the current rule.

## Runtime and preservation

The successful pilot took 1.797 seconds; the conservative full L10-only
projection is 47.204 seconds. Compute time is not the barrier.

All 118 entries from the accepted `H06-D-001`/`H06-D-002` two-part record
remain byte-identical. The accepted two-part failure report, occurrence and
positive-only models, MAP diagnostics, manifests, transition, handoff, and
pre-sleep no-nugget object remain historical records and were not rewritten.
No full shifted-log batch, deletion batch, BH update, remaining daily grid,
shared preparation, main H06, Stage 3, or Stage 4 computation ran.

## Independent verification

Fresh R 4.6.1 verification independently confirmed:

- 14/14 controlling static input pins and all 118 historical identities;
- exact source reconstruction and exact reuse eligibility for all three
  additive Gaussian REML objects;
- the three samples, zero counts, estimates, intervals, family-sensitivity
  shifts, inverse-transform bounds, temporal diagnostics, and runtime;
- six raw-only tests with no BH update;
- all input, code, output, software, and report manifest identities; and
- passing static and pilot focused tests, with all eight shifted-log R files
  parsing successfully.

Accepted identities:

| Artifact | SHA-256 |
|---|---|
| Pilot QMD | `7cf38c446a6bb769abcfe6ce07a70a1df153145ef8cdbe6cc37c0bec65d54480` |
| Pilot HTML | `15655a82cf165b6fa927197519a50c552e85e2aa8d7048ab119509836c9c4581` |
| Transition | `0941cfb61c811ab8b850ecb1fb9cb1569812d00830c4064e597b79f3fa7a3350` |
| Model bundle | `4631d958521918a5ba9f16743322a1b2bb56dbdb9d8b6e4315c07c45c2b2799d` |
| Input manifest | `5e4159f107eda56da94277208f4c17e28dc5c3846c6c81dfacfc5537569a398f` |
| Code manifest | `973695956f67aecbd2b90b89d40b96e864bbc4ae0e081ac9392db3249e996473` |
| Output manifest | `09e305a1db747f97413a6881645b933fbe97ee602097d3ac59dcac8931c7d348` |
| Software manifest | `bad5b21b51dc79e83f2e64c10ca4af282d2b7c37f96157c6b3451208bc81a898` |
| Report manifest | `dc38b8857f0240a257a15b2a56a1b5bfeda7288d18f8ca5b47c36faca6ddb8af` |
| Focused pilot test | `6a8476e25397b17cf63545a62bd8c367c1ae3f2b01ea33e9203a296209a72ff6` |

## Author decision required

The recommended author decision is:

1. accept the pilot as an adequate test of the candidate route;
2. retain the `NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE` disposition;
3. stop the full shifted-log L10 batch; and
4. preserve the accepted two-part non-estimable record as the current H06-daily
   L10 result.

The alternative is not an ordinary continuation. It requires a new explicit
amendment to the temporal estimand or acceptance rule, followed by a newly
bounded authorization. Until the author chooses, all downstream H06-daily work
remains frozen.

## Reopening condition

Reopen if a controlling identity, frame, response, formula, contrast, family,
model, residual-dependence threshold, AR diagnostic, sensitivity, runtime,
preservation check, manifest, or verifier changes, or if the author explicitly
approves a revised temporal rule.
