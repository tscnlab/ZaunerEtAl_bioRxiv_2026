# REPORT-018 order 54: H08 result render and acceptance

Date: 2026-08-21

Owner: H08 owner `019fbdb6-b6a8-7e53-8e84-7a2967af9ea5`

Status: released for exactly one H08 result-page render. The H08 companion and
every later REPORT-018 render remain held.

## Controlling authority

Follow the complete central release at
`audit/report_harmonization/report018_h08_result_release.md`, SHA-256
`c729a0917cbaa7cd51f41b259b7016a6936abdad4fbb99ad5617589c5ced4ccd`,
and its 30-row non-circular manifest, SHA-256
`71e1fb067205453e462255b6bd3bb5e687c50f3be26e120ce544f5afc333e279`.
The central R 4.6.1 checker and its pins remain:

- `scripts/report_harmonization/check_h08_result_report018_release.R`,
  SHA-256
  `06c523c34776008d76cd8e2a2d4fde217adbe0e7b61de7ea87d2d4987d8a0a26`;
- `audit/report_harmonization/report018_h08_result_release_pins.csv`,
  SHA-256
  `49388f62105372f81cc0ef4cbbb7ce28eba2553b76d6b263806856eb15331714`;
  and
- its completed disposition:
  `H08_RESULT_REPORT018_RELEASE=PASS pins=31/31 chunks=22 tables=15
  figures=5 links=26 deviations=2 historical_manifest=100/102
  reader_test=DEFERRED_HISTORICAL forbidden_calls=0 build_symlinks=0
  R=4.6.1 quarto=1.9.37`.

The preceding serial acceptance is
`audit/report_harmonization/report018_h07_companion_independent_acceptance.md`,
SHA-256
`d721a733c3ccb5867f7cbed4fc442858f9c4561354db5023422e96765e854ca4`,
with its 34-row non-circular manifest at SHA-256
`fd57630a224c6f998712bcf457f422cab4303e751fd1d15370be9d1595b07fb7`.

Before any execution, reproduce this order, the complete dispatch manifest,
and every non-matrix hard pin exactly. The coordination matrix is dispatch-time
evidence only. It will change when this order is released and must not be
treated as an owner execution pin. Do not rerun the completed central release
checker after the expected matrix transition.

## Frozen page and environment identities

Require these exact identities before the render:

- result QMD `notebooks/hypotheses/H08.qmd`, SHA-256
  `1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1`,
  44,031 bytes;
- held companion QMD
  `audit/hypotheses/H08/H08_analysis_preparation.qmd`, SHA-256
  `3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d`,
  57,777 bytes;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H08.html`,
  SHA-256
  `a08a888a40ec58669c61a47b7500159388577eaad49ece5440b9bee9da6a93e1`,
  299,712 bytes;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html`,
  SHA-256
  `95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135`,
  675,700 bytes;
- normal profile `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper and engine at SHA-256 `28c11058...` and
  `7c949930...`; and
- `renv.lock`, SHA-256 `3bf99c63...`.

Use R 4.6.1, Quarto 1.9.37, and the accepted project library at
`renv/library/macos/R-4.6/aarch64-apple-darwin23`.

## Pre-render gate

Before rendering:

1. Rehash every non-matrix dispatch member and require exact agreement.
2. Parse all 22 R chunks without executing the QMD.
3. Require exactly 15 unique native `gt` table endpoints, five unique figure
   endpoints, and the accepted source order.
4. Require all 26 unique relative reader and source-data targets, including
   reciprocal companion navigation and resolving DEV-035 and DEV-036 anchors.
5. Require the exact nine ordered Wilkinson formula literals and the frozen
   scientific contracts summarized by the central release.
6. Require zero model fitting, refitting, prediction, simulation, bootstrap,
   resampling, p-value recalculation, or scientific-artifact writing calls.
7. Inventory the complete `_build/nathealth` tree and the complete protected
   H08 scope. Require zero build symlinks.
8. Require the unchanged 102-row Stage 3 manifest to have exactly its two
   accepted pre-render historical transitions: result QMD and profile. Every
   other row must be live-exact.
9. Confirm no competing Quarto, Pandoc, H08 semantic-hook, or loopback process.
10. Create one fresh empty absolute semantic-evidence directory under
    `/private/tmp`.

Preserve both historical H08 tests byte-for-byte and do not execute them. The
reader test predates the accepted `Answer in brief`, FDR wording, and fifteenth
native formula table. The preparation test belongs to the held companion
integration. Create one order-specific verifier under the new order-54
evidence directory instead.

## Sole render

Run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render notebooks/hypotheses/H08.qmd --profile nathealth
```

