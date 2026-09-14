# REPORT-018 order 48: H06_daily complementary result render

Date: 2026-08-21

Owner: H06_daily owner `019fec6a-20d3-7710-ab9b-a035e0874182`

Status: released for exactly one H06_daily result-page render. The H06_daily
companion and every later target remain held.

## Controlling authority

Central release is sealed at:

- `audit/report_harmonization/report018_h06_daily_result_release.md`, SHA-256
  `20ab904bbe4bcbd2a7c8b8abcf434a8ed2c033d0db6682589bcbaec07aaa2137`,
  9,205 bytes;
- its 28-row non-circular manifest, SHA-256
  `14e42dcb2c0037589acb4520f1f39e55313c3a43704713aef447d32cfb22ed59`,
  4,376 bytes; and
- the read-only release checker and 25-row pin input at SHA-256
  `5ce08094b2cb1f2c3ac8e0fabe687f6aa54a39d82b064c0b4661ea605abbca0e`
  and
  `046090c99b323257e9c4b8a1311bcb92054c6474d1d8241ad7bd549ec9c15831`.

The accepted hourly H06 result and companion remain fixed under acceptance
`046537d759b39e6ce622e7e2dcbbb215c064046212e0c355c97ac047231af562`
and its 37-row manifest
`6bb0e432dfbadb1e65adab639eeb22ed56d05f8c42f6eb0f0faa19ef65fd3770`.

## Hard current pins

Before execution, require all non-matrix rows in
`audit/report_harmonization/report018_h06_daily_order48_dispatch_manifest.csv`
to match exactly. Key protected identities are:

- result QMD `notebooks/hypotheses/H06_daily.qmd`, SHA-256
  `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`,
  65,344 bytes;
- held companion QMD
  `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`, SHA-256
  `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`,
  35,409 bytes;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H06_daily.html`,
  SHA-256
  `5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3`,
  3,617,976 bytes;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`,
  SHA-256
  `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`,
  4,613,650 bytes;
- profile `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper and engine, SHA-256 `28c11058...` and `7c949930...`;
- historical reader test, SHA-256
  `16e3d02bbfe443928708a8a6e2c793a04c47281afaa8993116e1c27d0bdaa8d2`;
- accepted site-deviation PNG, SHA-256
  `a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1`;
  and
- package lock, SHA-256
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

The coordination matrix is dispatch-time evidence only. The H06_daily owner
must not edit it. The central release checker is completed pre-dispatch
evidence and must not be rerun after the expected matrix transition.

## Historical evidence classifications

Preserve the historical reader test and all H06_daily manifests byte-for-byte.
They retain exactly three accepted REPORT-014 classifications:

1. historical result QMD `0318fd6c...` to accepted editorial QMD
   `01213a19...`;
2. historical site-deviation PNG `69fd3786...` to accepted display-only PNG
   `a1ddd2ae...`; and
3. historical link wording `main H06 analysis` to accepted wording
   `hourly H06 analysis`.

The historical figure-readability manifest contains only the same accepted
PNG transition. No fourth mismatch is accepted. Do not run the unchanged
historical live-identity gates after rendering. For current scientific and
reader assertions, use an owner-local read-only in-memory reconciliation of
only these exact three classifications or the already accepted central
preflight evidence.

## Hard preflight

Before the render:

1. reproduce every non-matrix row in the order-48 dispatch manifest;
2. require the source to retain 15 parseable R chunks, exactly 14 unique
   native `gt` table endpoints, five unique figure endpoints, and seven
   dynamic QMD links;
3. require no fit, refit, prediction, bootstrap, simulation, resampling,
   p-value or FDR recalculation, artifact write, system call, or other
   scientific-regeneration call in the result source;
4. inventory the complete `_build/nathealth` tree, all H06_daily protected
   inputs and durable outputs, both H06_daily QMDs and HTMLs, hourly H06
   endpoints, profile, hook, engine, lockfile, shared phase-4 manifest, and
   central ledgers;
5. require zero build symlinks and no competing Quarto, Pandoc, H06_daily
   semantic, or loopback process; and
6. create one fresh empty absolute semantic-audit directory under
   `/private/tmp`.

Stop before execution on any unclassified drift. Do not edit any source,
test, manifest, artifact, profile, package, lockfile, or ledger.

## Sole render command

Run exactly once through normal R 4.6.1, Quarto 1.9.37, project-profile, and
`renv` startup, with only the established narrow access to the existing
user-owned cache:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06_daily.qmd --profile nathealth
```

Do not use `--no-execute`, bypass the semantic hook, render the companion,
render another page, or render the full project.

The page may read accepted stored tables, source CSVs, registries, and figures
and format their frozen values. It must not fit or refit a model, predict,
bootstrap, simulate, resample, recalculate p-values or FDR decisions,
regenerate a scientific artifact, or change a sample, formula, estimate,
interval, diagnostic, sensitivity, or claim.

## Required nonvisual acceptance

Require all of the following against the fresh result HTML:

1. Render exit 0 under R 4.6.1 and Quarto 1.9.37, with no embedded error,
   warning, stderr, unresolved cross-reference, or raw execution trace.
2. Exactly 14 native `gt` tables and five figures in accepted source order.
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
5. Preserve the Answer in brief callout, the accepted hourly-main and
   complementary-daily hierarchy, all seven dynamic QMD links, the reciprocal
   companion target, DEV-015/030/031/032 anchors, active navigation, and all
   nine country-coded sites.
6. Preserve every accepted input, source CSV, durable figure, historical
   test and manifest, held companion QMD and HTML, hourly H06 source and HTML,
   profile, hook, engine, lockfile, central ledger, and unrelated source or
   build member byte-for-byte.
7. Classify the complete build delta. Only the result HTML, normal target-owned
   source-identical resource copies, and expected search or sitemap integration
   changes may change. Any deterministically regenerated target display must
   be reproduced from the same frozen source and independently prove unchanged
   scientific and visible content.
8. Keep `audit/report_harmonization/phase4_corpus_manifest.csv` byte-identical.
   Classify its H06_daily HTML row as the expected historical-to-fresh target
   transition pending the companion or shared integration step. Verify
   navigation and links directly against the fresh page.

## Secure loopback visual QA

Only after all nonvisual checks pass:

1. preflight `_build/nathealth` again for symlinks;
2. serve exactly that directory read-only on one unused high port bound only
   to `127.0.0.1`;
3. inspect only the exact H06_daily result route in the supported in-app
   Browser at 1440 by 1000, 708 by 1000, and 720 by 500 as the
   200-percent-equivalent view;
4. inspect the complete reader flow, all 14 tables, all five figures, the
   Answer in brief callout, headings, captions, source links, navigation,
   wrapping, disclosures, axes, legends, symbols, site codes, clipping,
   overlap, and page overflow;
5. apply the accepted table policy: HTML tables must work reasonably at a
   typical desktop or laptop size; at narrow width, a genuinely wide table may
   use a visible contained horizontal scroller without page-level overflow;
6. inspect all five exported figures at their intended final sizes and require
   essential text of at least 7 points; and
7. record screenshots and measurements, stop the server, prove no listener
   remains, reset and close the QA surface, and rehash the complete build and
   protected inventories.

## Return and prohibitions

Return one complete acceptance package or one consolidated fail-closed defect
list. Do not patch or rerender within this order. Retain the external semantic
evidence until independent acceptance.

No source, test, historical or current manifest, scientific artifact, profile,
ledger, package, lockfile, manuscript, navigation, commit, push, upload, or
publication change is authorized. H06_daily companion and every later
REPORT-018 target remain held pending independent result-page acceptance.
