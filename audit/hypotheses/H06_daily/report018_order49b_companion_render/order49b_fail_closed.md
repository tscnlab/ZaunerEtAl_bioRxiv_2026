# REPORT-018 H06_daily Order 49b fail-closed record

Date: 2026-08-21

Status: **FAIL_CLOSED_BROKEN_LOCAL_FIGURE_AND_PROTECTED_HTML_REMOVAL**

## Authorized source transition

The required independent R 4.6.1 checker passed exactly once. The companion
source then received only the sealed `rel_path = FALSE` addition to the unique
`knitr::include_graphics()` call. Its live identity is SHA-256
`cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2`,
35,450 bytes. Reversing only that addition in memory reproduced the immediate
preimage SHA-256
`ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252`,
35,432 bytes. All 19 R chunks parsed, and the 17-table, one-figure, one
top-down-Mermaid, and two-dynamic-link source inventories remained exact.

No historical test or manifest was changed.

## Sole replacement render

The following command was run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order49b-semantic.UvRg9U quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

The command exited 0 after 41 of 41 knitr steps and Pandoc. The semantic hook
repaired 17 tables and produced an external 1,003-row reversible ledger. The
post-hook companion HTML is SHA-256
`896cc3797ab570eeb3b36dc9811ce9cc5ed378dc0e0bb7d15b75d7f77ac35584`,
5,349,983 bytes. Direct reversal of the semantic ledger reproduced the exact
pre-hook HTML identity.

## Consolidated defects

### Broken and nonportable figure source

`rel_path = FALSE` prevented knitr from rewriting the absolute file path
before its existence check. Pandoc nevertheless emitted the path in the page
as:

```text
../../../Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png
```

Relative to the built companion page, this resolves to a nonexistent
build-local `Users/zauner` path. The frozen PNG itself was copied correctly to
the target artifact directory and retains SHA-256
`f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff`,
but the HTML does not reference that copy. The page therefore contains both a
broken image and a forbidden user-specific path.

### Removed protected authoring HTML

The render removed
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`, which was a
held hard-dispatch member at SHA-256
`7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`,
4,613,650 bytes. This is the sole protected-inventory transition.

These are genuine direct-integration failures. They are distinct from the
scientific content and from the table semantic repair.

## Checks that passed

- Exactly 17 native gt tables, one figure endpoint, one top-down Mermaid, and
  two dynamic links are present in the required order.
- The document has 98 unique semantic IDs, 905 header-bearing nodes, and 1,193
  header-token references. Every token resolves exactly once inside its table.
- Both dynamic H06 links resolve in the build. Country-coded site names are
  present, and no embedded error, warning, or unresolved-reference node was
  found.
- The build changed in exactly seven places: four target-owned resources were
  added, and only the target HTML, search index, and sitemap changed identity.
- The accepted H06_daily result source and HTML remain exact at
  `8f696f3f...` and `74a63bd0...`.

## Visual gate and teardown

Secure-loopback and 170-mm visual acceptance were not started because the
direct integration gate had already failed. A page with a broken required
figure is not eligible for reader acceptance. No loopback listener was
started.

The authorized source postimage and rendered evidence remain preserved. No
patch, second Quarto command, helper, historical test, manifest builder,
commit, push, or upload occurred. The final process check found no Quarto,
Pandoc, semantic-hook, H06_daily, or loopback process.

Order 49b therefore stops here. A new central amendment is required before any
further path-handling change, disposition of the removed held HTML, or
rerender. A prospective amendment should validate a project-relative,
reader-safe resource path through both knitr and Pandoc and explicitly decide
whether the historical source-side HTML must be restored or reclassified.
