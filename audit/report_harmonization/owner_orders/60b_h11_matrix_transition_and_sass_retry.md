# REPORT-018 owner order 60b: H11 matrix-transition classification and Sass retry

Date: 2026-08-22

Owner: H11 task `019fba59-0f3c-74a0-ab3d-58d389365ad1`

Scope: corrected preflight classification and the still-unconsumed H11 result retry

Status: `SEALED_FOR_ONE_DISPATCH`

## Authority and disposition

Order 60a is independently accepted at a pre-render evidence-classification
stop under
`audit/report_harmonization/report018_h11_order60a_preflight_stop_independent_acceptance.md`.
No Quarto command, elevated cache access, semantic hook, post-render checker,
server, or browser QA ran. The one-attempt environment retry remains
unconsumed.

The sole defect was that the mandated Order 60 environment checker required
the historical 58-row owner seal to remain 58/58 live-exact even though the
Order 60a dispatch explicitly advanced the coordination matrix. The exact
transition is sealed and independently classified. All other historical rows
remain live-exact.

This order changes no file or scientific authority. It substitutes the new
exact transition-aware preflight checker for the single incompatible
environment-stop checker invocation, then preserves the rest of Order 60a
unchanged.

## Coordination boundary

The shared coordination matrix must remain byte-identical at SHA-256
`c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac`,
42,552 bytes. Its H11 row retains
`active_order60_h11_result_target_render`, which is required by the complete
H11 preflight and post-render checker. The matrix also retains the Order 60a
environment-retry gate. This Order 60b dispatch is recorded by its own durable
receipt and must not cause another matrix transition.

## Corrected exact preflight

Before Quarto, the owner must:

1. reproduce the non-circular Order 60b dispatch manifest exactly;
2. reproduce the independent Order 60a preflight-stop acceptance manifest;
3. run
   `scripts/report_harmonization/check_report018_h11_order60a_preflight_stop.R`
   under R 4.6.1 and require 8/8 PASS, including the owner 46/46 seal, the
   historical 57-plus-matrix and 35-plus-matrix classifications, the exact
   current matrix, unconsumed retry, held scopes, and unchanged Sass database;
4. do not rerun
   `scripts/report_harmonization/check_report018_h11_order60_environment_stop.R`;
   preserve its first Order 60a failure as historical evidence;
5. run the unchanged complete H11 checker with `H11_RESULT_PHASE=preflight`
   against one new Order 60b evidence directory and require its complete 13/13
   PASS, including H10 closure, the two Stage 3 and four held preparation
   transitions, both transition-aware tests, 15 tables, eight figures, 193
   scientific assets, and 34 source-identical build resources;
6. require the fixed result QMD `7909ba06...`, stale result HTML `c5724711...`,
   held companion QMD `3f5a0d2e...`, held companion HTML `fd6307a6...`, profile
   `80dd0557...`, lockfile `3bf99c63...`, sensitivity QMD `d2d17770...`, and
   sensitivity HTML `b9af89c0...` exact;
7. require zero symlinks below `_build/nathealth`;
8. require the existing user-owned Sass database to retain its accepted path,
   36,864-byte size, SHA-256 `22f60821...`, ownership, schema version 1, and no
   WAL or SHM file;
9. require both prior failed semantic directories to remain empty; and
10. use the established elevated read-only process inventory to require no
    competing H11, Quarto, Pandoc, semantic-hook, or task-owned loopback
    process. Leave unrelated services untouched.

Stop before Quarto on any failed condition.

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
`XDG_CACHE_HOME`, `DENO_DIR`, the R library, renv-autoloader setting, target,
QMD, or profile. Do not delete, clear, replace, redirect, copy, rename, chmod,
or chown a cache file. Quarto itself may perform normal transactional cache
access during this one render.

If the command fails, stop and seal the complete one-attempt state. No second
retry, alternate target, profile bypass, cache workaround, or source repair is
authorized.

## Successful-render continuation

On exit 0 with successful semantic repair, continue without another Quarto
command through the complete Order 60 contract:

1. run the unchanged durable checker once with
   `H11_RESULT_PHASE=postrender`, the exact fresh semantic directory, and the
   Order 60b evidence root;
2. require exactly one `main#quarto-document-content`, 15 native `gt` tables,
   eight source-ordered figures, complete captions and alt text, and no
   embedded error, warning node, unresolved reference, privacy token, broken
   link, or missing fragment;
3. require exact semantic reversal and reapplication, unique document IDs,
   and every scoped table-header token resolving exactly once in its table;
4. require only the previously accepted historical manifest transitions plus
   the one fresh result-HTML transition, with no additional mismatch;
5. require both transition-aware tests to pass from temporary copies while
   project tests remain exact;
6. require zero helper and preparation-test executions, all 193 scientific
   assets exact, all 34 target resources source-identical, and the held
   companion, profile, lockfile, handoff, and sensitivity identities exact;
7. classify only the result HTML plus normal profile-owned `search.json` and
   `sitemap.xml` synchronization, with zero added or removed build path and
   zero symlinks; and
8. record the Sass-cache inventory before and after as mutable environment
   evidence without copying cache contents into the project.

Only after post-render PASS, apply the active `$quarto-authoring` boundary:

1. repeat the zero-symlink preflight;
2. serve only `_build/nathealth` on one unused high port bound to
   `127.0.0.1`;
3. inspect `/notebooks/hypotheses/H11.html` at 1,440 by 1,000, 708 by 1,000,
   and 720 by 500;
4. inspect all 15 tables, eight figures, scrollers, disclosures, captions,
   alt text, navigation, reciprocal links, and deviation links;
5. inspect exported figures at 642 pixels and exact 170-mm width, requiring at
   least 7-point essential text;
6. reject overflow, clipping, overlap, missing content, broken interaction, or
   page-attributable console warning or error; and
7. close or reset the QA surface, stop the server, prove no listener remains,
   rerun the no-drift gate, and require byte-identical build inventories across
   QA.

## Writes, prohibitions, and stop

On success, writes are limited to the canonical H11 result HTML and ordinary
target-owned resources, normal `search.json` and `sitemap.xml` updates, the
fresh external semantic directory, and new bounded non-circular Order 60b
render, semantic, reconciliation, screenshot, visual-QA, lifecycle, and
completion evidence under
`audit/hypotheses/H11/report018_order60b_environment_retry/`.

No QMD, source, test, helper, historical manifest, handoff, profile, package,
lockfile, model, estimate, interval, p-value, FDR decision, diagnostic,
scientific artifact, companion, or sensitivity file may change. No analysis,
helper, preparation test, companion render, sensitivity execution, later
target, full-project render, commit, push, or upload is authorized.

Return one non-circular completion or stopped package. The mandatory next stop
is independent acceptance of the successful H11 result page or the complete
single-retry environment failure. H11 companion and sensitivity remain held.
