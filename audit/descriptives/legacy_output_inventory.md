# Earlier descriptive-output inventory

Source reviewed: root-level `Descriptives.qmd`, its read-only helpers, the
rendered `docs/Descriptives.html`, and the existing example images. No old
serialized `.RData` workspace was loaded. The complete machine-readable
inventory is `legacy_output_inventory.csv`.

## Governing replication decisions

1. Reproduce the recognizable submitted layouts with the updated verified
   data: the wide participant/site table, wide metric table with miniature
   distributions, five-part overview, 3 × 3 site profiles, 4 × 4 metric grid,
   four-panel time-series explanation, latitude diagnostic, and contextual
   light table.
2. Preserve the submitted site labels, order, and colours through the shared
   DISPLAY-001 registry at `config/site_display_registry.csv`. Internal data
   codes remain unchanged. A missing site is omitted without reordering or
   recolouring the remaining sites.
3. Repair rather than copy errors. The updated table separates near-eye and
   chest denominators, corrects the duplicated near-eye non-wear input in the
   earlier chest calculation, uses the correct chest coverage stage, fixes the
   MPI/TUM display swap, and gives every statistic an explicit denominator.
4. Use verified one-minute values for time-of-day profiles and verified metric
   artifacts for metric summaries. Near-eye is primary; chest is
   complementary; placements are never pooled.
5. Keep the old 48-hour double-plot form as a display replica, but base it on
   participant-balanced daily profiles. Bands are exact pointwise 95%
   confidence intervals for the participant median, not unlabeled empirical
   observation ranges.
6. Use circular summaries for clock time. A rebuild-specific
   `stats::quantile()` argument typo was detected and corrected before final
   generation; its repair proposal is recorded separately.
7. Retain the same seven time-series exemplars and Wednesday–Sunday structure.
   Actual local dates remain in source data, 30-minute means are verified, and
   daily metrics are joined from the approved artifact rather than recalculated.
8. Preserve the recommendation-table organization but describe fractions of
   valid minutes in contextual ranges, not adherence or compliance. During
   diary sleep, bedside values describe the sleep environment rather than
   direct ocular exposure. The old chest recommendation table is retired.
9. Retire only redundant deliveries that add no construct: the two reduced
   Table 1 variants, separate site PDFs, and letter-only individual metric
   exports. Exact values and panels remain in the full replicated tables,
   composite figures, and source CSVs.

## Difference coverage

`output_difference_explanations.csv` covers all 22 inventoried tables,
figures, panels, and export batches. Cell-level comparisons cover all 220
current participant/site cells, all 170 metric/site cells, and all 80
recommendation-context cells. The four prior rendered tables are also stored
as display-only CSV snapshots under `audit/descriptives/` so every comparison
can be repeated without reading old analytical workspaces.
