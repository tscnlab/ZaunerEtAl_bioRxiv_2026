# REPORT-018 H06_daily order 49b stopped-state independent acceptance

Date: 2026-08-21

Disposition: **ACCEPTED FAIL-CLOSED READER-RESOURCE PATH DEFECT**

## Independent reproduction

Order 49b applied only the authorized `rel_path = FALSE` addition and consumed
exactly one replacement companion render. The render exited 0 after all 41
knitr steps and Pandoc, and the semantic hook repaired all 17 native gt
tables. The owner then stopped without a patch, another render, or browser QA
because the required figure did not resolve for readers.

The controlling owner record is
`audit/hypotheses/H06_daily/report018_order49b_companion_render/order49b_fail_closed.md`,
SHA-256
`a7d66b5f3c8ba2a9316b46a134db75e265062dbf7b4773087c6c99aa56407cb7`.
Its 65-row non-circular manifest is SHA-256
`b19a5d64967665ee9e0e2e8c128ce224c35478f81fb95590f2049d3046b909ed`.

Independent R 4.6.1 verification reproduces all 65 paths, SHA-256 identities,
and byte counts. The current companion source is
`cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2`,
35,450 bytes. The stopped build HTML is
`896cc3797ab570eeb3b36dc9811ce9cc5ed378dc0e0bb7d15b75d7f77ac35584`,
5,349,983 bytes. The accepted H06_daily result source and HTML remain exact at
`8f696f3f...` and `74a63bd0...`. The frozen figure and its build copy are
byte-identical at `f9be5723...`, 165,458 bytes.

The semantic summary and direct reversal pass with 17 tables, 98 IDs, 905
headers substitutions, and 1,003 total reversible substitutions. Table
semantics, dynamic links, country-coded sites, the bounded seven-path build
delta, and scientific protection pass. No Quarto, Pandoc, semantic-hook,
H06_daily, or loopback process remains.

## Defect and canonical-output classification

The stopped HTML contains this figure source:

```text
../../../Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png
```

It resolves to no file beneath `_build/nathealth` and exposes a user-local
filesystem path. This is a genuine reader-resource defect and blocks visual
acceptance.

The same render removed the old source-side
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`. Under the
author's REPORT-018 render-completion priority, that removal is accepted as
canonical-output cleanup rather than a second reader defect. The reader-facing
companion is the profile-owned `_build/nathealth` endpoint. Historical Stage 4
records and manifests continue to pin the removed source-side HTML at
`7f3adfd0...`, 4,613,650 bytes. They remain historical evidence and must not be
rewritten. The absent source-side HTML must not be restored merely to satisfy
a historical live-file check.

## Reader-safe path proof

The independent checker
`scripts/report_harmonization/check_h06_daily_order49b_stop_and_reader_safe_path.R`
verifies the complete stopped state and tests the next path formulation without
editing or rendering. Under R 4.6.1, knitr 1.51, and xfun 0.59, it evaluates the
absolute frozen PNG from the companion directory through `xfun::in_dir()`.
Knitr then returns exactly:

```text
../../../artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png
```

That relative path resolves to the frozen PNG from the companion directory,
contains no local prefix, and matches the established pattern in accepted
companion HTML.

The unique prospective source is SHA-256
`b1d2c9ec6184e9c537af04119d94040b581ae691069e38e0a713935ab1582536`,
35,521 bytes. Exact reverse substitution recovers `cc0647d1...`, and all 19 R
chunks parse. No table, figure, Mermaid, link, scientific value, input, or
execution boundary changes.

One final consolidated source repair and companion rerender is supported. This
acceptance alone does not authorize an edit or render.
