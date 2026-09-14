# Reader-report render-completion scheduling override

Date: 2026-08-20

Decision ID: REPORT-018  
Status: author-approved render-completion priority

## Decision

After the already active H02 order 33f bounded cleanup reaches its next safe
point, stop opening new REPORT-017 language-harmonization, wording, styling,
test-classification, manifest-reseal, and cosmetic display loops. Preserve all
completed reader-source harmonization. Make successful target rendering and
integration of every reader-facing Quarto document the next priority.

The current H02 exception is limited to the already identified no-rerender
reader-test classification, the existing semantic and preservation checks,
secure-loopback visual QA, and its completion seal. No additional H02 cleanup
is implied.

## Remaining sequence

The authoritative corpus remains the 37-source
`audit/report_harmonization/phase4_corpus_manifest.csv` inventory. After H02
acceptance:

1. render the missing shared `supplementary_information.qmd` target so existing
   reader links can resolve;
2. complete the held H02 companion;
3. complete the current result and companion sources for H03 through H11,
   including the main hourly H06 pair and the complementary H06_daily pair, in
   the established profile order;
4. render the remaining shared `sensitivity_battery.qmd` target; and
5. run one final integrated HTML, navigation, deviation-anchor, download,
   semantic-table, country-label, and build-manifest audit before closing
   DOC-001.

Previously accepted shared, descriptive, preparation, and H01 renders remain
accepted unless a final integration check exposes a broken dependency.

## Hard blockers and deferred findings

The remaining target sequence may stop only for a condition that prevents a
successful or trustworthy integration:

- source, profile, or protected scientific identity drift;
- prohibited model fitting, prediction, simulation, bootstrap, resampling,
  Shapley or dominance recomputation, or scientific-artifact regeneration;
- target-render failure or missing required build output;
- post-render semantic-hook failure, duplicate document IDs, or unresolved
  table header references;
- broken required internal navigation, deviation anchors, source-data
  downloads, or reciprocal result-companion links;
- missing or unusable core reader content, including severe clipping, overlap,
  or navigation failure; or
- incomplete loopback teardown or unclassified build changes.

Language polish, stylistic consistency, optional cross-links, minor visual
refinement, provisional output-role choices, historical manifest drift, and
stale non-scientific test literals are recorded as deferred findings. They do
not start a new cleanup loop. After the current H02 exception, a non-scientific
test mismatch may be classified against the rendered source and HTML without
editing the test when the controlling scientific, semantic, link, and visual
contracts pass.

If one of the hard blockers requires a correction, inspect the full affected
page first and issue one bounded render-enabling correction. Do not reopen a
general language-harmonization pass.

## Safeguards retained

- Render one source target at a time through the Nature Health profile. Do not
  run a full-project render.
- Use normal R 4.6.1 project-profile and `renv` startup and retain the accepted
  post-render `gt` semantic hook.
- Preserve all accepted data, samples, formulas, models, estimates, intervals,
  p-values, diagnostics, sensitivities, multiplicity decisions, source data,
  and scientific claims.
- Use only stored accepted outputs for reader rendering. Do not perform a
  full-project scientific recomputation.
- Verify protected identities and classify the complete target build delta.
- Perform secure loopback QA from a server rooted exactly at
  `_build/nathealth`, bound only to `127.0.0.1`, with desktop and narrow checks,
  then prove complete teardown and post-QA stability.
- Keep principal and supplemental output roles provisional until final author
  review.

## Relationship to earlier decisions

REPORT-018 changes the scheduling and defect-triage portions of REPORT-017 and
the consolidated document-pass protocol for all work after the current H02
cleanup. It does not withdraw REPORT-014 through REPORT-017, undo an accepted
source change, weaken a scientific preservation rule, or authorize a full
render, source rewrite, scientific recomputation, package change, commit, push,
upload, or publication.

Reopen this decision only if the author changes the render-completion priority,
a scientific discrepancy is verified, or the target-by-target approach cannot
produce a complete trustworthy reader corpus without a broader intervention.
