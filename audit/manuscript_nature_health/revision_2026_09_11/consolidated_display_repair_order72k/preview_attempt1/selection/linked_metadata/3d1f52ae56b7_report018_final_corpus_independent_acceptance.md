# REPORT-018 final corpus independent acceptance

REPORT-018 is independently accepted as a complete 37-page reader corpus with
documented residual legacy accessibility limitations.

## Corpus and manifest

The Phase 4 corpus manifest was rebuilt exactly once through the registered R
4.6.1 navigation-contract builder. The historical preimage remains preserved
at SHA-256
`73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334`.
The current 37-row manifest is
`audit/report_harmonization/phase4_corpus_manifest.csv`, SHA-256
`983b16136c1115d5a6b8dceb135c10de8d347743c694c5027c4ead9b2c7aa605`.
All 37 registered sources and all 37 registered HTML targets exist and match
their current manifest hashes. Logical, sidebar, and intentional render order
are exact.

The final live-corpus checker is
`scripts/report_harmonization/check_report018_final_corpus_integration.R`,
SHA-256
`e55a59df29ea2f382262b54c4520afaa382356ea7c91dc562f4d5f4140240218`.
It passes six of six domains under R 4.6.1.

## Structural and integration disposition

The integrated corpus contains exactly 572 native `gt` tables, 46,120 table
header tokens, 160 figures, and 10,192 local links. Every page has exactly one
reader `main` element. All local paths and fragments resolve within the build,
and no rendered error node is present.

Six current structural tests pass. Three unchanged historical gates stop on
their exact retained pre-integration assumptions: H01 table-render status, the
Phase 2 table inventory, and the pre-overlay Preparation link prohibition.
Their outputs and classifications are sealed. They do not establish a current
reader, link, or scientific defect.

The final integration step did not run Quarto or change any reader source,
HTML, scientific artifact, profile, package, or lockfile. Pre- and
post-integration build inventories are byte-identical at SHA-256
`bc1656c63470deefeae55bfd7014035cfbbec11652135667e74bdf5fc51283b7`:
1,180 members, including 871 files and 309 directories, with zero symlinks.
Across 13,087 protected pre-existing paths, only the registered corpus
manifest changed. The only two added protected paths are the bounded
structural runner and final corpus checker. No protected path was removed.

## Residual accessibility limitations

This acceptance does not claim that all legacy pages are fully accessible.
Eight older pages, Preparation 01 through 07 and Descriptives, retain their
exact historical `gt` identifier and `headers` patterns. They contain 5,509
unresolved table-local header tokens and 63 repeated non-SVG identifiers in
total. Every other page has zero such finding. One H06 companion table is a
valid header-only, scope-based table with five scoped header cells and no data
cells.

The landing page retains 24 informative, captioned images without alt text.
Descriptives has 17 captioned empty-alt images, all explicitly marked
`role="presentation"` and `aria-hidden="true"`. Every other corpus figure
image has nonempty alt text. Exact page-level dispositions are sealed in
`corpus_semantic_disposition.csv`, `corpus_image_alt_disposition.csv`, and
`legacy_accessibility_limitations.md`.

These conditions are accepted as documented residual limitations under the
author's render-completion scheduling boundary. No accessibility repair is
inferred or claimed.

## Coordination transition

The shared coordination row moved from
`idle_sensitivity_battery_order62_independently_accepted_awaiting_final_corpus`
to
`complete_report018_final_37_page_corpus_accepted_with_documented_legacy_accessibility_limitations`.
The matrix transitioned from SHA-256
`01b3438ff097c7ea31486f20932ec3fed72e2eac0361732ada3bedc69408d960` to
`63b5f469c0270cd0c8d5570591e69f1b35c0b96e291ffb28c879ada95c43a582`.

REPORT-018 render and integration work is complete. Existing document-level
author-review or principal-output statuses remain governed by their own
accepted records and are not broadened by this corpus-level closure.
