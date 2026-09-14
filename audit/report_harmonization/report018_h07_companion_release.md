# REPORT-018 H07 companion serial release

Date: 2026-08-21

Status: released for exactly one H07 preparation/provenance companion render.
Every later REPORT-018 render remains held.

## Serial prerequisite

The H07 result page is independently accepted at:

- `audit/report_harmonization/report018_h07_result_independent_acceptance.md`,
  SHA-256
  `7752009f6cbda0ac1954c7d6b98238e00aa21172443f18bc2268193581e37813`;
  and
- its 26-row non-circular manifest, SHA-256
  `cd2324cf4b1ab31dd8c9f760bb1b9c468eda7db91358a14803212a42d44d47e1`.

The accepted result source and HTML remain fixed at SHA-256
`c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226`
and
`7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40`.

## Completed preflight

The completed R 4.6.1 checker at
`scripts/report_harmonization/check_h07_companion_report018_release.R`,
SHA-256
`02a6cf08ccea3bfa0ea1b3303ddcf8ca9a59c3ed48db6328c305f6dfd8f9bb61`,
passed 20 of 20 checks. Its verification output is SHA-256
`a3e8f2328e1dadea5173c9c76e30f863f467dc3b79b65411e95125874da93d9c`.
The 23-row pin set is SHA-256
`47161aabe9c90eb3457d6d8bbb7787930bc95af0e1d109cc13702decb1a35f6a`.

The preflight establishes:

- 23 of 23 current hard pins exact;
- 26 parseable R chunks, 21 unique `tbl-h07-*` endpoints, and three unique
  `fig-h07-*` endpoints;
- no model fit, refit, prediction, derivative calculation, resampling,
  simulation, p-value recalculation, or other scientific regeneration call;
- 14 relative reader/source-data targets, all resolving;
- exactly three dynamic links to `notebooks/hypotheses/H07.qmd`, including
  the preregistration-deviation anchor;
- one unique companion deviation-section anchor;
- the normal profile registers the companion exactly once;
- zero build symlinks; and
- 1,231 of 1,235 current preparation-manifest rows live-exact, with exactly
  four accepted historical-to-current mismatches: companion source, result
  source, accepted result HTML, and profile.

## Held stale-test classification

The unchanged preparation test requires one obsolete hard-coded
`../../../notebooks/hypotheses/H07.html` source literal. The accepted companion
source instead uses dynamic `.qmd` links, which Quarto renders to the correct
HTML route. Preserve the test byte-for-byte and do not execute it in this
order. Its remaining scientific, source-data, manifest, semantic, and reader
contracts must be independently reproduced in task-owned evidence after the
render.

This is a historical test classification, not a waiver of any companion-page
contract. Do not patch the test or open a cleanup loop.

## Authorized execution

After reproducing every non-matrix pin, inventory the complete build and
protected scope and create one fresh absolute semantic-audit directory under
`/private/tmp`. Then run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H07/H07_analysis_preparation.qmd --profile nathealth
```

The established narrow elevated access to the existing user-owned `renv`
cache is authorized. Use R 4.6.1, Quarto 1.9.37, the normal project profile,
and the accepted semantic hook. Do not bypass the profile or autoloader.

If and only if the render and semantic hook succeed, run exactly once:

```sh
NATHEALTH_PROJECT_ROOT=<absolute-project-root> Rscript --vanilla scripts/hypotheses/H07/build_h07_preparation_report_manifest.R
```

The helper may synchronize only the source-identical build QMD and record the
truthful current H07 preparation manifest. Because the source is profile
integrated, the source-side historical HTML and asset tree must remain exact.

## Required post-render acceptance

Before browser QA, require all of the following:

1. authoring and build companion QMDs are byte-identical;
2. the new companion HTML has exactly 21 native `gt` tables, two accepted
   paired-source PNG figures, and one top-down Mermaid endpoint;
3. the semantic hook repairs every native table, every final document ID is
   unique, every `headers` token resolves once to a `th` inside its own table,
   and the ledger exactly reverses and reapplies;
4. every table and figure endpoint, caption, note, alt text, reader link,
   source-data link, navigation link, country-coded site, and required anchor
   passes;
5. the dynamic result links render to the accepted H07 result route and its
   preregistration-deviation anchor;
6. the dedicated helper executes once and its final manifest is unique,
   live-exact, non-circular, and contains the accepted result plus current
   companion identities;
7. the unchanged result reader test still passes, and the held preparation
   test remains unchanged and unexecuted;
8. the accepted result QMD/HTML, scientific artifacts, profile, hook, engine,
   lockfile, handoff, shared corpus manifest, source-side companion HTML, and
   all unrelated paths remain exact; and
9. build changes are limited to the companion target, its source-identical
   build QMD and resources, search and sitemap updates, and the truthful H07
   preparation manifest.

Then perform secure-loopback QA at 1440 by 1000, 708 by 1000, 720 by 500
200-percent-equivalent, and 170 mm final figure size. Inspect the full page,
all 21 tables, both PNG figures, the Mermaid diagram, contained table
scrollers, captions, notes, links, and final provenance. Require zero page
overflow, clipping, overlap, missing content, broken interaction, or
report-attributable console warning or error. Reset the viewport, close the QA
surface, stop the server, and prove no listener remains.

## Prohibitions

No source, helper, test, scientific artifact, model, estimate, interval,
p-value, classification, profile, package, lockfile, ledger, manuscript, or
handoff edit is authorized. Do not render the result again, render another
page, render the full project, retry a failed render, commit, push, upload, or
start a new language or cosmetic loop. Return one complete acceptance package
or one consolidated fail-closed defect list.
