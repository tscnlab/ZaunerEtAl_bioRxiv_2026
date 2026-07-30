# Preregistration contract

Status: extracted; implementation reconciliation open  
Contract date: 2026-07-29  
Authoritative source: `preregistration/AsPredicted #273407.pdf`  
Public locator stated in the signed PDF: <https://aspredicted.org/te3zw2.pdf>  
AsPredicted identifier: `#273407`  
Preregistered: 2026-02-13 00:07 PT  
PDF generated: 2026-03-17 02:12 PT  
PDF SHA-256: `fce192c88676602b72013e4872a03b535a2f4ef59d34de3a9e1c47527742b7ad`

The signed two-page AsPredicted PDF is authoritative for the confirmatory
contract. The analysis-plan document, repository notebooks, manuscript
versions, reviewer comments, and `_deviations.qmd` help explain implementation
and reporting, but they do not silently replace the signed contract.

The longer manuscript at repository tag `v1.0.0` was read in full as contextual
evidence. Its commit is `76f8467ef41437493a0868629f5722f318a6683e` and its
`index.qmd` SHA-256 is
`ae28cfffcaabbb2bed7d0f198efcb6d9bff973d035de98095db0f07481b6659e`.
Material recovered from it must still be reconciled with this contract and the
verified analysis.

## Registration context

Data had already been collected and publicly released when the study was
preregistered. The signed record states that the data had been accessed and
descriptively inspected, but that none of the specified hypothesis-driven
analyses had been performed. It labels the registered analyses as
confirmatory analyses of existing observational data and requires deviations
to be explicitly documented and labelled exploratory.

## Registered outcome set

All registered outcomes were to be derived from chest-mounted melanopic EDI
measurements sampled every 10 seconds. Chest data were primary and analyses
were to be repeated with glasses-mounted data for robustness.

| Class | Registered outcomes |
|---|---|
| Level | Geometric mean melanopic EDI in hourly bins/daily average; geometric mean during the 10 brightest hours; geometric mean during the 5 darkest hours |
| Duration | Time above 1000 lx; time above 250 lx during daytime; time within 1–10 lx during evening; time below 1 lx during sleep; longest period above 250 lx |
| Timing | First and last time above 250 lx; midpoint of brightest 10 hours; midpoint of darkest 10 hours; midpoint of the longest period above 250 lx |
| Spectrum | Melanopic daylight efficacy ratio (MDER; CIE S 026) |
| Dynamics | Interdaily stability; intradaily variability |
| Exposure history | Melanopic EDI dose in lx·h |

H2, H3, H4, and H11 specifically registered hourly geometric mean melanopic
EDI as their dependent variable.

For the brightest- and darkest-10-hour windows, the registered analytical
timing outcomes are the two **midpoints**. Window onset and offset may be
derived internally to verify the selected 10-hour interval, wrapping, and
tie handling, but they are not registered outcomes and must not enter an
H1--H11 model, multiplicity family, table, figure, or claim.

### Approved darkest-window deviation

The registered level metric based on the 5 darkest hours is replaced by the
geometric mean during the 10 darkest hours (L10 mean). This is a documented,
approved deviation recorded in `_deviations.qmd:12` and the decision ledger.
No 5-darkest-hour level metric (L5) will be calculated.

This does not alter the separately registered timing metric, which was already
the midpoint of the darkest 10 hours.

## Cross-hypothesis analysis rules

- Software: R 4.5 was named in the registration; the approved environment
  migration to R 4.6.1 must be documented and verified separately.
- FDR correction is required within hypothesis families.
- LMM selection uses likelihood-ratio tests evaluated against a chi-squared
  distribution at alpha 0.05.
- GAMM selection uses a minimum AIC difference of 2.
- Registered diagnostics include residual inspection, homoscedasticity, and
  normality.
- If a model is unstable, random slopes are reduced before interactions.
- AR(1) structures are added where residual autocorrelation is detected in
  GAMs.

The PDF does not define a numeric multiplicity-family size for every
hypothesis or say precisely how multiple predictors, contrasts, and
interactions are partitioned. Each repaired hypothesis must therefore declare
its complete p-value vector and family membership before adjustment. Applying
`p.adjust()` separately to scalar p-values does not satisfy this contract.

## Exclusion and threshold rules

