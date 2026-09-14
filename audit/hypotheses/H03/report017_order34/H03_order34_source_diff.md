# H03 order 34 exact source-difference record

Date: 2026-08-14

Comparator: the two exact preflight identities in REPORT-017 order 34.

## Result source

The result source changed only in the authorized editorial structure and
display vocabulary:

1. Added `lightbox: true`.
2. Shortened the opening answer and moved the existing seven category and six
   supported site-deviation inline lines to `## Detailed analysis record`.
3. Moved `tbl-h03-overall-samples` and `tbl-h03-category-support` to that
   record without changing their chunks.
4. Made `fig-h03-primary-estimates` and `tbl-h03-primary-results` the first
   figure and table endpoints.
5. Replaced reader-visible historical interaction, participant, site-style,
   and multiplicity labels with the approved terms.
6. Added the one authorized companion-anchor link.
7. Wrapped the exact detailed endpoints in the four authorized disclosures.

Structural comparison against the preflight source found no added or removed
chunk labels, inline-R expressions, top-level assignments, artifact
references, source-data references, or numeric tokens. The endpoint set is
unchanged at 14 tables and eight figures.

## Companion source

The companion source changed only in the authorized synchronization and
display layer:

1. Added `lightbox: true`, the reader-oriented opening heading, shared
   country-coded site wording, and display recoding of verification states.
2. Added read-only access to the accepted auxiliary summary, Shapley,
   nested-fit checks, diagnostics, environment, and six-file manifest. The
   model file itself is verified through that manifest.
3. Added one anchored auxiliary subsection and one `gt` endpoint immediately
   after descriptive fixed-effect model performance.
4. Added one script-map row and seven exact auxiliary output-map rows.
5. Added reader-facing labels for the estimand, multiplicity, script, output,
   and render-boundary tables.

The exact structural additions are:

- chunk label: `tbl-h03-prep-participant-random-intercept`;
- top-level assignments:
  `participant_random_intercept_summary`,
  `participant_random_intercept_shapley`,
  `participant_random_intercept_model_checks`,
  `participant_random_intercept_diagnostics`,
  `participant_random_intercept_environment`,
  `participant_random_intercept_manifest`,
  `participant_random_intercept_expected_files`,
  `participant_random_intercept_paths`,
  `participant_random_intercept_fit_checks`, and
  `participant_random_intercept_display`;
- artifact references: the accepted model RDS, summary CSV, Shapley CSV,
  nested-model-check CSV, diagnostic CSV, environment CSV, and six-file
  manifest CSV; and
- numeric tokens new to the preflight set: stored diagnostic labels `0.288`
  and `0.398`, plus the display-only column width `52`.

No inline-R expression or source-data reference was added or removed. The
formula addition in the companion is the already accepted auxiliary formula,
`geo_medi_1h ~ site * light_source + (1 | participant)`. The combined result
and companion formula set therefore preserves the accepted scientific corpus.

## Endpoint delta

| Document | Tables before | Tables after | Figures before | Figures after | Authorized delta |
|---|---:|---:|---:|---:|---|
| Result | 14 | 14 | 8 | 8 | Reorder only |
| Companion | 26 | 27 | 4 | 4 | One auxiliary table |

No figure, source-data file, scientific artifact, historical manifest, or
rendered output changed.

