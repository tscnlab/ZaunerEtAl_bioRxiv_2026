# H01 response-family candidate assessment protocol

Date fixed: 2026-08-01  
Status: candidate set and decision rule fixed before alternative-fit results
were inspected  
Scope: H01 only

## Purpose

This protocol implements the author's disposition of the post-bootstrap H01
response-family gate. It compares like-for-like response-family packages for
three outcomes while preserving the outcome constructs, exact fitted rows,
fixed and random effects, main/manuscript-prepared implementations, near-eye
primacy, and complementary chest analyses.

The assessment is diagnostic. Effect directions, raw p-values, adjusted
p-values, site-follow-up eligibility, and agreement with the submitted
manuscript are excluded from model selection.

## Candidate packages

| Metric | Candidate ID | Family and response scale | Role |
|---|---|---|---|
| Time below 1 lx melEDI during sleep | `tweedie_log_identity` | Tweedie, log link, raw duration | Current |
| Time below 1 lx melEDI during sleep | `gaussian_identity` | Gaussian, identity scale | Predefined alternative |
| Time below 1 lx melEDI during sleep | `gaussian_log10_offset_0.1` | Gaussian after log10(duration + 0.1 h) | Conservative positive-scale alternative |
| Calendar-day cumulative time below 10 lx melEDI before sleep | `tweedie_log_identity` | Tweedie, log link, raw duration | Current |
| Calendar-day cumulative time below 10 lx melEDI before sleep | `gaussian_identity` | Gaussian, identity scale | Like-for-like alternative |
| Calendar-day cumulative time below 10 lx melEDI before sleep | `gaussian_log10_offset_0.1` | Gaussian after log10(duration + 0.1 h) | Conservative positive-scale alternative |
| L10 mean melEDI | `gaussian_log10_offset_0.1` | Gaussian after log10(melEDI + 0.1 lx) | Current |
| L10 mean melEDI | `tweedie_log_identity` | Tweedie, log link, raw melEDI | Named alternative |
| L10 mean melEDI | `gaussian_identity` | Gaussian, identity scale | Completeness candidate |

Gamma candidates are not fitted because the observed outcomes contain exact
zeros. Adding an offset to enable Gamma fitting would change the likelihood
and make the offset part of the scientific model. Zero-inflated and hurdle
models are not candidates because they introduce a second estimand and would
require a separately specified inferential and reporting contract. If none of
the candidates above is adequate, the current model is retained with explicit
limitations under the author's instruction; a more complex model would
require a new major-change gate.

## Runs and invariant sample

Each candidate is fitted to all eight declared combinations:

- main and manuscript-prepared data;
- near-eye and chest placement; and
- all-available and paired/common samples.

For a metric-run combination, every candidate must have identical ordered
`.model_row_id` values, predictors, centering constants, contrasts, and model
formulas. Main-data measurement-support quantities are retained. Support
hours unavailable in manuscript-prepared data remain unavailable.

## Diagnostic evidence

The comparison uses the existing H01 implementation and records:

- errors, warnings, convergence, positive-definite Hessian, singularity, and
  maximum gradient for every comparison and final model;
- residual classification and its underlying Gaussian or DHARMa statistics;
- observed and predicted physical-support checks, including the strictly
  above-six-hours pre-sleep audit warning;
- exact participants, participant-days, observations, sites, and main-data
  support hours; and
- the number and identity of model rows, verified across candidates.

The existing H01 diagnostic thresholds are retained without modification.
The same deterministic diagnostic seed is used for every candidate within a
metric-run combination.

## Candidate eligibility

A candidate is eligible only if all of the following hold:

1. every required inferential comparison and final model in all eight runs is
   fitted;
2. every required inferential model converges with a positive-definite
   Hessian and is not singular;
3. no run has `FAIL_MAJOR_GATE`;
4. the two all-available near-eye runs have no strong residual warning; and
5. no run has an observed-support failure.

An eligible alternative is classified as showing good common diagnostics
only when it also has no strong residual warning in any of the eight runs and
neither all-available near-eye run has a predicted physical-support warning.
The latter check uses the bounds available in each data scenario; unavailable
manuscript-prepared sleep-support hours are not imputed.

## Selection rule

One common candidate is selected per metric for all eight runs. Selection is
lexicographic and does not use inferential results:

1. retain only eligible candidates with good common diagnostics;
2. prefer fewer physical prediction-support warnings;
3. then prefer fewer ordinary residual warnings;
4. then prefer fewer fit warnings across required models; and
5. if an alternative is not strictly better than the current candidate on
   this ordered diagnostic profile, retain the current candidate.

If the current candidate is not eligible, an eligible alternative with good
common diagnostics is selected using the same ordering. If no candidate has
good common diagnostics, retain the current model with an explicit diagnostic
limitation, as directed by the author. No response family will be switched
silently.

AIC is recorded only as descriptive fit metadata. It is not compared across
different response transformations because such likelihoods are not directly
comparable without the transformation Jacobian.

The separately fitted random-site model is a descriptive variance summary,
not one of the site, photoperiod, latitude, or same-frame adequacy comparison
models. Its convergence and singularity are reported but do not determine
response-family eligibility. The first automated scorecard on 2026-08-01
incorrectly counted this descriptive model among the required inferential
models. This implementation error was identified during result review and
corrected before any canonical family was selected or changed. Candidate
fits, residual thresholds, support checks, and inferential model definitions
were not changed.

## Downstream computation rule

Candidate fitting does not overwrite canonical models or completed bootstrap
draws. If a replacement is selected, only changed metric-run targets require
new point-model artifacts and bootstrap draws. All four 17-test BH vectors
must nevertheless be recalculated after new model-level p-values are
available.

Before any changed production bootstrap, COMPUTE-001 requires a separately
stored 50- or 100-successful-refit pilot for every changed target, explicit
pilot labelling, runtime/failure/warning/resource/checkpoint evidence, reader-
facing table and figure previews, and author approval. Existing unaffected
production draws remain authoritative and are not recomputed.
