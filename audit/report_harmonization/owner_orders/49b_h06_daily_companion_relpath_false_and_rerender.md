# REPORT-018 owner order 49b: H06_daily companion rel_path repair and rerender

Date: 2026-08-21  
Owner: H06_daily  
Scope: add one verified knitr argument and run exactly one companion render  
Status: sealed for dispatch

## Controlling acceptance and runtime proof

Order 49a is independently accepted as a clean fail-closed knitr path-rewrite
stop under:

- `audit/report_harmonization/report018_h06_daily_order49a_stopped_independent_acceptance.md`,
  SHA-256
  `f4d1d75ae3ae96faf209a33e1b01b14c626093c7c2c336b87310b3523a2776ed`;
  and
- its 24-row non-circular manifest, SHA-256
  `2b44d4a981ccdf9b48ecfd1539447eb16a57079cfefa45ca41578c5f023479f0`.

The independent read-only checker
`scripts/report_harmonization/check_h06_daily_order49a_stop_and_relpath_probe.R`,
SHA-256
`b9f3a8c5289dc155e819ae62a041bc1ad2e4712dd8b46bea83bd57fd7ff02d17`,
passes under R 4.6.1 and knitr 1.51. From the project working directory, with
`opts_knit$output.dir` set to the companion directory, the exact two-argument
`include_graphics(..., rel_path = FALSE)` call returns the existing absolute
frozen PNG path unchanged. The prospective source and reverse proof also pass.

The accepted H06_daily result remains frozen at source SHA-256
`8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`
and HTML SHA-256
`74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`.

## Preflight

Before any edit:

1. reproduce every hard row of
   `audit/report_harmonization/report018_h06_daily_order49b_dispatch_manifest.csv`,
   treating only the coordination matrix as dispatch-time evidence;
2. run the independent checker above exactly once and require PASS;
3. require the companion source to remain SHA-256
   `ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252`,
   35,432 bytes;
4. require the included PNG to remain SHA-256
   `f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`,
   165,458 bytes;
5. require the order-49a 54-row owner seal, 846 build files, 3,498 protected
   files, zero symlinks, held HTML, accepted result, historical test, and
   historical manifests exact; and
6. require no active Quarto, Pandoc, semantic-hook, H06_daily, or loopback
   process.

Stop before mutation on any other drift.

## Sole source repair

In the unique current call in
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, change only:

```r
knitr::include_graphics(file.path(
  project_root,
  "artifacts/10_figures/H06_daily",
  "H06_daily_preparation_primary_sample_support.png"
))
```

to:

```r
knitr::include_graphics(file.path(
  project_root,
  "artifacts/10_figures/H06_daily",
  "H06_daily_preparation_primary_sample_support.png"
), rel_path = FALSE)
```

Do not format or otherwise rewrite the QMD. Require exact postimage SHA-256
`cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2`,
35,450 bytes. Reverse only this addition in memory and require exact recovery
of `ae0d270b...`, 35,432 bytes. Parse all 19 R chunks and reproduce the exact
17-table, one-figure, one-top-down-Mermaid, and two-dynamic-link inventories.

Treat `ae0d270b...` to `cc0647d1...` as the only authorized live source
transition in current or historical pin comparisons. Preserve every historical
test and manifest byte-for-byte. Do not rebuild or reseal them.

## Sole replacement render

Create one fresh empty absolute semantic-audit directory under `/private/tmp`
and run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the normal project profile and renv startup, and
the established narrow elevated access to the existing user-owned renv cache
from process startup. Do not bypass the profile, renv, or semantic hook. If
startup or rendering fails, stop without another render.

The companion may read and format only frozen stored outputs. No model fit or
refit, prediction, contrast, p-value or FDR calculation, bootstrap, simulation,
resampling, source-data change, model-object regeneration, or scientific
artifact write is authorized.

## Direct integration and acceptance

Do not run a helper, the historical preparation test, or any manifest builder.
Verify the fresh target directly and require:

1. exactly 17 native gt tables, one figure, one top-down Mermaid, and two
   dynamic `.qmd` links in accepted source order;
2. the figure resolves from the exact frozen PNG and appears once with its
   accepted caption, alt text, dimensions, and source relationship;
3. semantic-hook completion with external summary and reversible ledger,
   unique document IDs, and every explicit table header token resolving
   exactly once inside its table;
4. all table values, rows, columns, captions, notes, labels, headings, links,
   navigation, and country-coded sites preserved;
5. zero embedded errors, warning nodes, unresolved references, broken internal
   links, forbidden local paths, or unexpected output;
6. exact preservation of the accepted result, all scientific inputs and
   artifacts, profile, lockfile, semantic tools, phase-4 corpus manifest,
   historical test and manifests, and unrelated paths; and
7. a complete build-delta account confined to target-owned companion output
   and expected search or sitemap integration.

## Secure-loopback QA and return

Serve `_build/nathealth` read-only on one unused high port bound only to
`127.0.0.1`. Inspect the exact companion route at 1440 by 1000, 708 by 1000,
and 720 by 500 as the 200-percent-equivalent view. Inspect all tables, the
figure, Mermaid, captions, links, navigation, table scrollers, wrapping,
clipping, overlap, and page overflow. Inspect the figure at 170 mm and require
essential text of at least 7 points.

Stop the server, prove no listener remains, reset or close the QA surface, and
rehash the complete build and protected inventories. Return one exact,
non-circular acceptance package or one consolidated fail-closed defect list.
Do not patch or rerender if another defect appears.

No result rerender, other source edit, helper, test edit, manifest edit,
scientific computation, H07 or later render, Brown action, full-project render,
profile or ledger change, package or lock change, commit, push, or upload is
authorized.
