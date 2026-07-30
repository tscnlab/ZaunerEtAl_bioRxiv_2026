# H01 model and reporting decisions

Date: 2026-07-30  
Status: approved by the author; no rebuilt H01 exposure model fitted

This record closes the decisions listed below. It does not contain or imply a
rebuilt H01 result. The approved response model for each of the 17 metrics and
the formal site-versus-latitude adequacy comparison are recorded in
`audit/decisions/h01_prefit_gate.md`.

## H01-001: Model-level Benjamini--Hochberg correction

The intended unit of correction is one preselected overall test from each of
the 17 metric models, not every coefficient estimated within those models.

Four separate model-level families will be calculated:

1. 17 overall site tests;
2. 17 overall photoperiod tests; and
3. 17 overall latitude tests; and
4. 17 same-frame comparisons of the full site model with the linear-latitude
   model.

Each family is assembled as a complete 17-value vector and adjusted once with
the Benjamini--Hochberg method. A planned metric whose test is not estimable
remains as a missing row in the 17-row registry; the family is never shortened
or redefined after inspecting results.

For nested comparisons, the full and reduced models use identical rows,
outcome distribution, link, and random-effect structure. Gaussian models with
different fixed effects are compared under maximum likelihood. Final Gaussian
effect estimates are obtained from the declared restricted-maximum-likelihood
fit where appropriate.

## H01-002: Site deviations from the overall mean

The recognizable submitted H1 follow-up is retained. When a metric's overall
site test is supported after correction of the 17-test site family,
`emmeans` will compare each site's model-based average with the equally
weighted mean of all site averages.

These follow-ups are secondary to the overall site test:

- the nine near-eye deviations are adjusted together within that metric;
- the eight complementary chest deviations are adjusted together within that
  metric;
- both raw and adjusted \(p\)-values are shown;
- every site estimate and deviation has a 95% confidence interval; and
- a linear-scale result is reported as a difference, whereas a valid
  response-scale result from a log-link model is reported as a ratio.

Metrics without a supported overall site test receive descriptive site
averages but no inferential from-mean follow-up. The follow-up values do not
enter the primary 17-test family.

## H01-003: Variation represented by the models

The scientific construct of variation represented by site, photoperiod, and
participants is retained, but the submitted calculation and terminology are
repaired.

For every declared full model, irrespective of statistical significance, the
report includes:

- marginal \(R^2\) for all fixed effects together;
- conditional \(R^2\) for fixed and random effects together;
- the participant-associated share, defined as conditional minus marginal
  \(R^2\), for participant-day models;
- part \(R^2\) for the complete site term;
- part \(R^2\) for photoperiod; and
- one minus conditional \(R^2\) as the variation not represented by the
  fitted model.

The part \(R^2\) for a term is the reduction in fixed-effect prediction
variance after removing that term, divided by the full model's variance
denominator. The full and reduced fits use the same rows, model family, link,
and participant structure. Site and photoperiod part \(R^2\) values are
reported separately and are not added because they can share information.
The latitude model receives a separate latitude part \(R^2\); it is not added
to values from the fixed-site model. Participant-level IS and IV models have
no participant random-effect share.

The submitted code's conditional-\(R^2\) branch error and
significance-dependent switching are not retained.

## H01-004: Uncertainty and exact model samples

All effect estimates, site averages and deviations, transformed effects,
marginal and conditional \(R^2\), participant-associated shares, and part
\(R^2\) values receive 95% confidence intervals.

The planned primary uncertainty calculation uses at least 1,000 successful
parametric-bootstrap refits per metric. Full and reduced models are refitted
within the same bootstrap replicate. The random seed, attempted and successful
refits, failed refits, warnings, and interval method are recorded. Tweedie
\(R^2\) is reported on the log-link scale using the lognormal residual-variance
approximation as primary and the delta approximation as a named sensitivity.

Every participant-day model reports participants, participant-days (model
rows), valid measurement hours contributing to the metric, and sites overall
and by site. IS and IV models report participants (model rows), contributing
participant-days, valid measurement hours, and sites overall and by site.
Measurement hours are explicitly labelled as derivation support rather than
model rows. These are the exact fitted-model samples and their supporting
exposure records, not counts from the prepared H01 dataset.

The retained manuscript-prepared metric artifacts do not contain the exact
support minutes needed to reconstruct metric-specific hours. That sensitivity
still reports the exact fitted-model observations, participants,
participant-days or contributing days, and sites, but labels the support hours
as unavailable rather than zero. If exact support records are later recovered,
they require separate reconstruction and verification before being reported.

The repaired H01 page will compare these results with the submitted estimates
and claims as part of the audit discussion. Its formal data sensitivity uses
the same repaired H01 implementation on the manuscript-prepared dataset, with
only objectively demonstrable data errors corrected, as defined in
`audit/decisions/manuscript_prepared_data_sensitivity.md`. It does not rerun
the manuscript's H01 model implementation. Any material result or claim change
reopens the H01 result gate.
