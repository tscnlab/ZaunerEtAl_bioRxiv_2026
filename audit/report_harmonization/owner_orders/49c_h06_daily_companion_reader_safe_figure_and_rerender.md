# REPORT-018 owner order 49c: H06_daily reader-safe figure and companion rerender

Date: 2026-08-21  
Owner: H06_daily  
Scope: one localized reader-resource repair and one companion rerender  
Status: sealed for independent concurrence before dispatch

## Controlling acceptance

Order 49b is independently accepted as a clean fail-closed reader-resource
stop under
`audit/report_harmonization/report018_h06_daily_order49b_stopped_independent_acceptance.md`.
The acceptance checker
`scripts/report_harmonization/check_h06_daily_order49b_stop_and_reader_safe_path.R`
passes under R 4.6.1 and proves the exact stopped state, canonical-output
classification, prospective source, exact reversal, 19 parsed chunks, and
reader-safe relative path.

The accepted H06_daily result remains frozen at source SHA-256
`8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`
and HTML SHA-256
`74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`.

## Preflight

Before any edit:

1. reproduce every hard row of the order-49c dispatch manifest, treating only
   the coordination matrix as dispatch-time evidence;
2. run the controlling checker exactly once and require PASS;
3. require the current companion source to remain SHA-256
   `cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2`,
   35,450 bytes;
4. require the stopped companion HTML to remain SHA-256
   `896cc3797ab570eeb3b36dc9811ce9cc5ed378dc0e0bb7d15b75d7f77ac35584`,
   5,349,983 bytes;
5. require the frozen source and copied build PNG to remain exact at
   `f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`,
   165,458 bytes;
6. require the order-49b 65-row owner seal, accepted result, profile, semantic
   tools, historical test and manifests, build inventory, protected inventory,
   and zero-symlink contract exact; and
7. require the obsolete source-side companion HTML to remain absent and no
   active Quarto, Pandoc, semantic-hook, H06_daily, or loopback process.

Stop before mutation on any other drift.

## Sole source repair

In the unique current figure call in
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, replace only:

```r
knitr::include_graphics(file.path(
  project_root,
  "artifacts/10_figures/H06_daily",
  "H06_daily_preparation_primary_sample_support.png"
), rel_path = FALSE)
```

with:

```r
xfun::in_dir(
  file.path(project_root, "audit", "hypotheses", "H06_daily"),
  knitr::include_graphics(file.path(
    project_root,
    "artifacts/10_figures/H06_daily",
    "H06_daily_preparation_primary_sample_support.png"
  ))
)
```

Do not format or otherwise rewrite the QMD. Require exact postimage SHA-256
`b1d2c9ec6184e9c537af04119d94040b581ae691069e38e0a713935ab1582536`,
35,521 bytes. Reverse only this block in memory and require exact recovery of
`cc0647d1...`, 35,450 bytes. Parse all 19 R chunks and reproduce the exact
17-table, one-figure, one-top-down-Mermaid, and two-dynamic-link inventories.

Before rendering, execute the localized call with the actual absolute
companion output directory. Require knitr to return exactly
`../../../artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png`,
require that path to resolve from the companion directory, and reject any
absolute or user-local output.

This QMD block is the sole source mutation. Preserve every historical test,
manifest, prior order, and Stage 4 record byte-for-byte. Do not restore or
recreate `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`; its
historical identity remains sealed in prior evidence, while the canonical
reader endpoint is under `_build/nathealth`.

## Sole replacement render

Create one fresh empty absolute semantic-audit directory under `/private/tmp`
and run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the normal project profile and renv startup, and
only the established narrow elevated access to the existing user-owned renv
cache. Do not bypass the profile, renv, or semantic hook. Stop without another
render on any startup, knitr, Pandoc, semantic, or output failure.

The companion may only read and display frozen stored outputs. No model fit or
refit, prediction, contrast, p-value or FDR calculation, bootstrap, simulation,
resampling, source-data change, model-object regeneration, or scientific
artifact write is authorized.

## Complete direct acceptance

Do not run a helper, historical preparation test, or manifest builder. Complete
the entire static audit before deciding whether the page is eligible for
browser QA. Require:

1. exactly 17 native gt tables, one figure, one top-down Mermaid, and two
   dynamic `.qmd` links in accepted source order;
2. the figure source exactly
   `../../../artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png`,
   resolving to the copied build PNG at the frozen identity, with its accepted
   caption, alt text, width, and source relationship;
3. no absolute path, `Users/zauner` path, missing resource, or Pandoc warning
   attributable to the companion figure;
4. semantic-hook completion with an external summary and reversible ledger,
   unique document IDs, and every explicit table header token resolving once
   inside its table;
5. all table values, rows, columns, captions, notes, headings, links,
   navigation, country-coded sites, and endpoint order preserved;
6. zero embedded errors, warning nodes, unresolved references, broken internal
   links, forbidden local paths, or unexpected output;
7. exact preservation of the accepted result, all scientific inputs and
   artifacts, profile, lockfile, semantic tools, phase-4 corpus manifest,
   historical test and manifests, and unrelated paths; and
8. a complete build delta confined to the target companion HTML, existing
   target-owned resources, and expected search or sitemap integration. The
   already absent source-side HTML is the accepted historical-to-canonical
   transition and is not a new deletion.

## Secure-loopback QA and return

Serve `_build/nathealth` read-only on one unused high port bound only to
`127.0.0.1`, after symlink preflight. Inspect the exact companion route at 1440
by 1000, 708 by 1000, and 720 by 500 as the 200-percent-equivalent view.
Inspect all 17 tables, the figure, Mermaid, captions, links, navigation, table
scrollers, wrapping, clipping, overlap, and page overflow. Inspect the figure
at 170 mm and require essential text of at least 7 points. For HTML tables,
require normal desktop usability and contained narrow horizontal scrolling
where needed. The exported PNG remains the authority for the exported figure.

Stop the server, prove no listener remains, close or reset the QA surface, and
rehash the complete build and protected inventories. Return one exact,
non-circular acceptance package or one consolidated fail-closed defect list.
Do not patch or rerender if another defect appears.

No result rerender, other source edit, helper, test edit, manifest edit,
scientific computation, H07 or later render, Brown action, full-project render,
profile or ledger change, package or lock change, commit, push, or upload is
authorized.
