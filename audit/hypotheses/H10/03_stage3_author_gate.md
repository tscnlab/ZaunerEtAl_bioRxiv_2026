# H10 reader-report author gate

Date: 2026-08-10  
Gate: **H10-G3 — approved**

## Decision received

The author explicitly approved the H10 reader report after review and directed
the task to continue to the analysis-preparation and provenance companion. The
approval includes the subsequently requested display-only repairs to the H10
overview figure: wrapped metric labels and separate zero-inclusive x-ranges
for the three association facets. No estimate, confidence interval, p-value,
multiplicity decision, sample, diagnostic, sensitivity result, or scientific
interpretation changed.

## Deliverable ready for review

The standalone reader-facing report is:

- source: `notebooks/hypotheses/H10.qmd`;
- rendered HTML:
  `_build/nathealth/notebooks/hypotheses/H10.html`.

The report opens with the exact “Answer in brief” callout and presents the
question, construct distinction, estimands, model rationale, exact formulas,
response specifications, four separate 17-metric BH families, exact fitted
samples, 95% confidence intervals, primary near-eye results, complementary
chest results, site heterogeneity, interpreted diagnostics with explicit
acceptability, placement-matched evidence, the gap-timing-unaware dataset,
preregistration exclusions, metric-specific checks, and limitations. It does
not discuss implementation history or alternative report constructions.

At the author's request, the report now includes a V0-like but inferentially
corrected overview: participant age distributions by submitted site order and
colour, all 11 adjusted main findings, and the site-specific components of the
two adjusted age-by-site results. Age distributions contain one row per
participant rather than repeated participant-day rows, and no unadjusted
pooled smoother was introduced. The figure has a de-identified paired source
CSV and separate PNG/PDF exports.

The reader report uses the author-approved Gaussian/identity response for
pre-sleep TBT10 and reports age per decade through `age_decade = age / 10`.
The latter is a unit change only and does not alter fitted values or
inferential p-values. Measured biological sex and gender remain conceptually
distinct; gender was not substituted or inferred.

## Verification completed

- H10-only Quarto render under R 4.6.1 and the project library: PASS.
- Frozen numerical-package SHA-256 identities: PASS.
- Scientific result, sample, confidence-interval, multiplicity, diagnostic,
  sensitivity, terminology, and p-value regression checks: PASS.
- Eight final-size 170-mm figure proofs: PASS for clipping, overlap,
  distortion, wrapping, balance, and essential-text readability.
- Compiled HTML structure: eight 100%-width figures with captions and detailed
  alt text, 12 compact `gt` tables, and 17 resolved local CSV links: PASS.
- Automated visual navigation to the local-file HTML was blocked by browser
  security policy and was not bypassed. The author-facing HTML is part of
  this approval request.
- New inferential model fitting, prediction, simulation, bootstrap, and other
  resampling: none.

The current input qualification remains explicit: PREP-003/FIND-044 says the
current Preparation 06 model-ready layer, METRIC-010 MDER values, and
METRIC-011 L10 normalization are independently verified, while complete
independent reconstruction of the exact current state-support classification
remains open. This is a provenance qualification, not evidence of incorrect
data.

## Post-approval METRIC-010 amendment and gap repair

On 2026-08-11, the reader report was selectively refreshed for the controlling
mean-of-viable-minute-ratios MDER estimand. Only MDER-dependent models,
diagnostics, sample comparisons, multiplicity slots, tables, and figures were
recomputed. Sixteen exact non-MDER identity guards passed, and no retained main
or interaction conclusion changed. The report now gives current MDER samples,
95% CIs, primary and gap-timing-unaware results, direct distribution and
influence assessments. FIND-049/CHG-101 subsequently repaired the shared
gap-timing-unaware MDER input: every finite value is now strictly positive,
and `THUAS::THUAS_S002` on 2025-03-09 at chest is reason-coded missing rather
than stored as zero. The bounded reseal refitted only corrected gap MDER and
revised common-sample branches; frozen primary MDER and all non-MDER identity
guards passed. No resampling was used.

## Coordinator handoff proposals

The H10 worker did not edit coordinator-owned ledgers or shared Quarto files.
The coordinator may record:

- H10-G2 approved by the author on 2026-08-10;
- H10 standalone reader report produced, verified, and approved on
  2026-08-10;
- H10-G3 approved and the analysis-preparation and provenance companion
  authorized on 2026-08-10; and
- website/navigation integration remains coordinator-owned and is requested
  separately after the H10-owned companion has passed its pre-integration
  checks.

## Post-approval METRIC-011 reseal

On 2026-08-12, the reader report was selectively resealed for METRIC-011. Eight
primary L10 means were normalized from numerical noise to exact zero. Only the
affected primary L10 branches, complete 17-test BH families, source-data
displays, and frozen-residual diagnostic pages were refreshed. Fifteen frozen
identity guards passed; no non-L10 raw p-value, MDER model, sample, or
significance decision changed. The report still retains 11 adjusted main
findings and two adjusted chest age-by-site interactions. Its targeted render
completed 47/47 operations, and all eight final-size figure proofs passed.

## Authorized continuation

This approval authorizes the H10 analysis-preparation and provenance companion,
bounded rendering checks, reciprocal H10 links, and an exact request for
coordinator-owned website integration. It does not authorize edits to shared
website configuration, central ledgers, manuscript files, other hypotheses,
or any new inferential analysis.
