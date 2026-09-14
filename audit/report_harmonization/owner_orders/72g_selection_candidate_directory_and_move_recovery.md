# REPORT-018 Order 72g: candidate-directory and move recovery

Date: 2026-09-11

Status: SEALED FOR ONE HARMONIZER CONTINUATION DISPATCH.

Executor: Harmonizer task 019ff52e-48ac-77b3-9a0e-9a87749a3bba.

Order72f's sole render succeeded. The subsequent move stopped because its
destination directory did not exist. The coordinator independently reproduces
the intact candidate, unchanged source and old canonical HTML, and absent
destination directory. This is a directory-sequencing defect, not permission
for another render or source change. The successful-render allowance is now
consumed.

## Exact frozen endpoints

Candidate source:

    audit/manuscript_nature_health/manuscript_figure_table_selection_order72f_candidate.html

SHA-256 7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4,
29,370,696 bytes.

Selection QMD remains SHA-256
9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3,
49,865 bytes. The old canonical selection HTML remains SHA-256
82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6,
30,925,051 bytes. Both paths are those named in Order72f.

Rehash this order's release manifest, the complete nested Order72f 91-row
release and all three current endpoints before acting. Preserve all historical
72e/72f contracts, source checks, preimages, render output and failed-move
evidence. Store new recovery evidence in the existing owner's
order72g_move_recovery/ subdirectory, not over old logs.

## Directory creation and one move retry

The existing parent must be the exact non-symlink owner root:

    audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/

Require the candidate to be a regular file, the destination directory absent,
and the final destination absent. Create only this missing rendered directory
under the existing owner root:

    audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/rendered/

Verify the resulting directory is not a symlink and is contained in the exact
owner root. Do not create an alternate root, overwrite anything, or remove any
file. With the final destination still absent, retry the same move exactly
once from the frozen candidate source to:

    audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/rendered/manuscript_figure_table_selection.html

Record pre/post SHA-256 and bytes, require the exact candidate identity above
at the destination, and require the temporary sibling source to be absent.
Rehash the QMD and old canonical HTML, which must remain exact. A failed move
must preserve the remaining file state and stop without a second retry.

This is a recoverable relocation of a known new candidate, not deletion,
regeneration, content modification or canonical HTML promotion. No Quarto,
Pandoc, source edit, SVG/table regeneration or computational engine is allowed.

## Continue the already authorized acceptance path

After an exact successful move, continue the full Order72e/72f verification,
conditional candidate-only semantic normalization if needed, bounded loopback
visual QA, teardown and post-QA preservation checks. Those contracts and all
20 SVG identities, 19 retained gt tables, 22 total tables, 11 disclosures,
Table 3 ordering, captions, alt text, local links and scientific holds remain
unchanged. Do not patch a new finding or rerender.

The canonical old HTML may be replaced once only after the complete existing
candidate acceptance contract passes. Return at
REPORT018-ORDER72E-SELECTION-SVG-PREVIEW-REVIEW with the combined non-circular
seal. This directory-only amendment does not accept the page in advance.

Writer Order72d, all production outputs, hypothesis/Brown files, scientific
inputs and artifacts, packages/lockfiles and the Brown scientific reopening
remain outside this release. No other task is dispatched.
