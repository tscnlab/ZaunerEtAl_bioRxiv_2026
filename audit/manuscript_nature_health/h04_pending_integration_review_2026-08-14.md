# H04 pending manuscript-integration review

Date: 2026-08-14

Status: resolved. Commit `2c8c097ed1b312058cbf3ff69c31fc501fa7c994` sealed the H04 sources. The qualified exploratory decomposition has entered the Phase 3 manuscript.

Accepted identities:

- reader source `notebooks/hypotheses/H04.qmd`: `cd58c2ff5708fd3c74336656056dc1459f59772e55a31abd6f90bd25ad11e6ac`;
- companion source `audit/hypotheses/H04/H04_analysis_preparation.qmd`: `28e44e527f1048cdd2b56cf2d7d7ed4b6a1faea5b8cd2c6765068fb2bf994d3d`.

## Provisional evidence received

The proposed exploratory model is a fractionally weighted `glmmTMB` Tweedie log-link mixed model fitted by maximum likelihood:

```r
geo_medi_1h ~ site * activity_named + (1 | participant)
```

It uses the fixed working power 1.539919, exact 1/*k* weights and the support-qualified five named activity categories. Other-only hours are excluded. The pending reader sources report:

- near eye: marginal R-squared 0.766, conditional R-squared 0.858, participant-intercept increment 0.092 and distribution-specific remainder 0.142;
- chest: marginal R-squared 0.768, conditional R-squared 0.859, participant-intercept increment 0.092 and distribution-specific remainder 0.141;
- allocation of marginal R-squared at near eye: activity 80.7%, site 12.5% and activity-by-site interaction 6.9%; and
- allocation of marginal R-squared at chest: activity 86.1%, site 5.9% and activity-by-site interaction 8.0%.

These are point estimates without bootstrap intervals. The pending diagnostics report participant-hour lag-one residual correlations of 0.317 near eye and 0.301 at chest. Observed exact-zero fractions were 0.294 and 0.301, compared with model-implied fractions of 0.410 and 0.429.

## Integration concerns

1. The H04 sources and assessment artifacts are not yet sealed. The shared checkout remains at H03 commit `c88c2d7`, while the H04 report and assessment files are uncommitted. Manuscript integration must wait for the owner-approved H04 commit, exact accepted identities and provenance confirmation.
2. The H04 R-squared construction uses the exact 1/*k*-weighted variance of the fixed linear predictor. It is related to, but not directly interchangeable with, the H03 unweighted-row Nakagawa quantities or the existing H04 quasi-deviance and squared-error summaries.
3. The assessment covers five named activity categories and excludes Other-only hours. It therefore describes a narrower support-qualified frame than the full descriptive activity roster.
4. The random intercept describes a common stable participant multiplier across activities. With no random activity slopes, it cannot support participant-specific activity responses or individual prediction.
5. The Shapley values allocate marginal model-based R-squared. They are not shares of raw response variance, causal importance or out-of-sample predictive importance.
6. Residual serial dependence and zero-mass mismatch remain. Convergence, positive-definite Hessians and nonsingularity do not remove these limitations.
7. The manuscript already reports the primary population-mean activity estimates and an existing descriptive quasi-deviance allocation. Reporting both allocations without a clear hierarchy would burden readers and invite false numerical comparison.
8. The current Introduction, Results and Discussion total is close to the author-approved 4,400-word ceiling. Any H04 addition should replace or compress existing activity-model-fit prose rather than create a full new paragraph.

## Implemented post-seal treatment

The accepted population-mean quasi-Tweedie estimates remain the activity-section anchor. The older main-text quasi-deviance allocation was replaced with the sealed exploratory mixed-model decomposition, including both positions, the common participant-intercept increment and the marginal-R-squared allocation. The Results state that this is not raw response variance or causal importance, that no participant-specific activity slopes were fitted and that residual correlation and zero-mass mismatch remained. Methods record the five-category restriction, exclusion of Other-only hours, exact 1/*k* weighting, weighted fixed-predictor variance and point-only uncertainty boundary.

## Provisional sources inspected

- `notebooks/hypotheses/H04.qmd`
- `audit/hypotheses/H04/H04_analysis_preparation.qmd`
- `artifacts/09_tables/H04/H04_participant_random_intercept_summary.csv`
- `artifacts/09_tables/H04/H04_participant_random_intercept_marginal_r2_shapley.csv`
- `artifacts/08_diagnostics/H04/H04_participant_random_intercept_diagnostics.csv`
- `artifacts/08_diagnostics/H04/H04_participant_random_intercept_shapley_models.csv`
