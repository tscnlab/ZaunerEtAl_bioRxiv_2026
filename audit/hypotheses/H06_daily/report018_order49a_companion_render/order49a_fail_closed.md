# REPORT-018 H06_daily Order 49a fail-closed record

Date: 2026-08-21

Status: **FAIL_CLOSED_KNITR_REL_PATH_REWRITE**

## Authorized source transition

The required central checker passed exactly once. The companion source then
received only the sealed `knitr::include_graphics()` replacement. Its live
identity is SHA-256
`ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252`,
35,432 bytes. Reversing only that replacement in memory reproduced the
preimage SHA-256
`ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`,
35,409 bytes. All 19 R chunks parsed and the 17-table, one-figure, one
top-down-Mermaid, and two-link source inventories remained exact.

The authorized source postimage remains in place. No historical manifest or
test was changed.

## Sole replacement render

The following command was run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order49a-semantic.LprYhu quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

The command exited with status 1 in chunk
`fig-h06d-prep-primary-sample-support`. No retry was attempted.

## Consolidated defect

The intended PNG exists at its exact frozen absolute path, but
`knitr::include_graphics()` applies its default `rel_path = TRUE` behavior
before checking file existence. With `knitr` output directory
`audit/hypotheses/H06_daily`, the valid absolute path is rewritten to:

```text
../../../artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png
```

The profile executes R from the project root. The rewritten path therefore
does not exist from the active working directory, and `include_graphics()`
raises the same file-not-found condition. A direct read-only reproduction of
that path conversion matched the render error exactly. The same probe showed
that retaining the absolute path with `rel_path = FALSE` avoids this conversion,
but this record does not apply that prospective repair.

## Preservation and teardown

- All 846 build files are byte-identical to the pre-render inventory, with no
  additions, removals, or symlinks.
- All 3,498 protected files are byte-identical to the pre-render inventory.
- The accepted H06_daily result source and HTML remain `8f696f3f...` and
  `74a63bd0...`.
- The repaired companion source remains `ae0d270b...`. Both held companion
  HTML copies remain `7f3adfd0...` because no new HTML was produced.
- The fresh semantic-audit directory is empty. Pandoc and the semantic hook
  were not reached.
- Secure-loopback and 170-mm visual QA were not started because there is no
  new HTML to inspect.
- No further source patch, helper, historical test, manifest builder, bypass,
  second Quarto command, commit, push, or upload occurred.
- The final process check found no Quarto, Pandoc, semantic-hook, H06_daily, or
  loopback process.

Order 49a therefore stops here. A new central amendment is required before a
further path-handling correction or rerender.
