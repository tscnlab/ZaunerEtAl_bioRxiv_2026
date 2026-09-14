# H03 post-closure harmonization synchronization check

Date: 2026-08-14  
Finding: RH-SYNC-H03-001  
Disposition: companion and catalog synchronization required before the H03 REPORT-017 render; no scientific discrepancy and no shared-navigation repair

## Accepted owner return

The H03 owner reported an author-approved scientific closure at commit
`c88c2d79e428578345c466ca18bb5b5faee912f5`. The current reader-result
source is:

- `notebooks/hypotheses/H03.qmd`
- SHA-256 `5d329c24afbd321a2be8d87ca7453a8612ab6745d009d4cecef2c82a4c6dd59a`

The live preparation and provenance companion remains the previously accepted
harmonized source:

- `audit/hypotheses/H03/H03_analysis_preparation.qmd`
- SHA-256 `b7671d848544228088df9bbe179a172fd7402e7fa18c3029be9b499d0ef2f760`

That companion is deliberately unstaged and was not changed by the scientific
closure commit.

The controlling central scientific authority is `H03-AUX-001 / CHG-139`:

- `audit/decisions/h03_auxiliary_model_assessments_closure.md`
- SHA-256 `85be31f6c105ea2c47a5353a32d4081dcdbc50a0738998f2106c0952c4527827`

That decision keeps H03 scientifically closed, classifies the auxiliary model
as descriptive supplementary evidence, and prohibits importing its estimates
into another hypothesis, multiplicity family, diagnostic verdict, or claim.
The later companion synchronization must implement that boundary without
reopening H03 model selection or analysis.

## Scientific distinctions that must remain explicit

The existing within-participant and between-participant sensitivity is a
population-mean quasi-Tweedie augmentation with participant-clustered
covariance:

```text
geo_medi_1h ~ site + light_source +
  between_source_1 + between_source_2 + between_source_3 +
  between_source_4 + between_source_5 + between_source_6
```

It is not a random-slope mixed model. Its overall conclusion remained stable.
The owner-approved magnitude summaries are 0.333 (95% CI 0.190 to 0.585) for
near-eye external light during sleep, 25.8% below the primary estimate, and
0.244 (95% CI 0.116 to 0.514) for the chest placement, 34.0% below the primary
estimate. The near-eye outdoor-electric estimate remained null and imprecise:
1.019 (95% CI 0.336 to 3.090), FDR-adjusted p = 0.973.

The newly reported auxiliary model is a distinct participant random-intercept
assessment. It uses `glmmTMB`, a Tweedie distribution with a log link, maximum
likelihood, and fixed power 1.539919:

```text
geo_medi_1h ~ site * light_source + (1 | participant)
```

Its accepted model-based values are marginal R-squared 0.79585, conditional
R-squared 0.87623, and a participant-intercept increment of 0.08037. The
hierarchy-respecting refit-based Shapley allocation is 0.05630 for site
(7.07%), 0.71045 for light source (89.27%), and 0.02910 for the interaction
(3.66%). All five nested fits passed the convergence, Hessian, and singularity
checks.

This auxiliary assessment is descriptive and model-dependent. It is neither a
causal nor a unique allocation. It contains no random slopes, participant-day
term, or AR(1) term. The residual lag-one correlation of 0.288 and the working
zero-mass mismatch remain visible qualifications. It does not replace or
modify the accepted population-mean quasi-Tweedie GLM or its omnibus test.

## Structural and link review

The shared profile already places the H03 result and companion adjacently in
both `project.render` and the hypothesis-analysis sidebar. No profile or
navigation change is needed.

The current Phase 4 corpus manifest already records:

- result source SHA-256 `5d329c24afbd321a2be8d87ca7453a8612ab6745d009d4cecef2c82a4c6dd59a`;
- result HTML SHA-256 `68aa07eb7470286d0d6da76114ce7bf346ee635974fe7403c1860ad4560c3d25`;
- companion source SHA-256 `b7671d848544228088df9bbe179a172fd7402e7fa18c3029be9b499d0ef2f760`;
- companion HTML SHA-256 `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`.

The new result subsection uses a unique Quarto table endpoint,
`tbl-h03-participant-random-intercept`, and all four linked stored CSV targets
resolve. Existing result-to-companion and companion-to-result links use
relative `.qmd` targets. No hard-coded internal HTML link was found in the
current result flow.

The owner-scoped H03 render is verification evidence only. It is not an
accepted REPORT-017 serial integration render. H03 remains held until its
serial position after H01 and H02.

## Required bounded owner synchronization

Before the H03 REPORT-017 render, the H03 owner should receive one bounded
source-only synchronization order covering the following items:

1. Add a preparation-companion subsection immediately after the fixed-effect
   R-squared section. Give it a stable Quarto anchor and document the auxiliary
   model, its stored estimands, fit checks, remaining qualifications, and
   display-only reading of accepted artifacts.
2. State explicitly that the auxiliary random-intercept assessment and the
   Mundlak-style within-participant and between-participant sensitivity are
   different models with different purposes. Do not describe the latter as a
   random-slope model.
3. Add `run_h03_participant_random_intercept_assessment.R` and its accepted
   model, summary, Shapley, diagnostic, environment, and manifest outputs to
   the companion code and output maps.
4. Add one dynamic result-to-companion `.qmd` link to the new companion anchor.
   Preserve the existing reciprocal companion-to-result link.
5. Prefer the plain reader label `participant-level variation` over an
   unexplained `participant heterogeneity` group label. Keep exact technical
   terms where required for reproducibility.
6. Refresh `audit/handoffs/H03_worker_handoff.md` with the new result identity,
   auxiliary-model boundary, and companion synchronization evidence.
7. Add `tbl-h03-participant-random-intercept` to the output catalog as a
   supplemental detailed-result and model-check table. The provisional H03
   principal roles remain `fig-h03-primary-estimates` and
   `tbl-h03-primary-results`.

The order must preserve all accepted samples, formulas, estimates, intervals,
p-values, FDR decisions, model checks, sensitivity results, figures, source
data, and the primary population-mean conclusion. It must not fit or refit a
model, recompute Shapley values, regenerate a scientific artifact, or advance
the REPORT-017 render queue.

## Current disposition

RH-SYNC-H03-001 is a bounded provenance and reader-pair synchronization item.
It is not a scientific discrepancy. No H03-owned source was edited during this
check, and the active H01 REPORT-017 work was not interrupted.
