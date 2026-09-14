# REPORT-018 navigation Order 67 dispatch

Date: 2026-09-02 16:06:03 CEST

Status: `DISPATCHED_EXACTLY_ONCE`

The Coordinator independently accepted the H06 Order 66b visual stop,
confirmed the shared mobile table-of-contents mechanism across the full
37-route corpus, added the frozen 892-file build identity to the release gate,
and sent Order 67 exactly once to navigation integration task
`01a02dde-497e-7a92-8fd8-b8cc7ff360ac`.

The controlling order is
`audit/report_harmonization/owner_orders/67_nathealth_mobile_toc_collapse_repair_and_h06_completion.md`,
SHA-256
`54ed7e519f93b049ee3538545a53118874a01c90d90420cd0810d403804200fe`,
8,316 bytes.

The 25-row non-circular dispatch manifest is
`audit/report_harmonization/report018_navigation_order67_dispatch_manifest.csv`,
SHA-256
`c12d5aeb2289349b1c7291e12baebfe2b6f47c5ab470d4ef7a6eaa03691cb729`,
4,678 bytes. R 4.6.1 reproduced 25 of 25 members by exact SHA-256 and
byte count.

The released operation is candidate-first and permits exactly one shared CSS
rule followed by one-time replacement of the source and built Nature Health
stylesheets. It includes corpus-wide narrow-screen verification and completion
of the deferred H06 visual checks. No Quarto command, HTML rewrite, QMD or
scientific change, corpus-manifest reseal, retry, or later-target action was
released.
