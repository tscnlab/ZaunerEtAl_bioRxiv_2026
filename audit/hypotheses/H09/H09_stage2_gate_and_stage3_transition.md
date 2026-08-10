# H09 Stage 2 gate and Stage 3 transition

Date: 2026-08-10

Decision ID: **H09-002**

Status: **Stage 2 approved as amended; Stage 3 authorized**

## Author decision

The author accepted the H09 Stage 2 gates with one amendment. After visually
inspecting Figure 2 (near-eye diagnostics) and Figure 3 (chest diagnostics),
the author judged the response/residual distributions and residual
heteroscedasticity “good enough” and directed that the final assessment be
changed from **not acceptable** to **acceptable**.

The decision applies to both diagnostic domains for all 24 primary
metric-by-instrument-by-placement targets:

- `Response and residual distribution`: final assessment `acceptable`;
- `Residual heteroscedasticity`: final assessment `acceptable`.

## Audit-preserving implementation

The decision changes the interpreted verdict, not the observed diagnostic
quantities. The original quantitative screen results remain in
`artifacts/08_diagnostics/H09/H09_residual_diagnostics.csv`. The complete
mapping from each screen result to the final author assessment is stored in
`artifacts/08_diagnostics/H09/H09_diagnostic_author_adjudication.csv`, and the
final assessment plus its basis is stored in
`artifacts/08_diagnostics/H09/H09_diagnostic_assessment_registry.csv`.

The amendment does not change any model specification, fitted sample, model
object, estimate, 95% confidence interval, p-value, multiplicity family or
decision, sensitivity estimate, figure source data, or resampling decision.
It changes the overall target summary from 10 acceptable and 14 not acceptable
to 18 acceptable and 6 not acceptable.

The six remaining not-acceptable targets are unchanged:

- both near-eye last-timing targets have direction instability under
  participant-deletion and leave-one-site-out checks;
- all four registered longest-period targets lack the registered outcome in
  the gap-timing-unaware prepared artifact; and
- chest longest-period/MEQ additionally has a singular ML interaction fit.

## Transition

H09-002 authorizes creation of the standalone reader-facing
`notebooks/hypotheses/H09.qmd`. That report must remain gated for separate
author approval before the analysis-preparation and provenance companion is
created.
