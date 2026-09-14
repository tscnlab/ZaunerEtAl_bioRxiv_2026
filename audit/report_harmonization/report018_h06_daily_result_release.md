# REPORT-018 H06_daily result-page central concurrence and serial release

Date: 2026-08-21

Disposition: **RELEASED FOR EXACTLY ONE H06_DAILY RESULT RENDER**

The accepted hourly H06 result and companion integration clears the serial
gate. This release applies only to the complementary H06_daily result page.
The H06_daily companion and every later REPORT-018 target remain held pending
separate independent result acceptance.

## Controlling acceptance and current pins

The controlling hourly H06 acceptance is:

- `audit/report_harmonization/report018_h06_companion_independent_acceptance.md`,
  SHA-256
  `046537d759b39e6ce622e7e2dcbbb215c064046212e0c355c97ac047231af562`;
- its 37-row non-circular manifest, SHA-256
  `6bb0e432dfbadb1e65adab639eeb22ed56d05f8c42f6eb0f0faa19ef65fd3770`;
  and
- coordination baseline, SHA-256
  `3813794523090f4cab710e60c274aa449d7eaad238319096fdd31c46ff545b55`.

The released H06_daily pins are:

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
  4,613,650 bytes; and
- `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
  with the result and companion adjacent after the accepted hourly H06 pair.

The semantic wrapper and accepted engine remain exact at `28c11058...` and
`7c949930...`. R is 4.6.1 and Quarto is 1.9.37. No competing Quarto, Pandoc,
or H06_daily semantic process was present at release preflight.

The coordination-matrix row in the pin set is release-time evidence only. It
is not an owner execution pin because sealing and dispatching the owner order
will truthfully update that coordinator-owned file. The central checker is a
completed pre-dispatch audit and must not be rerun after that expected matrix
transition. Every other pin remains a hard owner preflight identity.

## Independent preflight and historical classifications

The read-only checker
`scripts/report_harmonization/check_h06_daily_result_release.R`, SHA-256
`5ce08094b2cb1f2c3ac8e0fabe687f6aa54a39d82b064c0b4661ea605abbca0e`,
passed under R 4.6.1. Its 25-row hard-pin input is
`audit/report_harmonization/report018_h06_daily_result_release_pins.csv`,
SHA-256
`046090c99b323257e9c4b8a1311bcb92054c6474d1d8241ad7bd549ec9c15831`.

Fresh verification passed:

- 25/25 release pins and 37/37 hourly H06 acceptance rows;
- 23/23 Stage 3 inputs and 23/23 paired source-data rows;
- 14 unique native `gt` table endpoints and five unique figure endpoints;
- the accepted Order 20 source-preservation audit with 15 result R chunks,
  one inline R expression, and seven dynamic result links; and
- the complete focused Stage 3 scientific and reader contract after applying
  only the three accepted REPORT-014 classifications in memory.

The unchanged historical test and manifests retain exactly these accepted
classifications:

1. the historical result QMD `0318fd6c...` became the accepted editorial QMD
   `01213a19...`;
2. the historical site-deviation PNG `69fd3786...` became the accepted
   display-only Order 21 PNG `a1ddd2ae...`; and
3. the historical test expects link text `main H06 analysis`, while the
   accepted source uses the more precise `hourly H06 analysis`.

The historical figure-readability manifest contains only the same accepted
PNG transition. There is no fourth mismatch. With only those exact
classifications reconciled in memory, the complete focused test passes all
later scientific and structural assertions: primary and gap inference, ten
primary site blocks, six exploratory joint families, four temporal GAMM
estimands, three main-hourly comparison rows, 90 site adjustments, 144 site
colour markers, 14 tables, and five accessible paired-source figures.

These are historical evidence classifications, not permission to edit the
test or either historical manifest. Do not run their unchanged live-identity
gates as post-render acceptance gates. Do not rebuild or reseal them in this
result-only order.

## Sole authorized render

After reproducing every non-matrix hard pin, a complete pre-render build and
protected inventory, zero out-of-root build symlinks, no competing render
process, and one fresh empty absolute semantic-evidence directory under
`/private/tmp`, run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06_daily.qmd --profile nathealth
```

