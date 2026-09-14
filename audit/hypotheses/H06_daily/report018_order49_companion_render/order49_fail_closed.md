# REPORT-018 H06_daily Order 49 fail-closed record

Date: 2026-08-21

Status: **FAIL_CLOSED_SOURCE_PATH_DEFECT**

## Sole render execution

The complete pre-render gate passed under R 4.6.1. It reproduced 30 hard
dispatch rows, 26 release pins with the explicitly expected coordination-matrix
transition treated as dispatch evidence only, all 26 accepted-result rows, 846
build files with no symlinks, and 3,468 protected files. The fresh absolute
semantic-audit directory was empty, and no prohibited render or loopback
process was active.

The following authorized command was then run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order49-semantic.hym9JL quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

The command exited with status 1 in chunk
`fig-h06d-prep-primary-sample-support`. `knitr::include_graphics()` could not
find:

```text
../../../artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png
```

## Defect classification

This is a genuine display-source path defect, not a missing scientific
artifact. The profile sets `execute-dir: project`, so the R chunk evaluates
from the project root. From that working directory, the source-relative
`../../../artifacts/...` reference points outside the project and does not
exist. The intended figure is present at
`artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png`,
SHA-256
`f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`,
165,458 bytes.

The prospective minimal repair is a separately authorized source-only change
to make the `knitr::include_graphics()` call resolve the stored figure from
`project_root`. This record does not apply that repair.

## Preservation and teardown

- No source, model, estimate, interval, p-value, diagnostic, scientific
  artifact, historical test, or historical manifest was changed.
- All 846 build files are byte-identical to the pre-render inventory, with no
  additions, removals, or symlinks.
- All 3,468 protected files are byte-identical to the pre-render inventory.
- The accepted result source and HTML remain
  `8f696f3f...` and `74a63bd0...` respectively.
- The companion source remains `ef4fde67...`. Both held companion HTML copies
  remain `7f3adfd0...` because no new HTML was produced.
- The semantic-audit directory remains empty. Pandoc and the semantic hook
  were not reached.
- Secure-loopback visual QA was not started because there is no new HTML to
  inspect.
- No retry, patch, bypass, helper, historical test, manifest builder, or
  second Quarto command was run.
- The final process check found no Quarto, Pandoc, semantic-hook, H06_daily, or
  loopback process.

Order 49 therefore stops here. A new central amendment is required before any
source correction or rerender.
