# REPORT-018 owner order 49a: H06_daily companion path repair and rerender

Date: 2026-08-21  
Owner: H06_daily  
Scope: one exact source-path repair plus exactly one companion target render  
Status: sealed for dispatch

## Controlling stopped-state acceptance

Order 49 stopped correctly before Pandoc, semantic repair, HTML replacement,
or visual QA. The independent acceptance is
`audit/report_harmonization/report018_h06_daily_order49_stopped_independent_acceptance.md`,
SHA-256
`004f86e988f2527afeb757c91e1f153482ccbf96fe7ce8a6b57dd32f1bc5a901`.
Its 23-row non-circular manifest is SHA-256
`8e6482a9f1dbedcee8997c8d45ad8728d8744dd62fbf9449f210b09edfd79b9f`.

The owner stopped record is SHA-256
`0a15429a58c6e35a5dfd7227fe404d4b8116d181e52b7ae38d72f3945cf61f56`,
and its 50-row manifest is SHA-256
`929ea51950b7f409a03254106f53dc54becb6023e39edd618fee7bb2aab63ae8`.
Independent R 4.6.1 verification passes 50 of 50 rows, 846 of 846 build
files, and 3,468 of 3,468 protected files. No relevant process remains.

The accepted H06_daily result remains frozen at source SHA-256
`8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`
and HTML SHA-256
`74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`.

## Preflight

Before any edit:

1. reproduce every row of
   `audit/report_harmonization/report018_h06_daily_order49a_dispatch_manifest.csv`,
   treating only the coordination matrix as dispatch-time evidence;
2. rerun
   `scripts/report_harmonization/check_h06_daily_order49_stop_and_repair.R`
   exactly once under R 4.6.1 and require PASS;
3. require the companion QMD to remain SHA-256
   `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`,
   35,409 bytes;
4. require the stored figure to remain SHA-256
   `f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`,
   165,458 bytes;
5. require 846 build files, zero symlinks, exact historical manifests and test,
   and exact accepted result endpoints; and
6. require no active Quarto, Pandoc, semantic-hook, H06_daily, or loopback
   process.

Stop before mutation on any other drift.

## Sole source repair

In
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, replace only
the unique exact call:

```r
knitr::include_graphics(
  "../../../artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png"
)
```

with:

```r
knitr::include_graphics(file.path(
  project_root,
  "artifacts/10_figures/H06_daily",
  "H06_daily_preparation_primary_sample_support.png"
))
```

Do not format or otherwise rewrite the QMD. Require the exact postimage
SHA-256
`ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252`,
35,432 bytes. Reverse only this replacement in memory and require exact
reproduction of the preimage SHA and bytes. Parse all 19 R chunks and require
the same 17 table, one figure, one top-down Mermaid, and two dynamic-link
inventories.

The new source identity is an exact authorized live transition wherever the
historical release pins, output manifest, or preparation report manifest retain
the pre-repair or earlier source identity. Preserve those historical files
byte-for-byte. Do not reseal, rebuild, or edit them.

## Sole replacement render

After the exact source repair and pre-render checks pass, create one fresh empty
absolute semantic-audit directory under `/private/tmp` and run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, normal project and renv startup, and the
established narrow elevated access to the existing user-owned renv cache from
process startup. Do not bypass the profile, renv, or semantic hook. If startup
or rendering fails, stop without another render.

The companion may only format frozen stored outputs. No model fit or refit,
prediction, contrast, p-value or FDR calculation, bootstrap, simulation,
resampling, model-object regeneration, source-data change, or scientific
artifact write is authorized.

## Direct integration and nonvisual acceptance

Do not run a helper, the historical preparation test, or any manifest builder.
Verify the new target directly and require:

1. exactly 17 native gt tables, one figure, one top-down Mermaid, and two
   dynamic `.qmd` links in accepted source order;
2. the included figure resolves to the exact frozen PNG above;
3. semantic-hook completion with external summary and reversible ledger,
   document-wide unique IDs, and every explicit table header token resolving
   exactly once inside its table;
4. all table values, rows, columns, captions, notes, labels, figure source and
   dimensions, headings, reciprocal links, navigation, and country-coded sites
   preserved;
5. zero embedded errors, warning nodes, unresolved cross-references, broken
   internal links, forbidden local paths, or unexpected execution output;
6. exact preservation of the accepted result source and HTML, profile,
   lockfile, semantic tools, historical test and manifests, all scientific
   inputs and artifacts, phase-4 corpus manifest, and unrelated files; and
7. a complete build-delta account confined to target-owned companion output
   and expected search or sitemap integration.

## Secure-loopback visual QA

Serve `_build/nathealth` read-only on one unused high port bound only to
`127.0.0.1`. Inspect the exact companion route at 1440 by 1000, 708 by 1000,
and 720 by 500 as the 200-percent-equivalent view. Inspect every table, the
figure, Mermaid, headings, captions, links, navigation, table scrollers,
wrapping, clipping, overlap, and page overflow. Inspect the figure at its
intended 170-mm display size and require essential text of at least 7 points.

Stop the server, prove no listener remains, reset or close the QA surface, and
rehash the complete build and protected inventories. Return one exact,
non-circular acceptance package or one consolidated fail-closed defect list.
Do not patch or rerender if another defect appears.

No result rerender, other source edit, helper, test edit, manifest edit,
scientific computation, H07 or later render, Brown action, full-project render,
profile or ledger change, package or lock change, commit, push, or upload is
authorized.
