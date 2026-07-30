# H01 predictor-identifiability gate

Status: major gate prepared; no exposure outcome inspected  
Date: 2026-07-30  
Runtime: R 4.6.1

## Question

H01 was preregistered as a test of site differences after considering latitude
and, for day/night-duration metrics, photoperiod. The current analysis and
manuscript sometimes describe a site effect as persisting “after accounting
for latitude and photoperiod.” The predictor structure must establish whether
that statement is estimable before any repaired H01 outcome is modelled.

## Outcome-blinded audit

`audit/scripts/audit_h01_predictor_identifiability.R` read only the exact
site, participant, placement, and local-date columns from the canonical
participant-day metric artifacts. It joined those keys without row loss to
the verified 616-row site/solar context. It did not select, summarize, model,
or export an exposure outcome.

The near-eye domain contains 811 participant-days from 141 participants at
nine sites. The chest domain contains 897 participant-days from 154
participants at eight sites. Every domain row matched exactly one context
row.

## Identifiability result

Latitude is a single constant for each site. Consequently:

- `site + photoperiod` has full design-matrix rank for both placements;
- `site + latitude + photoperiod` is rank deficient for both placements; and
- a coefficient for latitude cannot be estimated conditionally on a saturated
  fixed site factor.

The raw model spaces nevertheless permit a useful nested scientific
comparison: a linear latitude model is a constrained submodel of the
site-factor model. Comparing them can test whether the between-site pattern
is adequately summarized by a linear latitude gradient. It cannot decompose
a fitted site coefficient into a latitude-adjusted and a residual site
coefficient.

Photoperiod varies within site and can therefore enter a site-factor model,
but its conditional coefficient is identified from within-site collection
periods. Support is uneven:

- near eye: within-site ranges extend from 0.009 h at UCR and 0.218 h at
  KNUST to 8.63 h at RISE;
- chest: within-site ranges extend from 0.218 h at KNUST and 0.516 h at UCR
  to 9.17 h at RISE.

Thus, a site-adjusted photoperiod coefficient is not a generic cross-country
latitude/season effect. It is principally a within-site collection-period
association, with very little information from some sites.

## Recommended disposition

For eligible daily outcomes:

1. Fit a site-factor model with photoperiod as an explicitly
   within-site-supported covariate. Interpret the site omnibus as residual
   between-site heterogeneity at the observed collection periods.
2. Fit a separate latitude-plus-photoperiod model and compare its model space
   with the site-factor model on the exact same frame. Interpret improvement
   by site as evidence that a linear latitude gradient does not summarize the
   observed site pattern.
3. Do not report a “site effect adjusted for latitude.” Use wording such as
   “site differences were not fully summarized by latitude and observed
   photoperiod.”
4. Preserve the literal preregistered photoperiod scope as a named
   sensitivity if the adapted primary analysis applies photoperiod to all
   scientifically eligible daily outcomes.
5. Report within-site photoperiod support and leave-one-site-out influence;
   do not interpret a photoperiod coefficient as seasonal causation.

Participant-level IS/IV require a separate, declared aggregation of
photoperiod support or a model without a day-varying photoperiod covariate.
No participant-level value should be duplicated across days merely to fit the
daily formulation.

This disposition changes the wording and exact H01 estimand relative to the
current manuscript and therefore requires author approval before H01 fitting.

## Artifacts

- `audit/reconciliation/h01_predictor_gate/site_photoperiod_support.csv`
- `audit/reconciliation/h01_predictor_gate/design_rank.csv`
- `audit/reconciliation/h01_predictor_gate/photoperiod_range_overlap.csv`
- `audit/reconciliation/h01_predictor_gate/artifact_manifest.csv`

## Reopening condition

Reopen if the site set, placement rule, participant-day domain, coordinates,
photoperiod definition, collection dates, site structure, or H01 predictor
scope changes.
