# H01 transition to the four-stage hypothesis workflow

Decision ID: `H01-009`
Date: 2026-08-01
Status: approved

## Decision

H01 follows the same four-stage reporting sequence as the later hypotheses:

1. audit and proposed analysis;
2. implementation and comparison with V0;
3. a standalone reader-facing H01 results report; and
4. a scientific description and provenance record for the H01
   result-producing pipeline.

The completed production bootstrap is an additional computation gate between
Stages 2 and 3. It is not Stage 3 and it does not require a new report merely
to renumber the workflow.

## Existing work mapped to the stages

- Stage 1 is satisfied by the approved H01 preregistration, implementation,
  metric, response-family, multiplicity, model, and prefit gate records. These
  records are retained rather than duplicated in a new document.
- Stage 2 is the accepted implementation and V0 comparison currently rendered
  from `notebooks/hypotheses/H01.qmd`. Before that path is rewritten for Stage
  3, the task preserves the Stage 2 source and HTML as
  `audit/hypotheses/H01/02_implementation_and_v0_comparison.qmd` and its
  corresponding rendered HTML, with exact checksums.
- The required production bootstrap is complete. Its 128 targets and stored
  outputs have passed the focused no-refit verifier. No bootstrap is rerun for
  this workflow transition.
- Stage 3 is now the next action. It rewrites
  `notebooks/hypotheses/H01.qmd` as the standalone reader-facing result and
  stops for author review.
- Stage 4 begins only after Stage 3 is accepted. It creates
  `audit/hypotheses/H01/H01_analysis_preparation.qmd` under `REPORT-007` and is
  integrated into the Nature Health website beside the accepted H01 result.

## Stage 3 requirements

The standalone report contains no V0 comparison, submitted-versus-new
language, internal gate history, discarded model candidates, or construction
variants. It includes:

- the exact preregistered hypothesis and every relevant deviation;
- the question, analysis, rationale, results, interpretation, and limitations
  in familiar manuscript language;
- visible evaluated R cells showing the exact Wilkinson formula objects used
  for every fitted and comparison model;
- near-eye results as primary and the corresponding chest-level figures and
  tables as complementary evidence;
- exact participants, participant-days, observations or hours, and sites for
  every fitted model;
- 95% confidence intervals, the approved 17-test Benjamini–Hochberg families,
  and the approved from-mean site contrasts where applicable;
- final production-bootstrap results read from the verified stored outputs;
- model diagnostics with a plain-language interpretation and an explicit
  acceptable, acceptable-with-limitations, or not-acceptable assessment;
- registered sensitivities, readable `gt` tables, accessible figures, and
  exact paired source data; and
- manuscript terminology, `melEDI` in reader-facing text, `period` rather
  than `bout`, and the submitted-manuscript site names, order, and colours.

Rendering Stage 3 must not refit a model or rerun a bootstrap. Any new
scientific computation requires the relevant earlier gate to reopen.

## Stage 4 requirements

After Stage 3 approval, the H01 pipeline companion follows `REPORT-007` and
the accepted H02 exemplar. It explains the exact data-to-result chain for a
scientific reader using bounded identity checks and lightweight descriptions,
without executing model fits, predictions, or resampling during render. Its
reader-facing content does not label itself Stage 4 or Step 4.

## Reopening condition

Reopen if the preserved Stage 2 report does not reproduce the accepted source
and HTML, if a scientific input, formula, target, draw, interval, diagnostic,
multiplicity result, or claim changes, if Stage 3 reruns accepted production
computation, or if Stage 4 begins before the reader-facing report is approved.
