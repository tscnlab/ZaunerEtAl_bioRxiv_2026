# Metric group-context repair proposal

## Finding

The clean full descriptive build emitted repeated warnings that
`display_unit`, `analysis_unit`, and `site` were unavailable inside
`summarise_one_metric_group()`. The caller used `dplyr::group_modify()` with
its default `.keep = FALSE`, so the grouped columns were supplied in the `.y`
group key and intentionally omitted from the `.x` data passed to the helper.
The helper nevertheless attempted to read those columns from `.x`.

## Consequence

- Clock-time metrics were not recognized as clock time in this path and were
  summarized linearly instead of circularly.
- The branch distinguishing participant-level metrics from participant-day
  metrics did not receive its analysis unit.
- Site was absent from the participant-day key used for the displayed
  denominator.

This affects descriptive summaries, replicated metric-table cells, metric
distribution annotations derived from those summaries, comparisons, hashes,
and prose. It does not alter prepared metric values, inclusion, fitted models,
or shared preparation.

## Proposed repair

Change `summarise_one_metric_group()` to accept the explicit `.y` group key.
Read `display_unit`, `analysis_unit`, and the group site from that key, while
continuing to read metric values and observation identifiers from `.x`. Keep
grouping columns out of the returned one-row summary so `group_modify()` can
reattach them in its documented way.

Add clean-session tests that independently verify:

1. circular timing summaries against a direct circular-centering calculation;
2. participant-level and participant-day denominator branches;
3. non-zero, expected participant-day counts for every displayed metric; and
4. absence of warnings from the complete descriptive build.

## Decision

Approved for repair in the descriptive-only R implementation, followed by a
complete rebuild, cell-comparison refresh, deterministic-output check, and
renewed visual inspection.
