# Order 71c candidate harness stop

Date: 2026-09-03

Status: `RESOLVED_WITHOUT_PRODUCTION_WRITE`

The first candidate invocation stopped while locating the accepted landing-page metadata block. The inherited Order 70 helper required one author metadata tag, while both the accepted Order 70 landing shell and the accepted final manuscript contain exactly 28 ordered author metadata tags. The stop occurred before the candidate landing or download was replaced.

The isolated candidate tree was then rehashed against the accepted Order 70 build inventory. All 893 files were exact and the tree contained zero symlinks. The production landing, production Word download, and 37-row corpus manifest also remained at their sealed preimage identities, as recorded in `candidate_initial_stop_production_reverse_proof.csv`.

The coordinator authorized one constrained locator correction. The site-side locator now enumerates exactly 28 positive author-metadata positions and uses the first position as the retained metadata-block boundary. The manuscript-side 28-element guard is unchanged. Because the two accepted metadata blocks are byte-identical, the resynchronization records this as an exact retained block rather than forcing a content change.

A second harness assertion confirmed that this retained metadata block was already byte-identical. It also stopped before any candidate transformation or production write. The candidate copy was still exact at that boundary. The no-op case was then expressed as an identity guard, with no output-byte effect.

No Quarto, Pandoc, knitr, QMD, scientific code, table code, figure code, or manuscript source was executed or edited.
