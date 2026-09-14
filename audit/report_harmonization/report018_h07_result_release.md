# REPORT-018 H07 result-page central concurrence and serial release

Date: 2026-08-21

Disposition: **RELEASED FOR EXACTLY ONE H07 RESULT RENDER**

The independently accepted Brown Stage 4 environment-recovery integration
clears the serial render gate. This release applies only to the H07 result
page. The H07 companion and every later REPORT-018 render remain held pending
separate independent result acceptance.

## Controlling acceptance and current pins

The preceding serial acceptance is:

- `audit/decisions/brown_adherence_stage4_order51_environment_retry_independent_acceptance.md`,
  SHA-256
  `9890452d0d970e37ed929823939898f2d13a8fbce910ad13912bc94568c54bd0`;
- its 35-row non-circular manifest, SHA-256
  `99ae012b5ca0988e8c54822f90038d7de748ef45b9ebe6f7fa5837dd3e7fa322`;
  and
- the H07 coordination baseline, SHA-256
  `8a98ad1997b8b25f46434a5b0376217ed58383e61dd1f7bddace48b15ed5b330`.

The released H07 pins are:

- result QMD `notebooks/hypotheses/H07.qmd`, SHA-256
  `c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226`,
  45,440 bytes;
- held companion QMD
  `audit/hypotheses/H07/H07_analysis_preparation.qmd`, SHA-256
  `a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b`,
  49,762 bytes;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H07.html`,
  SHA-256
  `c45058b98da10a0e86d8fc6ed6183cabe7997fdb33414942874102faf953068d`,
  239,136 bytes;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html`,
  SHA-256
  `53c261b88b5d10238e18e33323ad705c61c92215c040fc84880385cdc434fd2f`,
  641,597 bytes; and
- `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
  with the result and companion adjacent in both the render list and website
  navigation.

The semantic wrapper and accepted engine remain exact at `28c11058...` and
`7c949930...`. The lockfile remains `3bf99c63...`. R is 4.6.1 and Quarto is
1.9.37. No competing Quarto, Pandoc, semantic-hook, or H07 process was present
at release preflight.

The coordination-matrix row in the pin set is release-time evidence only. It
is not an owner execution pin because dispatching this order will truthfully
update that coordinator-owned file. The completed central checker must not be
rerun after that expected matrix transition. Every other pin remains a hard
owner preflight identity.

## Independent source and integration preflight

The read-only checker
`scripts/report_harmonization/check_h07_result_report018_release.R`, SHA-256
`b086f466a357288f2b26c2592cfc1b366e03959fe5271ebaebc6c2b241c4d8cd`,
passed under R 4.6.1 after Air 0.4.1 and R parse checks. Its 25-row pin input is
`audit/report_harmonization/report018_h07_result_release_pins.csv`, SHA-256
`a61e70c90b3b19cf7ac2b3dbc7408b5dfa299cc130310be2aa90bea496a19a7a`.

Fresh verification passed:

- 25/25 exact, unique release pins;
- 16 R chunks, 11 native `gt` table endpoints, and two figure endpoints in
  accepted source order;
- exactly nine relative reader targets, including DEV-016, DEV-033, and
  DEV-034, with every anchor resolving and no `IMP-008` target;
- zero fit, prediction, simulation, bootstrap, derivative-generation, or
  other prohibited analytical calls;
- the complete R 4.6.1 H07 reader test against the held page;
- accepted six-of-nine near-eye and seven-of-nine chest classifications, the
  exact three-part derivative rule, the gap-timing-unaware sensitivity, and
  the no-ceiling limitation; and
- zero symlinks in `_build/nathealth`.

The held preparation test has one stale integration assertion: it requires a
hard-coded `../../../notebooks/hypotheses/H07.html` source target while the
accepted companion correctly uses the dynamic
`../../../notebooks/hypotheses/H07.qmd` target. This assertion belongs to the
held companion integration. Preserve the preparation test byte-for-byte and
do not execute it in this result-only order.

## Sole authorized render

After reproducing every non-matrix hard pin, complete pre-render build and
protected inventories, zero build symlinks, no competing render process, and
one fresh empty absolute semantic-evidence directory under `/private/tmp`, run
exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H07.qmd --profile nathealth
```

