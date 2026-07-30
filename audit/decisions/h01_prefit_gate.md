# H01 decisions approved before model fitting

Date: 2026-07-30  
Status: approved by the author  
Result-blinding: no rebuilt H01 exposure model or effect was fitted

## Decision record

The H01 question, predictor structure, multiple-testing correction,
site-from-mean follow-up, confidence intervals, sample reporting and
variation summaries had already been approved. The author approved the two
remaining choices before fitting:

1. the error distribution and transformation used for each metric; and
2. a formal test of whether a linear latitude gradient adequately summarizes
   the full site pattern.

These choices affect the likelihood, effect scale, confidence intervals,
diagnostics, multiplicity families and permissible claim. They therefore
remain fixed unless a required diagnostic triggers a new major gate.

## Approved response-family package

The recommendation preserves the manuscript's response models wherever they
remain compatible with the verified outcome support. The same primary model
must be used for the main and manuscript-prepared datasets.

| Metric | Proposed primary response model | Predefined diagnostic or alternative |
|---|---|---|
| Interdaily stability | Gaussian after logit transformation | Beta/logit only after a separately approved failure of the transformed Gaussian model |
| Intradaily variability | Gaussian with identity link | Residual, variance and influence checks |
| Mean melEDI | Gaussian after `log10(value + 0.1)` | Offset and upper-tail checks; Tweedie/log alternative |
| Brightest 10-hour mean melEDI | Gaussian after `log10(value + 0.1)` | Influence and upper-tail checks; Tweedie/log alternative |
| Darkest 10-hour mean melEDI | Gaussian after `log10(value + 0.1)` | High-risk zero-mass check; Tweedie/log alternative |
| Time above 1,000 lx melEDI | Tweedie with log link | Zero mass, tail, dispersion and prediction-bound checks |
| Time above 250 lx melEDI during wake | Tweedie with log link | Zero mass, tail and waking-duration-bound checks |
| Time below 10 lx melEDI before sleep | Tweedie with log link | Three-hour ceiling check; shifted-log Gaussian alternative |
| Time below 1 lx melEDI during sleep | Tweedie with log link | Distribution check; identity-Gaussian alternative |
| Longest continuous period above 250 lx melEDI | Gaussian after `log10(value + 0.1)` | Mandatory exactly-identified-only sensitivity |
| Midpoint of the brightest 10 hours | Gaussian with identity link | Verify one continuous daytime range |
| Midpoint of the darkest 10 hours | Gaussian after subtracting 24 hours from values after noon | Verify one continuous range around midnight |
| Mean timing above 250 lx melEDI | Gaussian with identity link | Verify one continuous clock range |
| First light timing above 250 lx melEDI | Gaussian with identity link | Verify no late-evening cluster |
| Last light timing above 250 lx melEDI | Gaussian with identity link | Verify no early-morning cluster |
| melEDI dose | Gaussian after `log10(value + 0.1)` | Offset, influence and upper-tail checks; Tweedie/log alternative |
| MDER | Gaussian with identity link | Tail and influence checks; zero-capable Tweedie/log alternative |

The outcome-blinded screen was repeated against the final verified H01 data.
It did not alter any recommendation. Darkest 10-hour mean melEDI contains
111/811 near-eye zeros and 126/897 chest zeros. The primary longest-period
outcome is a lower bound on 314/811 near-eye and 332/897 chest
participant-days. Only the darkest 10-hour midpoint crosses midnight. MDER
cannot use a beta model because the chest data contain an exact zero and
values above 1.

Switching a primary response family after diagnostics remains a major gate.
An alternative is never selected separately for one data scenario: if the
approved primary model fails for the main or manuscript-prepared dataset, the
affected result is reported as non-estimable until one common replacement is
approved.

## Approved site-versus-latitude adequacy test

The three approved 17-test Benjamini--Hochberg families test site, day length
and latitude separately. None directly tests whether the full site pattern can
be summarized by one linear latitude gradient.

For each metric, compare the fixed-site model with the otherwise identical
linear-latitude model on the same observations and adjust the 17 resulting
model-level \(p\)-values together as a fourth Benjamini--Hochberg family. This
permits a formal claim about whether latitude adequately summarizes the site
pattern.

Adding the formal family is a change to the approved multiplicity registry and
is recorded as a transparent H01 adaptation before fitting. Same-sample AIC
differences and leave-one-site-out latitude estimates remain descriptive
support and do not replace the formal family.

## Author approval

On 2026-07-30, before any rebuilt H01 exposure model was fitted, the author
approved the complete 17-metric response-family package and the formal fourth
17-test site-versus-latitude Benjamini--Hochberg family.
