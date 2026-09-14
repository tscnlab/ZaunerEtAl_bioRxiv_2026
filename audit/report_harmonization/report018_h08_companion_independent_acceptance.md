# REPORT-018 H08 companion independent acceptance

Date: 2026-08-21

Disposition: **ACCEPTED**

The H08 result and preparation/provenance companion are accepted as the
current integrated reader pair. Order 55 used exactly one H08 companion
target render, followed by exactly one execution of the dedicated preparation
manifest helper. No result page, later target, or full project was rendered.

## Accepted endpoints

- Result QMD `notebooks/hypotheses/H08.qmd`, SHA-256
  `1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1`,
  44,031 bytes.
- Result HTML `_build/nathealth/notebooks/hypotheses/H08.html`, SHA-256
  `472848d0da3e3996fa1727151048e3cab4a7e363dba3dc8eda8b024eb5a4ca9a`,
  340,040 bytes.
- Companion QMD `audit/hypotheses/H08/H08_analysis_preparation.qmd`, SHA-256
  `3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d`,
  57,777 bytes.
- Source-identical build QMD, SHA-256
  `3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d`,
  57,777 bytes.
- Companion HTML
  `_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html`,
  SHA-256
  `cd0ce2210949559408d07bcbccac502d3b0a372b4229da70bdfc6dbe0c52f66b`,
  732,155 bytes.
- Preparation manifest
  `artifacts/12_manifests/H08/H08_preparation_report_manifest.csv`, SHA-256
  `53264f81daed1b69ff8e78e7afcdab0e7d34b473ddb2f20b9f6820ffca5c1720`,
  64,474 bytes.

The profile remains exact at SHA-256
`80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
Both historical H08 tests remain byte-identical and were not executed.

## Independent verification

The independent R 4.6.1 checker
`scripts/report_harmonization/check_h08_order55_companion_acceptance.R`,
SHA-256
`2e4eb135e63dde33616ed165034bdc74bc5ed75afea1ab25c4bf675f6e7e8298`,
passed 64 of 64 checks. Its verification table is SHA-256
`3c17d6fea5d0787f8045236fc309e8ff00575601c9af10e198ca230fc7807741`.

The replay independently established:

- all 209 owner-seal members are present, unique, non-circular, and exact;
- all 258 preparation-manifest members are present, unique, non-circular,
  live-exact, and exclude the manifest itself and order-55 evidence;
- exactly 19 native `gt` tables, three figure endpoints, and one top-down
  Mermaid endpoint occur in the accepted page;
- the semantic hook made exactly 193 ID and 878 `headers` substitutions,
  for 1,071 reversible substitutions;
- the document has zero duplicate IDs and all 1,581 table-header tokens
  resolve exactly once to a `th` inside their own table;
- all 25 reader and source-data targets, required fragments, reciprocal H08
  navigation, country-coded site names, formulas, model settings, eight
  complete nine-test FDR families, and stored-output contracts pass;
- the post-QA build inventory is exact at 851 of 851 files, the protected H08
  inventory is exact at 276 of 276 paths, and all 82 screenshot identities
  are present and exact; and
- the loopback server was stopped, the QA tab was closed, the viewport was
  reset, and no listener or related process remained.

Independent inspection of the retained desktop, 708-pixel, 200-percent
equivalent, and 170-mm evidence found no clipping, overlap, missing content,
page overflow, or illegible essential text. Both required narrow table
scrollers operate within their containers. All three figures meet an 8-point
effective final-size text floor.

## Classified target-resource transition

Exactly one target-owned companion PNG changed during the authorized render:
`fig-h08-prep-sample-support-1.png`, from SHA-256 `a0755098...` to
`858a691e...`. The paired source remains exact, the 1285 by 940 geometry and
all plotted values, coordinates, panels, axes, labels, and colours are
preserved. The fresh file adds only the source-declared dashed line and
triangle redundancy for the chest series. The transition is accepted as
deterministic target regeneration with unchanged scientific content.

The five owner verifier corrections and four browser-harness corrections are
fully recorded. They concern historical-row classification, isolated DOM
instances, type coercion, an invented reader-phrase requirement, vectorized
site checks, browser measurement, scroller interaction, and current-target
physical-size evidence. None changed a source, model, estimate, inference,
rendered page, scientific artifact, or accepted claim, and no rerender
occurred.

## Serial disposition

H08 is idle with its result and companion accepted. Principal-output
appearance remains provisional for final author approval. The next eligible
REPORT-018 target is the H09 result page. The H09 companion and every later
render remain held until separate result acceptance.
