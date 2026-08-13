# H06_daily H02-aligned temporal production transition

- Date: 2026-08-11
- Gate: **H06-D-G2P-H02**
- Status: **approved with pointwise-only uncertainty amendment**
- MDER: **still on upstream hold and excluded from this transition**

## Author decision

The author approved the H02-aligned temporal production scope after reviewing
the corrected bounded pilot. The approval closes H06-D-G2P-H02 items 02–05
with one explicit amendment: use pointwise 95% confidence intervals only.
Do not construct, simulate, display, or describe simultaneous intervals.

The approved association functions are:

1. Free day minus Work day over local clock time;
2. Active minus Sedentary daily activity status over local clock time;
3. the association per one-hour greater previous-night sleep duration within
   participant; and
4. the association per one-hour greater participant-mean sleep duration
   between participants.

The first two contrasts and two sleep functions form one separate exploratory
four-test Benjamini–Hochberg family. This family must not be combined with any
preregistration-aligned participant-day family.

## Approved display and uncertainty contract

Report:

- transformed-scale functions and pointwise 95% confidence intervals;
- ratios for the shifted response `Y + 0.1` where scientifically useful;
- inverse-transformed conditional-median-like profiles in lx with pointwise
  95% confidence intervals; and
- raw and four-test BH-adjusted whole-function p-values, clearly labelled as
  exploratory approximate GAM inference.

Never call the inverse-transformed profile raw-scale `E[Y]`. Do not create
simultaneous bands or use simultaneous-interval simulation.

## Approved placement and dataset frames

The production batch may fit:

1. near-eye all available;
2. chest all available;
3. paired/common near-eye;
4. paired/common chest;
5. gap-timing-unaware near-eye; and
6. gap-timing-unaware chest.

Each frame must reconstruct its own equally day-weighted within/between sleep
decomposition, estimate its own working rho from the rho-zero full-model
response residuals, retain exact samples, and repeat all convergence, basis,
residual, temporal-dependence, identifiability, and cyclic-closure checks.
Near-eye all available is primary for this exploratory amendment; chest and
paired/common frames are complementary, and the gap-timing-unaware frames are
a separately labelled sensitivity.

## Remaining compute boundary

The 12-fit six-frame base-model batch is approved after static support and
formula checks. Site-deletion batches, bootstrap, or other heavy resampling
remain withheld until a bounded production-code representative or 50/100-
replicate pilot reports its runtime and receives separate approval.
Pointwise model-based standard errors and intervals are not a resampling
batch.

No MDER-specific contract, frame, estimate, or conclusion is activated by
this approval.