Use the normal R 4.6.1 project startup and accepted `renv` library. The
established narrow elevated access to the existing user-owned `renv` cache is
authorized so the render does not enter the documented restricted-cache
startup loop. Do not bypass the project profile or semantic hook, render the
companion, render another page, or render the full project.

The page may read accepted stored tables, source CSVs, registries, and figures
and format their frozen values. It must not fit or refit a model, predict,
bootstrap, simulate, resample, regenerate derivatives, recalculate p-values,
change a classification, or rebuild a scientific artifact.

## Required result-page acceptance

After the sole render, require all of the following against the fresh result
HTML:

1. R 4.6.1 and Quarto 1.9.37, render exit 0, and no embedded error, warning,
   stderr, unresolved cross-reference, or raw execution trace.
2. Exactly 11 native `gt` tables and two figures in accepted source order,
   with every endpoint, caption, note, value, label, alt text, and paired
   source relationship preserved.
3. Semantic-hook disposition `REPAIRED` or an independently justified
   already-repaired disposition. Retain the external summary and complete
   reversible ledger. Require unique document IDs and every explicit
   `headers` token to resolve exactly once to its intended `th` inside its own
   table. Reverse the ledger in a temporary copy and require the recorded
   pre-hook identity.
4. Preserve the Answer in brief callout, the six-of-nine and seven-of-nine
   classifications, the derivative-defined plateau pattern, the
   gap-timing-unaware sensitivity, and all qualifications that the result is
   descriptive and does not establish a ceiling, mechanism, causal effect, or
   distinct latitude effect.
5. Preserve all nine relative reader links, the reciprocal companion target,
   DEV-016/033/034 anchors, active navigation, and all country-coded sites.
6. Run the unchanged H07 reader test against the fresh HTML. Do not execute,
   edit, or classify the held preparation test in this result-only order.
7. Preserve every accepted input, source CSV, durable figure, test, historical
   manifest, companion QMD and HTML, profile, hook, engine, lockfile, central
   ledger, Brown endpoint, and unrelated build member byte-for-byte.
8. Classify the complete build delta. Only the H07 result HTML, normal
   target-owned source-identical resource copies, and expected search or
   sitemap integration changes may change. Any target-regenerated display
   requires deterministic same-source and visible-content verification.
9. Keep `audit/report_harmonization/phase4_corpus_manifest.csv` byte-identical.
   Its H07 HTML row becomes one expected historical-to-fresh transition until
   later integration. Verify navigation and links directly against the fresh
   page.

## Secure loopback visual QA

Only after all nonvisual checks pass, serve exactly `_build/nathealth` from one
temporary read-only server bound only to `127.0.0.1`. Inspect only the H07
result route at 1440 by 1000, 708 by 1000, and a 720 by 500 200-percent
equivalent view.

Inspect the complete reader flow, all 11 tables, both paired smooth-and-
derivative figures, callouts, headings, captions, links, navigation, wrapping,
disclosures, axes, legends, symbols, site codes, clipping, overlap, and page
overflow. Inspect the two exported figures at their intended 170 mm final size
and require essential text of at least 7 points. A genuinely wide table may
use a visible contained horizontal scroller at narrow width if it does not
create page-level overflow.

Stop the server immediately after QA. Prove that neither its process nor a
listener remains, reset the viewport, close the QA tab, and rehash the source,
profile, result target, held companion, complete build, and protected
inventories.

## Return and hold

Return one complete acceptance package or one consolidated fail-closed defect
list. Do not patch or rerender within this order. Do not open another language
or cosmetic cleanup loop. Retain semantic evidence until independent
acceptance.

No H07 companion render or later target is released. No source, test,
historical or current manifest, scientific artifact, profile, ledger, package,
lockfile, commit, push, upload, or publication change is authorized.
