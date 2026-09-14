# REPORT-018 order 56: H09 result render and acceptance

Date: 2026-08-21

Owner: H09 owner `019fdc1b-b927-7fb1-ac61-88993c0a818a`

Status: released for exactly one H09 result-page render. The H09 companion and
every later REPORT-018 render remain held.

## Controlling authority

Follow the complete central release at
`audit/report_harmonization/report018_h09_result_release.md`, SHA-256
`68482d5bb752dc2a47f5b666cb7c8e3ca5289488a442f43d50cf55012b56103c`,
and its 46-row non-circular manifest, SHA-256
`51feb12b928136c0816b626985524f3052fc3dfde66a759db345c0574ca38c5b`.
The central R 4.6.1 checker and its frozen evidence are:

- `scripts/report_harmonization/check_h09_result_report018_release.R`,
  SHA-256
  `2e4046aa949b3a4ef8ef428c4bfd02a3ecd9b7c54a3fee1703f0f527aa4363b7`;
- `audit/report_harmonization/report018_h09_result_release_pins.csv`, SHA-256
  `d65f20daa2ec1955aaa48bcdf7a9ec6c4e98c84c444a5d24348fe807a1578947`;
- `audit/report_harmonization/report018_h09_result_release_verification.csv`,
  SHA-256
  `4be33abc17149b6367440fea947d9b4ca855d17a1c111046614528683de20b59`;
  and
- the completed disposition
  `H09_RESULT_REPORT018_RELEASE=PASS checks=29/29 pins=42/42
  preceding=30/30 chunks=17 tables=11 figures=4 links=23/21
  deviations=3 historical_manifest=97/108+11
  reader_test=DEFERRED_HISTORICAL forbidden_calls=0 build_symlinks=0
  R=4.6.1 quarto=1.9.37`.

The preceding serial acceptance is
`audit/report_harmonization/report018_h08_companion_independent_acceptance.md`,
SHA-256
`beacb92b41ee7f142bf95b8e2fb53cf8e8595ba3339d99c8277c53b5e1bbc816`,
with its 30-row non-circular manifest at SHA-256
`d84f7bda237c29ce73eb465a8d521dad920fb0bff499c5e0244931bc4c699297`.

Before any execution, reproduce this order, the complete dispatch manifest,
and every non-matrix hard pin exactly. The coordination matrix is
dispatch-time evidence only. It will change when this order is released and
must not be treated as an owner execution pin. Do not rerun the completed
central release checker after the expected matrix transition.

## Frozen page and environment identities

Require these exact identities before the render:

- result QMD `notebooks/hypotheses/H09.qmd`, SHA-256
  `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6`,
  36,970 bytes;
- held companion QMD
  `audit/hypotheses/H09/H09_analysis_preparation.qmd`, SHA-256
  `7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46`,
  47,901 bytes;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H09.html`,
  SHA-256
  `ce6c4c644af675e5feb25dcbc834b55c3ddfc87ec3dc581c95366edc0de067b1`,
  229,798 bytes;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html`,
  SHA-256
  `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05`,
  593,181 bytes;
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
2. Parse all 17 R chunks without executing the QMD.
3. Require exactly 11 unique native `gt` table endpoints and four unique
   figure endpoints in the source order frozen by the central checker.
4. Require exactly 23 link occurrences and 21 unique relative reader or
   source-data targets, including reciprocal companion navigation and
   resolving DEV-037, DEV-038, and DEV-039 anchors. Require IMP-009 absent.
5. Require the exact five ordered Wilkinson formulas and the frozen scientific
   contracts summarized by the central release.
6. Require zero model fitting, refitting, prediction, simulation, bootstrap,
   resampling, p-value recalculation, or scientific-artifact writing calls.
7. Inventory the complete `_build/nathealth` tree and complete protected H09
   scope. Require zero build symlinks.
8. Require the unchanged 108-row Stage 3 manifest to have exactly its 11
   accepted pre-render historical transitions. Every other row must be
   live-exact.