Use the normal R 4.6.1 project and `renv` startup. Only the established narrow
access to the existing user-owned `renv` cache is allowed. Do not use
`--no-execute`, bypass the configured semantic hook, render the companion,
render another page, or render the full project.

The page may read accepted stored tables, source CSVs, registries, and figures
and format their frozen values. It must not fit or refit a model, predict,
bootstrap, simulate, resample, recalculate p-values or FDR decisions, rebuild
scientific artifacts, or change a sample, formula, estimate, interval,
diagnostic, sensitivity, or claim.

## Required result-page acceptance

After the sole render, require all of the following against the fresh build
HTML:

1. R 4.6.1 and Quarto 1.9.37, render exit 0, and no embedded error, warning,
   stderr, unresolved cross-reference, or raw execution trace.
2. Exactly 14 native `gt` tables and five figures in accepted source order,
   with every caption, note, value, label, alt text, and paired source-data
   relationship preserved.
3. Semantic-hook disposition `REPAIRED` or an independently justified
   already-repaired disposition. Retain the external summary and complete
   reversible ledger. Require unique document IDs and require every explicit
   `headers` token to resolve exactly once to its intended `th` inside the
   same table.
4. Preserve the Answer in brief callout, the accepted hourly-main and
   complementary-daily hierarchy, all seven dynamic QMD links, the reciprocal
   companion target, DEV-015/030/031/032 anchors, navigation, and all nine
   country-coded sites.
5. Preserve every accepted input, source CSV, durable figure, test, historical
   manifest, companion QMD and HTML, hourly H06 endpoint, profile, hook,
   engine, lockfile, central ledger, and unrelated build member byte-for-byte.
6. Classify the complete build delta. Only the target result HTML, normal
   target-owned source-identical resource copies, and expected search or
   sitemap integration changes may change. A target-generated display may
   change only if it is deterministically regenerated from the same frozen
   source and independently proves unchanged scientific and visible content.
7. Keep `phase4_corpus_manifest.csv` byte-identical in this result-only order.
   Its H06_daily HTML row becomes one expected historical-to-fresh target
   transition pending companion or shared integration. Verify navigation and
   links directly against the fresh page rather than rebuilding the shared
   corpus manifest.

The immutable focused test at SHA-256 `16e3d02b...` remains protected. Use the
central read-only reconciliation checker or an equivalent owner-local
in-memory classification for current scientific assertions. No test,
historical manifest, source, artifact, profile, or shared-file edit is
authorized.

## Secure loopback visual QA

Only after all nonvisual checks pass, serve exactly `_build/nathealth` from one
temporary read-only server bound to `127.0.0.1`. Inspect only the H06_daily
result route at 1440 by 1000, 708 by 1000, and a 720 by 500 200-percent
equivalent view.

Inspect the complete reader flow, all 14 tables, all five figures at final
website and intended exported size, the Answer in brief callout, headings,
captions, links, navigation, wrapping, disclosures, axes, legends, symbols,
site codes, clipping, overlap, and essential text size. Contained horizontal
scrolling is acceptable for genuinely wide HTML tables if it remains usable
and does not create page-level overflow. Essential final-size text must meet
the established 7-point floor.

Stop the server immediately after QA. Prove that neither its process nor a
listener remains, reset the viewport, close the QA tab, and rehash the source,
profile, target, held companion, build, and protected inventories.

## Return and hold

Return one complete acceptance package or one consolidated fail-closed defect
list. Do not patch or rerender within this order. Keep the semantic evidence
until independent acceptance.

No H06_daily companion render or later target is released. No source, test,
manifest, scientific artifact, profile, ledger, package, or lock change,
commit, push, upload, or publication is authorized.
