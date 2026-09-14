# REPORT-018 navigation Order 70a dispatch

Date: 2026-09-02 21:06:52 CEST

Status: `DISPATCHED_EXACTLY_ONCE_AS_PRE_CANDIDATE_GATE_CLARIFICATION`

The navigation owner paused Order 70 before creating a candidate, an evidence
directory, or any live write because its absolute 37-route DOM condition
conflicted with the accepted Order 67a legacy baseline. The Harmonizer
confirmed the contradiction and released one narrow, baseline-aware gate
clarification to task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`.

The controlling clarification is
`audit/report_harmonization/owner_orders/70a_nathealth_landing_page_legacy_dom_baseline_clarification.md`,
SHA-256
`52096ce9f9b22507e5ab0df48dca132abfa13b562604c75801916a3a5ef47435`,
4,183 bytes.

The 12-row non-circular dispatch manifest is
`audit/report_harmonization/report018_navigation_order70a_dispatch_manifest.csv`,
SHA-256
`cfe626d776c2471f0864de040c2f2e4e8013884c675fe8b2a4a4c35831f13cee`,
2,520 bytes. R 4.6.1 with digest 0.6.39 reproduced 12 of 12 members
by exact SHA-256 and byte count immediately before release.

Order 70a requires a zero-defect new landing page and exact preservation of
the complete accepted legacy duplicate-ID and unresolved-token baseline on
the byte-frozen other 36 routes. It grants no new execution, write, render,
scientific, stylesheet, shared-include, QMD, or route authority.