1. Exclude days with less than 80% valid wear time, excluding sleep, from
   daily metric computation.
2. Remove non-wear periods identified in device logs.
3. Use complete cases within each model when required predictors are missing.
4. Do not statistically trim melanopic EDI; set values **above** 120,000 lx to
   missing.
5. Exclude hours with less than 50% valid data.
6. Report all exclusions transparently.

The strict inequality is part of the signed contract. The observed
`>=120000` versus `>120000` implementation difference remains an open
reconciliation item.

## Hypothesis contracts

### H01

Personal light-exposure metrics differ across sites after accounting for
latitude and photoperiod. Registered LMM:

`Metric ~ Site + Latitude + (1 | Site:Participant)`

Photoperiod was registered only for day/night duration metrics.

### H02

Within-participant variance in hourly melanopic EDI, with participants nested
in sites, exceeds variance between sites. Registered GAMM:

`Metric ~ Site + s(Time, by = Site, bs = "cc", k = 12) + s(Participant, Time, bs = "fs")`

The registered target is a comparison of variance components, not the
variance of prediction terms.

### H03

Hourly self-reported light-source categories predict hourly geometric mean
melanopic EDI. Registered LMM:

`melEDI ~ Predictor + (Predictor | Site) + (1 | Site:Participant)`

All tested categories, estimates, intervals, and null contrasts must be
reported.

### H04

Hourly self-reported activity categories predict hourly geometric mean
melanopic EDI. The registered model is the same structural LMM as H03, with
activity as the predictor. All tested categories, estimates, intervals, and
null contrasts must be reported.

### H05

LEBA questionnaire factors correlate with selected personal-light-exposure
metrics. Registered analyses are correlation matrices plus:

`Metric ~ LEBA + (1 | Site)`

The signed record does not enumerate the selected metric set, LEBA factor set,
or exact multiplicity-family size.

### H06

Day type, daily exercise, and sleep variables predict daily light-exposure
metrics. Day type includes weekday/weekend and free/work day. Registered LMM:

`Metric ~ Measure + (Measure | Site) + (1 | Site:Participant)`

The current change to hourly geometric mean melanopic EDI is a documented
deviation, not the registered outcome.

### H07

There is a nonlinear ceiling effect of absolute latitude and photoperiod on
level-, duration-, and exposure-history metrics. Registered GAMM:

`Metric ~ te(Latitude, Photoperiod) + s(Site, bs = "re") + s(Participant, bs = "re")`

The current photoperiod-only analysis is a documented deviation. A plateau or
ceiling claim must be supported by an estimand and diagnostic capable of
identifying it.

### H08

Duration-, exposure-history-, and level-based metrics are associated with
VLSQ-8 light-sensitivity scores. Registered LMM:

`Metric ~ Predictor * Site + (1 | Site:Participant)`

### H09

Timing-based metrics are associated with chronotype measured using MCTQ and
MEQ. Registered LMM:

`Metric ~ Predictor * Site + (1 | Site:Participant)`

### H10

Personal-light-exposure metrics depend on age and sex. Registered LMM:

`Metric ~ Predictor * Site + (1 | Site:Participant)`

Age and sex require distinct, declared multiplicity vectors and model
contrasts if treated as separate predictor families.

### H11

Diurnal exposure patterns differ by sex. Registered GAMM:

`melEDI ~ Sex + s(Time, by = Sex, bs = "cc", k = 12) +`
`s(Time, by = Site, bs = "fs", k = 12) +`
`s(Site, bs = "re") + s(Participant, bs = "re")`

## Placement amendment

The signed registration specifies chest data as primary and glasses data as a
robustness repeat. The approved placement decision reverses that order for a
clearly stated ocular-exposure estimand: glasses are primary and chest data
are paired/common-sample complementary evidence. Simple pooling is rejected.
This remains a transparent deviation from the signed registration, not a
reinterpretation of what was originally registered.

## Current reconciliation status

- The signed contract has been extracted into
  `audit/ledgers/hypothesis_contracts.csv`.
- Existing documented deviations through H07 are registered in
  `audit/ledgers/deviation_register.csv`.
- `_deviations.qmd` currently has no H08–H11 section; that coverage gap remains
  open.
- Confirmed implementation discrepancies are listed as open until their
  scientific consequences are repaired, rerun in R, and approved where the
  gate requires it.