The established narrow elevated filesystem access to the existing user-owned
Quarto and R caches is authorized for this command. Do not change `HOME`,
reset or redirect any cache, install or restore packages, bypass the profile
or semantic hook, render the companion, render another page, or render the
full project. If startup fails before QMD execution, stop once with complete
environment evidence. Do not retry.

The render may read accepted stored tables, source CSVs, registries, and
figures and format their frozen values. It must not fit or refit a model,
predict, bootstrap, simulate, resample, recalculate p-values, change a
classification, or rebuild a scientific artifact.

## Complete post-render verification

After a successful render, use R 4.6.1 and the new order-specific verifier to
require:

- render exit 0, no embedded error, warning, stderr, unresolved reference, or
  raw execution trace;
- exactly 15 native `gt` tables and five figures in accepted source order;
- every endpoint, caption, note, cell, label, alt text, and paired-source
  relationship preserved;
- `tbl-h08-formulas` contains exactly the nine ordered evaluated formula
  strings in one semantic table, with no separate formula-object output;
- semantic-hook disposition `REPAIRED`, or a separately evidenced already
  repaired disposition, with external summary, complete ledger, exact reverse
  to the recorded pre-hook HTML, exact reapplication, zero duplicate document
  IDs, and every `headers` token resolving exactly once to an intended `th`
  inside its own table;
- the accepted Answer in brief callout, exact sample counts, mixed effect
  scales, eight complete FDR families, primary near-eye and complementary
  chest hierarchy, model-check and sensitivity qualifications, and the
  conclusion that no association retained FDR-adjusted support;
- all 26 relative targets, reciprocal companion target, DEV-035 and DEV-036,
  active navigation, and country-coded sites;
- the five accepted result PNGs and every accepted scientific input,
  source-data file, test, historical manifest, held companion QMD and HTML,
  profile, hook, engine, lockfile, central ledger, preceding H07 endpoint, and
  unrelated build member remain exact;
- the historical Stage 3 manifest remains byte-identical and has exactly its
  three expected post-render transitions: result QMD, profile, and result HTML;
- `audit/report_harmonization/phase4_corpus_manifest.csv` remains
  byte-identical, with its H08 HTML row explicitly classified as the expected
  historical-to-fresh transition; and
- every build delta is target-owned, source-identical, or an expected search
  or sitemap integration change. Any target-regenerated display requires
  deterministic same-source and visible-content verification.

The deferred baked wording in accepted H08 figures does not authorize a
display refresh. Report a genuine scientific or readability defect if one is
found, but do not open a language or cosmetic cleanup loop.

## Secure loopback visual QA

Only after all nonvisual checks pass, serve exactly `_build/nathealth` through
one temporary read-only server bound only to `127.0.0.1`. First require no
symlink under the served root to escape that root.

Inspect only the H08 result route at 1440 by 1000, 708 by 1000, and 720 by 500
as the 200-percent-equivalent view. Inspect the complete reader flow, all 15
tables, all five figures, callouts, headings, captions, links, navigation,
wrapping, disclosures, axes, legends, symbols, site codes, clipping, overlap,
and page overflow. Inspect every exported figure at its intended 170-mm final
size and require essential text at or above 7 points. A genuinely wide table
may use a visible contained horizontal scroller at narrow width if it causes
no page-level overflow.

Stop the server immediately after QA. Close the QA tab, reset the viewport,
wait for process exit, prove that no listener remains, and rehash the QMD,
profile, result HTML, held companion, complete build inventory, and protected
inventory. The pre-QA and post-QA inventories must match exactly.

## Return and hold

Return one complete acceptance record and one unique, non-circular evidence
manifest, or one consolidated fail-closed record. Retain the external semantic
evidence until independent acceptance.

No source, test, historical or current manifest, scientific artifact,
profile, central ledger, package, lockfile, companion render, later render,
full-project render, retry, commit, push, upload, or publication change is
authorized.
