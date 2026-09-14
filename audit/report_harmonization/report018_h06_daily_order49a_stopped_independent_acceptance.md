# REPORT-018 H06_daily order 49a stopped-state independent acceptance

Date: 2026-08-21

Disposition: **ACCEPTED FAIL-CLOSED KNITR PATH REWRITE**

## Independent reproduction

Order 49a applied only the authorized source transition and then stopped after
its sole replacement render failed in the same figure chunk. The owner record
is
`audit/hypotheses/H06_daily/report018_order49a_companion_render/order49a_fail_closed.md`,
SHA-256
`c55bfdd9ef07c682940961bf21cbba495411123375388541e2c2ab80774dd8a2`.
Its non-circular 54-row manifest is SHA-256
`02f3db0c1b8cba398b5585b4b15aa4164a1c4b7c2766241d652f6bc08eb31450`.

Independent R 4.6.1 verification reproduces all 54 paths, hashes, and byte
counts. The pre-render and post-failure inventories are byte-identical for all
846 build files and all 3,498 protected files. The accepted result source and
HTML remain exact, both held companion HTML copies remain exact, the semantic
directory is empty, and no relevant render or loopback process remains.

The authorized companion source remains at SHA-256
`ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252`,
35,432 bytes. Its sealed reverse proof restores the pre-order source
`ef4fde67...`, 35,409 bytes. No historical test or manifest changed.

## Runtime diagnosis and verified repair

The source now supplies a valid absolute path through `project_root`. However,
knitr 1.51 defaults `include_graphics()` to `rel_path = TRUE`. With
`opts_knit$output.dir` set to the companion directory, knitr rewrites the
absolute path back to `../../../artifacts/...` before its existence check. The
profile executes R from the project root, where that rewritten path is invalid.

The read-only checker
`scripts/report_harmonization/check_h06_daily_order49a_stop_and_relpath_probe.R`,
SHA-256
`b9f3a8c5289dc155e819ae62a041bc1ad2e4712dd8b46bea83bd57fd7ff02d17`,
verifies the owner seal and exercises the exact two-argument call under R 4.6.1
and knitr 1.51. It sets the working directory to the project root and
`opts_knit$output.dir` to `audit/hypotheses/H06_daily`. With
`rel_path = FALSE`, `include_graphics()` returns the unchanged existing
absolute path to the frozen PNG, SHA-256
`f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`.

Adding only `rel_path = FALSE` to the current call produces the unique
prospective companion source SHA-256
`cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2`,
35,450 bytes. Exact reverse substitution restores `ae0d270b...`, and all 19 R
chunks parse. No table, figure, Mermaid, link, value, scientific input, or
execution boundary changes.

One final combined source repair and companion rerender is technically
supported. No separate source-only loop, other source change, helper,
historical test or manifest edit, scientific computation, result rerender,
later render, or Brown action is authorized by this acceptance alone.
