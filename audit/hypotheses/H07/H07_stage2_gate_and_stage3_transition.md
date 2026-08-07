# H07 revised Stage 2 gate and Stage 3 transition

Decision ID: `H07-003`
Date: 2026-08-07
Status: approved

## Evidence approved

The owner explicitly approved the H07 author gates and instructed the worker
to continue after reviewing the revised Stage 2 package, including the paired
fitted-value and derivative figures:

- `audit/hypotheses/H07/02_implementation_and_v0_comparison.qmd`, SHA-256
  `b6489eb8ffd78b6f96493d296d88da73ae18ddfb2bb36d56540d044a6b319680`;
- `audit/hypotheses/H07/02_implementation_and_v0_comparison.html`, SHA-256
  `e5e7b22e94253783c26224b82200778533d6f39caf3d4bf036888834161d4002`;
- decision `H07-002` and its post-result derivative-defined plateau rule; and
- H07-S2R-001 through H07-S2R-008 as displayed in the rendered report.

## Approved dispositions

1. `H07-S2R-001`: the registered latitude--photoperiod analysis is
   structurally non-identifiable because absolute latitude is determined by
   site. Adapted association and shape p-values remain withheld because of
   extreme concurvity. These are interpretation limitations, not gates that
   suppress the descriptive derivative pattern.
2. `H07-S2R-002`: report the post-result derivative-defined plateau pattern
   for six of nine primary near-eye metrics and seven of nine complementary
   chest metrics, with exact transition brackets and absence reasons. Do not
   translate the result into equivalence, an asymptote, a mechanistic ceiling,
   or a causal effect.
3. `H07-S2R-003`: retain the derivative-method, data, model-form,
   exact-period, and leave-one-site-out findings as visible sensitivity and
   influence limitations rather than exclusion rules.
4. `H07-S2R-004`: retain time below 1 lx melEDI during sleep as descriptive
   and non-inferential because its Tweedie model fails the 100-simulation
   zero-mass check. Do not add a result-selected alternative family.
5. `H07-S2R-005`: retain exact `mgcv::gam(method = "REML")`; do not add a
   `bam(discrete = FALSE)` branch or transfer H11's participant-cluster CR1
   method.
6. `H07-S2R-006`: accept the reconstructed historical comparison and the
   distinction between a last detected increase and the approved
   zero-compatible-through-the-recorded-end rule. Construction-history
   material must not enter the Stage 3 reader-facing report.
7. `H07-S2R-007`: run no production simultaneous derivative draw. A future
   full-range curve-wide sensitivity would require a new 100-draw pilot and
   separate production authorization.
8. `H07-S2R-008`: proceed to the standalone Stage 3 reader-facing report.

## Stage 3 boundary

Create `notebooks/hypotheses/H07.qmd` from approved H07 artifacts only. It must
contain an Answer in brief callout, plain scientific prose, exact samples,
95% intervals, readable tables, accessible paired fitted-value/derivative
figures with source CSVs, interpreted diagnostics, and the approved
sensitivity limitations. It must contain no historical-version,
construction-history, gate, or audit-workflow language.

Stage 3 must stop for explicit owner approval. Do not create
`audit/hypotheses/H07/H07_analysis_preparation.qmd` until that approval.
