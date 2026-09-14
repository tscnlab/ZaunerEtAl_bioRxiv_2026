# REPORT-018 H06_daily Order 49c fail-closed record

Date: 2026-08-21

Status: **FAIL_CLOSED_REQUIRED_VIEWPORT_QA_NOT_EXECUTABLE**

## Authorized source transition

The controlling R 4.6.1 checker passed exactly once before mutation. The
companion source then received only the sealed `xfun::in_dir()` figure-call
replacement. Its live identity is SHA-256
`b1d2c9ec6184e9c537af04119d94040b581ae691069e38e0a713935ab1582536`,
35,521 bytes. Reversing only that block in memory reproduced the immediate
preimage SHA-256
`cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2`,
35,450 bytes.

All 19 R chunks parsed. The source retained exactly 17 tables, one figure, one
top-down Mermaid diagram, and two dynamic links. Before rendering, the exact
figure call returned:

```text
../../../artifacts/10_figures/H06_daily/H06_daily_preparation_primary_sample_support.png
```

That path resolved from the companion directory to the frozen PNG and
contained no absolute or user-local prefix.

## Sole replacement render

The following command was run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order49c-semantic.diqxRe quarto render audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd --profile nathealth
```

It exited 0 after 41 of 41 knitr steps and Pandoc. No second render was run.
The semantic hook repaired 17 tables and produced a 1,003-row reversible
ledger. The canonical companion HTML is SHA-256
`768d4675a54e183ddc06df66a255c6d83919268d16f02d27169ec89f5bbb0fd6`,
5,570,770 bytes. Reversing the ledger reproduced the exact pre-hook identity
`1c65ce04...`.

Pandoc no longer reported a companion-figure warning. Its three remaining
warnings concerned the H07 link, the reciprocal H06_daily link, and the global
Datatype font. Both reader links resolve inside the build, and the font has a
working fallback. No browser console entry was observed.

## Complete static acceptance

The repaired reader resource passes:

- the final HTML embeds 165,458 decoded PNG bytes whose SHA-256 is exactly the
  frozen figure identity `f9be5723...`;
- the accepted alt text, ARIA label, caption, width, and source relationship
  are present;
- no `Users/zauner` string, absolute figure path, missing figure, embedded
  error, embedded warning, unresolved reference, duplicate ID, or broken link
  remains;
- all 17 native gt tables have nonempty captions and data, 905 header-bearing
  nodes, and 1,193 header-token references that each resolve once inside their
  table;
- all 424 reader links pass, including the two required reciprocal H06 links;
- all nine country-coded site names and the single rendered Mermaid diagram
  are present; and
- the build changes are confined to the canonical companion HTML, search
  index, and sitemap. The 3,527-path protected inventory changes only at the
  authorized QMD source transition.

The historical source-side companion HTML remains absent, as required by the
canonical-output classification. The accepted H06_daily result and every
historical test, manifest, scientific artifact, profile, lockfile, and
semantic tool retain their sealed identities.

## Visual checks completed

The canonical page was served read-only on `127.0.0.1:49273`. At the secure
browser surface's available 1280 by 720 viewport:

- the page has no horizontal document overflow;
- all 17 tables are contained in their table wrappers and have readable
  captions, headings, and values;
- the figure loads at its exact 3011 by 2657 pixels, remains within its panel,
  and has a complete caption and alt text;
- the top-down Mermaid diagram is complete and unclipped when scrolled; and
- the execution-boundary callout, navigation, representative wide tables, and
  browser console pass visual inspection.

A 643 by 567 preview corresponding to 170 mm at 96 dpi was also inspected.
The historical minimum effective text size is 8.667 points, above the 7-point
floor. Labels, symbols, legend, axis text, and all 15 metric rows remain
legible.

## Consolidated stop

The selected secure browser exposes a fixed 1280 by 720 viewport and no
viewport-control API. Its page-evaluation surface is read-only, so it cannot
construct exact-size in-page frames. A data-URL frame was rejected by the
browser URL security policy. No alternate browser, indirect wrapper, raw
browser command, or policy workaround was attempted after that rejection.

Consequently, the mandatory 1440 by 1000, 708 by 1000, and 720 by 500
200-percent-equivalent inspections, including the exact narrow table-scroll
acceptance, could not be completed. This is a QA-environment limitation, not a
new page or scientific defect. It nevertheless prevents an Order 49c reader
acceptance under the exact contract.

The browser tab was closed, the loopback server exited normally, and final
checks found no Quarto, Pandoc, semantic-hook, H06_daily, or loopback process
or listener. Post-QA inventories remain byte-identical to the post-render
inventories.

Order 49c therefore stops here without a patch, second render, helper,
historical test, manifest builder, commit, push, or upload. An environment-only
continuation can inspect the preserved `768d4675...` HTML at the three exact
viewports without rerendering or changing any source or build artifact.
