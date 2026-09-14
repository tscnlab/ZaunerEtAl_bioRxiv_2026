# REPORT-018 owner order 60a: H11 Sass-cache environment retry

Date: 2026-08-22

Owner: H11 task `019fba59-0f3c-74a0-ab3d-58d389365ad1`

Scope: one environment-only retry of the unchanged H11 result target

Status: `SEALED_FOR_ONE_DISPATCH`

## Authority and disposition

Order 60 is independently accepted at an environment-only stop under
`audit/report_harmonization/report018_h11_order60_environment_stop_independent_acceptance.md`.
The owner render completed all 53 knitr cells and stopped before HTML
production only because sandboxed Quarto could not open its user-owned macOS
Sass database.

R 4.6.1 verifies the owner seal 58/58, original dispatch 30/30, complete
preflight 28/28, build tree 1,180/1,180, protected state 336/336, and H11
scientific assets 193/193. Both QMDs, the stale result HTML, held companion
HTML, profile, lockfile, helper, tests, manifests, handoff, sensitivity source,
and sensitivity HTML are exact. The first semantic directory is empty and no
related process remains.

The established environment route is
`/Users/zauner/Library/Caches/quarto/sass/sass.kv`. The database is owned by
user `zauner`, is 36,864 bytes, has SHA-256
`22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`,
and reports schema version 1 under the Quarto-bundled Deno probe. This order
changes only the execution permission boundary for one replacement render.

## Exact preflight

Before executing Quarto, the owner must:

1. reproduce the non-circular Order 60a dispatch manifest exactly;
2. reproduce the independent Order 60 environment-stop acceptance manifest;
3. run
   `scripts/report_harmonization/check_report018_h11_order60_environment_stop.R`
   under R 4.6.1 and require 14/14 PASS;
4. run the existing complete H11 checker with `H11_RESULT_PHASE=preflight`
   against one new Order 60a evidence directory and require its complete 13/13
   PASS, including the exact two Stage 3 and four held preparation transition
   sets, both transition-aware tests, 193 scientific assets, and 34
   source-identical build resources;
5. require the unchanged current H11 coordination status
   `active_order60_h11_result_target_render`, with its render gate advanced to
   the separately sealed Order 60a environment retry;
6. require the result QMD `7909ba06...`, stale result HTML `c5724711...`, held
   companion QMD `3f5a0d2e...`, held companion HTML `fd6307a6...`, profile
   `80dd0557...`, lockfile `3bf99c63...`, sensitivity source `d2d17770...`, and
   sensitivity HTML `b9af89c0...` exact;
7. require zero symlinks below `_build/nathealth`;
8. require the existing Sass database to retain its accepted path, ownership,
   byte count, hash, and schema version, with no WAL or SHM file;
9. require the first failed semantic directory to remain empty; and
10. use the established elevated read-only process inventory to require no
    competing H11, Quarto, Pandoc, semantic-hook, or task-owned loopback
    process. Unrelated services, including LightLogWeb, must remain untouched.

Stop before rendering on any failed project pin, cache identity, process
condition, build condition, or protected identity.

## One environment-only render retry

Create one fresh empty absolute semantic-audit directory under `/private/tmp`.
From the project root, invoke exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library \
quarto render notebooks/hypotheses/H11.qmd --profile nathealth
```

Run this command with narrow elevated filesystem access sufficient for Quarto
to use its existing user-owned Sass cache. Do not change `HOME`,
`XDG_CACHE_HOME`, `DENO_DIR`, the R library, the renv-autoloader setting,
target, QMD, or profile. Do not delete, clear, replace, redirect, copy, rename,
chmod, or chown a cache file. Quarto itself may perform its normal
transactional cache access during this one render.

If this attempt fails, stop and seal the complete one-attempt state. No second
retry, cache workaround, alternate target, profile bypass, or source repair is
authorized.

## Successful-render continuation

If the render exits 0 and the configured semantic hook completes, continue
without another Quarto invocation through the unchanged Order 60 acceptance
contract:

1. run the existing durable checker once with
   `H11_RESULT_PHASE=postrender`, the exact fresh semantic directory, and the
   Order 60a evidence root;
2. require exactly one `main#quarto-document-content`, 15 native `gt` tables,
   eight source-ordered figure endpoints, complete captions and alt text, and
   no embedded error, warning node, unresolved reference, privacy token,
   broken link, or missing fragment;
3. require exact semantic summary and ledger reversal and reapplication,
   unique document IDs, and every scoped table-header token resolving exactly
   once in its table;
4. require the immutable Stage 3 and held preparation manifests to have only
   their already classified transitions plus the one new result-HTML
   transition, with no additional mismatch;
5. require both transition-aware tests to pass from temporary copies while
   project tests remain exact;
6. require zero helper and preparation-test executions, all 193 scientific
   assets exact, all 34 H11 target resources source-identical, and the held
   companion, profile, lockfile, handoff, and sensitivity identities exact;
7. classify only the result HTML plus normal profile-owned `search.json` and
   `sitemap.xml` target synchronization, with zero added or removed build path
   and zero symlinks; and
8. record the Sass-cache filenames, byte counts, ownership, and hashes before
   and after the render as environment evidence. Do not copy cache contents
   into the project or evidence tree.

Only after every post-render check passes, apply the active
`$quarto-authoring` QA boundary:

1. repeat the zero-symlink preflight;
2. serve only `_build/nathealth` on one unused high port bound to
   `127.0.0.1`;
3. inspect `/notebooks/hypotheses/H11.html` at 1,440 by 1,000, 708 by 1,000,
   and 720 by 500;
4. inspect all 15 tables and eight figures, disclosures, scrollers, captions,
   alt text, navigation, reciprocal links, and central deviation links;
5. inspect every exported figure at 642 pixels, the exact 170-mm width, and
   require essential text of at least 7 points;
6. reject page overflow, clipping, overlap, missing content, broken
   interaction, or page-attributable console warning or error; and
7. close or reset the QA surface, stop the server, prove no listener remains,
   rerun the no-drift gate, and require byte-identical build inventories across
   QA.

## Authorized writes and prohibitions

On success, writes are limited to the canonical H11 result HTML and ordinary
target-owned result resources, normal `search.json` and `sitemap.xml` updates,
the fresh external semantic directory, and new bounded non-circular Order 60a
render, semantic, reconciliation, screenshot, visual-QA, lifecycle, and
completion evidence under
`audit/hypotheses/H11/report018_order60a_environment_retry/`.

No QMD, test, helper, manifest, handoff, profile, package, lockfile, source
data, model, estimate, interval, p-value, FDR decision, diagnostic, scientific
artifact, companion, or sensitivity file may change. No analysis, helper,
preparation test, companion render, sensitivity execution, later target,
full-project render, commit, push, or upload is authorized.

Return one non-circular completion or stopped package. The mandatory next stop
is independent acceptance of the successful H11 result page or the complete
single-retry environment failure. H11 companion and the sensitivity battery
remain held.
