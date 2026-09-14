# REPORT-018 order 38: Supplementary information target render

Date: 2026-08-20

Owner: shared-page coordinator task `019faf58-3df3-7383-8034-f715cdfdd154`

Status: **AUTHORIZED ONCE**

H01 result and companion integration and the H02 result integration are
independently accepted. Under REPORT-018, the shared Supplementary information
page is the sole active render target. The H02 companion and every later target
remain held until this page is independently accepted.

## Controlling authority and pins

- REPORT-018 decision:
  `audit/decisions/report_harmonization_render_completion_priority.md`,
  SHA-256
  `0cb7c62806b40c1702c7fdde994d98090f0fc820abfa32205a8e58e392681ecf`;
- scheduling addendum:
  `audit/report_harmonization/report017_render_completion_scheduling_override.md`,
  SHA-256
  `117dfedc650dc035b74978a7621cac8ef7bf14c8caf4533d0a94f7fecb1b52e0`;
- H02 result acceptance:
  `audit/report_harmonization/report018_h02_result_independent_acceptance.md`,
  SHA-256
  `13a5121a00974e7660b7b045319c945e3c84a56a7ea13b2d72e23b16d204ab4d`;
- source: `supplementary_information.qmd`, SHA-256
  `8d013e4d37ca5ff438988e82907a26d65b98a9a47cc2d62ec3ddcd0e2b3862fa`;
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- base Quarto configuration: `_quarto.yml`, SHA-256
  `44e4a7435494d570baca6e7b0de75b15be015a52c811c076dd2b8b959d70f59c`;
- bibliography: `bibliography.bib`, SHA-256
  `a8f9799d8dd02d097586f7b95d241997e7bee724d0197332e252a6cda263f249`;
- CSL: `nature.csl`, SHA-256
  `15b1272a3c360168e0b51ab9257534b08ced67190ed57be7a1c32cea8fc87be8`;
- site CSS: `styles.css`, SHA-256
  `557cf99b617ba158611d5326a76716c871f7373357e11d0295012600c0e6994b`;
- semantic wrapper:
  `scripts/report_harmonization/post_render_gt_html_semantics.R`, SHA-256
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine:
  `scripts/report_harmonization/repair_gt_html_semantics.R`, SHA-256
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- corpus builder:
  `scripts/report_harmonization/build_phase4_corpus_manifest.R`, SHA-256
  `c01f0dc86e25bcf4a37685515cd692e2007774a004a4e902eac5936521749e2e`;
- navigation test:
  `tests/report_harmonization/test_navigation_contract.R`, SHA-256
  `1ba59346328e8e4fb2aa898c5806313763711867514097969f5e4df1c22d3407`;
- reader-link test:
  `tests/report_harmonization/test_reader_links.R`, SHA-256
  `3b4164069b36493a643886d87065cffd1b5ca644854d4e3be12db0ac9e8aee21`;
- pre-render corpus manifest:
  `audit/report_harmonization/phase4_corpus_manifest.csv`, SHA-256
  `b838a2d10b7cbe7a080bfbaecf5c018295a50d0132c40a00acca8d9e17e9ea84`;
- accepted H02 result HTML:
  `_build/nathealth/notebooks/hypotheses/H02.html`, SHA-256
  `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`.

Quarto must be 1.9.37 and R must be 4.6.1 under the normal project and
`renv` startup. The established narrow access to the existing user-owned
`renv` cache is allowed if startup requires it.

## Scope and sole render command

The source is an accepted static assembly outline. It contains no executable
cell, inline R expression, table endpoint, figure endpoint, or cross-reference.
Do not edit it and do not open a content, language, or output-role review.
Acceptance in this order concerns current target rendering, shared navigation,
link resolution, and page integrity only. Final Supplementary Information
content remains a later authoring task.

Before rendering, require the target HTML to be absent, record complete
`_build/nathealth` and protected-source inventories, reject output-tree
symlinks, verify every hard pin, and confirm that no Quarto or project-local R
process is active. Create one fresh absolute semantic-audit directory under
`/private/tmp` and retain it through independent acceptance.

Execute exactly once:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render supplementary_information.qmd --profile nathealth
```

The semantic hook must return `NO_GT` for the target. Do not use
`--no-execute`, `quarto preview`, a full-project render, or any second Quarto
command.

## Post-render contract

After the render:

1. Require the target HTML, correct title, all accepted outline headings,
   active Supplementary navigation, zero native `gt` tables, zero figures,
   zero raw error or stderr nodes, and zero unresolved cross-references.
2. Rebuild only
   `audit/report_harmonization/phase4_corpus_manifest.csv` with the accepted
   builder. Require 37 unique accepted sources and 37 existing target HTML
   files with nonempty hashes.
3. Run the navigation and reader-link tests under R 4.6.1. Require all dynamic
   QMD targets and all 86 deviation anchors to resolve. Classify external HTTPS
   actions as external before checking internal paths.
4. Reconcile the complete protected-source inventory byte-for-byte. Classify
   the complete build delta. Only the Supplementary target and ordinary
   target-render search or sitemap changes may contain new bytes. Any other
   content change is a hard stop.
5. Serve only `_build/nathealth` from one read-only static server bound to
   `127.0.0.1`. Inspect only the exact Supplementary route at 1440 x 1000 and
   708 x 1000. Check title, headings, sidebar state, prose wrapping, links,
   page-level overflow, clipping, and narrow navigation usability.
6. Stop the server immediately after QA, prove process exit and no listener,
   then require post-QA source, profile, target, protected, and complete build
   identities to match their post-render state.

Return one non-circular acceptance record and manifest, or one consolidated
fail-closed stopped record. Record commands, versions, timings, pre/post
inventories, hook evidence, test output, build delta, visual measurements,
screenshots, server lifecycle, and final identities.

## Prohibitions

No source QMD, profile, scientific input, model, artifact, ledger, manuscript,
package, lockfile, or existing target may be edited. Do not calculate or alter
scientific results. Do not commit, push, upload, publish, delete, render the H02
companion, or release any later page.
