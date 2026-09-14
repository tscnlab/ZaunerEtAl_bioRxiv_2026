# H10 Stage 2 author decision

Date: 2026-08-10  
Gate: H10-G2, Stage 2 to Stage 3  
Status: **approved**

## Decision received in the H10 task

After reviewing
`audit/hypotheses/H10/02_implementation_and_v0_comparison.html`, the author
explicitly approved Stage 2 and directed the task to continue.

This authorizes creation and bounded rendering of the standalone reader-facing
Stage 3 report at `notebooks/hypotheses/H10.qmd`, using the verified H10 Stage
2 artifacts and accepted interpretations. Stage 3 must retain:

- the Gaussian/identity response model for pre-sleep TBT10;
- age reported per 10 years through `age_decade = age / 10`;
- the measured biological-sex construct, with Female-minus-Male contrasts and
  no substitution or inference of gender;
- common site-adjusted associations as the primary estimands and site
  interactions as heterogeneity;
- four separate complete 17-member BH families per placement;
- primary near-eye and complementary chest evidence without pooling or an
  equivalence claim;
- exact fitted samples, model-based 95% confidence intervals, diagnostics,
  sensitivities, and the gap-timing-unaware provenance qualification; and
- paired/common participant-level IS and IV and waking-only MDER as
  unavailable rather than approximated.

The Stage 3 report must stand alone for scientific readers. It must contain an
“Answer in brief” callout directly in or after the hypothesis/question
section and must not discuss V0, construction history, or implementation
variants.

## Boundary

This approval does not authorize Stage 4, shared Quarto configuration or
navigation edits, central-ledger edits, a full-project render, a production
resampling run, a commit, push, upload, or manuscript-path changes. Stage 3
must stop for a separate author decision after its focused render and
verification.

Provenance qualification: `PREP-003` / `FIND-044` remains open. The current
Preparation 06 model-ready layer is independently verified, but complete
independent reconstruction of every current metric value, MDER
classification, and state-support classification remains open. This is not
evidence that the data are incorrect.
