# REPORT-018 navigation Order 70b dispatch

Date: 2026-09-02 21:11:24 CEST

Status: `DISPATCHED_EXACTLY_ONCE_AS_PRE_CANDIDATE_BROWSER_CLARIFICATION`

The navigation owner paused the untouched Order 70 execution on a second
baseline contradiction. The accepted Descriptives route has one documented
708-pixel internal-scroller overflow condition that cannot be repaired while
the other 36 routes remain byte-identical. The Harmonizer released one narrow,
baseline-aware browser-gate clarification to navigation task
`01a02dde-497e-7a92-8fd8-b8cc7ff360ac`.

The controlling clarification is
`audit/report_harmonization/owner_orders/70b_nathealth_landing_page_legacy_overflow_baseline_clarification.md`,
SHA-256
`1b9e7db13e689d4024810cb9d388207edc3415636519009db35cd6f0849c1f67`,
4,356 bytes.

The 13-row non-circular dispatch manifest is
`audit/report_harmonization/report018_navigation_order70b_dispatch_manifest.csv`,
SHA-256
`60989e0c36438564c83abe8b7b0912f13e75be2587b6eae3695732d661002b8f`,
2,719 bytes. R 4.6.1 with digest 0.6.39 reproduced 13 of 13 members
by exact SHA-256 and byte count immediately before release.

Order 70b requires an overflow-clean new landing page and exact preservation
of the complete accepted Order 67a browser baseline on the other 36 routes,
including the sole Descriptives 708-pixel exception with zero worsening. It
grants no new execution, write, render, scientific, stylesheet, shared-
include, QMD, or route authority.
