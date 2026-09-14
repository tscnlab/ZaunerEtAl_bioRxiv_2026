# REPORT-018 order 52: H07 result-page render and acceptance

Date: 2026-08-21

Owner: H07 owner `019fbe52-6781-7c32-bdcf-379c88ef1e78`

Status: released for exactly one H07 result-page render. The H07 companion and
every later REPORT-018 render remain held.

## Controlling authority

Central release is sealed at:

- `audit/report_harmonization/report018_h07_result_release.md`, SHA-256
  `2310116b3a9a768fa18b80965eee49d5ca4bca0b948f4f94ff2bb3c06739f583`,
  8,678 bytes;
- its 28-row non-circular manifest, SHA-256
  `dc1b187fc9868d50c7dc97ebc68b6d1f589fefe1458d1259994363fe595bf8f7`,
  4,242 bytes; and
- the completed central checker and 25-row pin input at SHA-256
  `b086f466a357288f2b26c2592cfc1b366e03959fe5271ebaebc6c2b241c4d8cd`
  and
  `a61e70c90b3b19cf7ac2b3dbc7408b5dfa299cc130310be2aa90bea496a19a7a`.

The preceding accepted Brown Stage 4 integration remains fixed under
acceptance
`9890452d0d970e37ed929823939898f2d13a8fbce910ad13912bc94568c54bd0`
and its 35-row manifest
`99ae012b5ca0988e8c54822f90038d7de748ef45b9ebe6f7fa5837dd3e7fa322`.

## Hard current pins

Before execution, require every non-matrix row in
`audit/report_harmonization/report018_h07_result_order52_dispatch_manifest.csv`
to match exactly. Key protected identities are:

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
  641,597 bytes;
- profile `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper and engine, SHA-256 `28c11058...` and `7c949930...`;
- current reader test, SHA-256
  `84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17`;
- held preparation test, SHA-256
  `89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558`;
- accepted near-eye and chest figures, SHA-256 `f19763fe...` and
  `2a714e19...`; and
- lockfile, SHA-256
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

The coordination matrix is dispatch-time evidence only. The H07 owner must
not edit it. The central release checker is completed pre-dispatch evidence
and must not be rerun after the expected matrix transition.

## Held companion classification

The accepted companion source uses dynamic
`../../../notebooks/hypotheses/H07.qmd` reader links. The unchanged preparation
test instead requires the stale hard-coded
`../../../notebooks/hypotheses/H07.html` literal. Preserve that test
byte-for-byte and do not execute it in this result-only order. Its complete
integration contract is deferred to the separately held H07 companion render.

This classification does not waive any scientific, source, link, semantic, or
reader-page requirement for the H07 result. The result reader test remains
required after rendering.

## Hard preflight

Before the render:

1. reproduce every non-matrix row in the order-52 dispatch manifest;
2. require 16 parseable R chunks, exactly 11 unique native `gt` table
   endpoints, two unique figure endpoints, and the exact nine relative reader
   targets recorded by the central checker;
3. require no fit, refit, prediction, bootstrap, simulation, resampling,
   derivative generation, p-value recalculation, artifact write, system call,
   or other scientific-regeneration call in the result source;
4. preserve the six-of-nine near-eye and seven-of-nine chest classifications,
   the exact three-part derivative rule, every sensitivity and limitation,
   and the conclusion that no physiological or environmental ceiling was
   identified;
5. inventory the complete `_build/nathealth` tree and all protected H07
   inputs, source data, figures, tests, manifests, both H07 QMDs and HTMLs,
   profile, hook, engine, lockfile, Brown endpoints, central ledgers, and
   shared phase-4 manifest;
6. require zero build symlinks and no competing Quarto, Pandoc, H07 semantic,
   or loopback process; and
7. create one fresh empty absolute semantic-audit directory under
   `/private/tmp`.

Stop before execution on any unclassified drift. Do not edit any source,
test, manifest, artifact, profile, package, lockfile, or ledger.

## Sole render command

Run exactly once through R 4.6.1, Quarto 1.9.37, the normal project profile,
and the accepted project `renv` library:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H07.qmd --profile nathealth
```

