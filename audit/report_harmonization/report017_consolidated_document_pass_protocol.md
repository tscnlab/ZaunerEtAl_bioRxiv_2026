# REPORT-017 consolidated document-pass protocol

Date: 2026-08-14

Author direction: reduce serial correction loops. Review each remaining
reader-facing document completely, assemble all known changes, and implement
them as one coherent source revision before rendering.

## Required sequence for each remaining document set

1. **Complete read-only review.** Read the current handoff, full result source,
   full preparation/provenance companion, current focused tests and manifests,
   all displayed table and figure endpoints, captions, alt text, dynamic links,
   and the latest rendered HTML when one exists.
2. **Single consolidated change matrix.** Record every source-visible language,
   structure, link, site-label, terminology, table, figure, test, and direct
   manifest repair that can be identified before rendering. Distinguish
   scientific discrepancies, which stop the document, from display-only and
   provenance-only work.
3. **One owner source order.** Dispatch the complete approved matrix in one
   bounded order. The owner returns one coherent source revision and all
   directly dependent source tests and manifests. Do not issue incremental
   wording or test orders while that revision is underway.
4. **One source acceptance.** Review the complete returned document set and run
   all applicable source-only checks together. If several correctable defects
   are found, inspect the entire source first and return one combined correction
   order rather than one order per failed assertion.
5. **One targeted render per page.** After source acceptance, render each page
   once through the Nature Health profile. Result and companion pages may still
   use separate target commands when the project contract requires it, but the
   source revision and acceptance remain document-set-wide.
6. **One complete render review.** Inspect the full rendered page at desktop and
   narrow viewports, all native HTML tables, exported PNG table artifacts where
   those are the publication outputs, figures at final size and 200%, captions,
   alt text, navigation, and links. Collect all newly exposed display defects
   before issuing one combined display correction.

## Exceptions

An additional loop is allowed only when:

- a scientific discrepancy is newly exposed and requires the scientific
  owner or coordinator;
- a defect depends on actual rendered layout and could not reasonably be
  established from source or static output inspection;
- an external shared file changes after the consolidated preflight; or
- a fail-closed preservation check detects genuine identity drift.

Stale test wording, predictable manifest dependencies, terminology updates,
dynamic-link repairs, country-coded site labels, and known figure-label changes
must be included in the consolidated pre-render source order.

## Coordination safeguards

- Update the coordination matrix before sealing an owner order, or treat its
  hash as informational. Do not invalidate an order by changing its pinned
  matrix immediately after dispatch.
- Pin only inputs that are materially part of the document's implementation or
  preservation contract.
- Keep one owner active at a time, but perform the complete read-only audit for
  the next document before dispatching its source order when this does not touch
  shared state.
- Preserve the no-scientific-recomputation, no-full-render, no-commit, and
  owner-boundary rules.

## Immediate application

Order 31i may finish because all three prescribed tests already pass and only
its final non-circular seal remains. Before any further H01 source order or
rerender is released, perform one complete H01 result-and-companion review and
consolidate every remaining source, test, manifest, table, figure, link, and
visual requirement. Apply this protocol to H02 and every later document set.
