# H03-to-H04 reader-report crosswalk

This crosswalk records the literal H03 reader-report elements checked for the
H04 standalone report. Transfer means the H03 content and visual grammar are
retained while the H04 estimand, fractional weights, support gate, and
display-only treatment of Other remain unchanged.

| H03 reader element | H04 disposition | H04 adaptation |
|---|---|---|
| Exact fitted samples and category support | Retain | Add H04 sample-flow, long-row, and effective-weighted-hour columns required by the multi-select contract. |
| Exact Wilkinson formulas | Retain | Use the approved H04 activity-long formulas, including thin-plate `sz` activity and site deviations in the exploratory temporal model. |
| Standardized category means and reference ratios | Retain | Because site heterogeneity is supported, the five named descriptive means, ratios, differences, and intervals use the accepted heterogeneity model, as in H03. The additive omnibus remains primary; Other is an additive-model display-only exception and is excluded from claims. Reader-facing order is At home, Office/home working, Outdoors, Vehicle/public transport, Sleeping, with Other last where present. |
| Primary and heterogeneity omnibus tests | Retain | Keep the primary five-named-category test and secondary six-category test distinct; add the separate support-gated heterogeneity omnibus. |
| Site-specific factorization table | Retain | Show the near-eye standardized row and site-deviation ratios for the five named H04 categories in the reference-first reader order; unsupported cells remain non-estimable. The overall row reports four heterogeneity-model category-comparison BH p-values versus At home. Every estimable site cell reports only its complete-family BH-adjusted deviation p-value, with only BH-passing site ratios and adjusted p-values bolded. Internal audit identifiers are omitted from the reader report. |
| Site-specific interval figure | Retain | Use submitted site names, order, and colours; show both placements because H04 has complementary chest evidence. Every placement-by-activity facet has a dashed equal-site geometric mean from the heterogeneity model. |
| Descriptive heterogeneity-model R-squared allocation | Retain | Reproduce H03's hierarchy-respecting point decomposition using H04's `1/k` prior weights; it is descriptive and supplies no new effect test. |
| Three-panel primary diagnostics | Retain | Aggregate concurrent memberships back to one original participant-hour for residual and zero-mass panels; use boundary-aware unique-hour autocorrelation. |
| Common-sample placement figure | Retain | Replace the forest display with H03's log-log near-eye-versus-chest concordance plot, with horizontal and vertical 95% confidence intervals. |
| Three-row temporal figures | Retain | Show accepted equal-site activity curves plus the dashed global smooth, activity/global ratios, and effective weighted support. Other is display-only. Use an H04-specific palette with no colour reused from H03's light-source categories so the two category systems are not visually conflated. Export at 15.75 by 12.5 inches, use six single-line abbreviated facet labels in the reference-first order, and place A/B/C at the upper right away from vertical axis titles. Panel B uses one 0.01–50 ratio range with standard 1–2–5 logarithmic breaks, covering all displayed pointwise intervals at both placements. |
| Temporal fit and participant-balanced R-squared | Retain | Add `1/k` to H03's equal-site, participant-balanced weighting hierarchy. |
| Temporal linear-predictor variance allocation | Retain | Allocate global time, activity deviations, site deviations, participant curves, and participant-day shifts; point estimates only, zero simulation draws. |
| Three-panel temporal diagnostics | Retain | Residual and zero panels return to one weighted original hour; autocorrelation retains activity-specific run boundaries so concurrent rows are never lag neighbours. |
| Exploratory latitude replacement | Omit | H04 did not preregister or approve a latitude replacement, and adding it would introduce a different scientific question. |

Across transferred elements, the H03 `cowplot` typography, table font sizes,
caption treatment, panel tags, point/interval geometry, durable source-data
links, and publication-width checks are used as the reader-facing reference.
