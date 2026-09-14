# REPORT-018 sealed owner order 71a: manuscript wording and accepted display integration

Date: 2026-09-02

Prospective owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_READY_FOR_EXACTLY_ONCE_DISPATCH`

## Release basis

Order 70 is independently accepted and closed under
`report018_navigation_order70f_independent_acceptance.md`, SHA-256
`c25f7b91de9ac22c9ae2d4ddbdd7dd211bad2f5fc6d70ebb0b889fe599a51ff6`,
and its 19-row non-circular seal, SHA-256
`2ab69a9cd569953aa6c2c5919039ec42a7b56b937920452a53e3c3440f344a3d`.
This order may therefore be dispatched once to the Nature Health Writer. It
releases one bounded source and manuscript-HTML integration only. Word and
website work remain held under Orders 71b and 71c.

## Controlling abstract

The complete controlling abstract, after the author's two terminology
refinements, is:

> Personal light exposure has been associated with sleep and non-communicable diseases, yet how ocular exposure varies across the day, among people and between everyday settings remains poorly understood. We analysed 191 adults at nine sites in seven countries; 184 contributed 1,478 participant-days (near eye: 141 adults, 816 days; complementary chest: 154 adults, 902 days). The shared 24-hour near-eye pattern accounted for 78.9% of full-model R², participant patterns 12.9%, participant-day shifts 6.2% and site patterns 2.0%. Reported light source and immediate setting produced large contrasts and had the next-largest shares of fitted-pattern variance after time of day in separate exploratory decompositions (24.2% and 30.7%). Site, civil-photoperiod and person-level associations were metric-specific rather than uniform. Only 24.0% of daytime minutes met the recommendation. By resolving variation across sites, people, days and immediate settings, this study lays an empirical foundation for targeted, harmonised exposure monitoring aligned with health-based light recommendations.

R 4.6.1 whitespace counting gives 147 words, within the 150-word limit. A
Word-style count must also be recorded during the bounded execution.

## Other exact author wording

Replace the recommendation-results lead with:

> Exposure was within the applicable recommendation during 24.0% of daytime minutes, 63.3% of pre-sleep minutes and 87.7% of sleep minutes.

Only the immediately adjacent counts may be edited to avoid repeating those
same percentages. Preserve all counts, denominators, estimates, intervals,
citations, and claims.

Replace the Discussion opening with:

> The expected 24-hour rhythm was evident across nine sites in seven countries. The key advance was to quantify its amplitude across sites, participants and participant-days, and to show how immediate settings reorganised exposure within that rhythm.

Add the following exact technical boundary once in Results or Methods:

> The decomposition partitioned the full model’s row-weighted in-sample R² for log10(melanopic EDI + 0.1 lx), defined as the reduction in squared prediction error relative to predicting the fitted-sample mean. The percentages therefore represent shares of the variation accounted for on that transformed response scale, not shares of variance in raw melanopic EDI and not causal or out-of-sample predictive importance.

This supersedes any broader statement saying that the allocation is not
response variance explained.

## Terminology matrix

Audit every decomposition phrase in Abstract, Results, Discussion, Methods,
and Supplementary Table S5 and S6 captions. Apply these exact construct
boundaries:

1. H02 dominance partitions custom row-weighted in-sample R² for
   `log10(melanopic EDI + 0.1 lx)`. Use `share of full-model R²` and define it
   once with the exact boundary above.
2. H03 and H04 participant-intercept Shapley analyses allocate marginal
   Nakagawa R². Use `share of marginal R²`.
3. H03 and H04 temporal GAM values 60.4/24.2 and 52.5/30.7 are Shapley
   allocations of fitted linear-predictor variance. Use the reader phrase
   `share of fitted-pattern variance`, and define it once in Methods as
   `share of fitted linear-predictor variance`.
4. Never call item 3 response variance explained. Keep fitted-curve dispersion
   separate from every decomposition quantity.
5. Brown marginal and conditional R² values and variance allocations may use
   R² or variance-explained language where the displayed statistic directly
   supports it.

Replace `model-fit credit` wherever the quantity supports the more precise R²
or variance wording. Preserve every value and its correct estimand. In this
order, the H02 caption audit applies to Supplementary **Tables** S5 and S6,
not the unrelated Brown Supplementary Figures S5 and S6.

## Reader terminology

Remove `primary` where the near-eye specification already identifies the
measurement or analysis. Retain it only where it is needed to distinguish a
prespecified primary analysis from a complementary, exploratory, or
sensitivity analysis. Do not alter internal filenames, object names, IDs, or
historical analytical labels. In particular, the abstract uses `reported
light source`, not `reported primary light source`.

The author's earlier original H06_daily instruction is withdrawn. This order
does not add, remove, renumber, or reinterpret an H06_daily display. Preserve
the current hourly H06 and complementary H06_daily boundary and do not
reintroduce a superseded H06_daily instruction.

## Accepted display integration

The Writer must retain or integrate the accepted figure and table selections
in the manuscript source and its included Supplementary Information. Do not
recompose panels in Quarto and do not regenerate a scientific asset.

1. Replace only
   `manuscript/R0_NatHealth/display_assets/table3_metric_context.html` with the
   exact accepted Table 3 fragment
   `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html`,
   SHA-256
   `d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2`,
   1,901,204 bytes. Its approved 17-row order is exactly: Duration (five),
   Dynamics (two), Exposure history (one), Level (three), Spectrum (one), and
   Timing (five), with metric order within each group matching the descriptive
   table. Preserve the approved widths, compact padding, bold metric names,
   `Participants`, FDR wording, bold supported adjusted values, percentage R²
   summaries, and all density SVG thumbnails. The accepted content inventory
   is SHA-256
   `b134338872efdef40fb755f95d465ea96beff06abed0507e1dc8f4b32c05441a`.
2. Main Figure 3 remains the accepted H04 activity/immediate-setting
   four-panel figure. The accepted H03 light-source four-panel figure remains
   supplementary. Do not swap them and do not reuse site colors for category
   encodings.
3. Supplementary Figure S5 must remain one owner-sealed two-panel SVG, not two
   images composed by Quarto.
4. Supplementary Figure S6 must use the accepted SVG
   `manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg`,
   SHA-256
   `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`,
   108,600 bytes. This explicit author instruction supersedes the older
   planning-table proposal to omit the Brown participant raincloud. Do not
   substitute a PNG, rasterize it, or embed it as a data URI.
5. Every multi-panel reader figure must use uppercase panel tags placed at the
   left side of its panel. Verify the accepted asset rather than adding HTML
   labels over an image. Any nonconforming asset stops this order for owner
   correction.
6. No reader-facing MDER legend may be introduced into Supplementary Figure
   S12 or any other unrelated figure. The accepted owner-side H06_daily legend
   repair remains outside this source order.
7. Preserve the approved Table 1 caption terminology that spells out
   near-eye, complementary chest, and paired samples. Preserve the accepted
   compact Table 2 and all other accepted display identities and captions,
   except for the exact wording changes authorized above.

The accepted review source is
`audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`,
SHA-256
`1e29b5f4a83343978bbb4bf8e841072d1b941832991e3fa78139517738044676`.
Where that older planning source conflicts with an explicit instruction in
this order, this order controls.

## Bounded execution and stop

Begin from these exact current inputs:

- manuscript QMD SHA-256
  `9853f0bd462c8c6ed0e74dae8a7bae9a570fdc8ba6f13644dfbc0d88109657d0`;
- Supplementary Information outline SHA-256
  `f438f912da5287e4bd687255b7d17661ff91593aee4cce975e4a23c4ae34f1b0`;
- current Table 3 manuscript fragment SHA-256
  `953561901707d886e4ec142c02805f69636da03edcf1e42c0f4fc4041a737883`;
- current canonical manuscript HTML SHA-256
  `8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac`;
  and
- current canonical DOCX SHA-256
  `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`.

Seal a source inventory showing every affected wording occurrence and every
display reference. Apply only the approved wording, exact Table 3 replacement,
necessary local de-duplication, and any path-only synchronization required to
use the already accepted figures. Run one narrow manuscript HTML render, no
Word, report, supplementary-only, website, or project render. Require complete
source, number, citation, cross-reference, figure, table, SVG, semantic,
browser, protected-token, and display-order verification. Confirm the 147-word
abstract with R 4.6.1 and a Word-style count. Confirm all 17 Table 3 rows in the
approved descriptive order.

Promote only the revised manuscript QMD, Supplementary Information outline,
exact Table 3 fragment, and canonical manuscript HTML after every gate passes.
The canonical DOCX and website must remain byte-identical. Stop once on any
identity drift, missing figure, panel-tag defect, broken reference, scientific
mismatch, or render failure. Return one complete source and HTML seal for
independent acceptance before Order 71b begins.

Do not change analyses, estimates, intervals, p-values, model objects, figure
contents, accepted table contents, accepted SVG, packages, lockfiles, Word, or
website output. Do not commit, push, upload, deploy, or submit.
