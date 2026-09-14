# REPORT-018 Order 68 raw manuscript semantic stop: independent acceptance

Date: 2026-09-02

Status: `ACCEPTED_VERIFIER_AND_RAW_GT_SEMANTIC_STOP`

## Disposition

The sole nested Nature Health manuscript render completed successfully exactly once. The rendered HTML and raw DOCX exist at their expected canonical endpoints, and byte-identical evidence copies are retained. No second Quarto render is required or authorized.

The raw HTML contains exactly eight duplicated internal `gt` IDs, each occurring twice and shared by exactly the two table endpoints `tbl-plan-h01-metric-synthesis-candidate` and `tbl-plan-person-level-synthesis-gt-candidate`. This is the same raw-render semantic condition accepted on 2026-09-01. It is not a visible-content, source, table-value, figure, citation, or scientific defect.

The historical candidate-first repair script and its shared semantic engine remain byte-identical to the accepted prior package. An independent R 4.6.1 replay against the new raw HTML produced exactly:

- candidate HTML SHA-256 `8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac`, 30,881,505 bytes;
- semantic ledger SHA-256 `225b5d37818850dca9b6cb5dcf39d78e5fd76c1e79745bbf09f981a70a980287`, 70,290 bytes;
- 191 substitutions, comprising 47 `id` and 144 `headers` substitutions across the exact two table endpoints; and
- exact reversal to raw-render SHA-256 `c9156f078af52713a71a58adda545e03687a8b206d164d4d548b93ebae9732ee`.

The normalized DOM excluding only the changed `id` and `headers` values is identical. The candidate has 582 unique document IDs, 19 native `gt` tables, 2,762 table-header tokens that each resolve exactly once within their own table, 20 figure endpoints in the accepted order, 124 resolved internal-fragment links, 74 embedded images, and only embedded `data:` script and stylesheet resources.

## Consolidated verifier disposition

The task-local final-HTML verifier has two evidence-only classification defects:

1. It searches only `figure` elements, although the three main Quarto figures use `div` endpoint containers and the 17 supplementary figures use `figure` containers. Selection must use the exact expected endpoint-ID vector regardless of container element.
2. It requires zero `src` or stylesheet `href` attributes, although a self-contained Quarto HTML legitimately contains embedded `data:` URIs. It must instead require every such resource URI to start with `data:`.

The exact two-hunk prospective verifier is SHA-256 `7054f6da946edf858813378017dd606283dbdf0816e2bc41a8f7237fd681c55c`, 6,657 bytes. It parses and the complete in-memory validation passes against the independently repaired candidate:

`FINAL_HTML_STRUCTURE=PASS tables=19 figures=20 authors=28 ids=582 header_tokens=2762 internal_fragments=124 bytes=30881505 R=4.6.1`

No other masked final-HTML structural failure remains.

## Preservation

The manuscript QMD, nested Quarto profile, bibliography, CSS, source validator, capture implementation, Word postprocessor, accepted navigation corpus, root website, `renv.lock`, and all scientific inputs remain outside this repair. The raw Quarto DOCX remains SHA-256 `b8eeca31794e06c7c2ec2d6a474ae812b77b2b8c2dcadf7d341e3b6178430cdd`, 9,872,181 bytes.

Independent checker:

- `scripts/report_harmonization/check_report018_order68_raw_semantic_stop.R`
- checks: `audit/report_harmonization/report018_order68_raw_semantic_stop_checks.csv`
- result: 21/21 PASS under R 4.6.1

The correct continuation is one no-rerender semantic-repair and production-completion order. It may preserve the stopped verifier before applying exactly the two approved verifier hunks, create and validate one semantic candidate, promote that candidate once, and then resume the unconsumed browser, capture, Word-postprocessing, DOCX, and final sealing stages from Order 68.
