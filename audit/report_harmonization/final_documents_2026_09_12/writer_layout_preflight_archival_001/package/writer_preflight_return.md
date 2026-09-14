# Writer layout preflight: complete, implementation held

Date: 2026-09-12. Task: Nature Health manuscript Writer.

This is the single consolidated read-only return requested by the coordinator's
`consolidated_planning_disposition_001/disposition.md`, SHA-256
`027312e79404c42838c1bcc35f74e650d67843b26364e3066f5664a932e0cbc3`.
Its dispatch manifest is
`c2a946ec8c8c1d3ca3be715695dc7c3e4af908b5287a7dee985eae0c784c292f`.
All 34 dispatch members and all 178 distinct source/input pins checked here
are exact. This accepts the preflight identities, not the proposed layout or
the current document as final.

All work is contained in the new temporary directory
`/private/tmp/nature-health-layout-preflight.yMAKmA`.
No live source/helper was changed, no QMD was executed, no model or scientific
verification was run, and no DOCX/HTML was rendered, captured, assembled,
embedded or exported. No browser, Word session, server, office converter or
visual lease was opened. No historical allowance was reset. The previous
native review remains closed. The only JavaScript process was Node's syntax-only
`--check` on a prospective file whose entrypoint is deliberately disabled.

## Main findings and proposed repairs

The S2 source is already correct: all 170 mean ± SD units are complete nowrap
spans. The two downstream CSS copies and image helper override that property,
and the native exporter discards it. The proposed width-first repair keeps the
existing semantic source and all three complete-width parts. It widens numeric
columns inside the same 1490 px total width, preserves each whole expression,
and converts only allowed internal spaces to NBSP in the editable Word table.
The exact conditional one-point conversion is recorded separately. It is not
a global font reduction and has not been applied.

The blank pages around S2 have a confirmed section mechanism: adjacent
landscape ranges insert two empty portrait sections before S2 and S3. In the
reviewed f055 document those are body nodes 514 and 525, section positions 8
and 10. Both are `nextPage`, not odd/even breaks. The proposed removal preserves
the intervening bookmarks and creates direct A4-landscape / A3-landscape /
A4-landscape transitions. The explicit section map changes from 31 to 29;
all 13 top-level new-page starts remain.

Image and caption paragraphs inherit the reference body style's 1.5-line
spacing. The proposed fix is paragraph-only single spacing and appropriate
heading/caption keeps, preserving body prose, font sizes, all text and all
reference-document conventions. These changes address the main and supplementary
caption findings together. They remain subject to actual pagination QA.

S7's long third image is reduced by the height cap from the preceding parts'
10.55-inch width to 7.24 inches. The proposal reuses parts 1/2 exactly and
replaces the final part with two new, equal-scale parts. That is a four-part
table-image map, not a native-table-content change. The native S7 DOCX can be
reused unchanged. S7's figure caption is separately proposed for placement
after A and before the independently page-starting B in Word, with its exact
wording and both SVGs preserved.

## Package contents

- `layout_change_matrix.md`: every native finding, exact cause, proposed change,
  protected content and verification/stop condition.
- `prospective_changes.diff` and `diffs/`: one combined and four per-file unified
  diffs against pinned live sources. No diff has been applied to a live file.
- `prospective/`: the same proposed helper/CSS postimages. Python/JavaScript
  generation entrypoints are disabled. They are not runnable instructions.
- `static_diff_checks.json`: both Python files parse; changed existing functions
  are confined to the declared layout/export allowlists; unmodified SVG handling
  and bookmark functions remain exact; the complete 17-entry screen-reader
  contract is exact; Node syntax passes; every diff round-trips both texts.
  CSS brace balance is only a structural check, not browser visual acceptance.
- `input_identity_preflight.csv` and `input_identity_postflight.csv`: all 178
  exact, deduplicated inputs, including the current helper preimages, source
  fragments, 19 native tables, 29 image parts, 22 SVG files and reviewed f055.
- `final_docx_paragraph_geometry.csv`, `final_docx_styles.csv`,
  `focused_paragraph_geometry.csv`, `section_boundaries.csv` and
  `prospective_section_map.csv`: read-only OOXML evidence for the actual
  spacing, section sequence and blank-page mechanism.
- `s2_protected_mean_sd_units.csv`, `s2_mean_sd_part_contract.csv`,
  `s2_proposed_column_geometry.csv`, `s2_point_conversion.csv`: exact existing
  no-break-unit inventory and prospective physical geometry. These contain
  copied display tokens and layout arithmetic, not recalculated research results.
- `old_image_part_dispositions.csv`, `prospective_s2_s7_part_map.csv`,
  `editable_table_reuse_and_source_bindings.csv`,
  `svg_source_bindings_and_dispositions.csv`: complete reuse and replacement
  mapping with exact source identities. Unaffected native tables and image
  parts are not unnecessarily regenerated.
- `part_count_contract_UNRESOLVED.json`: complete 19-key prospective part map,
  with null Brown-dependent entries that intentionally prevent assembly.
- `serial_qa_plan_NOT_EXECUTED.md`: one serial future generation/QA sequence,
  automatic renderer argument/count contract and focused final native session.
- Read-only inspection, validation and sealing scripts plus their session
  records. The first XML inspection attempt is preserved with its stop note;
  it was corrected before producing inspection output. No document was changed.

## Counts and reusable evidence

There are 29 existing table-image parts and 19 native DOCXs. Outside the Brown
dependency set, the proposed new image production is limited to three S2 parts
and two S7 tail parts. Reuse the first two S7 parts and all other unaffected
table images byte-exact. All unaffected native DOCXs retain their existing
visual evidence; only S2 and the accepted changed Brown table set are re-exported.

The prospective fixed non-Brown table-image count is 26. The final count is
`26 + b(Table 2) + b(S3) + b(S4)` after accepted Brown scope reconciliation. If
those remain 1/1/2, the count is 30 table images and 53 total drawings under the
unchanged 23-appearance figure contract. This is conditional, not a fabricated
final count. All 22 current SVG file identities and 23 appearances are mapped.
S5 is held; S4/S6 need Brown-scope confirmation; optional H11 replacement stays
excluded and accepted S17 remains the intended source.

The proposed initial automatic QA count is `2 + |B|` document commands, where B
is the accepted changed Brown native-table set. Each command can internally
make up to three serial office conversion attempts, explicitly recorded in the
plan. The whole main document is checked automatically; only the SVG-critical
appearances need a focused final native Word compatibility session. No repeated
manual author-opening workflow is needed for ordinary table QA.

## Outstanding prerequisites, not new author-writing decisions

1. Accepted Brown alignment results and exact downstream scope. Brown is already
   working under its own continuation; it has not been redispatched here.
   Neither Table 2 nor historical S5 is replaced by this preflight.
2. A genuinely permissible capture route or an explicit author-supplied artifact
   with source/layout proof. The existing browser denial remains binding. The
   supplied disabled legacy helper is not a workaround.
3. Coordinator approval of the consolidated prospective changes, resolved maps,
   fresh finite execution allowances and the internal office-fallback budget.
4. Harmonizer's separate 37-route dependency/freshness reconciliation and staged
   source/download consistency. The stale root and placeholder supplement must
   not be reinstated by a blind project render.

The Word file that remains open is still the unchanged non-S5 preview f055:
`audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/Nature_Health_non_S5_preview_attempt1.docx`,
SHA-256 `f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c`.
It is not relabelled final. Final handover still means the main Word, all 19
editable table documents and ZIP, plus the complete source-consistent 37-route
website and a clear link index.
