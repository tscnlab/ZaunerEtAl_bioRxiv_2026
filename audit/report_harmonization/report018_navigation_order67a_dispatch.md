# REPORT-018 navigation Order 67a dispatch

Date: 2026-09-02 16:22:08 CEST

Status: `DISPATCHED_EXACTLY_ONCE_AS_STOPPED_ORDER_CONTINUATION`

The Coordinator independently accepted the Order 67 candidate-only stop,
audited all 37 embedded mobile-TOC scripts and 892 live build files, sealed the
clone-state repair, and sent Order 67a exactly once to navigation integration
task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`.

The controlling order is
`audit/report_harmonization/owner_orders/67a_nathealth_mobile_toc_clone_state_repair_and_h06_completion.md`,
SHA-256
`4a04f727535247fb6a8ce5e54ab002d9b0f21fb78ee9d36097f27f1eac9001c4`,
11,296 bytes.

The 30-row non-circular dispatch manifest is
`audit/report_harmonization/report018_navigation_order67a_dispatch_manifest.csv`,
SHA-256
`53086ca8e49d1e998b0cc3b2f37b2616c98a2dd8bdb083622259da653585b174`,
5,556 bytes. R 4.6.1 reproduced 30 of 30 members by exact SHA-256 and
byte count immediately before release.

Order 67a is a continuation after the accepted stopped state, not a duplicate
Order 67 dispatch. It authorizes only the exact shared include change, the 37
byte-exact embedded-script transitions, an HTML-hash-only corpus reseal,
responsive route QA, and completion of H06 QA. It authorizes no Quarto render,
QMD or scientific change, stylesheet change, substantive HTML change, retry,
or later shared-build action.
