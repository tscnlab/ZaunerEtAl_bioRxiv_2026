# Single primary Table 2 and table-column layout revision

2026-09-13. Owner: Writer, task 019ffb39-372e-7262-bfac-192751fd0e63.
Status: RELEASED_FOR_SOURCE_AND_STATIC_LAYOUT_IMPLEMENTATION.

## Author direction

The author rejects the proposed two-panel main Table 2 and requests one table
for the primary sample, combining descriptive adherence, recommendation
windows, Work-day and Free-day model results, their difference and adjusted
p-values. The attached historical screenshot controls the layout concept,
not the current numerical results. Its SHA-256 is
851eea3e5abbd48cc170a6da1b3ca0eca8f19d11668daec1d84b7cd7b38b41d1.
The author also identifies overly wide/narrow columns, clipping and awkward
or unnecessary line breaks in the seven current manual-source pages.

This supersedes the two-panel Table 2 proposal and its dependent part-count
specifications. Brown scientific and author review remain closed.

## Write boundary

Write new candidate source, HTML/CSS table fragments, source mappings,
verification and delivery files only under the previously absent root:

`audit/manuscript_nature_health/table_layout_revision_2026_09_13/`

Preserve the accepted source integration package, previous manual pages,
historical screenshots, all live manuscript sources, reports, scientific
artifacts, Word files, profiles and website output. Copy the supplied
screenshot into this new root byte-exact as design evidence if useful.

## Table 2

Restore the original three-row, seven-column form, with Daytime, Pre-sleep
and Sleep in that order. The columns are recommendation window, recommendation,
observed valid minutes meeting recommendation n/N (%), Work-day adherence
(95% CI), Free-day adherence (95% CI), Free minus Work in percentage points
(95% CI), and FDR-adjusted p. Retain a clear descriptive/model spanner split.

Use only the primary any-valid accepted model results. Do not include the
80% sensitivity as additional main-table rows, panels or columns. Preserve
its existing report/Supplement and narrative availability. Show one Table 2
label, one native table and one complete proposed image part, not Table 2A/B.

The historical template is
`manuscript/R0_NatHealth/display_assets/table2_brown_adherence.html`,
SHA-256 6f7367bf3e8d5ea657c18f11217a197265311bd08a8292dcbaaad30e8ba41d9a.
The accepted current Writer package is
`audit/manuscript_nature_health/brown_final_integration_2026_09_13/`,
manifest SHA-256 3dcc090cbb74489c15a9df442a5b82cb629c760a5f8dc58d362bed2e3973b8f5.

Bind the current primary model cells to frozen/table_levels_source.csv
(5ce0008819ba241c23682e87554fed9807da157237b7b36e4dc64521976fa326)
and frozen/table_primary_source.csv
(90500204c488451d053c0db35f6c595e5ea8cd851d0899867c3ec439934fa924).
Trace descriptive minute fractions to the accepted descriptive source and
verify them separately. Do not substitute pooled-minute fractions for fitted
period-level estimates. Preserve the accepted equal-site weighting, inclusive
thresholds, measurement-position distinction and current limitations in notes.
Do not import old estimates or p-values from the screenshot.

Widen the Work-day and Free-day columns. Keep estimates and whole confidence
intervals together with deliberate line breaks between estimate and interval
where useful. Rebalance excess whitespace in other columns. Do not solve
width problems by shrinking all text or clipping cell contents.

## Other table pages

Revise the three S2 parts and two S7 tail parts in the new root. Allow coherent
column-width, padding, text-flow, header-break and contained-scroller changes
from the author's feedback. Preserve all rows, cells, group labels, complete
notes, non-colour cues and all 17 embedded S2 PNG payloads byte-exact. Preserve
all 170 S2 mean-plus/minus-SD units as whole units. Retain S2's 16px source base;
do not revive the old 12px override or an unrestricted all-table font reduction.
Use data-appropriate unequal widths and consistent widths across parts.

The new standalone set is six pages: one Table 2, three S2 parts, two S7 tail
parts. Reuse S7 parts 1 and 2. Keep the current S2/S7 row partitions unless a
demonstrable fit problem requires a separately explained change. Do not
regenerate plots, data or inference. Update index/guide wording accordingly.

## Reconciliation and return

Use R 4.6.1 with the accepted library for source-data mapping, joins and all
numerical verification. No model loading, fitting, prediction, new contrasts,
p-values, FDR recalculation, resampling or raw-data reprocessing is allowed.
Record every output cell's source and exact formatting transformation.

Prepare a new candidate copy of the accepted manuscript source with only the
Table 2 includes, caption and directly dependent references changed. Preserve
all other accepted manuscript changes. Update copies of the complete native
table, image-part and drawing maps. Derive counts from the new maps rather
than retaining the previous 31-parts/55-drawings/two-native-table assumptions.
Keep all unaffected reuse decisions exact. The expected change from this
single consolidation is one fewer native table element and one fewer image
appearance; verify this programmatically.

Run complete static table-content, primary-sample, source-identity, header/IDREF,
row-partition, image-payload, reference and preservation checks. Candidate-only
source/layout iterations are allowed within this scope; retain meaningful
failed checks and return one coherent completed source package with a
non-circular manifest and concise change summary. Do not create another
proposal-only memo if the frozen inputs support implementation.

## Visual and production boundary

The synthetic localhost diagnostic passed in the coordinator task, but it
served no research report or previously rejected content. It establishes
browser capability, not a product-side permission resolution for the earlier
blocked capture. This order does not permit a browser/server/office route to
evade that denial. Use the supplied screenshot for direct visual design
evidence. Label source/static checks separately from unperformed visual QA.

No browser navigation, server, screenshot capture, Quarto/QMD execution,
office conversion, native Word assembly, website build/promotion, package or
lock change, commit, push or upload is released here. Request a precise
remaining visual/production disposition after this implemented source package
returns. Do not ask for another Brown scientific approval.