The established narrow elevated access to the existing user-owned `renv`
cache is authorized for this command. Do not bypass the project profile or
semantic hook. Do not use `--no-execute`, render the companion, render another
page, or render the full project.

The page may read and format accepted stored tables, source CSVs, registries,
and figures. It must not fit or refit a model, predict, bootstrap, simulate,
resample, regenerate derivatives, recalculate p-values, change a
classification, rebuild a scientific artifact, or alter a sample, formula,
estimate, interval, diagnostic, sensitivity, or claim.

## Required nonvisual acceptance

Require all of the following against the fresh result HTML:

1. Render exit 0 under R 4.6.1 and Quarto 1.9.37, with no embedded error,
   warning, stderr, unresolved cross-reference, or raw execution trace.
2. Exactly 11 native `gt` tables and two figures in accepted source order.
   Preserve every caption, note, value, row and column order, label, alt text,
   and paired source-data relationship.
3. Semantic-hook disposition `REPAIRED` or an independently justified
   already-repaired disposition. Retain the external summary and full
   reversible ledger. Require unique document IDs and every explicit
   `headers` token to resolve exactly once to its intended `th` inside the
   same table.
4. Reverse the semantic ledger into a temporary copy and require its hash to
   equal the recorded pre-hook hash. Prove visible text, values, element order,
   captions, notes, links, endpoint counts, and table geometry unchanged
   across the hook.
5. Run the unchanged H07 reader test against the fresh HTML. Preserve and do
   not execute the held preparation test.
6. Preserve the Answer in brief callout, the accepted result hierarchy, all
   nine relative reader targets, the reciprocal companion target,
   DEV-016/033/034 anchors, active navigation, and country-coded sites.
7. Preserve every accepted input, source CSV, durable figure, test, historical
   manifest, held companion QMD and HTML, profile, hook, engine, lockfile,
   central ledger, Brown endpoint, and unrelated source or build member
   byte-for-byte.
8. Classify the complete build delta. Only the H07 result HTML, normal
   target-owned source-identical resource copies, and expected search or
   sitemap integration changes may change. A target-generated display may
   change only after deterministic same-source and visible-content proof.
9. Keep `audit/report_harmonization/phase4_corpus_manifest.csv` byte-identical.
   Classify its H07 HTML row as the expected historical-to-fresh transition
   until later integration. Verify navigation and links directly against the
   fresh page.

## Secure loopback visual QA

Only after every nonvisual check passes:

1. preflight `_build/nathealth` again for symlinks;
2. serve exactly that directory read-only on one unused high port bound only
   to `127.0.0.1`;
3. inspect only the H07 result route at 1440 by 1000, 708 by 1000, and 720 by
   500 as the 200-percent-equivalent view;
4. inspect the complete reader flow, all 11 tables, both paired
   smooth-and-derivative figures, callouts, headings, captions, links,
   navigation, wrapping, disclosures, axes, legends, symbols, site codes,
   clipping, overlap, and page overflow;
5. exercise any contained narrow table scrollers without accepting page-level
   overflow;
6. inspect both exported figures at their intended 170 mm final size and
   require essential text of at least 7 points; and
7. record screenshots and measurements, stop the server, prove no listener
   remains, reset and close the QA surface, and rehash the complete build and
   protected inventories.

## Evidence and return

Write new order-52 execution, semantic, inventory, structural, visual, and
completion evidence only under
`audit/hypotheses/H07/report018_order52_result_render/` and the fresh external
semantic directory. The canonical target HTML and ordinary target-owned build
integration files are the only project outputs that the render itself may
replace.

Return one complete acceptance package or one consolidated fail-closed defect
list with one unique non-circular evidence manifest. Do not patch or rerender
within this order. Do not open another language or cosmetic cleanup loop.
Retain external semantic evidence until independent acceptance.

No H07 companion render or later target is released. No source, test,
historical or current manifest, scientific artifact, profile, ledger, package,
lockfile, manuscript, commit, push, upload, or publication change is
authorized.