9. Confirm no competing Quarto, Pandoc, H09 semantic-hook, or loopback
   process.
10. Create one fresh empty absolute semantic-evidence directory under
    `/private/tmp`.

Preserve both historical H09 tests byte-for-byte and do not execute them. The
reader test predates accepted FDR wording. The preparation test belongs to the
held companion integration. Create one order-specific verifier under
`audit/hypotheses/H09/report018_order56_result_render/` instead.

## Sole render

Run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render notebooks/hypotheses/H09.qmd --profile nathealth
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
- exactly 11 native `gt` tables and four figures in accepted source order;
- every endpoint, caption, note, cell, label, alt text, and paired-source
  relationship preserved;
- `tbl-h09-formulas` contains exactly the five ordered evaluated Wilkinson
  formulas in one semantic table, with no separate formula-object output;
- semantic-hook disposition `REPAIRED`, or a separately evidenced
  already-repaired disposition, with external summary, complete ledger, exact
  reverse to recorded pre-hook HTML, exact reapplication, zero duplicate
  document IDs, and every `headers` token resolving exactly once to an
  intended `th` inside its own table;
- the accepted Answer in brief callout, exact sample counts, primary near-eye
  and complementary chest hierarchy, eight complete FDR families, six and
  four adjusted-significant primary rows, zero adjusted-significant
  interactions, diagnostic and sensitivity qualifications, and non-causal
  wording;
- all 23 link occurrences and 21 unique relative targets, reciprocal
  companion target, DEV-037 through DEV-039, active navigation, and
  country-coded sites;
- all four accepted result figures and paired source data, plus every
  accepted scientific input, test, historical manifest, held companion QMD
  and HTML, profile, hook, engine, lockfile, central ledger, preceding H08
  endpoints, and unrelated build member remain exact;
- the historical Stage 3 manifest remains byte-identical and has exactly its
  12 expected post-render transitions: the 11 frozen pre-render transitions
  plus result HTML;
- `audit/report_harmonization/phase4_corpus_manifest.csv` remains
  byte-identical, with its H09 HTML row explicitly classified as the expected
  historical-to-fresh transition; and
- every build delta is target-owned, source-identical, or an expected search
  or sitemap integration change. Any target-regenerated display requires
  deterministic same-source and visible-content verification.

Do not execute or edit either historical H09 report test. Do not open a new
language or cosmetic cleanup pass.

## Secure loopback visual QA

Only after all nonvisual checks pass, serve exactly `_build/nathealth` through
one temporary read-only server bound only to `127.0.0.1`. First require no
symlink under the served root to escape that root.

Inspect only the H09 result route at 1440 by 1000, 708 by 1000, and 720 by 500
as the 200-percent-equivalent view. Inspect the complete reader flow, all 11
tables, all four figures, callouts, headings, captions, links, navigation,
wrapping, disclosures, axes, legends, symbols, site codes, clipping, overlap,
and page overflow. Inspect every exported figure at its intended 170-mm final
size.

The historical figure manifest records effective essential-text values from
5.10 to 6.69 points. It is not sufficient evidence for this render. Require a
fresh final-size inspection and the accepted 7-point essential-text floor. If
the page or an exported figure fails, return one consolidated fail-closed
readability finding. Do not patch or rerender within this order. A genuinely
wide table may use a visible contained horizontal scroller at narrow width if
it causes no page-level overflow.

Stop the server immediately after QA. Close the QA tab, reset the viewport,
wait for process exit, prove that no listener remains, and rehash the QMD,
profile, result HTML, held companion, complete build inventory, and protected
inventory. Pre-QA and post-QA inventories must match exactly.

## Return and hold

Return one complete acceptance record and one unique, non-circular evidence
manifest, or one consolidated fail-closed record. Retain the external semantic
evidence until independent acceptance.

No source, test, historical or current manifest, scientific artifact,
profile, central ledger, package, lockfile, companion render, later render,
full-project render, retry, commit, push, upload, or publication change is
authorized.
