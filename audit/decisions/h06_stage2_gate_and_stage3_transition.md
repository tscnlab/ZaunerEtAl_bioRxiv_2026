# H06 Stage 2 gate and Stage 3 transition

Decision ID: `H06-003`  
Date: 2026-08-11  
Status: approved

## Evidence

The author accepted H06 Stage 2 and authorized the transition to the
standalone reader-facing report. The accepted Stage 2 identities are:

- source: `audit/hypotheses/H06/02_implementation_and_v0_comparison.qmd`,
  SHA-256
  `736926de3576a7dceaed7b92fb65f65a05d8f6d32604d533fd9eb6e45e26a36d`;
- rendered HTML:
  `audit/hypotheses/H06/02_implementation_and_v0_comparison.html`, SHA-256
  `eea3da853bb23db96a59759d11a8f7eeb838e2e42960bf71ab96830030289b75`;
- Stage 2 manifest:
  `artifacts/12_manifests/H06/H06_stage2_artifacts.csv`, containing 227
  recorded identities and SHA-256
  `2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752`.

The four focused H06 R 4.6.1 test suites passed at the worker handoff. The
coordinator independently matched the two accepted report identities,
confirmed the 227-row manifest structure, and passed the central comparison
ledger verifier after recording this transition.

## Accepted Stage 2 result contract

H06-G2 is closed with the qualifications stated in the accepted report:

1. The quasi-Poisson population-mean model with participant-cluster HC3
   covariance is the primary implementation of the selected supported-hour
   estimand.
2. The active-versus-sedentary association is retained as a stable
   observational association across the declared checks.
3. The free-versus-work association is retained only with its
   working-variance, site-heterogeneity, and leave-site-out qualifications; it
   is not a generally robust, site-invariant association.
4. The previous-sleep association is inconclusive over the accepted 95%
   confidence interval and is not evidence of no association.
5. Chest, paired-day, gap-timing-unaware, weekday/weekend, additional-diary,
   and temporal GAM results retain their complementary, sensitivity,
   contextual, or exploratory roles.
6. The documented mean-calibration, residual temporal-dependence, local-clock,
   zero-process, and working-distribution limitations remain adjacent to the
   results.

No production bootstrap or other heavy resampling is required between Stages
2 and 3.

## Stage 3 authorization

Stage 3 is authorized at `notebooks/hypotheses/H06.qmd`. It must be a
standalone reader-facing report, use the accepted stored H06 outputs, contain
the compact `Answer in brief` callout directly after the hypothesis and
analytical question, and preserve exact samples, 95% confidence intervals,
multiplicity rules, diagnostics, placement roles, sensitivity
classifications, and claim scope. It must stop for explicit author approval
before Stage 4 begins.

At the author's request, Stage 3 must also include exploratory temporal
contrasts for:

- Active versus Sedentary; and
- Free day versus Work day.

These displays may be derived from the accepted stored two-part temporal
models and their frozen prediction framework; they must not refit or amend a
model. They should show the response-scale expected-melEDI contrast across
local clock time, with a clearly marked null reference and pointwise 95%
intervals. Any pointwise highlighting must be described as exploratory and
must not be presented as a multiplicity-controlled whole-curve test.

The temporal contrasts remain separate from the accepted primary inference.
Their captions and interpretation must retain both components of the temporal
model (positive-occurrence probability and positive conditional magnitude)
and the existing qualifications: fixed smoothing parameters, omitted
occurrence--magnitude cross-component covariance, residual working
correlation, occurrence calibration, basis sensitivity, and no confirmatory
whole-curve inference. Each durable display requires an exact source-data CSV,
accessible alt text, and final-size readability and clipping checks. If valid
contrast intervals cannot be derived from the frozen models under this
contract, the worker must stop and reopen the display decision rather than
refit silently.

## Stage boundary and reopening condition

Stage 4 remains blocked until the author approves Stage 3. Reopen H06-G2 if an
accepted input, model, estimate, interval, multiplicity family, diagnostic,
sensitivity classification, or substantive claim changes; if the new
temporal contrasts require a model amendment; or if a focused verifier fails.
