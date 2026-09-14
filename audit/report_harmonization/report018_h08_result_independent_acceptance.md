# REPORT-018 H08 result independent acceptance

Date: 2026-08-21

Disposition: **ACCEPTED**

The H08 result page is independently accepted after exactly one authorized
target render. The H08 companion and every later REPORT-018 render remain held
pending a separately sealed release.

## Accepted endpoints

- Result QMD `notebooks/hypotheses/H08.qmd`, SHA-256
  `1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1`,
  44,031 bytes.
- Result HTML `_build/nathealth/notebooks/hypotheses/H08.html`, SHA-256
  `472848d0da3e3996fa1727151048e3cab4a7e363dba3dc8eda8b024eb5a4ca9a`,
  340,040 bytes.
- Held companion QMD
  `audit/hypotheses/H08/H08_analysis_preparation.qmd`, SHA-256
  `3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d`,
  57,777 bytes.
- Held companion HTML
  `_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html`,
  SHA-256
  `95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135`,
  675,700 bytes.
- Normal profile `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

## Independent verification

The durable checker
`scripts/report_harmonization/check_h08_order54_result_acceptance.R`,
SHA-256
`f948f190f5c3cd09640892f18ef5c92ad3a8cd565490d5107b97419624fcf99d`,
ran under R 4.6.1 with digest 0.6.39 and xml2 1.6.0. Its verification table is
`audit/report_harmonization/report018_h08_result_independent_verification.csv`,
SHA-256
`823a80ac2ab50bd404f736de9603aa3d1cd326d4b5811aae2072e397ecc1e840`.

It independently passed all 48 checks:

- 174 of 174 owner-manifest members exist and match their exact SHA-256 and
  byte counts; paths are unique and the seal is non-circular;
- the one render attempt exited 0 under R 4.6.1 and Quarto 1.9.37;
- exactly 15 native `gt` tables and five figure endpoints occur once each;
- the formula table contains all nine accepted ordered Wilkinson formulas;
- the semantic hook repaired exactly 86 IDs and 855 `headers` attributes,
  for 941 reversible substitutions;
- semantic reverse and reapplication checks pass, visible and structural
  invariance checks pass, there are no duplicate document IDs, and all 864
  table-header token uses resolve exactly once to a `th` inside their table;
- all 26 reader and source-data targets, reciprocal navigation, DEV-035,
  DEV-036, active navigation, country-coded sites, and accepted reader phrases
  pass;
- the Stage 3 manifest remains byte-identical at 99 of 102 live-exact rows
  plus exactly the accepted result-QMD, profile, and result-HTML transitions;
- the phase-4 manifest remains byte-identical with its H08 HTML row correctly
  classified as historical-to-fresh;
- exactly three build changes are classified: H08 result HTML, `search.json`,
  and `sitemap.xml`; no build member was removed and no build symlink exists;
- the post-render and post-QA inventories are identical for all 851 build files
  and all 153 protected paths; and
- all 74 screenshot files are present with their recorded byte counts.

The independent DOM replay found one `main#quarto-document-content`, zero
duplicate IDs, 15 native tables, five unique figures, and 864 correctly
resolved table-header tokens. A fresh `lsof` check found no listener on the
recorded loopback port 8774.

## Visual and lifecycle acceptance

The retained visual evidence passes at 1440 by 1000, 708 by 1000, and 720 by
500 as the 200-percent-equivalent view. All tables and figures remain readable
and contained, the narrow sidebar and internal anchors work, and there is no
page-level overflow, clipping, overlap, missing content, or report-attributable
console warning or error. All five accepted 170-mm figure proofs retain 7.5-pt
effective essential text and pass clipping, overlap, wrapping, distortion, and
data-region-balance checks.

The QA tab was closed, the viewport was reset, the loopback server exited, and
no listener or order-specific process remains.

## Preserved boundary

Both historical H08 tests, the 102-row Stage 3 manifest, the phase-4 corpus
manifest, the held companion, the five durable figures, every source-data and
scientific artifact, the profile, semantic engine, package library, and
`renv.lock` remain unchanged. The order-specific verifier corrections and two
finalizer corrections are evidence-harness changes only. No source patch,
rerender, model fit or refit, prediction, resampling, simulation, p-value
calculation, scientific regeneration, commit, push, upload, or publication
action occurred.

This closes the H08 result-page gate. It does not release the H08 companion.
