# Owner order 56b: H09 Sass-cache environment retry

Date: 2026-08-22

Workflow: `REPORT-018`

Owner: H09 task `019fdc1b-b927-7fb1-ac61-88993c0a818a`

Status: `RELEASED_ONCE_AFTER_EXACT_PREFLIGHT`

## Authority and disposition

Order 56a is independently accepted at a fail-closed environment stop under
`audit/report_harmonization/report018_h09_order56a_stopped_independent_acceptance.md`,
SHA-256
`a09a0c38a5cf431a0f66e6085ac1848a36dde487883a5896a4fe884b2127c617`,
4,570 bytes. Its 39-row non-circular acceptance manifest, SHA-256
`453623e678787ba863564751fde0553ece60425d247b4240870ebaa18ef11334`,
5,530 bytes, passes 39/39 path, hash, and byte checks under R 4.6.1.

The owner completed the complete frozen-source figure repair, promoted the
eight PNG/PDF postimages together exactly once, and passed the complete
pre-render gate. The sole normal-profile H09 render then completed knitr 35/35
and stopped before HTML generation because Quarto could not open its macOS
Sass-cache database. The stopped result HTML, both QMDs, held companion HTML,
semantic tools, profile, lockfile, scientific inputs, 851 build paths, and 275
protected paths remain exact. The semantic directory is empty and no render,
Pandoc, hook, or loopback process remains.

This order changes only the execution permission boundary for one replacement
render. It creates no source, figure, scientific, semantic, or reporting
change.

## Reproduced environment boundary

Quarto 1.9.37 routes the macOS Sass cache through
`/Users/zauner/Library/Caches/quarto/sass/sass.kv` and opens it with
`Deno.openKv()`. The database is owned by user `zauner`, is 36,864 bytes, and
has SHA-256
`22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`.

This is the same user-owned database and access boundary independently
diagnosed and successfully recovered for the Brown Stage 4 render. The
required recovery is narrow filesystem access to that existing cache. It does
not require a cache reset, redirect, copy, permission edit, or project change.

## Exact preflight

Immediately before execution, the owner must:

1. reproduce the independent 39-row order-56a stopped-state acceptance
   manifest;
2. rerun
   `scripts/report_harmonization/check_h09_order56a_stopped_acceptance.R`
   under R 4.6.1 and require its complete 12/12 PASS result, including the
   91/91 owner seal, eight-file promotion, typography, 851 build paths, 275
   protected paths, render classification, and Sass-cache identity;
3. rehash the fixed result QMD `c738a436...`, stopped result HTML
   `dbc9122c...`, companion QMD `7563a933...`, held companion HTML
   `4054dfc6...`, profile `80dd0557...`, refresh script `ceaf4771...`, focused
   test `eefa3e27...`, builder `4711057e...`, figure manifest `74c0f444...`,
   semantic wrapper `28c11058...`, semantic engine `7c949930...`, and lockfile
   `3bf99c63...`;
4. require the eight promoted display outputs to retain the exact identities
   in the 39-row independent seal;
5. confirm the existing Sass database is user-owned and retains its stated
   preflight hash and byte count;
6. confirm the first failed semantic directory remains empty; and
7. confirm no competing Quarto, Pandoc, H09 render, semantic-hook, or loopback
   process is active.

Record this preflight in the new order-56b evidence root. If any project pin,
owner seal, cache identity, process condition, or protected identity fails,
stop without rendering.

## One environment-only render retry

From the project root, create one fresh, empty semantic-audit directory under
`/private/tmp`, then invoke the same H09 target and accepted profile exactly
once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> \
quarto render notebooks/hypotheses/H09.qmd --profile nathealth
```

Run this single command with narrow elevated filesystem access sufficient for
Quarto to read and transactionally update its existing user-owned Sass cache.
Do not change or repurpose `HOME`. Do not change `XDG_CACHE_HOME`, `DENO_DIR`,
the accepted R library, the renv-autoloader setting, the QMD, target, or
profile. Do not delete, clear, replace, redirect, copy, rename, chmod, or chown
any cache file. Quarto itself may make its normal transactional cache update
during this one render.

Record the Sass-cache filenames, byte counts, ownership, and hashes before and
after the render as mutable environment evidence. Do not copy cache contents
into the project or evidence tree.

If this attempt fails, stop and seal the complete one-attempt environment
result. No second retry, alternate target, profile bypass, or cache workaround
is authorized.

## Authorized writes

On a successful retry, writes are limited to:

- the canonical H09 result HTML and ordinary target-owned H09 result resources
  written by the one authorized render;
- normal profile-owned `search.json` and `sitemap.xml` updates;
- the fresh external semantic-audit directory; and
- new, bounded, non-circular retry, render, semantic, reconciliation,
  screenshot, visual-QA, lifecycle, and completion evidence under
  `audit/hypotheses/H09/report018_order56b_environment_retry/`.

All order-56 and order-56a evidence, figures, source files, tests, manifests,
QMDs, the held companion HTML, profile, lockfile, and scientific artifacts
must remain byte-identical.

## Successful-render continuation

If the render succeeds, continue without another Quarto invocation through
the complete post-render and reader-acceptance contract already defined by
order 56a:

1. require exactly 11 native `gt` tables and four figure endpoints in accepted
   order;
2. require exactly 23 reader-link occurrences and 21 unique targets;
3. verify the semantic summary and ledger, exact reversal and reapplication,
   document-wide unique IDs, and every explicit header token resolving once
   inside its table;
4. verify accepted H09 score directions, MCTQ MSFsc versus MEQ distinction,
   four five-outcome FDR families, hierarchy, qualifications, deviations,
   reciprocal links, navigation, and country labels;
5. reconcile rendered images to all eight promoted display files and all three
   frozen source CSVs;
6. require zero embedded error, warning, stderr, raw trace, unresolved
   reference, unsupported target, or local path;
7. classify only the target-owned render delta authorized above and preserve
   every companion, historical, scientific, profile, semantic-tool, and
   unrelated-document identity;
8. serve `_build/nathealth` read-only on one unused `127.0.0.1` high port and
   inspect the H09 result at 1440 by 1000, 708 by 1000, 720 by 500, and exact
   170-mm figure width;
9. inspect every table and all four figures, require at least 7.0 effective
   points for essential text, and reject clipping, overlap, broken wrapping,
   missing labels, inaccessible legends, or page overflow; and
10. close the QA tab, reset the viewport, stop the server, prove no listener
    remains, and require build and protected inventories to remain exact
    across QA.

Do not update `phase4_corpus_manifest.csv` in this result-only order.

## Prohibitions and mandatory stop

No source edit, QMD edit, figure regeneration, model, fit, refit, prediction,
simulation, bootstrap, resampling, estimate, interval, p-value, FDR decision,
diagnostic calculation, sensitivity, scientific artifact regeneration, full
builder, broad manifest builder, historical test or manifest rewrite, profile,
package, lockfile, ledger, companion render, later render, full-project render,
commit, push, upload, or publication action is authorized.

Return one non-circular completion or stopped package. The mandatory next stop
is independent acceptance of either the successful H09 result page or the
complete one-attempt environment failure package. The H09 companion and every
later render remain held.
