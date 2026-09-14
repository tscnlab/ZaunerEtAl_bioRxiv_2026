# REPORT-018 order 55: H08 companion render and acceptance

Date: 2026-08-21

Owner: H08 owner `019fbdb6-b6a8-7e53-8e84-7a2967af9ea5`

Status: released for exactly one H08 companion render. Every later
REPORT-018 render remains held.

## Controlling authority

Follow the complete release at
`audit/report_harmonization/report018_h08_companion_release.md`, SHA-256
`cfceb62d6a3fb9b4c0e524ac3571e02152bdde3fa44d77add36b6179dec65c81`.
Its completed preflight is:

```text
H08_COMPANION_REPORT018_RELEASE=PASS checks=32/32 pins=34/34 result_acceptance=31/31 chunks=24 tables=19 figures=3 mermaid=1 links=25 manifest=121/125+4 prospective_manifest=258 forbidden_calls=0 build=851 symlinks=0 R=4.6.1 digest=0.6.39 quarto=1.9.37
```

The controlling preflight identities are:

- checker `scripts/report_harmonization/check_h08_companion_report018_release.R`,
  SHA-256
  `4e5e82d02d7f509aac6bb2719a8ec4367f0af55fb7cfe1c755512f68833e32fa`,
  21,227 bytes;
- verification SHA-256
  `1d654a189cf7aba6e6c428f89cfbbe6b6627433910b64310e8057c6fe828f26a`,
  4,322 bytes; and
- 34-row pins SHA-256
  `340c236b006a18c2f42ba2d5563dc7cab9267cce2c500a7bbd43e18e9881b309`,
  5,521 bytes.

Before execution, reproduce this order, the complete dispatch manifest, the
release, and every non-matrix hard pin. The coordination matrix is
dispatch-time evidence only. Do not edit it and do not rerun the completed
central checker after its expected status transition.

## Frozen endpoints

Require:

- accepted result QMD `1b6b50b2...` and HTML `472848d0...`;
- companion QMD `3eeeda47...`;
- stale build companion QMD `1a3c9ee0...`;
- stale companion HTML `95f5ba0a...`;
- helper `55fb7222...`;
- historical preparation test `2e83542b...` and result test `3049ecd8...`;
- current 125-row preparation manifest `1cf574e0...`;
- Stage 3 manifest `e8dcec4b...` and physical-size QA `f4680525...`;
- profile `80dd0557...`, semantic wrapper `28c11058...`, semantic engine
  `7c949930...`, phase-4 manifest `73f1a371...`, handoff `8a7be6d7...`, and
  lockfile `3bf99c63...`; and
- all six frozen companion source CSVs and three current target PNGs at the
  exact dispatch identities.

## Pre-render gate

Before rendering:

1. reproduce every non-matrix dispatch member;
2. require 24 parseable R chunks, exactly 19 native-table endpoints, three
   figure endpoints, one top-down Mermaid, and all 25 relative targets in the
   accepted source order;
3. require zero prohibited scientific-regeneration calls;
4. require the 125-row preparation manifest to have exactly 121 live rows and
   only the four accepted historical transitions;
5. require 851 build files, zero build symlinks, and the accepted result,
   companion, profile, source CSV, figure, helper, test, and manifest pins;
6. inventory the complete build and protected H08 scopes; and
7. confirm no competing Quarto, Pandoc, H08 semantic, or loopback process.

Create all pre-render working evidence under one fresh temporary directory
outside the project. Create a separate fresh empty absolute semantic-audit
directory under `/private/tmp`.

Preserve both historical H08 tests byte-for-byte and do not execute them. The
preparation test contains the classified obsolete hard-coded HTML source link.
Use a new order-specific verifier after rendering.

## Sole render

Run exactly once from the project root:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render audit/hypotheses/H08/H08_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the accepted project library, the normal profile,
the accepted semantic hook, and the established narrow access to existing
user-owned caches. Do not alter `HOME`, redirect or reset a cache, restore or
install packages, bypass the profile, use `--no-execute`, render another
target, or retry. On any failure, stop once and seal it.

## One helper execution

If and only if the render and semantic hook succeed, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla scripts/hypotheses/H08/build_h08_preparation_report_manifest.R
```

The helper must execute before any durable order-55 evidence directory is
created. Require authoring and build companion QMDs to be byte-identical and
the resulting preparation manifest to contain exactly 258 unique,
live-exact, non-circular rows. It must exclude itself and every order-55
evidence path. The helper may change only the build QMD copy and the
preparation manifest. Do not run it again.

## Required acceptance

After the helper, create one new durable evidence directory under
`audit/hypotheses/H08/report018_order55_companion_render/` and prove:

- render exit zero, exactly one Quarto invocation, and no embedded error,
  unresolved reference, or raw trace;
- exactly 19 native `gt` tables, three figures, and one top-down Mermaid in
  source order;
- every table and figure endpoint, caption, note, alt text, cell, label,
  paired source, reader link, navigation link, and country-coded site present;
- semantic repair of all 19 tables, unique document IDs, exact ledger reverse
  and reapplication, and every `headers` token resolving exactly once to an
  intended `th` inside its own table;
- all 25 relative targets and fragments resolve, including three dynamic
  result links, reciprocal navigation, DEV-035, DEV-036, and the result
  deviation-section anchor;
- all accepted source-data row counts, score audit, sample support, exact
  formulas, model settings, eight FDR families, response gates, influence and
  sensitivity summaries, METRIC-011 provenance, code/output maps, and
  environment records remain consistent with the frozen inputs;
- the accepted result, profile, helper, historical tests, source CSVs,
  scientific artifacts, durable figures, handoff, historical manifests,
  phase-4 manifest, semantic code, and lockfile remain exact;
- the final 258-row preparation manifest is wholly live-exact;
- the source-side companion HTML remains absent; and
- build changes are only the companion target, source-identical build QMD,
  target-owned resources, search and sitemap integration, and the truthful
  H08 preparation manifest.

If any of the three target-generated PNGs changes bytes, require the same
frozen CSV rows, geometry, labels, values, panels, colours, and visible
content, plus at least 7-point final-size text. Classify the exact transition
in owner evidence only. Do not edit the physical-size manifest or promote a
durable display artifact.

The phase-4 corpus manifest remains byte-identical. Its result and companion
HTML identities are historical records and must be classified against the
current accepted pages rather than resealed.

## Secure loopback QA

After every nonvisual gate passes, serve `_build/nathealth` through one
read-only server bound only to `127.0.0.1`. Inspect the H08 companion route at
1440 by 1000, 708 by 1000, and 720 by 500 as the 200-percent-equivalent view.
Inspect all 19 tables, all three figures, the Mermaid diagram, headings,
callouts, captions, notes, links, navigation, disclosures, and final
provenance. Exercise required narrow table scrollers. Inspect each figure at
170 mm and require essential text of at least 7 points.

Require no page overflow, clipping, overlap, missing content, broken
interaction, or report-attributable console warning or error. Close the QA
surface, reset the viewport, stop the server, prove no listener remains, and
require post-QA build and protected inventories to match their post-render
states exactly.

## Return and prohibitions

Return one completion record and one unique non-circular evidence manifest,
or one consolidated fail-closed record. Retain external semantic evidence
until independent acceptance.

No source/helper/test/profile/science/durable-figure/handoff/ledger/package or
lock change, result rerender, later render, full-project render, retry,
language or cosmetic loop, commit, push, upload, or publication is
authorized. The mandatory next stop is independent H08 companion acceptance.
