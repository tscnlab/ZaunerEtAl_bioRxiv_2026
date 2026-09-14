# H02 order 33b masked-test review

Date: 2026-08-14

Scope: read-only review of the complete remaining H02 source-only test paths after the stopped order 33a return.

## Finding

Order 33a corrected all seven failures reported by order 33. Its single verifier reached 40 of 42 audit checks and one of three focused tests. The two reported failures were old test-harness defects that had been masked by earlier stops:

1. The reader test searched for a one-line fixed hypothesis string, but the accepted source wraps that statement across two Markdown blockquote lines.
2. The preparation test passed a Markdown phrase containing `**` to PCRE without escaping the asterisks.

A full temporary-copy replay then exposed two additional masked classifications farther down those same tests:

3. The reader test applied its historical-terminology exclusion to executable R source as well as reader prose. It therefore rejected the protected code-only names `manuscript_prepared_stability.csv` and `manuscript_prepared_data__glasses__all_available`.
4. The preparation test searched raw chunk text for function-call spellings. It therefore interpreted the displayed table string `mgcv::bam()` as an executed model call.

These are test classifications, not document or scientific discrepancies. The accepted QMDs, formulas, endpoints, values, artifacts, and scientific-call boundary remain unchanged.

## Complete temporary replay

Temporary copies of both source-only tests were changed only in memory-equivalent files under `/private/tmp`. The replay used R 4.6.1 and the project root as the read-only input.

The temporary corrections were:

- remove leading Markdown blockquote markers and collapse whitespace before matching the exact registered hypothesis;
- inspect reader-visible prose outside fenced code for historical reader terminology;
- collapse whitespace and use a fixed literal match for the Markdown model-frame definition;
- parse every R chunk and recursively inspect actual call heads, including namespace-qualified calls, rather than scanning strings and comments for call-like text.

Commands:

```text
NATHEALTH_PROJECT_ROOT=<project-root> H02_REPORT_SOURCE_ONLY=true Rscript --vanilla <temporary-reader-test>
NATHEALTH_PROJECT_ROOT=<project-root> H02_REPORT_SOURCE_ONLY=true Rscript --vanilla <temporary-preparation-test>
NATHEALTH_PROJECT_ROOT=<project-root> Rscript --vanilla <temporary-paired-placement-test>
```

Outcome:

- reader-report source-only test: PASS;
- preparation-report source-only test: PASS;
- paired-placement display test: PASS;
- combined exit status: 0.

No project file was edited by the temporary replay. No QMD was executed. No model, prediction, bootstrap, Shapley allocation, p-value, table, figure, or source-data artifact was calculated or regenerated.

## Disposition

Issue one final consolidated test-only H02 correction. Apply all four classifications together and run the complete order-33 verifier once. If it passes, complete only the non-analytical final seal. Do not reopen the accepted H02 source rewrite.
