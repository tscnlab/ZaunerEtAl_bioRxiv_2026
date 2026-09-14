# Table 3 author approval and all-`gt` integration

Date: 2026-08-31

## Author decision

The author explicitly approved the revised native `gt` implementation of
manuscript Table 3 in the Harmonizer task. The approval applies to the table
layout and wording shown in the sealed preview. It does not alter data,
estimates, intervals, p-values, model results, samples, or claims.

Approved Table 3 fragment:

- `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html`
- SHA-256: `2f7f6f475d9fe55ee37da3c73aa12474e347ec4619889278fbca0aeab2f40e1c`

Approved visual preview:

- `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate-preview.html`
- SHA-256: `f5519d056e32e698b8d4a70ef9da332b2e81386e2795951587d208b5f30fb07d`

## Integrated selection page

The accepted selection QMD now references the approved Table 3 fragment and
native `gt` replacements for Supplementary Tables S5, S6, and S8. All other
manuscript main and supplementary tables retain their existing native `gt`
fragments.

- QMD: `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`
- QMD SHA-256: `462e1610233185cf3655443cafdc1fd8009ec17646187cae806636815b06e441`
- HTML: `audit/manuscript_nature_health/manuscript_figure_table_selection.html`
- HTML SHA-256: `ad1b29613f2e418e3d61b995993891f0804d523140b5e590bee059c08e92c509`

## Verification

The accepted HTML rendered without Quarto or Pandoc warnings. Verification
used R 4.6.1, `gt` 1.3.0, `knitr` 1.51, and Quarto 1.9.37.

The endpoint audit passed all 13 checks:

- 19 logical manuscript main and supplementary table endpoints;
- 20 native `gt` fragments, because the long H05 table is intentionally split
  into two continued fragments;
- every fragment exists, is included exactly once, contains a native
  `gt_table`, and renders as a `gt` table;
- the old static H02 fragments, old Table 3 fragment, and inline person-level
  Markdown table are absent from the accepted QMD;
- the only three non-`gt` tables in the page are internal planning/status
  tables under author decisions, excluded items, and coordination status.

Evidence:

- `audit/report_harmonization/all_gt_selection_candidate/endpoint_audit.csv`
- `audit/report_harmonization/all_gt_selection_candidate/checks.csv`
- `audit/report_harmonization/all_gt_selection_candidate/render_context.csv`
- checker: `scripts/report_harmonization/check_all_gt_selection_candidate.R`

## Metric-order harmonization

The author subsequently instructed that Table 3 follow the descriptive-table
metric order. Table 3 now orders groups as Duration, Dynamics, Exposure
history, Level, Spectrum, and Timing. Within Timing, First light and Last light
precede Mean timing, matching the descriptive table. This was a row-order-only
presentation change. The R 4.6.1 Table 3 checker passed 14 of 14 checks,
including direct group-order and metric-order comparisons against the
descriptive table source.
