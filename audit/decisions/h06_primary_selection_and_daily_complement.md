# H06 primary-analysis selection and daily-metric complement

Decision ID: `H06-007`  
Change ID: `CHG-116`  
Date: 2026-08-12  
Status: approved; main analysis selected, complementary analysis in progress

## Author decision

The author has selected the completed **hourly H06 analysis** as the main H06
analysis. The participant-day H06_daily variant is retained as complementary
evidence because it more closely represents the preregistered daily-metric
question. The complementary branch is to be completed, but it does not replace
the main analysis and is not a competing final version.

This resolves the version-selection hold recorded in `H06-006`. The main H06
four-stage record remains accepted and frozen. Overall H06 closure now awaits
completion and author review of the complementary daily-metric branch, not a
later choice between two alternative primary analyses.

## Scientific roles

- `notebooks/hypotheses/H06.qmd` remains the submission-facing main result.
- H06_daily answers a distinct participant-day question in which every
  admissible participant-day contributes once to the relevant daily metric.
- H06_daily must be labelled **complementary** wherever its relation to the
  main H06 result is described. It must not be described as a replication,
  replacement, equivalence analysis, or adjudication of which analysis is
  correct.
- Agreement or disagreement is interpreted as dependence on analytical unit,
  estimand, and temporal weighting. It does not retroactively change an
  accepted main-H06 model or claim.

## Reporting structure

The daily branch retains separate Stage 3 and Stage 4 documents:

1. `notebooks/hypotheses/H06_daily.qmd` is a concise, standalone
   reader-facing report of the complementary scientific results. It contains
   the preregistered question, an **Answer in brief** note, methods needed to
   understand the estimand, results, diagnostics, sensitivities, limitations,
   and a clear statement that the hourly H06 analysis is primary.
2. `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd` is the
   separate bounded scientific preparation and provenance companion. It
   explains inputs, scripts, sample construction, model pipeline, diagnostics,
   stored outputs, and checks without refitting or reinterpreting the result.

Combining these pages is not approved. Their purposes and execution boundaries
are different, the established four-stage structural verifier expects the
split, and combining them would make the complementary result harder to read.
The provenance companion should therefore be proportionate and lean rather
than duplicating the full result report. Stage 4 begins only after explicit
author approval of Stage 3. Website integration remains coordinator-owned and
is considered only after both sources are accepted.

## Preservation and gate effect

The accepted main H06 sources, models, estimates, intervals, diagnostics,
sensitivities, figures, tables, manifests, and claims remain frozen. This
decision authorizes no main-H06 fit, report edit, or shared-data change.

The central H06 gate moves from `version_selection` to
`complementary_daily_stage2_pilot`. H06_daily proceeds only under the separate
bounded reopening in `H06-D-007`; all later H06_daily reporting gates remain
in force.

## Reopening condition

Reopen this hierarchy only if the author changes which analysis is primary, a
sealed main-H06 identity or verifier fails, or the completed complementary
analysis exposes a discrepancy that materially affects the main-H06 result or
claim. A different complementary estimate by itself is not such a discrepancy.
