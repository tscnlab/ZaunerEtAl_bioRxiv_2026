# REPORT-018 owner order 60: H11 result-only render

Date: 2026-08-22  
Owner: H11  
Scope: one H11 result render and complete result-page acceptance  
Status: sealed for one dispatch

## Controlling acceptance and preflight

H10 result and companion are independently closed under
`audit/report_harmonization/report018_h10_order59a_companion_independent_acceptance.md`.
The complete H11 read-only preflight is sealed at
`audit/report_harmonization/report018_h11_result_complete_preflight.md`.
The durable checker
`scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R`
must return the exact preflight PASS before any render.

This order authorizes exactly one H11 result target. H11 companion integration
and the H11 sensitivity battery remain held.

## Hard preflight

Before any Quarto command:

1. reproduce every hard row of the order-60 dispatch manifest;
2. run the durable checker with `H11_RESULT_PHASE=preflight` and require PASS;
3. require the fixed identities in the controlling preflight, including result
   QMD `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`,
   held companion QMD `3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816`,
   stale result HTML `c5724711ad1aa94631df0b6186fee92398d414ae02690ade08f320b29d6b6db7`,
   held companion HTML `fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11`,
   profile `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
   and both held sensitivity identities;
4. preserve the historical Stage 3 and preparation manifests byte-for-byte,
   with exactly the two and four pre-render transition sets sealed by the
   preflight;
5. snapshot the complete build and protected inventories before rendering;
6. require all 193 scientific assets and all 34 source-identical build
   resources exact;
7. repeat the `_build/nathealth` symlink preflight and require zero symlinks;
8. use elevated read-only process inventory only if the sandbox denies it, and
   require no competing H11, Quarto, Pandoc, semantic-hook, or loopback
   process; and
9. create one fresh empty absolute semantic-audit directory outside the
   project and evidence trees.

Stop before rendering on any additional drift. Do not edit a QMD, test,
helper, manifest, handoff, profile, source data, scientific artifact, package,
or lockfile.

## Sole result render

From the project root, run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library \
quarto render notebooks/hypotheses/H11.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the knitr engine, the accepted normal profile, and
the configured semantic hook. Do not use a full-project render, alternate
profile, profile bypass, QMD execution outside this command, or second render.
If startup, knitr, Pandoc, semantic repair, or target production fails, stop
and seal the exact state without retry.

This render may only read frozen H11 outputs. No model fit or refit,
prediction, contrast, p-value or FDR calculation, bootstrap, simulation,
resampling, model selection, source-data change, or scientific artifact write
is authorized.

## Complete post-render verification

Run the durable checker once with `H11_RESULT_PHASE=postrender`, the exact
external semantic directory, and one new H11 order-60 evidence directory. It
must verify all of the following before browser QA:

1. exactly one `main#quarto-document-content`, 15 native `gt` tables, and the
   exact eight source-ordered figure endpoints;
2. semantic-hook completion, zero duplicate document IDs, every scoped table
   header token resolving exactly once inside its table, and exact raw reversal
   and reapplication of the accepted HTML;
3. nonempty captions and alt text, no embedded error, warning node, unresolved
   reference, privacy token, broken link, or missing fragment;
4. the complete live Stage 3 and REPORT-016 contracts using temporary
   transition-aware copies only, while both project tests remain byte-exact;
5. the immutable Stage 3 manifest at exactly 66 live-exact rows plus the two
   accepted pre-render transitions and the one result-HTML transition whose
   live SHA-256 equals the semantic summary's `post_sha256`, with no fourth
   mismatch;
6. the held preparation manifest at exactly its four accepted source/profile
   transitions plus the result-HTML transition, with no sixth mismatch;
7. zero helper executions and zero preparation-test executions;
8. all 193 scientific assets, result source, held companion source and HTML,
   profile, lockfile, handoff, and sensitivity source and HTML exact;
9. every one of the 34 H11 target resources still source-identical; and
10. a complete build content delta confined to
    `_build/nathealth/notebooks/hypotheses/H11.html`,
    `_build/nathealth/search.json`, and `_build/nathealth/sitemap.xml`, with no
    added or removed build path and zero symlinks.

Any new mismatch is a fail-closed stop. Do not patch, run a helper or broad
manifest builder, edit a test, or rerender.

## Secure-loopback visual QA

Only after complete post-render verification passes:

1. repeat the mandatory zero-symlink audit of `_build/nathealth`;
2. serve only `_build/nathealth` read-only on one unused high port bound only
   to `127.0.0.1`;
3. inspect the exact route `/notebooks/hypotheses/H11.html` at 1,440 by 1,000,
   708 by 1,000, and 720 by 500 as the 200-percent-equivalent view;
4. inspect all 15 tables and eight figures in source order, including the main
   `tbl-h11-global-tests`, near-eye and chest displays, table scrollers,
   disclosures, captions, alt text, navigation, reciprocal links, and central
   deviation links;
5. require no page overflow, clipping, overlap, missing content, broken
   interaction, or page-attributable console warning or error;
6. inspect each exported figure at 642 pixels, the exact 170-mm final width,
   and require essential text of at least 7 points; and
7. close or reset the QA surface, stop the loopback server, and prove no
   listener remains.

Rerun the post-render checker in post-QA mode or perform its exact no-drift
equivalent. Require byte-identical build inventories across QA and exact
protected, source, scientific, companion, profile, and sensitivity identities.

## Return boundary

Return one non-circular owner acceptance manifest and completion record, or
one consolidated fail-closed record. Record R, Quarto, and consequential
package versions; the single render command and exit status; semantic summary,
ledger, reversal, build delta, protected delta, link audit, screenshots,
visual observations, server lifecycle, and no-listener proof.

No H11 companion render, sensitivity-battery execution, alternate H11 render,
later target, full-project render, source repair, helper, historical test or
manifest edit, scientific computation, profile or ledger change, package or
lock change, commit, push, or upload is authorized.
