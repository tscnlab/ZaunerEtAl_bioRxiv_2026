# REPORT-018 H06_daily companion render release

Date: 2026-08-21

Disposition: **RELEASED, COMPANION TARGET ONLY**

## Controlling result acceptance

The H06_daily result page is independently accepted under:

- `audit/report_harmonization/report018_h06_daily_result_independent_acceptance.md`,
  SHA-256
  `eef994b2851d8b150719ce34f158ce46a77c7d49c8e12ed7ceeee6f7f1aac8d6`,
  3,930 bytes; and
- its 26-row non-circular manifest, SHA-256
  `1bdcf80ac0d0adeaafa16a432efcdf3d9331271c20300b6728d0e0dcd9b612da`,
  4,604 bytes.

Accepted result endpoints are:

- source `notebooks/hypotheses/H06_daily.qmd`, SHA-256
  `8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`;
- HTML `_build/nathealth/notebooks/hypotheses/H06_daily.html`, SHA-256
  `74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`;
  and
- focused order-48 verifier, SHA-256
  `06abb903f7de51792d1dbb57d8ffcfd26ddf02ebd2455f646ae3f12db6ee6109`.

These endpoints are frozen. The result page must not be rendered again.

## Companion preflight

The read-only R 4.6.1 release checker
`scripts/report_harmonization/check_h06_daily_companion_release.R`, SHA-256
`629fe40682bfb4ff092df801a7aac20a12415f9a9af0328f6423f079e0da123f`,
passes the complete pre-dispatch contract:

- 26 of 26 release pins and 26 of 26 result-acceptance rows are exact;
- all 19 R chunks parse;
- the source declares exactly 17 unique native-table endpoints, one figure,
  one top-down Mermaid, and two dynamic `.qmd` links;
- no prohibited fit, prediction, multiplicity, resampling, simulation, or
  write call appears in executable chunks;
- the source-data manifest is 17 of 17 exact;
- the historical output manifest is 30 of 31 live-exact, with only its sealed
  companion-source transition;
- the historical preparation report manifest is 12 of 15 live-exact, with
  exactly its sealed result-source, absent historical source-side result HTML,
  and companion-source transitions;
- the profile keeps hourly result, hourly companion, daily result, and daily
  companion adjacent and in that order; and
- `_build/nathealth` contains exactly 846 files and no symlinks.

The authoring companion source is SHA-256
`ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`.
The held authoring and build companion HTML copies are byte-identical at
SHA-256
`7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`.

## Render authority

Order 49 authorizes exactly one normal-profile target command:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the normal project profile, and the configured
semantic hook. The established narrowly elevated access to the existing
user-owned renv cache is authorized from process startup. Do not bypass the
profile or renv, change the lockfile, or use an alternate library.

Before execution, reproduce the complete dispatch seal, require no competing
render or loopback process, and inventory the full build and protected sets.
Stop before rendering on any unclassified drift.

The companion may read and format only frozen stored outputs. No fit, refit,
prediction, contrast, p-value or FDR calculation, bootstrap, simulation,
resampling, model-object regeneration, scientific artifact write, or source
edit is authorized.

## Integration and verification

This release does not authorize a helper, historical test, or manifest builder.
Keep the historical preparation test and both historical preparation manifests
byte-identical. Classify only their exact preflight transition sets. Verify the
fresh build HTML directly.

Acceptance requires:

1. exactly 17 native gt tables, one figure, one top-down Mermaid, and the two
   dynamic result/companion links in source order;
2. successful semantic-hook output with document-wide unique IDs, every
   explicit table header token resolving exactly once within its own table,
   and an exact reversible mutation ledger;
3. captions, notes, values, rows, columns, labels, figure source relationship,
   navigation, country-coded sites, and internal links preserved;
4. zero embedded execution errors, warning nodes, unresolved cross-references,
   forbidden local paths, or broken internal targets;
5. the accepted result source and HTML, profile, package lock, semantic tools,
   frozen source and output artifacts, phase-4 corpus manifest, and all
   unrelated sources and build members preserved;
6. a complete build-delta classification confined to the target companion
   HTML and its target-owned assets plus expected search and sitemap refreshes;
   and
7. post-QA byte stability of the complete build and protected inventories.

## Visual QA and return

Serve `_build/nathealth` read-only on one unused high port bound only to
`127.0.0.1`. Inspect the exact companion route at 1440 by 1000, 708 by 1000,
and 720 by 500 as the 200-percent-equivalent view. Inspect all 17 tables, the
figure, Mermaid, headings, callouts, captions, links, navigation, wrapping,
clipping, overlap, page overflow, and any contained narrow table scrollers.
Inspect the exported figure at its intended 170-mm display size and require
essential text of at least 7 points.

Stop the server, prove no listener remains, close or reset the QA surface, and
rehash all protected endpoints. Return one complete acceptance package or one
consolidated fail-closed defect list. Do not patch or rerender if a new defect
appears.

No H07 or later render, Brown render, source-language edit, profile or ledger
change, full-project render, commit, push, upload, or publication action is
released here. Brown Stage 3 and Stage 4 language harmonization remains queued
until this companion reaches a durable safe point.
