# REPORT-018 H06_daily order 49 stopped-state independent acceptance

Date: 2026-08-21

Disposition: **ACCEPTED FAIL-CLOSED SOURCE-PATH DEFECT**

## Independent reproduction

The owner stopped correctly after the sole authorized companion render failed
in `fig-h06d-prep-primary-sample-support` and before Pandoc, the semantic hook,
HTML replacement, or visual QA. The owner record is
`audit/hypotheses/H06_daily/report018_order49_companion_render/order49_fail_closed.md`,
SHA-256
`0a15429a58c6e35a5dfd7227fe404d4b8116d181e52b7ae38d72f3945cf61f56`.
Its non-circular 50-row manifest is SHA-256
`929ea51950b7f409a03254106f53dc54becb6023e39edd618fee7bb2aab63ae8`.

Independent R 4.6.1 verification reproduces all 50 paths, hashes, and byte
counts. The pre-render and post-failure inventories are byte-identical for all
846 build files and all 3,468 protected files. The semantic directory is empty,
the accepted result source and HTML remain exact, both held companion HTML
copies remain exact, and no Quarto, Pandoc, semantic-hook, H06_daily, or
loopback process remains.

## Defect and bounded repair

The failure is a source path-resolution defect only. The profile uses
`execute-dir: project`, while the companion chunk passes a source-relative
`../../../artifacts/...` path to `knitr::include_graphics()`. From the project
execution directory that path resolves outside the project. The intended
frozen figure exists at
`artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png`,
SHA-256
`f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`,
165,458 bytes.

The read-only central checker
`scripts/report_harmonization/check_h06_daily_order49_stop_and_repair.R`,
SHA-256
`4fbcc278fc89a1a5bf28e44866774f6d68962219306a756196829d200954c93e`,
verifies the stopped state and the exact prospective repair. Replacing only the
single `knitr::include_graphics()` call with:

```r
knitr::include_graphics(file.path(
  project_root,
  "artifacts/10_figures/H06_daily",
  "H06_daily_preparation_primary_sample_support.png"
))
```

transitions the companion QMD from SHA-256
`ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`,
35,409 bytes, to the exact prospective SHA-256
`ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252`,
35,432 bytes. Exact reverse substitution reproduces the preimage. All 19 R
chunks parse, `project_root` is established before the figure chunk, and the
table, figure, Mermaid, link, scientific-input, and execution boundaries are
otherwise unchanged.

This repair may be combined with one replacement companion render. It does not
authorize a separate source-only loop, any other source change, a helper,
historical test or manifest edit, scientific computation, result rerender,
later render, or Brown action.
